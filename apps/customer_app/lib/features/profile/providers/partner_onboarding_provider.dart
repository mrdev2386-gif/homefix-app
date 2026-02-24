import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:customer_app/core/services/storage_service.dart';

/// Production-grade state management for Partner Onboarding
/// 
/// CRITICAL FEATURES:
/// - Single source of truth for all form data
/// - Reactive validation that updates on every change
/// - Prevents duplicate submissions
/// - Maintains state across step navigation
/// - Secure Firebase Cloud Functions integration
class PartnerOnboardingProvider extends ChangeNotifier {
  final StorageService _storageService;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  PartnerOnboardingProvider(this._storageService);

  // ==================== STATE ====================
  int _currentStep = 0;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  // Form Data - persisted across all steps
  final Map<String, dynamic> _formData = {
    'fullName': '',
    'phone': '',
    'email': '',
    'categoryIds': <String>[],
    'subcategoryIds': <String>[],
    'selectedServices': <Map<String, dynamic>>[],
    'experienceYears': '',
    'experienceDescription': '',
    'address': '',
    'bankHolderName': '',
    'bankAccountNumber': '',
    'bankIfscCode': '',
    'agreedToTerms': false,
  };
  
  XFile? _profilePhoto;
  XFile? _idProof;

  // Cache of subcategory metadata to build selectedServices payload
  final Map<String, Map<String, dynamic>> _subcategoryMetadata = {};

  // Validation state per step
  final Map<int, bool> _stepValidation = {
    0: false, // Personal info
    1: false, // Categories
    2: false, // Experience
    3: false, // Profile photo
    4: false, // ID proof
    5: false, // Address
    6: false, // Bank details
    7: false, // Terms agreement
  };

  // ==================== GETTERS ====================
  int get currentStep => _currentStep;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isCurrentStepValid => _stepValidation[_currentStep] ?? false;
  
  // Form data getters
  String get fullName => _formData['fullName'] ?? '';
  String get phone => _formData['phone'] ?? '';
  String get email => _formData['email'] ?? '';
  List<String> get categoryIds => List<String>.from(_formData['categoryIds'] ?? []);
  List<String> get subcategoryIds => List<String>.from(_formData['subcategoryIds'] ?? []);
  List<Map<String, dynamic>> get selectedServices => List<Map<String, dynamic>>.from(_formData['selectedServices'] ?? []);
  String get experienceYears => _formData['experienceYears'] ?? '';
  String get experienceDescription => _formData['experienceDescription'] ?? '';
  String get address => _formData['address'] ?? '';
  String get bankHolderName => _formData['bankHolderName'] ?? '';
  String get bankAccountNumber => _formData['bankAccountNumber'] ?? '';
  String get bankIfscCode => _formData['bankIfscCode'] ?? '';
  bool get agreedToTerms => _formData['agreedToTerms'] ?? false;
  
  XFile? get profilePhoto => _profilePhoto;
  XFile? get idProof => _idProof;

  // ==================== SETTERS WITH AUTO-VALIDATION ====================
  
  void setFullName(String value) {
    _formData['fullName'] = value;
    _validateCurrentStep();
    notifyListeners();
  }

  void setPhone(String value) {
    _formData['phone'] = value;
    _validateCurrentStep();
    notifyListeners();
  }

  void setEmail(String value) {
    _formData['email'] = value;
    _validateCurrentStep();
    notifyListeners();
  }

  void toggleCategory(String categoryId) {
    final categories = List<String>.from(_formData['categoryIds'] ?? []);
    if (categories.contains(categoryId)) {
      categories.remove(categoryId);
    } else {
      categories.add(categoryId);
    }
    _formData['categoryIds'] = categories;
    _validateCurrentStep();
    notifyListeners();
  }

  void toggleSubcategory(String subcategoryId, {Map<String, dynamic>? metadata}) {
    final subcategories = List<String>.from(_formData['subcategoryIds'] ?? []);
    
    if (metadata != null) {
      _subcategoryMetadata[subcategoryId] = metadata;
    }

    if (subcategories.contains(subcategoryId)) {
      subcategories.remove(subcategoryId);
    } else {
      subcategories.add(subcategoryId);
    }
    _formData['subcategoryIds'] = subcategories;
    
    _rebuildSelectedServices();
    _validateCurrentStep();
    notifyListeners();
  }

