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

    // ============================================================================
    // VALIDATION: Critical Fields Extraction with Safe Defaults
    // ============================================================================
    
    // Extract categoryId with fallback logic
    String categoryId = _extractCategoryId(doc, data);
    
    // Extract title/name (required for display)
    final String key = (data['id'] ?? data['serviceId'] ?? data['key'] ?? id).toString();
    final String title = (data['name'] ?? data['title'] ?? 'Service').toString();
    
    // Extract and validate image URL with global fallback
    final String imageUrl = _extractImageUrl(id, title, data);
    
    // ============================================================================
    // PRICE EXTRACTION: Safe number parsing for all price fields
    // ============================================================================
    
    double price = 0.0;
    double? originalPrice;
    double? offerPrice;
    
    price = _parsePrice(data['price'] ?? data['basePrice']);
    originalPrice = _parsePrice(data['originalPrice']);
    offerPrice = _parsePrice(data['offerPrice']);
    
    // Log price information only for services with special offers (reduce spam)
    if (kDebugMode && offerPrice != null && offerPrice > 0 && offerPrice < price) {
      final discountPercent = ((price - offerPrice!) / price * 100).toInt();
      debugPrint('💰 [SERVICE_OFFER] $title: ₹$price → ₹$offerPrice ($discountPercent% off)');
    }

    // ============================================================================
    // REMAINING FIELDS: Activity status, metadata, technician info
    // ============================================================================
    final bool isActive = data['isActive'] ?? true;
    final String finalCategory = categoryId.isNotEmpty ? categoryId : (data['categoryName'] ?? 'General').toString();
    final String finalCategoryName = (data['categoryName'] ?? data['category'] ?? 'General').toString();
    
    final bool isTop = data['isTopService'] ?? false;
    
    int order = _parseInteger(data['order'], defaultValue: 0);
    double rating = _parsePrice(data['rating'] ?? data['ratingValue'], isRating: true);
    int reviews = _parseInteger(data['reviewCount'] ?? data['reviews'], defaultValue: 0);

    final bool isTrending = data['isTrending'] ?? false;
    final bool isRecommended = data['isRecommended'] ?? false;
    final String duration = (data['duration'] ?? '1 hour').toString();
    
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    // Extract technician info with fallback to Firestore path
    String? technicianId = _extractTechnicianId(doc, data);

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

  /// ============================================================================
  /// HELPER METHODS: Data extraction and validation
  /// ============================================================================

  /// Extract categoryId with multiple fallback strategies
  static String _extractCategoryId(DocumentSnapshot doc, Map<String, dynamic> data) {
    String? categoryId = data['category'] ?? data['categoryId'];
    
    // Strategy 1: Check direct field mapping
    if (categoryId != null && categoryId.toString().isNotEmpty) {
      return categoryId.toString();
    }
    
    // Strategy 2: Infer from Firestore document path (e.g., /categories/electrical/services/doc_id)
    try {
      final pathSegments = doc.reference.path.split('/');
      final catIndex = pathSegments.indexOf('categories');
      if (catIndex != -1 && catIndex + 1 < pathSegments.length) {
        categoryId = pathSegments[catIndex + 1];
        if (kDebugMode) {
          debugPrint('🔧 [Service] categoryId inferred from path: $categoryId for service: ${data['name'] ?? data['title'] ?? doc.id}');
        }
        return categoryId;
      }
    } catch (e) {
      // Ignore path parsing errors
    }
    
    // Strategy 3: Default to empty (will be handled upstream, but warn in debug)
    if (kDebugMode) {
      debugPrint('⚠️ [Service] categoryId missing for service: ${data['name'] ?? data['title'] ?? doc.id}');
    }
    return '';
  }

  /// Extract and validate image URL with fallback
  static String _extractImageUrl(String serviceId, String serviceName, Map<String, dynamic> data) {
    // Check multiple image field names
    String? imageUrl = (data['imageUrl'] ?? 
                        data['image'] ?? 
                        data['thumbnail'] ?? 
                        data['bannerUrl'] ?? 
                        data['imageAssetPath'])?.toString().trim();
    
    // Validate extracted URL
    if (imageUrl != null && imageUrl.isNotEmpty && _isValidImageUrl(imageUrl)) {
      return imageUrl;
    }
    
    // Return global fallback (avoid logging for every missing image to reduce spam)
    return AppConstants.fallbackServiceImage;
  }

  /// Parse numeric price values safely
  static double _parsePrice(dynamic value, {bool isRating = false}) {
    if (value == null) return 0.0;
    
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    
    return 0.0;
  }

  /// Parse integer values safely with default
  static int _parseInteger(dynamic value, {required int defaultValue}) {
    if (value == null) return defaultValue;
    
    if (value is num) {
      return value.isFinite ? value.toInt() : defaultValue;
    } else if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    
    return defaultValue;
  }

  /// Extract technician ID with fallback to path
  static String? _extractTechnicianId(DocumentSnapshot doc, Map<String, dynamic> data) {
    String? technicianId = data['technicianId']?.toString();
    
    if (technicianId != null && technicianId.isNotEmpty) {
      return technicianId;
    }
    
    // Try extracting from path
    try {
      final pathSegments = doc.reference.path.split('/');
      final techIndex = pathSegments.indexOf('technicians');
      if (techIndex != -1 && techIndex + 1 < pathSegments.length) {
        return pathSegments[techIndex + 1];
      }
    } catch (_) {}
    
    return null;
  }

  /// Validate image URL format
  static bool _isValidImageUrl(String url) {
    final trimmed = url.trim();
    return trimmed.startsWith('http://') || 
           trimmed.startsWith('https://') ||
           trimmed.startsWith('assets/');
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
