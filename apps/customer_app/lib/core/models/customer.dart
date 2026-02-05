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
  final String? defaultAddress;
  final List<Map<String, dynamic>> addresses;
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
    this.defaultAddress,
    this.addresses = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return Customer(
      uid: (data['uid'] ?? doc.id).toString(),
      name: (data['name'] ?? 'HomeFix User').toString(),
      phone: (data['phone'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      photoUrl: data['photoUrl']?.toString(),
      referralCode: (data['referralCode'] ?? '').toString(),
      referredBy: data['referredBy']?.toString(),
      walletBalance: double.tryParse((data['walletBalance'] ?? 0.0).toString()) ?? 0.0,
      fcmToken: data['fcmToken']?.toString(),
      defaultAddress: data['defaultAddress']?.toString(),
      addresses: data['addresses'] != null 
          ? List<Map<String, dynamic>>.from(data['addresses']) 
          : [],
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
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
      'defaultAddress': defaultAddress,
      'addresses': addresses,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
