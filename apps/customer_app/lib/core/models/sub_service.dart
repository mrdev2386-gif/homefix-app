import 'package:cloud_firestore/cloud_firestore.dart';

class SubService {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;
  final int order;
  final bool isActive;

  const SubService({
    required this.id,
    required this.name,
    this.imageUrl,
    this.price = 0,
    this.order = 0,
    this.isActive = true,
  });

  factory SubService.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    final String id = doc.id;
    final String name = (data['name'] ?? data['title'] ?? 'Sub Service').toString();
    final String? imageUrl = data['imageUrl'] != null 
        ? (data['imageUrl'] as String).trim()
        : null;
    
    double price = 0.0;
    final dynamic priceData = data['price'] ?? data['basePrice'] ?? 0;
    if (priceData is num) {
      price = priceData.toDouble();
    } else if (priceData is String) {
      price = double.tryParse(priceData) ?? 0.0;
    }

    int order = 0;
    final dynamic orderData = data['order'] ?? 0;
    if (orderData is num) {
      order = orderData.toInt();
    } else if (orderData is String) {
      order = int.tryParse(orderData) ?? 0;
    }

    final bool isActive = data['isActive'] ?? true;

    return SubService(
      id: id,
      name: name,
      imageUrl: imageUrl,
      price: price,
      order: order,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl ?? '',
      'price': price,
      'order': order,
      'isActive': isActive,
    };
  }

  /// Get effective image URL with fallback
  String? getEffectiveImageUrl() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl;
    }
    return null;
  }
}
