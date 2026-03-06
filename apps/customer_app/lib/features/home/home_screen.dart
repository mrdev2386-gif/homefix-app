import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/models/address.dart';
import '../../core/models/booking.dart';
import '../../core/providers/location_provider.dart';
import '../../core/services/notifications_service.dart';
import '../notifications/presentation/notification_screen.dart';
import '../services/presentation/service_list_screen.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../support/presentation/support_screen.dart';
import '../profile/presentation/saved_addresses_screen.dart';
import '../custom_request/presentation/custom_request_form_screen.dart';
import '../dashboard/widgets/real_services_sections.dart';
import '../cart/presentation/cart_screen.dart';
import '../../core/providers/cart_provider.dart';
import '../urgent/urgent_booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  Stream<List<Booking>>? _bookingsStream;

  bool _isNavigatingToCustomRequest = false;
  DateTime? _lastCustomRequestNavigationTime;
  final _customRequestDebounceDuration = const Duration(milliseconds: 500);
  
  // Banner state
  final CategoryService _categoryService = CategoryService();
  final PageController _bannerPageController = PageController(viewportFraction: 0.92);
  int _currentBannerIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser != null) {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      _bookingsStream =
          firestore.streamBookings(auth.currentUser!.uid, limit: 1);

      // Initialize location provider with user ID to load district
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final locationProvider =
            Provider.of<LocationProvider>(context, listen: false);
        locationProvider.initialize(auth.currentUser!.uid);
      });
    }
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Precache local banner asset
    try {
      precacheImage(
        const AssetImage('assets/images/ac_repair.png'),
        context,
      );
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Section
            SliverToBoxAdapter(child: _buildHeader(context)),
            
            // Search Bar
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            
            // Promotional Banners with real data
            SliverToBoxAdapter(child: _buildPromotionalBanners()),
            
            // Quick Requests Section
            SliverToBoxAdapter(child: _buildQuickRequests()),
            
            // Popular Services
            SliverToBoxAdapter(child: _buildPopularServices()),
            
            // Recommended Technicians
            SliverToBoxAdapter(child: _buildRecommendedSection()),
            
            // Top Rated
            SliverToBoxAdapter(child: _buildTopRatedSection()),
            
            // Need Assistance
            SliverToBoxAdapter(child: _buildNeedAssistance(context)),
            
            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          // Left side: Location icon + Address
          Expanded(
            child: GestureDetector(
              onTap: () => _showLocationBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Consumer<AuthService>(
                        builder: (context, auth, _) {
                          if (auth.currentUser == null) {
                            return Text(
                              '📍 Select Location',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          
                          final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                          return StreamBuilder<Address?>(
                            stream: firestoreService.streamPrimaryAddress(auth.currentUser!.uid),
                            builder: (context, snapshot) {
                              String displayText = '📍 Select Location';
                              if (snapshot.hasData && snapshot.data != null) {
                                final address = snapshot.data!;
                                // Show short address: Area/City • District
                                final area = address.landmark.isNotEmpty ? address.landmark : address.city;
                                if (area.isNotEmpty && address.district.isNotEmpty) {
                                  displayText = '📍 $area • ${address.district}';
                                } else if (address.district.isNotEmpty) {
                                  displayText = '📍 ${address.district}';
                                } else if (area.isNotEmpty) {
                                  displayText = '📍 $area';
                                }
                              }
                              return Text(
                                displayText,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right side: Notification + Cart
          Row(
            children: [
              // Notification icon with rounded background
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildNotificationIcon(context),
              ),
              const SizedBox(width: 8),
              // Cart icon with rounded container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildCartIcon(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          iconSize: 24,
          color: AppTheme.textColor,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
        ),
        Consumer<AuthService>(
          builder: (context, auth, _) {
            if (auth.currentUser == null) return const SizedBox.shrink();
            return StreamBuilder<int>(
              stream: NotificationsService.streamUnreadCount(auth.currentUser!.uid),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCartIcon(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final itemCount = cart.itemCount;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              iconSize: 24,
              color: AppTheme.textColor,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
            ),
            if (itemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceListScreen())),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            // Cream background as per reference
            color: const Color(0xFFF5F1E8),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600], size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search here for services',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Circular search button on right
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionalBanners() {
    final banners = [
      {'title': 'AC Repair', 'image': 'assets/banners/ac_banner.png', 'categoryId': 'ac_repair'},
      {'title': 'Deep Cleaning', 'image': 'assets/banners/cleaning_banner.png', 'categoryId': 'cleaning'},
      {'title': 'Electrician', 'image': 'assets/banners/electrician_banner.png', 'categoryId': 'electrician'},
    ];
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _bannerPageController,
              onPageChanged: (index) => setState(() => _currentBannerIndex = index),
              padEnds: false,
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];
                return Padding(
                  padding: EdgeInsets.only(right: 12, left: index == 0 ? 16 : 0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceListScreen(category: banner['categoryId']!),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            banner['image']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.image_not_supported)),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    banner['title']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
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
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentBannerIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentBannerIndex == index ? AppTheme.primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuickRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Requests',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UrgentBookingScreen()),
                  ),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on, color: Colors.orange, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Urgent Booking',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CustomRequestFormScreen()),
                  ),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_note, color: Colors.blue, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Custom Booking',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPopularServices() {
    final categoryService = CategoryService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Services',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceListScreen())),
                child: Text(
                  'View All',
                  style: GoogleFonts.outfit(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<List<Category>>(
          stream: categoryService.getCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final categories = snapshot.data!.take(8).toList();
            
            // Horizontal scrolling list with 3.5 cards visible
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < categories.length - 1 ? 12 : 0,
                    ),
                    child: _buildServiceCard(category),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(Category category) {
    final categoryIcons = _getCategoryIconData(category.name);
    final color = categoryIcons['color'] as Color;
    final icon = categoryIcons['icon'] as IconData;
    
    final cardWidth = MediaQuery.of(context).size.width * 0.25;
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceListScreen(category: category.name))),
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Realistic gradient icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommendation',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.outfit(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const RecommendedServicesSection(),
      ],
    );
  }

  Widget _buildTopRatedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          child: Text(
            'Top Rated',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
        ),
        const TopRatedRealServicesSection(),
      ],
    );
  }

  Widget _buildNeedAssistance(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Assistance?',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Our support team is ready to help.',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    'Contact Support',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.headset_mic_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategoryIconData(String name) {
    final nameLower = name.toLowerCase();
    
    if (nameLower.contains('clean')) {
      return {'icon': Icons.cleaning_services_rounded, 'color': const Color(0xFF10B981)};
    }
    if (nameLower.contains('ac') || nameLower.contains('air')) {
      return {'icon': Icons.ac_unit_rounded, 'color': const Color(0xFF06B6D4)};
    }
    if (nameLower.contains('plumb')) {
      return {'icon': Icons.plumbing_rounded, 'color': const Color(0xFF3B82F6)};
    }
    if (nameLower.contains('electric')) {
      return {'icon': Icons.electrical_services_rounded, 'color': const Color(0xFFF59E0B)};
    }
    if (nameLower.contains('paint')) {
      return {'icon': Icons.format_paint_rounded, 'color': const Color(0xFFEC4899)};
    }
    if (nameLower.contains('carpenter')) {
      return {'icon': Icons.carpenter_rounded, 'color': const Color(0xFF8B5CF6)};
    }
    if (nameLower.contains('appliance')) {
      return {'icon': Icons.kitchen_rounded, 'color': const Color(0xFFEF4444)};
    }
    if (nameLower.contains('pest')) {
      return {'icon': Icons.pest_control_rounded, 'color': const Color(0xFF6366F1)};
    }
    if (nameLower.contains('salon') || nameLower.contains('spa')) {
      return {'icon': Icons.spa_rounded, 'color': const Color(0xFFF472B6)};
    }
    if (nameLower.contains('cook') || nameLower.contains('chef')) {
      return {'icon': Icons.restaurant_rounded, 'color': const Color(0xFFFB923C)};
    }
    if (nameLower.contains('laundry')) {
      return {'icon': Icons.local_laundry_service_rounded, 'color': const Color(0xFF14B8A6)};
    }
    if (nameLower.contains('garden') || nameLower.contains('landscap')) {
      return {'icon': Icons.nature_rounded, 'color': const Color(0xFF22C55E)};
    }
    if (nameLower.contains('security')) {
      return {'icon': Icons.security_rounded, 'color': const Color(0xFF1E40AF)};
    }
    if (nameLower.contains('solar')) {
      return {'icon': Icons.wb_sunny_rounded, 'color': const Color(0xFFFCD34D)};
    }
    if (nameLower.contains('water') || nameLower.contains('ro')) {
      return {'icon': Icons.water_drop_rounded, 'color': const Color(0xFF0EA5E9)};
    }
    if (nameLower.contains('interior')) {
      return {'icon': Icons.home_rounded, 'color': const Color(0xFFD946EF)};
    }
    if (nameLower.contains('repair')) {
      return {'icon': Icons.build_rounded, 'color': const Color(0xFF64748B)};
    }
    if (nameLower.contains('mover') || nameLower.contains('packer')) {
      return {'icon': Icons.local_shipping_rounded, 'color': const Color(0xFF7C3AED)};
    }
    if (nameLower.contains('photo')) {
      return {'icon': Icons.camera_alt_rounded, 'color': const Color(0xFFEC4899)};
    }
    if (nameLower.contains('event')) {
      return {'icon': Icons.celebration_rounded, 'color': const Color(0xFFF97316)};
    }
    if (nameLower.contains('massage')) {
      return {'icon': Icons.self_improvement_rounded, 'color': const Color(0xFFA78BFA)};
    }
    if (nameLower.contains('makeup')) {
      return {'icon': Icons.face_rounded, 'color': const Color(0xFFFCA5A5)};
    }
    if (nameLower.contains('mehendi')) {
      return {'icon': Icons.brush_rounded, 'color': const Color(0xFFE879F9)};
    }
    if (nameLower.contains('driver')) {
      return {'icon': Icons.directions_car_rounded, 'color': const Color(0xFF0284C7)};
    }
    if (nameLower.contains('computer') || nameLower.contains('tech')) {
      return {'icon': Icons.computer_rounded, 'color': const Color(0xFF6366F1)};
    }
    if (nameLower.contains('glass')) {
      return {'icon': Icons.window_rounded, 'color': const Color(0xFFBAE6FD)};
    }
    if (nameLower.contains('tank') || nameLower.contains('cleaning')) {
      return {'icon': Icons.water_rounded, 'color': const Color(0xFF06B6D4)};
    }
    if (nameLower.contains('smart')) {
      return {'icon': Icons.home_rounded, 'color': const Color(0xFF8B5CF6)};
    }
    if (nameLower.contains('renovation')) {
      return {'icon': Icons.construction_rounded, 'color': const Color(0xFFB45309)};
    }
    
    return {'icon': Icons.home_rounded, 'color': const Color(0xFF6366F1)};
  }

  void _showLocationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Delivery Location',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.home_work_outlined),
                title: const Text('Saved Addresses'),
                subtitle: const Text('Select from frequently used locations'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _handleSavedAddresses(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSavedAddresses(BuildContext context) async {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
    );
  }



  Future<void> _navigateToCustomRequest() async {
    final now = DateTime.now();

    if (_isNavigatingToCustomRequest) return;

    if (_lastCustomRequestNavigationTime != null &&
        now.difference(_lastCustomRequestNavigationTime!) <
            _customRequestDebounceDuration) {
      return;
    }

    if (!mounted) return;

    _isNavigatingToCustomRequest = true;
    _lastCustomRequestNavigationTime = now;

    try {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => CustomRequestFormScreen()));
    } catch (e) {
      debugPrint('Navigation error: $e');
    } finally {
      _isNavigatingToCustomRequest = false;
    }
  }
}
