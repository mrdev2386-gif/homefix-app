import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String title; // Home, Work, etc.
  final String name;
  final String phone;
  final String fullAddress;
  final String landmark;
  final String city;
  final String pincode;
  final double lat;
  final double lng;
  final bool isDefault;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.title,
    required this.name,
    required this.phone,
    required this.fullAddress,
    required this.landmark,
    required this.city,
    required this.pincode,
    required this.lat,
    required this.lng,
    required this.isDefault,
    required this.createdAt,
  });

  factory Address.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Address(
      id: doc.id,
      title: data['title'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      fullAddress: data['fullAddress'] ?? '',
      landmark: data['landmark'] ?? '',
      city: data['city'] ?? '',
      pincode: data['pincode'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'name': name,
      'phone': phone,
      'fullAddress': fullAddress,
      'landmark': landmark,
      'city': city,
      'pincode': pincode,
      'lat': lat,
      'lng': lng,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
