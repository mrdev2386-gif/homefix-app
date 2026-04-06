
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking.dart';
import '../../../core/services/booking_service.dart';
import '../../payment/presentation/payment_screen.dart';
import '../widgets/status_tracker.dart';
import 'rating_screen.dart';
8
class BookingDetailScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _ratingShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking.status == 'completed' && 
        widget.booking.paymentStatus == 'paid' && 
        !widget.booking.isRated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rateService(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
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
            onPressed: () {
              _shareBooking(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking ID Card
            _buildInfoCard(
              context,
              child: Column(
                children: [
                  Text(
                    'Booking ID',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        booking.id.substring(0, 12).toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
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
            _buildInfoCard(
              context,
              child: StatusTracker(status: booking.status),
            ),
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
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Scheduled',
                    DateFormat('MMM dd, yyyy').format(booking.scheduledAt),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    Icons.access_time,
                    'Time',
                    DateFormat('hh:mm a').format(booking.scheduledAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Address Details
            _buildSectionTitle('Service Location'),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red[400], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Address',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFullAddress(booking.addressSnapshot),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Technician Details (if assigned)
            if (booking.technicianName != null) ...[
              _buildSectionTitle('Technician Details'),
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                child: Row(
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
                          Text(
                            booking.technicianName!,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Assigned Technician',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (booking.status != 'completed' && booking.status != 'cancelled')
                      IconButton(
                        icon: const Icon(Icons.phone, color: Color(0xFF6366F1)),
                        onPressed: () {
                          _callTechnician();
                        },
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
                    Row(
                      children: [
                        Icon(Icons.local_offer, size: 14, color: Colors.green[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Coupon: ${booking.couponCode}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 24),
                  _buildPriceRow('Total Amount', booking.finalAmount, isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pay After Work QR Code
            if (booking.status == 'awaiting_customer_payment') ...[
              _buildSectionTitle('Payment Required'),
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                child: Column(
                  children: [
                    Text(
                      'Job Completed!',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please show this QR to the technician to complete the payment from your wallet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    QrImageView(
                      data: 'homefix_pay:${booking.id}:${booking.customerId}:${booking.finalAmount}',
                      version: QrVersions.auto,
                      size: 200.0,
                      foregroundColor: const Color(0xFF6366F1),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Amount to Pay: ₹${booking.finalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Booking Timeline
            _buildSectionTitle('Booking Timeline'),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              child: Column(
                children: [
                  _buildTimelineRow(
                    'Booking Created',
                    DateFormat('MMM dd, yyyy • hh:mm a').format(booking.createdAt),
                  ),
                  const Divider(height: 24),
                  _buildTimelineRow(
                    'Last Updated',
                    DateFormat('MMM dd, yyyy • hh:mm a').format(booking.updatedAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (['pending_admin_review', 'admin_approved', 'pending', 'assigned'].contains(booking.status)) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _cancelBooking(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel Booking',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],

            if (booking.status == 'awaiting_payment') ...[
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          bookingId: booking.id,
                          amount: booking.finalAmount,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'PAY NOW (₹${booking.finalAmount.toStringAsFixed(0)})',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => _cancelBooking(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel Booking',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],

            if (booking.status == 'confirmed') ...[
               Center(
                 child: Text(
                   'Waiting for technician to start work',
                   style: GoogleFonts.outfit(color: Colors.grey[600], fontStyle: FontStyle.italic),
                 ),
               ),
               const SizedBox(height: 12),
               SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => _cancelBooking(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel Booking',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],

            if (booking.status == 'completed') ...[
              if (!booking.isRated) 
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _rateService(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Rate Service',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ) else Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'You have rated this service',
                        style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    _bookAgain(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Book Again',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}₹${amount.toStringAsFixed(0)}',
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isDiscount ? Colors.green[600] : (isTotal ? const Color(0xFF6366F1) : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _callTechnician() {
    // Implement call if needed
  }

  void _cancelBooking(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Booking?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to cancel this booking? This action cannot be undone.',
              style: GoogleFonts.outfit(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No', style: GoogleFonts.outfit()),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              try {
                await BookingService().cancelBooking(widget.booking.id, reason);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking cancelled successfully')),
                  );
                  Navigator.pop(context); // Go back after cancellation
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel: $e')),
                  );
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
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => RatingScreen(booking: widget.booking),
      ),
    );
    if (result == true) {
      // Reload or update state if needed
      if (mounted) Navigator.pop(context); // Go back after successful rating
    }
  }

  void _bookAgain(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirecting to service booking...')),
    );
  }
}
