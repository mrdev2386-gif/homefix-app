import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final int order;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl = AppConstants.fallbackServiceImage,
    this.order = 0,
    this.isActive = true,
  });

  // Aliases for user requested fields and legacy code compatibility
  String get title => name;
  String get iconUrl => imageUrl ?? '';
  bool get isNew => (order == 0); // Logic for 'New' badge: lowest order or recent

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    final String id = doc.id;
    final String name = (data['name'] ?? data['title'] ?? 'Category').toString();
    
    // AUDIT: Prioritize imageUrl, fallback to legacy 'iconUrl', 'image', or 'thumbnail'
    // AUDIT: Strict mapping - never allow null
    String? imageUrl = (data['imageUrl'] ?? data['iconUrl'] ?? data['image'] ?? data['thumbnail'])?.toString().trim();
    
    if (imageUrl == null || imageUrl.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ [Category Model] No image for ${doc.id} (name: $name). Using global fallback.');
      }
      imageUrl = AppConstants.fallbackServiceImage;
    }
    
    int order = 0;
    final dynamic orderData = data['order'] ?? 0;
    if (orderData is num) {
      order = orderData.toInt();
    } else if (orderData is String) {
      order = int.tryParse(orderData) ?? 0;
    }

    final bool isActive = data['isActive'] ?? true;

    return Category(
      id: id,
      name: name,
      imageUrl: imageUrl,
      order: order,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl ?? '',
      'order': order,
      'isActive': isActive,
    };
  }

  /// Get fallback image URL - returns null to show local placeholder
  /// DO NOT use hardcoded network URLs - violates unique image requirement
  String? getFallbackImageUrl() {
    return null;
  }
}
