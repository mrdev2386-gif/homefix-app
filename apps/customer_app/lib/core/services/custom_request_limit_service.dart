import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomRequestLimitService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static const int maxActiveRequests = 2;

  static const List<String> activeStatuses = [
    'pending_admin_review',
    'approved',
    'technician_assigned',
    'accepted',
    'in_progress',
  ];

  static Future<int> getActiveRequestCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('custom_requests')
          .where('customerId', isEqualTo: user.uid)
          .where('status', whereIn: activeStatuses)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting active request count: $e');
      return 0;
    }
  }

  static Future<bool> canCreateNewRequest() async {
    final count = await getActiveRequestCount();
    return count < maxActiveRequests;
  }

  static Stream<int> streamActiveRequestCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('custom_requests')
        .where('customerId', isEqualTo: user.uid)
        .where('status', whereIn: activeStatuses)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
