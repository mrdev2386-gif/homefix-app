import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/functions_service.dart';
import '../../../core/models/address.dart';
import '../../home/main_wrapper_screen.dart';
import '../../../core/theme/app_theme.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final Map<String, dynamic> slot;
  final DateTime date;
  final Address address;

  const BookingConfirmationScreen({
    super.key, 
    required this.service, 
    required this.slot, 
    required this.date,
    required this.address,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isLoading = false;

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);
    try {
      final success = await Provider.of<FunctionsService>(context, listen: false).createBooking({
        'serviceId': widget.service['id'] ?? widget.service['key'] ?? widget.service['serviceId'] ?? '',
        'serviceTitle': widget.service['name'] ?? widget.service['title'] ?? 'Service',
        'price': (widget.service['price'] ?? widget.service['basePrice'] ?? 0).toDouble(),
        'technicianId': widget.slot['techId'],
        'slotId': widget.slot['id'],
        'scheduledDate': widget.date.toIso8601String(),
        'scheduledTime': widget.slot['startTime'],
        'address': widget.address.fullAddress,
      });

      if (success['bookingId'] != null) {
        if (mounted) {
          _showSuccessSheet();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Booking Failed: ${e.toString().split(']').last}"),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.successColor.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Booking Confirmed!',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Your professional is being assigned. You can track everything in your bookings.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 15),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainWrapperScreen()),
                  (route) => false,
                );
              },
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.service['price'] ?? widget.service['basePrice'] ?? 0;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Review & Pay", style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServicePreview(price),
            const SizedBox(height: 24),
            Text(
              "Booking Details",
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textColor),
            ),
            const SizedBox(height: 16),
            _buildDetailCard(),
            const SizedBox(height: 32),
            _buildCancellationPolicy(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(price),
    );
  }

  Widget _buildServicePreview(dynamic price) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service['name'] ?? widget.service['title'] ?? 'Service', 
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900)
                ),
                const SizedBox(height: 4),
                Text(
                  'Professional Home Service', 
                  style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 13, fontWeight: FontWeight.w500)
                ),
              ],
            ),
          ),
          Text(
            "₹$price", 
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_pin_rounded, "Expert Choice", widget.slot['techName']),
          const Divider(height: 32),
          _buildInfoRow(Icons.event_available_rounded, "Schedule", "${DateFormat('EEE, d MMM').format(widget.date)} at ${widget.slot['startTime']}"),
          const Divider(height: 32),
          _buildInfoRow(Icons.location_on_rounded, "Location", widget.address.fullAddress),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.primaryColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancellationPolicy() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Free cancellation until 2 hours before the service starts.",
              style: GoogleFonts.outfit(color: const Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(dynamic price) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 40, offset: const Offset(0, -10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TO BE PAID', style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                Text(
                  '₹$price',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _confirmBooking,
              child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text("Confirm & Book"),
            ),
          ),
        ],
      ),
    );
  }
}
