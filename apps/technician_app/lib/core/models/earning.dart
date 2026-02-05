
import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianEarning {
  final String id;
  final String bookingId;
  final List<String> serviceIds;
  final double totalAmount;
  final double commissionAmount;
  final double technicianAmount;
  final String status; // pending, paid
  final DateTime createdAt;

  TechnicianEarning({
    required this.id,
    required this.bookingId,
    required this.serviceIds,
    required this.totalAmount,
    required this.commissionAmount,
    required this.technicianAmount,
    required this.status,
    required this.createdAt,
  });

  factory TechnicianEarning.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TechnicianEarning(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      serviceIds: List<String>.from(data['serviceIds'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      commissionAmount: (data['commissionAmount'] ?? 0.0).toDouble(),
      technicianAmount: (data['technicianAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
