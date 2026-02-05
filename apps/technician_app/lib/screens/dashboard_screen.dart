import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../core/providers/technician_provider.dart';
import '../core/firestore/booking_service.dart';
import '../core/models/booking.dart';
import '../core/widgets/safe_network_image.dart';
import '../features/availability/presentation/availability_screen.dart';
import '../features/job_requests/job_requests_screen.dart';
import '../features/earnings/presentation/earnings_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import 'job_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BookingService _bookingService = BookingService();
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const JobRequestsScreen(),
    const EarningsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: const Color(0xFF94A3B8),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.work_outline_rounded), label: 'Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Earnings'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final BookingService _bookingService = BookingService();
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
       if (!mounted) return;
       final provider = Provider.of<TechnicianProvider>(context, listen: false);
       if (provider.technician?.isOnline == true) {
            try {
                final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
                await FirebaseFirestore.instance.collection('technicians').doc(provider.technician!.uid).update({
                   'geo': {'lat': pos.latitude, 'lng': pos.longitude},
                   'lastLocationUpdatedAt': FieldValue.serverTimestamp()
                });
            } catch (e) {
                debugPrint("Location error: $e");
            }
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TechnicianProvider>(context);
    final tech = provider.technician;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(tech, provider),
      body: tech == null 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: () async {
              _startLocationTracking();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildWelcomeHeader(tech)),
                SliverToBoxAdapter(child: _buildStatsGrid(tech)),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader("Active Jobs", Icons.event_available_rounded, const Color(0xFF6366F1)),
                            TextButton(
                              onPressed: () {},
                              child: Text("View All", style: GoogleFonts.outfit(color: const Color(0xFF6366F1))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildActiveSchedule(tech),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  PreferredSizeWidget _buildAppBar(dynamic tech, TechnicianProvider provider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hello, ${tech?.name ?? 'Partner'}", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(tech?.isOnline == true ? "Online" : "Offline", 
                style: GoogleFonts.outfit(fontSize: 12, color: tech?.isOnline == true ? Colors.green : Colors.grey)),
            ],
          ),
        ],
      ),
      actions: [
        Switch(
          value: tech?.isOnline ?? false,
          onChanged: (v) {
               provider.updateOnlineStatus(v);
               if(v) _startLocationTracking();
          },
          activeColor: Colors.green,
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {}, 
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeHeader(dynamic tech) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Overview", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text("You have ${tech.jobsDone} total completed jobs", style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic tech) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(child: _buildStatCard("Today's Jobs", "2", Icons.today_rounded, const Color(0xFF6366F1))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard("Earnings", "₹1,250", Icons.account_balance_wallet_rounded, const Color(0xFF10B981))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildActiveSchedule(dynamic tech) {
    return StreamBuilder<List<Booking>>(
      stream: _bookingService.getAssignedBookings(tech.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ));
        }
        final bookings = snapshot.data ?? [];
        final activeJobs = bookings.where((b) => b.status != 'completed' && b.status != 'cancelled').toList();
        
        if (activeJobs.isEmpty) {
          return _buildEmptyState("No active jobs", "New job requests will appear in the Requests tab.");
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeJobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildActiveJobCard(activeJobs[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_late_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildActiveJobCard(Booking b) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(booking: b))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SafeNetworkImage(
                  imageUrl: b.serviceImage,
                  width: 50,
                  height: 50,
                  borderRadius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.serviceTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(b.customerName, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                _buildStatusPill(b.status),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Expanded(child: Text(b.addressSnapshot['fullAddress'] ?? 'Address not found', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF475569)))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text("${b.scheduledTime} today", style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF475569), fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    "On the Way", 
                    b.status == 'assigned' || b.status == 'accepted', 
                    () => _updateStatus(b.bookingId, 'on_the_way'),
                    const Color(0xFF6366F1)
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionBtn(
                    "Start Work", 
                    b.status == 'on_the_way', 
                    () => _updateStatus(b.bookingId, 'started'),
                    const Color(0xFF10B981)
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionBtn(
                    "Complete", 
                    b.status == 'started', 
                    () => _updateStatus(b.bookingId, 'completed'),
                    const Color(0xFF0F172A)
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, bool enabled, VoidCallback onTap, Color color) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Colors.grey[100],
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: enabled ? Colors.white : Colors.grey[400])),
      ),
    );
  }

  void _updateStatus(String id, String status) {
    _bookingService.updateBookingStatus(id, status).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status updated to ${status.replaceAll('_', ' ')}")));
    });
  }

  Widget _buildStatusPill(String status) {
    Color color = const Color(0xFF6366F1);
    if (status == 'completed') color = const Color(0xFF10B981);
    if (status == 'started') color = const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.toUpperCase().replaceAll('_', ' '), 
        style: GoogleFonts.outfit(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
