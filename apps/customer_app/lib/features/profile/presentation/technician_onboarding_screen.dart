import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/services/firestore_service.dart';
import 'package:customer_app/core/services/storage_service.dart';
import 'package:customer_app/core/theme/app_theme.dart';

/// Modern, production-grade technician onboarding with premium UI/UX
class TechnicianOnboardingScreen extends StatefulWidget {
  const TechnicianOnboardingScreen({super.key});

  @override
  State<TechnicianOnboardingScreen> createState() => _TechnicianOnboardingScreenState();
}

class _TechnicianOnboardingScreenState extends State<TechnicianOnboardingScreen> 
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _experienceYearsController = TextEditingController();
  final TextEditingController _experienceDescController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _bankIfscController = TextEditingController();
  final TextEditingController _bankHolderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final Set<String> _selectedCategoryIds = {};
  final Set<String> _selectedSubCategoryIds = {};
  XFile? _profilePhoto;
  XFile? _idProof;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceYearsController.dispose();
    _experienceDescController.dispose();
    _bankAccountController.dispose();
    _bankIfscController.dispose();
    _bankHolderController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    String? errorMessage;
    
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().length < 3) {
          errorMessage = 'Name must be at least 3 characters';
        } else if (_phoneController.text.trim().length != 10) {
          errorMessage = 'Phone must be exactly 10 digits';
        } else if (!_isValidEmail(_emailController.text.trim())) {
          errorMessage = 'Please enter a valid email address';
        }
        break;
      case 1:
        if (_selectedCategoryIds.isEmpty || _selectedSubCategoryIds.isEmpty) {
          errorMessage = 'Please select at least 1 category and 1 subcategory';
        }
        break;
      case 2:
        final years = int.tryParse(_experienceYearsController.text.trim());
        if (years == null || years <= 0) {
          errorMessage = 'Please enter valid years of experience (must be greater than 0)';
        }
        break;
      case 3:
        if (_profilePhoto == null) {
          errorMessage = 'Please upload a profile photo';
        }
        break;
      case 4:
        if (_idProof == null) {
          errorMessage = 'Please upload an ID proof document';
        }
        break;
      case 5:
        if (_addressController.text.trim().length < 10) {
          errorMessage = 'Please enter a complete address (minimum 10 characters)';
        }
        break;
      case 6:
        if (_bankHolderController.text.trim().isEmpty) {
          errorMessage = 'Account holder name is required';
        } else if (_bankAccountController.text.trim().length < 9) {
          errorMessage = 'Please enter a valid account number';
        } else if (_bankIfscController.text.trim().length != 11) {
          errorMessage = 'IFSC code must be exactly 11 characters';
        }
        break;
      case 7:
        if (!_agreedToTerms) {
          errorMessage = 'Please agree to the terms and conditions';
        }
        break;
    }
    
    if (errorMessage != null) {
      _showErrorSnackbar(errorMessage);
      return false;
    }
    return true;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _nextPage() async {
    if (!_validateCurrentStep()) return;
    
    if (_currentStep < 7) {
      await _animationController.reverse();
      setState(() => _currentStep++);
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _animationController.forward();
    } else {
      await _submitApplication();
    }
  }

  Future<void> _prevPage() async {
    if (_currentStep > 0) {
      await _animationController.reverse();
      setState(() => _currentStep--);
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _animationController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profilePhoto = pickedFile;
          } else {
            _idProof = pickedFile;
          }
        });
        _showSuccessSnackbar('Image uploaded successfully');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    }
  }

  Future<void> _submitApplication() async {
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final userId = auth.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      String? profileUrl;
      String? idProofUrl;

      if (_profilePhoto != null) {
        profileUrl = await storage.uploadProfilePhoto(
          userId,
          File(_profilePhoto!.path),
        );
      }
      
      if (_idProof != null) {
        idProofUrl = await storage.uploadTechnicianDoc(
          userId,
          File(_idProof!.path),
          'id_proof',
        );
      }

      await firestore.becomeTechnician(userId, {
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'categories': _selectedCategoryIds.toList(),
        'subCategories': _selectedSubCategoryIds.toList(),
        'experienceYears': _experienceYearsController.text.trim(),
        'experienceDescription': _experienceDescController.text.trim(),
        'profilePhotoUrl': profileUrl,
        'idProofUrl': idProofUrl,
        'address': _addressController.text.trim(),
        'bankDetails': {
          'accountNumber': _bankAccountController.text.trim(),
          'ifscCode': _bankIfscController.text.trim(),
          'holderName': _bankHolderController.text.trim(),
        },
        'status': 'pending',
        'appliedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to submit application: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Application Submitted!',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'re reviewing your application. You\'ll be notified within 24-48 hours.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Back to Profile',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildStep1Personal(),
                _buildStep2Categories(),
                _buildStep3Experience(),
                _buildStep4Photo(),
                _buildStep5IdProof(),
                _buildStep6Address(),
                _buildStep7Bank(),
                _buildStep8Agreement(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: _prevPage,
        color: AppTheme.textColor,
      ),
      title: Text(
        'Join as Partner',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: AppTheme.textColor,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentStep + 1) / 8;
    final percentage = (progress * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of 8',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '$percentage% Complete',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: _isLoading ? 0 : 4,
              shadowColor: AppTheme.primaryColor.withOpacity(0.3),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _currentStep == 7 ? 'Submit Application' : 'Continue',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Personal() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s start with your basic details',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildModernTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '10-digit mobile number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'your.email@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Categories() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service Expertise',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the services you can provide',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Selected: ${_selectedCategoryIds.length} categories, ${_selectedSubCategoryIds.length} subcategories',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ['Plumbing', 'Electrical', 'Carpentry', 'Painting', 'Cleaning'];
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((cat) {
        final isSelected = _selectedCategoryIds.contains(cat);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCategoryIds.remove(cat);
                _selectedSubCategoryIds.remove('${cat}_sub');
              } else {
                _selectedCategoryIds.add(cat);
                _selectedSubCategoryIds.add('${cat}_sub');
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Text(
              cat,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep3Experience() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track Record',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us about your professional experience',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildModernTextField(
                controller: _experienceYearsController,
                label: 'Years of Experience *',
                hint: 'e.g., 5',
                icon: Icons.work_outline_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _experienceDescController,
                label: 'Brief Description (Optional)',
                hint: 'Describe your expertise and past projects',
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep4Photo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Photo',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a clear photo of yourself',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: _profilePhoto == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to upload',
                                style: GoogleFonts.outfit(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: kIsWeb
                                ? Image.network(_profilePhoto!.path, fit: BoxFit.cover)
                                : Image.file(File(_profilePhoto!.path), fit: BoxFit.cover),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep5IdProof() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID Verification',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a government-issued ID (Aadhaar, PAN, Driving License)',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: _idProof == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to upload ID',
                                style: GoogleFonts.outfit(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: kIsWeb
                                ? Image.network(_idProof!.path, fit: BoxFit.cover)
                                : Image.file(File(_idProof!.path), fit: BoxFit.cover),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep6Address() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service Address',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Where will you provide services?',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildModernTextField(
                controller: _addressController,
                label: 'Complete Address',
                hint: 'House no., Street, Area, City, PIN',
                icon: Icons.location_on_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep7Bank() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Details',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For receiving payments',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildModernTextField(
                controller: _bankHolderController,
                label: 'Account Holder Name',
                hint: 'As per bank records',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _bankAccountController,
                label: 'Account Number',
                hint: 'Enter account number',
                icon: Icons.account_balance_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _bankIfscController,
                label: 'IFSC Code',
                hint: 'e.g., SBIN0001234',
                icon: Icons.code_outlined,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep8Agreement() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms & Conditions',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please review and accept',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partner Agreement',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '• You will provide quality services to customers\n'
                      '• You agree to our commission structure\n'
                      '• You will maintain professional conduct\n'
                      '• You can be suspended for policy violations\n'
                      '• All information provided is accurate',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _agreedToTerms = !_agreedToTerms;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _agreedToTerms ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _agreedToTerms ? AppTheme.primaryColor : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: _agreedToTerms
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I agree to the terms and conditions',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
