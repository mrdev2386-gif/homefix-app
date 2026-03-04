import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Category data model
class CategoryData {
  final String id;
  final String name;
  final String? iconName;
  final int? order;

  CategoryData({
    required this.id,
    required this.name,
    this.iconName,
    this.order,
  });

  factory CategoryData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryData(
      id: doc.id,
      name: data['name'] as String? ?? data['displayName'] as String? ?? '',
      iconName: data['iconName'] as String? ?? data['icon'] as String?,
      order: data['order'] as int?,
    );
  }
}

/// Subcategory data model
class SubCategoryData {
  final String id;
  final String name;
  final String? categoryId;
  final int? order;

  SubCategoryData({
    required this.id,
    required this.name,
    this.categoryId,
    this.order,
  });

  factory SubCategoryData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubCategoryData(
      id: doc.id,
      name: data['name'] as String? ?? data['displayName'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? data['parentCategoryId'] as String?,
      order: data['order'] as int?,
    );
  }
}

/// Service data model - for loading services from 'services' collection
class ServiceData {
  final String id;
  final String name;
  final String? categoryId;
  final String? description;
  final double? basePrice;
  final bool isActive;
  final int? order;

  ServiceData({
    required this.id,
    required this.name,
    this.categoryId,
    this.description,
    this.basePrice,
    this.isActive = true,
    this.order,
  });

  factory ServiceData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceData(
      id: doc.id,
      name: data['name'] as String? ?? data['serviceName'] as String? ?? '',
      categoryId: data['categoryId'] as String?,
      description: data['description'] as String?,
      basePrice: (data['basePrice'] as num?)?.toDouble() ?? (data['price'] as num?)?.toDouble(),
      isActive: data['isActive'] as bool? ?? true,
      order: data['order'] as int?,
    );
  }
}

/// SubService data model - for loading subservices from 'services/{serviceId}/subServices' subcollection
class SubServiceData {
  final String id;
  final String name;
  final double? price;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int? order;

  SubServiceData({
    required this.id,
    required this.name,
    this.price,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.order,
  });

  factory SubServiceData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubServiceData(
      id: doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? (data['basePrice'] as num?)?.toDouble(),
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String? ?? data['image'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      order: data['order'] as int?,
    );
  }
}

