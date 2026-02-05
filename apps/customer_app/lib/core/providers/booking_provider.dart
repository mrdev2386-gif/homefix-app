import 'package:flutter/material.dart';
import '../firestore/booking_service.dart';
import '../models/booking.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  
  bool _isBooking = false;
  bool get isBooking => _isBooking;

  Future<String> createBooking(Booking booking) async {
    _isBooking = true;
    notifyListeners();
    try {
      // Convert Booking model to Map before passing to service
      final response = await _bookingService.createBooking(booking.toMap());
      // Extract bookingId from response
      final bookingId = response['bookingId'] as String;
      return bookingId;
    } catch (e) {
      rethrow;
    } finally {
      _isBooking = false;
      notifyListeners();
    }
  }

  Stream<List<Booking>> customerBookings(String customerId) {
    return _bookingService.getCustomerBookings(customerId);
  }

  Future<void> cancelBooking(String bookingId, {String reason = 'Cancelled by customer'}) async {
    await _bookingService.cancelBooking(bookingId, reason);
  }
}
