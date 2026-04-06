import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../models/booking.dart';
import '../firebase/firebase_functions.dart';

class BookingService {
  late final FirebaseFirestore _db;
  late final FirebaseFunctions _functions;

  BookingService() {
    _db = FirebaseFirestore.instance;
    _functions = FirebaseFunctionsService.instance;
  }

  /// NEW FLOW: Get pending bookings that need technician response
  /// Status: ASSIGNED - admin approved, waiting for technician
  Stream<List<Booking>> getPendingBookings(String techId) {
    return _db.collection('bookings')
        .where('technicianId', isEqualTo: techId)
        .where('status', whereIn: [BookingStatus.assigned, 'approved_by_admin'])
        .limit(20)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();
          // Sort in memory to avoid composite index requirement
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        }).handleError((e) {
          debugPrint('❌ [BookingService] Error fetching pending bookings: $e');
        })
        .onErrorReturn(<Booking>[]);
  }

  /// NEW FLOW: Get bookings that are awaiting payment
  /// Status: awaiting_payment - technician accepted, waiting for customer payment
  Stream<List<Booking>> getAwaitingPaymentBookings(String techId) {
    return _db.collection('bookings')
        .where('technicianId', isEqualTo: techId)
        .where('bookingStatus', isEqualTo: 'awaiting_payment')
        .limit(20)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();
          // Sort in memory to avoid composite index requirement
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        }).handleError((e) {
          debugPrint('❌ [BookingService] Error fetching awaiting payment bookings: $e');
        })
        .onErrorReturn(<Booking>[]);
  }

  /// Legacy: Get available bookings (no technician assigned)
  /// Used for instant booking / auto-assign flow
  Stream<List<Booking>> getAvailableBookings(List<String> skills) {
    if (skills.isEmpty) return Stream.value([]);
    
    return _db.collection('bookings')
        .where('assignedTechnicianId', isNull: true)
        .where('bookingStatus', whereIn: ['pending', 'confirmed'])
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();
        }).handleError((e) {
          debugPrint('❌ [BookingService] Error fetching available bookings: $e');
        })
        .onErrorReturn(<Booking>[]);
  }

  /// Get bookings assigned to this technician (all statuses)
  Stream<List<Booking>> getAssignedBookings(String techId) {
    return _db.collection('bookings')
        .where('technicianId', isEqualTo: techId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        }).handleError((e) {
          debugPrint('❌ [BookingService] Error fetching assigned bookings: $e');
        })
        .onErrorReturn(<Booking>[]);
  }

  /// Get active bookings for dashboard (assigned, accepted, in_progress)
  Stream<List<Booking>> getActiveBookings(String techId) {
    return _db.collection('bookings')
        .where('technicianId', isEqualTo: techId)
        .where('status', whereIn: BookingStatus.activeStatuses)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();
        }).handleError((e) {
          // PART 1: Robust error handling
          debugPrint('❌ [BookingService] Error fetching active bookings: $e');
          if (e.toString().contains('FAILED_PRECONDITION')) {
            debugPrint('⚠️ [BookingService] Missing index for active bookings query');
          }
        })
        .onErrorReturn(<Booking>[]);
  }

  /// NEW FLOW: Accept a booking (technician accepts)
  Future<Map<String, dynamic>> acceptBooking(String bookingId, {String? idempotencyKey}) async {
    try {
      debugPrint("CALLING FUNCTION: technicianAcceptBooking");
      final HttpsCallable callable = _functions.httpsCallable('technicianAcceptBooking');
      final payload = {
        'bookingId': bookingId,
        'action': 'accept',
      };
      
      // Add idempotency key if provided
      if (idempotencyKey != null) {
        payload['idempotencyKey'] = idempotencyKey;
      }
      
      final result = await callable.call(payload);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error accepting booking: $e');
      rethrow;
    }
  }

  /// NEW FLOW: Reject a booking (technician declines)
  Future<Map<String, dynamic>> rejectBooking(String bookingId, {String? reason, String? idempotencyKey}) async {
    try {
      debugPrint("CALLING FUNCTION: technicianRejectBooking");
      final HttpsCallable callable = _functions.httpsCallable('technicianRejectBooking');
      final payload = {
        'bookingId': bookingId,
        'action': 'reject',
        'rejectionReason': reason,
      };
      
      // Add idempotency key if provided
      if (idempotencyKey != null) {
        payload['idempotencyKey'] = idempotencyKey;
      }
      
      final result = await callable.call(payload);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error rejecting booking: $e');
      rethrow;
    }
  }

  Future<void> sendQuote({
    required String bookingId,
    required String technicianId,
    required String technicianName,
    required double price,
    required DateTime date,
    required String time,
    String? note,
  }) async {
    debugPrint("CALLING FUNCTION: updateBookingStatusNew");
    await _functions.httpsCallable('updateBookingStatusNew').call({
      'bookingId': bookingId,
      'status': 'quote_sent',
      'price': price,
      'scheduledAt': date.toIso8601String(),
      'scheduledTime': time,
      'note': note,
    });
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _functions.httpsCallable('updateBookingStatusNew').call({
      'bookingId': bookingId,
      'status': status,
    });
  }

  Future<Map<String, dynamic>> markWorkCompleted(String bookingId) async {
    debugPrint("CALLING FUNCTION: completeService");
    final result = await _functions.httpsCallable('completeService').call({
      'bookingId': bookingId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> confirmQRPayment({
    required String bookingId,
    required String customerId,
    required double amount,
  }) async {
    final result = await _functions.httpsCallable('confirmQRPayment').call({
      'bookingId': bookingId,
      'customerId': customerId,
      'amount': amount,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<void> claimBooking(String bookingId) async {
    await _functions.httpsCallable('claimBooking').call({
      'bookingId': bookingId,
    });
  }

  Future<Booking?> getBooking(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return null;
    return Booking.fromFirestore(doc);
  }
}
