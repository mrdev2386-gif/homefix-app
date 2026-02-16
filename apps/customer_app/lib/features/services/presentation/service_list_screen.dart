import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/service.dart';
import '../../../core/models/category.dart';
import '../../../core/models/banner_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import 'sub_service_screen.dart';

class ServiceListScreen extends StatefulWidget {
  final String? category;
  final String? initialSearchQuery;
  const ServiceListScreen({super.key, this.category, this.initialSearchQuery});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  bool _imagesPrefetched = false;
  bool _isNavigating = false;
  Timer? _debounceTimer;
  final PageController _bannerPageController = PageController(viewportFraction: 0.92);

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = _searchQuery;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prefetchImages();
  }

  void _prefetchImages() {
    if (_imagesPrefetched) return;
    _imagesPrefetched = true;
    
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    firestoreService.streamServices(category: _selectedCategory).listen((services) {
      if (!mounted) return;
      
      // Prefetch MAX 6 images only
      final firstSix = services.take(6);
      for (final service in firstSix) {
        try {
          // Skip empty or invalid URLs
          final imageUrl = service.imageUrl;
          if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
            continue;
          }
          precacheImage(
            NetworkImage(imageUrl),
            context,
          );
        } catch (_) {
          // Silently ignore prefetch errors to prevent crashes
        }
      }
    });
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(),
                  ),
                  // Search Bar
                  SliverToBoxAdapter(
                    child: _buildSearchBar(),
                  ),
                  // Featured Banner Carousel
                  SliverToBoxAdapter(
                    child: _buildFeaturedBannerCarousel(firestoreService),
                  ),
                  // Small Icon Categories Row
                  SliverToBoxAdapter(
                    child: _buildCategoryIconRow(firestoreService),
                  ),
                  // Popular Services Section
                  SliverToBoxAdapter(
                    child: _buildPopularServicesSection(firestoreService),
                  ),
                  // All Services Section
                  SliverToBoxAdapter(
                    child: _buildAllServicesSectionHeader(),
                  ),
                  // All Services Grid
                  _buildAllServicesGrid(firestoreService),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello! 👋',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find Services',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.textColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search services...',
            hintStyle: GoogleFonts.outfit(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.subtitleColor),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedBannerCarousel(FirestoreService service) {
    return StreamBuilder<List<BannerModel>>(
      stream: service.streamBanners(),
      builder: (context, snapshot) {
        final banners = snapshot.data ?? [];
        
        if (banners.isEmpty) {
          // Use first few services as featured banners if no banners exist
          return _buildFeaturedServicesAsBanners(service);
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Featured',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _bannerPageController,
                physics: const BouncingScrollPhysics(),
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  return _buildBannerCard(banners[index], service);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedServicesAsBanners(FirestoreService service) {
    return StreamBuilder<List<HomeService>>(
      stream: service.streamServices(limit: 5),
      builder: (context, snapshot) {
        final services = snapshot.data ?? [];
        
        if (services.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Featured',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _bannerPageController,
                physics: const BouncingScrollPhysics(),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return _buildServiceAsBanner(services[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBannerCard(BannerModel banner, FirestoreService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _navigateToService(banner.targetId, service),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.white,
                    child: Container(color: Colors.grey[300]),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(
                      Icons.image_rounded,
                      color: AppTheme.primaryColor,
                      size: 48,
                    ),
                  ),
                ),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Content
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (banner.title.isNotEmpty)
                        Text(
                          banner.title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      if (banner.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          banner.subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildServiceAsBanner(HomeService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _navigateToServiceFromHomeService(service),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                _buildServiceImage(service, 400, 200),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Content
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (service.description.isNotEmpty)
                        Text(
                          service.description,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
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

  Widget _buildCategoryIconRow(FirestoreService service) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.getCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                'Categories',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final categoryData = categories[index];
                  final String catId = (categoryData['id'] ?? categoryData['title'] ?? '').toString();
                  final String catName = (categoryData['name'] ?? categoryData['title'] ?? 'Category').toString();
                  final String catImageUrl = categoryData['imageUrl']?.toString() ?? '';
                  final bool hasValidImage = catImageUrl.isNotEmpty && catImageUrl.startsWith('http');

                  return _buildCategoryIconCard(catId, catName, catImageUrl, hasValidImage);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryIconCard(String categoryId, String categoryName, String? imageUrl, bool hasValidImage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _navigateToCategory(categoryId, categoryName),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: hasValidImage
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 128,
                        placeholder: (context, url) => Container(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(
                            Icons.category_rounded,
                            color: AppTheme.primaryColor,
                            size: 28,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(
                            Icons.category_rounded,
                            color: AppTheme.primaryColor,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          _getCategoryIcon(categoryName),
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 72,
              child: Text(
                categoryName,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('clean')) return Icons.cleaning_services_rounded;
    if (name.contains('plumb')) return Icons.plumbing_rounded;
    if (name.contains('electric')) return Icons.electrical_services_rounded;
    if (name.contains('ac') || name.contains('air')) return Icons.ac_unit_rounded;
    if (name.contains('appliance')) return Icons.kitchen_rounded;
    if (name.contains('carpenter')) return Icons.carpenter_rounded;
    if (name.contains('paint')) return Icons.format_paint_rounded;
    if (name.contains('pest')) return Icons.pest_control_rounded;
    if (name.contains('salon') || name.contains('beauty')) return Icons.spa_rounded;
    if (name.contains('repair')) return Icons.build_rounded;
    return Icons.category_rounded;
  }

  Widget _buildPopularServicesSection(FirestoreService service) {
    return StreamBuilder<List<HomeService>>(
      stream: service.streamServices(limit: 10),
      builder: (context, snapshot) {
        final services = snapshot.data ?? [];
        
        if (services.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get top rated services (sorted by rating)
        final popularServices = List<HomeService>.from(services)
          ..sort((a, b) => b.rating.compareTo(a.rating));
        final topServices = popularServices.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular Services',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                  Text(
                    'View All',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: topServices.length,
              itemBuilder: (context, index) {
                return _buildPopularServiceCard(topServices[index]);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopularServiceCard(HomeService service) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToServiceFromHomeService(service),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildServiceImage(service, 200, 120),
                      // Rating badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
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
              ),
              // Content
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (service.basePrice > 0)
                        Text(
                          '₹${service.basePrice.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllServicesSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'All Services',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list_rounded, size: 16, color: AppTheme.subtitleColor),
                const SizedBox(width: 4),
                Text(
                  'Filter',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllServicesGrid(FirestoreService service) {
    return StreamBuilder<List<HomeService>>(
      stream: service.streamServices(category: _selectedCategory),
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: _buildError());
        }

        // Loading state - only show skeleton when waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: _buildSkeleton());
        }
        
        final servicesList = snapshot.data ?? [];
        
        var services = List<HomeService>.from(servicesList);
        if (_searchQuery.isNotEmpty) {
          services = services.where((s) => 
            s.title.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        // Empty state - prevent blank screen
        if (services.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmpty());
        }

        // Services grid with performance optimizations
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return RepaintBoundary(
                  child: _buildServiceCard(services[index]),
                );
              },
              childCount: services.length,
            ),
          ),
        );
      },
    );
  }

  void _navigateToService(String serviceId, FirestoreService service) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();
    
    // Find the service by ID and navigate
    service.streamServices(limit: 50).first.then((services) {
      if (!mounted) return;
      
      final matchingService = services.where((s) => s.id == serviceId || s.category == serviceId).firstOrNull;
      
      if (matchingService != null) {
        _navigateToServiceFromHomeService(matchingService);
      } else {
        _isNavigating = false;
      }
    }).catchError((_) {
      if (mounted) {
        _isNavigating = false;
      }
    });
  }

  void _navigateToServiceFromHomeService(HomeService service) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();
    
    // Create Category from HomeService for navigation
    final category = Category(
      id: service.category,
      name: service.category,
      order: service.order,
      isActive: service.isActive,
    );
    
    // Navigate to sub-services screen with hero animation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubServiceScreen(
          category: category,
          service: service,
        ),
      ),
    );
    
    // Reset flag after navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _isNavigating = false;
      }
    });
  }

  void _navigateToCategory(String categoryId, String categoryName) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();
    
    final category = Category(
      id: categoryId,
      name: categoryName,
      order: 0,
      isActive: true,
    );
    
    // Navigate with a dummy service for category view
    final dummyService = HomeService(
      id: '',
      key: categoryId,
      title: categoryName,
      imageAssetPath: '',
      basePrice: 0,
      isActive: true,
      category: categoryId,
      isTopService: false,
      order: 0,
      createdAt: DateTime.now(),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubServiceScreen(
          category: category,
          service: dummyService,
        ),
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _isNavigating = false;
      }
    });
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load services',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(HomeService service) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToServiceFromHomeService(service),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Service Image with hero animation, shimmer placeholder, and error fallback
              Hero(
                tag: 'service_image_${service.id}',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildServiceImage(service, 56, 56),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Service Name
              Text(
                service.title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceImage(HomeService service, int width, int height) {
    // Get the effective image URL with fallback
    String? imageUrl = service.imageUrl;
    
    // Skip invalid URLs safely
    if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      // Use fallback image from service model
      imageUrl = service.getFallbackImageUrl();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width.toDouble(),
      height: height.toDouble(),
      fit: BoxFit.cover,
      // Memory-safe sizing
      memCacheWidth: width * 2,
      memCacheHeight: height * 2,
      // Shimmer placeholder while loading
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.white,
        child: Container(
          width: width.toDouble(),
          height: height.toDouble(),
          color: Colors.white,
        ),
      ),
      // Error fallback icon
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 9,
      addSemanticIndexes: false,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[100]!,
          highlightColor: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.category_rounded,
                size: 48,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No services available',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new services',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
