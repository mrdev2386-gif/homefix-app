import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/service.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/widgets/safe_cached_image.dart';
import '../../../core/theme/app_theme.dart';

class ProfessionalHomeServiceSection extends StatelessWidget {
  final List<HomeService> services;

  const ProfessionalHomeServiceSection({
    super.key,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Professional Home Service',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
        ),
        // 2 rows of 2 cards each - horizontal swipe with hardened performance
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: (services.length / 2).ceil(),
            primary: false,
            shrinkWrap: false,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            addSemanticIndexes: false,
            pageStorageKey: const PageStorageKey('professional_home_service'),
            itemBuilder: (context, rowIndex) {
              final firstIndex = rowIndex * 2;
              final secondIndex = firstIndex + 1;
              final firstService = services[firstIndex];
              final secondService = secondIndex < services.length ? services[secondIndex] : null;

              return RepaintBoundary(
                child: _buildRowCard(firstService, secondService),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRowCard(HomeService firstService, HomeService? secondService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(child: _buildLargeServiceCard(firstService)),
        if (secondService != null) ...[
          const SizedBox(width: 12),
          RepaintBoundary(child: _buildLargeServiceCard(secondService)),
        ],
      ],
    );
  }

  Widget _buildLargeServiceCard(HomeService service) {
    final double cacheWidth = (180 * 2).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to service details
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image with memory optimization
                SafeCachedImage(
                  imageUrl: service.imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: cacheWidth,
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
                // Content
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        service.title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${service.basePrice.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  service.rating.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
