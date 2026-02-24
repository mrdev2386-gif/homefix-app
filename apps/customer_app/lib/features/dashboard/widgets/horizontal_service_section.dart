import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../services/presentation/service_details_screen.dart';
import '../../services/presentation/services_categories_screen.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/models/category.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'package:customer_app/core/services/category_service.dart';
import '../../../core/widgets/service_result_builder.dart';
import '../../../core/models/service_result.dart';

/// Reusable horizontal service section widget
/// 
/// Parameters:
/// - [title]: Section title to display
/// - [serviceFilter]: Function to filter services by category
/// - [maxItems]: Maximum number of services to show (default: 8)
class HorizontalServiceSection extends StatefulWidget {
  final String title;
  final bool Function(String category) serviceFilter;
  final int maxItems;
  final String? viewAllCategory;

  const HorizontalServiceSection({
    super.key,
    required this.title,
    required this.serviceFilter,
    this.maxItems = 8,
    this.viewAllCategory,
  });

  @override
  State<HorizontalServiceSection> createState() => _HorizontalServiceSectionState();
}

class _HorizontalServiceSectionState extends State<HorizontalServiceSection> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.viewAllCategory != null)
                GestureDetector(
                  onTap: () async {
                    if (_isNavigating) return;
                    _isNavigating = true;

                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServicesCategoriesScreen(),
                        ),
                      );
                    } finally {
                      if (mounted) {
                        _isNavigating = false;
                      }
                    }
                  },
                  child: Text(
                    'View all',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _HorizontalServiceSlider(
          serviceFilter: widget.serviceFilter,
          maxItems: widget.maxItems,
          viewAllCategory: widget.viewAllCategory,
        ),
      ],
    );
  }
}

class _HorizontalServiceSlider extends StatelessWidget {
  final bool Function(String category) serviceFilter;
  final int maxItems;
  final String? viewAllCategory;

  const _HorizontalServiceSlider({
    required this.serviceFilter,
    required this.maxItems,
    this.viewAllCategory,
  });

  @override
  Widget build(BuildContext context) {
    final CategoryService categoryService = CategoryService();
    
    final Stream<ServiceResult<List<HomeService>>> resultStream;
    if (viewAllCategory == 'trending' || viewAllCategory == 'new') {
      resultStream = categoryService.getRecentlyAddedServicesResult(limit: 20);
    } else {
      final String categoryId = viewAllCategory ?? 'cleaning';
      resultStream = categoryService.getServicesByCategoryResult(categoryId);
    }

    return ServiceResultBuilder<List<HomeService>>(
      stream: resultStream,
      loadingWidget: SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: 4,
          itemBuilder: (context, index) => _buildShimmerCard(),
        ),
      ),
      errorWidget: _buildErrorState(),
      emptyWidget: _buildEmptyState(),
      builder: (context, services) {
        final filteredServices = services.where((s) {
          return serviceFilter(s.category.toLowerCase());
        }).take(maxItems).toList();

        if (filteredServices.isEmpty) {
          return _buildEmptyState();
        }

        return _buildHorizontalSlider(filteredServices);
      },
    );
  }


  /// Build proper empty state UI to prevent silent failures
  Widget _buildEmptyState() {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              color: Colors.grey[400],
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'No services available',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state UI to prevent red screen
  Widget _buildErrorState() {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.grey[400],
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load services',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSlider(List<HomeService> services) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.45),
        physics: const BouncingScrollPhysics(),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          
          return _ServiceCard(
            serviceId: service.id,
            title: service.name,
            imageUrl: service.imageUrl,
            category: service.category,
            price: service.basePrice,
            service: service,
          );
        },
      ),
    );
  }


  Widget _buildShimmerCard() {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final String serviceId;
  final String title;
  final String imageUrl;
  final String category;
  final double price;
  final HomeService service;

  const _ServiceCard({
    required this.serviceId,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.service,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () async {
          if (_isNavigating) return;
          _isNavigating = true;

          try {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceDetailsScreen(
                  serviceId: widget.serviceId,
                  categoryId: widget.category,
                  serviceName: widget.title,
                  serviceData: widget.service,
                ),
              ),
            );
          } finally {
            if (mounted) {
              _isNavigating = false;
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox.expand(
                    child: SafeNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.price > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '₹${widget.price.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// DELETED redundant helper methods - logic moved to widget build and SafeNetworkImage
