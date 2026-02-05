import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/booking.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Stream<List<Booking>> getAvailableBookings(List<String> skills) {
    if (skills.isEmpty) return Stream.value([]);
    
    return _db.collection('bookings')
        .where('assignedTechnicianId', isNull: true)
        .where('status', whereIn: ['pending', 'confirmed'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();
        });
  }

  Stream<List<Booking>> getAssignedBookings(String techId) {
    return _db.collection('bookings')
        .where('assignedTechnicianId', isEqualTo: techId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
          bookings.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
          return bookings;
        });
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
}
