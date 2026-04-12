import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import 'sub_service_screen.dart';
import 'service_details_screen.dart';

class ServiceListScreen extends StatefulWidget {
  final String? category;
  final String? initialSearchQuery;

  const ServiceListScreen({
    super.key,
    this.category,
    this.initialSearchQuery,
  });

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final CategoryService _categoryService;

  Timer? _debounceTimer;
  bool _isNavigating = false;
  String? _selectedCategory;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  List<HomeService> _allServices = [];
  List<HomeService> _filteredServices = [];

  late Stream<List<HomeService>> _servicesStream;

  @override
  void initState() {
    super.initState();
    _categoryService = context.read<CategoryService>();
    _selectedCategory = widget.category;
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = _searchQuery;
    }
    _initStreams();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initStreams() {
    _updateServicesStream();
  }

  void _updateServicesStream() {
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      _servicesStream = _categoryService.getServicesByCategory(_selectedCategory!);
    } else {
      _servicesStream = _categoryService.getAllServices();
    }
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

  List<HomeService> _applyFilters(List<HomeService> services) {
    List<HomeService> filtered = List.from(services);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedFilter.startsWith('category:')) {
      final category = _selectedFilter.replaceFirst('category:', '');
      filtered = filtered.where((s) => s.category == category).toList();
    }

    switch (_selectedFilter) {
      case 'toprated':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowestprice':
        filtered.sort((a, b) {
          final aFinal = (a.offerPrice != null && a.offerPrice! < a.price) ? a.offerPrice! : a.price;
          final bFinal = (b.offerPrice != null && b.offerPrice! < b.price) ? b.offerPrice! : b.price;
          return aFinal.compareTo(bFinal);
        });
        break;
      case 'popular':
        filtered.sort((a, b) => (b.reviewCount ?? 0).compareTo(a.reviewCount ?? 0));
        break;
      case 'recent':
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      default:
        break;
    }

    return filtered;
  }

  void _showCategoryBottomSheet() {
    final categories = _allServices.map((s) => s.category).toSet().toList();
    categories.sort();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Category',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: categories.length,
                separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedFilter = 'category:$category');
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          category,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleServiceTap(HomeService service) async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();

    try {
      final hasSubServices = await _categoryService.serviceHasSubServices(
        service.category,
        service.id,
      );

      if (!mounted) {
        _isNavigating = false;
        return;
      }

      if (hasSubServices) {
        final category = Category(id: service.category, name: service.title);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubServiceScreen(category: category, service: service),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailsScreen(
              serviceId: service.id,
              categoryId: service.category,
              serviceName: service.title,
              serviceData: service,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Navigation Error: $e');
    } finally {
      if (mounted) _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
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
                        _selectedCategory ?? 'Services',
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.subtitleColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _clearSearch,
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

          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Categories',
                    isSelected: _selectedFilter.startsWith('category:'),
                    onTap: _showCategoryBottomSheet,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Top Rated',
                    isSelected: _selectedFilter == 'toprated',
                    onTap: () => setState(() => _selectedFilter = 'toprated'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Lowest Price',
                    isSelected: _selectedFilter == 'lowestprice',
                    onTap: () => setState(() => _selectedFilter = 'lowestprice'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Popular',
                    isSelected: _selectedFilter == 'popular',
                    onTap: () => setState(() => _selectedFilter = 'popular'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Recently Added',
                    isSelected: _selectedFilter == 'recent',
                    onTap: () => setState(() => _selectedFilter = 'recent'),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          StreamBuilder<List<HomeService>>(
            stream: _servicesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(child: _buildShimmerLoading());
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Error loading services', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                );
              }

              _allServices = snapshot.data ?? [];
              final filtered = _applyFilters(_allServices);

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyState());
              }

              return SliverPadding(
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
                      final service = filtered[index];
                      return _ServiceGridCard(
                        key: ValueKey(service.id),
                        service: service,
                        onTap: () => _handleServiceTap(service),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 300,
      child: Center(
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
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // PRICE CALCULATION (SAME AS HOME SCREEN)
    final double price = service.price ?? 0;
    final double offerPrice = service.offerPrice ?? 0;
    
    final bool hasOffer = offerPrice > 0 && offerPrice < price;
    final double finalPrice = hasOffer ? offerPrice : price;
    
    final int discount = hasOffer 
        ? ((price - offerPrice) / price * 100).round()
        : 0;
    
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
                        child: Icon(Icons.image_not_supported_rounded, color: Colors.grey[400]),
                      ),
                    ),
                  ),
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _SmallFavoriteButton(service: service),
                  ),
                  if (discount > 0)
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
                          '$discount% OFF',
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
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 4),
                    // PRICE ROW
                    Row(
                      children: [
                        Text(
                          "₹${finalPrice.toStringAsFixed(0)}",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (hasOffer)
                          Text(
                            "₹${price.toStringAsFixed(0)}",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.subtitleColor,
                              decoration: TextDecoration.lineThrough,
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
