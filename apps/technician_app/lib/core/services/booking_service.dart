import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/booking.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// NEW FLOW: Get pending bookings that need technician response
  /// Status: technician_pending - admin approved, waiting for technician
  Stream<List<Booking>> getPendingBookings(String techId) {
    return _db.collection('bookings')
        .where('technicianId', isEqualTo: techId)
        .where('status', isEqualTo: 'technician_pending')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();
        }).handleError((e) {
          debugPrint('❌ [BookingService] Error fetching pending bookings: $e');
          return <Booking>[];
        });
  }

  /// NEW FLOW: Get bookings that are awaiting payment
  /// Status: awaiting_payment - technician accepted, waiting for customer payment
  Stream<List<Booking>> getAwaitingPaymentBookings(String techId) {
    return _db.collection('bookings')
        .where('technicianId', isEqualTo: techId)
        .where('status', isEqualTo: 'awaiting_payment')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();
        }).handleError((e) {
          debugPrint('❌ [BookingService] Error fetching awaiting payment bookings: $e');
          return <Booking>[];
        });
  }

  /// Legacy: Get available bookings (no technician assigned)
  /// Used for instant booking / auto-assign flow
  Stream<List<Booking>> getAvailableBookings(List<String> skills) {
    if (skills.isEmpty) return Stream.value([]);
    
    return _db.collection('bookings')
        .where('assignedTechnicianId', isNull: true)
        .where('status', whereIn: ['pending', 'confirmed'])
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();
        }).handleError((e) {
          debugPrint('❌ [BookingService] Error fetching available bookings: $e');
          return <Booking>[];
        });
  }

  /// Get bookings assigned to this technician (all statuses)
  Stream<List<Booking>> getAssignedBookings(String techId) {
    return _db.collection('bookings')
        .where('technicianId', isEqualTo: techId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
          bookings.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
          return bookings;
        }).handleError((e) {
          debugPrint('❌ [BookingService] Error fetching assigned bookings: $e');
          return <Booking>[];
        });
  }

  /// NEW FLOW: Accept a booking (technician accepts)
  Future<Map<String, dynamic>> acceptBooking(String bookingId) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('technicianRespondBooking');
      final result = await callable.call({
        'bookingId': bookingId,
        'action': 'accept',
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error accepting booking: $e');
      rethrow;
    }
  }

  /// NEW FLOW: Reject a booking (technician declines)
  Future<Map<String, dynamic>> rejectBooking(String bookingId, {String? reason}) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('technicianRespondBooking');
      final result = await callable.call({
        'bookingId': bookingId,
        'action': 'reject',
        'rejectionReason': reason,
      });
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
    await _functions.httpsCallable('sendQuote').call({
      'bookingId': bookingId,
      'price': price,
      'scheduledAt': date.toIso8601String(),
      'scheduledTime': time,
      'note': note,
    });
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _functions.httpsCallable('updateBookingStatus').call({
      'bookingId': bookingId,
      'status': status,
    });
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
