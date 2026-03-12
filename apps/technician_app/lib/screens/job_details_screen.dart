import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/booking.dart';
import '../core/services/booking_service.dart';
import '../core/widgets/safe_network_image.dart';

class JobDetailsScreen extends StatefulWidget {
  final Booking booking;

  const JobDetailsScreen({super.key, required this.booking});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  // STEP 3: Action spam hard guard
  bool _isActionRunning = false;

  // STEP 1: Helper to safely get technician earnings (technicianAmount > finalAmount > 0)
  double _getTechnicianEarnings() {
    // Try to get technicianAmount from quoteData first
    final quoteData = widget.booking.quoteData;
    if (quoteData != null) {
      final techAmount = quoteData['technicianAmount'];
      if (techAmount != null) {
        if (techAmount is num) return techAmount.toDouble();
        if (techAmount is String) return double.tryParse(techAmount) ?? 0.0;
      }
    }
    // Fallback to finalAmount, then price, then 0
    if (widget.booking.finalAmount > 0) return widget.booking.finalAmount;
    if (widget.booking.price > 0) return widget.booking.price;
    return 0.0;
  }

  // STEP 2: Timezone-safe time display
  String _formatScheduledAt() {
    try {
      final scheduledAt = widget.booking.scheduledAt;
      // Display in local device timezone with 12-hour format
      return DateFormat('EEEE, dd MMM yyyy').format(scheduledAt.toLocal());
    } catch (e) {
      return '—';
    }
  }

