import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/service.dart';
import '../models/address.dart';
import '../models/banner_model.dart';
import '../models/service_request.dart';
import '../models/proposal.dart';
import '../models/user_model.dart';
import '../models/cart_item.dart';
import '../models/dashboard_models.dart';
import '../utils/firestore_guards.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of bookings for a user with pagination support
  Stream<List<Booking>> streamBookings(String userId, {int limit = 10}) {
    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: userId)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
          // Sort by createdAt in-memory to avoid composite index
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  // Single booking detail
  Stream<Booking> streamBookingDetail(String bookingId) {
    return _db
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .map((doc) => Booking.fromFirestore(doc));
  }
  
  /// CRITICAL: Stream for Home Screen "All Services"
  Stream<List<HomeService>> streamAllTechnicianServices({int limit = 50}) {
    return _db.collectionGroup('technician_services')
        .where('status', isEqualTo: 'active')
        .where('isPublished', isEqualTo: true)
        .where('technicianApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final services = snapshot.docs
              .map((doc) => HomeService.fromFirestore(doc))
              .whereType<HomeService>()
              .toList();
          return services;
        });
  }
  
  // Get Banners - removed orderBy to avoid index requirement
  Stream<List<BannerModel>> streamBanners() {
    return _db.collection('home_banners')
        .snapshots()
        .map((snapshot) {
          final List<BannerModel> banners = [];
          for (var doc in snapshot.docs) {
            try {
              final banner = BannerModel.fromFirestore(doc);
              if (banner.active) {
                // AUDIT: Defensive check for imageUrl
                if (banner.imageUrl.isEmpty) {
                  if (kDebugMode) debugPrint('⚠️ [FirestoreService] Skipping banner ${doc.id} due to missing imageUrl');
                  continue;
                }
                banners.add(banner);
              }
            } catch (e) {
              if (kDebugMode) debugPrint('❌ [FirestoreService] Error parsing banner ${doc.id}: $e');
            }
          }
          // Sort by order field in-memory
          banners.sort((a, b) => (a.order).compareTo(b.order));
          return banners;
        });
  }

  // Get categories (HomeFix services like Cleaning, Repair, etc.)
  Future<List<Map<String, dynamic>>> getCategories() async {
    final snapshot = await _db.collection('categories').get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
  
  // --- Address Management ---
  Stream<List<Address>> streamAddresses(String userId) {
    return _db.collection('users').doc(userId).collection('addresses')
        .snapshots()
        .map((snapshot) {
          final addresses = snapshot.docs.map((doc) => Address.fromFirestore(doc)).toList();
          addresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return addresses;
        });
  }
  
  Future<void> saveAddress(String userId, Address address) async {
    final callable = FirebaseFunctions.instance.httpsCallable('manageAddress');
    await callable.call({
      'action': address.id.isEmpty ? 'add' : 'edit',
      if (address.id.isNotEmpty) 'addressId': address.id,
      'label': address.label ?? "",
      'fullAddress': address.fullAddress ?? "",
      'latitude': address.latitude ?? 0.0,
      'longitude': address.longitude ?? 0.0,
    });
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('manageAddress');
    await callable.call({
      'action': 'delete',
      'addressId': addressId,
    });
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('manageAddress');
    await callable.call({
      'action': 'setDefault',
      'addressId': addressId,
    });
  }

  /// Set primary address with Firestore batch update
  Future<void> setPrimaryAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in setPrimaryAddress');
      return;
    }

    try {
      final batch = _db.batch();
      
      // Get all addresses
      final addressesSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();

      // Set all addresses to non-primary
      for (final doc in addressesSnapshot.docs) {
        batch.update(doc.reference, {'isDefault': false, 'isPrimary': false});
      }

      // Set selected address as primary
      final selectedAddressRef = _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId);
      batch.update(selectedAddressRef, {'isDefault': true, 'isPrimary': true});

      // Get selected address data to update user document
      final selectedAddressDoc = await selectedAddressRef.get();
      if (selectedAddressDoc.exists) {
        final addressData = selectedAddressDoc.data() as Map<String, dynamic>;
        final userRef = _db.collection('users').doc(userId);
        batch.update(userRef, {
          'primaryAddressId': addressId,
          'serviceDistrict': addressData['district'] ?? '',
          'serviceState': addressData['state'] ?? '',
        });
      }

      await batch.commit();
      debugPrint('✅ [Address] Primary address updated successfully');
    } catch (e) {
      debugPrint('❌ [Address] setPrimaryAddress failed: $e');
      rethrow;
    }
  }

  /// Stream primary address
  Stream<Address?> streamPrimaryAddress(String userId) {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in streamPrimaryAddress');
      return Stream.value(null);
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Address.fromFirestore(snapshot.docs.first);
    });
  }


  // --- Cart Management ---
  Stream<List<CartItem>> streamCart(String userId) {
    if (!FirestoreGuards.isValidDocumentId(userId)) {
      if (kDebugMode) debugPrint('[CART] Invalid userId, returning empty stream');
      return Stream.value([]);
    }
    
    final userDoc = FirestoreGuards.safeDoc(_db.collection('customers'), userId);
    if (userDoc == null) {
      return Stream.value([]);
    }
    
    return userDoc.collection('cart')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList();
          
          // CLEANUP: Auto-remove invalid cart items (legacy data protection)
          final List<CartItem> validItems = [];
          for (final item in items) {
            final bool hasTechnicianId = item.technicianId != null && item.technicianId!.isNotEmpty;
            final bool hasServiceId = item.serviceId.isNotEmpty;
            final bool hasCategoryId = item.categoryId.isNotEmpty;
            
            if (!hasTechnicianId || !hasServiceId || !hasCategoryId) {
              if (kDebugMode) {
                final reason = !hasTechnicianId ? 'missing technicianId' 
                    : !hasServiceId ? 'missing serviceId' 
                    : 'missing categoryId';
                debugPrint('🧹 [CART] Auto-cleaning legacy item ${item.id}: $reason');
              }
              Future.microtask(() => _safeDeleteCartItem(userId, item.id));
            } else {
              validItems.add(item);
            }
          }
          
          return validItems;
        })
        // FIX: handleError's return value is DISCARDED by Dart — it does NOT emit data.
        // Use StreamTransformer to properly emit [] as a DATA event on error.
        .transform(StreamTransformer<List<CartItem>, List<CartItem>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (e, stackTrace, sink) {
            final errorStr = e.toString().toLowerCase();
            final bool isUnavailable = errorStr.contains('unavailable') || errorStr.contains('network');
            
            if (kDebugMode) {
              if (isUnavailable) {
                debugPrint('⚠️ [CART] Network unavailable — emitting empty list');
              } else {
                debugPrint('❌ [CART] Stream error: $e');
              }
            }
            // CRITICAL: sink.add emits a real data event → CartProvider listener fires → isLoading = false
            sink.add(<CartItem>[]);
          },
        ));
  }
  
  /// Safe delete cart item - never throws, for background cleanup
  Future<void> _safeDeleteCartItem(String userId, String itemId) async {
    try {
      if (FirestoreGuards.isValidDocumentId(userId) && FirestoreGuards.isValidDocumentId(itemId)) {
        await _db.collection('customers').doc(userId).collection('cart').doc(itemId).delete();
        if (kDebugMode) debugPrint('✅ [CART] Auto-cleaned item: $itemId');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [CART] Failed to auto-clean item $itemId: $e');
      // Silent fail - don't crash
    }
  }

  Future<void> addToCart(String userId, CartItem item) async {
    if (!FirestoreGuards.isValidDocumentId(userId)) {
      debugPrint('[CART] Invalid userId, aborting add');
      throw Exception('Invalid user ID');
    }
    
    // DEV ASSERT: Validate critical fields before writing
    assert(item.serviceId.isNotEmpty, 'serviceId is mandatory for cart item');
    assert(item.technicianId != null && item.technicianId!.isNotEmpty, 'technicianId is mandatory for cart item');
    assert(item.categoryId.isNotEmpty, 'categoryId is mandatory for cart item');
    assert(item.categoryName.isNotEmpty, 'categoryName is mandatory for cart item');
    assert(item.finalPriceSnapshot > 0, 'finalPriceSnapshot must be valid');
    
    try {
      if (kDebugMode) debugPrint('[CART] Adding item via callable...');
      final callable = FirebaseFunctions.instance.httpsCallable('addToCartCallable');
      await callable.call(item.toMap());
      if (kDebugMode) debugPrint('✅ [CART] Item added successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [CART] Add failed: $e');
      rethrow;
    }
  }

  Future<void> updateCartItemQuantity(String userId, String itemId, int quantity) async {
    if (!FirestoreGuards.isValidDocumentId(userId)) {
      debugPrint('[CART] Invalid userId, aborting update');
      throw Exception('Invalid user ID');
    }
    
    if (!FirestoreGuards.isValidDocumentId(itemId)) {
      debugPrint('[CART] Invalid itemId, aborting update');
      throw Exception('Invalid item ID');
    }
    
    try {
      if (kDebugMode) debugPrint('[CART] Updating quantity via callable...');
      final callable = FirebaseFunctions.instance.httpsCallable('updateCartQuantityCallable');
      await callable.call({
        'itemId': itemId,
        'quantity': quantity,
      });
      if (kDebugMode) debugPrint('✅ [CART] Quantity updated successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [CART] Update failed: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String userId, String itemId) async {
    if (!FirestoreGuards.isValidDocumentId(userId)) {
      debugPrint('[CART] Invalid userId, aborting remove');
      throw Exception('Invalid user ID');
    }
    
    if (!FirestoreGuards.isValidDocumentId(itemId)) {
      debugPrint('[CART] Invalid itemId, aborting remove');
      throw Exception('Invalid item ID');
    }
    
    try {
      if (kDebugMode) debugPrint('[CART] Removing item via callable...');
      final callable = FirebaseFunctions.instance.httpsCallable('removeFromCartCallable');
      await callable.call({'itemId': itemId});
      if (kDebugMode) debugPrint('✅ [CART] Item removed successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [CART] Remove failed: $e');
      rethrow;
    }
  }

  Future<void> clearCart(String userId) async {
    if (!FirestoreGuards.isValidDocumentId(userId)) {
      debugPrint('[CART] Invalid userId, aborting clear');
      throw Exception('Invalid user ID');
    }
    
    try {
      if (kDebugMode) debugPrint('[CART] Clearing cart via callable...');
      final callable = FirebaseFunctions.instance.httpsCallable('clearCartCallable');
      await callable.call();
      if (kDebugMode) debugPrint('✅ [CART] Cart cleared successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [CART] Clear failed: $e');
      rethrow;
    }
  }

  // --- Service Request ---
  Future<String> createServiceRequest(ServiceRequest request) async {
    final docRef = _db.collection('service_requests').doc();
    await docRef.set(request.toMap());
    return docRef.id;
  }

  Stream<List<ServiceRequest>> streamServiceRequests(String userId) {
    return _db
        .collection('service_requests')
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRequest.fromFirestore(doc))
            .toList());
  }

  // --- Proposals (Quotes) --- 
  Stream<List<Proposal>> streamProposals(String requestId) {
    return _db
        .collection('proposals')
        .where('requestId', isEqualTo: requestId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Proposal.fromFirestore(doc))
            .toList());
  }

  // --- Proposals (Quotes) --- Harden: Moved to Cloud Functions
  Future<void> acceptProposal(Proposal proposal, ServiceRequest request) async {
    final callable = FirebaseFunctions.instance.httpsCallable('acceptProposal');
    await callable.call({
      'proposalId': proposal.id,
      'requestId': request.id,
    });
  }

  // --- Referrals ---
  Future<void> processReferral(String currentUserId, String referralCode) async {
    if (currentUserId.isEmpty || referralCode.isEmpty) {
      if (kDebugMode) debugPrint('[PATH GUARD] blocked empty id in processReferral');
      return;
    }
    
    if (kDebugMode) debugPrint('[WRITE GUARD] Direct write blocked in processReferral');
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('processReferralCallable');
      await callable.call({
        'referralCode': referralCode,
      });
      if (kDebugMode) debugPrint('✅ [Referral] Processed via callable');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Referral] Process failed: $e');
      rethrow;
    }
  }

  // --- User Profile ---
  Future<void> updateUserDefaultAddress(String userId, String address) async {
    if (userId.isEmpty) {
      if (kDebugMode) debugPrint('[PATH GUARD] blocked empty id in updateUserDefaultAddress');
      return;
    }
    if (kDebugMode) debugPrint('[WRITE GUARD] Direct write blocked in updateUserDefaultAddress');
    await updateUserProfile(userId, {'defaultAddress': address});
  }
  
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _db.collection('customers').doc(userId).get();
    return doc.data();
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) {
      if (kDebugMode) debugPrint('[PATH GUARD] blocked empty id in updateUserData');
      return;
    }
    if (kDebugMode) debugPrint('[WRITE GUARD] Direct write blocked in updateUserData');
    await updateUserProfile(userId, data);
  }

  /// Update user profile image URL
  /// CRITICAL: Only updates profileImageUrl field
  Future<void> updateProfileImageUrl(String userId, String imageUrl) async {
    if (userId.isEmpty) {
      if (kDebugMode) debugPrint('[PATH GUARD] blocked empty id in updateProfileImageUrl');
      return;
    }
    if (kDebugMode) debugPrint('[WRITE GUARD] Direct write blocked in updateProfileImageUrl');
    await updateUserProfile(userId, {
      'photoUrl': imageUrl,
      'profileImageUrl': imageUrl,
    });
  }

  Stream<UserModel> streamUserModel(String userId) {
    return _db.collection('customers').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return UserModel(uid: userId);
      }
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) {
      if (kDebugMode) debugPrint('[PATH GUARD] blocked empty id in updateUserProfile');
      return;
    }
    if (kDebugMode) debugPrint('[WRITE GUARD] Direct write blocked in updateUserProfile');
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('updateUserProfile');
      await callable.call(data);
      if (kDebugMode) debugPrint('✅ [Profile] Updated via callable');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Profile] Update failed: $e');
      rethrow;
    }
  }

  Future<void> becomeTechnician(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) {
      if (kDebugMode) debugPrint('[PATH GUARD] blocked empty id in becomeTechnician');
      return;
    }
    if (kDebugMode) debugPrint('[WRITE GUARD] Direct write blocked in becomeTechnician');
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('submitPartnerApplication');
      await callable.call(data);
      if (kDebugMode) debugPrint('✅ [Technician] Application submitted via callable');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Technician] Submission failed: $e');
      rethrow;
    }
  }

  // --- Favorites --- Harden: Added categoryId to ensure correct service lookup in nested structure
  Future<void> toggleFavorite(String userId, String categoryId, String serviceId, bool isFavorite) async {
    if (userId.isEmpty || serviceId.isEmpty) return;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('toggleFavoriteCallable');
      await callable.call({
        'serviceId': serviceId,
        'categoryId': categoryId,
        'isFavorite': isFavorite,
      });
      debugPrint('✅ [Favorite] Toggled via callable (status: $isFavorite)');
    } catch (e) {
      debugPrint('❌ [Favorite] Toggle failed: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, String>>> streamFavoriteIdsWithCategory(String userId) {
    return _db.collection('customers').doc(userId).collection('favorites').snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => {
        'serviceId': doc.id,
        'categoryId': (doc.data()['categoryId'] ?? '').toString(),
      }).toList()
    );
  }

  Stream<List<HomeService>> streamFavoriteServices(String userId) {
    return streamFavoriteIdsWithCategory(userId).asyncMap((items) async {
      if (items.isEmpty) return [];
      
      final services = <HomeService>[];
      for (final item in items) {
        final categoryId = item['categoryId'];
        final serviceId = item['serviceId'];
        
        if (categoryId != null && categoryId.isNotEmpty && serviceId != null && serviceId.isNotEmpty) {
           final doc = await _db.collection('categories').doc(categoryId).collection('services').doc(serviceId).get();
           if (doc.exists) {
             final service = HomeService.fromFirestore(doc);
             if (service != null) services.add(service);
           }
        }
      }
      return services;
    });
  }

  // --- Dashboard Data ---
  Stream<List<CleaningEssential>> streamCleaningEssentials() {
    return _db
        .collection('cleaning_essentials')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final essentials = snapshot.docs.map((doc) => CleaningEssential.fromFirestore(doc)).toList();
          // Sort by order field in-memory
          essentials.sort((a, b) => a.order.compareTo(b.order));
          return essentials;
        });
  }

  Stream<List<Map<String, dynamic>>> streamServiceSpotlight() {
    return _db.collection('service_spotlight').limit(6).snapshots().asyncMap((snapshot) async {
      try {
        final spotlights = <Map<String, dynamic>>[];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final serviceId = data['serviceId'] as String? ?? data['id'];
          int techCount = 0;
          if (serviceId != null && serviceId.isNotEmpty) {
            final techSnapshot = await _db.collection('technicians')
                .where('serviceId', isEqualTo: serviceId)
                .where('status', isEqualTo: 'approved')
                .where('isAvailable', isEqualTo: true)
                .get();
            techCount = techSnapshot.docs.length;
          }
          spotlights.add({'id': doc.id, ...data, 'availableTechnicians': techCount});
        }
        return spotlights;
      } catch (e) {
        debugPrint('❌ [FirestoreService] Spotlight query failed: $e');
        return [];
      }
    });
  }

  Stream<List<ServiceBanner>> streamServiceBottomBanners() {
    return _db
        .collection('service_bottom_banners')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final List<ServiceBanner> banners = [];
          for (var doc in snapshot.docs) {
            try {
              final banner = ServiceBanner.fromFirestore(doc);
              // AUDIT: Defensive check for imageUrl
              if (banner.imageUrl.isEmpty) {
                // debugPrint('⚠️ [FirestoreService] Skipping bottom banner ${doc.id} due to missing imageUrl');
                continue;
              }
              banners.add(banner);
            } catch (e) {
              debugPrint('❌ [FirestoreService] Error parsing bottom banner ${doc.id}: $e');
            }
          }
          banners.sort((a, b) => a.order.compareTo(b.order));
          return banners;
        });
  }

  // --- Technician Categories ---
  Stream<List<TechnicianCategory>> streamTechnicianCategories() {
    return _db.collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final categories = snapshot.docs
            .map((doc) => TechnicianCategory.fromFirestore(doc))
            .toList();
          // Sort in-memory to avoid index requirement
          categories.sort((a, b) => a.order.compareTo(b.order));
          return categories;
        });
  }

  Stream<List<TechnicianSubcategory>> streamTechnicianSubcategories({String? categoryId}) {
    Query query = _db.collection('services')
        .where('isActive', isEqualTo: true);
    
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots()
        .map((snapshot) {
          final subcategories = snapshot.docs
            .map((doc) => TechnicianSubcategory.fromFirestore(doc))
            .toList();
          // Sort in-memory to avoid index requirement
          subcategories.sort((a, b) => a.order.compareTo(b.order));
          return subcategories;
        });
  }

  Future<List<TechnicianCategory>> getTechnicianCategories() async {
    final snapshot = await _db.collection('categories')
        .where('isActive', isEqualTo: true)
        .get();
    
    final categories = snapshot.docs
      .map((doc) => TechnicianCategory.fromFirestore(doc))
      .toList();
    categories.sort((a, b) => a.order.compareTo(b.order));
    return categories;
  }

  Future<List<TechnicianSubcategory>> getTechnicianSubcategories() async {
    final snapshot = await _db.collection('services')
        .where('isActive', isEqualTo: true)
        .get();
    
    final subcategories = snapshot.docs
      .map((doc) => TechnicianSubcategory.fromFirestore(doc))
      .toList();
    subcategories.sort((a, b) => a.order.compareTo(b.order));
    return subcategories;
  }

  Stream<List<HomeService>> streamRecommendedServices(String userId, {int limit = 10}) {
    // 1. Fetch user's last booking categories or district
    return _db.collection('bookings')
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(2)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<String> preferredCategoryIds = [];
          String? userDistrict;

          if (snapshot.docs.isNotEmpty) {
            for (var doc in snapshot.docs) {
              final catId = doc.data()['categoryId'];
              if (catId != null) preferredCategoryIds.add(catId);
            }
          }

          // Also get user district for localized recommendations
          final customerDoc = await _db.collection('customers').doc(userId).get();
          if (customerDoc.exists) {
            userDistrict = customerDoc.data()?['district'];
          }

          // 2. Build Query
          Query query = _db.collectionGroup('technician_services')
              .where('status', isEqualTo: 'active')
              .where('isPublished', isEqualTo: true)
              .where('technicianApproved', isEqualTo: true);

          // Priority 1: Preferred Categories
          if (preferredCategoryIds.isNotEmpty) {
            query = query.where('categoryId', whereIn: preferredCategoryIds.take(10).toList());
          } 
          // Priority 2: User District
          else if (userDistrict != null && userDistrict.isNotEmpty) {
            query = query.where('technicianDistrict', isEqualTo: userDistrict);
          }
          // Fallback: Top Rated (handled via post-processing or orderBy)
          else {
            query = query.where('rating', isGreaterThanOrEqualTo: 4.0).orderBy('rating', descending: true);
          }

          final finalSnapshot = await query.limit(limit).get();
          
          // If query returned nothing, absolute fallback to Top Rated
          if (finalSnapshot.docs.isEmpty) {
            final fallbackSnapshot = await _db.collectionGroup('technician_services')
                .where('status', isEqualTo: 'active')
                .where('isPublished', isEqualTo: true)
                .where('technicianApproved', isEqualTo: true)
                .where('rating', isGreaterThanOrEqualTo: 4.0)
                .orderBy('rating', descending: true)
                .limit(limit)
                .get();
            return fallbackSnapshot.docs.map((doc) => HomeService.fromFirestore(doc)).whereType<HomeService>().toList();
          }

          return finalSnapshot.docs.map((doc) => HomeService.fromFirestore(doc)).whereType<HomeService>().toList();
        });
  }

  Stream<List<HomeService>> streamTopRatedTechnicianServices({int limit = 10}) {
    return _db.collectionGroup('technician_services')
        .where('status', isEqualTo: 'active')
        .where('isPublished', isEqualTo: true)
        .where('technicianApproved', isEqualTo: true)
        .where('rating', isGreaterThanOrEqualTo: 4.0)
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).whereType<HomeService>().toList();
        });
  }

  Stream<List<HomeService>> streamRecentTechnicianServices({int limit = 10}) {
    return _db.collectionGroup('technician_services')
        .where('status', isEqualTo: 'active')
        .where('isPublished', isEqualTo: true)
        .where('technicianApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).whereType<HomeService>().toList();
        });
  }

  Future<void> createCustomRequest(Map<String, dynamic> requestData) async {
    try {
      await _db.collection('custom_requests').add(requestData);
      if (kDebugMode) debugPrint('✅ [CustomRequest] Created successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [CustomRequest] Creation failed: $e');
      rethrow;
    }
  }
}
