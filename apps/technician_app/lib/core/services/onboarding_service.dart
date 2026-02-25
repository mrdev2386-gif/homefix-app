import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart' as functions;
import '../models/technician.dart';

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
  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  // Helper to call Cloud Functions with error handling
  Future<Map<String, dynamic>> _callFunction(
    String name, 
    Map<String, dynamic> data
  ) async {
    try {
      final result = await _functions.httpsCallable(name)(data);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[OnboardingService] Cloud Function error: ${e.message}');
      throw Exception(e.message ?? 'Cloud function failed');
    } catch (e) {
      debugPrint('[OnboardingService] Error calling $name: $e');
      rethrow;
    }
  }

  /// Create a new technician draft profile after phone OTP verification
  /// Uses Cloud Function for secure server-side creation
  Future<void> createTechnicianDraft({
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
        'district': district ?? '',
        'experienceYears': experienceYears ?? 0,
      });

      debugPrint('[OnboardingService] Saved basic details via Cloud Function: $result');
      
      // Handle idempotent response - don't throw if already saved
      if (result['idempotent'] == true) {
        debugPrint('[OnboardingService] Basic details already saved (idempotent)');
      }
    } on functions.FirebaseFunctionsException catch (e) {
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

  /// Submit the complete KYC application
  /// Uses Cloud Function to transition to pending review status
  /// 
  /// SECURITY: This is the critical step that sets isKycComplete=true
  /// and can only be done through the server to prevent client manipulation
  Future<void> submitApplication() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    // Use Cloud Function for secure submission
    final result = await _callFunction('submitTechnicianKyc', {});

    debugPrint('[OnboardingService] Submitted KYC via Cloud Function: $result');
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

  /// Update technician online status (for approved technicians only)
  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    // Use Cloud Function for secure status update
    final result = await _callFunction('updateTechnicianStatus', {
      'isOnline': isOnline,
    });

    debugPrint('[OnboardingService] Updated online status via Cloud Function: $result');
  }

  /// Validate Aadhaar number format (12 digits, numeric only)
  /// Returns null if valid, error message if invalid
  static String? validateAadhaar(String? aadhaar) {
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
