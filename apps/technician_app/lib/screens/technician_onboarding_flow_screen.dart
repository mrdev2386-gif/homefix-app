import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:technician_app/core/providers/technician_provider.dart';
import 'package:technician_app/core/models/technician.dart';
import 'package:technician_app/screens/onboarding_steps/step1_basic_identity.dart';
import 'package:technician_app/screens/onboarding_steps/step2_professional_details.dart';
import 'package:technician_app/screens/onboarding_steps/step3_kyc_verification.dart';

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
  bool _isSavingStep = false;

  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeFromLastStep();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _resumeFromLastStep() {
    final provider = context.read<TechnicianProvider>();
    final tech = provider.technician;

    if (tech != null) {
      final step = tech.currentOnboardingStep;
      final stepsCompleted = tech.stepsCompleted ?? {};
      
      int safeStep = step.stepIndex;
      
      final completedSteps = [
        if (stepsCompleted['basic'] == true) 0,
        if (stepsCompleted['professional'] == true) 1,
        if (stepsCompleted['kyc'] == true) 2,
        if (stepsCompleted['services'] == true) 3,
      ];
      
      if (completedSteps.isNotEmpty) {
        final highestCompleted = completedSteps.last;
        if (highestCompleted > safeStep) {
          safeStep = highestCompleted;
        }
      }
      
      safeStep = safeStep.clamp(0, 3);
      
      if (_currentStep != safeStep) {
        setState(() {
          _currentStep = safeStep;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(safeStep);
        }
      }

      _formData['fullName'] = tech.name;
      _formData['email'] = tech.email;
      _formData['state'] = tech.state;
      _formData['district'] = tech.district;
      _formData['experienceYears'] = tech.experienceYears;
      _formData['aadhaarNumber'] = tech.aadhaarNumber;
      _formData['profilePhotoUrl'] = tech.profilePhotoUrl;
      _formData['aadhaarFrontUrl'] = tech.aadhaarFrontUrl;
      _formData['aadhaarBackUrl'] = tech.aadhaarBackUrl;
      _formData['primaryCategoryId'] = tech.primaryCategoryId;
      _formData['primaryCategoryName'] = tech.primaryCategoryName;
      _formData['skills'] = tech.skills;
      _formData['languagePreferences'] = tech.languagePreferences ?? [];
      _formData['referralCode'] = tech.referralCodeUsed;
      _formData['panNumber'] = tech.panNumber;
      _formData['accountType'] = tech.accountType;
      _formData['payoutPreference'] = tech.payoutPreference;

      _formData['maxDailyJobs'] = tech.maxDailyJobs;
      _formData['dynamicPricingAllowed'] = tech.dynamicPricingAllowed;
    }
  }

  Future<void> _nextStep() async {
    if (_isSavingStep) {
      debugPrint('[Onboarding] Blocked — already saving');
      return;
    }
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    if (_currentStep == 0) {
      final categories = _formData['primaryCategoryId'];
      if (categories == null || (categories is List && categories.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select at least one category'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    if (_currentStep == 4) {
      await _submitApplication();
    } else {
      await _saveCurrentStep();
    }
  }

  Future<void> _saveCurrentStep() async {
    if (_isSavingStep) return;

    setState(() => _isSavingStep = true);
    final stepToSave = _currentStep;
    debugPrint('[Onboarding] Attempt save step $stepToSave');

    try {
      final provider = context.read<TechnicianProvider>();
      final data = _getStepData(stepToSave);
      debugPrint('[ONBOARD_SAVE] payload=$data');
      
      await provider.saveStepData(
        step: stepToSave,
        data: data,
      );

      debugPrint('[Onboarding] Save completed, mounted=$mounted');
      if (!mounted) {
        debugPrint('[Onboarding] Widget unmounted, aborting');
        return;
      }

      final nextStep = stepToSave + 1;
      debugPrint('[Onboarding] Setting step to $nextStep');
      setState(() {
        _currentStep = nextStep;
      });
      
      debugPrint('[Onboarding] Moving to step $nextStep');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Step saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      debugPrint('[Onboarding] Calling nextPage');
      
      // CRITICAL FIX: Reset _isSavingStep BEFORE page transition
      // This allows onPageChanged to properly sync state during programmatic navigation
      if (mounted) {
        setState(() => _isSavingStep = false);
      }
      
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      debugPrint('[Onboarding] nextPage completed');
    } catch (e, st) {
      debugPrint('[Onboarding] ERROR: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection issue. Your progress is safe. Tap to retry.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _saveCurrentStep,
            ),
          ),
        );
      }
    } finally {
      // _isSavingStep already reset before nextPage() call above
      // This is a safety reset in case of exceptions before reaching nextPage
      if (mounted && _isSavingStep) {
        setState(() => _isSavingStep = false);
      }
    }
  }

  Map<String, dynamic> _getStepData(int step) {
    switch (step) {
      case 0:
        return {
          'name': _formData['fullName'] ?? '',
          'email': _formData['email'] ?? '',
          'state': _formData['state'] ?? '',
          'district': _formData['district'] ?? '',
          'experienceYears': _formData['experienceYears'] ?? 0,
          'gender': _formData['gender'],
          'dateOfBirth': _formData['dob'],
          'primaryCategoryId': _formData['primaryCategoryId'],
          'primaryCategoryName': _formData['primaryCategoryName'],
          'profilePhotoUrl': _formData['profilePhotoUrl'],
        };
      case 1:
        return {
          'bio': _formData['bio'],
          'languagePreferences': _formData['languagePreferences'] ?? [],
        };
      case 2:
        return {
          'aadhaarNumber': _formData['aadhaarNumber'],
          'aadhaarFrontUrl': _formData['aadhaarFrontUrl'],
          'aadhaarBackUrl': _formData['aadhaarBackUrl'],
          'panNumber': _formData['panNumber'],
        };
      case 3:
        return {
          'skills': _formData['skills'] ?? [],
          'basePrice': _formData['basePrice'],
          'visitingCharge': _formData['visitingCharge'],
          'maxTravelDistance': _formData['maxTravelDistance'],
          'maxDailyJobs': _formData['maxDailyJobs'],
          'dynamicPricingAllowed': _formData['dynamicPricingAllowed'] ?? false,
          'emergencyServiceAvailable': _formData['emergencyServiceAvailable'] ?? false,
        };
      default:
        return {};
    }
  }

  void _previousStep() {
    if (_currentStep > 0 && !_isSubmitting && !_isSavingStep) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitApplication() async {
    final provider = context.read<TechnicianProvider>();
    if (provider.isSubmittingApplication) return;

    setState(() => _isSubmitting = true);

    try {
      await provider.submitKycApplication();

      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        debugPrint('[OnboardingFlow] Submission error: $errorMsg');
        
        String displayMsg = errorMsg;
        if (errorMsg.contains('unavailable')) {
          displayMsg = 'Network issue detected. Your data is safe. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Submitting your application...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please do not close the app',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                  if (!_isSavingStep) {
                    debugPrint('[Onboarding] Page changed to $index');
                    setState(() => _currentStep = index);
                  }
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
            if (_currentStep < 4) _buildBottomBar(),
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
                'Step ${_currentStep + 1} of 5',
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
              value: (_currentStep + 1) / 5,
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back button — fixed width, no flex to avoid conflict
            if (_currentStep > 0) ...[
              TextButton(
                onPressed: (_isSubmitting || _isSavingStep) ? null : _previousStep,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
            ],
            // Continue button fills all remaining horizontal space
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isSavingStep || _isSubmitting) ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: (_isSubmitting || _isSavingStep)
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
                          _currentStep == 4 ? 'Submit' : 'Continue',
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
      'Personal Details',
      'Professional Details',
      'KYC Verification',
      'Availability',
      'Success',
    ];
    return titles[step];
  }
}
