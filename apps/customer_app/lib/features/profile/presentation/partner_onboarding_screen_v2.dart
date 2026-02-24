import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../providers/partner_onboarding_provider.dart';
import 'widgets/onboarding_step_personal.dart';
import 'widgets/onboarding_step_categories.dart';
import 'widgets/onboarding_step_experience.dart';
import 'widgets/onboarding_step_photo.dart';
import 'widgets/onboarding_step_id_proof.dart';
import 'widgets/onboarding_step_address.dart';
import 'widgets/onboarding_step_bank.dart';
import 'widgets/onboarding_step_terms.dart';

/// Production-grade Partner Onboarding Screen
/// 
/// ARCHITECTURE:
/// - Uses ChangeNotifier provider for state management
/// - All validation is reactive and updates on input change
/// - State persists across step navigation
/// - Prevents duplicate submissions
/// - Secure Cloud Functions integration
/// - Premium UI with smooth animations
/// 
/// FIXES APPLIED:
/// - Modern card-based UI with proper spacing
/// - Fixed Submit button with loading state
/// - Proper validation per step
/// - Inline error messages
/// - Responsive layout
class PartnerOnboardingScreenV2 extends StatefulWidget {
  const PartnerOnboardingScreenV2({super.key});

  @override
  State<PartnerOnboardingScreenV2> createState() => _PartnerOnboardingScreenV2State();
}

class _PartnerOnboardingScreenV2State extends State<PartnerOnboardingScreenV2> 
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<_StepInfo> _steps = [
    _StepInfo('Personal', Icons.person_outline_rounded),
    _StepInfo('Services', Icons.category_outlined),
    _StepInfo('Experience', Icons.work_outline_rounded),
    _StepInfo('Photo', Icons.camera_alt_outlined),
    _StepInfo('ID Proof', Icons.badge_outlined),
    _StepInfo('Address', Icons.location_on_outlined),
    _StepInfo('Bank', Icons.account_balance_outlined),
    _StepInfo('Terms', Icons.description_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleNext(BuildContext context) async {
    final provider = context.read<PartnerOnboardingProvider>();
    
    // Show error if current step is invalid
    if (!provider.isCurrentStepValid) {
      _showErrorSnackbar(context, provider.errorMessage ?? 'Please complete all required fields');
      return;
    }

    if (provider.currentStep < 7) {
      // Navigate to next step with animation
      await _animationController.reverse();
      provider.nextStep();
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      _animationController.forward();
    } else {
      // Final step - submit application
      await _submitApplication(context);
    }
  }

  Future<void> _handlePrevious(BuildContext context) async {
    final provider = context.read<PartnerOnboardingProvider>();
    
    if (provider.currentStep > 0) {
      await _animationController.reverse();
      provider.previousStep();
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      _animationController.forward();
    } else {
      // Exit onboarding
      _handleExit(context);
    }
  }

  void _handleExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.exit_to_app, color: Colors.orange.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Exit Application?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Your progress will be saved. You can continue later from where you left off.',
          style: GoogleFonts.outfit(color: Colors.grey.shade600, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Exit',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitApplication(BuildContext context) async {
    final provider = context.read<PartnerOnboardingProvider>();
    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.uid;

    if (userId == null) {
      _showErrorSnackbar(context, 'Please sign in to submit your application');
      return;
    }

    // Final validation check
    if (!provider.agreedToTerms) {
      _showErrorSnackbar(context, 'Please accept the terms and conditions');
      return;
    }

    final success = await provider.submitApplication(userId);

    if (!mounted) return;

    if (success) {
      _showSuccessDialog(context);
    } else {
      _showErrorSnackbar(context, provider.errorMessage ?? 'Failed to submit application. Please try again.');
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
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
              // Success Animation Container
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981),
                            const Color(0xFF059669),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Application Submitted!',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you for applying to become a HomeFix partner. Our team will review your application and get back to you within 24-48 hours.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active, color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'You\'ll receive a notification',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
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
    return Consumer<PartnerOnboardingProvider>(
      builder: (context, provider, child) {
        return PopScope(
          canPop: provider.currentStep == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && provider.currentStep > 0) {
              _handlePrevious(context);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: _buildAppBar(context, provider),
            body: Column(
              children: [
                _buildStepIndicator(provider),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      OnboardingStepPersonal(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                      OnboardingStepCategories(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                      OnboardingStepExperience(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                      OnboardingStepPhoto(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                      OnboardingStepIdProof(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                      OnboardingStepAddress(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                      OnboardingStepBank(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                      OnboardingStepTerms(
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomBar(context, provider),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, PartnerOnboardingProvider provider) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            provider.currentStep == 0 ? Icons.close : Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppTheme.textColor,
          ),
        ),
        onPressed: () => _handlePrevious(context),
      ),
      title: Column(
        children: [
          Text(
            'Join as Partner',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.textColor,
            ),
          ),
          Text(
            _steps[provider.currentStep].title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${provider.currentStep + 1}/8',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(PartnerOnboardingProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
          // Step dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(8, (index) {
              final isCompleted = index < provider.currentStep;
              final isCurrent = index == provider.currentStep;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isCurrent ? 32 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : isCurrent
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (provider.currentStep + 1) / 8,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, PartnerOnboardingProvider provider) {
    final isEnabled = provider.isCurrentStepValid && !provider.isSubmitting;
    final isLastStep = provider.currentStep == 7;
    
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error message if any
            if (provider.errorMessage != null && !provider.isCurrentStepValid)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.errorMessage!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Main CTA Button
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isEnabled ? () => _handleNext(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastStep 
                      ? const Color(0xFF10B981) 
                      : AppTheme.primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: isEnabled ? 4 : 0,
                  shadowColor: isLastStep
                      ? const Color(0xFF10B981).withOpacity(0.4)
                      : AppTheme.primaryColor.withOpacity(0.4),
                ),
                child: provider.isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Submitting...',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastStep ? 'Submit Application' : 'Continue',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastStep ? Icons.check_circle : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepInfo {
  final String title;
  final IconData icon;
  
  _StepInfo(this.title, this.icon);
}
