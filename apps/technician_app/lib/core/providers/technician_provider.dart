import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/technician_service.dart';
import '../services/onboarding_service.dart';
import '../services/image_compression_service.dart';
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
      
      _technician = tech;
      
      // Update onboarding state from technician data
      if (tech != null) {
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
      debugPrint("Error listening to tech data: $e");
      if (_isDisposed) return;
      _isLoading = false;
      notifyListeners();
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

  /// Submit the complete KYC application
  /// SECURITY: This method ONLY submits - protected fields like isApproved, rating,
  /// walletBalance, adminNotes are NEVER written by the client and can only be
  /// set by admin actions via Firestore rules
  Future<void> submitKycApplication() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _onboardingService.submitApplication();
      _currentOnboardingStep = OnboardingStep.submitted;
      _isOnboardingComplete = true;
      // SECURITY NOTE: isApproved is set by ADMIN only
      // Client NEVER writes isApproved, rating, walletBalance, or adminNotes
    } catch (e) {
      debugPrint("Error submitting application: $e");
      rethrow;
    } finally {
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
        
        // Compress image before upload
        compressedFile = await ImageCompressionService.compressImage(imageFile);
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

  /// Refresh technician data (e.g., after approval)
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
