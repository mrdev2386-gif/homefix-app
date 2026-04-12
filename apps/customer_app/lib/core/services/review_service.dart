import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/firebase_constants.dart';

class ReviewService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<bool> hasReview(String bookingId) async {
    if (bookingId.isEmpty) return false;
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.reviewsCollection)
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ReviewService] hasReview error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getReview(String bookingId) async {
    if (bookingId.isEmpty) return null;
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.reviewsCollection)
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ReviewService] getReview error: $e');
      rethrow;
    }
  }

  static Stream<List<Map<String, dynamic>>> getTechnicianReviews(
    String technicianId, {
    int limit = 15,
    DocumentSnapshot? startAfter,
  }) {
    if (technicianId.isEmpty) return Stream.value([]);
    Query query = _firestore
        .collection(FirebaseConstants.reviewsCollection)
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return query
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList())
        .handleError((e) {
      if (kDebugMode) debugPrint('❌ [ReviewService] getTechnicianReviews error: $e');
      throw e;
    });
  }

  static Future<Map<String, dynamic>?> getTechnicianRating(String technicianId) async {
    if (technicianId.isEmpty) return null;
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.techniciansCollection)
          .doc(technicianId)
          .get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return {
        'averageRating': data['averageRating'] ?? 0.0,
        'totalReviews': data['totalReviews'] ?? 0,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ReviewService] getTechnicianRating error: $e');
      rethrow;
    }
  }
}
