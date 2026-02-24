import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? phone;
  final String? name;
  final String? photoUrl;
  final DateTime? createdAt;
  final String role; // customer or technician
  final String? fcmToken;
  final List<Map<String, dynamic>> addresses;
  final String? referralCode;
  final String? referredBy;
  final double walletBalance;
  final List<String> favoriteServices;
  final bool isOnboarded;
  final String? defaultAddress;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final bool isBlocked;
  final String? district;
  final bool profileCompleted;

  UserModel({
    required this.uid,
    this.email,
    this.phone,
    this.name,
    this.photoUrl,
    this.createdAt,
    this.role = 'customer',
    this.fcmToken,
    this.addresses = const [],
    this.referralCode,
    this.referredBy,
    this.walletBalance = 0.0,
    this.favoriteServices = const [],
    this.isOnboarded = false,
    this.defaultAddress,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isBlocked = false,
    this.district,
    this.profileCompleted = false,
  });

  // Getter for convenience in UI
  String? get displayName => name;
  String? get phoneNumber => phone;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return UserModel(uid: doc.id);
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return UserModel(
      uid: doc.id,
      email: (data['email'] ?? '').toString(),
      phone: (data['phone'] ?? data['phoneNumber'] ?? '').toString(),
      name: (data['name'] ?? data['displayName'] ?? '').toString(),
      photoUrl: (data['photoUrl'] ?? data['photoURL'] ?? '').toString(),
      createdAt: data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : null,
      role: (data['role'] ?? 'customer').toString().toLowerCase(),
      fcmToken: (data['fcmToken'] ?? '').toString(),
      addresses: data['addresses'] != null ? List<Map<String, dynamic>>.from(data['addresses']) : [],
      referralCode: (data['referralCode'] ?? '').toString(),
      referredBy: (data['referredBy'] ?? '').toString(),
      walletBalance: double.tryParse((data['walletBalance'] ?? 0.0).toString()) ?? 0.0,
      favoriteServices: data['favoriteServices'] != null ? List<String>.from(data['favoriteServices']) : [],
      isOnboarded: data['isOnboarded'] ?? false,
      defaultAddress: (data['defaultAddress'] ?? '').toString(),
      latitude: double.tryParse((data['latitude'] ?? 0.0).toString()),
      longitude: double.tryParse((data['longitude'] ?? 0.0).toString()),
      isVerified: data['isVerified'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
      district: (data['district'] ?? '').toString(),
      profileCompleted: data['profileCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phone': phone,
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'role': role,
      'fcmToken': fcmToken,
      'addresses': addresses,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'walletBalance': walletBalance,
      'favoriteServices': favoriteServices,
      'isOnboarded': isOnboarded,
      'defaultAddress': defaultAddress,
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'district': district,
      'profileCompleted': profileCompleted,
    };
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? email,
    String? phone,
    double? walletBalance,
    List<String>? favoriteServices,
    bool? isOnboarded,
    String? defaultAddress,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isBlocked,
    String? fcmToken,
    List<Map<String, dynamic>>? addresses,
    String? district,
    bool? profileCompleted,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      role: role,
      fcmToken: fcmToken ?? this.fcmToken,
      addresses: addresses ?? this.addresses,
      referralCode: referralCode,
      referredBy: referredBy,
      walletBalance: walletBalance ?? this.walletBalance,
      favoriteServices: favoriteServices ?? this.favoriteServices,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      district: district ?? this.district,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }
}
