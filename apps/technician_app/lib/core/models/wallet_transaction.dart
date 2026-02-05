import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransaction {
  final String txnId;
  final String type; // credit, debit
  final double amount;
  final String reason; // referral_reward, coupon, refund, booking_payment
  final String? relatedBookingId;
  final DateTime createdAt;

  WalletTransaction({
    required this.txnId,
    required this.type,
    required this.amount,
    required this.reason,
    this.relatedBookingId,
    required this.createdAt,
  });

  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WalletTransaction(
      txnId: doc.id,
      type: data['type'] ?? 'credit',
      amount: (data['amount'] ?? 0.0).toDouble(),
      reason: data['reason'] ?? '',
      relatedBookingId: data['relatedBookingId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'reason': reason,
      'relatedBookingId': relatedBookingId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
