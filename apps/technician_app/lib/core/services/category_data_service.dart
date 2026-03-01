import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Category data model
class CategoryData {
  final String id;
  final String name;
  final String? iconName;
  final int? sortOrder;

  CategoryData({
    required this.id,
    required this.name,
    this.iconName,
    this.sortOrder,
  });

  factory CategoryData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryData(
      id: doc.id,
      name: data['name'] as String? ?? data['displayName'] as String? ?? '',
      iconName: data['iconName'] as String? ?? data['icon'] as String?,
      sortOrder: data['sortOrder'] as int? ?? data['order'] as int?,
    );
  }
}

/// Subcategory data model
class SubCategoryData {
  final String id;
  final String name;
  final String? categoryId;
  final int? sortOrder;

  SubCategoryData({
    required this.id,
    required this.name,
    this.categoryId,
    this.sortOrder,
  });

  factory SubCategoryData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubCategoryData(
      id: doc.id,
      name: data['name'] as String? ?? data['displayName'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? data['parentCategoryId'] as String?,
      sortOrder: data['sortOrder'] as int? ?? data['order'] as int?,
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
  final int? sortOrder;

  ServiceData({
    required this.id,
    required this.name,
    this.categoryId,
    this.description,
    this.basePrice,
    this.isActive = true,
    this.sortOrder,
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
      sortOrder: data['sortOrder'] as int? ?? data['order'] as int?,
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
  /// Uses collection: service_categories (or falls back to categories)
  /// PART 7: Firestore query safety with try/catch and FirebaseException handling
  Future<List<CategoryData>> getCategories() async {
    // Return cached if valid
    if (_isCategoriesCacheValid && _cachedCategories != null) {
      debugPrint('[CategoryDataService] Returning cached categories: ${_cachedCategories!.length}');
      return _cachedCategories!;
    }

    try {
      // Try service_categories first with orderBy using both possible field names
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('service_categories')
            .where('isActive', isEqualTo: true)
            .orderBy('order')
            .get();

        if (snapshot.docs.isNotEmpty) {
          _cachedCategories = snapshot.docs
              .map((doc) => CategoryData.fromFirestore(doc))
              .toList();
          _categoriesCacheTime = DateTime.now();
          debugPrint('[CategoryDataService] Fetched categories: ${_cachedCategories!.length}');
          return _cachedCategories!;
        }
      } catch (e) {
        debugPrint('[CategoryDataService] orderBy "order" failed, trying "sortOrder": $e');
      }

      // Try with sortOrder field
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('service_categories')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .get();

        if (snapshot.docs.isNotEmpty) {
          _cachedCategories = snapshot.docs
              .map((doc) => CategoryData.fromFirestore(doc))
              .toList();
          _categoriesCacheTime = DateTime.now();
          debugPrint('[CategoryDataService] Fetched categories: ${_cachedCategories!.length}');
          return _cachedCategories!;
        }
      } catch (e) {
        debugPrint('[CategoryDataService] orderBy "sortOrder" also failed: $e');
      }

      // Fallback to categories collection
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('categories')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .get();

        if (snapshot.docs.isNotEmpty) {
          _cachedCategories = snapshot.docs
              .map((doc) => CategoryData.fromFirestore(doc))
              .toList();
          _categoriesCacheTime = DateTime.now();
          debugPrint('[CategoryDataService] Fetched categories: ${_cachedCategories!.length}');
          return _cachedCategories!;
        }
      } catch (e) {
        debugPrint('[CategoryDataService] Fallback to categories failed: $e');
      }

      // Last resort - no ordering
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('service_categories')
            .where('isActive', isEqualTo: true)
            .get();

        _cachedCategories = snapshot.docs
            .map((doc) => CategoryData.fromFirestore(doc))
            .toList();
        _categoriesCacheTime = DateTime.now();
        debugPrint('[CategoryDataService] Fetched categories (no order): ${_cachedCategories!.length}');
        return _cachedCategories!;
      } catch (e) {
        debugPrint('[CategoryDataService] Final fallback failed: $e');
      }

      _cachedCategories = [];
      _categoriesCacheTime = DateTime.now();
      return _cachedCategories!;
    } on FirebaseException catch (e) {
      // PART 7: Handle FirebaseException with user-friendly messages
      debugPrint('[CategoryDataService] FirebaseException: ${e.code} - ${e.message}');
      return _cachedCategories ?? [];
    } catch (e) {
      debugPrint('[CategoryDataService] Error fetching categories: $e');
      return _cachedCategories ?? [];
    }
  }

