import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/booking.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../payment/presentation/payment_screen.dart';
import '../widgets/status_tracker.dart';
import 'rating_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _ratingShown = false;
  late Booking _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    final status = _booking.bookingStatus.isNotEmpty ? _booking.bookingStatus : _booking.status;
    if (status == 'completed' && _booking.paymentStatus == 'paid' && !_booking.isRated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _rateService(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Booking Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareBooking(context),
          ),
        ],
      ),
      body: StreamBuilder<Booking?>(
        stream: firestoreService.streamBookingDetail(_booking.id),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            _booking = snapshot.data!;
          }
          
          final booking = _booking;
          final currentStatus = booking.bookingStatus.isNotEmpty ? booking.bookingStatus : booking.status;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking ID Card
                _buildInfoCard(
                  context,
                  child: Column(
                    children: [
                      Text('Booking ID', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            booking.id.substring(0, 12).toUpperCase(),
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: booking.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking ID copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Status Tracker
                _buildInfoCard(context, child: StatusTracker(status: currentStatus)),
                const SizedBox(height: 20),
                // Service Details
                _buildSectionTitle('Service Details'),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.home_repair_service, 'Service', booking.serviceTitle),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.calendar_today, 'Scheduled', DateFormat('MMM dd, yyyy').format(booking.scheduledAt)),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.access_time, 'Time', DateFormat('hh:mm a').format(booking.scheduledAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Address
                _buildSectionTitle('Service Location'),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.location_on, color: Colors.red[400], size: 20),
                        const SizedBox(width: 8),
                        Text('Address', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      Text(_getFullAddress(booking.addressSnapshot),
                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700], height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Technician - Show when approved_by_admin or technician_accepted
                if ((currentStatus == 'approved_by_admin' || currentStatus == 'technician_accepted' || currentStatus == 'in_progress' || currentStatus == 'started' || currentStatus == 'awaiting_payment') && booking.technicianName != null) ...[
                  _buildSectionTitle('Technician Details'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                              child: const Icon(Icons.person, color: Color(0xFF6366F1), size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(booking.technicianName!, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentStatus == 'approved_by_admin' ? 'Technician Assigned' : 
                                    currentStatus == 'technician_accepted' ? 'Technician On The Way' :
                                    currentStatus == 'in_progress' || currentStatus == 'started' ? 'Service In Progress' :
                                    'Assigned Technician',
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            if (currentStatus != 'completed' && currentStatus != 'cancelled' && currentStatus != 'cancelled_by_customer')
                              IconButton(
                                icon: const Icon(Icons.phone, color: Color(0xFF6366F1)),
                                onPressed: _callTechnician,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                currentStatus == 'approved_by_admin' ? Icons.assignment_ind : 
                                currentStatus == 'technician_accepted' ? Icons.directions_car :
                                Icons.build,
                                color: const Color(0xFF2563EB),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  currentStatus == 'approved_by_admin' ? 'Technician has been assigned to your booking' : 
                                  currentStatus == 'technician_accepted' ? 'Technician is on the way to your location' :
                                  currentStatus == 'in_progress' || currentStatus == 'started' ? 'Technician is working on your service' :
                                  'Technician assigned',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: const Color(0xFF1E40AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Payment Details
                _buildSectionTitle('Payment Details'),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  child: Column(
                    children: [
                      _buildPriceRow('Service Price', booking.price),
                      if (booking.discountAmount > 0) ...[
                        const Divider(height: 24),
                        _buildPriceRow('Discount', -booking.discountAmount, isDiscount: true),
                      ],
                      if (booking.couponCode != null) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(Icons.local_offer, size: 14, color: Colors.green[600]),
                          const SizedBox(width: 6),
                          Text('Coupon: ${booking.couponCode}',
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.green[600], fontWeight: FontWeight.w500)),
                        ]),
                      ],
                      const Divider(height: 24),
                      _buildPriceRow('Total Amount', booking.finalAmount, isTotal: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Timeline
                _buildSectionTitle('Booking Timeline'),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  child: Column(
                    children: [
                      _buildTimelineRow('Booking Created', DateFormat('MMM dd, yyyy • hh:mm a').format(booking.createdAt)),
                      const Divider(height: 24),
                      _buildTimelineRow('Last Updated', DateFormat('MMM dd, yyyy • hh:mm a').format(booking.updatedAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // ── ACTION BUTTONS ──
                // Cancel: only for pending_admin_review (customer can only cancel before admin approves)
                if (currentStatus == 'pending_admin_review') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _cancelBooking(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel Booking', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
                // Pay Now button
                if (currentStatus == 'awaiting_payment') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => PaymentScreen(bookingId: booking.id),
                      )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: Text('PAY NOW (₹${booking.finalAmount.toStringAsFixed(0)})',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
                // Cancelled state
                if (currentStatus == 'cancelled' || currentStatus == 'cancelled_by_customer') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_outlined, color: Colors.red),
                        const SizedBox(width: 12),
                        Text('This booking has been cancelled.',
                            style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                // Rate service - only show if completed AND paid
                if (currentStatus == 'completed' && booking.paymentStatus == 'paid') ...[
                  if (!booking.isRated)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _rateService(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Rate Service', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text('You have rated this service', style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) =>
      Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold));

  Widget _buildInfoCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? Colors.black : Colors.grey[700],
        )),
        Text('${isDiscount ? '-' : ''}₹${amount.toStringAsFixed(0)}', style: GoogleFonts.outfit(
          fontSize: isTotal ? 18 : 14,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          color: isDiscount ? Colors.green[600] : (isTotal ? const Color(0xFF6366F1) : Colors.black),
        )),
      ],
    );
  }

  Widget _buildTimelineRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700])),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _getFullAddress(Map<String, dynamic> addressSnapshot) {
    if (addressSnapshot.isEmpty) return 'Address not available';
    final parts = <String>[];
    if (addressSnapshot['houseNo'] != null) parts.add(addressSnapshot['houseNo']);
    if (addressSnapshot['street'] != null) parts.add(addressSnapshot['street']);
    if (addressSnapshot['area'] != null) parts.add(addressSnapshot['area']);
    if (addressSnapshot['landmark'] != null) parts.add('Near ${addressSnapshot['landmark']}');
    if (addressSnapshot['city'] != null) parts.add(addressSnapshot['city']);
    if (addressSnapshot['pincode'] != null) parts.add(addressSnapshot['pincode']);
    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }

  void _shareBooking(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share functionality coming soon!')));
  }

  void _callTechnician() {}

  void _cancelBooking(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Booking?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to cancel? This cannot be undone.', style: GoogleFonts.outfit()),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: 'Reason for cancellation', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('No', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
                return;
              }
              Navigator.pop(ctx);
              try {
                await context.read<BookingProvider>().cancelBooking(_booking.id, reason: reason);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking cancelled successfully'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
                }
              }
            },
            child: Text('Yes, Cancel', style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _rateService(BuildContext context) async {
    if (_ratingShown) return;
    _ratingShown = true;
    final result = await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => RatingScreen(booking: _booking),
    ));
    if (result == true && mounted) Navigator.pop(context);
  }
}
