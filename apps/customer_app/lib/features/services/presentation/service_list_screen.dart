after - import 'dart:async';
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
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'sub_service_screen.dart';
import 'service_details_screen.dart';

class ServiceListScreen extends StatefulWidget {
  final String? category;
  final String? initialSearchQuery;
  const ServiceListScreen({super.key, this.category, this.initialSearchQuery});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  // State for Lists
  final List<HomeService> _services = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String? _selectedCategory;
  String _searchQuery = '';
  int _activeQueryId = 0;
  final Set<String> _serviceIds = {}; // DUPLICATE PROTECTION

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Helpers
  Timer? _debounceTimer;
  bool _isNavigating = false;
  bool _imagesPrefetched = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = _searchQuery;
    }
    _scrollController.addListener(_onScroll);
    
    // Initial Fetch
    scheduleMicrotask(() => _fetchServices(reset: true));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      if (!_isLoadingMore && _hasMore) {
        _fetchServices();
      }
    }
  }

  Future<void> _fetchServices({bool reset = false}) async {
    if (reset) {
      _activeQueryId++;
      setState(() {
        _isLoading = true;
        _services.clear();
        _serviceIds.clear();
        _lastDocument = null;
        _hasMore = true;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    final int queryId = _activeQueryId;
    
    try {
      final firestore = FirebaseFirestore.instance;
      // HARDENING: collectionGroup ensures global scalability
      Query query = firestore.collectionGroup('services').where('isActive', isEqualTo: true);
      
      if (_selectedCategory != null) {
        query = query.where('categoryId', isEqualTo: _selectedCategory);
      }

      // STABLE ORDERING: Required for cursor-based pagination
      query = query.orderBy('order').orderBy('__name__');

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      // LIMIT: Keep it lean for low-end devices
      query = query.limit(20);
      
      final snapshot = await query.get();

      if (queryId != _activeQueryId || !mounted) return;

      final List<HomeService> fetchedServices = snapshot.docs
          .map((doc) => HomeService.fromFirestore(doc))
          .toList();

      final bool hasNextPage = snapshot.docs.length == 20;

      List<HomeService> results = [];
      for (final s in fetchedServices) {
        // DUPLICATE PROTECTION: Set-based check
        if (_serviceIds.contains(s.id)) continue;
        
        // Client-side search optimization for instant feel
        if (_searchQuery.isNotEmpty && 
            !s.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
          continue;
        }
        
        results.add(s);
        _serviceIds.add(s.id);
      }

      if (mounted) {
        setState(() {
          _services.addAll(results);
          if (snapshot.docs.isNotEmpty) {
            _lastDocument = snapshot.docs.last;
          }
          _hasMore = hasNextPage;
          _isLoading = false;
          _isLoadingMore = false;
        });
        _prefetchImages();
      }
    } catch (e) {
      if (queryId != _activeQueryId || !mounted) return;
      debugPrint('❌ [ServiceList] Fetch error: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _searchQuery = value);
        _fetchServices(reset: true);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _fetchServices(reset: true);
  }

  void _onCategoryChanged(String? categoryId) {
    if (_selectedCategory == categoryId) return;
    
    setState(() {
      _selectedCategory = categoryId;
      _searchQuery = '';
      _searchController.clear();
    });
    
    HapticFeedback.selectionClick();
    _fetchServices(reset: true);
  }

  void _prefetchImages() {
    if (_imagesPrefetched || !mounted || _services.isEmpty) return;
    
    // Optimized prefetching for the first few items
    for (final service in _services.take(10)) {
      if (service.imageUrl.startsWith('http')) {
        precacheImage(CachedNetworkImageProvider(service.imageUrl), context);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          _buildCategoryFilter(),
          _buildServicesContent(),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textColor, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        'Explore Services',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: AppTheme.textColor,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          children: [
            const SizedBox(height: 90),
            _buildModernSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Search for cleaning, repairs...',
            hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w400),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CategoryFilterDelegate(
        child: Container(
          color: Colors.white,
          height: 60,
          child: StreamBuilder<List<Category>>(
            stream: FirebaseFirestore.instance
                .collection('categories')
                .where('isActive', isEqualTo: true)
                .orderBy('order')
                .snapshots()
                .map((snapshot) => snapshot.docs.map((d) => Category.fromFirestore(d)).toList()),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? [];
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final category = isAll ? null : categories[index - 1];
                  final isSelected = isAll 
                      ? _selectedCategory == null 
                      : _selectedCategory == category!.id;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(isAll ? 'All' : category!.name),
                      selected: isSelected,
                      onSelected: (_) => _onCategoryChanged(category?.id),
                      labelStyle: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: Colors.grey[100],
                      elevation: 0,
                      pressElevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildServicesContent() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor.withOpacity(0.5)),
          ),
        ),
      );
    }

    if (_services.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final service = _services[index];
            return _buildModernServiceCard(service);
          },
          childCount: _services.length,
        ),
      ),
    );
  }

  Widget _buildModernServiceCard(HomeService service) {
    return GestureDetector(
      onTap: () => _navigateToService(service),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[100]!),
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
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SafeNetworkImage(
                      imageUrl: service.imageUrl,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      fit: BoxFit.cover,
                      serviceName: service.title,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            service.rating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
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
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      service.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.basePrice > 0 ? '₹${service.basePrice.toStringAsFixed(0)}' : 'Free Est.',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.primaryColor),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          Text(
            'No services found',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or category',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _clearSearch,
            child: Text('Clear All Filters', style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _navigateToService(HomeService service) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailsScreen(
          serviceId: service.id,
          serviceName: service.title,
          serviceData: service,
        ),
      ),
    ).then((_) {
      if (mounted) _isNavigating = false;
    });
  }
}

class _CategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _CategoryFilterDelegate({required this.child});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryFilterDelegate oldDelegate) => false;
}  