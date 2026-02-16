import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/safe_cached_image.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../services/presentation/service_details_screen.dart';
import '../../../core/models/service.dart';

class ServiceSpotlightSection extends StatelessWidget {
  const ServiceSpotlightSection({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    debugPrint("[Firestore] streaming service_spotlight...");
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestoreService.streamServiceSpotlight(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final spotlightServices = snapshot.data ?? [];
        if (spotlightServices.isEmpty) {
          debugPrint("[Firestore] service_spotlight is empty");
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                'Spotlight deals are taking a break!',
                style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
        debugPrint("[Firestore] service_spotlight docs: ${spotlightServices.length}");

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'In the Spotlight',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'FEATURED',
                      style: GoogleFonts.outfit(
                        color: Colors.amber.shade900,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: spotlightServices.length,
                itemBuilder: (context, index) {
                  final serviceData = spotlightServices[index];
                  return _buildSpotlightCard(context, serviceData);
                },
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildSpotlightCard(BuildContext context, Map<String, dynamic> data) {
    final availableTechs = data['availableTechnicians'] ?? 0;
    // Ultra-safe price parsing - prevents type cast crash
    final rawPrice = data['price'] ?? data['basePrice'] ?? 0;
    final double price = (rawPrice is num) ? rawPrice.toDouble() : 0.0;
    // Ultra-safe rating parsing
    final rawRating = data['rating'] ?? 0;
    final double rating = (rawRating is num) ? rawRating.toDouble() : 0.0;
    final String serviceId = data['serviceId'] ?? data['id'] ?? '';
    final String title = data['serviceName'] ?? data['title'] ?? 'Service';
    final String? imageUrl = data['imageUrl'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(
              serviceId: serviceId,
              initialService: HomeService(
                id: serviceId,
                key: serviceId,
                title: title,
                imageAssetPath: imageUrl ?? '',
                description: data['description'] ?? '',
                category: data['category'] ?? '',
                basePrice: price,
                rating: rating,
                reviewCount: data['reviewCount'] ?? 0,
                isActive: true,
                isTopService: true,
                order: 0,
                createdAt: DateTime.now(),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Hero(
                    tag: 'spotlight_$serviceId',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: AppTheme.accentColor,
                        child: (imageUrl?.isNotEmpty ?? false)
                            ? (() {
                                print("IMAGE URL => $imageUrl");
                                return SafeCachedImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                );
                              }())
                            : Icon(Icons.home_repair_service_rounded, size: 40, color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Info Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, size: 18, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                    const Divider(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 14,
                          color: availableTechs > 0 ? Colors.teal : Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          availableTechs > 0 
                            ? '$availableTechs Experts Nearby' 
                            : 'No Experts Online',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: availableTechs > 0 ? Colors.teal : Colors.blueGrey,
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
      ),
    );
  }
}