/// Category Data Service - Fetches categories and subcategories from Firestore
class CategoryDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for categories
  List<CategoryData>? _cachedCategories;
  DateTime? _categoriesCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 10);

  // Cache for subcategories
  List<SubCategoryData>? _cachedSubCategories;
  DateTime? _subCategoriesCacheTime;

  /// Check if categories cache is valid
  bool get _isCategoriesCacheValid {
    if (_cachedCategories == null || _categoriesCacheTime == null) return false;
    return DateTime.now().difference(_categoriesCacheTime!).isNegative == false &&
           DateTime.now().difference(_categoriesCacheTime!) < _cacheDuration;
  }

  /// Check if subcategories cache is valid
  bool get _isSubCategoriesCacheValid {
    if (_cachedSubCategories == null || _subCategoriesCacheTime == null) return false;
    return DateTime.now().difference(_subCategoriesCacheTime!).isNegative == false &&
           DateTime.now().difference(_subCategoriesCacheTime!) < _cacheDuration;
  }

  /// Get active categories from Firestore
  /// STRICT: Only collection "categories", orderBy "order"
  Future<List<CategoryData>> getCategories({bool forceRefresh = false}) async {
    if (forceRefresh) clearCache();
    
    // Return cached if valid and not empty
    if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
      debugPrint('[CategoryDataService] Returning cached categories: ${_cachedCategories!.length}');
      return _cachedCategories!;
    }

    try {
      debugPrint('[DEBUG] Category fetch path: categories collection');
      debugPrint('[CATEGORY] Fetching from "categories" collection...');
      
      QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      debugPrint('[CATEGORY] SUCCESS: docs=${snapshot.docs.length}');
      
      _cachedCategories = snapshot.docs
          .map((doc) => CategoryData.fromFirestore(doc))
          .toList();
      _categoriesCacheTime = DateTime.now();
      
      return _cachedCategories!;
    } catch (e) {
      debugPrint('[CATEGORY] CRITICAL ERROR fetching categories: $e');
      rethrow;
    }
  }

  /// Get active subcategories (filtered by category if provided)
  /// STRICT: Only collection "services", orderBy "order", filter categoryId
  Future<List<SubCategoryData>> getSubCategories({String? categoryId, bool forceRefresh = false}) async {
    if (forceRefresh) clearCache();

    try {
      debugPrint('[SUBCATEGORY] Fetching from "services" for category: $categoryId');
      
      Query query = _firestore
          .collection('services')
          .where('isActive', isEqualTo: true);

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      QuerySnapshot snapshot = await query.orderBy('order').get();

      debugPrint('[SUBCATEGORY] SUCCESS: docs=${snapshot.docs.length}');
      
      final subCategories = snapshot.docs
          .map((doc) => SubCategoryData.fromFirestore(doc))
          .toList();
          
      return subCategories;
    } catch (e) {
      debugPrint('[SUBCATEGORY] CRITICAL ERROR fetching subcategories: $e');
      rethrow;
    }
  }

  /// Get all subcategories (350+ items)
  Future<List<SubCategoryData>> getAllSubCategories() async {
    return getSubCategories();
  }

  /// Search categories
  List<CategoryData> searchCategories(List<CategoryData> categories, String query) {
    if (query.isEmpty) return categories;
    final lowercaseQuery = query.toLowerCase().trim();
    return categories
        .where((c) => c.name.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  /// Search subcategories
  List<SubCategoryData> searchSubCategories(List<SubCategoryData> subCategories, String query) {
    if (query.isEmpty) return subCategories;
    final lowercaseQuery = query.toLowerCase().trim();
    return subCategories
        .where((s) => s.name.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  /// Clear caches (useful for refresh)
  void clearCache() {
    _cachedCategories = null;
    _categoriesCacheTime = null;
    _cachedSubCategories = null;
    _subCategoriesCacheTime = null;
    debugPrint('[CategoryDataService] Cache cleared');
  }

  /// Get services from Firestore by category
  /// Uses collection: services
  /// Query: .where("categoryId", isEqualTo: selectedCategoryId).where("isActive", isEqualTo: true)
  /// PART 7: Firestore query safety with try/catch and FirebaseException handling
  Future<List<ServiceData>> getServicesByCategory(String categoryId) async {
    debugPrint('[DEBUG] Service fetch path: services collection filtered by categoryId');
    debugPrint('[DEBUG] Fetching services for categoryId: $categoryId');
    try {
      // Try with orderBy - may fail if index is missing
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('services')
            .where('categoryId', isEqualTo: categoryId)
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final services = snapshot.docs
              .map((doc) => ServiceData.fromFirestore(doc))
              .toList();
          debugPrint('[CategoryDataService] Fetched services for category $categoryId: ${services.length}');
          return services;
        }
      } catch (e) {
        debugPrint('[CategoryDataService] orderBy in services failed: $e');
      }

      // Try alternative field name with orderBy
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('services')
            .where('parentCategoryId', isEqualTo: categoryId)
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final services = snapshot.docs
              .map((doc) => ServiceData.fromFirestore(doc))
              .toList();
          debugPrint('[CategoryDataService] Fetched services for category $categoryId: ${services.length}');
          return services;
        }
      } catch (e) {
        debugPrint('[CategoryDataService] orderBy with parentCategoryId failed: $e');
      }

      // Last resort - fallback WITHOUT orderBy
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('services')
            .where('categoryId', isEqualTo: categoryId)
            .where('isActive', isEqualTo: true)
            .get();

        final services = snapshot.docs
            .map((doc) => ServiceData.fromFirestore(doc))
            .toList();
        debugPrint('[CategoryDataService] Fetched services for category $categoryId (no order): ${services.length}');
        return services;
      } catch (e) {
        debugPrint('[CategoryDataService] Final fallback failed: $e');
      }

      return [];
    } on FirebaseException catch (e) {
      // PART 7: Handle FirebaseException with user-friendly messages
      debugPrint('[CategoryDataService] FirebaseException: ${e.code} - ${e.message}');
      
      String userMessage;
      switch (e.code) {
        case 'permission-denied':
          userMessage = 'Access denied. Please check your permissions.';
          break;
        case 'unavailable':
          userMessage = 'Service unavailable. Please check your network connection.';
          break;
        case 'deadline-exceeded':
          userMessage = 'Request timed out. Please try again.';
          break;
        case 'not-found':
          userMessage = 'No services found for this category.';
          break;
        default:
          userMessage = 'Failed to load services. Please try again.';
      }
      
      debugPrint('[CategoryDataService] User-friendly error: $userMessage');
      return [];
    } catch (e) {
      debugPrint('[CategoryDataService] Error fetching services: $e');
      return [];
    }
  }

  /// Get subservices from Firestore by service
  /// Uses subcollection: services/{serviceId}/subServices
  /// Query: .where("isActive", isEqualTo: true).orderBy("order")
  Future<List<SubServiceData>> getSubServicesByService(String serviceId) async {
    debugPrint('[DEBUG] SubService fetch path: services/$serviceId/subServices');
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('services')
          .doc(serviceId)
          .collection('subServices')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      final subServices = snapshot.docs
          .map((doc) => SubServiceData.fromFirestore(doc))
          .toList();
      debugPrint('[CategoryDataService] Fetched subservices for service $serviceId: ${subServices.length}');
      return subServices;
    } on FirebaseException catch (e) {
      debugPrint('[CategoryDataService] FirebaseException fetching subservices: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      debugPrint('[CategoryDataService] Error fetching subservices: $e');
      return [];
    }
  }
}
