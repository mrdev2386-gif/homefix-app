import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking.dart';
import '../../../core/firestore/booking_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../bookings/presentation/rating_screen.dart';
import '../../home/main_wrapper_screen.dart';

class BookingStatusScreen extends StatefulWidget {
  final String bookingId;
  const BookingStatusScreen({super.key, required this.bookingId});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  final BookingService _bookingService = BookingService();
  bool _ratingShown = false;

  void _showRating(Booking booking) {
    if (_ratingShown) return;
    _ratingShown = true;
    
    // Slight delay for better UX after completion
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => RatingScreen(booking: booking),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Booking Status', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
            (route) => false,
          ),
        ),
      ),
      body: StreamBuilder<Booking?>(
        stream: _bookingService.getBookingStream(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final booking = snapshot.data;
          if (booking == null) {
            return const Center(child: Text('Booking not found'));
          }

          // Auto-open rating logic
          if (booking.status == 'completed' && 
              booking.paymentStatus == 'paid' && 
              !booking.isRated && 
              !_ratingShown) {
            _showRating(booking);
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildStatusHeader(booking),
                _buildTrackingSection(booking),
                if (booking.technicianId != null) _buildProfessionalCard(booking),
                _buildBookingDetails(booking),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStatusHeader(Booking booking) {
    String message = 'Finding the best professional for you...';
    if (booking.status == 'assigned') message = 'Professional assigned!';
    if (booking.status == 'on_the_way') message = 'Professional is on the way';
    if (booking.status == 'started') message = 'Work in progress';
    if (booking.status == 'completed') message = 'Job completed successfully';
    if (booking.status == 'cancelled') message = 'Booking cancelled';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getStatusIcon(booking.status), color: _getStatusColor(booking.status), size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            booking.status.replaceAll('_', ' ').toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _getStatusColor(booking.status),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingSection(Booking booking) {
    final statusList = ['confirmed', 'assigned', 'on_the_way', 'started', 'completed'];
    if (booking.status == 'cancelled') return const SizedBox();
    
    int currentIndex = statusList.indexOf(booking.status);
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: List.generate(statusList.length, (index) {
          final isPast = index < currentIndex;
          final isCurrent = index == currentIndex;
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isPast || isCurrent ? AppTheme.primaryColor : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isPast 
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Container(width: 8, height: 8, decoration: BoxDecoration(color: isCurrent ? Colors.white : Colors.grey.shade400, shape: BoxShape.circle)),
                    ),
                  ),
                  if (index < statusList.length - 1)
                    Container(width: 2, height: 40, color: isPast ? AppTheme.primaryColor : Colors.grey.shade200),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusList[index].replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 14,
                        color: isCurrent ? AppTheme.textColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusSubtext(statusList[index]),
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProfessionalCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.technicianName ?? 'Your Expert',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Professional Partner',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.phone, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails(Booking booking) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BOOKING DETAILS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 16),
          _detailRow(Icons.build_circle_rounded, 'Services', booking.serviceTitle),
          const Divider(height: 32),
          _detailRow(Icons.calendar_month_rounded, 'Schedule', '${DateFormat('EEE, d MMM').format(booking.scheduledAt)} at ${booking.scheduledTime}'),
          const Divider(height: 32),
          _detailRow(Icons.location_on_rounded, 'Address', booking.addressSnapshot['fullAddress'] ?? 'No address'),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Need Help?'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.blue;
      case 'assigned': return Colors.indigo;
      case 'on_the_way': return Colors.orange;
      case 'started': return AppTheme.primaryColor;
      case 'completed': return AppTheme.successColor;
      case 'cancelled': return AppTheme.errorColor;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle_outline;
      case 'assigned': return Icons.person_search;
      case 'on_the_way': return Icons.directions_bike;
      case 'started': return Icons.build;
      case 'completed': return Icons.verified;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  String _getStatusSubtext(String status) {
    switch (status) {
      case 'confirmed': return 'Booking received & payment verified';
      case 'assigned': return 'Service expert assigned to your job';
      case 'on_the_way': return 'Expert is travelling to your location';
      case 'started': return 'Work is currently in progress';
      case 'completed': return 'Service finished. Thank you!';
      default: return '';
    }
  }
}
