
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 1;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentStep();
  }

  Future<void> _fetchCurrentStep() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // In a real app, we'd fetch this from the 'technicianApplications' collection
      // For now, we'll start at step 1 or based on some fast logic
      // Simulating a fetch...
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _currentStep = 1; // Default to step 1
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error.isNotEmpty) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Technician Setup - Step $_currentStep')),
      body: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _Step1PhoneVerification(onNext: () => setState(() => _currentStep = 2));
      case 2:
        return _Step2PersonalDetails(onNext: () => setState(() => _currentStep = 3));
      // Add other steps...
      default:
        return const Center(child: Text('Unknown Step'));
    }
  }
}

class _Step1PhoneVerification extends StatelessWidget {
  final VoidCallback onNext;
  const _Step1PhoneVerification({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Step 1: Phone Verification (Mock)'),
          ElevatedButton(onPressed: onNext, child: const Text('Verify & Continue')),
        ],
      ),
    );
  }
}

class _Step2PersonalDetails extends StatelessWidget {
  final VoidCallback onNext;
  const _Step2PersonalDetails({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Step 2: Personal Details (Mock)'),
          ElevatedButton(onPressed: onNext, child: const Text('Save & Continue')),
        ],
      ),
    );
  }
}
