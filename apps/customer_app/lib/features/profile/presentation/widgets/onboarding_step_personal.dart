import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../providers/partner_onboarding_provider.dart';

/// Personal Information Step - Step 1 of 8
/// 
/// FIXES:
/// - Uses StatefulWidget with persistent TextEditingControllers
/// - Shows inline validation errors
/// - Modern card-based UI with proper spacing
class OnboardingStepPersonal extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const OnboardingStepPersonal({
    super.key,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<OnboardingStepPersonal> createState() => _OnboardingStepPersonalState();
}

class _OnboardingStepPersonalState extends State<OnboardingStepPersonal> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = context.read<PartnerOnboardingProvider>();
      _nameController = TextEditingController(text: provider.fullName);
      _phoneController = TextEditingController(text: provider.phone);
      _emailController = TextEditingController(text: provider.email);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PartnerOnboardingProvider>(
      builder: (context, provider, child) {
        return FadeTransition(
          opacity: widget.fadeAnimation,
          child: SlideTransition(
            position: widget.slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personal Information',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Let\'s start with your basic details',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.badge_outlined,
                            onChanged: provider.setFullName,
                            errorText: _getNameError(provider.fullName),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hint: '10-digit mobile number',
                            icon: Icons.phone_outlined,
                            onChanged: provider.setPhone,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            errorText: _getPhoneError(provider.phone),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'your.email@example.com',
                            icon: Icons.email_outlined,
                            onChanged: provider.setEmail,
                            keyboardType: TextInputType.emailAddress,
                            errorText: _getEmailError(provider.email),
                          ),
                        ],
                      ),
                    ),
                    
                    // Info Card
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFD97706),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your information will be verified during the review process.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF92400E),
                                height: 1.4,
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
          ),
        );
      },
    );
  }

  String? _getNameError(String name) {
    if (name.isEmpty) return null; // Don't show error for empty (not touched)
    if (name.trim().length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _getPhoneError(String phone) {
    if (phone.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(phone)) return 'Only digits allowed';
    if (phone.length != 10) return 'Phone must be exactly 10 digits';
    return null;
  }

  String? _getEmailError(String email) {
    if (email.isEmpty) return null;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) return 'Please enter a valid email';
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    int? maxLength,
    String? errorText,
  }) {
    final hasError = errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLength: maxLength,
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
            prefixIcon: Icon(
              icon,
              color: hasError ? Colors.red : AppTheme.primaryColor,
              size: 22,
            ),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade200 : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: hasError ? Colors.red.shade50 : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                errorText,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
