import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:technician_app/core/providers/technician_provider.dart';
import 'package:technician_app/core/models/technician.dart';
import 'package:technician_app/screens/onboarding_steps/step1_basic_identity.dart';
import 'package:technician_app/screens/onboarding_steps/step2_professional_details.dart';
import 'package:technician_app/screens/onboarding_steps/step3_kyc_verification.dart';
import 'package:technician_app/screens/onboarding_steps/step4_bank_details.dart';
import 'package:technician_app/screens/onboarding_steps/step5_service_setup.dart';
import 'package:technician_app/screens/onboarding_steps/step6_success.dart';

class TechnicianOnboardingFlowScreen extends StatefulWidget {
  const TechnicianOnboardingFlowScreen({super.key});

  @override
  State<TechnicianOnboardingFlowScreen> createState() =>
      _TechnicianOnboardingFlowScreenState();
}

class _TechnicianOnboardingFlowScreenState
    extends State<TechnicianOnboardingFlowScreen> {
  late PageController _pageController;
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form data across steps
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _resumeFromLastStep();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Resume from last incomplete step
  void _resumeFromLastStep() {
    final provider = context.read<TechnicianProvider>();
    final tech = provider.technician;

    if (tech != null) {
      final step = tech.currentOnboardingStep;
      _currentStep = step.stepIndex;

      // Load existing data
      _formData['fullName'] = tech.name;
      _formData['email'] = tech.email;
      _formData['district'] = tech.district;
      _formData['experienceYears'] = tech.experienceYears;
      _formData['aadhaarNumber'] = tech.aadhaarNumber;
      _formData['profilePhotoUrl'] = tech.profilePhotoUrl;
      _formData['aadhaarFrontUrl'] = tech.aadhaarFrontUrl;
      _formData['aadhaarBackUrl'] = tech.aadhaarBackUrl;
      _formData['primaryCategoryId'] = tech.primaryCategoryId;
      _formData['primaryCategoryName'] = tech.primaryCategoryName;
      _formData['skills'] = tech.skills;
    }
  }

  Future<void> _nextStep() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    if (_currentStep == 5) {
      // Final submission
      await _submitApplication();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitApplication() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<TechnicianProvider>();
      await provider.submitKycApplication();

      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
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
                  Step1BasicIdentity(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      _formData[key] = value;
                    },
                  ),
                  Step2ProfessionalDetails(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      _formData[key] = value;
                    },
                  ),
                  Step3KycVerification(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      _formData[key] = value;
                    },
                  ),
                  Step4BankDetails(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      _formData[key] = value;
                    },
                  ),
                  Step5ServiceSetup(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      _formData[key] = value;
                    },
                  ),
                  const Step6Success(),
                ],
              ),
            ),
            if (_currentStep < 5) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of 6',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
              Text(
                _getStepTitle(_currentStep),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 6,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              TextButton(
                onPressed: _isSubmitting ? null : _previousStep,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Back'),
              ),
            const Spacer(),
            Expanded(
              flex: _currentStep > 0 ? 2 : 3,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _currentStep == 5 ? 'Submit' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    const titles = [
      'Basic Identity',
      'Professional Details',
      'KYC Verification',
      'Bank Details',
      'Service Setup',
      'Success',
    ];
    return titles[step];
  }
}
