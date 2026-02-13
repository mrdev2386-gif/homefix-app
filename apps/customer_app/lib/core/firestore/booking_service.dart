import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      // Use V2 function for booking creation
      final HttpsCallable callable = _functions.httpsCallable('createBookingV2');
      final results = await callable.call(bookingData);
      return results.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error creating booking via Function: $e");
      rethrow;
    }
  }

  Stream<List<Booking>> getCustomerBookings(String customerId) {
    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
     try {
      final HttpsCallable callable = _functions.httpsCallable('updateBookingStatus');
      await callable.call({
        'bookingId': bookingId,
        'status': 'cancelled',
        'reason': reason,
      });
    } catch (e) {
      debugPrint("Error cancelling booking via Function: $e");
      rethrow;
    }
  }

  Stream<Booking?> getBookingStream(String bookingId) {
    return _db.collection('bookings').doc(bookingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Booking.fromFirestore(doc);
    });
  }
}

