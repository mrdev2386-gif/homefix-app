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
        // MANDATORY: Check for errors first
        if (snapshot.hasError) {
          debugPrint('Firestore Error: ${snapshot.error}');
          return Center(child: Text('Error loading services', style: GoogleFonts.outfit()));
        }

        // MANDATORY: Check connection state and data presence
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmpty();
        }

        var services = snapshot.data!;
        
        // Final sanity check before filtering
        if (services.isEmpty) {
          return _buildEmpty();
        }
        
        if (_searchQuery.isNotEmpty) {
          services = services.where((s) => 
            s.title.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        if (_sortBy == 'Top Rated') {
          services.sort((a, b) => b.rating.compareTo(a.rating));
        }

        if (services.isEmpty) {
          return _buildEmpty();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            // SAFETY: Double check bounds
            if (index >= services.length) return const SizedBox();
            
            final service = services[index];
            return ServiceGridIcon(service: service);
          },
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
