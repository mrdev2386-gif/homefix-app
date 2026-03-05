import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String label; // Home, Office, Other
  final String name;
  final String phone;
  final String fullAddress;
  final String landmark;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.fullAddress,
    required this.landmark,
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.createdAt,
  });

  factory Address.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Address(
      id: doc.id,
      label: data['label'] ?? data['title'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      fullAddress: data['fullAddress'] ?? data['addressLine'] ?? '',
      landmark: data['landmark'] ?? '',
      city: data['city'] ?? '',
      district: data['district'] ?? '',
      state: data['state'] ?? '',
      pincode: data['pincode'] ?? '',
      latitude: (data['latitude'] ?? data['lat'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? data['lng'] ?? 0.0).toDouble(),
      isDefault: data['isDefault'] ?? data['isPrimary'] ?? false,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'title': label,
      'name': name,
      'phone': phone,
      'fullAddress': fullAddress,
      'addressLine': fullAddress,
      'landmark': landmark,
      'city': city,
      'district': district,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'lat': latitude,
      'lng': longitude,
      'isDefault': isDefault,
      'isPrimary': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Address copyWith({
    String? id,
    String? label,
    String? name,
    String? phone,
    String? fullAddress,
    String? landmark,
    String? city,
    String? district,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      fullAddress: fullAddress ?? this.fullAddress,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
