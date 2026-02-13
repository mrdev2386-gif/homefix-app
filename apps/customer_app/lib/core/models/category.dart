import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String? imageUrl;
  final int order;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl,
    this.order = 0,
    this.isActive = true,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    final String id = doc.id;
    final String name = (data['name'] ?? data['title'] ?? 'Category').toString();
    final String? imageUrl = data['imageUrl'] != null 
        ? (data['imageUrl'] as String).trim()
        : null;
    
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

  /// Get fallback image URL based on category name
  String getFallbackImageUrl() {
    final nameLower = name.toLowerCase();
    
    if (nameLower.contains('ac') || nameLower.contains('air')) {
      return 'https://images.unsplash.com/photo-1631545806609-5adb40c6e3eb?w=400&q=80';
    } else if (nameLower.contains('plumb')) {
      return 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400&q=80';
    } else if (nameLower.contains('electric')) {
      return 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=400&q=80';
    } else if (nameLower.contains('clean') || nameLower.contains('house')) {
      return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80';
    } else if (nameLower.contains('appliance') || nameLower.contains('repair')) {
      return 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&q=80';
    } else if (nameLower.contains('salon') || nameLower.contains('beauty')) {
      return 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80';
    } else if (nameLower.contains('pest')) {
      return 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=400&q=80';
    } else if (nameLower.contains('paint')) {
      return 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80';
    } else if (nameLower.contains('carpenter') || nameLower.contains('wood')) {
      return 'https://images.unsplash.com/photo-1611486212557-88be5ff6f941?w=400&q=80';
    } else if (nameLower.contains('water') || nameLower.contains('ro')) {
      return 'https://images.unsplash.com/photo-1538300342682-cf57afb97285?w=400&q=80';
    }
    // Default category placeholder
    return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80';
  }
}
