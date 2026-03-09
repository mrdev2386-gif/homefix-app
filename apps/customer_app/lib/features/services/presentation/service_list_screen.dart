import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../../core/providers/location_provider.dart';
import '../widgets/services_banner.dart';
import '../widgets/category_chip_bar.dart';
import '../widgets/featured_services_carousel.dart';
import '../widgets/service_grid_card.dart';
import '../widgets/empty_state_view.dart';
import 'sub_service_screen.dart';
import 'service_details_screen.dart';

/// Premium Services Screen with Urban Company-style UI
/// Properly architected for performance and stability.
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
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Helpers
  Timer? _debounceTimer;
  bool _isNavigating = false;
  String? _selectedCategory;
  String _searchQuery = '';
  ErrorType? _errorType;
  bool _hasError = false;

  late Stream<List<HomeService>> _servicesStream;
  late Stream<List<HomeService>> _topServicesStream;

  // Category service for data fetching
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
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

  /// Initialize streams (SINGLE SOURCE OF TRUTH)
  void _initStreams() {
    _topServicesStream = _categoryService.getTopServices(limit: 6);
    _updateServicesStream();
  }

  void _updateServicesStream() {
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      _servicesStream = _categoryService.getServicesByCategory(_selectedCategory!);
    } else {
      _servicesStream = _categoryService.getAllServices();
    }
  }

  void _handleError(dynamic error) {
    debugPrint('❌ [ServiceListScreen] Error: $error');
    final errorString = error.toString().toLowerCase();

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

    if (mounted) {
      setState(() {
        _hasError = true;
        _errorType = type;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _searchQuery = value);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _onCategoryChanged(String? categoryId) {
    if (_selectedCategory == categoryId) return;

    setState(() {
      _selectedCategory = categoryId;
      _searchQuery = '';
      _searchController.clear();
      _updateServicesStream();
    });

    HapticFeedback.selectionClick();
  }

  /// Handle service tap with navigation debounce and safety
  Future<void> _handleServiceTap(HomeService service) async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
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
      body: SafeArea(
        child: Column(
          children: [
            // Header with search
            _buildHeader(),
            // Category chips
            CategoryChipBar(
              selectedCategoryId: _selectedCategory,
              onCategorySelected: _onCategoryChanged,
            ),
            // Main content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Services',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  final address = locationProvider.selectedAddress;
                  if (address == null) return const SizedBox.shrink();

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          address.label.isNotEmpty ? address.label : 'Location',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildModernSearchBar(),
        ],
      ),
    );
  }

  Widget _buildModernSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search for cleaning, repairs...',
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
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<List<HomeService>>(
      stream: _servicesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _handleError(snapshot.error);
          return ErrorStateView(
            errorType: _errorType ?? ErrorType.unknown,
            onRetry: () => setState(() => _updateServicesStream()),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingContent();
        }

        final allServices = snapshot.data ?? [];
        final filteredServices = _searchQuery.isEmpty
            ? allServices
            : allServices
                .where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

        if (filteredServices.isEmpty) {
          return EmptyStateView(
            title: 'No services found',
            subtitle: _searchQuery.isNotEmpty
                ? 'Try adjusting your search or category'
                : 'No services available in this category',
            onRetry: () => setState(() => _updateServicesStream()),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() => _updateServicesStream()),
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Section 1: Top Banners
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: ServicesBanner(height: 170),
                ),
              ),

              // Section 2: Featured Services
              StreamBuilder<List<HomeService>>(
                stream: _topServicesStream,
                builder: (context, topSnapshot) {
                  if (!topSnapshot.hasData || topSnapshot.data!.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        FeaturedServicesCarousel(
                          services: topSnapshot.data!,
                          onServiceTap: _handleServiceTap,
                          height: 190,
                          cardWidth: 270,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Services Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory != null ? 'Services' : 'All Services',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${filteredServices.length} services',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Services Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final service = filteredServices[index];
                      return ServiceGridCard(
                        key: ValueKey(service.id),
                        service: service,
                        onTap: () => _handleServiceTap(service),
                        index: index,
                      );
                    },
                    childCount: filteredServices.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingContent() {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Container(
            height: 170,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 270,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 20,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }
}
