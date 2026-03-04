import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/service.dart';
import '../models/banner_model.dart';
import '../models/service_result.dart';

/// Helper: Converts a stream so that errors become error-result data events.
/// Dart's .handleError() return value is SILENTLY DISCARDED — it never emits data.
/// This transformer properly emits [fallback] as a DATA event on error.
Stream<T> _errorToData<T>(Stream<T> source, T Function(Object error) fallback) {
  return source.transform(StreamTransformer<T, T>.fromHandlers(
    handleData: (data, sink) => sink.add(data),
    handleError: (error, stackTrace, sink) {
      if (kDebugMode) debugPrint('❌ [CategoryService] Stream error caught: $error');
      sink.add(fallback(error));
    },
  ));
}

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<ServiceResult<List<Category>>> getActiveCategoriesResult() {
    return _errorToData(
      _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots()
          .map((snapshot) {
        debugPrint('[CategoryService] STREAM: Fetched ${snapshot.docs.length} categories from Firestore');
        final categories =
            snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
        return ServiceResult.success(categories);
      }),
      (e) => ServiceResult.error(e.toString()),
    );
  }

  Stream<List<Category>> getActiveCategories() {
    return getActiveCategoriesResult().map((result) => result.data ?? []);
  }

  Stream<List<Category>> getCategories() {
    return getActiveCategories();
  }

  Future<List<Category>> getCategoriesOnce() async {
    try {
      debugPrint('🔍 [CategoryService] Fetching categories once (Strict)...');
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();
      
      debugPrint('📂 Categories fetched: ${snapshot.docs.length}');
      
      final categories = snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
      
      for (var i = 0; i < categories.length && i < 5; i++) {
        debugPrint('   ${i + 1}. ${categories[i].name} (ID: ${categories[i].id})');
      }
      
      return categories;
    } catch (e, stackTrace) {
      debugPrint('❌ [CategoryService] CRITICAL: Error fetching categories: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow; // Rethrow to surface error as per instructions
    }
  }

  Stream<ServiceResult<List<HomeService>>> getRecentlyAddedServicesResult(
      {int limit = 10}) {
    return _errorToData(
      _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        final services = snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
        return ServiceResult.success(services);
      }),
      (e) => ServiceResult.error(e.toString()),
    );
  }

  Stream<List<HomeService>> getRecentlyAddedServices({int limit = 10}) {
    return getRecentlyAddedServicesResult(limit: limit)
        .map((r) => r.data ?? []);
  }

  Stream<ServiceResult<List<HomeService>>> getServicesByCategoryResult(
      String categoryId) {
    if (categoryId.isEmpty) {
      return Stream.value(ServiceResult.empty());
    }

    return _errorToData(
      _firestore
          .collectionGroup('technician_services')
          .where('categoryId', isEqualTo: categoryId)
          .where('status', isEqualTo: 'active')
          .where('isPublished', isEqualTo: true)
          .where('technicianApproved', isEqualTo: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        final services = snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
        services.sort((a, b) => a.order.compareTo(b.order));
        return ServiceResult.success(services);
      }),
      (e) => ServiceResult.error(e.toString()),
    );
  }

  Stream<List<HomeService>> getServicesByCategory(String categoryId) {
    return getServicesByCategoryResult(categoryId).map((r) => r.data ?? []);
  }

  Stream<ServiceResult<List<HomeService>>> getSubServicesResult(
      String categoryId, String serviceId) {
    if (categoryId.isEmpty || serviceId.isEmpty) {
      if (kDebugMode) debugPrint('⚠️ [SubServiceQuery] ABORTED: Invalid IDs (cat: "$categoryId", srv: "$serviceId")');
      return Stream.value(ServiceResult.empty());
    }

    if (kDebugMode) debugPrint('🕵️ [SubServiceQuery] START - using technician_services');

    return _errorToData(
      _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true)
          .where('categoryId', isEqualTo: categoryId)
          .snapshots()
          .map((snapshot) {
        if (kDebugMode) debugPrint('✅ [SubServiceQuery] SUCCESS count=${snapshot.docs.length}');
        final services = snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
        services.sort((a, b) => a.order.compareTo(b.order));
        return ServiceResult.success(services);
      }),
      (e) => ServiceResult.error(e.toString()),
    );
  }

  Stream<List<HomeService>> getSubServices(
      String categoryId, String serviceId) {
    return getSubServicesResult(categoryId, serviceId).map((r) => r.data ?? []);
  }

  Future<bool> serviceHasSubServices(
      String categoryId, String serviceId) async {
    try {
      // ✅ MANDATORY: Only check for published and approved technician services
      final snapshot = await _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true)
          .where('categoryId', isEqualTo: categoryId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [CategoryService] Error checking sub-services: $e');
      return false;
    }
  }

  Future<QuerySnapshot?> getServicesPaginated({
    String? categoryId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      // ✅ MANDATORY: Only show published and approved technician services
      Query query = _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true);

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      query = query.orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      return await query.limit(limit).get();
    } catch (e) {
      debugPrint('❌ [CategoryService] Error fetching paginated services: $e');
      return null;
    }
  }

  Future<HomeService?> getServiceById(String serviceId) async {
    try {
      // ✅ MANDATORY: Only find published and approved technician services
      final snapshot = await _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true)
          .where('id', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return HomeService.fromFirestore(snapshot.docs.first);
      }
    } catch (e) {
      debugPrint('❌ [CategoryService] Error fetching service $serviceId: $e');
    }
    return null;
  }

  Stream<ServiceResult<List<HomeService>>> getAllServicesResult() {
    return _errorToData(
      _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        final services = snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
        return ServiceResult.success(services);
      }),
      (e) => ServiceResult.error(e.toString()),
    );
  }

  Stream<List<HomeService>> getAllServices() {
    return getAllServicesResult().map((r) => r.data ?? []);
  }

  Stream<ServiceResult<List<HomeService>>> getTopServicesResult(
      {int limit = 10}) {
    return _errorToData(
      _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true)
          .where('isTopService', isEqualTo: true)
          .orderBy('order')
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        final services = snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
        return ServiceResult.success(services);
      }),
      (e) => ServiceResult.error(e.toString()),
    );
  }

  Stream<List<HomeService>> getTopServices({int limit = 10}) {
    return getTopServicesResult(limit: limit).map((r) => r.data ?? []);
  }

  Stream<ServiceResult<List<HomeService>>> getTopRatedServicesResult({int limit = 10}) {
    try {
      return _errorToData(
        _firestore
            .collectionGroup('technician_services')
            .where('isPublished', isEqualTo: true)
            .where('status', isEqualTo: 'active')
            .where('technicianApproved', isEqualTo: true)
            .orderBy('rating', descending: true)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .snapshots()
            .map((snapshot) {
          final services = snapshot.docs
              .map((doc) => HomeService.fromFirestore(doc))
              .whereType<HomeService>()
              .toList();
          return ServiceResult.success(services);
        }),
        (e) => ServiceResult.error(e.toString()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [SERVICES_QUERY] Top Rated query setup failed: $e');
      return Stream.value(ServiceResult.error(e.toString()));
    }
  }

  Stream<List<HomeService>> getTopRatedServices({int limit = 10}) {
    return getTopRatedServicesResult(limit: limit).map((r) => r.data ?? []);
  }

  Stream<ServiceResult<List<HomeService>>> getPopularServicesResult({int limit = 10}) {
    return _errorToData(
      _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        final services = snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
        return ServiceResult.success(services);
      }),
      (e) => ServiceResult.error(e.toString()),
    );
  }

  Stream<List<HomeService>> getPopularServices({int limit = 10}) {
    return getPopularServicesResult(limit: limit).map((r) => r.data ?? []);
  }

  Stream<ServiceResult<List<HomeService>>> getTrendingServicesResult({int limit = 10}) {
    try {
      return _errorToData(
        _firestore
            .collectionGroup('technician_services')
            .where('isPublished', isEqualTo: true)
            .where('status', isEqualTo: 'active')
            .where('technicianApproved', isEqualTo: true)
            .orderBy('bookingCount', descending: true)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .snapshots()
            .map((snapshot) {
          final services = snapshot.docs
              .map((doc) => HomeService.fromFirestore(doc))
              .whereType<HomeService>()
              .toList();
          return ServiceResult.success(services);
        }),
        (e) => ServiceResult.error(e.toString()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [SERVICES_QUERY] Trending query setup failed: $e');
      return Stream.value(ServiceResult.error(e.toString()));
    }
  }

  Stream<List<HomeService>> getTrendingServices({int limit = 10}) {
    return getTrendingServicesResult(limit: limit).map((r) => r.data ?? []);
  }

  /// Recommended Services - Basic version: random from published services
  Stream<ServiceResult<List<HomeService>>> getRecommendedServicesResult({int limit = 10}) {
    try {
      return _errorToData(
        _firestore
            .collectionGroup('technician_services')
            .where('isPublished', isEqualTo: true)
            .where('status', isEqualTo: 'active')
            .where('technicianApproved', isEqualTo: true)
            .limit(limit * 2) 
            .snapshots()
            .map((snapshot) {
          final services = snapshot.docs
              .map((doc) => HomeService.fromFirestore(doc))
              .whereType<HomeService>()
              .toList();
          
          services.shuffle();
          return ServiceResult.success(services.take(limit).toList());
        }),
        (e) => ServiceResult.error(e.toString()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [SERVICES_QUERY] Recommended query setup failed: $e');
      return Stream.value(ServiceResult.error(e.toString()));
    }
  }

  Stream<List<HomeService>> getRecommendedServices({int limit = 10}) {
    return getRecommendedServicesResult(limit: limit).map((r) => r.data ?? []);
  }

  Stream<ServiceResult<List<BannerModel>>> getBannersResult() {
    return _errorToData(
      _firestore
          .collection('service_bottom_banners')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots()
          .map((snapshot) {
        final banners = snapshot.docs.map((doc) {
          final data = doc.data();
          return BannerModel(
            id: doc.id,
            imageUrl: data['imageUrl'] ?? data['image'] ?? '',
            title: data['title'] ?? '',
            subtitle: data['subtitle'] ?? '',
            targetScreen: data['targetScreen'] ?? '',
            targetId: data['targetId'] ?? '',
            active: data['isActive'] ?? true,
            order: data['order'] ?? 0,
          );
        }).toList();
        return ServiceResult.success(banners);
      }),
      (e) => ServiceResult.error(e.toString()),
    );
  }

  Stream<List<BannerModel>> getBanners() {
    return getBannersResult().map((r) => r.data ?? []);
  }

  /// Get the live count of services inside a category subcollection.
  /// ✅ MANDATORY: Only count published and approved technician services
  Future<int> getServiceCount(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true)
          .where('categoryId', isEqualTo: categoryId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('[CategoryService] count error: $e');
      return 0;
    }
  }

  /// Enrich a list of categories with live service counts from Firestore.
  /// Use this when the Firestore document's serviceCount field is stale or 0.
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

  /// Get all services once (for initial load)
  /// ✅ MANDATORY: Only fetch published and approved technician services
  Future<List<HomeService>> getAllServicesOnce() async {
    try {
      debugPrint('🔍 [CategoryService] Fetching all services via collectionGroup (technician_services)...');
      final snapshot = await _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      
      final services = snapshot.docs
          .map((doc) {
            try {
              return HomeService.fromFirestore(doc);
            } catch (e) {
              debugPrint('⚠️ [CategoryService] Failed to parse service ${doc.id}: $e');
              return null;
            }
          })
          .whereType<HomeService>()
          .toList();
      
      debugPrint('🛠 Services fetched: ${services.length}');
      
      if (services.isEmpty) {
        debugPrint('⚠️ [CategoryService] WARNING: No published technician services found!');
        debugPrint('   Check: 1) Technicians have published services, 2) isPublished=true, 3) technicianApproved=true');
      } else {
        debugPrint('🧪 Sample service IDs: ${services.take(3).map((e) => e.id).toList()}');
        debugPrint('   Sample names: ${services.take(3).map((e) => e.name).toList()}');
      }
      
      return services;
    } catch (e, stackTrace) {
      debugPrint('❌ [CategoryService] CRITICAL: Error in getAllServicesOnce: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      // Check for specific error types
      if (e.toString().contains('FAILED_PRECONDITION')) {
        debugPrint('   ⚠️ FIRESTORE INDEX MISSING: Create composite index for this query');
      } else if (e.toString().contains('UNAVAILABLE')) {
        debugPrint('   ⚠️ NETWORK ERROR: Check internet connection');
      } else if (e.toString().contains('PERMISSION_DENIED')) {
        debugPrint('   ⚠️ PERMISSION ERROR: Check Firestore security rules');
      }
      
      return [];
    }
  }
}
