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

/// Recent Services Section - shows services ordered by createdAt
class RecentlyAddedServicesSection extends StatelessWidget {
  final Set<String> displayedServiceIds;
  final int limit;
  final bool showViewAll;
  final VoidCallback? onViewAllTap;

  const RecentlyAddedServicesSection({
    super.key,
    required this.displayedServiceIds,
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
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.new_releases_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Recently Added',
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
        
        // Horizontal Scroll - FIX #3: Enforce limit to 10 services
        SizedBox(
          height: 180,
          child: StreamBuilder<List<HomeService>>(
            stream: CategoryService().getRecentlyAddedServices(limit: limit),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingShimmer();
              }
              
              if (snapshot.hasError) {
                return _buildErrorState();
              }
              
              final services = snapshot.data ?? [];
              if (services.isEmpty) {
                return _buildEmptyState();
              }
              
              // Filter out already displayed services to avoid duplicates
              final filteredServices = services
                  .where((s) => !displayedServiceIds.contains(s.id))
                  .take(limit)
                  .toList();
              
              if (filteredServices.isEmpty) {
                return _buildEmptyState();
              }
              
              return _buildHorizontalList(filteredServices);
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
        return _RecentServiceCard(service: services[index]);
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
            width: 140,
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

  Widget _buildErrorState() {
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
          Icon(Icons.new_releases_outlined, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            'No new services',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _RecentServiceCard extends StatefulWidget {
  final HomeService service;

  const _RecentServiceCard({required this.service});

  @override
  State<_RecentServiceCard> createState() => _RecentServiceCardState();
}

class _RecentServiceCardState extends State<_RecentServiceCard> {
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
                serviceName: widget.service.title,
                serviceData: widget.service,
              ),
            ),
          );
        } finally {
          if (mounted) _isNavigating = false;
        }
      },
      child: Container(
        width: 140,
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SafeNetworkImage(
                imageUrl: widget.service.imageUrl ?? '',
                width: 140,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        widget.service.title,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${widget.service.basePrice.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
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
