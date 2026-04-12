import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/technician_service.dart';
import '../firebase/firebase_functions.dart';

/// ❌ UNUSED SERVICE - DO NOT USE
/// 
/// This service is NOT imported or used anywhere in the codebase.
/// All service management operations use FunctionsService directly.
/// 
/// REASON FOR KEEPING:
/// - Kept for potential future use or as reference implementation
/// - Contains useful helper methods (canManageServices, hasActiveServices, etc.)
/// 
/// MIGRATION: If you need to use this, migrate to FunctionsService instead.
/// 
/// DEPRECATED: Use FunctionsService for all service operations:
/// - addService() → FunctionsService.addService()
/// - updateService() → FunctionsService.updateService()
/// - deleteService() → FunctionsService.deleteService()
/// - getMyServices() → Use Firestore stream directly or FunctionsService
/// 
/// STATUS: DISABLED - All methods throw exceptions to prevent accidental usage
/// LAST VERIFIED: Production audit - no usages found in codebase
class TechnicianCatalogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctionsService.instance;

  /// SAFETY CHECK: Throw on instantiation to prevent accidental usage
  TechnicianCatalogService() {
    throw UnsupportedError(
      'TechnicianCatalogService is UNUSED and DISABLED. '
      'Use FunctionsService for all service operations instead.'
    );
  }

  /// Check if technician is approved to manage services
  Future<bool> canManageServices() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;
      
      final doc = await _db.collection('technicians').doc(uid).get();
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final isApproved = data['isApproved'] ?? false;
      final adminApproved = data['adminApproved'] ?? false;
      final isKycComplete = data['isKycComplete'] ?? false;
      
      return isKycComplete && isApproved && adminApproved;
    } catch (e) {
      debugPrint('[TechnicianCatalogService] Error checking service permissions: $e');
      return false;
    }
  }

  /// Create a new technician service via Cloud Function
  Future<TechnicianService> createService(CreateTechnicianServiceInput input) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final payload = input.toMap();
    
    debugPrint('[SERVICE CREATE] START');
    debugPrint('[SERVICE CREATE] payload=${payload..['technicianId'] = currentUid}');
    
    try {
      // First check if technician can manage services
      final canManage = await canManageServices();
      if (!canManage) {
        debugPrint('[SERVICE CREATE] ERROR: not approved');
        throw Exception('You must be approved by admin to add or manage services. Please wait for admin approval.');
      }
      final validationError = input.validate();
      if (validationError != null) {
        debugPrint('[SERVICE CREATE] ERROR: validation failed - $validationError');
        throw Exception(validationError);
      }

      final callable = _functions.httpsCallable('createTechnicianService');
      final result = await callable.call<Map<String, dynamic>>(input.toMap());

      if (result.data['success'] == true) {
        debugPrint('[SERVICE CREATE] SUCCESS');
        final serviceData = result.data['data'];
        return TechnicianService(
          id: serviceData['id'],
          technicianId: FirebaseAuth.instance.currentUser?.uid ?? '',
          categoryId: input.categoryId,
          subcategoryId: input.subcategoryId,
          title: input.title,
          description: input.description,
          tags: input.tags,
          price: input.price,
          durationMinutes: input.durationMinutes,
          imageUrl: input.imageUrl,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        throw Exception(result.data['message'] ?? 'Failed to create service');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[SERVICE CREATE] ERROR: FirebaseFunctionsException - ${e.code}: ${e.message}');
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      debugPrint('[SERVICE CREATE] ERROR: $e');
      rethrow;
    }
  }

  /// Update an existing technician service
  Future<void> updateService(UpdateTechnicianServiceInput input) async {
    try {
      // Check if technician can manage services
      final canManage = await canManageServices();
      if (!canManage) {
        throw Exception('You must be approved by admin to update services. Please wait for admin approval.');
      }
      
      final callable = _functions.httpsCallable('updateTechnicianService');
      await callable.call<Map<String, dynamic>>(input.toMap());
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ [TechnicianService] FirebaseFunctionsException: ${e.message}');
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      debugPrint('❌ [TechnicianService] Error updating service: $e');
      rethrow;
    }
  }

  /// Delete (soft delete) a technician service
  Future<void> deleteService(String serviceId) async {
    try {
      // Check if technician can manage services
      final canManage = await canManageServices();
      if (!canManage) {
        throw Exception('You must be approved by admin to delete services. Please wait for admin approval.');
      }
      
      final callable = _functions.httpsCallable('deleteTechnicianService');
      await callable.call<Map<String, dynamic>>({'serviceId': serviceId});
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ [TechnicianService] FirebaseFunctionsException: ${e.message}');
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      debugPrint('❌ [TechnicianService] Error deleting service: $e');
      rethrow;
    }
  }

  /// Get all services for the current technician
  Future<List<TechnicianService>> getMyServices() async {
    try {
      final callable = _functions.httpsCallable('getMyTechnicianServices');
      final result = await callable.call<Map<String, dynamic>>({});

      if (result.data['success'] == true) {
        final servicesList = result.data['services'] as List<dynamic>? ?? [];
        return servicesList.map((data) {
          return TechnicianService(
            id: data['id'],
            technicianId: data['technicianId'] ?? '',
            categoryId: data['categoryId'] ?? '',
            subcategoryId: data['subcategoryId'] ?? '',
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            tags: List<String>.from(data['tags'] ?? []),
            price: (data['price'] ?? 0.0).toDouble(),
            durationMinutes: (data['durationMinutes'] ?? 0).toInt(),
            imageUrl: data['imageUrl'] ?? '',
            isActive: data['isActive'] ?? true,
            createdAt: data['createdAt'] != null 
              ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
              : DateTime.now(),
            updatedAt: data['updatedAt'] != null 
              ? DateTime.tryParse(data['updatedAt']) ?? DateTime.now()
              : DateTime.now(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [TechnicianService] Error getting services: $e');
      // Fallback to direct Firestore read
      return _getMyServicesFromFirestore();
    }
  }

  /// Fallback: Get services directly from Firestore
  Future<List<TechnicianService>> _getMyServicesFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];

      final snapshot = await _db
          .collection('technician_services')
          .where('technicianId', isEqualTo: uid)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('isPublished', isEqualTo: true)
          .where('technicianApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TechnicianService.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ [TechnicianService] Error fetching from Firestore: $e');
      return [];
    }
  }

  /// Stream of services for real-time updates
  Stream<List<TechnicianService>> watchMyServices() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _db
        .collection('technician_services')
        .where('technicianId', isEqualTo: uid)
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .where('isPublished', isEqualTo: true)
        .where('technicianApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TechnicianService.fromFirestore(doc))
          .toList();
    }).handleError((e) {
      debugPrint('❌ [TechnicianCatalogService] Error watching services: $e');
      return <TechnicianService>[];
    });
  }

  /// Check if technician has any active services
  Future<bool> hasActiveServices() async {
    try {
      final services = await getMyServices();
      return services.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [TechnicianService] Error checking active services: $e');
      return false;
    }
  }

  /// Get a single service by ID
  Future<TechnicianService?> getServiceById(String serviceId) async {
    try {
      final doc = await _db
          .collection('technician_services')
          .doc(serviceId)
          .get();
      
      if (!doc.exists) return null;
      return TechnicianService.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [TechnicianService] Error fetching service: $e');
      return null;
    }
  }

  /// Convert error message from Cloud Function
  String _getErrorMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'invalid-argument':
        return e.message ?? 'Invalid input. Please check your entries.';
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'not-found':
        return 'Service not found.';
      case 'resource-exhausted':
        return e.message ?? 'Too many requests. Please try again later.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
