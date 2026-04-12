import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, ChangeNotifier;
import '../models/category.dart';
import '../models/service.dart';
import '../models/banner_model.dart';
import 'firestore_service.dart';

/// CategoryService - Thin wrapper around FirestoreService
/// Consolidates duplicate logic and delegates to single source of truth
class CategoryService extends ChangeNotifier {
  final FirestoreService _firestoreService;
  late final Stream<List<Category>> _categoriesStream;
  late final Stream<List<HomeService>> _servicesStream;
  late final Stream<List<HomeService>> _recentServicesStream;
  late final Stream<List<HomeService>> _topRatedServicesStream;
  late final Stream<List<HomeService>> _allServicesStream;
  late final Stream<List<BannerModel>> _bannersStream;

  CategoryService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService() {
    _initializeStreams();
  }

  void _initializeStreams() {
    _categoriesStream = _firestoreService.streamTechnicianCategories()
        .map((techCategories) => techCategories.map<Category>((tc) => Category(
          id: tc.id,
          name: tc.name,
          isActive: tc.isActive,
          order: tc.order,
        )).toList())
        .asBroadcastStream();

    _servicesStream = _firestoreService.streamTechnicianServices(
      sortBy: 'recent',
      limit: 50,
      filterByLocation: true,
    ).asBroadcastStream();

    _recentServicesStream = _firestoreService.streamRecentTechnicianServices(limit: 10).asBroadcastStream();
    _topRatedServicesStream = _firestoreService.streamTopRatedTechnicianServices(limit: 10).asBroadcastStream();
    _allServicesStream = _firestoreService.streamAllTechnicianServices(limit: 50).asBroadcastStream();
    _bannersStream = _firestoreService.streamBanners().asBroadcastStream();
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

  Stream<List<HomeService>> getRecentlyAddedServices({int limit = 10}) {
    return _recentServicesStream;
  }

  Stream<List<HomeService>> getServicesByCategory(String categoryId) {
    if (categoryId.isEmpty) return Stream.value([]);
    return _servicesStream.map((services) =>
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

  Stream<List<HomeService>> getAllServices() {
    return _allServicesStream;
  }

  Stream<List<HomeService>> getTopServices({int limit = 10}) {
    return _topRatedServicesStream;
  }

  Stream<List<HomeService>> getTopRatedServices({int limit = 10, String? district}) {
    return _topRatedServicesStream;
  }

  Stream<List<HomeService>> getPopularServices({int limit = 10, String? district}) {
    return _topRatedServicesStream;
  }

  Stream<List<HomeService>> getTrendingServices({int limit = 10, String? district}) {
    return _recentServicesStream;
  }

  Stream<List<HomeService>> getRecommendedServices({int limit = 10, String? district}) {
    return _firestoreService.streamRecommendedServices('', limit: limit).asBroadcastStream();
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
      return await _firestoreService.streamAllTechnicianServices(limit: 100).first;
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
