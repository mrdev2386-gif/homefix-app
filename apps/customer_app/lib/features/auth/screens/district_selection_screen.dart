import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/services/user_location_service.dart';
import 'package:customer_app/core/services/functions_service.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/widgets/location_selector.dart';

class DistrictSelectionScreen extends StatefulWidget {
  const DistrictSelectionScreen({super.key});

  @override
  State<DistrictSelectionScreen> createState() => _DistrictSelectionScreenState();
}

class _DistrictSelectionScreenState extends State<DistrictSelectionScreen> {
  final UserLocationService _locationService = UserLocationService();
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
      // This will now create an address and set primaryAddressId
      await _functionsService.updateUserProfile({
        'state': selectedState,
        'district': selectedDistrict,
      });

      if (mounted) {
        // Clear location cache to force refresh
        try {
          final categoryService = Provider.of<CategoryService>(context, listen: false);
          categoryService.clearLocationCache();
        } catch (e) {
          // Provider might not be available in all contexts
          debugPrint('Could not clear location cache: $e');
        }
        
        Navigator.of(context).pushReplacementNamed('/home');
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
    return Scaffold(
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
                  'Select Your Location',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ll show you services available in your area',
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
    );
  }
}
