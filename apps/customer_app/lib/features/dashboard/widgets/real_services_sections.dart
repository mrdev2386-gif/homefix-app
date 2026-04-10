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
        // STATE 1: WAITING - Show loader with proper layout
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildShimmer(context),
            ],
          );
        }

        // STATE 2: ERROR - Hide section
        if (snapshot.hasError) {
          if (kDebugMode) {
            print('[ERROR] $title: ${snapshot.error}');
          }
          return const SizedBox.shrink();
        }

        // STATE 3: EMPTY DATA - Hide section
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final allServices = snapshot.data!;
        var services = filterFunction(allServices);
        
        if (displayedServiceIds != null) {
          services = services.where((s) => !displayedServiceIds!.contains(s.id)).toList();
        }
        
        if (kDebugMode) {
          print('[REAL CHECK] $title: ${services.length} services (from ${allServices.length} total)');
        }
        
        // Hide section if filtered result is empty
        if (services.isEmpty) {
          return const SizedBox.shrink();
        }
        
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
        // Safety filter: Remove services without required fields
        final validServices = allServices.where((s) =>
          s.id != null && s.id.isNotEmpty &&
          s.category != null && s.category!.isNotEmpty &&
          s.createdAt != null
        ).toList();
        
        // STRICT: Force sort by createdAt DESC
        validServices.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        
        // Take latest 15 services
        final recent = validServices.take(15).toList();
        
        if (kDebugMode) {
          print('[FINAL CHECK] RecentlyAdded: ${recent.length} (from ${validServices.length} valid services, sorted by createdAt DESC)');
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

  Future<Map<String, dynamic>> _getUserInteractionData() async {
    if (_userId == null) return {'categories': <String>{}, 'serviceIds': <String>{}};
    
    final categories = <String>{};
    final serviceIds = <String>{};
    
    try {
      final db = FirebaseFirestore.instance;
      
      // Fetch cart items
      final cartSnapshot = await db
          .collection('customers')
          .doc(_userId)
          .collection('cart')
          .limit(10)
          .get();
      
      for (final doc in cartSnapshot.docs) {
        final data = doc.data();
        final serviceId = data['serviceId'] as String?;
        final categoryId = data['categoryId'] as String?;
        final categoryName = data['categoryName'] as String?;
        
        if (serviceId != null && serviceId.isNotEmpty) {
          serviceIds.add(serviceId.toLowerCase());
        }
        if (categoryId != null && categoryId.isNotEmpty) {
          categories.add(categoryId.toLowerCase());
        }
        if (categoryName != null && categoryName.isNotEmpty) {
          categories.add(categoryName.toLowerCase());
        }
      }
      
      // Fetch favorites
      final favoritesSnapshot = await db
          .collection('customers')
          .doc(_userId)
          .collection('favorites')
          .limit(10)
          .get();
      
      for (final doc in favoritesSnapshot.docs) {
        final data = doc.data();
        final serviceId = data['serviceId'] as String?;
        final categoryId = data['categoryId'] as String?;
        final categoryName = data['categoryName'] as String?;
        
        if (serviceId != null && serviceId.isNotEmpty) {
          serviceIds.add(serviceId.toLowerCase());
        }
        if (categoryId != null && categoryId.isNotEmpty) {
          categories.add(categoryId.toLowerCase());
        }
        if (categoryName != null && categoryName.isNotEmpty) {
          categories.add(categoryName.toLowerCase());
        }
      }
      
      // Fetch past bookings
      final bookingsSnapshot = await db
          .collection('bookings')
          .where('customerId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final serviceId = data['serviceId'] as String?;
        final categoryId = data['categoryId'] as String?;
        final categoryName = data['categoryName'] as String?;
        
        if (serviceId != null && serviceId.isNotEmpty) {
          serviceIds.add(serviceId.toLowerCase());
        }
        if (categoryId != null && categoryId.isNotEmpty) {
          categories.add(categoryId.toLowerCase());
        }
        if (categoryName != null && categoryName.isNotEmpty) {
          categories.add(categoryName.toLowerCase());
        }
      }
      
      if (kDebugMode) {
        print('[Recommended] User data - categories: ${categories.length}, serviceIds: ${serviceIds.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Recommended] Error fetching user interactions: $e');
      }
    }
    
    return {'categories': categories, 'serviceIds': serviceIds};
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
            
            // STRICT: If no user data, show ONLY top rated (rating >= 4)
            if (userCategories.isEmpty && userServiceIds.isEmpty) {
              if (kDebugMode) {
                print('[Recommended] No user data - showing ONLY top rated services');
              }
              
              final topRated = allServices
                  .where((s) => (s.rating ?? 0) >= 4.0)
                  .toList()
                ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
              
              final result = topRated.take(10).toList();
              if (kDebugMode) {
                print('[FINAL CHECK] Recommended: ${result.length} (fallback to top rated)');
              }
              return result;
            }
            
            // STRICT PERSONALIZATION with cascading priority
            final highPriority = <HomeService>[]; // Exact serviceId match
            final mediumPriority = <HomeService>[]; // SubCategory match
            final lowPriority = <HomeService>[]; // Category match (last resort)
            
            for (final service in allServices) {
              // Safety filter
              if (service.id == null || service.id.isEmpty) continue;
              if (service.category == null || service.category!.isEmpty) continue;
              
              final serviceIdLower = service.id.toLowerCase();
              final serviceCategoryLower = (service.category ?? '').toLowerCase();
              final serviceCategoryNameLower = (service.categoryName ?? '').toLowerCase();
              
              // HIGH PRIORITY: Exact serviceId match
              if (userServiceIds.contains(serviceIdLower)) {
                highPriority.add(service);
                continue; // Skip other checks
              }
              
              // MEDIUM PRIORITY: Category match (only if no high priority matches yet)
              if (userCategories.contains(serviceCategoryLower) || 
                  userCategories.contains(serviceCategoryNameLower)) {
                mediumPriority.add(service);
              }
            }
            
            // Sort each priority group by rating DESC
            highPriority.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
            mediumPriority.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
            
            // CASCADING LOGIC: Use highest priority available
            List<HomeService> result;
            if (highPriority.isNotEmpty) {
              // If HIGH matches exist → use ONLY high priority
              result = highPriority.take(10).toList();
              if (kDebugMode) {
                print('[STRICT REC] high: ${highPriority.length}, medium: 0 (ignored), final: ${result.length}');
              }
            } else if (mediumPriority.isNotEmpty) {
              // If no HIGH → use MEDIUM priority
              result = mediumPriority.take(10).toList();
              if (kDebugMode) {
                print('[STRICT REC] high: 0, medium: ${mediumPriority.length}, final: ${result.length}');
              }
            } else {
              // If nothing → fallback to top rated
              final topRated = allServices
                  .where((s) => (s.rating ?? 0) >= 4.0)
                  .toList()
                ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
              result = topRated.take(10).toList();
              if (kDebugMode) {
                print('[STRICT REC] high: 0, medium: 0, final: ${result.length} (fallback to top rated)');
              }
            }
            
            if (kDebugMode) {
              print('[FINAL CHECK] Recommended: ${result.length}');
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
