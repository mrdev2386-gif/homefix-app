
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/services/functions_service.dart';
import '../../../core/providers/location_provider.dart';
import '../../services/presentation/service_list_screen.dart';

class CleaningEssentialsSection extends StatefulWidget {
  final List<CleaningEssential> essentials;

  const CleaningEssentialsSection({
    super.key,
    required this.essentials,
  });

  @override
  State<CleaningEssentialsSection> createState() => _CleaningEssentialsSectionState();
}

class _CleaningEssentialsSectionState extends State<CleaningEssentialsSection> {
  bool _isLoading = false;

  Future<void> _handleCategoryTap(BuildContext context, CleaningEssential essential) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final functionsService = Provider.of<FunctionsService>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      final latitude = locationProvider.selectedAddress?.latitude ?? 0.0;
      final longitude = locationProvider.selectedAddress?.longitude ?? 0.0;

      final result = await functionsService.findEligibleTechniciansCount(
        essential.categoryId,
        {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (mounted) {
        if (result['isAvailable'] == true) {
          // Allow booking - navigate to service list for this category
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceListScreen(
                category: essential.categoryId,
              ),
            ),
          );
        } else {
          // No technician found
          _showNotAvailableDialog(context, essential.title);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking availability: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNotAvailableDialog(BuildContext context, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Service not available', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        content: Text(
          'We currently don\'t have any professionals for $categoryName within 25 KM of your location. We are expanding rapidly!',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OKAY', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.essentials.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "Admin has not added content yet",
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              const Icon(Icons.clean_hands_rounded, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 8),
              Text(
                'Cleaning Essentials',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: widget.essentials.length,
            controller: PageController(viewportFraction: 0.92),
            key: const PageStorageKey('cleaning_essentials'),
            itemBuilder: (context, index) {
              final essential = widget.essentials[index];
              return RepaintBoundary(
                child: _buildLargeCard(context, essential),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLargeCard(BuildContext context, CleaningEssential essential) {
    final double cacheWidth = (380 * 2).toDouble();
    
    return GestureDetector(
      onTap: _isLoading ? null : () => _handleCategoryTap(context, essential),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image with memory optimization
              SafeNetworkImage(
                imageUrl: essential.imageUrl,
                fit: BoxFit.cover,
                serviceName: essential.title,
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Label
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            essential.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Professional Cleaning Services',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
