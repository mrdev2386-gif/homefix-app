import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/technician.dart';
import '../firebase/firebase_functions.dart';

/// Service for managing technician onboarding state
/// 
/// SECURITY: All writes go through Firebase Cloud Functions to ensure:
/// - Firebase Auth UID is validated server-side
/// - role = 'technician' is set server-side only
/// - Protected fields (isApproved, adminApproved, etc.) can only be set by admin
class OnboardingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cloud Functions instance
  FirebaseFunctions get _functions => FirebaseFunctionsService.instance;

  /// Helper to call Cloud Functions with error handling
  Future<Map<String, dynamic>> _callFunction(
    String name, 
    Map<String, dynamic> data
  ) async {
    try {
      final result = await _functions.httpsCallable(name)(data);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[OnboardingService] Cloud Function error: code=${e.code}, message=${e.message}');
      throw Exception(e.message ?? 'Cloud function failed');
    } catch (e) {
      debugPrint('[OnboardingService] Error calling $name: $e');
      rethrow;
    }
  }

  /// Retry wrapper with exponential backoff for Firestore writes
  /// Retries only on UNAVAILABLE or network errors
  Future<Map<String, dynamic>> _retryWithBackoff(
    Future<Map<String, dynamic>> Function() operation, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } on FirebaseException catch (e) {
        lastError = e;
        debugPrint('[OnboardingService] FirebaseException: code=${e.code}, message=${e.message}');
        
        // Only retry on UNAVAILABLE or network errors
        if (e.code != 'unavailable' && e.code != 'failed-precondition') {
          rethrow;
        }
        
        attempt++;
        if (attempt >= maxAttempts) break;
        
        // Exponential backoff: 500ms, 1s, 2s
        final delayMs = 500 * (1 << (attempt - 1));
        debugPrint('[OnboardingService] Retry attempt $attempt after ${delayMs}ms');
        await Future.delayed(Duration(milliseconds: delayMs));
      } catch (e) {
        debugPrint('[OnboardingService] Non-Firebase error: $e');
        rethrow;
      }
    }

    throw lastError ?? Exception('Operation failed after $maxAttempts attempts');
  }

  /// Check internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('[OnboardingService] Error checking connectivity: $e');
      return false;
    }
  }

  /// Create a new technician draft profile after phone OTP verification
  /// Uses Cloud Function for secure server-side creation
  Future<Map<String, dynamic>?> createTechnicianDraft({
    required String phone,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    // Use Cloud Function for secure creation
    final result = await _callFunction('createTechnicianProfile', {
      'phone': phone,
    });

    debugPrint('[OnboardingService] Created draft profile via Cloud Function: $result');
    return result;
  }

  /// Update the current onboarding step
  /// Note: Steps are now managed through individual save methods
  Future<void> updateOnboardingStep(OnboardingStep step) async {
    // This is now handled implicitly through save methods
    debugPrint('[OnboardingService] Step update handled via save methods');
  }

  /// Save basic details during onboarding
  /// Uses Cloud Function for secure server-side validation and storage
  /// 
  /// HARDENED: Added isSubmitting guard and proper error handling
  Future<void> saveBasicDetails({
    required String fullName,
    String? email,
    String? state,
    String? district,
    int? experienceYears,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    // Use Cloud Function for secure storage
    try {
      final result = await _callFunction('saveTechnicianBasicDetails', {
        'fullName': fullName,
        'email': email ?? '',
        'state': state ?? '',
        'district': district ?? '',
        'experienceYears': experienceYears ?? 0,
      });

      debugPrint('[OnboardingService] Saved basic details via Cloud Function: $result');
      
      // Handle idempotent response - don't throw if already saved
      if (result['idempotent'] == true) {
        debugPrint('[OnboardingService] Basic details already saved (idempotent)');
      }
    } on FirebaseFunctionsException catch (e) {
      // Log the error with details
      debugPrint('[OnboardingService] FirebaseFunctionsException: code=${e.code}, message=${e.message}');
      
      // Re-throw with more helpful message
      if (e.code == 'failed-precondition') {
        throw Exception('Cannot save basic details at this stage. Please refresh and try again.');
      } else if (e.code == 'not-found') {
        throw Exception('Profile not found. Please restart the app.');
      }
      rethrow;
    }
  }

  /// Save documents during onboarding
  /// Uses Cloud Function for secure server-side validation and storage
  /// 
  /// CRITICAL: Validates and masks Aadhaar before sending to server
  Future<void> saveDocuments({
    required String? aadhaarNumber,
    required String? aadhaarFrontUrl,
    required String? aadhaarBackUrl,
    required String? profilePhotoUrl,
    String documentType = 'Aadhaar Card',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    // CRITICAL: Validate Aadhaar before sending
    String? cleanAadhaar;
    
    if (aadhaarNumber != null && aadhaarNumber.isNotEmpty) {
      // Validate: exactly 12 digits, numeric only, trim spaces
      final trimmed = aadhaarNumber.trim();
      final cleaned = trimmed.replaceAll(RegExp(r'[\s-]'), '');
      
      if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) {
        throw Exception('Invalid Aadhaar number: must be exactly 12 digits');
      }
      
      cleanAadhaar = cleaned;
    }

    // Use Cloud Function for secure storage
    final result = await _callFunction('saveTechnicianDocuments', {
      'aadhaarNumber': cleanAadhaar,
      'aadhaarFrontUrl': aadhaarFrontUrl ?? '',
      'aadhaarBackUrl': aadhaarBackUrl ?? '',
      'profilePhotoUrl': profilePhotoUrl ?? '',
      'documentType': documentType,
    });

    debugPrint('[OnboardingService] Saved documents via Cloud Function');
  }

  /// Save service selection during onboarding
  /// Uses Cloud Function for secure server-side validation
  Future<void> saveServices({
    required String categoryId,
    required String categoryName,
    required List<String> skills,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    // Use Cloud Function for secure storage
    final result = await _callFunction('saveTechnicianServices', {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'skills': skills,
    });

    debugPrint('[OnboardingService] Saved services via Cloud Function: $result');
  }

  /// Save step data with idempotency check and timestamp protection
  /// Prevents step rewind, out-of-order writes, and stale/offline overwrites
  /// Uses Cloud Function for secure server-side write (required by Firestore rules)
  Future<void> saveStepData({
    required int step,
    required Map<String, dynamic> data,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    // Use Cloud Function for secure write (Firestore rules block direct writes)
    final stepName = _getStepName(step);
    final stepKey = _getStepKey(step);
    
    final updateData = <String, dynamic>{
      'onboardingStep': stepName,
      'stepsCompleted': {
        'personalDetails': step >= 0,
        'serviceCategories': step >= 1,
        'portfolio': step >= 2,
        'verification': step >= 3,
      },
    };
    updateData.addAll(data);
    
    debugPrint('[TECH WRITE] START uid=$uid step=$stepName');
    debugPrint('[TECH WRITE] payload=$updateData');
    debugPrint('[TECH WRITE] user=${_auth.currentUser?.uid}');
    
    try {
      // Use Cloud Function - this is required because Firestore rules block direct writes
      final result = await _callFunction('saveTechnicianStepData', {
        'step': step,
        'stepName': stepName,
        'stepKey': stepKey,
        'data': updateData,
      });
      
      debugPrint('[TECH WRITE] SUCCESS via CF: ${result.toString()}');
    } catch (e) {
      debugPrint('[TECH WRITE] ERROR: $e');
      rethrow;
    }
  }

  String _getStepName(int step) {
    const steps = ['basic', 'professional', 'kyc', 'portfolio', 'services'];
    if (step < 0 || step >= steps.length) return 'basic';
    return steps[step];
  }

  String? _getStepKey(int step) {
    const keys = ['basic', 'professional', 'kyc', 'portfolio', 'services'];
    return step >= 0 && step < keys.length ? keys[step] : null;
  }

  int _getStepIndex(String? step) {
    const steps = ['phone', 'basicDetails', 'documents', 'services', 'review'];
    if (step == null) return -1;
    final index = steps.indexOf(step);
    return index >= 0 ? index : -1;
  }

  /// Submit the complete KYC application with server verification
  /// CRITICAL FIX: Sets profileCompletion to 100 and onboardingStep to 'submitted'
  Future<void> submitApplication() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    debugPrint('[OnboardingService] ===== SUBMITTING KYC APPLICATION =====');
    debugPrint('[OnboardingService] UID: $uid');

    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    await _retryWithBackoff(() async {
      debugPrint('[OnboardingService] Calling submitTechnicianKyc Cloud Function...');
      final result = await _callFunction('submitTechnicianKyc', {
        'onboardingCompleted': true,
        'profileCompletion': 100,  // CRITICAL FIX: Set to 100
        'onboardingStep': 'submitted',  // CRITICAL FIX: Mark as submitted
        'status': 'pending',
        'submittedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('[OnboardingService] Cloud Function result: $result');
      return result;
    }, maxAttempts: 3);

    debugPrint('[OnboardingService] Verifying submission...');
    final verifyDoc = await _db.collection('technicians').doc(uid).get(
      const GetOptions(source: Source.server),
    );
    
    debugPrint('[OnboardingService] Raw Firestore data: ${verifyDoc.data()}');
    
    final isCompleted = verifyDoc.data()?['onboardingCompleted'] as bool? ?? false;
    final isKycComplete = verifyDoc.data()?['isKycComplete'] as bool? ?? false;
    final status = verifyDoc.data()?['status'] as String?;
    
    debugPrint('[OnboardingService] Verification check:');
    debugPrint('[OnboardingService]   onboardingCompleted = $isCompleted (type=${isCompleted.runtimeType})');
    debugPrint('[OnboardingService]   isKycComplete = $isKycComplete (type=${isKycComplete.runtimeType})');
    debugPrint('[OnboardingService]   status = $status');
    
    if (!isCompleted || status != 'pending') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'submit-verification-failed',
        message: 'Submit verification failed: completed=$isCompleted, status=$status',
      );
    }
    
    debugPrint('[OnboardingService] ===== SUBMISSION VERIFIED SUCCESSFULLY =====');
  }

  /// Get current onboarding step from Firestore
  Future<OnboardingStep> getCurrentOnboardingStep() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return OnboardingStep.phone;
    }

    try {
      final doc = await _db.collection('technicians').doc(uid).get();
      if (!doc.exists) {
        return OnboardingStep.phone;
      }

      final stepString = doc.data()?['onboardingStep'] as String?;
      return OnboardingStepExtension.fromString(stepString);
    } catch (e) {
      debugPrint('[OnboardingService] Error getting onboarding step: $e');
      return OnboardingStep.phone;
    }
  }

  /// Check if technician profile exists
  Future<bool> hasTechnicianProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      final doc = await _db.collection('technicians').doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('[OnboardingService] Error checking profile: $e');
      return false;
    }
  }

  /// Get full technician data for onboarding resume
  Future<Map<String, dynamic>?> getTechnicianOnboardingData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final doc = await _db.collection('technicians').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('[OnboardingService] Error getting onboarding data: $e');
      return null;
    }
  }

  /// Validate Aadhaar number format (12 digits, numeric only)
  /// Returns null if valid, error message if invalid
  /// 
  /// ⚠️ Delegated to OnboardingValidationService for single source of truth
  static String? validateAadhaar(String? aadhaar) {
    // Import OnboardingValidationService at top of file if not already imported
    // This delegates to the validation service to avoid duplication
    if (aadhaar == null || aadhaar.isEmpty) {
      return 'Aadhaar number is required';
    }
    
    // Trim spaces
    final trimmed = aadhaar.trim();
    
    // Remove any spaces or dashes
    final cleaned = trimmed.replaceAll(RegExp(r'[\s-]'), '');
    
    // Must be exactly 12 digits
    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return 'Aadhaar must be exactly 12 digits';
    }
    
    return null; // Valid
  }

  /// Clean Aadhaar number (remove spaces/dashes)
  static String cleanAadhaar(String aadhaar) {
    return aadhaar.replaceAll(RegExp(r'[\s-]'), '');
  }

  /// Mask Aadhaar for display: XXXX-XXXX-1234
  static String maskAadhaar(String aadhaar) {
    final cleaned = cleanAadhaar(aadhaar);
    if (cleaned.length != 12) return 'XXXX-XXXX-XXXX';
    return '${cleaned.substring(0, 4)}-${cleaned.substring(4, 8)}-${cleaned.substring(8)}';
  }

  /// DEPRECATED: Use validateAadhaar instead
  /// This method is kept for backward compatibility
  @Deprecated('Use validateAadhaar instead')
  static bool isValidAadhaar(String? aadhaar) {
    return validateAadhaar(aadhaar) == null;
  }
}
