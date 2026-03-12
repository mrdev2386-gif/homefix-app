import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/location_missing_empty_state.dart';
import 'service_details_screen.dart';
import 'sub_service_screen.dart';
import 'category_services_screen.dart';

/// Modern Services Screen - Urban Company-style UI
/// 
/// Features:
/// - Clean header with search and filter
/// - 2-column category grid
/// - Horizontal featured services
/// - 2-column services grid
/// - Real-time data from technician_services collection
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with AutomaticKeepAliveClientMixin {
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Data state
  List<Category> _categories = [];
  List<HomeService> _allServices = [];
  List<HomeService> _featuredServices = [];
  String? _selectedCategoryId;
  
  // UI state
  bool _isLoading = true;
  String _searchQuery = '';
  ErrorType? _errorType;
  
  // Helpers
  Timer? _debounceTimer;
  bool _isNavigating = false;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    debugPrint('🚀 [ServicesScreen] Initializing...');
    _fetchAllData();
  }
  
  @override
  void dispose() {
    debugPrint('🔚 [ServicesScreen] Disposing...');
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  /// Fetch all data for the modern services screen
  Future<void> _fetchAllData() async {
    debugPrint('🔍 [ServicesScreen] Starting data fetch...');
    
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _errorType = null;
    });
    
    try {
      // Check if user has location first
      final location = await categoryService.getUserLocationCached();
      if (location == null) {
        debugPrint('⚠️ [ServicesScreen] No user location - will show location missing state');
        setState(() {
          _categories = [];
          _allServices = [];
          _featuredServices = [];
          _isLoading = false;
        });
        return;
      }
      
      // Fetch categories
      debugPrint('📁 [ServicesScreen] Fetching categories...');
      final categories = await categoryService.getCategoriesOnce();
      debugPrint('✅ [ServicesScreen] Categories loaded: ${categories.length}');
      
      // Fetch all services
      debugPrint('🛠️ [ServicesScreen] Fetching all services...');
      final allServicesSnapshot = await categoryService.getAllServicesOnce();
      debugPrint('✅ [ServicesScreen] All services loaded: ${allServicesSnapshot.length}');
      
      // Get featured services (top rated)
      final featured = allServicesSnapshot
          .where((s) => s.rating >= 4.0)
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
      debugPrint('⭐ [ServicesScreen] Featured services (>=4.0): ${featured.length}');
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _allServices = allServicesSnapshot;
          _featuredServices = featured.take(10).toList();
          _isLoading = false;
        });
        
        debugPrint('✅ [ServicesScreen] Data fetch complete and state updated');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ [ServicesScreen] Error fetching data: $e');
      debugPrint('📍 [ServicesScreen] Stack trace: $stackTrace');
      
      if (mounted) {
        final errorString = e.toString().toLowerCase();
        ErrorType type;
        
        if (errorString.contains('network') ||
            errorString.contains('socket') ||
            errorString.contains('internet')) {
          type = ErrorType.networkError;
        } else if (errorString.contains('permission') ||
            errorString.contains('denied')) {
          type = ErrorType.permissionDenied;
        } else if (errorString.contains('failed-precondition') ||
            errorString.contains('index')) {
          type = ErrorType.failedPrecondition;
        } else {
          type = ErrorType.unknown;
        }
        
        setState(() {
          _errorType = type;
          _isLoading = false;
        });
      }
    }
  }
  

  
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        debugPrint('🔍 [ServicesScreen] Search query: "$value"');
        setState(() => _searchQuery = value);
      }
    });
  }
  
  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    debugPrint('🔍 [ServicesScreen] Search cleared');
  }
  
  List<HomeService> get _filteredServices {
    var services = _selectedCategoryId == null 
        ? _allServices 
        : _allServices.where((s) => s.category == _selectedCategoryId).toList();
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      services = services
          .where((s) => s.title.toLowerCase().contains(query) ||
                       s.description.toLowerCase().contains(query))
          .toList();
    }
    
    debugPrint('🔍 [ServicesScreen] Filtered services: ${services.length}');
    return services;
  }
  
  Future<void> _handleServiceTap(HomeService service) async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    
    debugPrint('👆 [ServicesScreen] Service tapped: ${service.title}');
    HapticFeedback.lightImpact();
    
    try {
      // Check if service has sub-services
      final hasSubServices = await categoryService.serviceHasSubServices(
        service.category,
        service.id,
      );
      
      if (!mounted) {
        _isNavigating = false;
        return;
      }
      
      if (hasSubServices) {
        debugPrint('📂 [ServicesScreen] Navigating to sub-services');
        final category = Category(
          id: service.category,
          name: service.title,
        );
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubServiceScreen(
              category: category,
              service: service,
            ),
          ),
        );
      } else {
        debugPrint('📄 [ServicesScreen] Navigating to service details');
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
      debugPrint('❌ [ServicesScreen] Navigation error: $e');
    } finally {
      if (mounted) _isNavigating = false;
    }
  }
  

  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_errorType != null) {
      return ErrorStateView(
        errorType: _errorType!,
        onRetry: _fetchAllData,
      );
    }
    
    if (_categories.isEmpty && _allServices.isEmpty) {
      // Check if this is due to missing location
      return FutureBuilder<Map<String, String>?>(
        future: Provider.of<CategoryService>(context, listen: false).getUserLocationCached(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          
          if (snapshot.data == null) {
            // No location data - show location missing empty state
            return const LocationMissingEmptyState();
          } else {
            // Has location but no services - show regular empty state
            return _buildEmptyState();
          }
        },
      );
    }
    
    return _buildContent();
  }
  
  Widget _buildLoadingState() {
    debugPrint('⏳ [ServicesScreen] Showing loading state');
    
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Search bar skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
        
        // Section title skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        
        // Horizontal scroller skeleton
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Grid skeleton
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    debugPrint('📭 [ServicesScreen] Showing empty state');
    
    return EmptyStateView(
      title: 'No Services Available',
      subtitle: 'Check back later for available services',
      icon: Icons.home_repair_service_outlined,
      onRetry: _fetchAllData,
    );
  }
  
  Widget _buildContent() {
    debugPrint('📱 [ServicesScreen] Building content with ${_allServices.length} services');
    
    return RefreshIndicator(
      onRefresh: _fetchAllData,
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Modern Header Section
          _buildModernHeader(),
          
          // Category Grid (2-column)
          if (_categories.isNotEmpty) _buildCategoryGrid(),
          
          // Featured Services (horizontal scroll)
          if (_featuredServices.isNotEmpty) _buildFeaturedServicesSection(),
          
          // All Services Grid (2-column)
          _buildAllServicesGrid(),
          
          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large heading
            Text(
              'Find Services',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            // Subtext
            Text(
              'Book trusted technicians near you',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.subtitleColor,
              ),
            ),
            const SizedBox(height: 20),
            // Modern search bar with filter button
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for services...',
                        hintStyle: GoogleFonts.outfit(
                          color: Colors.grey[400],
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Colors.grey[400],
                                ),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter button
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _showFilterBottomSheet,
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryGrid() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Categories',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3.5,
              ),
              itemCount: _categories.take(6).length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryGridCard(category);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryGridCard(Category category) {
    final isSelected = _selectedCategoryId == category.id;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedCategoryId = isSelected ? null : category.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppTheme.primaryColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(category.id),
                color: isSelected ? Colors.white : AppTheme.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppTheme.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeaturedServicesSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Featured Services',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _featuredServices.length,
              itemBuilder: (context, index) {
                final service = _featuredServices[index];
                return _buildFeaturedServiceCard(service);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeaturedServiceCard(HomeService service) {
    final hasOffer = service.offerPrice != null && 
                     service.offerPrice! > 0 && 
                     service.offerPrice! < service.basePrice;
    final finalPrice = hasOffer ? service.offerPrice! : service.basePrice;
    
    return GestureDetector(
      onTap: () => _handleServiceTap(service),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 4),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: service.imageUrl ?? '',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Rating badge
                  if (service.rating > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              service.rating.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Service details
            Padding(
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hasOffer) ..[
                        Text(
                          '₹${service.basePrice.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '₹${finalPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
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
  
  Widget _buildAllServicesGrid() {
    final filteredServices = _filteredServices;
    
    if (filteredServices.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey[400],
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
                    ? 'Try adjusting your search terms'
                    : 'Check back later for available services',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategoryId == null 
                      ? 'All Services' 
                      : '${_categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => Category(id: '', name: 'Category')).name} Services',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor,
                  ),
                ),
                Text(
                  '${filteredServices.length} services',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                return _buildServiceGridCard(service);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildServiceGridCard(HomeService service) {
    final hasOffer = service.offerPrice != null && 
                     service.offerPrice! > 0 && 
                     service.offerPrice! < service.basePrice;
    final finalPrice = hasOffer ? service.offerPrice! : service.basePrice;
    
    return GestureDetector(
      onTap: () => _handleServiceTap(service),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: service.imageUrl ?? '',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Rating badge
                  if (service.rating > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              service.rating.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Favorite icon
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Service details
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
                    const Spacer(),
                    Row(
                      children: [
                        if (hasOffer) ..[
                          Text(
                            '₹${service.basePrice.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '₹${finalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
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
  
  void _showFilterBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Filter Services',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Categories',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('All', null),
                ..._categories.map((category) => _buildFilterChip(category.name, category.id)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _selectedCategoryId = null);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategoryId = categoryId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textColor,
          ),
        ),
      ),
    );
  }
  

  

  

  
  IconData _getCategoryIcon(String categoryId) {
    final id = categoryId.toLowerCase();
    if (id.contains('clean')) return Icons.cleaning_services_rounded;
    if (id.contains('electric')) return Icons.electrical_services_rounded;
    if (id.contains('plumb')) return Icons.plumbing_rounded;
    if (id.contains('ac') || id.contains('cool')) return Icons.ac_unit_rounded;
    if (id.contains('appliance')) return Icons.kitchen_rounded;
    if (id.contains('paint')) return Icons.format_paint_rounded;
    if (id.contains('carpentry') || id.contains('wood')) return Icons.carpenter_rounded;
    if (id.contains('pest')) return Icons.pest_control_rounded;
    if (id.contains('salon') || id.contains('spa')) return Icons.spa_rounded;
    if (id.contains('beauty') || id.contains('makeup')) return Icons.face_rounded;
    if (id.contains('massage')) return Icons.self_improvement_rounded;
    if (id.contains('repair') || id.contains('fix')) return Icons.build_rounded;
    if (id.contains('install')) return Icons.install_desktop_rounded;
    return Icons.home_repair_service_rounded;
  }
}