  void _rebuildSelectedServices() {
    final List<String> currentSubs = List<String>.from(_formData['subcategoryIds'] ?? []);
    final Map<String, Map<String, dynamic>> serviceGroups = {};

    for (var subId in currentSubs) {
      final meta = _subcategoryMetadata[subId];
      if (meta == null) continue;

      final String? serviceId = meta['serviceId'];
      
      if (serviceId == null || serviceId.isEmpty) {
        debugPrint('❌ [Migration Check] Subcategory $subId is missing serviceId mapping. Using legacy mode.');
        continue;
      }

      if (!serviceGroups.containsKey(serviceId)) {
        serviceGroups[serviceId] = {
          'serviceId': serviceId,
          'serviceName': meta['serviceName'] ?? 'Service',
          'subServiceIds': <String>[],
        };
      }
      
      final List<String> subServiceIds = List<String>.from(serviceGroups[serviceId]!['subServiceIds']);
      subServiceIds.add(subId);
      serviceGroups[serviceId]!['subServiceIds'] = subServiceIds;
    }

    _formData['selectedServices'] = serviceGroups.values.toList();
  }

  void setExperienceYears(String value) {
    _formData['experienceYears'] = value;
    _validateCurrentStep();
    notifyListeners();
  }

  void setExperienceDescription(String value) {
    _formData['experienceDescription'] = value;
    _validateCurrentStep();
    notifyListeners();
  }

  void setAddress(String value) {
    _formData['address'] = value;
    _validateCurrentStep();
    notifyListeners();
  }

  void setBankHolderName(String value) {
    _formData['bankHolderName'] = value;
    _validateCurrentStep();
    notifyListeners();
  }

  void setBankAccountNumber(String value) {
    _formData['bankAccountNumber'] = value;
    _validateCurrentStep();
    notifyListeners();
  }

  void setBankIfscCode(String value) {
    _formData['bankIfscCode'] = value;
    _validateCurrentStep();
    notifyListeners();
  }

  void setAgreedToTerms(bool value) {
    _formData['agreedToTerms'] = value;
    _validateCurrentStep();
    notifyListeners();
  }

  void setProfilePhoto(XFile? file) {
    _profilePhoto = file;
    _validateCurrentStep();
    notifyListeners();
  }

  void setIdProof(XFile? file) {
    _idProof = file;
    _validateCurrentStep();
    notifyListeners();
  }

  // ==================== VALIDATION ====================
  
  /// Validates current step and updates validation state
  /// Called automatically on every input change
  void _validateCurrentStep() {
    bool isValid = false;
    _errorMessage = null;

    switch (_currentStep) {
      case 0: // Personal Information
        isValid = _validatePersonalInfo();
        break;
      case 1: // Categories
        isValid = _validateCategories();
        break;
      case 2: // Experience
        isValid = _validateExperience();
        break;
      case 3: // Profile Photo
        isValid = _profilePhoto != null;
        break;
      case 4: // ID Proof
        isValid = _idProof != null;
        break;
      case 5: // Address
        isValid = _validateAddress();
        break;
      case 6: // Bank Details
        isValid = _validateBankDetails();
        break;
      case 7: // Terms
        isValid = agreedToTerms;
        break;
    }

    _stepValidation[_currentStep] = isValid;
  }

  bool _validatePersonalInfo() {
    final name = fullName.trim();
    final phoneNum = phone.trim();
    final emailAddr = email.trim();

    if (name.length < 3) {
      _errorMessage = 'Name must be at least 3 characters';
      return false;
    }
    if (phoneNum.length != 10 || !RegExp(r'^\d{10}$').hasMatch(phoneNum)) {
      _errorMessage = 'Phone must be exactly 10 digits';
      return false;
    }
    if (!_isValidEmail(emailAddr)) {
      _errorMessage = 'Please enter a valid email address';
      return false;
    }
    return true;
  }

  bool _validateCategories() {
    if (categoryIds.isEmpty || subcategoryIds.isEmpty) {
      _errorMessage = 'Please select at least 1 category and 1 subcategory';
      return false;
    }
    return true;
  }

  bool _validateExperience() {
    final years = int.tryParse(experienceYears.trim());
    if (years == null || years <= 0) {
      _errorMessage = 'Please enter valid years of experience (must be greater than 0)';
      return false;
    }
    return true;
  }

  bool _validateAddress() {
    if (address.trim().length < 10) {
      _errorMessage = 'Please enter a complete address (minimum 10 characters)';
      return false;
    }
    return true;
  }

