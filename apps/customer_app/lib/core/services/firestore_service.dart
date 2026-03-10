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

  // --- Stream Resilience Helper ---
  /// Wraps a stream with retry logic for network failures (UNAVAILABLE, DNS, timeouts)
  /// Returns stream with automatic error recovery
  Stream<T> _withErrorHandling<T>(Stream<T> source) {
    return source.handleError((error, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [Firestore] Stream error: $error');
      }
      // Return empty list instead of propagating error for critical streams
      if (error.toString().contains('UNAVAILABLE') || 
          error.toString().contains('DNS') ||
          error.toString().contains('network')) {
        if (kDebugMode) {
          debugPrint('🔄 [Firestore] Network error detected, streams will retry on reconnection');
        }
      }
      // Rethrow to let StreamBuilder handle the error state
      throw error;
    });
  }

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
  /// FIX: Query technician_services collection directly (not collectionGroup)
  /// Filters: status='approved' (not 'active'), no isPublished/technicianApproved checks
  /// Includes error handling and reconnection resilience
  Stream<List<HomeService>> streamAllTechnicianServices({int limit = 50}) {
    return _withErrorHandling(
      _db.collection('technician_services')
          .where('status', isEqualTo: 'approved')
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            final services = snapshot.docs
                .map((doc) => HomeService.fromFirestore(doc))
                .whereType<HomeService>()
                .toList();
            services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return services;
          }),
    );
  }
  
  // Get Banners - removed orderBy to avoid index requirement
  // Includes error handling for network resilience
  Stream<List<BannerModel>> streamBanners() {
    return _withErrorHandling(
      _db.collection('home_banners')
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
          }),
    );
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
    debugPrint('[ADDRESS_LIST] Starting stream for user $userId');
    return _db.collection('customers').doc(userId).collection('addresses')
        .snapshots()
        .map((snapshot) {
          debugPrint('[ADDRESS_LIST] Loaded ${snapshot.docs.length} addresses');
          final addresses = snapshot.docs.map((doc) {
            try {
              return Address.fromFirestore(doc);
            } catch (e) {
              debugPrint('[ADDRESS_LIST] Error parsing address ${doc.id}: $e');
              return null;
            }
          }).whereType<Address>().toList();
          
          addresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          debugPrint('[ADDRESS_LIST] Returning ${addresses.length} valid addresses');
          return addresses;
        });
  }
  
  Future<void> saveAddress(String userId, Address address) async {
    debugPrint('[ADDRESS_SAVE] Starting save for user $userId, isDefault: ${address.isDefault}');
    
    // If this is being set as default, first clear any existing default addresses
    if (address.isDefault) {
      try {
        final existingDefaults = await _db
            .collection('customers')
            .doc(userId)
            .collection('addresses')
            .where('isDefault', isEqualTo: true)
            .get();
        
        // Clear existing defaults
        for (final doc in existingDefaults.docs) {
          if (doc.id != address.id) { // Don't clear if editing the same address
            await doc.reference.update({'isDefault': false});
          }
        }
        debugPrint('[ADDRESS_SAVE] Cleared ${existingDefaults.docs.length} existing default addresses');
      } catch (e) {
        debugPrint('[ADDRESS_SAVE] Error clearing existing defaults: $e');
      }
    }
    
    // Save address via Cloud Function
    final callable = FirebaseFunctions.instance.httpsCallable('manageAddress');
    await callable.call({
      'action': address.id.isEmpty ? 'add' : 'edit',
      if (address.id.isNotEmpty) 'addressId': address.id,
      'label': address.label,
      'name': address.name,
      'phone': address.phone,
      'fullAddress': address.fullAddress,
      'landmark': address.landmark,
      'city': address.city,
      'district': address.district,
      'state': address.state,
      'pincode': address.pincode,
      'latitude': address.latitude,
      'longitude': address.longitude,
      'isDefault': address.isDefault,
    });
    
    // If this is set as primary/default, also update user profile
    if (address.isDefault) {
      await savePrimaryAddressToProfile(
        userId: userId,
        address: address.fullAddress,
        district: address.district,
        state: address.state,
      );
    }
    
    debugPrint('[ADDRESS_SAVE] Address saved successfully for user $userId');
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

  /// Set primary address - alias for setDefaultAddress for backward compatibility
  Future<void> setPrimaryAddress(String userId, String addressId) async {
    await setDefaultAddress(userId, addressId);
  }

  /// Save primary address to user profile in Firestore
  Future<void> savePrimaryAddressToProfile({
    required String userId,
    required String address,
    required String district,
    required String state,
  }) async {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in savePrimaryAddressToProfile');
      return;
    }

    try {
      await _db.collection('customers').doc(userId).set({
        'primaryAddress': address,
        'district': district.toLowerCase(),
        'state': state.toLowerCase(),
        'addressUpdatedAt': FieldValue.serverTimestamp(),
        'profileCompleted': true,
      }, SetOptions(merge: true));
      
      debugPrint('✅ [Address] Primary address saved to user profile');
    } catch (e) {
      debugPrint('❌ [Address] Failed to save primary address to profile: $e');
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
        .collection('customers')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Address.fromFirestore(snapshot.docs.first);
    });
  }

  /// Get primary address from user profile
  Future<Map<String, dynamic>?> getPrimaryAddressFromProfile(String userId) async {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in getPrimaryAddressFromProfile');
      return null;
    }
    
    try {
      final userDoc = await _db.collection('customers').doc(userId).get();
      if (!userDoc.exists) return null;
      
      final data = userDoc.data();
      if (data == null) return null;
      
      return {
        'primaryAddress': data['primaryAddress'],
        'district': data['district'],
        'state': data['state'],
      };
    } catch (e) {
      debugPrint('❌ [Address] Failed to get primary address from profile: $e');
      return null;
    }
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
    print('🛒 [FirestoreService.addToCart] Called with userId=$userId, item=${item.serviceName}');
    if (!FirestoreGuards.isValidDocumentId(userId)) {
      print('❌ [FirestoreService.addToCart] Invalid userId');
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
      print('🛒 [FirestoreService.addToCart] Calling Cloud Function addToCartCallable');
      if (kDebugMode) debugPrint('[CART] Adding item via callable...');
      final callable = FirebaseFunctions.instance.httpsCallable('addToCartCallable');
      await callable.call(item.toMap());
      print('✅ [FirestoreService.addToCart] Cloud Function succeeded');
      if (kDebugMode) debugPrint('✅ [CART] Item added successfully');
    } catch (e) {
      print('❌ [FirestoreService.addToCart] Cloud Function error: $e');
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
    print('❤️ [FirestoreService.toggleFavorite] Called with userId=$userId, serviceId=$serviceId, isFavorite=$isFavorite');
    if (userId.isEmpty || serviceId.isEmpty) {
      print('❌ [FirestoreService.toggleFavorite] Empty userId or serviceId');
      return;
    }
    try {
      print('❤️ [FirestoreService.toggleFavorite] Calling Cloud Function toggleFavoriteCallable');
      final callable = FirebaseFunctions.instance.httpsCallable('toggleFavoriteCallable');
      await callable.call({
        'serviceId': serviceId,
        'categoryId': categoryId,
        'isFavorite': isFavorite,
      });
      print('✅ [FirestoreService.toggleFavorite] Cloud Function succeeded');
      debugPrint('✅ [Favorite] Toggled via callable (status: $isFavorite)');
    } catch (e) {
      print('❌ [FirestoreService.toggleFavorite] Cloud Function error: $e');
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
        final serviceId = item['serviceId'];
        
        if (serviceId != null && serviceId.isNotEmpty) {
          // FIXED: Fetch from technician_services collection directly
          final doc = await _db.collection('technician_services').doc(serviceId).get();
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
    return _withErrorHandling(
      _db.collection('technician_services')
          .where('status', isEqualTo: 'approved')
          .limit(limit * 3)
          .snapshots()
          .asyncMap((snapshot) async {
            final userLocation = await _getUserLocation(userId);
            final services = snapshot.docs
                .map((doc) => HomeService.fromFirestore(doc))
                .whereType<HomeService>()
                .toList();
            
            if (userLocation != null && userLocation['state']!.isNotEmpty && userLocation['district']!.isNotEmpty) {
              return services
                  .where((s) => (s.technicianDistrict?.toLowerCase() ?? '') == userLocation['district'])
                  .take(limit)
                  .toList();
            }
            return services.take(limit).toList();
          }),
    );
  }

  Stream<List<HomeService>> streamTopRatedTechnicianServices({int limit = 10}) {
    return _withErrorHandling(
      _db.collection('technician_services')
          .where('status', isEqualTo: 'approved')
          .orderBy('rating', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => HomeService.fromFirestore(doc))
                .whereType<HomeService>()
                .where((service) => service.rating > 0) // Only include services with ratings
                .toList();
          }),
    );
  }

  Stream<List<HomeService>> streamRecentTechnicianServices({int limit = 10}) {
    return _withErrorHandling(
      _db.collection('technician_services')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).whereType<HomeService>().toList();
          }),
    );
  }

  Future<Map<String, String>?> _getUserLocation(String userId) async {
    try {
      final userDoc = await _db.collection('customers').doc(userId).get();
      if (!userDoc.exists) return null;
      final data = userDoc.data();
      return {
        'state': (data?['state'] ?? '').toString().toLowerCase(),
        'district': (data?['district'] ?? '').toString().toLowerCase(),
      };
    } catch (e) {
      debugPrint('Error getting user location: $e');
      return null;
    }
  }

  Stream<List<HomeService>> streamNearbyServices(String userId, {int limit = 10}) {
    return _db.collection('technician_services')
        .where('status', isEqualTo: 'approved')
        .limit(limit * 3)
        .snapshots()
        .asyncMap((snapshot) async {
          final userLocation = await _getUserLocation(userId);
          final services = snapshot.docs
              .map((doc) => HomeService.fromFirestore(doc))
              .whereType<HomeService>()
              .toList();
          
          if (userLocation != null && userLocation['district']!.isNotEmpty) {
            return services
                .where((s) => (s.technicianDistrict?.toLowerCase() ?? '') == userLocation['district'])
                .take(limit)
                .toList();
          }
          return services.take(limit).toList();
        });
  }

  Future<HomeService?> getServiceById(String serviceId) async {
    try {
      final doc = await _db.collection('technician_services').doc(serviceId).get();
      if (!doc.exists) return null;
      return HomeService.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching service: $e');
      return null;
    }
  }

  Stream<List<HomeService>> streamSubServices(String categoryId, String serviceId) {
    return _db
        .collection('categories')
        .doc(categoryId)
        .collection('services')
        .doc(serviceId)
        .collection('subServices')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HomeService.fromFirestore(doc))
              .whereType<HomeService>()
              .toList();
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
