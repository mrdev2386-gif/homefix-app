import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/models/service.dart';
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
    final double finalPrice = service.finalPrice;
    final double price = service.price;
    final bool hasOffer = service.offerPrice != null && 
                          service.offerPrice! > 0 && 
                          service.offerPrice! < price;

    return GestureDetector(
      onTap: _navigateToDetails,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // IMAGE
            AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: SafeNetworkImage(
                      imageUrl: service.imageUrl ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (service.rating > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 12),
                            const SizedBox(width: 2),
                            Text(
                              service.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Consumer<FavoritesProvider>(
                      builder: (context, favorites, _) {
                        final isFavorite = favorites.isFavorite(service.id);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            favorites.toggleFavorite(service.id, service.category);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFavorite ? Colors.red : Colors.grey[600],
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT - Optimized responsive layout
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title with flexible wrapping
                    Flexible(
                      child: Text(
                        service.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Price row - main price gets priority with Expanded
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "₹${finalPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasOffer) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "₹${price.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    // Button with minimum touch target height
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 32,
                        maxHeight: 36,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _navigateToDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
