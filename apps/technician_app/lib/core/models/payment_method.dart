import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethod {
  final String id;
  final String type; // card, upi
  final String label;
  final String? upiId;
  final String? last4;
  final String holderName;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.upiId,
    this.last4,
    required this.holderName,
    required this.createdAt,
  });

  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PaymentMethod(
      id: doc.id,
      type: data['type'] ?? '',
      label: data['label'] ?? '',
      upiId: data['upiId'],
      last4: data['last4'],
      holderName: data['holderName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'label': label,
      'upiId': upiId,
      'last4': last4,
      'holderName': holderName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
