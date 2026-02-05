import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../services/presentation/service_details_screen.dart';
import '../../services/presentation/service_list_screen.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/models/cart_item.dart';

class ServiceSection extends StatelessWidget {
  final String title;
  final bool isHorizontal;
  final bool isTopOnly;
  final String? category;

  const ServiceSection({
    super.key,
    required this.title,
    this.isHorizontal = true,
    this.isTopOnly = false,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('services').where('isActive', isEqualTo: true);
    
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    
    if (isTopOnly) {
      query = query.limit(5); // Simulated top services
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceListScreen(category: category))),
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
        StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final services = snapshot.data!.docs;
            
            if (services.isEmpty) return const SizedBox.shrink();

            if (isHorizontal) {
              return SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _HorizontalServiceCard(service: service);
                  },
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length > 6 ? 6 : services.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _VerticalServiceCard(service: service);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HorizontalServiceCard extends StatelessWidget {
  final QueryDocumentSnapshot service;
  const _HorizontalServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailsScreen(serviceId: service.id))),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SafeNetworkImage(
                  imageUrl: service['image'],
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              service['title'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textColor),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.orange, size: 14),
                const SizedBox(width: 4),
                Text(
                  '4.8',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.subtitleColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalServiceCard extends StatelessWidget {
  final QueryDocumentSnapshot service;
  const _VerticalServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailsScreen(serviceId: service.id))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SafeNetworkImage(
                      imageUrl: service['image'],
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      elevation: 2,
                      child: InkWell(
                        onTap: () async {
                          final cart = Provider.of<CartProvider>(context, listen: false);
                          await cart.addItem(CartItem(
                            id: '',
                            serviceId: service.id,
                            serviceName: service['title'],
                            serviceImage: service['image'],
                            price: (service['basePrice'] ?? 0.0).toDouble(),
                            quantity: 1,
                            totalPrice: (service['basePrice'] ?? 0.0).toDouble(),
                          ));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${service['title']} added to cart'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.add_rounded, color: AppTheme.primaryColor, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${service['basePrice']}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 12),
                            const SizedBox(width: 2),
                            Text('4.9', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.orange)),
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
    );
  }
}