  /// Get subcategories from Firestore
  /// Uses collection: technician_subcategories
  /// PART 7: Firestore query safety with try/catch and FirebaseException handling
  Future<List<SubCategoryData>> getSubCategories({String? categoryId}) async {
    // Return cached if valid
    if (_isSubCategoriesCacheValid && _cachedSubCategories != null) {
      final filtered = categoryId != null
          ? _cachedSubCategories!.where((s) => s.categoryId == categoryId || s.categoryId == null).toList()
          : _cachedSubCategories!;
      debugPrint('[CategoryDataService] Returning cached subcategories: ${filtered.length}');
      return filtered;
    }

    try {
      // Try technician_subcategories first with orderBy
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('technician_subcategories')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .orderBy('name')
            .get();

        if (snapshot.docs.isNotEmpty) {
          _cachedSubCategories = snapshot.docs
              .map((doc) => SubCategoryData.fromFirestore(doc))
              .toList();
          _subCategoriesCacheTime = DateTime.now();
          debugPrint('[CategoryDataService] Fetched subcategories: ${_cachedSubCategories!.length}');
          
          if (categoryId != null) {
            return _cachedSubCategories!
                .where((s) => s.categoryId == categoryId || s.categoryId == null)
                .toList();
          }
          return _cachedSubCategories!;
        }
      } catch (e) {
        debugPrint('[CategoryDataService] orderBy in technician_subcategories failed: $e');
      }

      // Try alternative collection with orderBy
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('sub_categories')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .orderBy('name')
            .get();

        if (snapshot.docs.isNotEmpty) {
          _cachedSubCategories = snapshot.docs
              .map((doc) => SubCategoryData.fromFirestore(doc))
              .toList();
          _subCategoriesCacheTime = DateTime.now();
          debugPrint('[CategoryDataService] Fetched subcategories: ${_cachedSubCategories!.length}');
          
          if (categoryId != null) {
            return _cachedSubCategories!
                .where((s) => s.categoryId == categoryId || s.categoryId == null)
                .toList();
          }
          return _cachedSubCategories!;
        }
      } catch (e) {
        debugPrint('[CategoryDataService] orderBy in sub_categories failed: $e');
      }

      // Try service_subcategories with orderBy
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('service_subcategories')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .orderBy('name')
            .get();

        if (snapshot.docs.isNotEmpty) {
          _cachedSubCategories = snapshot.docs
              .map((doc) => SubCategoryData.fromFirestore(doc))
              .toList();
          _subCategoriesCacheTime = DateTime.now();
          debugPrint('[CategoryDataService] Fetched subcategories: ${_cachedSubCategories!.length}');
          
          if (categoryId != null) {
            return _cachedSubCategories!
                .where((s) => s.categoryId == categoryId || s.categoryId == null)
                .toList();
          }
          return _cachedSubCategories!;
        }
      } catch (e) {
        debugPrint('[CategoryDataService] orderBy in service_subcategories failed: $e');
      }

      // Last resort - fallback WITHOUT orderBy
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('technician_subcategories')
            .where('isActive', isEqualTo: true)
            .get();

        _cachedSubCategories = snapshot.docs
            .map((doc) => SubCategoryData.fromFirestore(doc))
            .toList();
        _subCategoriesCacheTime = DateTime.now();
        debugPrint('[CategoryDataService] Fetched subcategories (no order): ${_cachedSubCategories!.length}');
        
        if (categoryId != null) {
          return _cachedSubCategories!
              .where((s) => s.categoryId == categoryId || s.categoryId == null)
              .toList();
        }
        return _cachedSubCategories!;
      } catch (e) {
        debugPrint('[CategoryDataService] Final fallback failed: $e');
      }

      _cachedSubCategories = [];
      _subCategoriesCacheTime = DateTime.now();
      return _cachedSubCategories!;
    } on FirebaseException catch (e) {
      // PART 7: Handle FirebaseException with user-friendly messages
      debugPrint('[CategoryDataService] FirebaseException: ${e.code} - ${e.message}');
      return _cachedSubCategories ?? [];
    } catch (e) {
      debugPrint('[CategoryDataService] Error fetching subcategories: $e');
      return _cachedSubCategories ?? [];
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
}
