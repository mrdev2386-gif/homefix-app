import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import 'package:customer_app/core/services/category_service.dart';
import 'package:customer_app/core/models/category.dart';
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
  late final CategoryService _categoryService;
  
  // CRITICAL FIX: Stable stream instance - created once, never recreated
  late final Stream<List<HomeService>> _servicesStream;
  
  // Track location changes to refresh stream
  String? _lastLocationId;
  
  bool _isNavigatingToCustomRequest = false;
  DateTime? _lastCustomRequestNavigationTime;
  final _customRequestDebounceDuration = const Duration(milliseconds: 500);
   
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _categoryService = context.read<CategoryService>();
    final auth = Provider.of<AuthService>(context, listen: false);
    
    // CRITICAL FIX: Initialize stable stream ONCE
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _servicesStream = firestoreService.getCachedServicesStream();
    if (kDebugMode) debugPrint('[STREAM] Dashboard stream created only once');
    
    if (auth.currentUser != null) {
      _bookingsStream = firestoreService.streamBookings(auth.currentUser!.uid, limit: 1);
       
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
    
    // CRITICAL: Refresh stream ONLY when location actually changes
    // Use listen: false to prevent rebuild loop
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final currentLocationId = '${locationProvider.selectedDistrict ?? ''}_${locationProvider.selectedAddress?.id ?? ''}';
      
      if (_lastLocationId != null && _lastLocationId != currentLocationId) {
        if (kDebugMode) debugPrint('[DASHBOARD] Location changed: $_lastLocationId → $currentLocationId, refreshing stream');
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        setState(() {
          _servicesStream = firestoreService.getCachedServicesStream();
        });
      }
      
      _lastLocationId = currentLocationId;
    } catch (e) {
      // LocationProvider might not be available in all contexts
      if (kDebugMode) debugPrint('[DASHBOARD] Could not track location change: $e');
    }
    
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

                  // SECTION: Categories
                  _buildCategoriesSection(),
                  const SizedBox(height: 24),

                  // SECTION: Upcoming Booking
                  _buildUpcomingBooking(context),
                  
                  // SECTION: All Services with Single StreamBuilder
                  StreamBuilder<List<HomeService>>(
                    stream: _servicesStream, // CRITICAL FIX: Use stable stream instance
                    builder: (context, snapshot) {
                      // CRITICAL FIX: Check connection state, not hasData
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        if (kDebugMode) debugPrint('[UI] Stream error: ${snapshot.error}');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Error: ${snapshot.error}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => setState(() {}),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      // CRITICAL FIX: Always get data with fallback to empty list
                      final allServices = snapshot.data ?? [];
                      
                      if (kDebugMode) debugPrint('[UI] Services count: ${allServices.length}');
                      
                      // Handle empty state
                      if (allServices.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No services available',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        );
                      }
                      
                      // Build UI with services
                      return Column(
                        children: [
                          // SECTION 1: All Services (Primary discovery)
                          AllServicesSection(data: allServices),
                          const SizedBox(height: 32),
                          
                          // SECTION 2: Top Rated Services
                          TopRatedRealServicesSection(data: allServices),
                          const SizedBox(height: 32),

                          // SECTION 3: Recently Added Services
                          RecentlyAddedServicesSection(data: allServices),
                          const SizedBox(height: 32),
                          
                          // SECTION 4: Recommended For You (AI Driven)
                          RecommendedServicesSection(data: allServices),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                  ),

                  // SECTION 5: Support
                  _buildOffersBanner(),
                  const SizedBox(height: 20),
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
      expandedHeight: 160,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Welcome to HomeFix',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildNotificationButton(context),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLocationRow(context),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        _buildCartButton(context),
        const SizedBox(width: 16),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildLocationRow(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, location, child) {
        return GestureDetector(
          onTap: () => _showLocationBottomSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    location.selectedDistrict ?? location.currentAddress ?? 'Select Location',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: AppTheme.subtitleColor, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textColor, size: 22),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
        ),
        if (Provider.of<AuthService>(context, listen: false).currentUser != null)
          StreamBuilder<int>(
            stream: NotificationsService.streamUnreadCount(Provider.of<AuthService>(context, listen: false).currentUser!.uid),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                  child: Text('$count', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCartButton(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.textColor, size: 22),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ),
        if (Provider.of<CartProvider>(context).itemCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
              child: Text('${Provider.of<CartProvider>(context).itemCount}', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
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

  // ========== QUICK ACTION BANNER ==========
  Widget _buildQuickActionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.home_repair_service,
              size: 120,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Book Trusted Home Services Instantly',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Explore Services',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
      padding: const EdgeInsets.all(20),
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

  // ========== OFFERS / PROMOTIONS BANNER ==========
  Widget _buildOffersBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8F5E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -10,
            child: Icon(
              Icons.local_offer,
              size: 100,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Limited Time',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF6B35),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Get 20% Off on First Booking',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return StreamBuilder<List<Category>>(
      stream: _categoryService.streamCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final categories = snapshot.data!;
        final limitedCategories = categories.take(10).toList();
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = (screenWidth - 32) / 2.5;
        final midpoint = (limitedCategories.length / 2).ceil();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              SizedBox(
                height: 115,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: midpoint,
                  itemBuilder: (context, index) {
                    return Container(
                      width: cardWidth,
                      margin: const EdgeInsets.only(right: 12),
                      child: _buildGridCategoryCard(limitedCategories[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 115,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: limitedCategories.length - midpoint,
                  itemBuilder: (context, index) {
                    return Container(
                      width: cardWidth,
                      margin: const EdgeInsets.only(right: 12),
                      child: _buildGridCategoryCard(limitedCategories[midpoint + index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridCategoryCard(Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceListScreen(initialSearchQuery: category.name),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 30,
              color: const Color(0xFFFF6B35),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
