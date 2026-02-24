import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/models/service.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../services/presentation/service_details_screen.dart';
import 'package:customer_app/core/models/category.dart';

class ProfessionalHomeServiceSection extends StatefulWidget {
  final List<HomeService> services;

  const ProfessionalHomeServiceSection({
    super.key,
    required this.services,
  });

  @override
  State<ProfessionalHomeServiceSection> createState() => _ProfessionalHomeServiceSectionState();
}

class _ProfessionalHomeServiceSectionState extends State<ProfessionalHomeServiceSection> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    if (widget.services.isEmpty) {
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
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: (widget.services.length / 2).ceil(),
            primary: false,
            shrinkWrap: false,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            addSemanticIndexes: false,
            itemBuilder: (context, rowIndex) {
              final firstIndex = rowIndex * 2;
              final secondIndex = firstIndex + 1;
              final firstService = widget.services[firstIndex];
              final secondService = secondIndex < widget.services.length ? widget.services[secondIndex] : null;

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (_isNavigating) return;
          if (service.id.isEmpty) {
            debugPrint('❌ Navigation blocked: Missing serviceId');
            return;
          }
          _isNavigating = true;

          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceDetailsScreen(
                  serviceId: service.id,
                  categoryId: service.category,
                  serviceName: service.title,
                  serviceData: service,
                ),
              ),
            );
          } finally {
            if (mounted) {
              _isNavigating = false;
            }
          }
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
                SafeNetworkImage(
                  imageUrl: service.imageUrl,
                  fit: BoxFit.cover,
                  serviceName: service.title,
                ),
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
