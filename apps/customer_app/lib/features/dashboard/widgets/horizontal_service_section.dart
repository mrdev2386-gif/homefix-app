import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../services/presentation/sub_service_screen.dart';
import '../../services/presentation/service_list_screen.dart';
import '../../../core/models/service.dart';
import '../../../core/models/category.dart';

/// Reusable horizontal service section widget
/// 
/// Parameters:
/// - [title]: Section title to display
/// - [serviceFilter]: Function to filter services by category
/// - [maxItems]: Maximum number of services to show (default: 8)
class HorizontalServiceSection extends StatefulWidget {
  final String title;
  final bool Function(String category) serviceFilter;
  final int maxItems;
  final String? viewAllCategory;

  const HorizontalServiceSection({
    super.key,
    required this.title,
    required this.serviceFilter,
    this.maxItems = 8,
    this.viewAllCategory,
  });

  @override
  State<HorizontalServiceSection> createState() => _HorizontalServiceSectionState();
}

class _HorizontalServiceSectionState extends State<HorizontalServiceSection> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              if (widget.viewAllCategory != null)
                GestureDetector(
                  onTap: () async {
                    if (_isNavigating) return;
                    _isNavigating = true;

                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceListScreen(category: widget.viewAllCategory),
                        ),
                      );
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
        _HorizontalServiceSlider(
          serviceFilter: widget.serviceFilter,
          maxItems: widget.maxItems,
        ),
      ],
    );
  }
}

class _HorizontalServiceSlider extends StatelessWidget {
  final bool Function(String category) serviceFilter;
  final int maxItems;

  const _HorizontalServiceSlider({
    required this.serviceFilter,
    required this.maxItems,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('services')
          .where('isActive', isEqualTo: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        // Handle waiting state - show skeleton loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 4,
              itemBuilder: (context, index) => _buildShimmerCard(),
            ),
          );
        }

        // Handle error state - show friendly error UI
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        // Handle no data
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmptyState();
        }

        final services = snapshot.data!.docs;
        
        // Filter services based on filter function with null-safe category access
        final filteredServices = services.where((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            final category = (data?['category'] ?? '').toString().toLowerCase().trim();
            return serviceFilter(category);
          } catch (e) {
            // Skip on any parsing error
            return false;
          }
        }).take(maxItems).toList();

        // If no matching services found, show empty state instead of blank
        if (filteredServices.isEmpty) {
          return _buildEmptyState();
        }

        return _buildHorizontalSlider(filteredServices);
      },
    );
  }

  /// Build proper empty state UI to prevent silent failures
  Widget _buildEmptyState() {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              color: Colors.grey[400],
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'No services available',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state UI to prevent red screen
  Widget _buildErrorState() {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.grey[400],
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load services',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSlider(List<QueryDocumentSnapshot> services) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.45),
        physics: const BouncingScrollPhysics(),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          final data = service.data() as Map<String, dynamic>?;
          // Ultra-safe price parsing - prevents type cast crash
          final rawPrice = data?['price'] ?? data?['basePrice'];
          final double price = (rawPrice is num) ? rawPrice.toDouble() : 0.0;
          // Safe field access using doc.data()
          return _ServiceCard(
            serviceId: service.id,
            title: data?['title'] ?? 'Service',
            imageUrl: data?['imageUrl'] ?? data?['image'] ?? '',
            category: data?['category'] ?? '',
            price: price,
          );
        },
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final String serviceId;
  final String title;
  final String imageUrl;
  final String category;
  final double price;

  const _ServiceCard({
    required this.serviceId,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.price,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isNavigating = false;

  // Getters for widget properties
  String get title => widget.title;
  double get price => widget.price;
  String get imageUrl => widget.imageUrl;
  String get category => widget.category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () async {
          if (_isNavigating) return;
          _isNavigating = true;

          try {
            _navigateToSubService(context);
          } finally {
            if (mounted) {
              _isNavigating = false;
            }
          }
        },
        child: Container(
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
              // Image
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildImage(),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (price > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    String validUrl = imageUrl.isNotEmpty ? imageUrl : _getFallbackImage();

    return CachedNetworkImage(
      imageUrl: validUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: 300,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.white,
        child: Container(color: Colors.grey[300]),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.primaryColor.withOpacity(0.1),
        child: Icon(
          _getCategoryIcon(),
          color: AppTheme.primaryColor,
          size: 32,
        ),
      ),
    );
  }

  String _getFallbackImage() {
    final cat = category.toLowerCase();
    if (cat.contains('ac') || cat.contains('air')) {
      return 'https://images.unsplash.com/photo-1631545806609-5adb40c6e3eb?w=400&q=80';
    } else if (cat.contains('electric')) {
      return 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=400&q=80';
    } else if (cat.contains('tv') || cat.contains('electronics')) {
      return 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=400&q=80';
    } else if (cat.contains('fridge') || cat.contains('refrigerator')) {
      return 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=400&q=80';
    } else if (cat.contains('washing')) {
      return 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&q=80';
    } else if (cat.contains('appliance')) {
      return 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400&q=80';
    }
    return 'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=400&q=80';
  }

  IconData _getCategoryIcon() {
    final cat = category.toLowerCase();
    if (cat.contains('electric')) return Icons.electrical_services_rounded;
    if (cat.contains('ac') || cat.contains('air')) return Icons.ac_unit_rounded;
    if (cat.contains('tv') || cat.contains('electronics')) return Icons.tv_rounded;
    if (cat.contains('fridge') || cat.contains('refrigerator')) return Icons.kitchen_rounded;
    if (cat.contains('washing')) return Icons.local_laundry_service_rounded;
    if (cat.contains('appliance')) return Icons.kitchen_rounded;
    return Icons.build_rounded;
  }

  void _navigateToSubService(BuildContext context) {
    HapticFeedback.lightImpact();
    
    // Create HomeService from data
    final service = HomeService(
      id: widget.serviceId,
      key: widget.serviceId,
      title: widget.title,
      imageAssetPath: widget.imageUrl,
      basePrice: widget.price,
      isActive: true,
      category: widget.category,
      isTopService: false,
      order: 0,
      createdAt: DateTime.now(),
    );
    
    // Create Category
    final cat = Category(
      id: widget.category,
      name: widget.category,
      order: 0,
      isActive: true,
    );

    // Navigate to SubServiceScreen in fullscreen mode
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubServiceScreen(
          category: cat,
          service: service,
        ),
      ),
    );
  }
}