  // STEP 6: Status fallback - check if status is known
  bool _isKnownStatus(String status) {
    const knownStatuses = [
      'admin_approved',
      'technician_accepted',
      'awaiting_payment',
      'pending',
      'confirmed',
      'accepted',
      'in_progress',
      'started',
      'completed',
      'cancelled',
      'rejected',
      'awaiting_customer_payment',
    ];
    return knownStatuses.contains(status);
  }

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SafeNetworkImage(
                    imageUrl: widget.booking.serviceImage,
                    height: 240,
                    width: double.infinity,
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildStatusPill(widget.booking.status),
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
                              widget.booking.serviceTitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Text(
                            "₹${_getTechnicianEarnings().toStringAsFixed(0)}",
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
                        "Booking ID: #${widget.booking.bookingId.substring(0, 8).toUpperCase()}",
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle("Customer Detail"),
                      const SizedBox(height: 16),
                      _buildCustomerCard(),
                      
                      if (widget.booking.addressSnapshot['latitude'] != null && widget.booking.addressSnapshot['longitude'] != null) ...[
                        const SizedBox(height: 16),
                        _buildLocationPreview(),
                      ],
                      
                      const SizedBox(height: 32),
                      _buildSectionTitle("Schedule"),
                      const SizedBox(height: 16),
                      _buildDetailCard([
                        _buildInfoRow(Icons.calendar_today_rounded, "Appointment Date", _formatScheduledAt()),
                        const Divider(height: 32, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(Icons.access_time_rounded, "Preferred Slot", widget.booking.scheduledTime),
                      ]),

                      if (widget.booking.problemDescription != null && widget.booking.problemDescription!.trim().isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSectionTitle("Special Instructions"),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 20, color: Color(0xFF0284C7)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.booking.problemDescription!,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF0C4A6E),
                                    height: 1.6,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                            _buildPriceRow("Service Price", "₹${(widget.booking.price as num?)?.toDouble() ?? 0}"),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: Colors.white10),
                            ),
                            _buildPriceRow("Your Earnings", "₹${_getTechnicianEarnings().toStringAsFixed(0)}", isTotal: true),
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
    ),
    bottomSheet: _buildBottomSheet(context),
  );
}

  Widget? _buildBottomSheet(BuildContext context) {
    final status = widget.booking.status;
    
    // STEP 6: Status fallback - hide action bar for unknown status
    if (!_isKnownStatus(status)) {
      return null;
    }
    
    if (status == 'admin_approved' || status == 'pending') {
      return _ActionBar(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleAction(context, 'reject'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text("Reject", style: GoogleFonts.plusJakartaSans(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _handleAction(context, 'accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: Text("Accept Job", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'confirmed' || status == 'accepted') {
      return _ActionBar(
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

    if (status == 'in_progress' || status == 'started') {
      return _ActionBar(
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

    if (status == 'awaiting_customer_payment') {
      return _ActionBar(
        child: ElevatedButton.icon(
          onPressed: () => _showQRScanner(context),
          icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
          label: Text("SCAN FOR PAYMENT", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    if (status == 'completed') {
      return null;
    }

    return null;
  }

  void _handleAction(BuildContext context, String action) async {
    // STEP 3: Action spam hard guard - prevent race condition double taps
    if (_isActionRunning) return;
    if (!mounted) return;
    
    _isActionRunning = true;
    
    // Generate idempotency key for this action
    final idempotencyKey = '${widget.booking.id}_${action}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    
    final service = BookingService();
    try {
      if (action == 'accept') {
        await service.acceptBooking(widget.booking.id, idempotencyKey: idempotencyKey);
      } else if (action == 'reject') {
        await service.rejectBooking(widget.booking.id, idempotencyKey: idempotencyKey);
      } else if (action == 'start') {
        await service.updateBookingStatus(widget.booking.id, 'in_progress');
      } else if (action == 'complete') {
        await service.markWorkCompleted(widget.booking.id);
      }
      
      if (!mounted) return;
      Navigator.pop(context);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Job ${action}ed successfully"),
          backgroundColor: Colors.green,
        ),
      );
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // STEP 3: Always reset the action lock
      if (mounted) {
        setState(() {
          _isActionRunning = false;
        });
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
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
    // STEP 6: Status fallback - neutral color for unknown status
    Color color = const Color(0xFF6366F1);
    if (status == 'completed') color = const Color(0xFF10B981);
    if (status == 'started' || status == 'in_progress') color = const Color(0xFFF59E0B);
    if (status == 'cancelled' || status == 'rejected') color = const Color(0xFFEF4444);
    if (status == 'admin_approved' || status == 'pending') color = const Color(0xFF8B5CF6);
    if (status == 'technician_accepted' || status == 'awaiting_payment') color = const Color(0xFFF59E0B);
    if (status == 'confirmed' || status == 'accepted') color = const Color(0xFF3B82F6);
    if (status == 'awaiting_customer_payment') color = const Color(0xFF6366F1);
    
    // Unknown status gets neutral gray color
    if (!_isKnownStatus(status)) {
      color = const Color(0xFF6B7280);
    }

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
            _isKnownStatus(status) ? status.toUpperCase().replaceAll('_', ' ') : 'UNKNOWN',
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

  Widget _buildCustomerCard() {
    final phone = widget.booking.addressSnapshot['phone'] as String? ?? '';
    final address = widget.booking.addressSnapshot['fullAddress'] as String? ?? 'Address not available';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEEF2FF),
                child: Text(
                  widget.booking.customerName.isNotEmpty ? widget.booking.customerName[0].toUpperCase() : 'C',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.booking.customerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _makePhoneCall(phone),
                        child: Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: Color(0xFF6366F1)),
                            const SizedBox(width: 6),
                            Text(
                              phone,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (phone.isNotEmpty)
                IconButton(
                  onPressed: () => _makePhoneCall(phone),
                  icon: const Icon(Icons.call, color: Color(0xFF10B981)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF0FDF4),
                  ),
                ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Service Address",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildLocationPreview() {
    final lat = (widget.booking.addressSnapshot['latitude'] as num?)?.toDouble();
    final lng = (widget.booking.addressSnapshot['longitude'] as num?)?.toDouble();
    
    if (lat == null || lng == null) return const SizedBox.shrink();
    
    // STEP 5: Location Preview Premium Polish - Add "View on Map" CTA
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: Color(0xFFCA8A04)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Location Available",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF854D0E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Tap to view on map",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFFA16207),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openMap(lat, lng),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFEF08A),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              "View Map",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF854D0E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 5: Open maps with coordinates
  void _openMap(double lat, double lng) async {
    final mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(mapsUrl)) {
        await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to open maps"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // STEP 4: Phone call hardening with validation and error handling
  void _makePhoneCall(String phone) async {
    // Validate phone not empty
    if (phone.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phone number not available"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Validate minimum length (at least 6 digits for valid phone)
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length < 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid phone number"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Ensure phone has country code
    final phoneToDial = cleanPhone.startsWith('+') ? cleanPhone : '+$cleanPhone';
    
    final uri = Uri.parse('tel:$phoneToDial');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Dialer not available on this device"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to make call: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showQRScanner(BuildContext context) {
    // Note: In real device, this would use mobile_scanner
    // For this simulation/demo, we'll show a dialog to "confirm scan"
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Scan Customer QR"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 100, color: Colors.indigo),
            const SizedBox(height: 16),
            Text("Scan the QR code shown on the customer's phone to receive ₹${_getTechnicianEarnings().toStringAsFixed(0)} in your wallet.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processQRPayment();
            },
            child: const Text("Simulate Scan"),
          ),
        ],
      ),
    );
  }

  Future<void> _processQRPayment() async {
    if (_isActionRunning) return;
    setState(() => _isActionRunning = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = BookingService();
      await service.confirmQRPayment(
        bookingId: widget.booking.id,
        customerId: widget.booking.customerId,
        amount: widget.booking.finalAmount > 0 ? widget.booking.finalAmount : widget.booking.price,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Confirmed! Your wallet has been credited."), backgroundColor: Colors.green),
      );
      
      Navigator.pop(context); // Go back to dashboard
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isActionRunning = false);
    }
  }
}

class _ActionBar extends StatelessWidget {
  final Widget child;
  
  const _ActionBar({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: child,
      ),
    );
  }
}
