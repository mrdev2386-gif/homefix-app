import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/service.dart';
import '../../../core/widgets/safe_network_image.dart';

class ServiceCard extends StatelessWidget {
  final HomeService service;
  final VoidCallback onAddToCart;
  final VoidCallback onBookNow;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onAddToCart,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section - Using SafeNetworkImage with proper handling
          Expanded(
            flex: 12,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Dynamic Network Image with shimmer loading
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  child: SafeNetworkImage(
                    imageUrl: service.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    usePlaceholder: true,
                    fallbackUrl: '',
                  ),
                ),

                // Top Service Badge
                if (service.isTopService)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'PREMIUM',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // Trending Badge
                if (service.isTrending)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 12,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Trending',
                            style: GoogleFonts.outfit(
                              color: Colors.orange[700],
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details Section
          Expanded(
            flex: 11,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Name
                      Text(
                        service.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          Text(
                            service.basePrice.toStringAsFixed(0),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/${service.duration}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Rating Row
                      if (service.rating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              service.rating.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            if (service.reviewCount > 0)
                              Text(
                                ' (${service.reviewCount})',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Book Now Button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onBookNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Book Now',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
