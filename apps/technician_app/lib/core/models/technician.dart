import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Onboarding step enum for technician KYC flow
/// Follows strict order: Phone → OTP → Basic Details → Documents → Services → Review → Submit
enum OnboardingStep {
  phone,          // Entry gate - phone number entry
  otp,            // OTP verification
  basicDetails,   // Full name, email, district, experience
  documents,      // Aadhaar, profile photo
  services,       // Service categories selection
  review,         // Review all information
  submitted,      // Submitted - awaiting admin approval
  approved,       // Fully approved - can access dashboard
}

extension OnboardingStepExtension on OnboardingStep {
  String get displayName {
    switch (this) {
      case OnboardingStep.phone:
        return 'Phone';
      case OnboardingStep.otp:
        return 'Verification';
      case OnboardingStep.basicDetails:
        return 'Basic Details';
      case OnboardingStep.documents:
        return 'Documents';
      case OnboardingStep.services:
        return 'Services';
      case OnboardingStep.review:
        return 'Review';
      case OnboardingStep.submitted:
        return 'Submitted';
      case OnboardingStep.approved:
        return 'Approved';
    }
  }

  int get stepIndex {
    return OnboardingStep.values.indexOf(this);
  }

  static OnboardingStep fromString(String? value) {
    if (value == null) return OnboardingStep.phone;
    return OnboardingStep.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OnboardingStep.phone,
    );
  }
}

class Technician {
  final String uid;
  final String name;
  final String phone;
  final String? alternatePhone;
  final String email;
  final String? photoUrl;
  final List<String> skills;
  final bool isOnline;
  final bool isVerified;
  final double avgRating;
  final int totalRatings;
  final Map<String, int> ratingBreakdown;
  final int jobsDone;
  final double? lat;
  final double? lng;
  final String? referralCode;
  final String? kycStatus;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // KYC Fields - New additions for hardened flow
  final String? onboardingStep;
  final bool isKycComplete;
  final bool isApproved;
  final bool adminApproved; // Additional approval flag for service management
  final bool profileApproved; // New field for profile approval workflow
  final bool profileApprovalRequested; // Auto-set when profile reaches 100%
  final bool profileRejected; // Set when admin rejects profile
  /// Indicates if the technician has completed onboarding (legacy/hardening flag)
  /// This mirrors the Firestore field `onboardingCompleted` and is used in
  /// routing logic (see `main.dart`).
  final bool onboardingCompleted;
  final String? aadhaarNumber;
  final String? aadhaarFrontUrl;
  final String? aadhaarBackUrl;
  final String? profilePhotoUrl;
  final String? state;
  final String? district;
  final int? experienceYears;
  final List<String>? primaryCategoryId;
  final String? primaryCategoryName;
  final String? documentType;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? bio;
  final List<String>? serviceAreas;
  final TimeOfDay? workStartTime;
  final TimeOfDay? workEndTime;
  final bool hasOwnTools;
  final int? basePrice;
  final int? visitingCharge;
  final int? maxTravelDistance;
  final bool emergencyServiceAvailable;
  
  // 🔵 Production onboarding fields
  final List<String>? languagePreferences;
  final String? referralCodeUsed;
  final String? panNumber;
  final String? accountType;
  final String? payoutPreference;
  final int? maxDailyJobs;
  final bool? dynamicPricingAllowed;
  final Map<String, dynamic>? stepsCompleted;
  final int? profileCompletion;
  
  // Bank details fields - PRODUCTION-SAFE VERIFICATION
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolderName;
  
  // NEW: Production-safe bank verification fields
  final String? bankVerificationStatus; // not_submitted, verifying, verified, failed
  final bool? bankVerified; // true when verified
  final String? bankVerificationMessage; // Error message or success message
  final DateTime? bankVerifiedAt; // When verification completed
  final String? fundAccountId; // Razorpay fund account ID
  final String? razorpayContactId; // Razorpay contact ID
  
  // DEPRECATED: Old bank status field (kept for backward compatibility)
  final String? bankStatus; // DEPRECATED - use bankVerificationStatus instead
  final String? bankRejectionReason; // DEPRECATED - use bankVerificationMessage instead
  final DateTime? bankSubmittedAt; // DEPRECATED

  // Custom services added by technician
  final List<String>? customServices;
  
  // Step 4 professional fields
  final String? experienceDescription;
  final List<String>? tools;
  final String? workPreference;

