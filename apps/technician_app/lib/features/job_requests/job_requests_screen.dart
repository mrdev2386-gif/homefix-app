import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/booking_service.dart';
import '../../core/models/booking.dart';
import '../../core/providers/technician_provider.dart';
import '../../core/widgets/safe_network_image.dart';
import 'package:shimmer/shimmer.dart';

class JobRequestsScreen extends StatefulWidget {
  const JobRequestsScreen({super.key});

  @override
  State<JobRequestsScreen> createState() => _JobRequestsScreenState();
}

class _JobRequestsScreenState extends State<JobRequestsScreen> {
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TechnicianProvider>(context);
    final tech = provider.technician;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Job Assignments",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: tech == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Booking>>(
              stream: _bookingService.getPendingBookings(tech.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Error loading requests: ${snapshot.error}', textAlign: TextAlign.center),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: 3,
                    itemBuilder: (context, index) => _buildSkeletonCard(),
                  );
                }

                final bookings = snapshot.data ?? [];

                return RefreshIndicator(
                  onRefresh: () async {
                    // Just wait a moment since Stream is real-time
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: bookings.isEmpty
                      ? Stack(
                          children: [
                            ListView(), // Empty list view to allow Pull-to-refresh
                            _buildEmptyState(),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(bookings[index], tech);
                          },
                        ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 24),
            Text(
              "No pending assignments",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Once an administrator assigns a job to you, it will appear here for your approval.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Booking b, dynamic tech) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SafeNetworkImage(
                      imageUrl: b.serviceImage,
                      height: 64,
                      width: 64,
                      borderRadius: 18,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "ESTIMATED EARNING",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹${b.finalAmount.toInt()}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildPill(
                      DateFormat('MMM dd').format(b.scheduledAt),
                      Icons.calendar_today_rounded,
                      const Color(0xFF6366F1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  b.serviceTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      b.addressSnapshot['area'] ?? 'Nearby Area',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (b.problemDescription != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CUSTOMER NOTE",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          b.problemDescription!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF475569),
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleAction(b.bookingId, 'reject'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text("Decline"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleAction(b.bookingId, 'accept'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          backgroundColor: const Color(0xFF6366F1),
                        ),
                        child: const Text("Accept Job"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  void _handleAction(String bookingId, String action) async {
    try {
      if (action == 'accept') {
        await _bookingService.acceptBooking(bookingId);
      } else {
        await _bookingService.rejectBooking(bookingId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Job ${action}ed successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 80, height: 12, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 120, height: 24, color: Colors.white),
                    ],
                  ),
                ),
                Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
              ],
            ),
            const SizedBox(height: 20),
            Container(width: 200, height: 20, color: Colors.white),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 14, color: Colors.white),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: Container(height: 52, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 52, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

