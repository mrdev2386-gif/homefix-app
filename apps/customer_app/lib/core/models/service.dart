import 'package:cloud_firestore/cloud_firestore.dart';

class HomeService {
  final String id;
  final String key;
  final String title;
  final String imageAssetPath;
  final String? _imageUrl;
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

  /// Get effective image URL with fallback chain:
  /// 1. imageUrl (from Firestore)
  /// 2. imageAssetPath (legacy)
  /// 3. null (will show placeholder)
  String? get imageUrl {
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return _imageUrl;
    }
    if (imageAssetPath.isNotEmpty && !imageAssetPath.startsWith('assets/')) {
      return imageAssetPath;
    }
    return null;
  }

  /// Get service-specific fallback image URL based on category
  String getFallbackImageUrl() {
    final categoryLower = category.toLowerCase();
    final titleLower = title.toLowerCase();

    if (categoryLower.contains('ac') || titleLower.contains('ac') || titleLower.contains('air')) {
      return 'https://images.unsplash.com/photo-1631545806609-5adb40c6e3eb?w=400&q=80';
    } else if (categoryLower.contains('plumb') || titleLower.contains('plumb') || titleLower.contains('pipe')) {
      return 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400&q=80';
    } else if (categoryLower.contains('electric') || titleLower.contains('electric') || titleLower.contains('wiring')) {
      return 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=400&q=80';
    } else if (categoryLower.contains('clean') || titleLower.contains('clean')) {
      return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80';
    } else if (categoryLower.contains('appliance') || titleLower.contains('appliance') || titleLower.contains('washing') || titleLower.contains('fridge')) {
      return 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&q=80';
    } else if (categoryLower.contains('repair') || titleLower.contains('repair') || titleLower.contains('fix')) {
      return 'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=400&q=80';
    } else if (categoryLower.contains('paint') || titleLower.contains('paint')) {
      return 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80';
    } else if (categoryLower.contains('carpenter') || titleLower.contains('carpenter') || titleLower.contains('wood')) {
      return 'https://images.unsplash.com/photo-1611486212557-88be5ff6f941?w=400&q=80';
    }
    // Default service placeholder
    return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80';
  }

  HomeService({
    required this.id,
    required this.key,
    required this.title,
    required this.imageAssetPath,
    String? imageUrl,
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
  }) : _imageUrl = imageUrl;

  factory HomeService.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // SAFE PARSING - MANDATORY NULL SAFETY
    final String id = doc.id;
    // Map Firestore fields with fallbacks
    final String key = (data['id'] ?? data['serviceId'] ?? data['key'] ?? id).toString();
    final String title = (data['name'] ?? data['title'] ?? 'Service').toString();
    
    // Parse imageUrl - primary field from Firestore
    final String? imageUrl = data['imageUrl'] != null 
        ? (data['imageUrl'] as String).trim()
        : null;
    
    // Legacy field support
    final String legacyImage = (data['image'] ?? data['imageAssetPath'] ?? '').toString();
    
    final String description = (data['description'] ?? '').toString();
    
    // SAFE NUMBER PARSING
    double price = 0.0;
    final dynamic priceData = data['price'] ?? data['basePrice'];
    if (priceData is num) {
      price = priceData.toDouble();
    } else if (priceData is String) {
      price = double.tryParse(priceData) ?? 0.0;
    }

    final bool isActive = data['isActive'] ?? true;
    final String category = (data['category'] ?? data['categoryId'] ?? 'general').toString();
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
      imageAssetPath: legacyImage,
      imageUrl: imageUrl,
      description: description,
      basePrice: price,
      isActive: isActive,
      category: category,
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
      'imageUrl': imageUrl ?? imageAssetPath,
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
    if (imageUrl == null) return false;
    final url = imageUrl!.trim();
    return url.startsWith('http://') || url.startsWith('https://');
  }
}
