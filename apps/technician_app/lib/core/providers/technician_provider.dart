import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../services/technician_service.dart';
import '../services/onboarding_service.dart';
import '../utils/image_size_guard.dart';
import '../models/technician.dart';

class TechnicianProvider extends ChangeNotifier {
  final TechnicianService _techService = TechnicianService();
  final OnboardingService _onboardingService = OnboardingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
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
  
  bool _isApproved = false;
  bool get isApproved => _isApproved;

  bool _isAdminApproved = false;
  bool get isAdminApproved => _isAdminApproved;

  StreamSubscription<Technician?>? _techSubscription;

  TechnicianProvider() {
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
        _isApproved = false;
        _isAdminApproved = false;
        notifyListeners();
      }
    });
  }

  void _listenToTechnicianData(String uid) {
    if (_isDisposed) return;
    
    _isLoading = true;
    notifyListeners();
    
    _techSubscription = _techService.getTechnicianStream(uid).listen((tech) {
      if (_isDisposed) return;
      
      debugPrint('[TECH PROVIDER] snapshot received=${tech != null}');
      if (tech != null) {
        debugPrint('[TECH PROVIDER] data={isKycComplete: ${tech.isKycComplete}, isApproved: ${tech.isApproved}, step: ${tech.currentOnboardingStep}}');
      }
      
      // PHASE 4 FIX: Add shallow equality guard to prevent duplicate emissions
      // Only notify if data actually changed
      final previousTech = _technician;
      if (previousTech != null && tech != null) {
        // Check if key onboarding/approval fields changed
        final hasChanged = 
          previousTech.isKycComplete != tech.isKycComplete ||
          previousTech.isApproved != tech.isApproved ||
          previousTech.adminApproved != tech.adminApproved ||
          previousTech.currentOnboardingStep != tech.currentOnboardingStep ||
          previousTech.status != tech.status;
        
        if (!hasChanged) {
          // Data unchanged, skip notification to prevent rebuild storm
          _technician = tech;
          _isLoading = false;
          return;
        }
      }
      
      _technician = tech;
      
      // Update onboarding state from technician data
      if (tech != null) {
        // Debug log for approval detection
        debugPrint('[ADMIN PIPELINE] Approval detected: ${tech.isApproved}');
        debugPrint('[ADMIN PIPELINE] Admin approved: ${tech.adminApproved}');
        debugPrint('[ADMIN PIPELINE] Status: ${tech.status}');
        
        // FIX 2: Onboarding step sanity guard
        OnboardingStep step = tech.currentOnboardingStep;
        if (step.stepIndex < OnboardingStep.basicDetails.stepIndex) {
          step = OnboardingStep.basicDetails;
        } else if (step.stepIndex > OnboardingStep.review.stepIndex && !tech.isKycComplete) {
          step = OnboardingStep.review;
        }
        
        _currentOnboardingStep = step;
        _isOnboardingComplete = tech.isKycComplete;
        _isApproved = tech.isApproved;
        _isAdminApproved = tech.adminApproved; // Track admin approval for service management
      }
      
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      // PART 6 & 7: Handle different error types with specific FirebaseException codes
      debugPrint('[Stream Error] Firestore listener error: $e');
      if (_isDisposed) return;
      
      // Handle FirebaseException specifically
      if (e is FirebaseException) {
        switch (e.code) {
          case 'permission-denied':
            debugPrint('[FirebaseException] permission-denied - user may not have access to this data');
            break;
          case 'unavailable':
            debugPrint('[FirebaseException] unavailable - network is down or service unavailable');
            break;
          case 'deadline-exceeded':
            debugPrint('[FirebaseException] deadline-exceeded - operation took too long');
            break;
          case 'not-found':
            debugPrint('[FirebaseException] not-found - document or resource does not exist');
            break;
          case 'cancelled':
            debugPrint('[FirebaseException] cancelled - operation was cancelled');
            break;
          case 'aborted':
            debugPrint('[FirebaseException] aborted - operation was aborted');
            break;
          case 'quota-exceeded':
            debugPrint('[FirebaseException] quota-exceeded - quota limit exceeded');
            break;
          case 'network-error':
            debugPrint('[FirebaseException] network-error - network connection failed');
            break;
          default:
            debugPrint('[FirebaseException] ${e.code}: ${e.message}');
        }
      } else {
        // Fallback to string matching for other error types
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('permission-denied') || errorStr.contains('unauthorized')) {
          debugPrint('[Stream Error] Permission denied - user may not have access');
        } else if (errorStr.contains('unavailable') || 
                   errorStr.contains('network') || 
                   errorStr.contains('host') ||
                   errorStr.contains('timeout') ||
                   errorStr.contains('deadline')) {
          debugPrint('[Stream Error] Network error - no internet connection detected');
        } else if (errorStr.contains('cancelled') || errorStr.contains('abort')) {
          debugPrint('[Stream Error] Stream was cancelled');
        } else {
          debugPrint('[Stream Error] Unknown error: $e');
        }
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
    
    if (isOnline && !_auth.currentUser!.emailVerified) {
        throw Exception("Please verify your email address first.");
    }

    try {
      await _techService.updateOnlineStatus(_technician!.uid, isOnline);
      // Stream takes care of local update
    } catch (e) {
      debugPrint("Error updating online status: $e");
      rethrow;
    }
  }

  /// Create technician draft after OTP verification
  Future<void> createOnboardingDraft({required String phone}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _onboardingService.createTechnicianDraft(phone: phone);
      _currentOnboardingStep = OnboardingStep.basicDetails;
    } catch (e) {
      debugPrint("Error creating onboarding draft: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
    notifyListeners();
    
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
      notifyListeners();
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
    notifyListeners();
    
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
      notifyListeners();
    }
  }

  /// Save service selection during onboarding
  Future<void> saveServices({
    required String categoryId,
    required String categoryName,
    required List<String> skills,
  }) async {
    _isLoading = true;
    notifyListeners();
    
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
      notifyListeners();
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
    notifyListeners();
    
    try {
      await _onboardingService.submitApplication();
      _currentOnboardingStep = OnboardingStep.submitted;
      _isOnboardingComplete = true;
      
      await refreshTechnicianData();
    } catch (e) {
      debugPrint("Error submitting application: $e");
      rethrow;
    } finally {
      _isSubmittingApplication = false;
      _isLoading = false;
      notifyListeners();
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
        // Clean up temp file
        if (compressedFile != null && await compressedFile.exists()) {
          await compressedFile.delete().catchError((_) {});
        }
      }
    }
    
    throw lastError ?? Exception('Upload failed after $maxRetries attempts');
  }

  /// Fetch fresh technician data from server (not cache)
  /// Used for routing decisions to prevent state drift
  Future<Technician?> fetchFreshTechnicianData() async {
    final uid = _auth.currentUser?.uid;
    debugPrint('[FINAL VERIFY] Fetching fresh data for UID: $uid');
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
        debugPrint('[FINAL VERIFY ❌] Document does not exist');
        return null;
      }
      
      debugPrint('[FINAL VERIFY] Firestore raw: ${doc.data()}');
      
      final tech = Technician.fromFirestore(doc);
      
      debugPrint('[FINAL VERIFY] isKycComplete resolved = ${tech.isKycComplete}');
      
      return tech;
    } on SocketException catch (e) {
      debugPrint('[Network Error] No internet connection: $e');
      return null;
    } on TimeoutException catch (e) {
      debugPrint('[Network Error] Connection timeout: $e');
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        debugPrint('[Network Error] Firestore unavailable: ${e.message}');
      } else {
        debugPrint('[FINAL VERIFY ❌] Firebase error: $e');
      }
      return null;
    } catch (e, st) {
      debugPrint('[FINAL VERIFY ❌] Failure reason: $e');
      debugPrintStack(stackTrace: st);
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
        _isApproved = tech.isApproved;
        _isAdminApproved = tech.adminApproved;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error refreshing technician data: $e");
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
    notifyListeners();
    
    try {
      await _techService.updateSkills(uid, skills);
      await refreshTechnicianData();
    } catch (e) {
      debugPrint('Error updating skills: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _techSubscription?.cancel();
    await _auth.signOut();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _techSubscription?.cancel();
    super.dispose();
  }
}
