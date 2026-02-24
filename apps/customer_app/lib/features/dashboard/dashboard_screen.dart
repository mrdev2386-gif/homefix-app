import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/models/service.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/models/booking.dart';
import '../../core/providers/location_provider.dart';
import '../../core/services/notifications_service.dart';
import '../cart/presentation/cart_screen.dart';
import '../notifications/presentation/notification_screen.dart';
import '../services/presentation/service_list_screen.dart';
import 'widgets/premium_search_bar.dart';
import 'widgets/real_services_sections.dart';
import 'widgets/upcoming_booking_widget.dart';
import '../../core/models/dashboard_models.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../services/presentation/service_details_screen.dart';
import '../support/presentation/support_screen.dart';
import '../profile/presentation/saved_addresses_screen.dart';
import '../profile/presentation/add_edit_address_screen.dart';
import '../custom_request/presentation/custom_request_screen.dart';
import '../services/presentation/instant_booking_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
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
      _bookingsStream = firestore.streamBookings(auth.currentUser!.uid, limit: 1);
       
      // Initialize location provider with user ID to load district
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        locationProvider.initialize(auth.currentUser!.uid);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Preload top banner image to remove first-frame lag
    try {
      precacheImage(
        const NetworkImage(
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&q=80',
        ),
        context,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _buildQuickActions(context),
                  
                  // SECTION 0: Available Quick Search
                  PremiumSearchBar(
                    hintText: 'Search for home services...',
                    onChanged: (query) {
                      if (query.isNotEmpty && query.length > 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceListScreen(initialSearchQuery: query),
                          ),
                        );
                      }
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ServiceListScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // SECTION: Upcoming Booking
                  _buildUpcomingBooking(context),
                  
                  // SECTION 1: All Services (Primary discovery)
                  const AllServicesSection(),
                  const SizedBox(height: 32),
                  
                  // SECTION 2: Top Rated Services
                  const TopRatedRealServicesSection(),
                  const SizedBox(height: 32),

                  // SECTION 3: Recently Added Services
                  const RecentlyAddedServicesSection(),
                  const SizedBox(height: 32),
                  
                  // SECTION 4: Recommended For You (AI Driven)
                  const RecommendedServicesSection(),
                  const SizedBox(height: 32),

                  // SECTION 5: Support
                  _buildSupportCard(context),
                  const SizedBox(height: 32),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 120,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(color: Colors.white),
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        centerTitle: false,
        title: Material(
          color: Colors.transparent,
          child: Consumer<LocationProvider>(
            builder: (context, location, child) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'YOUR DISTRICT',
                          style: GoogleFonts.outfit(
                            color: AppTheme.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            location.selectedDistrict ?? location.currentAddress, 
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: AppTheme.textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        _buildAppBarAction(
          context,
          icon: Icons.notifications_none_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          badgeCount: Provider.of<AuthService>(context, listen: false).currentUser != null 
            ? NotificationsService.streamUnreadCount(Provider.of<AuthService>(context, listen: false).currentUser!.uid)
            : null,
        ),
        const SizedBox(width: 8),
        _buildAppBarAction(
          context,
          icon: Icons.shopping_bag_outlined,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          badgeValue: Provider.of<CartProvider>(context).itemCount,
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildAppBarAction(BuildContext context, {required IconData icon, required VoidCallback onTap, Stream<int>? badgeCount, int? badgeValue}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(icon, color: AppTheme.textColor, size: 22),
            onPressed: onTap,
          ),
        ),
        if (badgeValue != null && badgeValue > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
              child: Text(
                '$badgeValue',
                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (badgeCount != null)
          StreamBuilder<int>(
            stream: badgeCount,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                  child: Text(
                    '$count',
                    style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSearchTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
            ),
          ),
          if (onSearchTap != null)
            GestureDetector(
              onTap: onSearchTap,
              child: Text(
                'View All',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLocationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Where should we serve you?',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 24),

            _buildLocationOption(
              context,
              icon: Icons.map_outlined,
              title: 'Add New Address',
              subtitle: 'Search for your home or office',
              onTap: () => _handleAddNewAddress(context),
            ),
            const Divider(height: 1, indent: 80),
            _buildLocationOption(
              context,
              icon: Icons.home_work_outlined,
              title: 'Saved Addresses',
              subtitle: 'Select from frequently used locations',
              onTap: () => _handleSavedAddresses(context),
            ),
          ],
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

  Widget _buildLocationOption(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(subtitle, style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: TextField(
        readOnly: true,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceListScreen())),
        decoration: InputDecoration(
          hintText: 'Search for services...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildUpcomingBooking(BuildContext context) {
    if (_bookingsStream == null) return const SizedBox.shrink();

    return StreamBuilder<List<Booking>>(
      stream: _bookingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final booking = bookings.first;
        if (booking.status == 'completed' || booking.status == 'cancelled') return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: UpcomingBookingWidget(
            booking: booking,
            onTap: () {
              // Navigate to booking details
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              'Custom\nRequest',
              Icons.handyman_rounded,
              const Color(0xFFF59E0B),
              _navigateToCustomRequest,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInstantBookingCard(context),
          ),
        ],
      ),
    );
  }

  // Debounced navigation to Custom Request screen - fully async safe
  Future<void> _navigateToCustomRequest() async {
    final now = DateTime.now();
    
    // Early return if already navigating
    if (_isNavigatingToCustomRequest) return;
    
    // Time-based debounce check (500ms)
    if (_lastCustomRequestNavigationTime != null &&
        now.difference(_lastCustomRequestNavigationTime!) < _customRequestDebounceDuration) {
      return;
    }
    
    // Final guard - ensure widget is still mounted before setting flag and navigating
    if (!mounted) return;
    
    _isNavigatingToCustomRequest = true;
    _lastCustomRequestNavigationTime = now;
    
    try {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomRequestScreen()));
    } catch (e) {
      // Handle any navigation errors safely
      debugPrint('Navigation error: $e');
    } finally {
      // Reset flag directly - no setState needed (flag doesn't affect UI)
      _isNavigatingToCustomRequest = false;
    }
  }

  Widget _buildInstantBookingCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstantBookingScreen())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              'Instant\nBooking',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Get service within 60 mins',
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              title, 
              style: GoogleFonts.outfit(color: AppTheme.textColor, fontWeight: FontWeight.w800, fontSize: 13, height: 1.2)
            ),
            const SizedBox(height: 4),
            Text(
              'Custom service request',
              style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Assistance?', 
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)
                ),
                const SizedBox(height: 4),
                Text(
                  'Our experts are here 24/7 to solve your problems', 
                  style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13)
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo,
                    minimumSize: const Size(120, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Chat with Us'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.headset_mic_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

}
