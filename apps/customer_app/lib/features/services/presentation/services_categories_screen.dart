import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../widgets/empty_state_view.dart';
import 'category_services_screen.dart';

/// Services Tab Screen - Shows categories only (Urban Company style)
/// 
/// This screen displays a grid of categories. Tapping a category
/// navigates to CategoryServicesScreen to show services under that category.
/// No booking is allowed here - only navigation.
class ServicesCategoriesScreen extends StatefulWidget {
  const ServicesCategoriesScreen({super.key});

  @override
  State<ServicesCategoriesScreen> createState() => _ServicesCategoriesScreenState();
}

class _ServicesCategoriesScreenState extends State<ServicesCategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = true;
  List<Category> _categories = [];
  ErrorType? _errorType;
  
  // Navigation guard
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorType = null;
    });

    try {
      final categories = await _categoryService.getCategoriesOnce();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
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

  Future<void> _handleCategoryTap(Category category) async {
    // Prevent double navigation
    if (_isNavigating) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryServicesScreen(category: category),
        ),
      );
    } finally {
      // Reset after navigation completes
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _isNavigating = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(
          'Services',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textColor,
          ),
        ),
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorType != null) {
      return ErrorStateView(
        errorType: _errorType!,
        onRetry: _fetchCategories,
      );
    }

    if (_categories.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCategoriesGrid();
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateView(
      title: 'No categories available',
      subtitle: 'Check back later for available services',
      icon: Icons.category_outlined,
      onRetry: _fetchCategories,
    );
  }

  Widget _buildCategoriesGrid() {
    return RefreshIndicator(
      onRefresh: _fetchCategories,
      color: AppTheme.primaryColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _CategoryCard(
            category: category,
            onTap: () => _handleCategoryTap(category),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category icon/image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: category.iconUrl != null && category.iconUrl!.isNotEmpty
                  ? SafeNetworkImage(
                      imageUrl: category.iconUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(16),
                      errorWidget: Icon(
                        _getCategoryIcon(category.id),
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    )
                  : Icon(
                      _getCategoryIcon(category.id),
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
            ),
            const SizedBox(height: 12),
            // Category name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category.name,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            // Services count
            Text(
              '${category.serviceCount ?? 0} services',
              style: GoogleFonts.outfit(
                fontSize: 12,
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
