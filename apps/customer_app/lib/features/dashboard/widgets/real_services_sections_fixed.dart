import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/services/firestore_service.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../services/presentation/service_details_screen.dart';

typedef StreamBuilderFunction = Stream<List<HomeService>> Function(FirestoreService, int);

class _BaseServicesSection extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final List<Color> iconGradient;
  final int limit;
  final bool isGrid;
  final StreamBuilderFunction streamProvider;

  const _BaseServicesSection({
    required this.title,
    required this.titleIcon,
    required this.iconGradient,
    required this.limit,
    this.isGrid = false,
    required this.streamProvider,
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

        final services = snapshot.data ?? [];
        if (services.isEmpty) {
          return const SizedBox.shrink();
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
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return _PremiumServiceCard(service: services[index]);
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
          return _PremiumServiceCard(service: services[index], isGrid: true);
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

class AllServicesSection extends StatelessWidget {
  const AllServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'All Services',
      titleIcon: Icons.grid_view_rounded,
      iconGradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      limit: 50,
      isGrid: true,
      streamProvider: (fs, limit) => fs.streamAllTechnicianServices(limit: limit),
    );
  }
}

class TopRatedRealServicesSection extends StatelessWidget {
  const TopRatedRealServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'Top Rated Services',
      titleIcon: Icons.star_rounded,
      iconGradient: const [Color(0xFFFF9800), Color(0xFFFF5722)],
      limit: 10,
      streamProvider: (fs, limit) => fs.streamTopRatedTechnicianServices(limit: limit),
    );
  }
}

class RecentlyAddedServicesSection extends StatelessWidget {
  const RecentlyAddedServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseServicesSection(
      title: 'Recently Added Services',
      titleIcon: Icons.new_releases_rounded,
      iconGradient: const [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      limit: 10,
      streamProvider: (fs, limit) => fs.streamRecentTechnicianServices(limit: limit),
    );
  }
}

class RecommendedServicesSection extends StatelessWidget {
  const RecommendedServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.uid;

    if (userId == null) return const SizedBox.shrink();

    return _BaseServicesSection(
      title: 'Recommended For You',
      titleIcon: Icons.auto_awesome_rounded,
      iconGradient: const [Color(0xFF9C27B0), Color(0xFFE91E63)],
      limit: 10,
      streamProvider: (fs, limit) => fs.streamRecommendedServices(userId, limit: limit),
    );
  }
}

class _PremiumServiceCard extends StatefulWidget {
  final HomeService service;
  final bool isGrid;

  const _PremiumServiceCard({required this.service, this.isGrid = false});

  @override
  State<_PremiumServiceCard> createState() => _PremiumServiceCardState();
}

class _PremiumServiceCardState extends State<_PremiumServiceCard> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return GestureDetector(
      onTap: () async {
        if (_isNavigating) return;
        _isNavigating = true;
        HapticFeedback.lightImpact();

        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailsScreen(
                serviceId: service.id,
                categoryId: service.category,
                serviceName: service.title,
                serviceData: service,
              ),
            ),
          );
        } finally {
          if (mounted) _isNavigating = false;
        }
      },
      child: Container(
        width: widget.isGrid ? null : 180,
        margin: widget.isGrid ? EdgeInsets.zero : const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: widget.isGrid ? 1.2 : 1.3,
                    child: SafeNetworkImage(
                      imageUrl: service.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                        const SizedBox(width: 2),
                        Text(
                          service.rating > 0 ? service.rating.toStringAsFixed(1) : 'New',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (service.urgentBookingEnabled)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flash_on, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'Urgent',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (service.originalPrice != null && service.originalPrice! > 0)
                              Text(
                                '₹${service.originalPrice!.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              '₹${(service.offerPrice ?? service.basePrice).toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, size: 12, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            service.technicianName ?? 'Verified Pro',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.subtitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (service.technicianDistrict != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            service.technicianDistrict!.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.blue[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_isNavigating) return;
                          _isNavigating = true;
                          HapticFeedback.lightImpact();
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceDetailsScreen(
                                  serviceId: service.id,
                                  categoryId: service.category,
                                  serviceName: service.title,
                                  serviceData: service,
                                ),
                              ),
                            );
                          } finally {
                            if (mounted) _isNavigating = false;
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Get Service',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
