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
  Future<List<CategoryData>> getCategories() async {
    // Return cached if valid
    if (_isCategoriesCacheValid && _cachedCategories != null) {
      debugPrint('[CategoryDataService] Returning cached categories: ${_cachedCategories!.length}');
      return _cachedCategories!;
    }

    try {
      // Try service_categories first
      QuerySnapshot snapshot = await _firestore
          .collection('service_categories')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .orderBy('name')
          .get();

      if (snapshot.docs.isEmpty) {
        // Fallback to categories collection
        snapshot = await _firestore
            .collection('categories')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .orderBy('name')
            .get();
      }

      if (snapshot.docs.isEmpty) {
        // Fallback to technician_categories
        snapshot = await _firestore
            .collection('technician_categories')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .orderBy('name')
            .get();
      }

      _cachedCategories = snapshot.docs
          .map((doc) => CategoryData.fromFirestore(doc))
          .toList();
      _categoriesCacheTime = DateTime.now();

      debugPrint('[CategoryDataService] Fetched categories: ${_cachedCategories!.length}');
      return _cachedCategories!;
    } catch (e) {
      debugPrint('[CategoryDataService] Error fetching categories: $e');
      // Return cached if available, otherwise empty list
      return _cachedCategories ?? [];
    }
  }

  /// Get subcategories from Firestore
  /// Uses collection: technician_subcategories
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
      // Try technician_subcategories first
      QuerySnapshot snapshot = await _firestore
          .collection('technician_subcategories')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .orderBy('name')
          .get();

      if (snapshot.docs.isEmpty) {
        // Fallback to sub_categories collection
        snapshot = await _firestore
            .collection('sub_categories')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .orderBy('name')
            .get();
      }

      if (snapshot.docs.isEmpty) {
        // Fallback to service_subcategories collection
        snapshot = await _firestore
            .collection('service_subcategories')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .orderBy('name')
            .get();
      }

      _cachedSubCategories = snapshot.docs
          .map((doc) => SubCategoryData.fromFirestore(doc))
          .toList();
      _subCategoriesCacheTime = DateTime.now();

      debugPrint('[CategoryDataService] Fetched subcategories: ${_cachedSubCategories!.length}');

      // Filter by category if provided
      if (categoryId != null) {
        return _cachedSubCategories!
            .where((s) => s.categoryId == categoryId || s.categoryId == null)
            .toList();
      }

      return _cachedSubCategories!;
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
}