  bool _validateBankDetails() {
    final holder = bankHolderName.trim();
    final account = bankAccountNumber.trim();
    final ifsc = bankIfscCode.trim();

    if (holder.isEmpty) {
      _errorMessage = 'Account holder name is required';
      return false;
    }
    if (account.length < 9) {
      _errorMessage = 'Please enter a valid account number';
      return false;
    }
    if (ifsc.length != 11) {
      _errorMessage = 'IFSC code must be exactly 11 characters';
      return false;
    }
    return true;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // ==================== NAVIGATION ====================
  
  /// Move to next step - PRESERVES all form data
  void nextStep() {
    if (_currentStep < 7) {
      _currentStep++;
      _validateCurrentStep(); // Validate new step
      notifyListeners();
    }
  }

  /// Move to previous step - PRESERVES all form data
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _validateCurrentStep(); // Validate previous step
      notifyListeners();
    }
  }

  // ==================== SUBMISSION ====================
  
  /// Submit application via Firebase Cloud Function
  /// 
  /// CRITICAL: This is the ONLY way to submit - no direct Firestore writes
  /// Prevents duplicate submissions with isSubmitting flag
  Future<bool> submitApplication(String userId) async {
    // CRITICAL: Prevent duplicate submissions
    if (_isSubmitting) {
      debugPrint('[PartnerOnboarding] Submission already in progress');
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Upload images to Firebase Storage
      String? profilePhotoUrl;
      String? idProofUrl;

      if (_profilePhoto != null) {
        debugPrint('[PartnerOnboarding] Uploading profile photo...');
        profilePhotoUrl = await _storageService.uploadProfilePhoto(
          userId,
          File(_profilePhoto!.path),
        );
      }

      if (_idProof != null) {
        debugPrint('[PartnerOnboarding] Uploading ID proof...');
        idProofUrl = await _storageService.uploadTechnicianDoc(
          userId,
          File(_idProof!.path),
          'id_proof',
        );
      }

      // Step 2: Call Firebase Cloud Function
      debugPrint('[PartnerOnboarding] Calling submitPartnerApplication function...');
      
      final callable = _functions.httpsCallable('submitPartnerApplication');
      final result = await callable.call({
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'categoryIds': categoryIds,
        'subcategoryIds': subcategoryIds,
        'selectedServices': selectedServices,
        'experienceYears': int.parse(experienceYears.trim()),
        'experienceDescription': experienceDescription.trim(),
        'profilePhotoUrl': profilePhotoUrl,
        'idProofUrl': idProofUrl,
        'address': address.trim(),
        'bankDetails': {
          'accountNumber': bankAccountNumber.trim(),
          'ifscCode': bankIfscCode.trim(),
          'holderName': bankHolderName.trim(),
        },
      });

      debugPrint('[PartnerOnboarding] Submission successful: ${result.data}');
      
      // Clear state on success
      _clearState();
      
      return true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[PartnerOnboarding] Cloud Function error: ${e.code} - ${e.message}');
      
      // User-friendly error messages
      switch (e.code) {
        case 'permission-denied':
          _errorMessage = 'You do not have permission to submit this application';
          break;
        case 'unauthenticated':
          _errorMessage = 'Please sign in to submit your application';
          break;
        case 'already-exists':
          _errorMessage = 'You have already submitted an application';
          break;
        case 'invalid-argument':
          _errorMessage = 'Invalid data provided. Please check all fields';
          break;
        case 'unavailable':
          _errorMessage = 'Service temporarily unavailable. Please try again';
          break;
        default:
          _errorMessage = e.message ?? 'Failed to submit application';
      }
      
      return false;
    } catch (e) {
      debugPrint('[PartnerOnboarding] Unexpected error: $e');
      _errorMessage = 'An unexpected error occurred. Please try again';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ==================== CLEANUP ====================
  
  /// Clear all state - called after successful submission
  void _clearState() {
    _currentStep = 0;
    _formData.clear();
    _formData.addAll({
      'fullName': '',
      'phone': '',
      'email': '',
      'categoryIds': <String>[],
      'subcategoryIds': <String>[],
      'experienceYears': '',
      'experienceDescription': '',
      'address': '',
      'bankHolderName': '',
      'bankAccountNumber': '',
      'bankIfscCode': '',
      'agreedToTerms': false,
    });
    _profilePhoto = null;
    _idProof = null;
    _stepValidation.clear();
    _errorMessage = null;
  }

  /// Reset provider - called when user exits the flow
  void reset() {
    _clearState();
    notifyListeners();
  }
}
