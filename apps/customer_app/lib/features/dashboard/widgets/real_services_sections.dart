import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/services/firestore_service.dart';
import 'unified_service_card.dart';

/// Base section widget with horizontal scrolling rows
class _BaseServicesSection extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final List<Color> iconGradient;
  final List<HomeService> data;
  final Set<String>? displayedServiceIds;
  final List<HomeService> Function(List<HomeService>) filterFunction;

  const _BaseServicesSection({
    required this.title,
    required this.titleIcon,
    required this.iconGradient,
    required this.data,
    required this.filterFunction,
    this.displayedServiceIds,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final services = filterFunction(data);
    
    // Show message if no services after filtering
    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No services available',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.subtitleColor,
            ),
          ),
        ),
      );
    }
    
    // Optional: Track displayed IDs (but don't filter by them to avoid 0 count)
    if (displayedServiceIds != null) {
      for (final service in services) {
        displayedServiceIds!.add(service.id);
      }
    }

    // Show section
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildHorizontalScrollingRows(context, services),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(titleIcon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalScrollingRows(BuildContext context, List<HomeService> services) {
    // STRICT: Show ONLY 2 rows vertically
    // Each row contains ALL its services horizontally scrollable
    // Split services into 2 rows (alternating: row 0 gets index 0,2,4,6... row 1 gets index 1,3,5,7...)
    final row1Services = <HomeService>[];
    final row2Services = <HomeService>[];
    
    for (int i = 0; i < services.length; i++) {
      if (i % 2 == 0) {
        row1Services.add(services[i]);
      } else {
        row2Services.add(services[i]);
      }
    }

    return Column(
      children: [
        if (row1Services.isNotEmpty) _buildRow(context, row1Services),
        if (row2Services.isNotEmpty) _buildRow(context, row2Services),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<HomeService> rowServices) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: MediaQuery.of(context).size.width * 0.65,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: rowServices.length,
          itemBuilder: (context, index) {
            final itemWidth = (MediaQuery.of(context).size.width - 48) / 2;
            return Container(
              width: itemWidth,
              margin: EdgeInsets.only(right: index < rowServices.length - 1 ? 16 : 0),
              child: UniversalServiceCard(
                key: ValueKey(rowServices[index].id),
                service: rowServices[index],
                isGrid: true,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Top Rated Services Section
class TopRatedRealServicesSection extends StatelessWidget {
  final List<HomeService> data;
  final Set<String>? displayedServiceIds;
  
  const TopRatedRealServicesSection({
    super.key,
    required this.data,
    this.displayedServiceIds,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'Top Rated Services',
      titleIcon: Icons.star_rounded,
      iconGradient: const [Color(0xFFFF9800), Color(0xFFFF5722)],
      data: data,
      displayedServiceIds: displayedServiceIds,
      filterFunction: (allServices) {
        final topRated = allServices
            .where((s) => (s.rating ?? 0) >= 4.0)
            .toList()
          ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        
        return topRated.take(20).toList();
      },
    );
  }
}

/// Recently Added Services Section
class RecentlyAddedServicesSection extends StatelessWidget {
  final List<HomeService> data;
  final Set<String>? displayedServiceIds;
  
  const RecentlyAddedServicesSection({
    super.key,
    required this.data,
    this.displayedServiceIds,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'Recently Added Services',
      titleIcon: Icons.new_releases_rounded,
      iconGradient: const [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      data: data,
      displayedServiceIds: displayedServiceIds,
      filterFunction: (allServices) {
        // Safety filter: Remove services without required fields
        final validServices = allServices.where((s) =>
          s.id != null && s.id.isNotEmpty &&
          s.category != null && s.category!.isNotEmpty &&
          s.createdAt != null
        ).toList();
        
        // Sort by createdAt DESC
        validServices.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        
        return validServices.take(15).toList();
      },
    );
  }
}

/// Recommended Services Section with Personalization
class RecommendedServicesSection extends StatelessWidget {
  final List<HomeService> data;
  final Set<String>? displayedServiceIds;
  
  const RecommendedServicesSection({
    super.key,
    required this.data,
    this.displayedServiceIds,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'Recommended For You',
      titleIcon: Icons.auto_awesome_rounded,
      iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
      data: data,
      displayedServiceIds: displayedServiceIds,
      filterFunction: (allServices) {
        final topRated = allServices
            .where((s) => (s.rating ?? 0) >= 4.0)
            .toList()
          ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        
        return topRated.take(10).toList();
      },
    );
  }
}

/// All Services Section
class AllServicesSection extends StatelessWidget {
  final List<HomeService> data;
  final Set<String>? displayedServiceIds;
  
  const AllServicesSection({
    super.key,
    required this.data,
    this.displayedServiceIds,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'All Services',
      titleIcon: Icons.grid_view_rounded,
      iconGradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      data: data,
      displayedServiceIds: displayedServiceIds,
      filterFunction: (allServices) => allServices.take(50).toList(),
    );
  }
}
