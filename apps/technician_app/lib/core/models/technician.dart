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
  /// Indicates if the technician has completed onboarding (legacy/hardening flag)
  /// This mirrors the Firestore field `onboardingCompleted` and is used in
  /// routing logic (see `main.dart`).
  final bool onboardingCompleted;
  final String? aadhaarNumber;
  final String? aadhaarFrontUrl;
  final String? aadhaarBackUrl;
  final String? profilePhotoUrl;
  final String? district;
  final int? experienceYears;
  final String? primaryCategoryId;
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
  
  // Bank details fields
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolderName;
  final String? bankStatus; // not_submitted, pending, approved, rejected
  final String? bankRejectionReason;
  final DateTime? bankSubmittedAt;

  // Custom services added by technician
  final List<String>? customServices;

  Technician({
    required this.uid,
    required this.name,
    required this.phone,
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
    this.onboardingCompleted = false,
    this.aadhaarNumber,
    this.aadhaarFrontUrl,
    this.aadhaarBackUrl,
    this.profilePhotoUrl,
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
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolderName,
    this.bankStatus,
    this.bankRejectionReason,
    this.bankSubmittedAt,
    this.customServices,
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
    final stepsMap = (data['stepsCompleted'] ?? {}) as Map<String, dynamic>;

    debugPrint('[TECH PROFILE] fullName=$fullName email=$email');

    // Handle legacy status field
    String status = data['status'] ?? 'pending_verification';
    String? kycStatus = data['kycStatus'];
    
    // SELF-HEALING KYC RESOLUTION - SINGLE SOURCE OF TRUTH
    // Check multiple sources to determine if KYC is truly complete
    final bool resolvedKyc =
        data['isKycComplete'] == true ||
        data['onboardingCompleted'] == true ||
        (stepsMap['kyc'] == true &&
         stepsMap['bank'] == true &&
         stepsMap['services'] == true);
    
    debugPrint('[FINAL HARDEN] resolvedKyc=$resolvedKyc');
    
    // Use resolved value as SINGLE source of truth
    bool isKycComplete = resolvedKyc;
    bool isApproved = data['isApproved'] ?? false;
    bool adminApproved = data['adminApproved'] ?? false;
    
    // Legacy conversion: if kycStatus is 'approved', set isApproved = true
    // BUT DO NOT override isKycComplete - it's already resolved above
    if (kycStatus == 'approved') {
      isApproved = true;
      adminApproved = true;
    } else if (status == 'approved') {
      isApproved = true;
      adminApproved = true;
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
      onboardingCompleted: data['onboardingCompleted'] == true,
      aadhaarNumber: data['aadhaarNumber'],
      aadhaarFrontUrl: data['aadhaarFrontUrl'],
      aadhaarBackUrl: data['aadhaarBackUrl'],
      profilePhotoUrl: data['profilePhotoUrl'],
      district: data['district'],
      experienceYears: data['experienceYears'],
      primaryCategoryId: data['primaryCategoryId'],
      primaryCategoryName: data['primaryCategoryName'],
      documentType: data['documentType'],
      gender: data['gender'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      bio: data['bio'],
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
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
      referralCodeUsed: data['referralCodeUsed'],
      panNumber: data['panNumber'],
      accountType: data['accountType'],
      payoutPreference: data['payoutPreference'],
      maxDailyJobs: data['maxDailyJobs'],
      dynamicPricingAllowed: data['dynamicPricingAllowed'],
      stepsCompleted: stepsMap,
      // Bank details - root level only (no legacy fallback)
      bankName: data['bankName'],
      accountNumber: data['accountNumber'],
      ifscCode: data['ifscCode'],
      accountHolderName: data['accountHolderName'],
      bankStatus: data['bankStatus'],
      bankRejectionReason: data['bankRejectionReason'],
      bankSubmittedAt: data['bankSubmittedAt'] != null
          ? (data['bankSubmittedAt'] as Timestamp).toDate()
          : null,
      customServices: (data['customServices'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
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
      'onboardingCompleted': onboardingCompleted,
      'aadhaarNumber': aadhaarNumber,
      'aadhaarFrontUrl': aadhaarFrontUrl,
      'aadhaarBackUrl': aadhaarBackUrl,
      'profilePhotoUrl': profilePhotoUrl,
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
      if (bankName != null) 'bankName': bankName,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (ifscCode != null) 'ifscCode': ifscCode,
      if (accountHolderName != null) 'accountHolderName': accountHolderName,
      if (bankStatus != null) 'bankStatus': bankStatus,
      if (bankRejectionReason != null) 'bankRejectionReason': bankRejectionReason,
      if (bankSubmittedAt != null) 'bankSubmittedAt': Timestamp.fromDate(bankSubmittedAt!),
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
    return isKycComplete && isApproved;
  }
  
  /// Check if technician can add/edit services
  /// CRITICAL: Requires adminApproved == true for service management
  bool get canManageServices {
    return isKycComplete && isApproved && adminApproved;
  }
  
  /// Check if technician is in onboarding process
  bool get isInOnboarding {
    return !isKycComplete;
  }
  
  /// Check if technician is under review
  bool get isUnderReview {
    return isKycComplete && !isApproved;
  }

  /// Calculate profile completion percentage
  int calculateProfileCompletion() {
    if (stepsCompleted != null && stepsCompleted!.isNotEmpty) {
      final totalSteps = 5;
      int completedSteps = 0;
      for (final entry in stepsCompleted!.entries) {
        if (entry.value == true) completedSteps++;
      }
      return ((completedSteps / totalSteps) * 100).round().clamp(0, 100);
    }
    
    int completed = 0;
    int total = 8;
    if (name.isNotEmpty) completed++;
    if (phone.isNotEmpty) completed++;
    if (profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty) completed++;
    if (skills.isNotEmpty) completed++;
    if (experienceYears != null && experienceYears! > 0) completed++;
    if (bankStatus == 'approved') completed++;
    if ((aadhaarFrontUrl != null && aadhaarFrontUrl!.isNotEmpty) || (panNumber != null && panNumber!.isNotEmpty)) completed++;
    if ((customServices != null && customServices!.isNotEmpty) || skills.isNotEmpty) completed++;
    return ((completed / total) * 100).round().clamp(0, 100);
  }
}
