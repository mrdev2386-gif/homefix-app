import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/services/category_service.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/models/service_result.dart';
import '../../services/presentation/service_details_screen.dart';

/// Premium Top Rated Services Section with horizontal scrolling
/// Filter: rating >= 4.0
class TopRatedServicesSection extends StatelessWidget {
  final int limit;
  final bool showViewAll;
  final VoidCallback? onViewAllTap;

  const TopRatedServicesSection({
    super.key,
    this.limit = 10,
    this.showViewAll = true,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Top Rated Services',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
              if (showViewAll)
                GestureDetector(
                  onTap: onViewAllTap,
                  child: Text(
                    'View All',
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
        
        // Horizontal Scroll
        SizedBox(
          height: 200,
          child: StreamBuilder<ServiceResult<List<HomeService>>>(
            stream: CategoryService().getTopRatedServicesResult(limit: limit),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingShimmer();
              }
              
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }
              
              final result = snapshot.data;
              if (result == null || result.isEmpty) {
                return _buildEmptyState();
              }
              
              return _buildHorizontalList(result.data!);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalList(List<HomeService> services) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _PremiumRatedCard(service: services[index]);
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.white,
          child: Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            'Unable to load',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border_rounded, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            'No top rated services yet',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// Premium card for top rated services with rating badge
class _PremiumRatedCard extends StatefulWidget {
  final HomeService service;

  const _PremiumRatedCard({required this.service});

  @override
  State<_PremiumRatedCard> createState() => _PremiumRatedCardState();
}

class _PremiumRatedCardState extends State<_PremiumRatedCard> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isNavigating) return;
        _isNavigating = true;
        HapticFeedback.lightImpact();
        
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailsScreen(
                serviceId: widget.service.id,
                categoryId: widget.service.category,
                serviceName: widget.service.name,
                serviceData: widget.service,
              ),
            ),
          );
        } finally {
          if (mounted) _isNavigating = false;
        }
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
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
            // Image with Rating Badge
            Stack(
              children: [
                // Image - use SizedBox with fixed dimensions, no double.infinity
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    width: 150,
                    height: 100,
                    child: SafeNetworkImage(
                      imageUrl: widget.service.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Rating Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB800),
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.service.rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service.name,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₹${widget.service.basePrice.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        if (widget.service.reviewCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(${widget.service.reviewCount})',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
