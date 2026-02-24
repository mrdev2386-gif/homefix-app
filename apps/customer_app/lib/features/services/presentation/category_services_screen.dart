import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/models/sub_service.dart';
import 'package:customer_app/core/services/category_service.dart';
import '../../../core/services/matching_service.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/widgets/no_technicians_popup.dart';
import '../../../core/widgets/matching_loading_overlay.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/location_provider.dart';
import 'service_details_screen.dart';
import 'technician_selection_screen.dart';
import 'package:customer_app/core/theme/app_theme.dart';

class CategoryServicesScreen extends StatefulWidget {
  final Category category;

  const CategoryServicesScreen({
    super.key, 
    required this.category,
  });

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  final CategoryService _categoryService = CategoryService();
  final MatchingService _matchingService = MatchingService();
  bool _isLoading = true;
  List<HomeService> _services = [];
  StreamSubscription? _servicesSubscription;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  void dispose() {
    _servicesSubscription?.cancel();
    super.dispose();
  }

  void _fetchServices() {
    setState(() => _isLoading = true); // Keep this line to show loading on refresh
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔍 [CategoryServicesScreen] Starting fetch...');
    debugPrint('   category.id = ${widget.category.id}');
    debugPrint('   category.name = ${widget.category.name}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _servicesSubscription?.cancel();
    _servicesSubscription = _categoryService
        .getServicesByCategoryResult(widget.category.id)
        .listen(
      (result) {
        final services = result.data ?? [];
        debugPrint('📦 [CategoryServicesScreen] Stream event received');
        debugPrint('   services.length = ${services.length}');
        
        if (mounted) {
          setState(() {
            _services = services;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('❌ [CategoryServicesScreen] Stream ERROR: $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _handleServiceTap(HomeService service) async {
    if (!mounted) return;

    // ✅ Pass widget.category.id (the Firestore doc ID) explicitly.
    // This is the ONLY safe source — it comes directly from the Category object
    // that was navigated to this screen, which holds the real Firestore doc ID.
    // Never rely on service.category which may be a display name.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(
          serviceId: service.id,
          categoryId: widget.category.id, // ✅ Firestore doc ID — guaranteed correct
          serviceName: service.title,
          serviceData: service,
        ),
      ),
    );
  }

  Future<void> _matchTechnicians(String serviceId, String? subServiceId) async {
    // Use the new loading overlay with timeout
    bool isTimedOut = false;
    
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secondaryAnim) {
        return MatchingLoadingOverlay(
          onTimeout: () {
            isTimedOut = true;
            Navigator.of(context).pop();
          },
          message: 'Finding best professionals for ${widget.category.name}...',
        );
      },
    );
    
    if (isTimedOut) {
      // Show timeout popup
      if (!mounted) return;
      NoTechniciansPopup.show(
        context: context,
        onRetry: () => _matchTechnicians(serviceId, subServiceId),
        onChangeService: () {
          Navigator.of(context)..pop()..pop();
        },
        customMessage: 'Taking longer than expected. Please try again or choose a different service.',
      );
      return;
    }
    
    // Check if already navigated away
    if (!mounted) return;
    
    // 1. Get location from LocationProvider (SOLE SOURCE OF TRUTH)
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    double? latitude = locationProvider.selectedAddress?.latitude;
    double? longitude = locationProvider.selectedAddress?.longitude;

    // 2. Fallback to 0.0 if no specific coordinates (we should ideally have district-based matching)
    // For now, we use existing matching service logic which requires lat/lng
    latitude ??= 0.0;
    longitude ??= 0.0;

    // 3. Get matching result
    final response = await _matchingService.matchTechnicians(
      serviceId: serviceId,
      subServiceId: subServiceId,
      latitude: latitude,
      longitude: longitude,
    );
    
    if (!mounted) return;
    
    if (response.available && response.topTechnicians != null) {
      // Navigate to technician selection
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TechnicianSelectionScreen(
            technicians: response.topTechnicians!,
            serviceId: serviceId,
            subServiceId: subServiceId,
          ),
        ),
      );
    } else {
      // Show no technicians popup
      NoTechniciansPopup.show(
        context: context,
        onRetry: () => _matchTechnicians(serviceId, subServiceId),
        onChangeService: () {
          Navigator.of(context)..pop()..pop();
        },
        customMessage: response.error,
      );
    }
  }

  void _showLoadingDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secondaryAnim) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Finding professionals...',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.name,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textColor,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchServices();
        },
        child: _isLoading
            ? _buildShimmerLoading()
            : _services.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return _ServiceCard(
                      service: service,
                      onTap: () => _handleServiceTap(service),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No services found in this category',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final HomeService service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  SubService? _selectedSubService;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final hasSubServices = service.subServices.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (hasSubServices) {
                setState(() => _isExpanded = !_isExpanded);
              } else {
                widget.onTap();
              }
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(20),
              bottom: Radius.circular(_isExpanded ? 0 : 20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SafeNetworkImage(
                      imageUrl: service.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                service.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (service.technicianDistrict != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  service.technicianDistrict!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_pin_rounded, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              service.technicianName ?? 'Verified Professional',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.subtitleColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              service.rating.toString(),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Starting from',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.subtitleColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${service.basePrice.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (hasSubServices && _isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Select a variant',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...service.subServices.map((sub) => _buildSubServiceTile(sub)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedSubService == null ? null : () {
                        // Handle request with sub-service
                        widget.onTap(); 
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Request Now',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubServiceTile(SubService sub) {
    final isSelected = _selectedSubService?.id == sub.id;
    return InkWell(
      onTap: () => setState(() => _selectedSubService = sub),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sub.name,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              '₹${sub.price.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact favorite button for list cards
class _SmallFavoriteButton extends StatelessWidget {
  final HomeService service;

  const _SmallFavoriteButton({required this.service});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.read<FavoritesProvider>().toggleFavorite(service.id, service.category);
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.red.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Consumer<FavoritesProvider>(
            builder: (context, favorites, _) {
              final isFavorite = favorites.isFavorite(service.id);
              return Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 16,
                color: isFavorite ? Colors.red : Colors.grey[600],
              );
            },
          ),
        ),
      ),
    );
  }
}
