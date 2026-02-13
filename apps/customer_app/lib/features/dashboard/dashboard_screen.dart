import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/models/booking.dart';
import '../../core/providers/location_provider.dart';
import '../../core/services/notifications_service.dart';
import '../cart/presentation/cart_screen.dart';
import '../notifications/presentation/notification_screen.dart';
import '../profile/presentation/saved_addresses_screen.dart';
import '../profile/presentation/add_edit_address_screen.dart';
import '../services/presentation/service_request_screen.dart';
import '../services/presentation/instant_booking_screen.dart';
import '../services/presentation/service_list_screen.dart';
import '../support/presentation/support_screen.dart';
import 'widgets/home_banner_carousel.dart';
import 'widgets/service_section.dart';
import 'widgets/upcoming_booking_widget.dart';
import 'widgets/category_grid.dart';
import 'widgets/service_spotlight_section.dart';
import 'widgets/professional_home_service.dart';
import 'widgets/professional_reels_section.dart';
import 'widgets/cleaning_essentials_section.dart';
import 'widgets/service_bottom_banners_section.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  Stream<List<ProfessionalReel>>? _reelsStream;
  Stream<List<CleaningEssential>>? _essentialsStream;
  Stream<List<ServiceBanner>>? _bannersStream;
  Stream<List<Booking>>? _bookingsStream;
  Stream<List<HomeService>>? _servicesStream;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    _reelsStream = firestore.streamProfessionalReels();
    _essentialsStream = firestore.streamCleaningEssentials();
    _bannersStream = firestore.streamServiceBottomBanners();
    _servicesStream = firestore.streamServices();

    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser != null) {
      _bookingsStream = firestore.streamBookings(auth.currentUser!.uid, limit: 1);
      
      // Initialize location provider with user ID
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
    precacheImage(
      const NetworkImage(
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&q=80',
      ),
      context,
    );
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
                  // Custom Request & Verified Technician (TOP)
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  
                  // What are you looking for?
                  _buildSectionHeader('What are you looking for?', null),
                  const CategoryGrid(),
                  const SizedBox(height: 24),
                  
                  // Professional Home Service (NEW 2x2 layout)
                  _buildProfessionalHomeService(context),
                  const SizedBox(height: 24),
                  
                  // Cleaning Essentials
                  _buildCleaningEssentials(context),
                  const SizedBox(height: 24),
                  
                  // Recommended for You
                  const ServiceListSection(title: 'Recommended For You', category: 'cleaning', isHorizontal: true),
                  const SizedBox(height: 24),
                  
                  // Need Assistance
                  _buildSupportCard(context),
                  const SizedBox(height: 24),
                  
                  // Celebration Professional (moved to bottom)
                  _buildProfessionalReels(context),
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
              return InkWell(
                onTap: () => _showLocationBottomSheet(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
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
                            'DELIVERING TO',
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
                              location.currentAddress, 
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: AppTheme.textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor, size: 18),
                        ],
                      ),
                    ],
                  ),
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
              icon: Icons.my_location_rounded,
              title: 'Current Location',
              subtitle: 'Precision location via GPS',
              onTap: () => _handleCurrentLocation(context),
            ),
            const Divider(height: 1, indent: 80),
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

  Future<void> _handleCurrentLocation(BuildContext context) async {
    if (!mounted) return;

    // First pop the bottom sheet
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    try {
      // Fetch location and save to Firestore
      final success = await locationProvider.updateCurrentLocation(saveToFirestore: true);

      // Always close loader safely
      if (!mounted) return;
      final nav = Navigator.maybeOf(context);
      if (nav != null && nav.canPop()) {
        nav.pop();
      }

      if (!mounted) return;

      if (success) {
        // Success popup
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location saved successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Error popup based on address state
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locationProvider.currentAddress == 'Location Denied'
                  ? 'Location permission denied. Please enable in settings.'
                  : 'Unable to get current location. Please try again.',
            ),
            action: locationProvider.currentAddress == 'Location Denied'
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: () => locationProvider.openAppSettings(),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      // Always close loader on error
      if (!mounted) return;
      final nav = Navigator.maybeOf(context);
      if (nav != null && nav.canPop()) {
        nav.pop();
      }

      if (!mounted) return;

      // Error popup
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch location'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              Icons.bolt_rounded,
              const Color(0xFFF59E0B),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceRequestScreen())),
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
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              title, 
              style: GoogleFonts.outfit(color: AppTheme.textColor, fontWeight: FontWeight.w800, fontSize: 13, height: 1.2)
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

  Widget _buildProfessionalHomeService(BuildContext context) {
    return StreamBuilder<List<HomeService>>(
      stream: _servicesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(),
          ));
        }
        
        final services = snapshot.data ?? [];
        if (services.isEmpty) {
          return const SizedBox.shrink();
        }
        return ProfessionalHomeServiceSection(services: services.take(6).toList());
      },
    );
  }

  Widget _buildProfessionalReels(BuildContext context) {
    return StreamBuilder<List<ProfessionalReel>>(
      stream: _reelsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(),
          ));
        }
        
        final reels = snapshot.data ?? [];
        if (reels.isEmpty) {
          return const SizedBox.shrink();
        }
        return ProfessionalReelsSection(reels: reels);
      },
    );
  }

  Widget _buildCleaningEssentials(BuildContext context) {
    return StreamBuilder<List<CleaningEssential>>(
      stream: _essentialsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(),
          ));
        }

        final essentials = snapshot.data ?? [];
        if (essentials.isEmpty) {
          return const SizedBox.shrink();
        }
        return CleaningEssentialsSection(essentials: essentials);
      },
    );
  }

  Widget _buildServiceBottomBanners(BuildContext context) {
    return StreamBuilder<List<ServiceBanner>>(
      stream: _bannersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        }

        final banners = snapshot.data ?? [];
        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }
        return ServiceBottomBannersSection(banners: banners);
      },
    );
  }
}
