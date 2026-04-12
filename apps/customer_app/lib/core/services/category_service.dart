import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, ChangeNotifier;
import '../models/category.dart';
import '../models/service.dart';
import '../models/banner_model.dart';
import 'firestore_service.dart';

/// CategoryService - Thin wrapper around FirestoreService
/// OPTIMIZED: Uses single base stream, derives all views from it
class CategoryService extends ChangeNotifier {
  final FirestoreService _firestoreService;
  late final Stream<List<Category>> _categoriesStream;
  late final Stream<List<BannerModel>> _bannersStream;
  
  // SINGLE BASE STREAM - All service queries derive from this
  late final Stream<List<HomeService>> _baseServicesStream;

  CategoryService({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
    _initializeStreams();
  }

  void _initializeStreams() {
    // Categories stream (separate collection)
    _categoriesStream = _firestoreService.streamTechnicianCategories()
        .map((techCategories) => techCategories.map<Category>((tc) => Category(
          id: tc.id,
          name: tc.name,
          isActive: tc.isActive,
          order: tc.order,
        )).toList())
        .asBroadcastStream();

    // SINGLE BASE STREAM - Uses cached stream from FirestoreService
    // This is the ONLY Firestore query for services
    _baseServicesStream = _firestoreService.getCachedServicesStream();
    
    // Banners stream (separate collection)
    _bannersStream = _firestoreService.streamBanners().asBroadcastStream();
    
    if (kDebugMode) debugPrint('[CATEGORY_SERVICE] Initialized with single base stream');
  }

  /// Clear location cache (call when user updates address)
  /// Notifies listeners to trigger UI updates
  void clearLocationCache() {
    _firestoreService.clearCachedServicesStream();
    
    // Notify listeners when cache is cleared
    notifyListeners();
  }

  Stream<List<Category>> streamCategories() {
    return _categoriesStream;
  }

  Stream<List<Category>> getActiveCategories() {
    return _categoriesStream;
  }

  Stream<List<Category>> getCategories() {
    return _categoriesStream;
  }

  Future<List<Category>> getCategoriesOnce() async {
    try {
      final techCategories = await _firestoreService.getTechnicianCategories();
      return techCategories.map<Category>((tc) => Category(
        id: tc.id,
        name: tc.name,
        isActive: tc.isActive,
        order: tc.order,
      )).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [CategoryService] Error fetching categories: $e');
      return [];
    }
  }

  // ========== DERIVED STREAMS - All from single base stream ==========
  
  /// Recently Added Services - derived from base stream
  Stream<List<HomeService>> getRecentlyAddedServices({int limit = 10}) {
    return _baseServicesStream.map((services) {
      final sorted = services.toList()
        ..sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
      return sorted.take(limit).toList();
    });
  }

  /// Services by Category - derived from base stream
  Stream<List<HomeService>> getServicesByCategory(String categoryId) {
    if (categoryId.isEmpty) return Stream.value([]);
    return _baseServicesStream.map((services) =>
        services.where((s) => s.category == categoryId || s.categoryId == categoryId).toList());
  }

  Stream<List<HomeService>> getSubServices(String categoryId, String serviceId) {
    if (categoryId.isEmpty || serviceId.isEmpty) return Stream.value([]);
    return _firestoreService.streamSubServices(categoryId, serviceId).asBroadcastStream();
  }

  Future<bool> serviceHasSubServices(String categoryId, String serviceId) async {
    if (categoryId.isEmpty || serviceId.isEmpty) return false;

    try {
      final subServices = await getSubServices(categoryId, serviceId).first;
      return subServices.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CategoryService] Error checking sub-services for $serviceId: $e');
      }
      return false;
    }
  }

  // Delegate to FirestoreService for service queries
  Future<HomeService?> getServiceById(String serviceId) async {
    return await _firestoreService.getServiceById(serviceId);
  }

  /// All Services - derived from base stream
  Stream<List<HomeService>> getAllServices() {
    return _baseServicesStream;
  }

  /// Top Services - derived from base stream
  Stream<List<HomeService>> getTopServices({int limit = 10}) {
    return _baseServicesStream.map((services) {
      final topRated = services
          .where((s) => (s.rating ?? 0) >= 4.0)
          .toList()
        ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      return topRated.take(limit).toList();
    });
  }

  /// Top Rated Services - derived from base stream
  Stream<List<HomeService>> getTopRatedServices({int limit = 10, String? district}) {
    return getTopServices(limit: limit);
  }

  /// Popular Services - derived from base stream
  Stream<List<HomeService>> getPopularServices({int limit = 10, String? district}) {
    return getTopServices(limit: limit);
  }

  /// Trending Services - derived from base stream
  Stream<List<HomeService>> getTrendingServices({int limit = 10, String? district}) {
    return getRecentlyAddedServices(limit: limit);
  }

  /// Recommended Services - derived from base stream
  Stream<List<HomeService>> getRecommendedServices({int limit = 10, String? district}) {
    return getTopServices(limit: limit);
  }

  Stream<List<BannerModel>> getBanners() {
    return _bannersStream;
  }

  // Utility methods
  Future<int> getServiceCount(String categoryId) async {
    try {
      final snapshot = await _firestoreService.db
          .collection('technician_services')
          .where('status', isEqualTo: 'approved')
          .where('categoryId', isEqualTo: categoryId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[CategoryService] count error: $e');
      return 0;
    }
  }

  Future<List<Category>> enrichWithCounts(List<Category> categories) async {
    final List<Category> enriched = [];
    for (final category in categories) {
      final count = await getServiceCount(category.id);
      enriched.add(category.copyWith(serviceCount: count));
    }
    return enriched;
  }

  List<Category> searchCategories(List<Category> categories, String query) {
    if (query.isEmpty) return categories;
    final lowercaseQuery = query.toLowerCase();
    return categories
        .where((c) => c.name.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  Future<List<HomeService>> getAllServicesOnce() async {
    try {
      return await _baseServicesStream.first;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [CategoryService] Error in getAllServicesOnce: $e');
      return [];
    }
  }

  Future<Map<String, String>?> getUserLocationCached() async {
    return await _firestoreService.getUserLocationCached();
  }

  Stream<List<HomeService>> getServicesByCategoryResult(String categoryId) {
    return getServicesByCategory(categoryId);
  }
}
