import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<bool> hasReview(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking review: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getReview(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    } catch (e) {
      print('Error fetching review: $e');
      return null;
    }
  }

  static Stream<List<Map<String, dynamic>>> getTechnicianReviews(String technicianId) {
    return _firestore
        .collection('reviews')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  static Future<Map<String, dynamic>?> getTechnicianRating(String technicianId) async {
    try {
      final doc = await _firestore.collection('technicians').doc(technicianId).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      return {
        'averageRating': data['averageRating'] ?? 0.0,
        'totalReviews': data['totalReviews'] ?? 0,
      };
    } catch (e) {
      print('Error fetching technician rating: $e');
      return null;
    }
  }
}
