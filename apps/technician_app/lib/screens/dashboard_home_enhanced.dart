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
import 'package:technician_app/features/profile/presentation/profile_screen.dart';
import 'package:technician_app/features/notifications/presentation/notifications_screen.dart';

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
      body: RefreshIndicator(
        onRefresh: () => provider.refreshTechnicianData(),
        color: const Color(0xFF6366F1),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
    );
  }

  PreferredSizeWidget _buildModernAppBar(Technician tech) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${tech.name.split(' ')[0]} 👋',
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
              .where('read', isEqualTo: false)
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

  Widget _buildSummaryCardsSection(Technician tech) {
    return SizedBox(
      height: 140,
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
              ),
              _buildEarningsSummaryCard(tech),
              _buildSummaryCard(
                'Rating',
                tech.avgRating.toStringAsFixed(1),
                Icons.star_rounded,
                const Color(0xFFFBBF24),
              ),
              _buildSummaryCard(
                'Pending',
                '$pending',
                Icons.pending_actions_rounded,
                const Color(0xFFF59E0B),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
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
      child: Column(
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
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
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
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSummaryCard(Technician tech) {
    return Container(
      width: 160,
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
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final todayEarnings = data?['todayEarnings'] ?? 0;

          return Column(
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
                child: Text(
                  '₹${todayEarnings.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
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
                  'Earnings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildQuickActionCard('View Jobs', Icons.work_outline_rounded, () {
                widget.onNavigate?.call(1);
              }),
              _buildQuickActionCard('Wallet', Icons.account_balance_wallet_outlined, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
              }),
              _buildQuickActionCard('My Services', Icons.home_repair_service_outlined, () {
                widget.onNavigate?.call(2);
              }),
              _buildQuickActionCard('Profile', Icons.person_outline_rounded, () {
                widget.onNavigate?.call(3);
              }),
            ],
          ),
        ],
      ),
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

  Widget _buildActiveBookingsSection(Technician tech) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
                  Text(
                    booking.addressSnapshot['city'] ?? 'Address',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
