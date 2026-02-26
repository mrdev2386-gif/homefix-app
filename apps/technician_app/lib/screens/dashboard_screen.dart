import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:technician_app/core/models/technician.dart';
import 'package:technician_app/core/services/notifications_service.dart';
import 'package:technician_app/features/notifications/presentation/notifications_screen.dart';

import 'package:technician_app/core/providers/technician_provider.dart';
import 'package:technician_app/core/services/booking_service.dart';
import 'package:technician_app/core/services/technician_catalog_service.dart';
import 'package:technician_app/core/models/booking.dart';
import 'package:technician_app/core/widgets/safe_network_image.dart';
import 'package:technician_app/features/job_requests/job_requests_screen.dart';
import 'package:technician_app/features/technician/services/services_screen.dart';
import 'package:technician_app/features/profile/presentation/profile_screen.dart';
import 'package:technician_app/features/services/presentation/create_service_screen.dart';
import 'package:technician_app/screens/limited_dashboard.dart';
import 'package:technician_app/screens/dashboard_home_enhanced.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHomeEnhanced(),
    const JobRequestsScreen(),
    const ServicesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: SafeArea(
          child: SizedBox(
            height: kBottomNavigationBarHeight,
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (!mounted) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _selectedIndex = index);
                  }
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              iconSize: 22,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline),
                  label: 'Jobs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.handyman_outlined),
                  label: 'Services',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
          ),
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

  @override
  void initState() {
    super.initState();
    debugPrint('[DashboardHome] initState called');
    _enforceOnboardingGate();
  }

  void _enforceOnboardingGate() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      debugPrint('[FINAL HARDEN] Dashboard gate check starting');
      final provider = context.read<TechnicianProvider>();
      
      if (provider.isLoading) {
        debugPrint('[FINAL HARDEN] Waiting for provider...');
        return;
      }
      
      final freshTech = await provider.fetchFreshTechnicianData();
      
      if (freshTech == null) {
        debugPrint('[FINAL HARDEN] Technician null — skip redirect');
        return;
      }
      
      debugPrint('[FINAL HARDEN] Dashboard using model value: ${freshTech.isKycComplete}');
      
      // ONLY redirect if CONFIRMED false (not null, not missing)
      if (freshTech.isKycComplete == false) {
        debugPrint('[FINAL HARDEN ❌] Redirecting to onboarding');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
        return;
      }
      
      debugPrint('[FINAL VERIFY ✅] KYC complete, staying on dashboard');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Background location tracking removed to minimize dependencies
  void _updateSelfLocation() {
    debugPrint('Manual location update requested (GPS-less mode)');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TechnicianProvider>(context);
    debugPrint('[DashboardHome] Building, tech=${provider.technician?.uid}');
    final tech = provider.technician;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: tech != null ? _buildAppBar(tech, provider) : null,
      body: tech == null 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: () async {
              _updateSelfLocation();
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

  PreferredSizeWidget _buildAppBar(Technician tech, TechnicianProvider provider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE2E8F0),
              backgroundImage: tech.photoUrl != null ? NetworkImage(tech.photoUrl!) : null,
              child: tech.photoUrl == null ? const Icon(Icons.person, size: 20, color: Color(0xFF64748B)) : null,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, ${tech.name.split(' ')[0]}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tech.isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tech.isOnline ? "Online" : "Offline",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Color(tech.isOnline ? 0xFFDCFCE7 : 0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(
                tech.isOnline ? "ONLINE" : "OFFLINE",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(tech.isOnline ? 0xFF15803D : 0xFF475569),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 24,
                width: 36,
                child: Switch(
                  value: tech.isOnline,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF10B981),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFF94A3B8),
                  onChanged: (v) async {
                    try {
                      if (v) {
                        // Check if technician has at least one service before going online
                        final serviceService = TechnicianCatalogService();
                        final hasServices = await serviceService.hasActiveServices();
                        
                        if (!hasServices) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('You need to create a service before going online'),
                                action: SnackBarAction(
                                  label: 'Create Service',
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const CreateServiceScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }
                          return;
                        }
                      }
                      await provider.updateOnlineStatus(v);
                      if (v) _updateSelfLocation();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update status: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        _buildNotificationIcon(provider.technician?.uid),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildNotificationIcon(String? userId) {
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: NotificationsService.streamUnreadCount(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeHeader(Technician tech) {
    final now = DateTime.now();
    final dayStr = DateFormat('MMM dd').format(now);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Overview",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "Your performance for today",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF6366F1)),
                    const SizedBox(width: 6),
                    Text(
                      dayStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Technician tech) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Jobs Done",
              "${tech.jobsDone}",
              Icons.check_circle_rounded,
              const Color(0xFF6366F1),
              "Total completed",
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              "Rating",
              tech.avgRating > 0 ? tech.avgRating.toStringAsFixed(1) : "N/A",
              Icons.star_rounded,
              const Color(0xFFF59E0B),
              "${tech.totalRatings} reviews",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
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

  Widget _buildActiveSchedule(Technician tech) {
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SafeNetworkImage(
                imageUrl: b.serviceImage,
                width: 56,
                height: 56,
                borderRadius: 16,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.serviceTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.customerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusPill(b.status),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  b.addressSnapshot['fullAddress'] ?? 'Address',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time_filled_rounded, size: 18, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 12),
              Text(
                "${b.scheduledTime} today",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  "On Way",
                  b.status == 'confirmed',
                  () => _updateStatus(b.bookingId, 'on_the_way'),
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBtn(
                  "Start",
                  b.status == 'on_the_way',
                  () => _updateStatus(b.bookingId, 'in_progress'),
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBtn(
                  "Done",
                  b.status == 'in_progress' || b.status == 'started',
                  () => _updateStatus(b.bookingId, 'completed'),
                  const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, bool enabled, VoidCallback onTap, Color color) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFF1F5F9),
        disabledForegroundColor: const Color(0xFF94A3B8),
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        padding: EdgeInsets.zero,
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Text(label),
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
