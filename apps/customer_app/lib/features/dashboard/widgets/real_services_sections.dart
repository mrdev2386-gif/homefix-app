import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/services/firestore_service.dart';
import 'unified_service_card.dart';

/// Base section widget - OPTIMIZED WITH SHARED STREAM
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
        // STEP 3: LOADING STATE - Show shimmer immediately for smooth UX
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildShimmer(context),
            ],
          );
        }

        // ERROR STATE - STEP 2: Network recovery handled by Firestore auto-retry
        if (snapshot.hasError) {
          if (kDebugMode) {
            print('[ERROR] $title: ${snapshot.error}');
            print('[NETWORK] Firestore will auto-retry on network recovery');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Something went wrong',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please try again later',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // STEP 3: FILTER IN UI (NOT FIRESTORE)
        final allServices = snapshot.data ?? [];
        var services = filterFunction(allServices);
        
        // Filter duplicates
        if (displayedServiceIds != null) {
          services = services.where((s) => !displayedServiceIds!.contains(s.id)).toList();
        }
        
        // STEP 4: LOGGING - Track service counts for debugging
        if (kDebugMode) {
          print('[DATA] $title: ${services.length} services (from ${allServices.length} total)');
        }
        
        // EMPTY STATE
        if (services.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, color: Colors.grey[300], size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No services available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Check back later',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        
        // Track displayed services
        if (displayedServiceIds != null) {
          for (final service in services) {
            displayedServiceIds!.add(service.id);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildGrid(context, services),
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

  Widget _buildGrid(BuildContext context, List<HomeService> services) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = (width - 16) / 2;
          final itemHeight = itemWidth * 1.3;
          
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: itemWidth / itemHeight,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              return UniversalServiceCard(
                key: ValueKey(services[index].id),
                service: services[index],
                isGrid: true,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = (width - 16) / 2;
          final itemHeight = itemWidth * 1.3;
          
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: itemWidth / itemHeight,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
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
        },
      ),
    );
  }
}

// STEP 2: USE SAME STREAM EVERYWHERE

/// All Services Section - USES SHARED CACHED STREAM
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
    // STEP 2: USE CACHED STREAM
    _servicesStream = firestoreService.getCachedServicesStream();
    if (kDebugMode) {
      print('[CACHE] AllServicesSection using shared stream');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'All Services',
      titleIcon: Icons.grid_view_rounded,
      iconGradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      stream: _servicesStream,
      displayedServiceIds: widget.displayedServiceIds,
      // STEP 3: FILTER IN UI - Take all services
      filterFunction: (allServices) => allServices.take(50).toList(),
    );
  }
}

/// Top Rated Services Section - USES SHARED CACHED STREAM
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
    // STEP 2: USE CACHED STREAM
    _servicesStream = firestoreService.getCachedServicesStream();
    if (kDebugMode) {
      print('[CACHE] TopRatedServicesSection using shared stream');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'Top Rated Services',
      titleIcon: Icons.star_rounded,
      iconGradient: const [Color(0xFFFF9800), Color(0xFFFF5722)],
      stream: _servicesStream,
      displayedServiceIds: widget.displayedServiceIds,
      // STEP 3: FILTER IN UI - Top rated only
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

/// Recently Added Services Section - USES SHARED CACHED STREAM
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
    // STEP 2: USE CACHED STREAM
    _servicesStream = firestoreService.getCachedServicesStream();
    if (kDebugMode) {
      print('[CACHE] RecentlyAddedServicesSection using shared stream');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'Recently Added Services',
      titleIcon: Icons.new_releases_rounded,
      iconGradient: const [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      stream: _servicesStream,
      displayedServiceIds: widget.displayedServiceIds,
      // STEP 3: FILTER IN UI - Recent services (already sorted by createdAt)
      filterFunction: (allServices) => allServices.take(10).toList(),
    );
  }
}

/// Recommended Services Section - USES SHARED CACHED STREAM
class RecommendedServicesSection extends StatefulWidget {
  final Set<String>? displayedServiceIds;
  
  const RecommendedServicesSection({super.key, this.displayedServiceIds});

  @override
  State<RecommendedServicesSection> createState() => _RecommendedServicesSectionState();
}

class _RecommendedServicesSectionState extends State<RecommendedServicesSection> {
  late final Stream<List<HomeService>>? _servicesStream;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.uid;
    
    if (userId != null) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      // STEP 2: USE CACHED STREAM
      _servicesStream = firestoreService.getCachedServicesStream();
      if (kDebugMode) {
        print('[CACHE] RecommendedServicesSection using shared stream');
      }
    } else {
      _servicesStream = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_servicesStream == null) return const SizedBox.shrink();
    
    return _BaseServicesSection(
      title: 'Recommended For You',
      titleIcon: Icons.auto_awesome_rounded,
      iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
      stream: _servicesStream!,
      displayedServiceIds: widget.displayedServiceIds,
      // STEP 3: FILTER IN UI - Recommended (for now, just take first 10)
      filterFunction: (allServices) => allServices.take(10).toList(),
    );
  }
}
