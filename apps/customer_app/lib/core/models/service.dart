import 'package:cloud_firestore/cloud_firestore.dart';

class HomeService {
  final String id;
  final String key;
  final String title;
  final String imageAssetPath;
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
  String get imageUrl => getEffectiveImageUrl();

  String getEffectiveImageUrl() {
    return imageAssetPath;
  }

  HomeService({
    required this.id,
    required this.key,
    required this.title,
    required this.imageAssetPath,
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

  factory HomeService.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // SAFE PARSING - MANDATORY NULL SAFETY
    final String id = doc.id;
    // Map Firestore fields with fallbacks
    final String key = (data['id'] ?? data['serviceId'] ?? data['key'] ?? id).toString();
    final String title = (data['name'] ?? data['title'] ?? 'Service').toString();
    final String image = (data['imageUrl'] ?? data['image'] ?? data['imageAssetPath'] ?? '').toString();
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
      imageAssetPath: image,
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
      'imageUrl': imageAssetPath,
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
}

