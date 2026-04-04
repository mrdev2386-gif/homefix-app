import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/services/firestore_service.dart';
import 'package:customer_app/core/providers/cart_provider.dart';
import 'package:customer_app/core/providers/favorites_provider.dart';
import 'package:customer_app/core/models/cart_item.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'unified_service_card.dart';
import '../../services/presentation/service_details_screen.dart';

// --- Shared Section Widget Builder ---

typedef StreamBuilderFunction = Stream<List<HomeService>> Function(FirestoreService, int);

class _BaseServicesSection extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final List<Color> iconGradient;
  final int limit;
  final bool isGrid;
  final StreamBuilderFunction streamProvider;
  final Set<String>? displayedServiceIds;

  const _BaseServicesSection({
    required this.title,
    required this.titleIcon,
    required this.iconGradient,
    required this.limit,
    this.isGrid = false,
    required this.streamProvider,
    this.displayedServiceIds,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<List<HomeService>>(
      stream: streamProvider(firestoreService, limit),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              isGrid ? _buildGridShimmer() : _buildHorizontalShimmer(),
            ],
          );
        }

        if (snapshot.hasError) {
          return _buildHeaderWithChild(_buildErrorState(snapshot.error.toString()));
        }

        var services = snapshot.data ?? [];
        
        print('\n📊 [STREAM BUILDER] $title received ${services.length} services');
        for (final service in services.take(3)) {
          print('   ${service.title}: price=${service.price}, offer=${service.offerPrice}');
        }
        
        // Filter out already displayed services to prevent duplicates
        if (displayedServiceIds != null) {
          services = services.where((s) => !displayedServiceIds!.contains(s.id)).toList();
        }
        
        if (services.isEmpty) {
          return const SizedBox.shrink(); // Hide entire section if empty
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
            isGrid
                ? _buildGridList(services)
                : _buildHorizontalList(services),
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
            child: Icon(
              titleIcon,
              color: Colors.white,
              size: 16,
            ),
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

  Widget _buildHeaderWithChild(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildHorizontalList(List<HomeService> services) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return UniversalServiceCard(
            key: ValueKey(services[index].id),
            service: services[index],
          );
        },
      ),
    );
  }

  Widget _buildGridList(List<HomeService> services) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return UniversalServiceCard(
            key: ValueKey(services[index].id),
            service: services[index],
            isGrid: true,
          );
        },
      ),
    );
  }

  Widget _buildHorizontalShimmer() {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.white,
            child: Container(
              width: 180,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              'Unable to load',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, color: Colors.grey[300], size: 48),
            const SizedBox(height: 8),
            Text(
              msg,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Specific Sections ---

class AllServicesSection extends StatelessWidget {
  final Set<String>? displayedServiceIds;
  
  const AllServicesSection({super.key, this.displayedServiceIds});

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'All Services',
      titleIcon: Icons.grid_view_rounded,
      iconGradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      limit: 50,
      isGrid: true,
      displayedServiceIds: displayedServiceIds,
      streamProvider: (fs, limit) => fs.streamAllTechnicianServices(limit: limit),
    );
  }
}

class TopRatedRealServicesSection extends StatelessWidget {
  final Set<String>? displayedServiceIds;
  
  const TopRatedRealServicesSection({super.key, this.displayedServiceIds});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    return StreamBuilder<List<HomeService>>(
      stream: firestoreService.streamTopRatedTechnicianServices(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Top Rated Services',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.45), // Show 2.2 cards
                  physics: const BouncingScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.white,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        if (snapshot.hasError) return const SizedBox.shrink();
        var services = snapshot.data ?? [];
        
        // Filter out already displayed services
        if (displayedServiceIds != null) {
          services = services.where((s) => !displayedServiceIds!.contains(s.id)).toList();
        }
        
        if (services.isEmpty) return const SizedBox.shrink();
        
        // Track displayed services
        if (displayedServiceIds != null) {
          for (final service in services) {
            displayedServiceIds!.add(service.id);
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Top Rated Services',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.45), // Show 2.2 cards
                physics: const BouncingScrollPhysics(),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: UniversalServiceCard(
                      key: ValueKey(services[index].id),
                      service: services[index],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class RecentlyAddedServicesSection extends StatelessWidget {
  final Set<String>? displayedServiceIds;
  
  const RecentlyAddedServicesSection({super.key, this.displayedServiceIds});

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'Recently Added Services',
      titleIcon: Icons.new_releases_rounded,
      iconGradient: const [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      limit: 10,
      isGrid: true,
      displayedServiceIds: displayedServiceIds,
      streamProvider: (fs, limit) => fs.streamRecentTechnicianServices(limit: limit),
    );
  }
}

class RecommendedServicesSection extends StatelessWidget {
  final Set<String>? displayedServiceIds;
  
  const RecommendedServicesSection({super.key, this.displayedServiceIds});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();
    return _BaseServicesSection(
      title: 'Recommended For You',
      titleIcon: Icons.auto_awesome_rounded,
      iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
      limit: 10,
      isGrid: false,
      displayedServiceIds: displayedServiceIds,
      streamProvider: (fs, limit) => fs.streamRecommendedServices(userId, limit: limit),
    );
  }
}
