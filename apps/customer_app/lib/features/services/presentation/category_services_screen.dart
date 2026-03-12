import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/models/sub_service.dart';
import 'package:customer_app/core/services/category_service.dart';
import '../../../core/services/matching_service.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/widgets/no_technicians_popup.dart';
import '../../../core/widgets/matching_loading_overlay.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/location_provider.dart';
import 'service_details_screen.dart';
import 'technician_selection_screen.dart';
import 'package:customer_app/core/theme/app_theme.dart';

class CategoryServicesScreen extends StatefulWidget {
  final Category category;

  const CategoryServicesScreen({
    super.key, 
    required this.category,
  });

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  final CategoryService _categoryService = CategoryService();
  final MatchingService _matchingService = MatchingService();
  bool _isLoading = true;
  List<HomeService> _services = [];
  List<HomeService> _filteredServices = [];
  StreamSubscription? _servicesSubscription;
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  void dispose() {
    _servicesSubscription?.cancel();
    super.dispose();
  }

  void _fetchServices() {
    setState(() => _isLoading = true);
    debugPrint('🔍 [CategoryServicesScreen] Fetching services for: ${widget.category.name}');

    _servicesSubscription?.cancel();
    _servicesSubscription = _categoryService
        .getServicesByCategoryResult(widget.category.id)
        .listen(
      (result) {
        final services = result.data ?? [];
        if (mounted) {
          setState(() {
            _services = services.take(20).toList();
            _applyFilters();
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('❌ Error: $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  void _applyFilters() {
    List<HomeService> filtered = List.from(_services);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply sort filter
    switch (_selectedFilter) {
      case 'toprated':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowestprice':
        filtered.sort((a, b) => a.basePrice.compareTo(b.basePrice));
        break;
      case 'fastest':
        filtered.sort((a, b) => (a.estimatedTime ?? 0).compareTo(b.estimatedTime ?? 0));
        break;
      case 'recent':
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      default:
        break;
    }

    setState(() => _filteredServices = filtered);
  }

  Future<void> _handleServiceTap(HomeService service) async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(
          serviceId: service.id,
          categoryId: widget.category.id,
          serviceName: service.title,
          serviceData: service,
        ),
      ),
    );
  }

  Future<void> _matchTechnicians(String serviceId, String? subServiceId) async {
    bool isTimedOut = false;
    
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secondaryAnim) {
        return MatchingLoadingOverlay(
          onTimeout: () {
            isTimedOut = true;
            Navigator.of(context).pop();
          },
          message: 'Finding best professionals for ${widget.category.name}...',
        );
      },
    );
    
    if (isTimedOut) {
      if (!mounted) return;
      NoTechniciansPopup.show(
        context: context,
        onRetry: () => _matchTechnicians(serviceId, subServiceId),
        onChangeService: () {
          Navigator.of(context)..pop()..pop();
        },
        customMessage: 'Taking longer than expected. Please try again or choose a different service.',
      );
      return;
    }
    
    if (!mounted) return;
    
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    double? latitude = locationProvider.selectedAddress?.latitude;
    double? longitude = locationProvider.selectedAddress?.longitude;

    latitude ??= 0.0;
    longitude ??= 0.0;

    final response = await _matchingService.matchTechnicians(
      serviceId: serviceId,
      subServiceId: subServiceId,
      latitude: latitude,
      longitude: longitude,
    );
    
    if (!mounted) return;
    
    if (response.available && response.topTechnicians != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TechnicianSelectionScreen(
            technicians: response.topTechnicians!,
            serviceId: serviceId,
            subServiceId: subServiceId,
          ),
        ),
      );
    } else {
      NoTechniciansPopup.show(
        context: context,
        onRetry: () => _matchTechnicians(serviceId, subServiceId),
        onChangeService: () {
          Navigator.of(context)..pop()..pop();
        },
        customMessage: response.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Gradient Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
                color: AppTheme.textColor,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.9),
                      AppTheme.secondaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.category.name,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose a service near you',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _applyFilters();
                },
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.subtitleColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            _applyFilters();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedFilter == 'all',
                    onTap: () {
                      setState(() => _selectedFilter = 'all');
                      _applyFilters();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Top Rated',
                    isSelected: _selectedFilter == 'toprated',
                    onTap: () {
                      setState(() => _selectedFilter = 'toprated');
                      _applyFilters();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Lowest Price',
                    isSelected: _selectedFilter == 'lowestprice',
                    onTap: () {
                      setState(() => _selectedFilter = 'lowestprice');
                      _applyFilters();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Fastest',
                    isSelected: _selectedFilter == 'fastest',
                    onTap: () {
                      setState(() => _selectedFilter = 'fastest');
                      _applyFilters();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Recently Added',
                    isSelected: _selectedFilter == 'recent',
                    onTap: () {
                      setState(() => _selectedFilter = 'recent');
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Services Grid
          if (_isLoading)
            SliverToBoxAdapter(
              child: _buildShimmerLoading(),
            )
          else if (_filteredServices.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = _filteredServices[index];
                    return _ServiceGridCard(
                      service: service,
                      onTap: () => _handleServiceTap(service),
                    );
                  },
                  childCount: _filteredServices.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No services found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search'
                  : 'No services available in this category yet',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppTheme.primaryColor.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.subtitleColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceGridCard extends StatelessWidget {
  final HomeService service;
  final VoidCallback onTap;

  const _ServiceGridCard({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: service.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.15),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _SmallFavoriteButton(service: service),
                  ),
                  // Discount badge
                  if (service.discount != null && service.discount! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${service.discount}% OFF',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      service.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          service.rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${service.reviewCount ?? 0})',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Price
                    Row(
                      children: [
                        Text(
                          '₹${service.basePrice.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        if (service.discount != null && service.discount! > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₹${(service.basePrice * (1 + service.discount! / 100)).toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.subtitleColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
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

class _SmallFavoriteButton extends StatelessWidget {
  final HomeService service;

  const _SmallFavoriteButton({required this.service});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.read<FavoritesProvider>().toggleFavorite(service.id, service.category);
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.red.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Consumer<FavoritesProvider>(
            builder: (context, favorites, _) {
              final isFavorite = favorites.isFavorite(service.id);
              return Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 16,
                color: isFavorite ? Colors.red : Colors.grey[600],
              );
            },
          ),
        ),
      ),
    );
  }
}