  Technician({
    required this.uid,
    required this.name,
    required this.phone,
    this.alternatePhone,
    required this.email,
    this.photoUrl,
    required this.skills,
    required this.isOnline,
    required this.isVerified,
    required this.avgRating,
    required this.totalRatings,
    required this.ratingBreakdown,
    required this.jobsDone,
    this.lat,
    this.lng,
    this.referralCode,
    this.kycStatus,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.onboardingStep,
    this.isKycComplete = false,
    this.isApproved = false,
    this.adminApproved = false, // Default to false - must be approved to manage services
    this.profileApproved = false, // Default to false - must be approved by admin
    this.profileApprovalRequested = false, // Default to false - set when profile reaches 100%
    this.profileRejected = false, // Default to false - set when admin rejects
    this.onboardingCompleted = false,
    this.aadhaarNumber,
    this.aadhaarFrontUrl,
    this.aadhaarBackUrl,
    this.profilePhotoUrl,
    this.state,
    this.district,
    this.experienceYears,
    this.primaryCategoryId,
    this.primaryCategoryName,
    this.documentType,
    this.gender,
    this.dateOfBirth,
    this.bio,
    this.serviceAreas,
    this.workStartTime,
    this.workEndTime,
    this.hasOwnTools = false,
    this.basePrice,
    this.visitingCharge,
    this.maxTravelDistance,
    this.emergencyServiceAvailable = false,
    this.languagePreferences,
    this.referralCodeUsed,
    this.panNumber,
    this.accountType,
    this.payoutPreference,
    this.maxDailyJobs,
    this.dynamicPricingAllowed,
    this.stepsCompleted,
    this.profileCompletion,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolderName,
    this.bankVerificationStatus,
    this.bankVerified,
    this.bankVerificationMessage,
    this.bankVerifiedAt,
    this.fundAccountId,
    this.razorpayContactId,
    this.bankStatus, // DEPRECATED
    this.bankRejectionReason, // DEPRECATED
    this.bankSubmittedAt, // DEPRECATED
    this.customServices,
    this.experienceDescription,
    this.tools,
    this.workPreference,
  });

  factory Technician.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic>? geo = data['geo'];

    // Convert skills string to list if necessary
    dynamic skillsData = data['skills'];
    List<String> skillsList = [];
    if (skillsData is String) {
      skillsList = skillsData.split(',').map((e) => e.trim()).toList();
    } else if (skillsData is List) {
      skillsList = List<String>.from(skillsData);
    }

