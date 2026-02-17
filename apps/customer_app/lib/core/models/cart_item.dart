import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String categoryId;
  final String serviceId;
  final String serviceName;
  final String serviceImage;
  final double price;
  final int quantity;
  final double totalPrice;
  final DateTime? scheduledAt;

  CartItem({
    required this.id,
    required this.categoryId,
    required this.serviceId,
    required this.serviceName,
    required this.serviceImage,
    required this.price,
    this.quantity = 1,
    required this.totalPrice,
    this.scheduledAt,
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CartItem(
      id: doc.id,
      categoryId: (data['categoryId'] ?? '').toString(),
      serviceId: (data['serviceId'] ?? '').toString(),
      serviceName: (data['serviceName'] ?? '').toString(),
      serviceImage: (data['serviceImage'] ?? '').toString(),
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: (data['quantity'] ?? 1).toInt(),
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      scheduledAt: data['scheduledAt'] != null ? (data['scheduledAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceImage': serviceImage,
      'price': price,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
    };
  }

  CartItem copyWith({
    String? id,
    String? categoryId,
    String? serviceId,
    String? serviceName,
    String? serviceImage,
    double? price,
    int? quantity,
    double? totalPrice,
    DateTime? scheduledAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      serviceImage: serviceImage ?? this.serviceImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      scheduledAt: scheduledAt ?? this.scheduledAt,
    );
  }
}
