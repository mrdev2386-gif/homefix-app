import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Custom Request Model for Urban Company-style custom service requests
class CustomRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String categoryId;
  final String? categoryName;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String preferredDate;
  final String preferredTime;
  final String addressId;
  final AddressInfo address;
  final double? budgetMin;
  final double? budgetMax;
  final Urgency urgency;
  final RequestStatus status;
  final String? technicianAssigned;
  final String? technicianName;
  final String? technicianPhone;
  final String? bookingId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;

  CustomRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.categoryId,
    this.categoryName,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.preferredDate,
    required this.preferredTime,
    required this.addressId,
    required this.address,
    this.budgetMin,
    this.budgetMax,
    required this.urgency,
    required this.status,
    this.technicianAssigned,
    this.technicianName,
    this.technicianPhone,
    this.bookingId,
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
  });

  factory CustomRequest.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return CustomRequest(
      id: documentId ?? map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      preferredDate: map['preferredDate'] ?? '',
      preferredTime: map['preferredTime'] ?? '',
      addressId: map['addressId'] ?? '',
      address: AddressInfo.fromMap(map['address'] ?? {}),
      budgetMin: (map['budgetMin'] as num?)?.toDouble(),
      budgetMax: (map['budgetMax'] as num?)?.toDouble(),
      urgency: Urgency.fromString(map['urgency'] ?? 'normal'),
      status: RequestStatus.fromString(map['status'] ?? 'pending'),
      technicianAssigned: map['technicianAssigned'],
      technicianName: map['technicianName'],
      technicianPhone: map['technicianPhone'],
      bookingId: map['bookingId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'preferredDate': preferredDate,
      'preferredTime': preferredTime,
      'addressId': addressId,
      'address': address.toMap(),
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'urgency': urgency.value,
      'status': status.value,
      'technicianAssigned': technicianAssigned,
      'technicianName': technicianName,
      'technicianPhone': technicianPhone,
      'bookingId': bookingId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'acceptedAt': acceptedAt,
    };
  }

  /// For creating a new request (client to function)
  Map<String, dynamic> toCreateRequest() {
    return {
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'preferredDate': preferredDate,
      'preferredTime': preferredTime,
      'addressId': addressId,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'urgency': urgency.value,
    };
  }
}

/// Address information for the request
class AddressInfo {
  final String address;
  final GeoPoint? coordinates;
  final String? city;
  final String? pinCode;
  final String? label;

  AddressInfo({
    required this.address,
    this.coordinates,
    this.city,
    this.pinCode,
    this.label,
  });

  factory AddressInfo.fromMap(Map<String, dynamic> map) {
    return AddressInfo(
      address: map['address'] ?? '',
      coordinates: map['coordinates'],
      city: map['city'],
      pinCode: map['pinCode'],
      label: map['label'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      if (coordinates != null) 'coordinates': coordinates,
      if (city != null) 'city': city,
      if (pinCode != null) 'pinCode': pinCode,
      if (label != null) 'label': label,
    };
  }
}

/// Urgency levels for custom requests
enum Urgency {
  normal('normal', 'Normal'),
  urgent('urgent', 'Urgent'),
  emergency('emergency', 'Emergency');

  final String value;
  final String displayName;

  const Urgency(this.value, this.displayName);

  factory Urgency.fromString(String value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => Urgency.normal,
    );
  }
}

/// Status of custom requests
enum RequestStatus {
  pending('pending', 'Pending'),
  accepted('accepted', 'Accepted'),
  booked('booked', 'Booked'),
  cancelled('cancelled', 'Cancelled'),
  expired('expired', 'Expired');

  final String value;
  final String displayName;

  const RequestStatus(this.value, this.displayName);

  factory RequestStatus.fromString(String value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => RequestStatus.pending,
    );
  }
}

/// Extension for urgency color coding
extension UrgencyColor on Urgency {
  Color get color {
    switch (this) {
      case Urgency.normal:
        return Colors.green;
      case Urgency.urgent:
        return Colors.orange;
      case Urgency.emergency:
        return Colors.red;
    }
  }
}
