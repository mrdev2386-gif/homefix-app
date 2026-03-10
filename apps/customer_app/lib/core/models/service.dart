import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'sub_service.dart';



class HomeService {
  final String id;
  final String key;
  final String title;
  final String imageAssetPath;
  final String imageUrl;
  final String description;
  final double basePrice;
  final double? originalPrice;  // NEW: For strikethrough display
  final double? offerPrice;     // NEW: For offer display
  final bool urgentBookingEnabled; // NEW: For urgent badge
  final bool isActive;
  final String category;
  final String categoryName;
  final bool isTopService;
  final int order;
  final double rating;
  final int reviewCount;
  final bool isTrending;
  final bool isRecommended;
  final String duration;
  final DateTime createdAt;
  final bool isPublished;
  final bool status; // Derived from 'status' field: true if 'active'
  final bool technicianApproved; // Added to match Cloud Functions
  final String? technicianId;
  final String? technicianName;
  final String? technicianDistrict;
  final List<SubService> subServices;

  // Derived status helper
  bool get isActiveStatus => status;

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
    this.originalPrice,
    this.offerPrice,
    this.urgentBookingEnabled = false,
    required this.isActive,
    required this.category,
    required this.categoryName,
    required this.isTopService,
    required this.order,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.isTrending = false,
    this.isRecommended = false,
    this.duration = '1 hour',
    required this.createdAt,
    this.isPublished = true,
    this.status = true,
    this.technicianApproved = true,
    this.technicianId,
    this.technicianName,
    this.technicianDistrict,
    this.subServices = const [],
  });

  static HomeService? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final String id = doc.id;

    // MANDATORY CATEGORY CHECK - FIX FOR SERVICE_COUNT 0
    String? categoryId = data['category'] ?? data['categoryId'];
    
    // FORENSIC FIX: Infer categoryId from path if missing
    if (categoryId == null || categoryId.toString().isEmpty) {
      try {
        // Try to find 'categories' segment in path
        final pathSegments = doc.reference.path.split('/');
        final catIndex = pathSegments.indexOf('categories');
        if (catIndex != -1 && catIndex + 1 < pathSegments.length) {
          categoryId = pathSegments[catIndex + 1];
          if (kDebugMode) {
            debugPrint('🔧 [HomeService] Inferred categoryId=$categoryId from path for ${doc.id}');
          }
        }
      } catch (e) {
        // ignore
      }
    }

    if (categoryId == null || categoryId.toString().isEmpty) {
      // ✅ LOG but do NOT drop — the service is still valid for display.
      // categoryId is only needed for subServices path, which is now always
      // supplied via widget.categoryId from the navigation argument.
      if (kDebugMode) {
        debugPrint('⚠️ [HomeService] categoryId missing for doc: $id (path: ${doc.reference.path})');
        debugPrint('   Service will still be shown. categoryId defaults to empty string.');
        debugPrint('   FIX: Add categoryId/category field to this Firestore document.');
      }
      categoryId = ''; // safe fallback — never drop a service just for missing categoryId
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

    // NEW: Parse originalPrice and offerPrice
    double? originalPrice;
    final dynamic originalPriceData = data['originalPrice'];
    if (originalPriceData is num) {
      originalPrice = originalPriceData.toDouble();
    } else if (originalPriceData is String) {
      originalPrice = double.tryParse(originalPriceData);
    }

    double? offerPrice;
    final dynamic offerPriceData = data['offerPrice'];
    if (offerPriceData is num) {
      offerPrice = offerPriceData.toDouble();
    } else if (offerPriceData is String) {
      offerPrice = double.tryParse(offerPriceData);
    }

    // DEBUG: Log price information for verification
    if (kDebugMode) {
      final hasDiscount = offerPrice != null && offerPrice > 0 && offerPrice < price;
      if (hasDiscount) {
        final discountPercent = ((price - offerPrice!) / price * 100).toInt();
        debugPrint('💰 [SERVICE_PRICES] id=$id | basePrice=$price | offerPrice=$offerPrice | discount=$discountPercent%');
      } else if (price > 0) {
        debugPrint('💰 [SERVICE_PRICES] id=$id | price=$price (no offer)');
      }
    }

    final bool isActive = data['isActive'] ?? true;
    final String finalCategory = categoryId.toString();
    final String finalCategoryName = (data['categoryName'] ?? data['category'] ?? 'General').toString();
    
    final bool isTop = data['isTopService'] ?? false;
    
    int order = 0;
    final dynamic orderData = data['order'] ?? 0;
    if (orderData is num) {
      order = (orderData.isFinite ? orderData : 0).toInt();
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
    final dynamic reviewsDataRaw = data['reviewCount'] ?? data['reviews'] ?? 0;
    if (reviewsDataRaw is num) {
      reviews = (reviewsDataRaw.isFinite ? reviewsDataRaw : 0).toInt();
    } else if (reviewsDataRaw is String) {
      reviews = int.tryParse(reviewsDataRaw) ?? 0;
    }

    final bool isTrending = data['isTrending'] ?? false;
    final bool isRecommended = data['isRecommended'] ?? false;
    final String duration = (data['duration'] ?? '1 hour').toString();
    
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    String? technicianId = data['technicianId']?.toString();
    if (technicianId == null || technicianId.isEmpty) {
      try {
        final pathSegments = doc.reference.path.split('/');
        final techIndex = pathSegments.indexOf('technicians');
        if (techIndex != -1 && techIndex + 1 < pathSegments.length) {
          technicianId = pathSegments[techIndex + 1];
        }
      } catch (_) {}
    }

    List<SubService> subServices = [];
    if (data['subServices'] is List) {
      subServices = (data['subServices'] as List)
          .map((item) => SubService.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return HomeService(
      id: id.isNotEmpty ? id : 'unknown',
      key: key,
      title: title,
      imageAssetPath: '', // Deprecated: No longer used for network images
      imageUrl: imageUrl,
      description: (data['description'] ?? '').toString(),
      basePrice: price,
      originalPrice: originalPrice,
      offerPrice: offerPrice,
      urgentBookingEnabled: data['urgentBookingEnabled'] ?? false,
      isActive: isActive,
      category: finalCategory,
      categoryName: finalCategoryName,
      isTopService: isTop,
      order: order,
      rating: rating,
      reviewCount: reviews,
      isTrending: isTrending,
      isRecommended: isRecommended,
      duration: duration,
      createdAt: createdAt,
      isPublished: data['isPublished'] ?? true,
      status: data['status'] == 'approved' || data['status'] == 'active' || data['isActive'] == true,
      technicianApproved: data['technicianApproved'] ?? true,
      technicianId: technicianId,
      technicianName: data['technicianName']?.toString(),
      technicianDistrict: data['technicianDistrict']?.toString() ?? data['district']?.toString(),
      subServices: subServices,
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
      'categoryName': categoryName,
      'isTopService': isTopService,
      'order': order,
      'rating': rating,
      'reviewCount': reviewCount,
      'isTrending': isTrending,
      'isRecommended': isRecommended,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublished': isPublished,
      'technicianApproved': technicianApproved,
      'status': status ? 'active' : 'inactive',
      'technicianId': technicianId,
    };
  }

  /// Check if service has valid image URL
  bool get hasValidImageUrl {
    final url = imageUrl.trim();
    return url.startsWith('http://') || url.startsWith('https://') || url.startsWith('assets/');
  }
}
