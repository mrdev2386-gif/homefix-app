import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/models/booking.dart';
import '../core/widgets/safe_network_image.dart';

class JobDetailsScreen extends StatelessWidget {
  final Booking booking;

  const JobDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Job Details", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeNetworkImage(
              imageUrl: booking.serviceImage,
              height: 200,
              width: double.infinity,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          booking.serviceTitle,
                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildStatusPill(booking.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Booking ID: #${booking.bookingId.substring(0, 8).toUpperCase()}",
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle("Customer Information"),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.person_outline_rounded, "Name", booking.customerName),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_outlined, "Address", booking.addressSnapshot['fullAddress'] ?? 'N/A'),
                  const SizedBox(height: 32),

                  _buildSectionTitle("Job Schedule"),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today_rounded, "Date", DateFormat('EEEE, dd MMM yyyy').format(booking.scheduledAt)),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.access_time_rounded, "Time Slot", booking.scheduledTime),
                  const SizedBox(height: 32),

                  if (booking.problemDescription != null) ...[
                    _buildSectionTitle("Problem Description"),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        booking.problemDescription!,
                        style: GoogleFonts.outfit(color: const Color(0xFF475569), height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionTitle("Payment Summary"),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildPriceRow("Service Fare", "₹${booking.price}"),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0xFFE2E8F0)),
                        ),
                        _buildPriceRow("Total Earnings", "₹${booking.finalAmount}", isTotal: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            // Implement Call Customer
          },
          icon: const Icon(Icons.call_rounded),
          label: const Text("Call Customer"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
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
        Text(label, style: GoogleFonts.outfit(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: GoogleFonts.outfit(fontSize: isTotal ? 20 : 16, fontWeight: FontWeight.bold, color: isTotal ? const Color(0xFF6366F1) : null)),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
    Color color = const Color(0xFF6366F1);
    if (status == 'completed') color = const Color(0xFF10B981);
    if (status == 'started') color = const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: GoogleFonts.outfit(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
