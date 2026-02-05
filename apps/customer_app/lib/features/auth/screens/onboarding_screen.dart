import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/functions_service.dart';
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
          'isOnboarded': true,
          'defaultAddress': locationProvider.currentAddress,
          'latitude': locationProvider.currentPosition?.latitude,
          'longitude': locationProvider.currentPosition?.longitude,
        });
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
          );
        }
      }
    } catch (e) {
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
          const SizedBox(height: 40),
          Text(
            'Where do you\nneed service?',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enable location so we can find the best pros in your area.',
            style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 60),
          Center(
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded, size: 80, color: Color(0xFF6366F1)),
            ),
          ),
          const Spacer(),
          Consumer<LocationProvider>(
            builder: (context, location, _) {
              final hasLocation = location.currentPosition != null && 
                                  location.currentAddress != 'Fetching location...';
              
              return Column(
                children: [
                  if (hasLocation)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              location.currentAddress,
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[800]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        if (hasLocation) {
                          await _completeOnboarding();
                        } else {
                          await location.updateCurrentLocation();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasLocation ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(hasLocation ? 'Finish' : 'Allow Access', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  if (!hasLocation)
                    TextButton(
                      onPressed: () {
                        // Manual entry simulation or skipping with default
                        _completeOnboarding();
                      },
                      child: Text('Skip for now', style: GoogleFonts.outfit(color: Colors.grey)),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
