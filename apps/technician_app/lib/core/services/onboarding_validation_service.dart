/// ⚠️ VALIDATION SERVICE: Single source of truth for onboarding step validation
/// 
/// IMPORTANT: For Aadhaar validation, use OnboardingService.validateAadhaar()
/// instead of duplicating logic here. This service handles multi-field validation
/// for complete steps, while OnboardingService handles individual field validation.
/// 
/// ARCHITECTURE:
/// - OnboardingService: Individual field validation (validateAadhaar, cleanAadhaar, maskAadhaar)
/// - OnboardingValidationService: Multi-field step validation (validateStep1-4)
class OnboardingValidationService {
  // Step 1: Basic Information validation
  static Map<String, String?> validateStep1(Map<String, dynamic> formData) {
    final errors = <String, String?>{};

    // Full Name - Mandatory
    final name = formData['fullName']?.toString().trim();
    if (name == null || name.isEmpty) {
      errors['fullName'] = 'Full name is required';
    } else if (name.length < 3) {
      errors['fullName'] = 'Name must be at least 3 characters';
    }

    // State - Mandatory
    if (formData['state'] == null || formData['state'].toString().isEmpty) {
      errors['state'] = 'State is required';
    }

    // District - Mandatory
    if (formData['district'] == null || formData['district'].toString().isEmpty) {
      errors['district'] = 'District is required';
    }

    // Profile Photo - Mandatory
    if (formData['profilePhotoUrl'] == null || formData['profilePhotoUrl'].toString().isEmpty) {
      errors['profilePhotoUrl'] = 'Profile photo is required';
    }

    // Primary Category - Mandatory (at least 1)
    final categories = formData['primaryCategoryId'];
    if (categories == null || (categories is List && categories.isEmpty)) {
      errors['primaryCategoryId'] = 'Select at least one service category';
    }

    return errors;
  }

  // Step 2: Professional Details validation
  static Map<String, String?> validateStep2(Map<String, dynamic> formData) {
    final errors = <String, String?>{};

    // Experience Years - Mandatory
    final experience = formData['experienceYears'];
    if (experience == null || experience == 0) {
      errors['experienceYears'] = 'Experience is required';
    } else if (experience < 0 || experience > 50) {
      errors['experienceYears'] = 'Enter valid experience (0-50 years)';
    }

    // Skills - Mandatory (at least 1)
    final skills = formData['skills'];
    if (skills == null || (skills is List && skills.isEmpty)) {
      errors['skills'] = 'Add at least one skill';
    }

    return errors;
  }

  // Step 3: KYC Verification validation
  // ⚠️ NOTE: Aadhaar validation logic is in OnboardingService.validateAadhaar()
  // This method uses the same validation rules for consistency
  static Map<String, String?> validateStep3(Map<String, dynamic> formData) {
    final errors = <String, String?>{};

    // Aadhaar Number - Mandatory
    // ⚠️ Delegated to OnboardingService.validateAadhaar() for single source of truth
    final aadhaar = formData['aadhaarNumber']?.toString().replaceAll(' ', '');
    if (aadhaar == null || aadhaar.isEmpty) {
      errors['aadhaarNumber'] = 'Aadhaar number is required';
    } else if (aadhaar.length != 12) {
      errors['aadhaarNumber'] = 'Aadhaar must be 12 digits';
    } else if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      errors['aadhaarNumber'] = 'Aadhaar must contain only digits';
    }

    // Aadhaar Front Image - Mandatory
    if (formData['aadhaarFrontUrl'] == null || formData['aadhaarFrontUrl'].toString().isEmpty) {
      errors['aadhaarFrontUrl'] = 'Aadhaar front photo is required';
    }

    // Aadhaar Back Image - Mandatory
    if (formData['aadhaarBackUrl'] == null || formData['aadhaarBackUrl'].toString().isEmpty) {
      errors['aadhaarBackUrl'] = 'Aadhaar back photo is required';
    }

