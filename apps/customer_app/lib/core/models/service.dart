import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class HomeService {
  final String id;
  final String key;
  final String title;
  final String imageAssetPath;
  final String imageUrl;
  final String description;
  final double basePrice;
  final bool isActive;
  final String category;
  final bool isTopService;
  final int order;
  final double rating;
  final int reviewCount;
  final bool isTrending;
  final String duration;
  final DateTime createdAt;

  // Aliases for user requested fields
  String get name => title;
  double get price => basePrice;

  HomeService({
    required this.id,
    required this.key,
    required this.title,
    required this.imageAssetPath,
    this.imageUrl = AppConstants.fallbackServiceImage,
    this.description = '',
    required this.basePrice,
    required this.isActive,
    required this.category,
    required this.isTopService,
    required this.order,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.isTrending = false,
    this.duration = '1 hour',
    required this.createdAt,
  });

  static HomeService? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final String id = doc.id;

    // MANDATORY CATEGORY CHECK - FIX FOR SERVICE_COUNT 0
    final categoryId = data['category'] ?? data['categoryId'];
    if (categoryId == null || categoryId.toString().isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ SERVICE SKIPPED — missing categoryId → $id');
      }
      return null;
    }

    // DEBUG (Temporary as requested)
    if (kDebugMode) {
      debugPrint(
        'SERVICE DEBUG → id=$id category=$categoryId name=${data['name'] ?? data['title']}',
      );
    }

    // Map Firestore fields with fallbacks - Ensure ONLY imageUrl is used for UI
    final String key = (data['id'] ?? data['serviceId'] ?? data['key'] ?? id).toString();
    final String title = (data['name'] ?? data['title'] ?? 'Service').toString();
    
    // AUDIT: Strict mapping - never allow null
    String? imageUrl = (data['imageUrl'] ?? data['image'] ?? data['thumbnail'] ?? data['bannerUrl'] ?? data['imageAssetPath'])?.toString().trim();
    
    if (imageUrl == null || imageUrl.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ [HomeService Model] No image found for $id (title: $title). Using global fallback.');
      }
      imageUrl = AppConstants.fallbackServiceImage;
    }
    
    // SAFE NUMBER PARSING
    double price = 0.0;
    final dynamic priceData = data['price'] ?? data['basePrice'];
    if (priceData is num) {
      price = priceData.toDouble();
    } else if (priceData is String) {
      price = double.tryParse(priceData) ?? 0.0;
    }

    final bool isActive = data['isActive'] ?? true;
    final String finalCategory = categoryId.toString();
    final bool isTop = data['isTopService'] ?? false;
    
    int order = 0;
    final dynamic orderData = data['order'] ?? 0;
    if (orderData is num) {
      order = orderData.toInt();
    } else if (orderData is String) {
      order = int.tryParse(orderData) ?? 0;
    }

    double rating = 0.0;
    final dynamic ratingData = data['rating'] ?? data['ratingValue'];
    if (ratingData is num) {
      rating = ratingData.toDouble();
    } else if (ratingData is String) {
      rating = double.tryParse(ratingData) ?? 0.0;
    }

    int reviews = 0;
    final dynamic reviewsData = data['reviewCount'] ?? data['reviews'] ?? 0;
    if (reviewsData is num) {
      reviews = reviewsData.toInt();
    } else if (reviewsData is String) {
      reviews = int.tryParse(reviewsData) ?? 0;
    }

    final bool isTrending = data['isTrending'] ?? false;
    final String duration = (data['duration'] ?? '1 hour').toString();
    
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    return HomeService(
      id: id,
      key: key,
      title: title,
      imageAssetPath: '', // Deprecated: No longer used for network images
      imageUrl: imageUrl,
      description: (data['description'] ?? '').toString(),
      basePrice: price,
      isActive: isActive,
      category: finalCategory,
      isTopService: isTop,
      order: order,
      rating: rating,
      reviewCount: reviews,
      isTrending: isTrending,
      duration: duration,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': key,
      'name': title,
      'imageUrl': imageUrl,
      'description': description,
      'price': basePrice,
      'isActive': isActive,
      'category': category,
      'isTopService': isTopService,
      'order': order,
      'rating': rating,
      'reviewCount': reviewCount,
      'isTrending': isTrending,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Check if service has valid image URL
  bool get hasValidImageUrl {
    final url = imageUrl.trim();
    return url.startsWith('http://') || url.startsWith('https://') || url.startsWith('assets/');
  }
}
