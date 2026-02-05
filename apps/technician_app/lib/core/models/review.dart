import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String reviewId;
  final String bookingId;
  final String customerId;
  final String technicianId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.reviewId,
    required this.bookingId,
    required this.customerId,
    required this.technicianId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Review(
      reviewId: doc.id,
      bookingId: data['bookingId'] ?? '',
      customerId: data['customerId'] ?? '',
      technicianId: data['technicianId'] ?? '',
      rating: (data['rating'] is String) ? (double.tryParse(data['rating']) ?? 0.0) : (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'technicianId': technicianId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
