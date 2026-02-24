import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String label; // Home, Office, Other
  final String name;
  final String phone;
  final String fullAddress;
  final String landmark;
  final String city;
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
      fullAddress: data['fullAddress'] ?? '',
      landmark: data['landmark'] ?? '',
      city: data['city'] ?? '',
      pincode: data['pincode'] ?? '',
      latitude: (data['latitude'] ?? data['lat'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? data['lng'] ?? 0.0).toDouble(),
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'title': label, // Keep title for compatibility
      'name': name,
      'phone': phone,
      'fullAddress': fullAddress,
      'landmark': landmark,
      'city': city,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'lat': latitude, // Keep lat for compatibility
      'lng': longitude, // Keep lng for compatibility
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
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
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
