
import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianPayout {
  final String id;
  final double amount;
  final String status; // initiated, success, failed
  final String? razorpayPayoutId;
  final String? error;
  final DateTime createdAt;

  TechnicianPayout({
    required this.id,
    required this.amount,
    required this.status,
    this.razorpayPayoutId,
    this.error,
    required this.createdAt,
  });

  factory TechnicianPayout.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TechnicianPayout(
      id: doc.id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'initiated',
      razorpayPayoutId: data['razorpayPayoutId'],
      error: data['error'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
