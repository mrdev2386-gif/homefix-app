
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransaction {
  final String txnId;
  final String userId;
  final double amount;
  final String type;
  final String? bookingId;
  final String description;
  final DateTime createdAt;
  final String status;

  WalletTransaction({
    required this.txnId,
    required this.userId,
    required this.amount,
    required this.type,
    this.bookingId,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransaction(
      txnId: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] ?? '',
      bookingId: data['bookingId'],
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'completed',
    );
  }
}
