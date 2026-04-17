import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/technician_service.dart';
import '../services/onboarding_service.dart';
import '../utils/image_size_guard.dart';
import '../models/technician.dart';
import '../utils/app_logger.dart';
import '../firebase/firebase_functions.dart';

class TechnicianProvider extends ChangeNotifier {
  final TechnicianService _techService = TechnicianService();
  final OnboardingService _onboardingService = OnboardingService();
  late final FirebaseAuth _auth;
  
  Technician? _technician;
  Technician? get technician => _technician;

  // NOTE: We do NOT track user role from users collection
  // The technician app is fully standalone - any authenticated user can start onboarding
  // Role is set server-side via Cloud Functions, never by client
  @Deprecated('User role is no longer tracked - technician app is standalone')
  String? get userRole => null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmittingApplication = false;
  bool get isSubmittingApplication => _isSubmittingApplication;

  // Onboarding state
  OnboardingStep _currentOnboardingStep = OnboardingStep.phone;
  OnboardingStep get currentOnboardingStep => _currentOnboardingStep;
  
  bool _isOnboardingComplete = false;
  bool get isOnboardingComplete => _isOnboardingComplete;

  bool get isApproved => _technician?.status == "approved" || _technician?.status == "active" || _technician?.profileApproved == true;
  bool get profileApproved => isApproved;
  bool get profileApprovalRequested => _technician?.profileApprovalRequested ?? false;
  bool get profileRejected => _technician?.profileRejected ?? false;

  StreamSubscription<Technician?>? _techSubscription;

  TechnicianProvider() {
    _auth = FirebaseAuth.instance;
    _auth.authStateChanges().listen((user) {
      _techSubscription?.cancel();
      
      if (user != null) {
        // NO LONGER listening to users collection - technician app is standalone
        _listenToTechnicianData(user.uid);
      } else {
        _technician = null;
        _isLoading = false;
        _currentOnboardingStep = OnboardingStep.phone;
        _isOnboardingComplete = false;
        if (!_isDisposed) notifyListeners();
      }
    });
  }