    // Rating breakdown map
    Map<String, int> breakdown = {};
    if (data['ratingBreakdown'] != null) {
      (data['ratingBreakdown'] as Map).forEach((key, value) {
        breakdown[key.toString()] = (value as num).toInt();
      });
    } else {
      breakdown = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0};
    }

    // PART 2: PROFILE NULL-SAFE MAPPING
    final fullName = (data['fullName'] ?? data['name'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final rawStepsMap = (data['stepsCompleted'] ?? {}) as Map<String, dynamic>;

    debugPrint('[TECH PROFILE] fullName=$fullName email=$email');

    // Handle legacy status field - normalize "active" to "approved"
    String status = data['status'] ?? 'pending';
    if (status == 'active') {
      status = 'approved';
      debugPrint('[STATUS NORMALIZATION] Document ${doc.id}: active → approved');
    }
    String? kycStatus = data['kycStatus'];

    // NORMALIZE STEP FIELDS: Map legacy fields to normalized structure with enhanced safety
    final normalizedStepsMap = <String, dynamic>{};
    
    // Map legacy fields to normalized fields with multiple fallback sources
    normalizedStepsMap['personalDetails'] = rawStepsMap['personalDetails'] ?? rawStepsMap['basic'] ?? false;
    normalizedStepsMap['serviceCategories'] = rawStepsMap['serviceCategories'] ?? rawStepsMap['professional'] ?? false;
    normalizedStepsMap['portfolio'] = rawStepsMap['portfolio'] ?? rawStepsMap['bank'] ?? false;
    normalizedStepsMap['verification'] = rawStepsMap['verification'] ?? rawStepsMap['kyc'] ?? false;
    
    // Enhanced safety: Check for any remaining legacy fields and log them
    final legacyFields = ['basic', 'professional', 'kyc', 'services', 'bank']
        .where((key) => rawStepsMap.containsKey(key))
        .toList();
    
    if (legacyFields.isNotEmpty) {
      debugPrint('[LEGACY FIELDS DETECTED] Document ${doc.id} has legacy fields: ${legacyFields.join(", ")}');
    }
    
    debugPrint('[STEP NORMALIZATION] Raw: $rawStepsMap');
    debugPrint('[STEP NORMALIZATION] Normalized: $normalizedStepsMap');
    
    // Calculate profile completion from normalized fields
    int completedSteps = 0;
    if (normalizedStepsMap['personalDetails'] == true) completedSteps++;
    if (normalizedStepsMap['serviceCategories'] == true) completedSteps++;
    if (normalizedStepsMap['portfolio'] == true) completedSteps++;
    if (normalizedStepsMap['verification'] == true) completedSteps++;
    
    final calculatedCompletion = (completedSteps * 100) ~/ 4;
    debugPrint('[PROFILE COMPLETION] Calculated from normalized: $calculatedCompletion% ($completedSteps/4)');
    
    // Update Firestore with normalized structure if needed
    if (legacyFields.isNotEmpty || status != data['status'] || calculatedCompletion != (data['profileCompletion'] ?? 0)) {
      _updateFirestoreWithNormalizedSteps(doc.id, normalizedStepsMap, calculatedCompletion, status);
    }
    
    // SELF-HEALING KYC RESOLUTION - SINGLE SOURCE OF TRUTH
    // Check multiple sources to determine if KYC is truly complete
    final bool resolvedKyc =
        data['isKycComplete'] == true ||
        data['onboardingCompleted'] == true ||
        (normalizedStepsMap['verification'] == true &&
         normalizedStepsMap['portfolio'] == true);  // Only check required normalized steps
    
    // Legacy data migration: map 'bank' to 'portfolio' - REMOVED (handled in normalization above)
    
    debugPrint('[FINAL HARDEN] resolvedKyc=$resolvedKyc');
    
    // Use resolved value as SINGLE source of truth
    bool isKycComplete = resolvedKyc;
    bool profileApprovalRequested = data['profileApprovalRequested'] ?? false;
    bool profileRejected = data['profileRejected'] ?? false;
    
    // SECURITY FIX: Use SINGLE approval source - only status == "approved"
    bool isApproved = (status == "approved");
    bool adminApproved = isApproved; // adminApproved mirrors isApproved
    bool profileApproved = isApproved; // profileApproved mirrors isApproved
    
    // Legacy conversion: if kycStatus is 'approved', set approval flags
    if (kycStatus == 'approved') {
      isApproved = true;
      adminApproved = true;
      profileApproved = true;
    }
    
    // FIX 2: Onboarding step sanity guard & safe value getter
    String? rawStep = data['onboardingStep'];
    String safeStepStr;
    if (rawStep == null) {
      safeStepStr = OnboardingStep.phone.name;
    } else {
      final stepEnum = OnboardingStepExtension.fromString(rawStep);
      final index = stepEnum.stepIndex;
      
      if (index < OnboardingStep.basicDetails.stepIndex) {
        // If they created a profile document, minimum logical step is basicDetails
        safeStepStr = OnboardingStep.basicDetails.name;
      } else if (index > OnboardingStep.review.stepIndex && !isKycComplete) {
        // Prevent bypassing to submitted without actually finishing
        safeStepStr = OnboardingStep.review.name;
      } else {
        safeStepStr = stepEnum.name;
      }
    }

    return Technician(
      uid: data['uid'] ?? doc.id,
      name: fullName,
      phone: data['phone'] ?? data['phoneNumber'] ?? '',
      alternatePhone: data['alternatePhone'],
      email: email,
      photoUrl: data['photoUrl'] ?? data['profilePhotoUrl'],
      skills: skillsList,
      isOnline: data['isOnline'] ?? false,
      isVerified: data['isVerified'] ?? false,
      avgRating: ((data['avgRating'] ?? data['rating'] ?? 4.5) as num).toDouble(),
      totalRatings: data['totalRatings'] ?? data['reviewCount'] ?? 0,
      ratingBreakdown: breakdown,
      jobsDone: data['jobsDone'] ?? 0,
      lat: geo != null ? (geo['lat'] as num?)?.toDouble() : null,
      lng: geo != null ? (geo['lng'] as num?)?.toDouble() : null,
      referralCode: data['referralCode'],
      kycStatus: kycStatus,
      status: status,
      rejectionReason: data['rejectionReason'] ?? data['suspensionReason'] ?? data['kyc']?['rejectionReason'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
      onboardingStep: safeStepStr,
      isKycComplete: isKycComplete,
      isApproved: isApproved,
      adminApproved: adminApproved,
      profileApproved: profileApproved,
      profileApprovalRequested: profileApprovalRequested,
      profileRejected: profileRejected,
      onboardingCompleted: data['onboardingCompleted'] == true,
      aadhaarNumber: data['aadhaarNumber'],
      aadhaarFrontUrl: data['aadhaarFrontUrl'],
      aadhaarBackUrl: data['aadhaarBackUrl'],
      profilePhotoUrl: data['profilePhotoUrl'],
      state: data['state']?.toString(),
      district: data['district']?.toString(),
      experienceYears: data['experienceYears'] as int?,
      primaryCategoryId: (data['primaryCategoryId'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      primaryCategoryName: data['primaryCategoryName']?.toString(),
      documentType: data['documentType']?.toString(),
      gender: data['gender']?.toString(),
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] is Timestamp
              ? (data['dateOfBirth'] as Timestamp).toDate()
              : data['dateOfBirth'] is String
                  ? DateTime.tryParse(data['dateOfBirth'])
                  : null)
          : null,
      bio: data['bio']?.toString(),
      serviceAreas: (data['serviceAreas'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      workStartTime: data['workStartTime'] != null
          ? TimeOfDay(
              hour: (data['workStartTime'] as Map)['hour'] ?? 0,
              minute: (data['workStartTime'] as Map)['minute'] ?? 0,
            )
          : null,
      workEndTime: data['workEndTime'] != null
          ? TimeOfDay(
              hour: (data['workEndTime'] as Map)['hour'] ?? 0,
              minute: (data['workEndTime'] as Map)['minute'] ?? 0,
            )
          : null,
      hasOwnTools: data['hasOwnTools'] ?? false,
      basePrice: data['basePrice'],
      visitingCharge: data['visitingCharge'],
      maxTravelDistance: data['maxTravelDistance'],
      emergencyServiceAvailable: data['emergencyServiceAvailable'] ?? false,
      languagePreferences: (data['languagePreferences'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      referralCodeUsed: data['referralCodeUsed']?.toString(),
      panNumber: data['panNumber']?.toString(),
      accountType: data['accountType']?.toString(),
      payoutPreference: data['payoutPreference']?.toString(),
      maxDailyJobs: data['maxDailyJobs'],
      dynamicPricingAllowed: data['dynamicPricingAllowed'],
      stepsCompleted: normalizedStepsMap,
      profileCompletion: data['profileCompletion'] as int?,
    // Bank details - root level only (no legacy fallback)
    bankName: data['bankName']?.toString(),
    accountNumber: data['accountNumber']?.toString(),
    ifscCode: data['ifscCode']?.toString(),
    accountHolderName: data['accountHolderName']?.toString(),
    
    // NEW: Production-safe bank verification fields
    bankVerificationStatus: data['bankVerificationStatus']?.toString(),
    bankVerified: data['bankVerified'] as bool?,
    bankVerificationMessage: data['bankVerificationMessage']?.toString(),
    bankVerifiedAt: data['bankVerifiedAt'] != null
        ? (data['bankVerifiedAt'] as Timestamp).toDate()
        : null,
    fundAccountId: data['fundAccountId']?.toString(),
    razorpayContactId: data['razorpayContactId']?.toString(),
    
    // DEPRECATED: Keep for backward compatibility
    bankStatus: data['bankStatus']?.toString(),
    bankRejectionReason: data['bankRejectionReason']?.toString(),
    bankSubmittedAt: data['bankSubmittedAt'] != null
        ? (data['bankSubmittedAt'] as Timestamp).toDate()
        : null,
      customServices: (data['customServices'] as List?)?.map((e) => e.toString()).toList(),
      experienceDescription: data['experienceDescription']?.toString(),
      tools: (data['tools'] as List?)?.map((e) => e.toString()).toList(),
      workPreference: data['workPreference']?.toString(),
    );
  }

  /// Update Firestore with normalized step structure
  static void _updateFirestoreWithNormalizedSteps(
    String docId, 
    Map<String, dynamic> normalizedSteps, 
    int calculatedCompletion,
    String normalizedStatus
  ) {
    // Update Firestore asynchronously to normalize legacy data
    FirebaseFirestore.instance
        .collection('technicians')
        .doc(docId)
        .update({
      'stepsCompleted': normalizedSteps,
      'profileCompletion': calculatedCompletion,
      'status': normalizedStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'normalizedAt': FieldValue.serverTimestamp(),
    }).catchError((error) {
      debugPrint('[STEP NORMALIZATION] Failed to update Firestore: $error');
    });
    
    debugPrint('[STEP NORMALIZATION] Updated Firestore: completion=$calculatedCompletion%, status=$normalizedStatus');
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      if (alternatePhone != null) 'alternatePhone': alternatePhone,
      'email': email,
      'photoUrl': photoUrl,
      'skills': skills,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'avgRating': avgRating,
      'totalRatings': totalRatings,
      'ratingBreakdown': ratingBreakdown,
      'jobsDone': jobsDone,
      'geo': lat != null && lng != null ? {'lat': lat, 'lng': lng} : null,
      'referralCode': referralCode,
      'kycStatus': kycStatus,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'onboardingStep': onboardingStep,
      'isKycComplete': isKycComplete,
      'isApproved': isApproved,
      'adminApproved': adminApproved,
      'profileApproved': profileApproved,
      'profileApprovalRequested': profileApprovalRequested,
      'profileRejected': profileRejected,
      'onboardingCompleted': onboardingCompleted,
      'aadhaarNumber': aadhaarNumber,
      'aadhaarFrontUrl': aadhaarFrontUrl,
      'aadhaarBackUrl': aadhaarBackUrl,
      'profilePhotoUrl': profilePhotoUrl,
      'state': state,
      'district': district,
      'experienceYears': experienceYears,
      'primaryCategoryId': primaryCategoryId,
      'primaryCategoryName': primaryCategoryName,
      'documentType': documentType,
      'gender': gender,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'bio': bio,
      'serviceAreas': serviceAreas,
      'workStartTime': workStartTime != null
          ? {'hour': workStartTime!.hour, 'minute': workStartTime!.minute}
          : null,
      'workEndTime': workEndTime != null
          ? {'hour': workEndTime!.hour, 'minute': workEndTime!.minute}
          : null,
      'hasOwnTools': hasOwnTools,
      'basePrice': basePrice,
      'visitingCharge': visitingCharge,
      'maxTravelDistance': maxTravelDistance,
      'emergencyServiceAvailable': emergencyServiceAvailable,
      if (languagePreferences != null) 'languagePreferences': languagePreferences,
      if (referralCodeUsed != null) 'referralCodeUsed': referralCodeUsed,
      if (panNumber != null) 'panNumber': panNumber,
      if (accountType != null) 'accountType': accountType,
      if (payoutPreference != null) 'payoutPreference': payoutPreference,
      if (maxDailyJobs != null) 'maxDailyJobs': maxDailyJobs,
      if (dynamicPricingAllowed != null) 'dynamicPricingAllowed': dynamicPricingAllowed,
      if (stepsCompleted != null) 'stepsCompleted': stepsCompleted,
      if (profileCompletion != null) 'profileCompletion': profileCompletion,
      if (bankName != null) 'bankName': bankName,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (ifscCode != null) 'ifscCode': ifscCode,
      if (accountHolderName != null) 'accountHolderName': accountHolderName,
      if (bankVerificationStatus != null) 'bankVerificationStatus': bankVerificationStatus,
      if (bankVerified != null) 'bankVerified': bankVerified,
      if (bankVerificationMessage != null) 'bankVerificationMessage': bankVerificationMessage,
      if (bankVerifiedAt != null) 'bankVerifiedAt': Timestamp.fromDate(bankVerifiedAt!),
      if (fundAccountId != null) 'fundAccountId': fundAccountId,
      if (razorpayContactId != null) 'razorpayContactId': razorpayContactId,
      if (bankStatus != null) 'bankStatus': bankStatus, // DEPRECATED
      if (bankRejectionReason != null) 'bankRejectionReason': bankRejectionReason, // DEPRECATED
      if (bankSubmittedAt != null) 'bankSubmittedAt': Timestamp.fromDate(bankSubmittedAt!), // DEPRECATED
      if (customServices != null) 'customServices': customServices,
      if (experienceDescription != null) 'experienceDescription': experienceDescription,
      if (tools != null) 'tools': tools,
      if (workPreference != null) 'workPreference': workPreference,
    };
  }
  
  /// Get current onboarding step as enum
  OnboardingStep get currentOnboardingStep {
    return OnboardingStepExtension.fromString(onboardingStep);
  }
  
  /// Safe computed full name (prevents null issues)
  String get fullName => name.isNotEmpty ? name : 'Technician';
  
  /// Check if technician can access dashboard
  bool get canAccessDashboard {
    return isKycComplete && status == "approved";
  }
  
  /// Check if technician can add/edit services
  /// SECURITY: Requires profileCompletion == 100% AND status == "approved" ONLY
  bool get canManageServices {
    print("[TECH STATUS] ${status}");
    print("[PROFILE COMPLETION] ${getProfileCompletion()}");
    print("[SERVICE ALLOWED] ${status == 'approved'}");
    return getProfileCompletion() == 100 && status == "approved";
  }
  
  /// Check if technician is in onboarding process
  bool get isInOnboarding {
    return !isKycComplete;
  }
  
  /// Check if technician is under review
  bool get isUnderReview {
    return isKycComplete && status != "approved";
  }

  /// Get profile completion percentage
  /// SECURITY: ALWAYS calculate dynamically - never use stored values
  /// Only required steps count: personalDetails, serviceCategories, portfolio, verification
  /// FIX #2: If admin approved, force 100% completion
  int getProfileCompletion() {
    // FIX #2: If technician is approved by admin, always show 100%
    if (status == "approved") {
      return 100;
    }
    
    // SECURITY: Always calculate dynamically, never trust stored values
    // Calculate based on required steps only - NORMALIZED FIELDS
    final stepsMap = stepsCompleted ?? {};
    int completedRequiredSteps = 0;
    const int totalRequiredSteps = 4; // personalDetails, serviceCategories, portfolio, verification
    
    // Check required steps only - NORMALIZED FIELD NAMES
    if (stepsMap['personalDetails'] == true) {
      completedRequiredSteps++;
    }
    
    if (stepsMap['serviceCategories'] == true) {
      completedRequiredSteps++;
    }
    
    if (stepsMap['portfolio'] == true) {
      completedRequiredSteps++;
    }
    
    if (stepsMap['verification'] == true) {
      completedRequiredSteps++;
    }
    
    final completion = (completedRequiredSteps * 100) ~/ totalRequiredSteps;
    print("[PROFILE COMPLETION] Calculated: $completion% ($completedRequiredSteps/$totalRequiredSteps)");
    
    return completion;
  }

  /// Get bank verification status (production-safe)
  String getBankVerificationStatus() {
    // Use new field if available, fallback to old field for backward compatibility
    if (bankVerificationStatus != null) {
      return bankVerificationStatus!;
    }
    
    // Map old bankStatus to new format
    switch (bankStatus) {
      case 'pending':
        return 'verifying';
      case 'approved':
        return 'verified';
      case 'rejected':
        return 'failed';
      case 'not_submitted':
      default:
        return 'not_submitted';
    }
  }

  /// Check if bank account is verified (production-safe)
  bool isBankVerified() {
    // Use new field if available
    if (bankVerified != null) {
      return bankVerified!;
    }
    
    // Fallback to old field
    return bankStatus == 'approved';
  }

  /// Check if user can resubmit bank details
  bool canResubmitBankDetails() {
    final status = getBankVerificationStatus();
    return status == 'failed' || status == 'not_submitted';
  }

  /// Get bank verification message
  String? getBankVerificationMessage() {
    // Use new field if available, fallback to old field
    return bankVerificationMessage ?? bankRejectionReason;
  }


  Technician copyWith({
    String? uid,
    String? name,
    String? phone,
    String? alternatePhone,
    String? email,
    String? photoUrl,
    List<String>? skills,
    bool? isOnline,
    bool? isVerified,
    double? avgRating,
    int? totalRatings,
    Map<String, int>? ratingBreakdown,
    int? jobsDone,
    double? lat,
    double? lng,
    String? referralCode,
    String? kycStatus,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? onboardingStep,
    bool? isKycComplete,
    bool? isApproved,
    bool? adminApproved,
    bool? profileApproved,
    bool? profileApprovalRequested,
    bool? profileRejected,
    bool? onboardingCompleted,
    String? aadhaarNumber,
    String? aadhaarFrontUrl,
    String? aadhaarBackUrl,
    String? profilePhotoUrl,
    String? state,
    String? district,
    int? experienceYears,
    List<String>? primaryCategoryId,
    String? primaryCategoryName,
    String? documentType,
    String? gender,
    DateTime? dateOfBirth,
    String? bio,
    List<String>? serviceAreas,
    TimeOfDay? workStartTime,
    TimeOfDay? workEndTime,
    bool? hasOwnTools,
    int? basePrice,
    int? visitingCharge,
    int? maxTravelDistance,
    bool? emergencyServiceAvailable,
    List<String>? languagePreferences,
    String? referralCodeUsed,
    String? panNumber,
    String? accountType,
    String? payoutPreference,
    int? maxDailyJobs,
    bool? dynamicPricingAllowed,
    Map<String, dynamic>? stepsCompleted,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
    String? bankVerificationStatus,
    bool? bankVerified,
    String? bankVerificationMessage,
    DateTime? bankVerifiedAt,
    String? fundAccountId,
    String? razorpayContactId,
    String? bankStatus, // DEPRECATED
    String? bankRejectionReason, // DEPRECATED
    DateTime? bankSubmittedAt, // DEPRECATED
    List<String>? customServices,
    String? experienceDescription,
    List<String>? tools,
    String? workPreference,
  }) {
    return Technician(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      skills: skills ?? this.skills,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      avgRating: avgRating ?? this.avgRating,
      totalRatings: totalRatings ?? this.totalRatings,
      ratingBreakdown: ratingBreakdown ?? this.ratingBreakdown,
      jobsDone: jobsDone ?? this.jobsDone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      referralCode: referralCode ?? this.referralCode,
      kycStatus: kycStatus ?? this.kycStatus,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      isKycComplete: isKycComplete ?? this.isKycComplete,
      isApproved: isApproved ?? this.isApproved,
      adminApproved: adminApproved ?? this.adminApproved,
      profileApproved: profileApproved ?? this.profileApproved,
      profileApprovalRequested: profileApprovalRequested ?? this.profileApprovalRequested,
      profileRejected: profileRejected ?? this.profileRejected,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      aadhaarFrontUrl: aadhaarFrontUrl ?? this.aadhaarFrontUrl,
      aadhaarBackUrl: aadhaarBackUrl ?? this.aadhaarBackUrl,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      state: state ?? this.state,
      district: district ?? this.district,
      experienceYears: experienceYears ?? this.experienceYears,
      primaryCategoryId: primaryCategoryId ?? this.primaryCategoryId,
      primaryCategoryName: primaryCategoryName ?? this.primaryCategoryName,
      documentType: documentType ?? this.documentType,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bio: bio ?? this.bio,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      hasOwnTools: hasOwnTools ?? this.hasOwnTools,
      basePrice: basePrice ?? this.basePrice,
      visitingCharge: visitingCharge ?? this.visitingCharge,
      maxTravelDistance: maxTravelDistance ?? this.maxTravelDistance,
      emergencyServiceAvailable: emergencyServiceAvailable ?? this.emergencyServiceAvailable,
      languagePreferences: languagePreferences ?? this.languagePreferences,
      referralCodeUsed: referralCodeUsed ?? this.referralCodeUsed,
      panNumber: panNumber ?? this.panNumber,
      accountType: accountType ?? this.accountType,
      payoutPreference: payoutPreference ?? this.payoutPreference,
      maxDailyJobs: maxDailyJobs ?? this.maxDailyJobs,
      dynamicPricingAllowed: dynamicPricingAllowed ?? this.dynamicPricingAllowed,
      stepsCompleted: stepsCompleted ?? this.stepsCompleted,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankVerificationStatus: bankVerificationStatus ?? this.bankVerificationStatus,
      bankVerified: bankVerified ?? this.bankVerified,
      bankVerificationMessage: bankVerificationMessage ?? this.bankVerificationMessage,
      bankVerifiedAt: bankVerifiedAt ?? this.bankVerifiedAt,
      fundAccountId: fundAccountId ?? this.fundAccountId,
      razorpayContactId: razorpayContactId ?? this.razorpayContactId,
      bankStatus: bankStatus ?? this.bankStatus, // DEPRECATED
      bankRejectionReason: bankRejectionReason ?? this.bankRejectionReason, // DEPRECATED
      bankSubmittedAt: bankSubmittedAt ?? this.bankSubmittedAt, // DEPRECATED
      customServices: customServices ?? this.customServices,
      experienceDescription: experienceDescription ?? this.experienceDescription,
      tools: tools ?? this.tools,
      workPreference: workPreference ?? this.workPreference,
    );
  }
}
