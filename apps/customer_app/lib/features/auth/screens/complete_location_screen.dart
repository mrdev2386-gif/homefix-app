import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/services/location_service.dart';
import 'package:customer_app/core/services/functions_service.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/widgets/location_selector.dart';

/// Screen to force existing users to complete location if missing
class CompleteLocationScreen extends StatefulWidget {
  const CompleteLocationScreen({super.key});

  @override
  State<CompleteLocationScreen> createState() => _CompleteLocationScreenState();
}

class _CompleteLocationScreenState extends State<CompleteLocationScreen> {
  final LocationService _locationService = LocationService();
  final FunctionsService _functionsService = FunctionsService();
  String? selectedState;
  String? selectedDistrict;
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    if (selectedState == null || selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both state and district')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save to SharedPreferences
      await _locationService.saveLocation(selectedState!, selectedDistrict!);

      // Update Firestore via Cloud Function
      // This will create address and set primaryAddressId
      await _functionsService.updateUserProfile({
        'state': selectedState,
        'district': selectedDistrict,
        'profileCompleted': true,
      });

      if (mounted) {
        // CRITICAL: Clear location cache BEFORE navigation (MANDATORY)
        debugPrint('[CompleteLocation] Clearing location cache...');
        final categoryService = Provider.of<CategoryService>(context, listen: false);
        categoryService.clearLocationCache();
        
        // Force immediate refresh by notifying listeners
        categoryService.notifyListeners();
        debugPrint('[CompleteLocation] ✅ Location cache cleared successfully');
        
        // Navigate AFTER cache is cleared
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF6366F1),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Complete Your Location',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We need your location to show you available services in your area',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  LocationSelector(
                    onLocationChanged: (state, district) {
                      if (!mounted) return;
                      setState(() {
                        selectedState = state;
                        selectedDistrict = district;
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Continue',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
