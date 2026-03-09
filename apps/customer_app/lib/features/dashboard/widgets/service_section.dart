import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../services/presentation/service_details_screen.dart';
import '../../services/presentation/service_list_screen.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/models/cart_item.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/services/category_service.dart';

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
  late Stream<List<HomeService>> _serviceStream;
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    // Step 2: Use CategoryService as SINGLE SOURCE OF TRUTH
    if (widget.category == null && widget.title.contains('Recently Added')) {
      _serviceStream = _categoryService.getRecentlyAddedServices(limit: widget.limit ?? 10);
    } else {
      final categoryId = widget.category ?? 'cleaning';
      _serviceStream = _categoryService.getServicesByCategory(categoryId);
    }
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
                      Expanded(
                        child: Text(
                          widget.title,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // Spacing between title and view all
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
        StreamBuilder<List<HomeService>>(
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
            
            final services = snapshot.data ?? [];
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
  const ServiceSection({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _HorizontalServiceCard extends StatefulWidget {
  final HomeService service;
  const _HorizontalServiceCard({required this.service});

  @override
  State<_HorizontalServiceCard> createState() => _HorizontalServiceCardState();
}

class _HorizontalServiceCardState extends State<_HorizontalServiceCard> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isNavigating) return;
        _isNavigating = true;

        try {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailsScreen(
                serviceId: widget.service.id,
                categoryId: widget.service.category,
                serviceName: widget.service.title,
                serviceData: widget.service,
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
                  imageUrl: widget.service.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.service.title,
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
                  widget.service.rating.toStringAsFixed(1),
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
  final HomeService service;
  const _VerticalServiceCard({required this.service});

  @override
  State<_VerticalServiceCard> createState() => _VerticalServiceCardState();
}

class _VerticalServiceCardState extends State<_VerticalServiceCard> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isNavigating) return;
        _isNavigating = true;

        try {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailsScreen(
                serviceId: widget.service.id,
                categoryId: widget.service.category,
                serviceName: widget.service.title,
                serviceData: widget.service,
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
                      imageUrl: widget.service.imageUrl,
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
                          try {
                            await cart.addItem(CartItem(
                              id: '',
                              serviceId: widget.service.id,
                              serviceName: widget.service.title,
                              serviceImage: widget.service.imageUrl,
                              price: widget.service.basePrice,
                              categoryId: widget.service.category,
                              categoryName: widget.service.categoryName,
                              quantity: 1,
                              totalPrice: widget.service.basePrice,
                              technicianId: widget.service.technicianId,
                              finalPriceSnapshot: widget.service.basePrice,
                            ));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${widget.service.title} added to cart'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add to cart: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
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
                    widget.service.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '₹${widget.service.basePrice.toStringAsFixed(0)}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryColor),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 12),
                            const SizedBox(width: 2),
                            Text(widget.service.rating.toStringAsFixed(1), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.orange)),
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
