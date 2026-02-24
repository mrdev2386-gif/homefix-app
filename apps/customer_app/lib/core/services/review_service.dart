import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> submitReview(Review review) async {
    final batch = _db.batch();
    final reviewRef = _db.collection('reviews').doc();
    final techRef = _db.collection('technicians').doc(review.technicianId);

    // Add review
    batch.set(reviewRef, review.toMap());

    // Update technician stats
    // Note: In real production, this should be done via Cloud Functions to prevent race conditions
    final techDoc = await techRef.get();
    if (techDoc.exists) {
      final double currentRating = (techDoc.data()?['ratingAvg'] ?? 4.5).toDouble();
      final int currentCount = techDoc.data()?['ratingCount'] ?? 10;
      final int jobsDone = techDoc.data()?['jobsDone'] ?? 10;

      final double newRating = ((currentRating * currentCount) + review.rating) / (currentCount + 1);

      batch.update(techRef, {
        'ratingAvg': newRating,
        'ratingCount': FieldValue.increment(1),
        'jobsDone': jobsDone + 1, // Optional: if jobsDone is also updated here
      });
    }

    await batch.commit();
  }

  Stream<List<Review>> getTechnicianReviews(String technicianId) {
    return _db
        .collection('reviews')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }
}
