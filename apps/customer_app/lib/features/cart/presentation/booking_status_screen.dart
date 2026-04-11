import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/models/booking.dart';
import '../../bookings/presentation/booking_detail_screen.dart';

class BookingStatusScreen extends StatelessWidget {
  final String bookingId;

  const BookingStatusScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Booking?>(
      stream: BookingService().getBookingStream(bookingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Booking not found'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          );
        }

        final booking = snapshot.data!;
        return BookingDetailScreen(booking: booking);
      },
    );
  }
}
