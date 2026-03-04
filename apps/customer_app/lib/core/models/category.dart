import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final int order;
  final bool isActive;
  final int serviceCount; // Number of services in this category

  const Category({
    required this.id,
    required this.name,
    this.imageUrl = AppConstants.fallbackServiceImage,
    this.order = 0,
    this.isActive = true,
    this.serviceCount = 0,
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
      order = (orderData.isFinite ? orderData : 0).toInt();
    } else if (orderData is String) {
      order = int.tryParse(orderData) ?? 0;
    }

    final bool isActive = data['isActive'] ?? true;
    
    // Get service count if available
    int serviceCount = 0;
    final dynamic countData = data['serviceCount'];
    if (countData is num) {
      serviceCount = countData.toInt();
    } else if (countData is String) {
      serviceCount = int.tryParse(countData) ?? 0;
    }

    return Category(
      id: id,
      name: name,
      imageUrl: imageUrl,
      order: order,
      isActive: isActive,
      serviceCount: serviceCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl ?? '',
      'order': order,
      'isActive': isActive,
      'serviceCount': serviceCount,
    };
  }

  /// copyWith — required for enrichWithCounts
  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? order,
    bool? isActive,
    int? serviceCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      serviceCount: serviceCount ?? this.serviceCount,
    );
  }

  /// Get fallback image URL - returns null to show local placeholder
  /// DO NOT use hardcoded network URLs - violates unique image requirement
  String? getFallbackImageUrl() {
    return null;
  }
}
