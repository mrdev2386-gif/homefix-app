import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/category.dart';
import '../../../core/models/service.dart';
import '../../../core/firestore/category_service.dart';
import '../../../core/firestore/matching_service.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/widgets/no_technicians_popup.dart';
import '../../../core/widgets/matching_loading_overlay.dart';
import 'sub_service_screen.dart';
import 'technician_selection_screen.dart';
import '../../../../core/theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    
    _categoryService.getServicesByCategory(widget.category.id).listen(
      (services) {
        if (mounted) {
          setState(() {
            _services = services;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Error fetching services: $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _handleServiceTap(HomeService service) async {
    // Check if service has sub-services
    final hasSubServices = await _categoryService.serviceHasSubServices(
      widget.category.id,
      service.id,
    );

    if (hasSubServices) {
      // Navigate to sub-service selection
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubServiceScreen(
            category: widget.category,
            service: service,
          ),
        ),
      );
    } else {
      // Directly trigger matching
      _matchTechnicians(service.id, null);
    }
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
    
    // Get matching result
    final response = await _matchingService.matchTechnicians(
      serviceId: serviceId,
      subServiceId: subServiceId,
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
      body: _isLoading
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
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
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
            Icons.home_repair_service_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No services available',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final HomeService service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final effectiveImageUrl = service.imageUrl ?? service.getFallbackImageUrl();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Service image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SafeNetworkImage(
                imageUrl: effectiveImageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            // Service info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Starting at',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
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
            ),
            // Arrow indicator
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