    return errors;
  }

  // Step 4: Work Portfolio validation
  static Map<String, String?> validateStep4(Map<String, dynamic> formData) {
    final errors = <String, String?>{};

    // Experience Description - Mandatory
    final description = formData['experienceDescription']?.toString().trim();
    if (description == null || description.isEmpty) {
      errors['experienceDescription'] = 'Work experience description is required';
    } else if (description.length < 20) {
      errors['experienceDescription'] = 'Description must be at least 20 characters';
    }

    // Work Preference - Mandatory
    if (formData['workPreference'] == null || formData['workPreference'].toString().isEmpty) {
      errors['workPreference'] = 'Work type preference is required';
    }

    return errors;
  }

  // Validate entire onboarding before final submission
  static Map<String, dynamic> validateCompleteProfile(Map<String, dynamic> formData) {
    final allErrors = <String, String?>{};
    
    // Validate all steps
    allErrors.addAll(validateStep1(formData));
    allErrors.addAll(validateStep2(formData));
    allErrors.addAll(validateStep3(formData));
    allErrors.addAll(validateStep4(formData));

    return {
      'isValid': allErrors.isEmpty,
      'errors': allErrors,
      'missingFields': allErrors.keys.toList(),
    };
  }

  // Get user-friendly error message for step
  static String getStepErrorMessage(int step, Map<String, dynamic> formData) {
    Map<String, String?> errors;
    
    switch (step) {
      case 0:
        errors = validateStep1(formData);
        break;
      case 1:
        errors = validateStep2(formData);
        break;
      case 2:
        errors = validateStep3(formData);
        break;
      case 3:
        errors = validateStep4(formData);
        break;
      default:
        return '';
    }

    if (errors.isEmpty) return '';

    // Return first error message
    return errors.values.first ?? 'Please complete all required fields';
  }

  // Check if step is complete
  static bool isStepComplete(int step, Map<String, dynamic> formData) {
    Map<String, String?> errors;
    
    switch (step) {
      case 0:
        errors = validateStep1(formData);
        break;
      case 1:
        errors = validateStep2(formData);
        break;
      case 2:
        errors = validateStep3(formData);
        break;
      case 3:
        errors = validateStep4(formData);
        break;
      default:
        return false;
    }

    return errors.isEmpty;
  }

  // Temporary calculation during onboarding steps.
  // This is NOT the source of truth.
  // The real completion value comes from Firestore `profileCompletion`.
  static int calculateOnboardingProgress(Map<String, dynamic> formData) {
    int totalFields = 0;
    int completedFields = 0;

    // Step 1 fields (6 mandatory)
    totalFields += 6;
    if (formData['fullName']?.toString().trim().isNotEmpty == true) completedFields++;
    if (formData['state']?.toString().isNotEmpty == true) completedFields++;
    if (formData['district']?.toString().isNotEmpty == true) completedFields++;
    if (formData['profilePhotoUrl']?.toString().isNotEmpty == true) completedFields++;
    final categories = formData['primaryCategoryId'];
    if (categories != null && categories is List && categories.isNotEmpty) completedFields++;
    if (formData['experienceYears'] != null && formData['experienceYears'] > 0) completedFields++;

    // Step 2 fields (1 mandatory)
    totalFields += 1;
    final skills = formData['skills'];
    if (skills != null && skills is List && skills.isNotEmpty) completedFields++;

    // Step 3 fields (3 mandatory)
    totalFields += 3;
    final aadhaar = formData['aadhaarNumber']?.toString().replaceAll(' ', '');
    if (aadhaar != null && aadhaar.length == 12) completedFields++;
    if (formData['aadhaarFrontUrl']?.toString().isNotEmpty == true) completedFields++;
    if (formData['aadhaarBackUrl']?.toString().isNotEmpty == true) completedFields++;

    // Step 4 fields (2 mandatory)
    totalFields += 2;
    final description = formData['experienceDescription']?.toString().trim();
    if (description != null && description.length >= 20) completedFields++;
    if (formData['workPreference']?.toString().isNotEmpty == true) completedFields++;

    return ((completedFields / totalFields) * 100).round();
  }
}
