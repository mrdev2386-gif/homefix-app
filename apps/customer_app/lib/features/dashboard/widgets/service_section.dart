import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../services/presentation/service_details_screen.dart';
import '../../services/presentation/service_list_screen.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/models/cart_item.dart';

class ServiceListSection extends StatefulWidget {
  final String title;
  final bool isHorizontal;
  final bool isTopOnly;
  final String? category;
  final int? limit;

  const ServiceListSection({
    super.key,
    required this.title,
    this.isHorizontal = true,
    this.isTopOnly = false,
    this.category,
    this.limit,
  });

  @override
  State<ServiceListSection> createState() => _ServiceListSectionState();
}

class _ServiceListSectionState extends State<ServiceListSection> {
  bool _isNavigating = false;
  late Stream<QuerySnapshot> _serviceStream;

  @override
  void initState() {
    super.initState();
    // AUDIT: Using collectionGroup to support nested categories/{catId}/services source
    Query query = FirebaseFirestore.instance.collectionGroup('services').where('isActive', isEqualTo: true);
    
    if (widget.category != null && widget.category!.isNotEmpty && widget.category != 'all') {
      // Filter by categoryId field on the service document
      query = query.where('categoryId', isEqualTo: widget.category);
    }
    
    if (widget.limit != null) {
      query = query.limit(widget.limit!);
    } else if (widget.isTopOnly) {
      query = query.limit(5); // Simulated top services
    }
    _serviceStream = query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (_isNavigating) return;
                  _isNavigating = true;

                  try {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceListScreen(category: widget.category)));
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
        StreamBuilder<QuerySnapshot>(
          stream: _serviceStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Loading shimmer
              return SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.white,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            
            final services = snapshot.data?.docs ?? [];
            // DEBUG: Log service count
            debugPrint('[SERVICE_COUNT] ${services.length}');
            if (services.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'No services available',
                  style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              );
            }

            if (widget.isHorizontal) {
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

class ServiceSection extends StatelessWidget {
  final Widget child;
  const ServiceSection({Key? key, required this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _HorizontalServiceCard extends StatefulWidget {
  final QueryDocumentSnapshot service;
  const _HorizontalServiceCard({required this.service});

  @override
  State<_HorizontalServiceCard> createState() => _HorizontalServiceCardState();
}

class _HorizontalServiceCardState extends State<_HorizontalServiceCard> {
  bool _isNavigating = false;

  /// Safe image URL extraction with unified mapping
  String _getImageUrl(Map<String, dynamic>? data) {
    // AUDIT: Use prioritized mapping standardized across app
    final imageUrl = (data?['imageUrl'] ?? data?['image'] ?? data?['thumbnail'] ?? '') as String;
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return '';
    }
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final data = service.data() as Map<String, dynamic>?;
    return GestureDetector(
      onTap: () async {
        if (_isNavigating) return;
        _isNavigating = true;

        try {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailsScreen(
                serviceId: widget.service.id,
                serviceName: (widget.service.data() as Map<String, dynamic>?)?['title'] ?? 'Service',
                serviceData: HomeService.fromFirestore(widget.service),
              )));
        } finally {
          if (mounted) {
            _isNavigating = false;
          }
        }
      },
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
                  imageUrl: _getImageUrl(data),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data?['title'] ?? 'Service',
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

class _VerticalServiceCard extends StatefulWidget {
  final QueryDocumentSnapshot service;
  const _VerticalServiceCard({required this.service});

  @override
  State<_VerticalServiceCard> createState() => _VerticalServiceCardState();
}

class _VerticalServiceCardState extends State<_VerticalServiceCard> {
  bool _isNavigating = false;

  /// Safe image URL extraction with unified mapping
  String _getImageUrl(Map<String, dynamic>? data) {
    // AUDIT: Use prioritized mapping standardized across app
    final imageUrl = (data?['imageUrl'] ?? data?['image'] ?? data?['thumbnail'] ?? '') as String;
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return '';
    }
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final data = service.data() as Map<String, dynamic>?;
    return GestureDetector(
      onTap: () async {
        if (_isNavigating) return;
        _isNavigating = true;

        try {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailsScreen(
                serviceId: widget.service.id,
                serviceName: (widget.service.data() as Map<String, dynamic>?)?['title'] ?? 'Service',
                serviceData: HomeService.fromFirestore(widget.service),
              )));
        } finally {
          if (mounted) {
            _isNavigating = false;
          }
        }
      },
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
                      imageUrl: _getImageUrl(data),
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
                          final data = widget.service.data() as Map<String, dynamic>?;
                          // Ultra-safe price parsing - prevents type cast crash
                          final rawPrice = data?['basePrice'];
                          final double price = (rawPrice is num) ? rawPrice.toDouble() : 0.0;
                          await cart.addItem(CartItem(
                            id: '',
                            serviceId: widget.service.id,
                            serviceName: data?['name'] ?? data?['title'] ?? 'Service',
                            serviceImage: _getImageUrl(data), // AUDIT: Use standardized image URL
                            price: price,
                            categoryId: (data?['categoryId'] ?? data?['category'] ?? '').toString(),
                            quantity: 1,
                            totalPrice: price,
                          ));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${data?['title'] ?? 'Service'} added to cart'),
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
                    data?['title'] ?? 'Service',
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
