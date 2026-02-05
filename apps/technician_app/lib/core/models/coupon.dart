import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id;
  final String code;
  final String discountType; // flat, percent
  final double value;
  final double minOrderValue;
  final bool isActive;
  final DateTime? expiresAt;

  Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    required this.minOrderValue,
    required this.isActive,
    this.expiresAt,
  });

  factory Coupon.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Coupon(
      id: doc.id,
      code: data['code'] ?? '',
      discountType: data['discountType'] ?? 'flat',
      value: (data['value'] ?? 0.0).toDouble(),
      minOrderValue: (data['minOrderValue'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? false,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discountType': discountType,
      'value': value,
      'minOrderValue': minOrderValue,
      'isActive': isActive,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }
}