  void _listenToTechnicianData(String uid) {
    if (_isDisposed) return;
    
    _isLoading = true;
    if (!_isDisposed) notifyListeners();
    
    _techSubscription = _techService.getTechnicianStream(uid).listen((tech) async {
      if (_isDisposed) return;
      
      AppLogger.provider('Technician snapshot received', data: tech != null);
      if (tech != null) {
        AppLogger.provider('Technician data loaded', data: {
          'uid': tech.uid,
          'status': tech.status,
          'isKycComplete': tech.isKycComplete,
          'profileCompletion': tech.getProfileCompletion(), // Always use dynamic calculation
          'canCreateServices': tech.status == "approved" && tech.getProfileCompletion() == 100,
          'step': tech.currentOnboardingStep,
          'stepsCompleted': tech.stepsCompleted,
        });
        
        // ISSUE 1 FIX: Auto-sync email from FirebaseAuth if empty in Firestore
        if (tech.email.isEmpty) {
          final authEmail = _auth.currentUser?.email;
          if (authEmail != null && authEmail.isNotEmpty) {
            AppLogger.firestore('Syncing email from Auth', data: authEmail);
            try {
              final functions = FirebaseFunctionsService.instance;
              final callable = functions.httpsCallable('syncTechnicianEmail');
              await callable.call({'email': authEmail});
            } catch (e) {
              AppLogger.error('FUNCTIONS', 'Email sync failed', data: e);
            }
          }
        }
      }
      
      _technician = tech;
      
      // Update onboarding state from technician data
      if (tech != null) {
        AppLogger.provider('Approval status updated', data: {
          'profileApproved': tech.profileApproved,
          'status': tech.status,
        });
        
        // FIX 2: Onboarding step sanity guard
        OnboardingStep step = tech.currentOnboardingStep;
        if (step.stepIndex < OnboardingStep.basicDetails.stepIndex) {
          step = OnboardingStep.basicDetails;
        } else if (step.stepIndex > OnboardingStep.review.stepIndex && !tech.isKycComplete) {
          step = OnboardingStep.review;
        }
        
        _currentOnboardingStep = step;
        _isOnboardingComplete = tech.isKycComplete;
        
      }
      
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }, onError: (e) {
      // PART 6 & 7: Handle different error types with specific FirebaseException codes
      AppLogger.error('FIRESTORE', 'Listener error', data: e);
      if (_isDisposed) return;
      
      // Handle FirebaseException specifically
      if (e is FirebaseException) {
        String message = e.code;
        switch (e.code) {
          case 'permission-denied':
            message = 'Permission denied - check Firestore rules';
            break;
          case 'unavailable':
            message = 'Network unavailable';
            break;
          case 'deadline-exceeded':
            message = 'Request timeout';
            break;
          case 'not-found':
            message = 'Document not found';
            break;
          case 'network-error':
            message = 'Network connection failed';
            break;
        }
        AppLogger.warning('FIRESTORE', message, data: e.code);
      }
      
      // Keep showing existing data if available, don't clear it
      _isLoading = false;
      // PART 6: Only notifyListeners if mounted
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_technician == null) return;

    try {
      // Call Cloud Function to update online status
      final functions = FirebaseFunctionsService.instance;
      final callable = functions.httpsCallable('updateTechnicianStatus');
      
      await callable.call({
        'isOnline': isOnline,
      });
      
      // Stream will update local state automatically
    } catch (e) {
      debugPrint("⚠️ Error updating online status: $e");
      // DO NOT rethrow - fail silently to prevent UI crashes
      // The stream will eventually sync the correct state
      // Log for debugging but don't crash the app
    }
  }

  /// Create technician draft after OTP verification
  Future<void> createOnboardingDraft({required String phone}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    // Check if technician document already exists and onboarding is completed
    final techDoc = await FirebaseFirestore.instance
        .collection('technicians')
        .doc(uid)
        .get();

    if (techDoc.exists) {
      final data = techDoc.data() as Map<String, dynamic>;
      final onboardingCompleted = data['onboardingCompleted'] == true;
      final status = data['status'];

      // If technician already finished onboarding, do NOT create draft again
      if (onboardingCompleted || status == 'approved') {
        debugPrint('[Provider] Onboarding already completed. Skipping draft creation.');
        return;
      }
    }

    _isLoading = true;
    if (!_isDisposed) notifyListeners();
    
    try {
      final result = await _onboardingService.createTechnicianDraft(phone: phone);
      
      // Check if technician already exists
      if (result != null && result is Map<String, dynamic>) {
        if (result['existing'] == true) {
          // Load existing technician state
          final step = result['step'] ?? 'basicDetails';
          final status = result['status'] ?? 'pending';
          
          debugPrint('[Provider] Technician already exists, step: $step, status: $status');
          
          // Route based on existing state
          if (status == 'approved') {
            // Already approved - no need for onboarding
            return;
          } else {
            // Set current step from existing data
            _currentOnboardingStep = OnboardingStepExtension.fromString(step);
          }
        } else {
          // New technician - start with basic details
          _currentOnboardingStep = OnboardingStep.basicDetails;
        }
      } else {
        // Fallback for null result - start with basic details
        _currentOnboardingStep = OnboardingStep.basicDetails;
      }
    } catch (e) {
      debugPrint("Error creating onboarding draft: $e");
      rethrow;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Save basic details during onboarding
  Future<void> saveBasicDetails({
    required String fullName,
    String? email,
    String? district,
    int? experienceYears,
  }) async {
    _isLoading = true;
    if (!_isDisposed) notifyListeners();
    
    try {
      await _onboardingService.saveBasicDetails(
        fullName: fullName,
        email: email,
        district: district,
        experienceYears: experienceYears,
      );
      _currentOnboardingStep = OnboardingStep.documents;
    } catch (e) {
      debugPrint("Error saving basic details: $e");
      rethrow;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Save documents during onboarding
  /// CRITICAL: Validates aadhaar before saving
  Future<void> saveDocuments({
    required String? aadhaarNumber,
    required String? aadhaarFrontUrl,
    required String? aadhaarBackUrl,
    required String? profilePhotoUrl,
    String documentType = 'Aadhaar Card',
  }) async {
    _isLoading = true;
    if (!_isDisposed) notifyListeners();
    
    try {
      // CRITICAL: Validate aadhaar before passing to service
      final aadhaarError = OnboardingService.validateAadhaar(aadhaarNumber);
      if (aadhaarError != null) {
        throw Exception(aadhaarError);
      }
      
      await _onboardingService.saveDocuments(
        aadhaarNumber: aadhaarNumber,
        aadhaarFrontUrl: aadhaarFrontUrl,
        aadhaarBackUrl: aadhaarBackUrl,
        profilePhotoUrl: profilePhotoUrl,
        documentType: documentType,
      );
      _currentOnboardingStep = OnboardingStep.services;
    } catch (e) {
      debugPrint("Error saving documents: $e");
      rethrow;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Save service selection during onboarding
  Future<void> saveServices({
    required String categoryId,
    required String categoryName,
    required List<String> skills,
  }) async {
    _isLoading = true;
    if (!_isDisposed) notifyListeners();
    
    try {
      await _onboardingService.saveServices(
        categoryId: categoryId,
        categoryName: categoryName,
        skills: skills,
      );
      _currentOnboardingStep = OnboardingStep.review;
    } catch (e) {
      debugPrint("Error saving services: $e");
      rethrow;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Save step data during onboarding with multi-device safety
  /// CRITICAL: Does NOT call notifyListeners to prevent rebuild during PageView transition
  Future<void> saveStepData({
    required int step,
    required Map<String, dynamic> data,
  }) async {
    try {
      final tech = _technician;
      if (tech != null) {
        final serverStep = tech.currentOnboardingStep.stepIndex;
        if (step < serverStep) {
          debugPrint('[Provider] Multi-device safety: ignoring stale step $step (server=$serverStep)');
          return;
        }
      }
      
      await _onboardingService.saveStepData(step: step, data: data);
      
      // DO NOT refresh or notify here - let the stream handle it naturally
      // This prevents rebuild during PageView transition
    } catch (e) {
      debugPrint("Error saving step: $e");
      rethrow;
    }
  }

  /// Submit the complete KYC application with global lock and refresh
  Future<void> submitKycApplication() async {
    if (_isSubmittingApplication) {
      throw Exception('Application already being submitted');
    }

    _isSubmittingApplication = true;
    _isLoading = true;
    if (!_isDisposed) notifyListeners();
    
    try {
      await _onboardingService.submitApplication();
      _currentOnboardingStep = OnboardingStep.submitted;
      _isOnboardingComplete = true;
      
      await refreshTechnicianData();
      
      // Evaluate KYC completion on backend after submission
      // Cloud Function checks all required fields and sets isKycComplete
      AppLogger.info('ONBOARDING', 'Evaluating KYC on backend');
      await evaluateTechnicianKyc();
      
      // Refresh again to get the updated isKycComplete status from backend
      await refreshTechnicianData();
      
    } catch (e) {
      debugPrint("Error submitting application: $e");
      rethrow;
    } finally {
      _isSubmittingApplication = false;
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Upload document image with compression
  /// Compresses before upload, stores only URL in Firestore
  Future<String> uploadDocumentImage(File imageFile, String type, {int maxRetries = 3}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    if (_isDisposed) {
      throw Exception('Provider disposed - cannot upload');
    }

    int attempt = 0;
    Exception? lastError;
    File? compressedFile;
    
    while (attempt < maxRetries) {
      try {
        if (_isDisposed) {
          throw Exception('Provider disposed during upload');
        }
        
        // Compress image before upload using canonical image_size_guard
        final compressedFile = await ImageSizeGuard.validateAndCompress(imageFile);
        final bytes = await compressedFile.readAsBytes();

        final extension = 'jpg';
        final docType = type.replaceAll('_', '');
        final path = 'technicians/$uid/kyc/$docType.$extension';
        
        final uploadTask = FirebaseStorage.instance.ref().child(path).putData(
          bytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': uid,
              'uploadedAt': DateTime.now().toIso8601String(),
              'type': type,
            },
          ),
        );

        final snapshot = await uploadTask.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Upload timed out');
          },
        );
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        debugPrint('[Provider] Uploaded $type (compressed)');
        return downloadUrl;
      } catch (e) {
        lastError = e as Exception;
        attempt++;
        debugPrint('[Provider] Upload attempt $attempt failed: $e');
        
        if (attempt >= maxRetries) {
          break;
        }
        
        await Future.delayed(Duration(milliseconds: 500 * attempt));
        
        if (_isDisposed) {
          throw Exception('Provider disposed - upload cancelled');
        }
      } finally {
        try {
          if (compressedFile != null && await compressedFile.exists()) {
            await compressedFile.delete();
          }
        } catch (_) {}
      }
    }
    
    throw lastError ?? Exception('Upload failed after $maxRetries attempts');
  }

  /// Fetch fresh technician data from server (not cache)
  /// Used for routing decisions to prevent state drift
  Future<Technician?> fetchFreshTechnicianData() async {
    final uid = _auth.currentUser?.uid;
    AppLogger.firestore('Fetching fresh technician data', data: uid);
    if (uid == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Firestore connection timeout'),
          );
      
      if (!doc.exists) {
        AppLogger.warning('FIRESTORE', 'Technician document does not exist', data: uid);
        // Auth trigger creates document automatically on signup
        return null;
      }
      
      AppLogger.firestore('Technician data fetched', data: doc.data());
      
      final tech = Technician.fromFirestore(doc);
      
      AppLogger.info('FIRESTORE', 'KYC complete resolved', data: tech.isKycComplete);
      
      return tech;
    } on SocketException catch (e) {
      AppLogger.error('NETWORK', 'No internet connection', data: e);
      return null;
    } on TimeoutException catch (e) {
      AppLogger.error('NETWORK', 'Connection timeout', data: e);
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        AppLogger.warning('FIRESTORE', 'Firestore unavailable', data: e.message);
      } else {
        AppLogger.error('FIREBASE', 'Firebase error', data: e);
      }
      return null;
    } catch (e, st) {
      AppLogger.error('FIRESTORE', 'Failure fetching technician', data: e, stackTrace: st);
      return null;
    }
  }

  /// Evaluate KYC completion status via Cloud Function
  /// Called after technician completes onboarding
  /// Returns checklist object with field completion status
  Future<Map<String, dynamic>?> evaluateTechnicianKyc() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLogger.error('AUTH', 'No user ID for KYC evaluation');
      return null;
    }

    try {
      final functions = FirebaseFunctionsService.instance;
      final callable = functions.httpsCallable('evaluateTechnicianKyc');
      
      final result = await callable.call().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('KYC evaluation timeout'),
      );
      
      final data = result.data as Map<String, dynamic>;
      AppLogger.firestore('KYC evaluation completed', data: data);
      
      return data;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('FUNCTIONS', 'KYC evaluation failed', data: '${e.code}: ${e.message}');
      return null;
    } on TimeoutException catch (e) {
      AppLogger.error('NETWORK', 'KYC evaluation timeout', data: e);
      return null;
    } catch (e, st) {
      AppLogger.error('FUNCTIONS', 'Unexpected KYC error', data: e, stackTrace: st);
      return null;
    }
  }

  /// Get approval status (backward compatible with all status values)
  bool getApprovalStatus() {
    if (_technician == null) return false;
    return _technician!.status == "approved" || 
           _technician!.status == "active" || 
           _technician!.profileApproved == true;
  }

  /// Check current KYC status via Cloud Function
  /// Returns current isKycComplete status without re-evaluating
  Future<bool?> checkKycStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLogger.error('AUTH', 'No user ID for KYC status check');
      return null;
    }

    try {
      final functions = FirebaseFunctionsService.instance;
      final callable = functions.httpsCallable('checkKycStatus');
      
      final result = await callable.call().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('KYC status check timeout'),
      );
      
      final data = result.data as Map<String, dynamic>;
      final isKycComplete = data['isKycComplete'] as bool? ?? false;
      
      AppLogger.firestore('KYC status checked', data: isKycComplete);
      
      return isKycComplete;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('FUNCTIONS', 'KYC status check failed', data: '${e.code}: ${e.message}');
      return null;
    } on TimeoutException catch (e) {
      AppLogger.error('NETWORK', 'KYC status check timeout', data: e);
      return null;
    } catch (e, st) {
      AppLogger.error('FUNCTIONS', 'Unexpected KYC status error', data: e, stackTrace: st);
      return null;
    }
  }

  Future<void> refreshTechnicianData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    try {
      final tech = await _techService.getTechnician(uid);
      if (tech != null && !_isDisposed) {
        _technician = tech;
        _currentOnboardingStep = tech.currentOnboardingStep;
        _isOnboardingComplete = tech.isKycComplete;
        if (!_isDisposed) notifyListeners();
      }
    } catch (e) {
      debugPrint("Error refreshing technician data: $e");
    }
  }

  /// Force refresh technician data from server (not cache)
  Future<void> refreshTechnician() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    try {
      debugPrint('[TechnicianProvider] Force refreshing from server...');
      final doc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      
      if (doc.exists && !_isDisposed) {
        final tech = Technician.fromFirestore(doc);
        debugPrint('[TechnicianProvider] Server data fetched: ${tech.fullName}, state: ${tech.state}, district: ${tech.district}');
        
        _technician = tech;
        _currentOnboardingStep = tech.currentOnboardingStep;
        _isOnboardingComplete = tech.isKycComplete;
        
        debugPrint('[TechnicianProvider] Provider updated, notifying listeners');
        if (!_isDisposed) notifyListeners();
      }
    } catch (e) {
      debugPrint("[TechnicianProvider] Error force refreshing technician: $e");
    }
  }

  Future<void> onboard(List<String> skills) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _techService.saveTechnicianProfile(user, skills: skills);
  }

  /// Update technician skills
  Future<void> updateSkills(List<String> skills) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    _isLoading = true;
    if (!_isDisposed) notifyListeners();
    
    try {
      await _techService.updateSkills(uid, skills);
      await refreshTechnicianData();
    } catch (e) {
      debugPrint('Error updating skills: $e');
      rethrow;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> signOut() async {
    _techSubscription?.cancel();
    await _auth.signOut();
    
    // CRITICAL: Clear local state to prevent onboarding flag persistence
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('[Provider] Local state cleared on logout');
    } catch (e) {
      debugPrint('[Provider] Failed to clear local state: $e');
    }
  }

  bool _isDisposed = false;


  /// Check if technician can create services
  bool canCreateServices() {
    if (_technician == null) return false;
    final completion = _technician!.getProfileCompletion();
    // BACKWARD COMPATIBLE: Check all approval indicators
    final approved = _technician!.status == "approved" || 
                     _technician!.status == "active" || 
                     _technician!.profileApproved == true;
    
    return completion == 100 && approved;
  }

  /// Get message explaining why service creation is blocked
  String getServiceBlockMessage() {
    if (_technician == null) {
      return 'Profile not loaded. Please try again.';
    }
    
    final completion = _technician!.getProfileCompletion();
    final approved = _technician!.status == "approved" || 
                     _technician!.status == "active" || 
                     _technician!.profileApproved == true;
    
    if (!approved) {
      if (_technician!.profileRejected) {
        return 'Your profile was rejected. Please update your information and resubmit.';
      }
      if (_technician!.profileApprovalRequested) {
        return 'Your profile is pending admin approval. You can create services once approved.';
      }
      return 'Your profile needs to be approved before you can create services.';
    }
    
    if (completion < 100) {
      return 'Please complete your profile (${completion}% complete) before creating services.';
    }
    
    return 'Unable to create services at this time.';
  }



  @override
  void dispose() {
    _isDisposed = true;
    _techSubscription?.cancel();
    super.dispose();
  }
}
