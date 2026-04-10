import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

        if (snapshot.hasError) {
          if (kDebugMode) {
            print('[ERROR] $title: ${snapshot.error}');
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
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        final allServices = snapshot.data ?? [];
        var services = filterFunction(allServices);
        
        if (displayedServiceIds != null) {
          services = services.where((s) => !displayedServiceIds!.contains(s.id)).toList();
        }
        
        if (kDebugMode) {
          print('[REAL CHECK] $title: ${services.length} services (from ${allServices.length} total)');
        }
        
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
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        
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
    final rows = <List<HomeService>>[];
    for (int i = 0; i < services.length; i += 2) {
      rows.add(services.sublist(i, i + 2 > services.length ? services.length : i + 2));
    }

    return Column(
      children: rows.map((rowServices) => _buildRow(context, rowServices)).toList(),
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

  Widget _buildShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: MediaQuery.of(context).size.width * 0.65,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 2,
          itemBuilder: (context, index) {
            final itemWidth = (MediaQuery.of(context).size.width - 48) / 2;
            return Container(
              width: itemWidth,
              margin: EdgeInsets.only(right: index < 1 ? 16 : 0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
                highlightColor: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
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
      filterFunction: (allServices) {
        final topRated = allServices
            .where((s) => (s.rating ?? 0) >= 4.0)
            .toList()
          ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        
        if (kDebugMode) {
          print('[REAL CHECK] TopRated: ${topRated.length} services with rating >= 4.0');
        }
        
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
      filterFunction: (allServices) {
        final recent = allServices.take(15).toList();
        
        if (kDebugMode) {
          print('[REAL CHECK] RecentlyAdded: ${recent.length} (sorted by createdAt DESC)');
        }
        
        return recent;
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
      if (kDebugMode) {
        print('[CACHE] RecommendedServicesSection using shared stream');
      }
    } else {
      _servicesStream = null;
    }
  }

  Future<Set<String>> _getUserInteractionCategories() async {
    if (_userId == null) return {};
    
    final categories = <String>{};
    
    try {
      final db = FirebaseFirestore.instance;
      
      final cartSnapshot = await db
          .collection('customers')
          .doc(_userId)
          .collection('cart')
          .limit(10)
          .get();
      
      for (final doc in cartSnapshot.docs) {
        final categoryId = doc.data()['categoryId'] as String?;
        if (categoryId != null && categoryId.isNotEmpty) {
          categories.add(categoryId);
        }
      }
      
      final favoritesSnapshot = await db
          .collection('customers')
          .doc(_userId)
          .collection('favorites')
          .limit(10)
          .get();
      
      for (final doc in favoritesSnapshot.docs) {
        final categoryId = doc.data()['categoryId'] as String?;
        if (categoryId != null && categoryId.isNotEmpty) {
          categories.add(categoryId);
        }
      }
      
      final bookingsSnapshot = await db
          .collection('bookings')
          .where('customerId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      for (final doc in bookingsSnapshot.docs) {
        final categoryId = doc.data()['categoryId'] as String?;
        if (categoryId != null && categoryId.isNotEmpty) {
          categories.add(categoryId);
        }
      }
      
      if (kDebugMode) {
        print('[Recommended] User interaction categories: $categories');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Recommended] Error fetching user interactions: $e');
      }
    }
    
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    if (_servicesStream == null) return const SizedBox.shrink();
    
    return FutureBuilder<Set<String>>(
      future: _getUserInteractionCategories(),
      builder: (context, categorySnapshot) {
        return _BaseServicesSection(
          title: 'Recommended For You',
          titleIcon: Icons.auto_awesome_rounded,
          iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
          stream: _servicesStream!,
          displayedServiceIds: widget.displayedServiceIds,
          filterFunction: (allServices) {
            final userCategories = categorySnapshot.data ?? {};
            
            if (userCategories.isEmpty) {
              if (kDebugMode) {
                print('[Recommended] No user data - falling back to top rated');
              }
              
              final topRated = allServices
                  .where((s) => (s.rating ?? 0) >= 4.0)
                  .toList()
                ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
              
              return topRated.take(10).toList();
            }
            
            final personalized = <HomeService>[];
            final otherServices = <HomeService>[];
            
            for (final service in allServices) {
              if (userCategories.contains(service.category) || 
                  userCategories.contains(service.categoryName)) {
                personalized.add(service);
              } else {
                otherServices.add(service);
              }
            }
            
            personalized.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
            
            final result = personalized.take(10).toList();
            
            if (result.length < 10) {
              otherServices.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
              result.addAll(otherServices.take(10 - result.length));
            }
            
            if (kDebugMode) {
              print('[REAL CHECK] Recommended: ${result.length} (personalized: ${personalized.length}, user categories: ${userCategories.length})');
            }
            
            return result;
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
      filterFunction: (allServices) => allServices.take(50).toList(),
    );
  }
}
