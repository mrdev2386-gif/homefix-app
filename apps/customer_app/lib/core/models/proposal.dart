import 'package:cloud_firestore/cloud_firestore.dart';

class Proposal {
  final String id;
  final String requestId;
  final String technicianId;
  final String technicianName;
  final String? technicianPhotoUrl;
  final double quotedPrice;
  final DateTime proposedDateTime;
  final String message;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  Proposal({
    required this.id,
    required this.requestId,
    required this.technicianId,
    required this.technicianName,
    this.technicianPhotoUrl,
    required this.quotedPrice,
    required this.proposedDateTime,
    required this.message,
    this.status = 'pending',
    required this.createdAt,
  });

  factory Proposal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Proposal(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      technicianId: data['technicianId'] ?? '',
      technicianName: data['technicianName'] ?? '',
      technicianPhotoUrl: data['technicianPhotoUrl'],
      quotedPrice: (data['quotedPrice'] ?? 0.0).toDouble(),
      proposedDateTime: (data['proposedDateTime'] as Timestamp).toDate(),
      message: data['message'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'technicianPhotoUrl': technicianPhotoUrl,
      'quotedPrice': quotedPrice,
      'proposedDateTime': Timestamp.fromDate(proposedDateTime),
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
