import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/models/category.dart';
import '../../core/models/booking.dart';
import '../../core/providers/location_provider.dart';
import '../../core/services/notifications_service.dart';
import '../notifications/presentation/notification_screen.dart';
import '../services/presentation/service_list_screen.dart';
import '../dashboard/widgets/premium_search_bar.dart';
import '../dashboard/widgets/real_services_sections.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../support/presentation/support_screen.dart';
import '../profile/presentation/saved_addresses_screen.dart';
import '../profile/presentation/add_edit_address_screen.dart';
import '../custom_request/presentation/custom_request_screen.dart';
import '../services/presentation/instant_booking_screen.dart';

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
            
            // Promotional Banners
            SliverToBoxAdapter(child: _buildPromotionalBanners()),
            
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
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showLocationBottomSheet(context),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Consumer<LocationProvider>(
                      builder: (context, location, _) {
                        final address = location.selectedDistrict ?? location.currentAddress ?? 'Select Location';
                        return Text(
                          address,
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {},
              ),
              _buildNotificationIcon(context),
              const SizedBox(width: 8),
              _buildProfileAvatar(context),
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
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen())),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null ? const Icon(Icons.person, size: 20) : null,
          ),
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
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text('Search here for services', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const Spacer(),
              Icon(Icons.tune, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionalBanners() {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(top: 24),
      child: PageView(
        padEnds: false,
        controller: PageController(viewportFraction: 0.9),
        children: [
          _buildBannerCard('Special Offer', '30% OFF', 'Book Now', const Color(0xFF6366F1)),
          _buildBannerCard('AC Repair', 'Starting ₹299', 'Book Now', const Color(0xFFEC4899)),
          _buildBannerCard('Referral & Earn', 'Get ₹100', 'Invite Now', const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildBannerCard(String title, String subtitle, String cta, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 16, left: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(subtitle, style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text(cta, style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Icon(Icons.flash_on_rounded, color: Colors.white.withValues(alpha: 0.3), size: 80),
        ],
      ),
    );
  }

  Widget _buildPopularServices() {
    final categoryService = CategoryService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Popular Services', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceListScreen())),
                child: Text('View All', style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        StreamBuilder<List<Category>>(
          stream: categoryService.getCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final categories = snapshot.data!.take(8).toList();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) => _buildServiceCard(categories[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(Category category) {
    final colors = [const Color(0xFF6366F1), const Color(0xFFEC4899), const Color(0xFF10B981), const Color(0xFFF59E0B)];
    final color = colors[category.name.hashCode % colors.length];
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceListScreen(category: category.name))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(_getCategoryIcon(category.name), color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(category.name, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recommendation', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('View All', style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontSize: 14, fontWeight: FontWeight.w600)),
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text('Top Rated', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const TopRatedRealServicesSection(),
      ],
    );
  }

  Widget _buildNeedAssistance(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need Assistance?', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Our support team is ready to help.', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Contact Support', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }



  IconData _getCategoryIcon(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('clean')) return Icons.cleaning_services_rounded;
    if (nameLower.contains('ac') || nameLower.contains('repair'))
      return Icons.ac_unit_rounded;
    if (nameLower.contains('plumb')) return Icons.plumbing_rounded;
    if (nameLower.contains('electric'))
      return Icons.electrical_services_rounded;
    if (nameLower.contains('paint')) return Icons.format_paint_rounded;
    if (nameLower.contains('carpenter')) return Icons.carpenter_rounded;
    if (nameLower.contains('appliance')) return Icons.kitchen_rounded;
    if (nameLower.contains('pest')) return Icons.pest_control_rounded;
    if (nameLower.contains('salon') || nameLower.contains('spa'))
      return Icons.spa_rounded;
    if (nameLower.contains('home')) return Icons.home_rounded;
    return Icons.home;
  }



  void _showLocationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag indicator
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.15),
                            AppTheme.primaryColor.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.primaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Delivery Location',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose where to deliver',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildLocationOption(
                context,
                icon: Icons.map_outlined,
                title: 'Add New Address',
                subtitle: 'Search for your home or office',
                onTap: () => _handleAddNewAddress(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 76),
                child: Divider(
                  height: 1,
                  color: Colors.grey[200],
                  thickness: 1,
                ),
              ),
              _buildLocationOption(
                context,
                icon: Icons.home_work_outlined,
                title: 'Saved Addresses',
                subtitle: 'Select from frequently used locations',
                onTap: () => _handleSavedAddresses(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddNewAddress(BuildContext context) async {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
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

  Widget _buildLocationOption(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.primaryColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.textColor,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: AppTheme.subtitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ],
        ),
      ),
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
          MaterialPageRoute(builder: (_) => const CustomRequestScreen()));
    } catch (e) {
      debugPrint('Navigation error: $e');
    } finally {
      _isNavigatingToCustomRequest = false;
    }
  }
}
