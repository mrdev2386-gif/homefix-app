import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import 'service_details_screen.dart';
import 'sub_service_screen.dart';
import 'category_services_screen.dart';

/// Modern Services Screen - Premium UI with Urban Company-inspired design
/// 
/// PHASE 1: Critical Data Fix - Comprehensive debugging and data visibility
/// This screen displays all services with proper error handling and logging
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with AutomaticKeepAliveClientMixin {
  
  // Service
  final CategoryService _categoryService = CategoryService();
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Data state
  List<Category> _categories = [];
  List<HomeService> _allServices = [];
  List<HomeService> _topRatedServices = [];
  List<HomeService> _recentServices = [];
  List<HomeService> _trendingServices = [];
  
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
  
  /// PHASE 1: Critical Data Fix - Comprehensive data fetching with logging
  Future<void> _fetchAllData() async {
    debugPrint('🔍 [ServicesScreen] Starting data fetch...');
    
    setState(() {
      _isLoading = true;
      _errorType = null;
    });
    
    try {
      // Fetch categories
      debugPrint('📁 [ServicesScreen] Fetching categories...');
      final categories = await _categoryService.getCategoriesOnce();
      debugPrint('✅ [ServicesScreen] Categories loaded: ${categories.length}');
      
      // Log each category with service count
      for (var i = 0; i < categories.length; i++) {
        final cat = categories[i];
        debugPrint('   ${i + 1}. ${cat.name} (ID: ${cat.id}, Services: ${cat.serviceCount}, Active: ${cat.isActive})');
      }
      
      // Fetch all services using collectionGroup
      debugPrint('🛠️ [ServicesScreen] Fetching all services...');
      final allServicesSnapshot = await _categoryService.getAllServicesOnce();
      debugPrint('✅ [ServicesScreen] All services loaded: ${allServicesSnapshot.length}');
      
      // Group services by category for logging
      final servicesByCategory = <String, int>{};
      for (var service in allServicesSnapshot) {
        servicesByCategory[service.category] = 
            (servicesByCategory[service.category] ?? 0) + 1;
      }
      
      debugPrint('📊 [ServicesScreen] Services by category:');
      servicesByCategory.forEach((categoryId, count) {
        final categoryName = categories
            .firstWhere((c) => c.id == categoryId, orElse: () => Category(id: categoryId, name: 'Unknown'))
            .name;
        debugPrint('   - $categoryName: $count services');
      });
      
      // Filter top rated services (rating >= 4.0)
      final topRated = allServicesSnapshot
          .where((s) => s.rating >= 4.0)
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
      debugPrint('⭐ [ServicesScreen] Top rated services (>=4.0): ${topRated.length}');
      
      // Get recent services (last 10)
      final recent = allServicesSnapshot.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('🆕 [ServicesScreen] Recent services: ${recent.take(10).length}');
      
      // Get trending services
      final trending = allServicesSnapshot
          .where((s) => s.isTrending)
          .toList();
      debugPrint('🔥 [ServicesScreen] Trending services: ${trending.length}');
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _allServices = allServicesSnapshot;
          _topRatedServices = topRated.take(5).toList();
          _recentServices = recent.take(10).toList();
          _trendingServices = trending.take(10).toList();
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
          debugPrint('🌐 [ServicesScreen] Error type: Network Error');
        } else if (errorString.contains('permission') ||
            errorString.contains('denied')) {
          type = ErrorType.permissionDenied;
          debugPrint('🔒 [ServicesScreen] Error type: Permission Denied');
        } else if (errorString.contains('failed-precondition') ||
            errorString.contains('index')) {
          type = ErrorType.failedPrecondition;
          debugPrint('⚠️ [ServicesScreen] Error type: Failed Precondition (missing index?)');
        } else {
          type = ErrorType.unknown;
          debugPrint('❓ [ServicesScreen] Error type: Unknown');
        }
        
        setState(() {
          _errorType = type;
          _isLoading = false;
        });
      }
    }
  }
  
  /// Get all services once (helper method)
  Future<List<HomeService>> getAllServicesOnce() async {
    // This will be implemented in CategoryService
    // For now, we'll fetch from all categories
    final services = <HomeService>[];
    
    for (var category in _categories) {
      try {
        final categoryServices = await _categoryService
            .getServicesByCategory(category.id)
            .first;
        services.addAll(categoryServices);
      } catch (e) {
        debugPrint('⚠️ [ServicesScreen] Error fetching services for ${category.name}: $e');
      }
    }
    
    return services;
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
    if (_searchQuery.isEmpty) return _allServices;
    
    final query = _searchQuery.toLowerCase();
    final filtered = _allServices
        .where((s) => s.title.toLowerCase().contains(query) ||
                     s.description.toLowerCase().contains(query))
        .toList();
    
    debugPrint('🔍 [ServicesScreen] Filtered services: ${filtered.length}');
    return filtered;
  }
  
  Future<void> _handleServiceTap(HomeService service) async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    
    debugPrint('👆 [ServicesScreen] Service tapped: ${service.title}');
    HapticFeedback.lightImpact();
    
    try {
      // Check if service has sub-services
      final hasSubServices = await _categoryService.serviceHasSubServices(
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
  
  Future<void> _handleCategoryTap(Category category) async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    
    debugPrint('👆 [ServicesScreen] Category tapped: ${category.name}');
    HapticFeedback.lightImpact();
    
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryServicesScreen(category: category),
        ),
      );
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
      return _buildEmptyState();
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
          // Search Bar
          _buildSearchBar(),
          
          // Top Rated Services (if available)
          if (_topRatedServices.isNotEmpty) _buildTopRatedSection(),
          
          // Popular Services
          if (_allServices.isNotEmpty) _buildPopularServicesSection(),
          
          // Trending Near You
          if (_trendingServices.isNotEmpty) _buildTrendingSection(),
          
          // New Services
          if (_recentServices.isNotEmpty) _buildNewServicesSection(),
          
          // All Categories Grid
          if (_categories.isNotEmpty) _buildCategoriesSection(),
          
          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search for services',
              hintStyle: GoogleFonts.outfit(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopRatedSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Top Rated Services',
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
              itemCount: _topRatedServices.length,
              itemBuilder: (context, index) {
                final service = _topRatedServices[index];
                return _buildTopRatedCard(service);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildTopRatedCard(HomeService service) {
    return GestureDetector(
      onTap: () => _handleServiceTap(service),
      child: Container(
        width: 280,
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 120,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${service.rating} (${service.reviewCount} reviews)',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.subtitleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Starting at ₹${service.basePrice.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPopularServicesSection() {
    final services = _allServices.take(10).toList();
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Popular Services',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return _buildServiceCard(service);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildTrendingSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Trending Near You',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _trendingServices.length,
              itemBuilder: (context, index) {
                final service = _trendingServices[index];
                return _buildServiceCard(service);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildNewServicesSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'New on HomeFix',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _recentServices.length,
              itemBuilder: (context, index) {
                final service = _recentServices[index];
                return _buildServiceCard(service);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildServiceCard(HomeService service) {
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 120,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image, size: 32, color: Colors.grey),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${service.basePrice.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.duration,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoriesSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'All Categories',
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
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryCard(category);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () => _handleCategoryTap(category),
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(category.id),
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${category.serviceCount} services',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.subtitleColor,
              ),
            ),
          ],
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
