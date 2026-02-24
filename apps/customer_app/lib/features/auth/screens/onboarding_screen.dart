import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import 'package:customer_app/core/services/functions_service.dart';
import '../../../core/providers/location_provider.dart';
import '../../home/main_wrapper_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final functionsService = Provider.of<FunctionsService>(context, listen: false);
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final user = authService.currentUser;
      if (user != null) {
        await functionsService.updateUserProfile({
          'name': _nameController.text.trim(),
          'displayName': _nameController.text.trim(),
          'isOnboarded': true,
          'profileCompleted': true,
          'district': locationProvider.selectedDistrict ?? 'Unknown',
          'defaultAddress': locationProvider.selectedDistrict ?? 'Unknown',
          'latitude': 0.0,
          'longitude': 0.0,
        });
        
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: List.generate(2, (index) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index <= _currentStep ? const Color(0xFF6366F1) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildNameStep(),
                  _buildLocationStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'What should we\ncall you?',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your full name so we can personalize your experience.',
            style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _nameController,
            onChanged: (val) => setState(() {}),
            autofocus: true,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Full Name',
              hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontWeight: FontWeight.normal),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nameController.text.trim().length >= 3
                  ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Where do you\nneed service?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all set to find the best pros in your area.',
            style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 32),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, size: 64, color: Color(0xFF6366F1)),
              ),
            ),
          ),
          const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _completeOnboarding(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Finish Onboarding', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                    ),
                  ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
