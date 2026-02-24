import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/location_provider.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../home/main_wrapper_screen.dart';

/// District Selection Screen - Mandatory after signup/login
/// User MUST select a district before accessing the app
class DistrictSelectionScreen extends StatefulWidget {
  const DistrictSelectionScreen({super.key});

  @override
  State<DistrictSelectionScreen> createState() => _DistrictSelectionScreenState();
}

class _DistrictSelectionScreenState extends State<DistrictSelectionScreen> {
  String? _selectedDistrict;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  
  // List of predefined districts (can be fetched from Firestore in production)
  final List<String> _districts = [
    'Ahmedabad',
    'Bangalore',
    'Bhopal',
    'Chennai',
    'Coimbatore',
    'Delhi',
    'Gurgaon',
    'Hyderabad',
    'Indore',
    'Jaipur',
    'Kolkata',
    'Lucknow',
    'Mumbai',
    'Nagpur',
    'Patna',
    'Pune',
    'Ranchi',
    'Surat',
    'Thane',
    'Vadodara',
    'Visakhapatnam',
  ];

  List<String> get _filteredDistricts {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _districts;
    return _districts.where((d) => d.toLowerCase().contains(query)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveDistrict() async {
    if (_selectedDistrict == null) return;

    setState(() => _isLoading = true);
    
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final success = await locationProvider.setSelectedDistrict(_selectedDistrict!);
      
      if (!mounted) return;
      
      if (success) {
        // Save profileCompleted flag to Firestore
        final authService = Provider.of<AuthService>(context, listen: false);
        if (authService.currentUser != null) {
          await FirebaseFirestore.instance
              .collection('customers')
              .doc(authService.currentUser!.uid)
              .update({
            'profileCompleted': true,
          });
        }
        
        // Navigate to main wrapper
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save district. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Select Your District',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'This helps us provide services in your area.\nYour district will be saved to your profile.',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search district...',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.grey[400],
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[400],
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Districts List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filteredDistricts.length,
                itemBuilder: (context, index) {
                  final district = _filteredDistricts[index];
                  final isSelected = _selectedDistrict == district;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryColor.withOpacity(0.1) 
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedDistrict = district;
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryColor.withOpacity(0.2)
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected 
                              ? Icons.check_rounded 
                              : Icons.location_city_outlined,
                          color: isSelected 
                              ? AppTheme.primaryColor 
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        district,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: isSelected 
                              ? FontWeight.w700 
                              : FontWeight.w500,
                          color: isSelected 
                              ? AppTheme.primaryColor 
                              : AppTheme.textColor,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedDistrict == null || _isLoading 
                      ? null 
                      : _saveDistrict,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
