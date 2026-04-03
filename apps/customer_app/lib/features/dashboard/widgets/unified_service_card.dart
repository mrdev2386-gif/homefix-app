import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/providers/favorites_provider.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../services/presentation/service_details_screen.dart';

class UniversalServiceCard extends StatefulWidget {
  final HomeService service;
  final bool isGrid;
  final VoidCallback? onNavigateToDetails;

  const UniversalServiceCard({
    super.key,
    required this.service,
    this.isGrid = false,
    this.onNavigateToDetails,
  });

  @override
  State<UniversalServiceCard> createState() => _UniversalServiceCardState();
}

class _UniversalServiceCardState extends State<UniversalServiceCard> {
  bool _isNavigating = false;

  void _navigateToDetails() async {
    if (_isNavigating) return;
    
    _isNavigating = true;
    HapticFeedback.lightImpact();
    
    try {
      if (widget.onNavigateToDetails != null) {
        widget.onNavigateToDetails!();
      } else {
        if (mounted) {
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
        }
      }
    } finally {
      if (mounted) {
        _isNavigating = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    
    final hasOffer = service.offerPrice != null && 
                     service.offerPrice! > 0 && 
                     service.offerPrice! < service.basePrice;
    
    final discount = hasOffer 
        ? ((service.basePrice - service.offerPrice!) / service.basePrice * 100).round()
        : 0;

    final finalPrice = hasOffer ? service.offerPrice! : service.basePrice;

    if (kDebugMode && hasOffer) {
      debugPrint('🏷️ [DISCOUNT_CARD] ${service.title}: ₹${service.basePrice} → ₹${service.offerPrice} ($discount% OFF)');
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: widget.isGrid ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: widget.isGrid ? null : 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // IMAGE SECTION
            GestureDetector(
              onTap: _navigateToDetails,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: SizedBox(
                      height: 130,
                      width: double.infinity,
                      child: SafeNetworkImage(
                        imageUrl: service.imageUrl ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Rating badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            service.rating > 0
                                ? service.rating.toStringAsFixed(1)
                                : 'New',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<FavoritesProvider>(
                      builder: (context, favorites, _) {
                        final isFavorite = favorites.isFavorite(service.id);
                        return GestureDetector(
                          onTap: () => favorites.toggleFavorite(
                            service.id,
                            service.category,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? Colors.red
                                  : Colors.grey[600],
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Price & Discount section
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (service.urgentBookingEnabled)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.flash_on,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Urgent',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (discount > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$discount% OFF',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${finalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (hasOffer)
                                Text(
                                  '₹${service.basePrice.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT SECTION
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.person_pin_rounded,
                          size: 11,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            service.technicianName ?? 'Verified Pro',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.subtitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    if (service.technicianDistrict != null &&
                        service.technicianDistrict!.isNotEmpty) ...[  
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          service.technicianDistrict!.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.blue[700],
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: _navigateToDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Get Service',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
