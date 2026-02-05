import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/booking.dart';
import '../../core/theme/app_theme.dart';

class DetailScreen extends StatelessWidget {
  final String bookingId;
  const DetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Scaffold(body: Center(child: Text('Booking not found')));
          }

          final booking = Booking.fromFirestore(snapshot.data!);
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, booking),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(booking),
                      const SizedBox(height: 24),
                      Text("Expert Details", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _buildTechnicianCard(context, booking),
                      const SizedBox(height: 32),
                      Text("Timeline", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 20),
                      _buildTimeline(booking),
                      const SizedBox(height: 32),
                      Text("Payment Summary", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _buildPaymentInfo(booking),
                      const SizedBox(height: 40),
                      if (['pending', 'confirmed'].contains(booking.status.toLowerCase()))
                        _buildCancelButton(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Booking booking) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          booking.serviceTitle,
          style: GoogleFonts.outfit(color: AppTheme.textColor, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        background: Container(color: Colors.white),
      ),
    );
  }

  Widget _buildStatusCard(Booking booking) {
    final statusColor = _getStatusColor(booking.status);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(_getStatusIcon(booking.status), color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.status.toUpperCase(),
                      style: GoogleFonts.outfit(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                    ),
                    Text(
                      _getStatusMessage(booking.status),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          _buildInfoRow(Icons.calendar_today_rounded, "Scheduled Date", DateFormat('EEE, MMM dd, yyyy').format(booking.scheduledAt)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.access_time_filled_rounded, "Expected Time", DateFormat.jm().format(booking.scheduledAt)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on_rounded, "Service Location", booking.addressSnapshot['fullAddress'] ?? 'Saved Address'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.subtitleColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianCard(BuildContext context, Booking booking) {
    if (booking.technicianId == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Assigning the best expert for you...',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.primaryColor, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text((booking.technicianName?.isNotEmpty ?? false) ? booking.technicianName![0] : 'T', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.technicianName ?? 'Technician',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text('Professional Expert', style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 12)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: AppTheme.successColor.withOpacity(0.1), shape: BoxShape.circle),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.phone_rounded, color: AppTheme.successColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Booking booking) {
    final statusMap = {
      'pending': 0,
      'confirmed': 1,
      'in_progress': 2,
      'completed': 3,
    };
    
    final currentIdx = statusMap[booking.status.toLowerCase()] ?? -1;
    
    return Column(
      children: [
        _buildTimelineStep('Order Placed', 'We have received your request', currentIdx >= 0, false),
        _buildTimelineStep('Expert Assigned', 'Professional is on the way', currentIdx >= 1, false),
        _buildTimelineStep('Work Started', 'Expert has started the service', currentIdx >= 2, false),
        _buildTimelineStep('Completed', 'Service finished successfully', currentIdx >= 3, true),
      ],
    );
  }

  Widget _buildTimelineStep(String title, String sub, bool isDone, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: isDone ? AppTheme.primaryColor : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: isDone ? AppTheme.primaryColor : Colors.grey.shade200),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: isDone ? AppTheme.textColor : AppTheme.subtitleColor)),
                  Text(sub, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.subtitleColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildPaymentRow('Service Price', '₹${booking.price}'),
          if (booking.discountAmount > 0)
            _buildPaymentRow('Promo Discount', '-₹${booking.discountAmount}', color: AppTheme.successColor),
          const Divider(height: 32),
          _buildPaymentRow('Total Payable', '₹${booking.finalAmount}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(color: isBold ? AppTheme.textColor : AppTheme.subtitleColor, fontWeight: isBold ? FontWeight.w800 : FontWeight.w500, fontSize: isBold ? 16 : 14)),
        Text(value, style: GoogleFonts.outfit(color: color ?? AppTheme.textColor, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, fontSize: isBold ? 18 : 14)),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => _confirmCancel(context),
        child: Text('Cancel Booking', style: GoogleFonts.outfit(color: AppTheme.errorColor, fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Service?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No, Keep It')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': 'cancelled'});
            }, 
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.hourglass_empty_rounded;
      case 'confirmed': return Icons.check_circle_outline_rounded;
      case 'in_progress': return Icons.engineering_rounded;
      case 'completed': return Icons.task_alt_rounded;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.info_outline_rounded;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Wait for Assignment';
      case 'confirmed': return 'Expect Professional';
      case 'in_progress': return 'Work is Underway';
      case 'completed': return 'Service Finished';
      case 'cancelled': return 'Booking Cancelled';
      default: return 'Information';
    }
  }
}
