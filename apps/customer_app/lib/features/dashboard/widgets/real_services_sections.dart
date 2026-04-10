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
  final Stream<List<HomeService>> stream;
  final Set<String>? displayedServiceIds;
  final List<HomeService> Function(List<HomeService>) filterFunction;

  const _BaseServicesSection({
    required this.title,
    required this.titleIcon,
    required this.iconGradient,
    required this.stream,
    required this.filterFunction,
    this.displayedServiceIds,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeService>>(
      stream: stream,
      builder: (context, snapshot) {
        // STATE 1: WAITING - Hide section (no loader to avoid layout jump)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        // STATE 2: ERROR - Hide section
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        // STATE 3: EMPTY DATA - Hide section
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final allServices = snapshot.data!;
        final services = filterFunction(allServices);
        
        // Hide section if no services after filtering
        if (services.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Optional: Track displayed IDs (but don't filter by them to avoid 0 count)
        if (displayedServiceIds != null) {
          for (final service in services) {
            displayedServiceIds!.add(service.id);
          }
        }

        // STATE 4: HAS DATA - Show section
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildHorizontalScrollingRows(context, services),
          ],
        );
      },
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
class TopRatedRealServicesSection extends StatefulWidget {
  final Set<String>? displayedServiceIds;
  
  const TopRatedRealServicesSection({super.key, this.displayedServiceIds});

  @override
  State<TopRatedRealServicesSection> createState() => _TopRatedRealServicesSectionState();
}

class _TopRatedRealServicesSectionState extends State<TopRatedRealServicesSection> {
  late final Stream<List<HomeService>> _servicesStream;

  @override
  void initState() {
    super.initState();
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _servicesStream = firestoreService.getCachedServicesStream();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'Top Rated Services',
      titleIcon: Icons.star_rounded,
      iconGradient: const [Color(0xFFFF9800), Color(0xFFFF5722)],
      stream: _servicesStream,
      displayedServiceIds: widget.displayedServiceIds,
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
class RecentlyAddedServicesSection extends StatefulWidget {
  final Set<String>? displayedServiceIds;
  
  const RecentlyAddedServicesSection({super.key, this.displayedServiceIds});

  @override
  State<RecentlyAddedServicesSection> createState() => _RecentlyAddedServicesSectionState();
}

class _RecentlyAddedServicesSectionState extends State<RecentlyAddedServicesSection> {
  late final Stream<List<HomeService>> _servicesStream;

  @override
  void initState() {
    super.initState();
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _servicesStream = firestoreService.getCachedServicesStream();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'Recently Added Services',
      titleIcon: Icons.new_releases_rounded,
      iconGradient: const [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      stream: _servicesStream,
      displayedServiceIds: widget.displayedServiceIds,
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
class RecommendedServicesSection extends StatefulWidget {
  final Set<String>? displayedServiceIds;
  
  const RecommendedServicesSection({super.key, this.displayedServiceIds});

  @override
  State<RecommendedServicesSection> createState() => _RecommendedServicesSectionState();
}

class _RecommendedServicesSectionState extends State<RecommendedServicesSection> {
  late final Stream<List<HomeService>>? _servicesStream;
  String? _userId;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    _userId = auth.currentUser?.uid;
    
    if (_userId != null) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      _servicesStream = firestoreService.getCachedServicesStream();
    } else {
      _servicesStream = null;
    }
  }

  Future<Map<String, dynamic>> _getUserInteractionData() async {
    if (_userId == null) return {'categories': <String>{}, 'serviceIds': <String>{}};
    
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      return await firestoreService.getUserInteractionData(_userId!);
    } catch (e) {
      if (kDebugMode) {
        print('[Recommended] Error fetching user interactions: $e');
      }
      return {'categories': <String>{}, 'serviceIds': <String>{}};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_servicesStream == null) return const SizedBox.shrink();
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserInteractionData(),
      builder: (context, userDataSnapshot) {
        return _BaseServicesSection(
          title: 'Recommended For You',
          titleIcon: Icons.auto_awesome_rounded,
          iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
          stream: _servicesStream!,
          displayedServiceIds: widget.displayedServiceIds,
          filterFunction: (allServices) {
            final userData = userDataSnapshot.data ?? {'categories': <String>{}, 'serviceIds': <String>{}};
            final userCategories = userData['categories'] as Set<String>;
            final userServiceIds = userData['serviceIds'] as Set<String>;
            
            // If no user data, show top rated services
            if (userCategories.isEmpty && userServiceIds.isEmpty) {
              final topRated = allServices
                  .where((s) => (s.rating ?? 0) >= 4.0)
                  .toList()
                ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
              
              return topRated.take(10).toList();
            }
            
            // Personalization with cascading priority
            final highPriority = <HomeService>[]; // Exact serviceId match
            final mediumPriority = <HomeService>[]; // Category match
            
            for (final service in allServices) {
              // Safety filter
              if (service.id == null || service.id.isEmpty) continue;
              if (service.category == null || service.category!.isEmpty) continue;
              
              final serviceIdLower = service.id.toLowerCase();
              final serviceCategoryLower = (service.category ?? '').toLowerCase();
              final serviceCategoryNameLower = (service.categoryName ?? '').toLowerCase();
              
              // High priority: Exact serviceId match
              if (userServiceIds.contains(serviceIdLower)) {
                highPriority.add(service);
                continue;
              }
              
              // Medium priority: Category match
              if (userCategories.contains(serviceCategoryLower) || 
                  userCategories.contains(serviceCategoryNameLower)) {
                mediumPriority.add(service);
              }
            }
            
            // Sort by rating
            highPriority.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
            mediumPriority.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
            
            // Use highest priority available
            if (highPriority.isNotEmpty) {
              return highPriority.take(10).toList();
            } else if (mediumPriority.isNotEmpty) {
              return mediumPriority.take(10).toList();
            } else {
              final topRated = allServices
                  .where((s) => (s.rating ?? 0) >= 4.0)
                  .toList()
                ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
              return topRated.take(10).toList();
            }
          },
        );
      },
    );
  }
}

/// All Services Section
class AllServicesSection extends StatefulWidget {
  final Set<String>? displayedServiceIds;
  
  const AllServicesSection({super.key, this.displayedServiceIds});

  @override
  State<AllServicesSection> createState() => _AllServicesSectionState();
}

class _AllServicesSectionState extends State<AllServicesSection> {
  late final Stream<List<HomeService>> _servicesStream;

  @override
  void initState() {
    super.initState();
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _servicesStream = firestoreService.getCachedServicesStream();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'All Services',
      titleIcon: Icons.grid_view_rounded,
      iconGradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      stream: _servicesStream,
      displayedServiceIds: widget.displayedServiceIds,
      filterFunction: (allServices) => allServices.take(50).toList(),
    );
  }
}
