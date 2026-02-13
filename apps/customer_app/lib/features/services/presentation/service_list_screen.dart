import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/service.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';

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
          if (service.imageUrl.isEmpty || !service.imageUrl.startsWith('http')) {
            continue;
          }
          precacheImage(
            NetworkImage(service.imageUrl),
            context,
          );
        } catch (_) {
          // Silently ignore prefetch errors to prevent crashes
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryBar(firestoreService),
            Expanded(
              child: _buildServiceResults(firestoreService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        'All Services',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          fontSize: 26,
          color: AppTheme.textColor,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
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
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search services',
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
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar(FirestoreService service) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.getCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [
          {'title': 'Cleaning', 'id': 'cleaning'},
          {'title': 'Repair', 'id': 'repair'},
          {'title': 'Appliance', 'id': 'appliance'},
          {'title': 'Electrical', 'id': 'electrician'},
          {'title': 'Plumbing', 'id': 'plumbing'},
        ];
        
        return Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 12, top: 8),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final bool isAll = index == 0;
              final categoryData = isAll ? null : categories[index - 1];
              final String? catId = isAll 
                  ? null 
                  : (categoryData?['id'] ?? categoryData?['title'] ?? '').toString();
              final String label = isAll 
                  ? 'All Services' 
                  : (categoryData?['title'] ?? categoryData?['name'] ?? 'Category').toString();
              
              final bool isSelected = _selectedCategory == catId;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = catId);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : AppTheme.textColor,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : Colors.grey.shade200,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildServiceResults(FirestoreService service) {
    return StreamBuilder<List<HomeService>>(
      stream: service.streamServices(category: _selectedCategory),
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          return _buildError();
        }

        // Loading state - only show skeleton when waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
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
          return _buildEmpty();
        }

        // Services grid with performance optimizations
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: services.length,
          cacheExtent: 800,
          physics: const BouncingScrollPhysics(),
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
          itemBuilder: (context, index) {
            return RepaintBoundary(
              child: _buildServiceCard(services[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
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
    );
  }

  Widget _buildServiceCard(HomeService service) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Debounce: ignore taps while navigating
          if (_isNavigating) return;
          _isNavigating = true;
          HapticFeedback.lightImpact();
          
          // Perform navigation - actual navigation is handled by parent
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _isNavigating = false;
            }
          });
        },
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
              // Service Image with safe loading and error fallback
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildServiceImage(service),
                ),
              ),
              const SizedBox(height: 10),
              // Service Name
              Text(
                service.title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
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

  Widget _buildServiceImage(HomeService service) {
    // Empty URL fallback
    if (service.imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(Icons.category_rounded, color: Colors.grey),
        ),
      );
    }

    return Image.network(
      service.imageUrl,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        // Loading placeholder with light grey bg
        return Container(
          color: const Color(0xFFF5F5F5),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Error fallback with light grey bg and centered icon
        return Container(
          color: const Color(0xFFF5F5F5),
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: 9,
      physics: const NeverScrollableScrollPhysics(),
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
    );
  }
}
