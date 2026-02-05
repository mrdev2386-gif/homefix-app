import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/booking.dart';
import '../../core/theme/app_theme.dart';
import 'detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text('My Bookings', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
          centerTitle: true,
          bottom: TabBar(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.subtitleColor,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: 'ACTIVE'),
              Tab(text: 'HISTORY'),
            ],
          ),
        ),
        body: user == null 
          ? _buildLoginPrompt(context)
          : TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                _BookingList(userId: user.uid, isActive: true),
                _BookingList(userId: user.uid, isActive: false),
              ],
            ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
            child: const Icon(Icons.lock_person_rounded, size: 64, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text('Login to track bookings', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('You need to be logged in to view your history', style: GoogleFonts.outfit(color: AppTheme.subtitleColor)),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final String userId;
  final bool isActive;

  const _BookingList({required this.userId, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        final bookings = allDocs.map((d) => Booking.fromFirestore(d)).where((b) {
          final isCompleted = ['completed', 'cancelled', 'rejected'].contains(b.status.toLowerCase());
          return isActive ? !isCompleted : isCompleted;
        }).toList();

        if (bookings.isEmpty) {
          return _buildEmpty(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          physics: const BouncingScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _BookingCard(booking: booking);
          },
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
            child: Icon(
              isActive ? Icons.calendar_today_rounded : Icons.history_rounded,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isActive ? 'No active bookings' : 'No past bookings',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            isActive ? 'Services you book will appear here' : 'Completed services will be listed here',
            style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(bookingId: booking.id)));
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(booking.scheduledAt),
                    style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                booking.serviceTitle,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIconInfo(Icons.access_time_filled_rounded, DateFormat.jm().format(booking.scheduledAt)),
                  const SizedBox(width: 20),
                  _buildIconInfo(Icons.payments_rounded, '₹${booking.finalAmount}'),
                ],
              ),
              if (booking.technicianName != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 12, backgroundColor: AppTheme.primaryColor, child: Icon(Icons.person_rounded, size: 14, color: Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          booking.technicianName!,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textColor),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.outfit(color: AppTheme.textColor, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'in_progress': return Colors.indigo;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
