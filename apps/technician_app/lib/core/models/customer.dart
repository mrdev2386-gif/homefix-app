import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String? photoUrl;
  final String referralCode;
  final String? referredBy;
  final double walletBalance;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    this.photoUrl,
    required this.referralCode,
    this.referredBy,
    required this.walletBalance,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Customer(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      referralCode: data['referralCode'] ?? '',
      referredBy: data['referredBy'],
      walletBalance: (data['walletBalance'] ?? 0.0).toDouble(),
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'walletBalance': walletBalance,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
