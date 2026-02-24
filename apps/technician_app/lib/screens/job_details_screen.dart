import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/models/booking.dart';
import '../core/services/booking_service.dart';
import '../core/widgets/safe_network_image.dart';

class JobDetailsScreen extends StatelessWidget {
  final Booking booking;

  const JobDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Job Details", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SafeNetworkImage(
                  imageUrl: booking.serviceImage,
                  height: 240,
                  width: double.infinity,
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildStatusPill(booking.status),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking.serviceTitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Text(
                            "₹${booking.finalAmount}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Booking ID: #${booking.bookingId.substring(0, 8).toUpperCase()}",
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle("Customer Detail"),
                      const SizedBox(height: 16),
                      _buildDetailCard([
                        _buildInfoRow(Icons.person_outline_rounded, "Recipient Name", booking.customerName),
                        const Divider(height: 32, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(Icons.location_on_outlined, "Service Address", booking.addressSnapshot['fullAddress'] ?? 'N/A'),
                      ]),
                      
                      const SizedBox(height: 32),
                      _buildSectionTitle("Schedule"),
                      const SizedBox(height: 16),
                      _buildDetailCard([
                        _buildInfoRow(Icons.calendar_today_rounded, "Appointment Date", DateFormat('EEEE, dd MMM yyyy').format(booking.scheduledAt)),
                        const Divider(height: 32, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(Icons.access_time_rounded, "Preferred Slot", booking.scheduledTime),
                      ]),

                      if (booking.problemDescription != null) ...[
                        const SizedBox(height: 32),
                        _buildSectionTitle("Technician Notes"),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Text(
                            booking.problemDescription!,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF475569),
                              height: 1.6,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      _buildSectionTitle("Payment Information"),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            _buildPriceRow("Base Fare", "₹${booking.price}"),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: Colors.white10),
                            ),
                            _buildPriceRow("Technician Payout", "₹${booking.finalAmount}", isTotal: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomSheet(context),
    );
  }

  Widget? _buildBottomSheet(BuildContext context) {
    if (booking.status == 'technician_pending') {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: _bottomSheetDecoration(),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleAction(context, 'reject'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text("Decline", style: GoogleFonts.plusJakartaSans(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleAction(context, 'accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text("Accept Job", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    if (booking.status == 'confirmed') {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: _bottomSheetDecoration(),
        child: ElevatedButton.icon(
          onPressed: () => _handleAction(context, 'start'),
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          label: Text("START JOB", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    if (booking.status == 'in_progress' || booking.status == 'started') {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: _bottomSheetDecoration(),
        child: ElevatedButton.icon(
          onPressed: () => _handleAction(context, 'complete'),
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
          label: Text("COMPLETE JOB", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    // Default: Call Customer
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: _bottomSheetDecoration(),
      child: ElevatedButton.icon(
        onPressed: () {
          // Implement call customer logic
        },
        icon: const Icon(Icons.call_rounded, size: 20),
        label: const Text("Call Customer"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  BoxDecoration _bottomSheetDecoration() {
    return BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, -8),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, String action) async {
    final service = BookingService();
    try {
      if (action == 'accept') {
        await service.acceptBooking(booking.id);
      } else if (action == 'reject') {
        await service.rejectBooking(booking.id);
      } else if (action == 'start') {
        await service.updateBookingStatus(booking.id, 'in_progress');
      } else if (action == 'complete') {
        await service.updateBookingStatus(booking.id, 'completed');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Job ${action}ed successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e")),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.white : Colors.white60,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTotal ? 22 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? const Color(0xFF818CF8) : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
    Color color = const Color(0xFF6366F1);
    if (status == 'completed') color = const Color(0xFF10B981);
    if (status == 'started') color = const Color(0xFFF59E0B);
    if (status == 'cancelled') color = const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase().replaceAll('_', ' '),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

