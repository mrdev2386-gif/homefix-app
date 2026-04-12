import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/firebase_constants.dart';

class TicketService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: FirebaseConstants.region);

  Future<void> createTicket(
    String customerId,
    String bookingId,
    String category,
    String description,
  ) async {
    if (customerId.isEmpty) throw Exception('customerId is required');
    if (category.trim().isEmpty) throw Exception('category is required');
    if (description.trim().isEmpty) throw Exception('description is required');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);

    final callable = _functions.httpsCallable('createSupportTicket');
    try {
      await callable.call({
        'bookingId': bookingId,
        'category': category.trim(),
        'description': description.trim().substring(
            0, description.trim().length > 1000 ? 1000 : description.trim().length),
      });
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        await user.getIdToken(true);
        await _functions.httpsCallable('createSupportTicket').call({
          'bookingId': bookingId,
          'category': category.trim(),
          'description': description.trim(),
        });
      } else {
        if (kDebugMode) debugPrint('❌ [TicketService] createTicket failed: $e');
        rethrow;
      }
    }
  }

  Stream<List<Map<String, dynamic>>> getCustomerTickets(String customerId) {
    if (customerId.isEmpty) return Stream.value([]);
    return _db
        .collection(FirebaseConstants.supportTicketsCollection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList())
        .handleError((e) {
      if (kDebugMode) debugPrint('❌ [TicketService] getCustomerTickets error: $e');
      throw e;
    });
  }
}
