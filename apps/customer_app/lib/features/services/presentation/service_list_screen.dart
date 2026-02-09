import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/service.dart';
import '../../../core/services/firestore_service.dart';
import '../../dashboard/widgets/service_grid_icon.dart';
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
  String _sortBy = 'Popular';
  final TextEditingController _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Service Catalog',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterBottomSheet(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchArea(),
          _buildCategoryBar(firestoreService),
          Expanded(
            child: _buildServiceResults(firestoreService),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search for services...',
            hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
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
          height: 50,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final bool isAll = index == 0;
              
              // SAFE ACCESS: Avoid "Null is not a subtype of String"
              final categoryData = isAll ? null : categories[index - 1];
              final String? catId = isAll ? null : (categoryData?['id'] ?? categoryData?['title'] ?? '').toString();
              final String label = isAll ? 'All Services' : (categoryData?['title'] ?? categoryData?['name'] ?? 'Category').toString();
              
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
        if (snapshot.hasError) {
          return Center(child: Text('Error loading services', style: GoogleFonts.outfit()));
        }

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

        if (_sortBy == 'Top Rated') {
          services.sort((a, b) => b.rating.compareTo(a.rating));
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (services.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmpty(),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ServiceGridIcon(service: services[index]),
                    childCount: services.length,
                  ),
                ),
              ),
              _buildBottomBanners(service),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBottomBanners(FirestoreService service) {
    return StreamBuilder<List<ServiceBanner>>(
      stream: service.streamServiceBottomBanners(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final banners = snapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final banner = banners[index];
                return _buildBannerCard(banner);
              },
              childCount: banners.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannerCard(ServiceBanner banner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 160,
      width: double.infinity,
      child: InkWell(
        onTap: () => _showComingSoonDialog(banner.title),
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.broken_image_rounded, color: AppTheme.primaryColor),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.white,
                    child: Container(color: Colors.white),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      banner.description,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String title) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Row(
                children: [
                  const Icon(Icons.rocket_launch_rounded, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text('Coming Soon', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                ],
              ),
              content: Text(
                'This feature ($title) will be available soon. We are working hard to bring you the best experience!',
                style: GoogleFonts.outfit(fontSize: 15, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'GOT IT',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[100]!,
          highlightColor: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
            child: const Icon(Icons.search_off_rounded, size: 64, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            'No matching services found',
            style: GoogleFonts.outfit(color: AppTheme.textColor, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort Portfolio By',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  _buildSortTile(context, setModalState, 'Popular', Icons.trending_up_rounded),
                  _buildSortTile(context, setModalState, 'Top Rated', Icons.star_rounded),
                  _buildSortTile(context, setModalState, 'Price: Low to High', Icons.arrow_upward_rounded),
                  _buildSortTile(context, setModalState, 'Price: High to Low', Icons.arrow_downward_rounded),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Selection'),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildSortTile(BuildContext context, StateSetter setModalState, String title, IconData icon) {
    bool isSelected = _sortBy == title;
    return InkWell(
      onTap: () {
        setModalState(() => _sortBy = title);
        setState(() => _sortBy = title);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.subtitleColor, size: 20),
            const SizedBox(width: 16),
            Text(title, style: GoogleFonts.outfit(
              fontSize: 16, 
              color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            )),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 22),
          ],
        ),
      ),
    );
  }
}
