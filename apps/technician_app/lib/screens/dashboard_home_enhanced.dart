import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:technician_app/core/models/technician.dart';
import 'package:technician_app/core/providers/technician_provider.dart';
import 'package:technician_app/core/services/booking_service.dart';
import 'package:technician_app/core/services/functions_service.dart';
import 'package:technician_app/core/models/booking.dart';
import 'package:technician_app/features/earnings/presentation/earnings_screen.dart';
import 'package:technician_app/screens/wallet_screen.dart';
import 'package:technician_app/features/profile/presentation/profile_screen.dart';
import 'package:technician_app/features/notifications/presentation/notifications_screen.dart';
import 'package:technician_app/features/technician/services/add_service_screen.dart';

/// Dashboard Home Enhanced - Responsive UI for all device sizes
/// 
/// Features:
/// - LayoutBuilder guards for responsive sizing
/// - Flexible/Expanded widgets to prevent overflow
/// - No hardcoded heights - uses flexible sizing
/// - Overflow ellipsis for long names
/// - Works on <360 width devices
class DashboardHomeEnhanced extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const DashboardHomeEnhanced({super.key, this.onNavigate});

  @override
  State<DashboardHomeEnhanced> createState() => _DashboardHomeEnhancedState();
}

class _DashboardHomeEnhancedState extends State<DashboardHomeEnhanced> with WidgetsBindingObserver {
  final BookingService _bookingService = BookingService();
  final FunctionsService _functionsService = FunctionsService();
  Timer? _offlineTimer;
  bool _isSettingOnline = false;
  DateTime? _lastOnlineCall;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnline();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offlineTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _offlineTimer?.cancel();
      _setOnline();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _startOfflineTimer();
    }
  }

  Future<void> _setOnline() async {
    if (_isSettingOnline) return;
    final now = DateTime.now();
    if (_lastOnlineCall != null && now.difference(_lastOnlineCall!).inSeconds < 10) return;

    _isSettingOnline = true;
    _lastOnlineCall = now;

    try {
      await _functionsService.updateTechnicianOnlineStatus(true);
    } catch (e) {
      debugPrint('Failed to set online: $e');
    } finally {
      _isSettingOnline = false;
    }
  }

  void _startOfflineTimer() {
    _offlineTimer?.cancel();
    _offlineTimer = Timer(const Duration(minutes: 5), () async {
      try {
        await _functionsService.updateTechnicianOnlineStatus(false);
      } catch (e) {
        debugPrint('Failed to set offline: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TechnicianProvider>(context);
    final tech = provider.technician;

    if (tech == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildModernAppBar(tech),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.refreshTechnicianData(),
          color: const Color(0xFF6366F1),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                _buildPremiumHeader(tech),
                const SizedBox(height: 16),
                _buildProfileCompletionCard(tech),
                const SizedBox(height: 16),
                _buildSummaryCardsSection(tech),
                const SizedBox(height: 24),
                _buildQuickActionsSection(),
                const SizedBox(height: 24),
                _buildActiveBookingsSection(tech),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(Technician tech) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${tech.name.split(' ').first} 👋',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Ready for today\'s jobs?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: tech.uid)
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data?.docs.length ?? 0;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Color(0xFF0F172A)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Premium greeting header with gradient
  /// PART 3: LayoutBuilder for responsive padding
  Widget _buildPremiumHeader(Technician tech) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive padding based on screen width
        final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PART 3: Flexible text with ellipsis
                          Flexible(
                            child: Text(
                              'Hello, ${tech.name.split(' ').first} 👋',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tech.isOnline ? 'You are online' : 'You are offline',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tech.isOnline ? Icons.circle : Icons.circle_outlined,
                            size: 10,
                            color: tech.isOnline ? Colors.greenAccent : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tech.isOnline ? 'Online' : 'Offline',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Profile completion card with animated ring
  /// PART 3: LayoutBuilder for responsive sizing
  Widget _buildProfileCompletionCard(Technician tech) {
    final completion = tech.calculateProfileCompletion();
    final clampedCompletion = completion.clamp(0, 100); // PART 5: Ensure value is clamped 0-100
    final isComplete = clampedCompletion >= 100;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // PART 3: Fixed size for circular indicator
                SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: clampedCompletion / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isComplete ? Colors.green : const Color(0xFF6366F1),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$clampedCompletion%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  fit: FlexFit.loose,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PART 3: Flexible text with ellipsis
                      Flexible(
                        child: Text(
                          isComplete ? 'Profile Complete!' : 'Complete Your Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          isComplete 
                              ? 'Your profile is all set up!'
                              : 'Add more details to get more bookings',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isComplete) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => widget.onNavigate?.call(3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Complete Now',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// PART 3: Responsive summary cards - no hardcoded heights
  Widget _buildSummaryCardsSection(Technician tech) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive card width based on screen size
        final cardWidth = constraints.maxWidth < 360 ? 140.0 : 160.0;
        
        return SizedBox(
          // PART 3: Flexible height - allows content to fit
          height: constraints.maxWidth < 360 ? 130 : 140,
          child: StreamBuilder<List<Booking>>(
            stream: _bookingService.getAssignedBookings(tech.uid),
            builder: (context, snapshot) {
              final bookings = snapshot.data ?? [];
              final todayJobs = bookings.where((b) => b.status != 'completed' && b.status != 'cancelled').length;
              final pending = bookings.where((b) => b.status == 'pending').length;

              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSummaryCard(
                    'Today\'s Jobs',
                    '$todayJobs',
                    Icons.work_outline_rounded,
                    const Color(0xFF6366F1),
                    cardWidth: cardWidth,
                  ),
                  _buildEarningsSummaryCard(tech, cardWidth: cardWidth),
                  _buildSummaryCard(
                    'Rating',
                    tech.avgRating.toStringAsFixed(1),
                    Icons.star_rounded,
                    const Color(0xFFFBBF24),
                    cardWidth: cardWidth,
                  ),
                  _buildSummaryCard(
                    'Pending',
                    '$pending',
                    Icons.pending_actions_rounded,
                    const Color(0xFFF59E0B),
                    cardWidth: cardWidth,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color, {double cardWidth = 160}) {
    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            // PART 3: Flexible with ellipsis
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PART 4: Earnings card hardening - null handling, shimmer, fallback
  Widget _buildEarningsSummaryCard(Technician tech, {double cardWidth = 160}) {
    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('technicians')
            .doc(tech.uid)
            .collection('stats')
            .doc('earnings')
            .snapshots(),
        builder: (context, snapshot) {
          // PART 4: Handle loading state with shimmer
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerCard();
          }
          
          // PART 4: Handle errors - show fallback
          if (snapshot.hasError) {
            return _buildFallbackEarningsCard();
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          // PART 4: Null-safe earnings with fallback to 0
          final todayEarnings = _safeDouble(data?['todayEarnings'] ?? data?['today'] ?? 0);
          final monthEarnings = _safeDouble(
            data?['monthEarnings'] ?? 
            data?['thisMonthEarnings'] ?? 
            data?['thisMonth'] ?? 
            data?['month'] ?? 
            0
          );

          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(height: 12),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  // PART 4: Proper currency formatting
                  '₹${_formatCurrency(monthEarnings)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  'This Month',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // PART 4: Proper currency formatting
                      'Today: ₹${_formatCurrency(todayEarnings)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
            ],
          ), // close Column
        ); // close FittedBox
        },
      ),
    );
  }

  /// PART 4: Shimmer loading state
  Widget _buildShimmerCard() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.account_balance_wallet_rounded, color: Colors.grey.shade400, size: 24),
        ),
        const SizedBox(height: 12),
        Container(
          height: 28,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 13,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 20,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
      ),
    );
  }

  /// PART 4: Fallback earnings card when data unavailable
  Widget _buildFallbackEarningsCard() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 24),
        ),
        const SizedBox(height: 12),
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            '₹0',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            'This Month',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Today: ₹0',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  /// PART 4: Safe double conversion with fallback
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// PART 4: Proper currency formatting
  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// PART 3: Responsive quick actions - GridView with flexible sizing
  Widget _buildQuickActionsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              // PART 3: Responsive grid - 2 columns on small screens
              GridView.count(
                crossAxisCount: constraints.maxWidth < 360 ? 2 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // PART 3: Flexible aspect ratio
                childAspectRatio: constraints.maxWidth < 360 ? 2.5 : 2.2,
                children: [
                  _buildQuickActionCard('Add Service', Icons.add_circle_outline, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddServiceScreen()));
                  }),
                  _buildQuickActionCard('View Jobs', Icons.work_outline_rounded, () {
                    widget.onNavigate?.call(1);
                  }),
                  _buildQuickActionCard('Wallet', Icons.account_balance_wallet_outlined, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                  }),
                  _buildQuickActionCard('My Services', Icons.home_repair_service_outlined, () {
                    widget.onNavigate?.call(2);
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              // PART 3: Expanded with ellipsis for long labels
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// PART 3: Responsive active bookings section
  Widget _buildActiveBookingsSection(Technician tech) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Bookings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Booking>>(
                stream: _bookingService.getAssignedBookings(tech.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookings = snapshot.data ?? [];
                  final activeBookings = bookings
                      .where((b) => b.status != 'completed' && b.status != 'cancelled')
                      .toList();

                  if (activeBookings.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeBookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildBookingCard(activeBookings[index]);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // PART 3: Expanded with ellipsis for long service titles
              Expanded(
                child: Text(
                  booking.serviceTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              // PART 3: Expanded with ellipsis for long names
              Expanded(
                child: Text(
                  booking.customerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Time row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    booking.scheduledTime,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              // Location row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      booking.addressSnapshot['city'] ?? 'Address',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF64748B)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFF59E0B);
        break;
      case 'confirmed':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF10B981);
        break;
      case 'in_progress':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF3B82F6);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No jobs yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New job requests will appear here',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
