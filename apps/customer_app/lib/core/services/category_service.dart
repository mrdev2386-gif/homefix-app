import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/service.dart';
import '../models/banner_model.dart';
import '../models/service_result.dart';

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

  Stream<List<Category>> streamCategories() {
    return _firestore
        .collection('categories')
        .snapshots()
        .map((snapshot) {
          final categories = snapshot.docs
              .map((doc) {
                try {
                  return Category.fromFirestore(doc);
                } catch (e) {
                  if (kDebugMode) debugPrint('❌ [CategoryService] Error parsing category ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<Category>()
              .toList();
          return categories;
        })
        .handleError((error, stackTrace) {
          if (kDebugMode) debugPrint('❌ [CategoryService] Stream error: $error');
          return <Category>[];
        });
  }

  Stream<List<Category>> getActiveCategories() {
    return streamCategories();
  }

  Stream<List<Category>> getCategories() {
    return streamCategories();
  }

  Future<List<Category>> getCategoriesOnce() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .get();
      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [CategoryService] Error fetching categories: $e');
      return [];
    }
  }

  Stream<List<HomeService>> getRecentlyAddedServices({int limit = 10, String? district}) {
    Query query = _firestore
        .collection('technician_services')
        .where('status', isEqualTo: 'active');

    if (district != null && district.isNotEmpty) {
      query = query.where('district', isEqualTo: district);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final services = snapshot.docs
          .map((doc) => HomeService.fromFirestore(doc))
          .whereType<HomeService>()
          .toList();
      return services;
    }).handleError((error) {
      if (kDebugMode) debugPrint('❌ [CategoryService] Recently added services error: $error');
      return <HomeService>[];
    });
  }

  Stream<List<HomeService>> getServicesByCategory(String categoryId, {String? district}) {
    if (categoryId.isEmpty) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('technician_services')
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'active');

    if (district != null && district.isNotEmpty) {
      query = query.where('district', isEqualTo: district);
    }

    return query
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final services = snapshot.docs
          .map((doc) => HomeService.fromFirestore(doc))
          .whereType<HomeService>()
          .toList();
      services.sort((a, b) => a.order.compareTo(b.order));
      return services;
    }).handleError((error) {
      if (kDebugMode) debugPrint('❌ [CategoryService] Services by category error: $error');
      return <HomeService>[];
    });
  }

  Stream<ServiceResult<List<HomeService>>> getSubServicesResult(
      String categoryId, String serviceId, {String? district}) {
    if (categoryId.isEmpty || serviceId.isEmpty) {
      if (kDebugMode) debugPrint('⚠️ [SubServiceQuery] ABORTED: Invalid IDs (cat: "$categoryId", srv: "$serviceId")');
      return Stream.value(ServiceResult.empty());
    }

    Query query = _firestore
        .collectionGroup('technician_services')
        .where('isPublished', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .where('technicianApproved', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId);

    if (district != null && district.isNotEmpty) {
      query = query.where('district', isEqualTo: district);
    }

    return _errorToData(
      (query as Query<Map<String, dynamic>>)
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

  Stream<List<HomeService>> getSubServices(
      String categoryId, String serviceId, {String? district}) {
    return getSubServicesResult(categoryId, serviceId, district: district).map((r) => r.data ?? []);
  }

  Future<bool> serviceHasSubServices(
      String categoryId, String serviceId) async {
    try {
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

  Stream<List<HomeService>> getAllServices({String? district}) {
    Query query = _firestore
        .collection('technician_services')
        .where('status', isEqualTo: 'active');

    if (district != null && district.isNotEmpty) {
      query = query.where('district', isEqualTo: district);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final services = snapshot.docs
          .map((doc) => HomeService.fromFirestore(doc))
          .whereType<HomeService>()
          .toList();
      return services;
    }).handleError((error) {
      if (kDebugMode) debugPrint('❌ [CategoryService] All services error: $error');
      return <HomeService>[];
    });
  }

  Stream<List<HomeService>> getTopServices({int limit = 10, String? district}) {
    Query query = _firestore
        .collection('technician_services')
        .where('status', isEqualTo: 'active')
        .where('isTopService', isEqualTo: true);

    if (district != null && district.isNotEmpty) {
      query = query.where('district', isEqualTo: district);
    }

    return query
        .orderBy('order')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final services = snapshot.docs
          .map((doc) => HomeService.fromFirestore(doc))
          .whereType<HomeService>()
          .toList();
      return services;
    }).handleError((error) {
      if (kDebugMode) debugPrint('❌ [CategoryService] Top services error: $error');
      return <HomeService>[];
    });
  }

  Stream<ServiceResult<List<HomeService>>> getTopRatedServicesResult({int limit = 10, String? district}) {
    try {
      Query query = _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true);

      if (district != null && district.isNotEmpty) {
        query = query.where('district', isEqualTo: district);
      }

      return _errorToData(
        (query as Query<Map<String, dynamic>>)
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

  Stream<List<HomeService>> getTopRatedServices({int limit = 10, String? district}) {
    return getTopRatedServicesResult(limit: limit, district: district).map((r) => r.data ?? []);
  }

  Stream<ServiceResult<List<HomeService>>> getPopularServicesResult({int limit = 10, String? district}) {
    Query query = _firestore
        .collectionGroup('technician_services')
        .where('isPublished', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .where('technicianApproved', isEqualTo: true);

    if (district != null && district.isNotEmpty) {
      query = query.where('district', isEqualTo: district);
    }

    return _errorToData(
      (query as Query<Map<String, dynamic>>)
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

  Stream<List<HomeService>> getPopularServices({int limit = 10, String? district}) {
    return getPopularServicesResult(limit: limit, district: district).map((r) => r.data ?? []);
  }

  Stream<ServiceResult<List<HomeService>>> getTrendingServicesResult({int limit = 10, String? district}) {
    try {
      Query query = _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true);

      if (district != null && district.isNotEmpty) {
        query = query.where('district', isEqualTo: district);
      }

      return _errorToData(
        (query as Query<Map<String, dynamic>>)
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

  Stream<List<HomeService>> getTrendingServices({int limit = 10, String? district}) {
    return getTrendingServicesResult(limit: limit, district: district).map((r) => r.data ?? []);
  }

  Stream<ServiceResult<List<HomeService>>> getRecommendedServicesResult({int limit = 10, String? district}) {
    try {
      Query query = _firestore
          .collectionGroup('technician_services')
          .where('isPublished', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('technicianApproved', isEqualTo: true);

      if (district != null && district.isNotEmpty) {
        query = query.where('district', isEqualTo: district);
      }

      return _errorToData(
        (query as Query<Map<String, dynamic>>)
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

  Stream<List<HomeService>> getRecommendedServices({int limit = 10, String? district}) {
    return getRecommendedServicesResult(limit: limit, district: district).map((r) => r.data ?? []);
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
              if (kDebugMode) debugPrint('⚠️ [CategoryService] Failed to parse service ${doc.id}: $e');
              return null;
            }
          })
          .whereType<HomeService>()
          .toList();
      
      return services;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [CategoryService] CRITICAL: Error in getAllServicesOnce: $e');
        if (e.toString().contains('FAILED_PRECONDITION')) {
          debugPrint('   ⚠️ FIRESTORE INDEX MISSING: Create composite index for this query');
        } else if (e.toString().contains('UNAVAILABLE')) {
          debugPrint('   ⚠️ NETWORK ERROR: Check internet connection');
        } else if (e.toString().contains('PERMISSION_DENIED')) {
          debugPrint('   ⚠️ PERMISSION ERROR: Check Firestore security rules');
        }
      }
      return [];
    }
  }
}
