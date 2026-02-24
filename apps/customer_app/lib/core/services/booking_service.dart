import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  FirebaseFirestore get db => _db;

  /// Creates a new booking request (NEW FLOW)
  /// 
  /// This replaces createBookingV2 with the admin-approval flow:
  /// 1. Customer creates booking → status: pending_admin
  /// 2. Admin approves → status: technician_pending
  /// 3. Technician accepts → status: awaiting_payment
  /// 4. Customer pays → status: confirmed
  Future<Map<String, dynamic>> createBookingRequest({
    required String serviceId,
    required String technicianId,
    required String categoryId,
    required String categoryName,
    required String scheduledDate,
    required String scheduledTime,
    required Map<String, dynamic> address,
    required double price,
    String? subcategoryId,
    int? durationMinutes,
    String? couponCode,
    String? idempotencyKey,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('createBookingRequest');
      final results = await callable.call({
        'serviceId': serviceId,
        'technicianId': technicianId,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'subcategoryId': subcategoryId,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'address': address,
        'price': price,
        'durationMinutes': durationMinutes,
        'couponCode': couponCode,
        'idempotencyKey': idempotencyKey ?? 'BK_${DateTime.now().millisecondsSinceEpoch}',
      });
      return results.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error creating booking request: $e");
      rethrow;
    }
  }

  Stream<List<Booking>> getCustomerBookings(String customerId) {
    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList())
        .handleError((e) {
      debugPrint('❌ [BookingService] Error fetching customer bookings: $e');
      return <Booking>[];
    });
  }

  /// Cancel a booking
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

  /// Confirm payment for a booking (NEW FLOW)
  /// 
  /// Call this when status is 'awaiting_payment'
  /// paymentMethod: 'online' or 'cash'
  Future<Map<String, dynamic>> confirmPayment({
    required String bookingId,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('customerConfirmPayment');
      final results = await callable.call({
        'bookingId': bookingId,
        'paymentMethod': paymentMethod,
        'paymentDetails': paymentDetails,
      });
      return results.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error confirming payment: $e");
      rethrow;
    }
  }

  Stream<Booking?> getBookingStream(String bookingId) {
    return _db.collection('bookings').doc(bookingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Booking.fromFirestore(doc);
    }).handleError((e) {
      debugPrint('❌ [BookingService] Error fetching booking $bookingId: $e');
      return null;
    });
  }

  Future<Booking?> getBooking(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return null;
    return Booking.fromFirestore(doc);
  }
}
