import 'package:cloud_firestore/cloud_firestore.dart';

class TicketService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createTicket(String customerId, String bookingId, String category, String description) async {
    await _db.collection('support_tickets').add({
      'customerId': customerId,
      'bookingId': bookingId,
      'category': category,
      'description': description,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getCustomerTickets(String customerId) {
    return _db
        .collection('support_tickets')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}
