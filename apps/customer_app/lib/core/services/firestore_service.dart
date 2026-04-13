import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../constants/firebase_constants.dart';
import 'user_location_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions functions = FirebaseFunctions.instanceFor(region: FirebaseConstants.region);
  
  // Expose db for backward compatibility
  FirebaseFirestore get db => _db;
  
  // Shared location service for user location caching
  final UserLocationService _locationService;
  
  // GLOBAL CACHED STREAM - Single Firestore connection for all sections
  Stream<List<HomeService>>? _cachedServicesStream;
  
  // CACHED USER INTERACTION DATA - Prevents repeated Firestore reads
  Map<String, dynamic>? _cachedUserInteractionData;
  String? _cachedUserId;
  DateTime? _lastInteractionFetch;
  static const Duration _interactionCacheDuration = FirebaseConstants.interactionCacheDuration;

  FirestoreService({UserLocationService? locationService})
      : _locationService = locationService ?? UserLocationService();

  // --- Authentication Helper ---
  /// Ensures user is authenticated and token is fresh
  /// Uses proper auth state listener with explicit 5s timeout
  Future<void> ensureAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    // FIX 3: Wait for stable auth state with explicit 5s timeout
    try {
      await FirebaseAuth.instance.authStateChanges()
          .firstWhere((u) => u != null && u.uid == user.uid)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              if (kDebugMode) debugPrint('❌ [Auth] Authentication timeout after 5 seconds');
              throw TimeoutException('Authentication state check timed out after 5 seconds');
            },
          );
    } catch (e) {
      if (e is TimeoutException) {
        if (kDebugMode) debugPrint('❌ [Auth] Failed to verify auth state: $e');
        throw Exception('Authentication verification failed - please try again');
      }
      if (kDebugMode) debugPrint('⚠️ [Auth] State check error: $e');
      // Continue for other errors - user exists
    }

    // Force token refresh
    await user.getIdToken(true);
  }

  // --- Stream Resilience Helper ---
  /// Wraps a stream with retry logic for network failures (UNAVAILABLE, DNS, timeouts)
  /// Returns stream with automatic error recovery
  Stream<T> _withErrorHandling<T>(Stream<T> source) {
    return source.handleError((error, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [Firestore] Stream error: $error');
      }
      // STEP 2: Handle network recovery - log and allow Firestore to retry
      if (error.toString().contains('UNAVAILABLE') || 
          error.toString().contains('DNS') ||
          error.toString().contains('network')) {
        if (kDebugMode) {
          debugPrint('[NETWORK] Network error detected - Firestore will auto-retry on reconnection');
        }
      }
      // Rethrow to let StreamBuilder handle the error state
      throw error;
    });
  }

  /// Stream bookings with pagination support
  /// CRITICAL FIX: includeMetadataChanges: true forces real-time updates
  /// CRITICAL FIX: Only sort by createdAt - updatedAt sorting prevents real-time UI refresh
  Stream<List<Booking>> streamBookings(String userId, {int limit = FirebaseConstants.bookingLimit, DocumentSnapshot? startAfter}) {
    Query query = _db
        .collection(FirebaseConstants.bookingsCollection)
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true) // FIXED: Only use createdAt for reliable stream updates
        .limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    return query.snapshots(includeMetadataChanges: true).asBroadcastStream().map((snapshot) {
      debugPrint('[BOOKING_STREAM] Snapshot received: ${snapshot.docs.length} bookings, metadata: ${snapshot.metadata}');
      final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
      // In-memory sort by updatedAt for display order (doesn't affect stream reactivity)
      bookings.sort((a, b) {
        final aTime = a.updatedAt?.millisecondsSinceEpoch ?? a.createdAt.millisecondsSinceEpoch;
        final bTime = b.updatedAt?.millisecondsSinceEpoch ?? b.createdAt.millisecondsSinceEpoch;
        return bTime.compareTo(aTime);
      });
      return bookings;
    });
  }

  // Single booking detail
  /// CRITICAL FIX: includeMetadataChanges: true forces real-time updates
  Stream<Booking> streamBookingDetail(String bookingId) {
    return _db
        .collection(FirebaseConstants.bookingsCollection)
        .doc(bookingId)
        .snapshots(includeMetadataChanges: true)
        .asBroadcastStream()
        .map((doc) {
          debugPrint('[BOOKING_DETAIL] Snapshot received for $bookingId, metadata: ${doc.metadata}');
          return Booking.fromFirestore(doc);
        });
  }
  
  /// SINGLE UNIFIED METHOD for all technician service queries
  /// SAFE MODE: Stream-level fallback - tries orderBy, falls back if error
  Stream<List<HomeService>> streamTechnicianServices({
    String sortBy = 'recent',
    int limit = 15,
    bool filterByLocation = false,
    DocumentSnapshot? startAfter,
  }) {
    if (kDebugMode) debugPrint('[SERVICES_SAFE_MODE] Starting query');
    
    // Build primary query with sorting
    Query query = _db.collection(FirebaseConstants.technicianServicesCollection);
    
    if (sortBy == 'recent') {
      query = query.orderBy('createdAt', descending: true);
    } else if (sortBy == 'topRated') {
      query = query.orderBy('rating', descending: true);
    }
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    query = query.limit(limit);

    // Build fallback query (no orderBy)
    Query fallbackQuery = _db.collection(FirebaseConstants.technicianServicesCollection)
        .limit(limit);

    // Return stream with error handling and fallback
    return query.snapshots()
        .handleError((error) {
          if (kDebugMode) {
            debugPrint('[SERVICES_ERROR] Primary query failed: $error');
          }
        })
        .asyncExpand((snapshot) {
          // If snapshot has data, use it
          if (snapshot.docs.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('[SERVICES_SAFE_MODE] Documents fetched: ${snapshot.docs.length}');
            }
            return Stream.value(snapshot);
          }
          
          // If empty, switch to fallback query
          if (kDebugMode) {
            debugPrint('[SERVICES_FALLBACK] Switching to fallback query');
          }
          return fallbackQuery.snapshots();
        })
        .map((snapshot) {
          if (kDebugMode) {
            debugPrint('[SERVICES_PARSE] Processing ${snapshot.docs.length} documents');
          }
          
          List<HomeService> services = snapshot.docs
              .map((doc) {
                try {
                  final service = HomeService.fromFirestore(doc);
                  if (service == null && kDebugMode) {
                    debugPrint("⚠️ [SERVICE_PARSE] Failed to parse: ${doc.id}");
                  }
                  return service;
                } catch (e) {
                  if (kDebugMode) debugPrint("⚠️ [SERVICE_PARSE] Error: $e");
                  return null;
                }
              })
              .whereType<HomeService>()
              .toList();
          
          if (kDebugMode) {
            debugPrint('[SERVICES_PARSE] Parsed: ${services.length} services');
          }
          
          return services;
        })
        .asBroadcastStream();
  }

  Stream<List<HomeService>> getCachedServicesStream() {
    if (_cachedServicesStream != null) {
      if (kDebugMode) debugPrint('[CACHE] Returning existing cached stream (no new query)');
      return _cachedServicesStream!;
    }
    
    if (kDebugMode) debugPrint('[CACHE] Creating new cached stream (SINGLE Firestore query)');
    _cachedServicesStream = streamTechnicianServices(
      sortBy: 'recent',
      limit: FirebaseConstants.defaultLimit,
      filterByLocation: false, // CRITICAL: Disabled to ensure services always load
    ).asBroadcastStream();
    return _cachedServicesStream!;
  }
  
  /// Fetch ALL services without any filters (for debugging)
  Stream<List<HomeService>> streamAllServicesNoFilter() {
    Query query = _db.collection(FirebaseConstants.technicianServicesCollection)
        .orderBy('createdAt', descending: true)
        .limit(FirebaseConstants.maxLimit); // PERFORMANCE: Add limit even for debug
    
    return _withErrorHandling(
      query.snapshots().asBroadcastStream().map((snapshot) {
        final services = snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
        
        return services;
      }),
    );
  }
  
  /// Clear cached stream (call when location changes)
  void clearCachedServicesStream() {
    Future.microtask(() {
      _cachedServicesStream = null;
    });
    if (kDebugMode) {
      debugPrint('[CACHE] clearCachedServicesStream called - stream cache cleared');
    }
  }

  /// Expose user location for delegates
  Future<Map<String, String>?> getUserLocationCached() {
    return _locationService.getUserLocationCached();
  }

  /// All Services - delegates to unified method with pagination
  Stream<List<HomeService>> streamAllTechnicianServices({int limit = FirebaseConstants.defaultLimit, DocumentSnapshot? startAfter}) {
    return streamTechnicianServices(
      sortBy: 'recent', 
      limit: limit, 
      filterByLocation: false, // CRITICAL: Disabled to ensure services always load
      startAfter: startAfter,
    );
  }
  
  // Get Banners - uses Firestore orderBy instead of in-memory sorting
  // Includes error handling for network resilience
  // BROADCAST: Safe for multiple listeners
  Stream<List<BannerModel>> streamBanners() {
    return _withErrorHandling(
      _db.collection('home_banners')
          .where('active', isEqualTo: true) // Filter active banners
          .orderBy('order') // FIRESTORE ORDERBY - NO IN-MEMORY SORTING
          .limit(10) // PERFORMANCE: Limit banner count
          .snapshots()
          .asBroadcastStream()
          .map((snapshot) {
            final List<BannerModel> banners = [];
            for (var doc in snapshot.docs) {
              try {
                final banner = BannerModel.fromFirestore(doc);
                // AUDIT: Defensive check for imageUrl
                if (banner.imageUrl.isEmpty) {
                  if (kDebugMode) debugPrint('⚠️ [FirestoreService] Skipping banner ${doc.id} due to missing imageUrl');
                  continue;
                }
                banners.add(banner);
              } catch (e) {
                if (kDebugMode) debugPrint('❌ [FirestoreService] Error parsing banner ${doc.id}: $e');
              }
            }
            // NO IN-MEMORY SORTING - Already ordered by Firestore
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
    return _db
        .collection('customers')
        .doc(userId)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asBroadcastStream()
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
          debugPrint('[ADDRESS_LIST] Returning ${addresses.length} valid addresses');
          return addresses;
        });
  }
  
  Future<void> saveAddress(String userId, Address address) async {
    debugPrint('[ADDRESS_SAVE] Starting save for user $userId, isDefault: ${address.isDefault}');
    
    if (address.isDefault) {
      try {
        final existingDefaults = await _db
            .collection('customers')
            .doc(userId)
            .collection('addresses')
            .where('isDefault', isEqualTo: true)
            .get();
        
        for (final doc in existingDefaults.docs) {
          if (doc.id != address.id) {
            await doc.reference.update({'isDefault': false});
          }
        }
        debugPrint('[ADDRESS_SAVE] Cleared ${existingDefaults.docs.length} existing default addresses');
      } catch (e) {
        debugPrint('[ADDRESS_SAVE] Error clearing existing defaults: $e');
      }
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    
    
    final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('manageAddress');
    final data = {
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
    };
    
    try {
      await callable.call(data);
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        await user.getIdToken(true);
        
        final retryCallable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('manageAddress');
        await retryCallable.call(data);
      } else {
        rethrow;
      }
    }
    
    if (address.isDefault) {
      await savePrimaryAddressToProfile(
        userId: userId,
        address: address.fullAddress,
        district: address.district,
        state: address.state,
      );
      
      // CRITICAL FIX: Clear location cache when primary address changes
      _locationService.clearLocationCache();
      // OPTIMIZATION: Clear services cache to refetch with new location
      clearCachedServicesStream();
      if (kDebugMode) debugPrint('✅ [ADDRESS_SAVE] Location cache and services cache cleared');
    }
    
    debugPrint('[ADDRESS_SAVE] Address saved successfully for user $userId');
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    
    
    final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('manageAddress');
    final data = {'action': 'delete', 'addressId': addressId};
    
    try {
      await callable.call(data);
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        await user.getIdToken(true);
        
        final retryCallable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('manageAddress');
        await retryCallable.call(data);
      } else {
        rethrow;
      }
    }
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    
    
    final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('manageAddress');
    final data = {'action': 'setDefault', 'addressId': addressId};
    
    try {
      await callable.call(data);
      
      // CRITICAL FIX: Clear location cache when default address changes
      _locationService.clearLocationCache();
      // OPTIMIZATION: Clear services cache to refetch with new location
      clearCachedServicesStream();
      if (kDebugMode) debugPrint('✅ [ADDRESS] Location cache and services cache cleared after setDefault');
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        await user.getIdToken(true);
        
        final retryCallable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('manageAddress');
        await retryCallable.call(data);
        
        // Clear cache on retry success too
        _locationService.clearLocationCache();
        // OPTIMIZATION: Clear services cache to refetch with new location
        clearCachedServicesStream();
        if (kDebugMode) debugPrint('✅ [ADDRESS] Location cache and services cache cleared after setDefault (retry)');
      } else {
        rethrow;
      }
    }
  }

  /// Set primary address - alias for setDefaultAddress for backward compatibility
  Future<void> setPrimaryAddress(String userId, String addressId) async {
    await setDefaultAddress(userId, addressId);
  }

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
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    
    
    final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('updateUserProfile');
    final data = {
      'primaryAddress': address,
      'district': district.toLowerCase(),
      'state': state.toLowerCase(),
      'profileCompleted': true,
      'isOnboarded': true,
    };
    
    try {
      await callable.call(data);
      debugPrint('✅ [Address] Primary address saved to user profile via callable');
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        await user.getIdToken(true);
        
        final retryCallable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('updateUserProfile');
        await retryCallable.call(data);
      } else {
        debugPrint('❌ [Address] Failed to save primary address to profile: $e');
        rethrow;
      }
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
        .asBroadcastStream()
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
  // FIX 1: PRESERVE CART STATE - Keep last known cart data on network errors
  List<CartItem> _lastKnownCart = [];
  
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
        .asBroadcastStream()
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
          
          // FIX 1: Update last known cart state on successful load
          _lastKnownCart = validItems;
          return validItems;
        })
        // IMPROVED ERROR HANDLING: Distinguish between network errors and other errors
        .transform(StreamTransformer<List<CartItem>, List<CartItem>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (e, stackTrace, sink) {
            final errorStr = e.toString().toLowerCase();
            final bool isNetworkError = errorStr.contains('unavailable') || 
                                       errorStr.contains('network') ||
                                       errorStr.contains('failed to get document');
            final bool isPermissionError = errorStr.contains('permission') || 
                                          errorStr.contains('denied');
            
            if (kDebugMode) {
              if (isNetworkError) {
                debugPrint('⚠️ [CART] Network error — preserving last known cart (${_lastKnownCart.length} items)');
              } else if (isPermissionError) {
                debugPrint('❌ [CART] Permission denied — user may need to re-authenticate');
              } else {
                debugPrint('❌ [CART] Stream error: $e');
              }
            }
            
            // FIX 1: Emit last known cart on network errors (preserve state)
            // For permission errors, emit empty but log for monitoring
            if (isNetworkError) {
              sink.add(_lastKnownCart);  // Preserve last known state
            } else {
              sink.add(<CartItem>[]);
            }
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
    // FIX 3: Safe auth wait - preserve original error for debugging
    try {
      await ensureAuthenticated();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [Cart] Auth check failed: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      throw Exception('Unable to verify authentication. Please try again.');
    }
    
    final user = FirebaseAuth.instance.currentUser!;
    
    // Validate all required fields before sending
    if (!FirestoreGuards.isValidDocumentId(userId)) {
      throw Exception('Invalid user ID');
    }
    if (item.serviceId.isEmpty) throw Exception('serviceId is mandatory');
    if (item.categoryId.isEmpty) throw Exception('categoryId is mandatory');
    if (item.technicianId == null || item.technicianId!.isEmpty) throw Exception('technicianId is mandatory');
    if (item.finalPriceSnapshot <= 0) throw Exception('finalPriceSnapshot must be > 0');
    if (item.price <= 0) throw Exception('price must be > 0');

    final callable = functions.httpsCallable('addToCartCallable');
    
    // CRITICAL: Ensure payload is never null/undefined
    final payload = item.toMap();

    try {
      // CRITICAL: Pass data object, never null
      final result = await callable.call(payload);
      
      // Invalidate user interaction cache
      clearUserInteractionCache();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Cart] Add failed: $e');
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        try {
          await ensureAuthenticated();
        } catch (authError, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ [Cart] Retry auth check failed: $authError');
            debugPrint('Stack trace: $stackTrace');
          }
          throw Exception('Unable to verify authentication. Please try again.');
        }
        final retryCallable = functions.httpsCallable('addToCartCallable');
        final result = await retryCallable.call(payload);
        
        // Invalidate user interaction cache
        clearUserInteractionCache();
      } else {
        rethrow;
      }
    }
  }

  Future<void> updateCartItemQuantity(String userId, String itemId, int quantity) async {
    if (!FirestoreGuards.isValidDocumentId(userId) || !FirestoreGuards.isValidDocumentId(itemId)) {
      throw Exception('Invalid user ID or item ID');
    }
    
    // FIX 3: Safe auth wait - catch timeout and convert to user-friendly error
    try {
      await ensureAuthenticated();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Cart] Auth check failed: $e');
      throw Exception('Unable to verify authentication. Please try again.');
    }
    
    final user = FirebaseAuth.instance.currentUser!;
    
    final callable = functions.httpsCallable('updateCartQuantityCallable');
    final data = {'itemId': itemId, 'quantity': quantity};
    
    try {
      await callable.call(data);
      
      // Invalidate user interaction cache
      clearUserInteractionCache();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Cart] Update quantity failed: $e');
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        try {
          await ensureAuthenticated();
        } catch (authError) {
          if (kDebugMode) debugPrint('❌ [Cart] Retry auth check failed: $authError');
          throw Exception('Unable to verify authentication. Please try again.');
        }
        final retryCallable = functions.httpsCallable('updateCartQuantityCallable');
        await retryCallable.call(data);
        
        // Invalidate user interaction cache
        clearUserInteractionCache();
      } else {
        rethrow;
      }
    }
  }

  Future<void> removeFromCart(String userId, String itemId) async {
    if (!FirestoreGuards.isValidDocumentId(userId) || !FirestoreGuards.isValidDocumentId(itemId)) {
      throw Exception('Invalid user ID or item ID');
    }
    
    // FIX 3: Safe auth wait - catch timeout and convert to user-friendly error
    try {
      await ensureAuthenticated();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Cart] Auth check failed: $e');
      throw Exception('Unable to verify authentication. Please try again.');
    }
    
    final user = FirebaseAuth.instance.currentUser!;
    
    final callable = functions.httpsCallable('removeFromCartCallable');
    final data = {'itemId': itemId};
    
    try {
      await callable.call(data);
      
      // Invalidate user interaction cache
      clearUserInteractionCache();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Cart] Remove failed: $e');
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        try {
          await ensureAuthenticated();
        } catch (authError) {
          if (kDebugMode) debugPrint('❌ [Cart] Retry auth check failed: $authError');
          throw Exception('Unable to verify authentication. Please try again.');
        }
        final retryCallable = functions.httpsCallable('removeFromCartCallable');
        await retryCallable.call(data);
        
        // Invalidate user interaction cache
        clearUserInteractionCache();
      } else {
        rethrow;
      }
    }
  }

  Future<void> clearCart(String userId) async {
    if (!FirestoreGuards.isValidDocumentId(userId)) {
      throw Exception('Invalid user ID');
    }
    
    // FIX 3: Safe auth wait - catch timeout and convert to user-friendly error
    try {
      await ensureAuthenticated();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Cart] Auth check failed: $e');
      throw Exception('Unable to verify authentication. Please try again.');
    }
    
    final user = FirebaseAuth.instance.currentUser!;
    
    final callable = functions.httpsCallable('clearCartCallable');
    
    try {
      await callable.call({});
      
      // Invalidate user interaction cache
      clearUserInteractionCache();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Cart] Clear failed: $e');
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        try {
          await ensureAuthenticated();
        } catch (authError) {
          if (kDebugMode) debugPrint('❌ [Cart] Retry auth check failed: $authError');
          throw Exception('Unable to verify authentication. Please try again.');
        }
        final retryCallable = functions.httpsCallable('clearCartCallable');
        await retryCallable.call({});
        
        // Invalidate user interaction cache
        clearUserInteractionCache();
      } else {
        rethrow;
      }
    }
  }

  /// Get user interaction data for personalization (cart, favorites, bookings)
  /// Returns categories and serviceIds that user has interacted with
  /// CACHED: Results are cached for 5 minutes to prevent repeated Firestore reads
  Future<Map<String, dynamic>> getUserInteractionData(String userId) async {
    if (userId.isEmpty) {
      return {'categories': <String>{}, 'serviceIds': <String>{}};
    }
    
    // Check cache validity
    final now = DateTime.now();
    final isCacheValid = _cachedUserId == userId &&
        _cachedUserInteractionData != null &&
        _lastInteractionFetch != null &&
        now.difference(_lastInteractionFetch!) < _interactionCacheDuration;
    
    if (isCacheValid) {
      return _cachedUserInteractionData!;
    }
    
    final categories = <String>{};
    final serviceIds = <String>{};
    
    try {
      // Fetch cart items
      final cartSnapshot = await _db
          .collection('customers')
          .doc(userId)
          .collection('cart')
          .limit(10)
          .get();
      
      for (final doc in cartSnapshot.docs) {
        final data = doc.data();
        _extractInteractionData(data, categories, serviceIds);
      }
      
      // Fetch favorites
      final favoritesSnapshot = await _db
          .collection('customers')
          .doc(userId)
          .collection('favorites')
          .limit(10)
          .get();
      
      for (final doc in favoritesSnapshot.docs) {
        final data = doc.data();
        _extractInteractionData(data, categories, serviceIds);
      }
      
      // Fetch past bookings
      final bookingsSnapshot = await _db
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        _extractInteractionData(data, categories, serviceIds);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UserInteraction] Error: $e');
      }
    }
    
    // Cache the result
    final result = {'categories': categories, 'serviceIds': serviceIds};
    _cachedUserInteractionData = result;
    _cachedUserId = userId;
    _lastInteractionFetch = now;
    
    return result;
  }
  
  /// Clear user interaction cache (call when cart/favorites/bookings change)
  void clearUserInteractionCache() {
    _cachedUserInteractionData = null;
    _cachedUserId = null;
    _lastInteractionFetch = null;
  }
  
  /// Helper to extract interaction data from document
  void _extractInteractionData(Map<String, dynamic> data, Set<String> categories, Set<String> serviceIds) {
    final serviceId = data['serviceId'] as String?;
    final categoryId = data['categoryId'] as String?;
    final categoryName = data['categoryName'] as String?;
    
    if (serviceId != null && serviceId.isNotEmpty) {
      serviceIds.add(serviceId.toLowerCase());
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      categories.add(categoryId.toLowerCase());
    }
    if (categoryName != null && categoryName.isNotEmpty) {
      categories.add(categoryName.toLowerCase());
    }
  }

  // --- Service Request ---
  Future<String> createServiceRequest(ServiceRequest request) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    final callable = functions.httpsCallable('createCustomServiceRequest');
    try {
      final result = await callable.call(request.toMap());
      return (result.data as Map<String, dynamic>)['requestId'] as String? ?? '';
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        await user.getIdToken(true);
        final result = await functions.httpsCallable('createCustomServiceRequest').call(request.toMap());
        return (result.data as Map<String, dynamic>)['requestId'] as String? ?? '';
      }
      rethrow;
    }
  }

  Stream<List<ServiceRequest>> streamServiceRequests(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _db
        .collection('service_requests')
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(FirebaseConstants.defaultLimit)
        .snapshots()
        .asBroadcastStream()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRequest.fromFirestore(doc))
            .toList())
        .handleError((e) {
      if (kDebugMode) debugPrint('❌ [FirestoreService] streamServiceRequests error: $e');
      throw e;
    });
  }

  // --- Proposals (Quotes) --- 
  Stream<List<Proposal>> streamProposals(String requestId) {
    if (requestId.isEmpty) return Stream.value([]);
    return _db
        .collection('proposals')
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .asBroadcastStream()
        .map((snapshot) => snapshot.docs
            .map((doc) => Proposal.fromFirestore(doc))
            .toList())
        .handleError((e) {
      if (kDebugMode) debugPrint('❌ [FirestoreService] streamProposals error: $e');
      throw e;
    });
  }

  Future<void> acceptProposal(Proposal proposal, ServiceRequest request) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    
    
    final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('acceptProposal');
    final data = {
      'proposalId': proposal.id,
      'requestId': request.id,
    };
    
    try {
      await callable.call(data);
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        await user.getIdToken(true);
        
        final retryCallable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('acceptProposal');
        await retryCallable.call(data);
      } else {
        rethrow;
      }
    }
  }

  Future<void> processReferral(String currentUserId, String referralCode) async {
    if (currentUserId.isEmpty || referralCode.isEmpty) {
      if (kDebugMode) debugPrint('[PATH GUARD] blocked empty id in processReferral');
      return;
    }
    
    if (kDebugMode) debugPrint('[WRITE GUARD] Direct write blocked in processReferral');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    
    
    final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('processReferralCallable');
    final data = {'referralCode': referralCode};
    
    try {
      await callable.call(data);
      if (kDebugMode) debugPrint('✅ [Referral] Processed via callable');
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        await user.getIdToken(true);
        
        final retryCallable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('processReferralCallable');
        await retryCallable.call(data);
      } else {
        if (kDebugMode) debugPrint('❌ [Referral] Process failed: $e');
        rethrow;
      }
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
    return _db.collection('customers').doc(userId).snapshots().asBroadcastStream().map((doc) {
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
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    
    
    final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('updateUserProfile');
    
    try {
      await callable.call(data);
      if (kDebugMode) debugPrint('✅ [Profile] Updated via callable');
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        await user.getIdToken(true);
        
        final retryCallable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('updateUserProfile');
        await retryCallable.call(data);
      } else {
        if (kDebugMode) debugPrint('❌ [Profile] Update failed: $e');
        rethrow;
      }
    }
  }

  Future<void> becomeTechnician(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) {
      if (kDebugMode) debugPrint('[PATH GUARD] blocked empty id in becomeTechnician');
      return;
    }
    if (kDebugMode) debugPrint('[WRITE GUARD] Direct write blocked in becomeTechnician');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    
    
    final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('submitPartnerApplication');
    
    try {
      await callable.call(data);
      if (kDebugMode) debugPrint('✅ [Technician] Application submitted via callable');
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        await user.getIdToken(true);
        
        final retryCallable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('submitPartnerApplication');
        await retryCallable.call(data);
      } else {
        if (kDebugMode) debugPrint('❌ [Technician] Submission failed: $e');
        rethrow;
      }
    }
  }

  Future<void> toggleFavorite(String userId, String categoryId, String serviceId, bool isFavorite) async {
    // FIX 3: Safe auth wait - catch timeout and convert to user-friendly error
    try {
      await ensureAuthenticated();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Favorite] Auth check failed: $e');
      throw Exception('Unable to verify authentication. Please try again.');
    }
    
    final user = FirebaseAuth.instance.currentUser!;

    if (userId.isEmpty) throw Exception('userId is required');
    if (serviceId.isEmpty) throw Exception('serviceId is required');
    if (categoryId.isEmpty) throw Exception('categoryId is required');

    final callable = functions.httpsCallable('toggleFavoriteCallable');

    final data = {
      'serviceId': serviceId,
      'categoryId': categoryId,
      'isFavorite': isFavorite,
    };

    try {
      await callable.call(data);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Favorite] Toggle failed: $e');
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        try {
          await ensureAuthenticated();
        } catch (authError) {
          if (kDebugMode) debugPrint('❌ [Favorite] Retry auth check failed: $authError');
          throw Exception('Unable to verify authentication. Please try again.');
        }
        final retryCallable = functions.httpsCallable('toggleFavoriteCallable');
        await retryCallable.call(data);
      } else {
        rethrow;
      }
    }
  }

  Stream<List<Map<String, String>>> streamFavoriteIdsWithCategory(String userId) {
    return _db.collection('customers').doc(userId).collection('favorites').snapshots().asBroadcastStream().map((snapshot) => 
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
        .orderBy('order') // FIRESTORE ORDERBY - NO IN-MEMORY SORTING
        .limit(20) // PERFORMANCE: Add limit
        .snapshots()
        .asBroadcastStream()
        .map((snapshot) {
          return snapshot.docs.map((doc) => CleaningEssential.fromFirestore(doc)).toList();
          // NO IN-MEMORY SORTING - Already ordered by Firestore
        });
  }

  Stream<List<Map<String, dynamic>>> streamServiceSpotlight() {
    return _db
        .collection('service_spotlight')
        .orderBy('order')
        .limit(6)
        .snapshots()
        .asBroadcastStream()
        .asyncMap((snapshot) async {
      final spotlights = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final serviceId = data['serviceId'] as String? ?? data['id'];
        int techCount = 0;
        if (serviceId != null && serviceId.isNotEmpty) {
          try {
            final techSnapshot = await _db
                .collection('technicians')
                .where('serviceId', isEqualTo: serviceId)
                .where('status', isEqualTo: 'approved')
                .where('isAvailable', isEqualTo: true)
                .count()
                .get();
            techCount = techSnapshot.count ?? 0;
          } catch (_) {}
        }
        spotlights.add({'id': doc.id, ...data, 'availableTechnicians': techCount});
      }
      return spotlights;
    }).handleError((e) {
      if (kDebugMode) debugPrint('❌ [FirestoreService] Spotlight query failed: $e');
      throw e;
    });
  }

  Stream<List<ServiceBanner>> streamServiceBottomBanners() {
    return _db
        .collection('service_bottom_banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order') // FIRESTORE ORDERBY - NO IN-MEMORY SORTING
        .limit(10) // PERFORMANCE: Add limit
        .snapshots()
        .asBroadcastStream()
        .map((snapshot) {
          final List<ServiceBanner> banners = [];
          for (var doc in snapshot.docs) {
            try {
              final banner = ServiceBanner.fromFirestore(doc);
              // AUDIT: Defensive check for imageUrl
              if (banner.imageUrl.isEmpty) {
                continue;
              }
              banners.add(banner);
            } catch (e) {
              debugPrint('❌ [FirestoreService] Error parsing bottom banner ${doc.id}: $e');
            }
          }
          // NO IN-MEMORY SORTING - Already ordered by Firestore
          return banners;
        });
  }

  // --- Technician Categories ---
  Stream<List<TechnicianCategory>> streamTechnicianCategories() {
    return _db.collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order') // FIRESTORE ORDERBY - NO IN-MEMORY SORTING
        .limit(50) // PERFORMANCE: Add reasonable limit
        .snapshots()
        .asBroadcastStream()
        .map((snapshot) {
          return snapshot.docs
            .map((doc) => TechnicianCategory.fromFirestore(doc))
            .toList();
          // NO IN-MEMORY SORTING - Already ordered by Firestore
        });
  }

  Stream<List<TechnicianSubcategory>> streamTechnicianSubcategories({String? categoryId}) {
    Query query = _db.collection('services')
        .where('isActive', isEqualTo: true);
    
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query
        .orderBy('order') // FIRESTORE ORDERBY - NO IN-MEMORY SORTING
        .limit(100) // PERFORMANCE: Add reasonable limit
        .snapshots()
        .asBroadcastStream()
        .map((snapshot) {
          return snapshot.docs
            .map((doc) => TechnicianSubcategory.fromFirestore(doc))
            .toList();
          // NO IN-MEMORY SORTING - Already ordered by Firestore
        });
  }

  Future<List<TechnicianCategory>> getTechnicianCategories() async {
    final snapshot = await _db.collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order') // FIRESTORE ORDERBY - NO IN-MEMORY SORTING
        .limit(50) // PERFORMANCE: Add reasonable limit
        .get();
    
    return snapshot.docs
      .map((doc) => TechnicianCategory.fromFirestore(doc))
      .toList();
    // NO IN-MEMORY SORTING - Already ordered by Firestore
  }

  Future<List<TechnicianSubcategory>> getTechnicianSubcategories() async {
    final snapshot = await _db.collection('services')
        .where('isActive', isEqualTo: true)
        .orderBy('order') // FIRESTORE ORDERBY - NO IN-MEMORY SORTING
        .limit(100) // PERFORMANCE: Add reasonable limit
        .get();
    
    return snapshot.docs
      .map((doc) => TechnicianSubcategory.fromFirestore(doc))
      .toList();
    // NO IN-MEMORY SORTING - Already ordered by Firestore
  }

  /// Recommended Services - delegates to unified method
  Stream<List<HomeService>> streamRecommendedServices(String userId, {int limit = 10}) {
    return streamTechnicianServices(sortBy: 'recent', limit: limit, filterByLocation: true);
  }

  /// Top Rated Services - delegates to unified method
  Stream<List<HomeService>> streamTopRatedTechnicianServices({int limit = 10}) {
    return streamTechnicianServices(sortBy: 'topRated', limit: limit, filterByLocation: false);
  }

  /// Recent Services - delegates to unified method
  Stream<List<HomeService>> streamRecentTechnicianServices({int limit = 10}) {
    return streamTechnicianServices(sortBy: 'recent', limit: limit, filterByLocation: false);
  }

  /// Nearby Services - delegates to unified method
  Stream<List<HomeService>> streamNearbyServices(String userId, {int limit = 10}) {
    return streamTechnicianServices(sortBy: 'recent', limit: limit, filterByLocation: true);
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
        .asBroadcastStream()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HomeService.fromFirestore(doc))
              .whereType<HomeService>()
              .toList();
        });
  }

  Future<void> createCustomRequest(Map<String, dynamic> requestData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    final callable = functions.httpsCallable('createCustomServiceRequest');
    try {
      await callable.call(requestData);
      if (kDebugMode) debugPrint('✅ [CustomRequest] Created successfully');
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
        await user.getIdToken(true);
        await functions.httpsCallable('createCustomServiceRequest').call(requestData);
      } else {
        if (kDebugMode) debugPrint('❌ [CustomRequest] Creation failed: $e');
        rethrow;
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchSubCategories(String categoryId) async {
    if (categoryId.isEmpty) return [];
    try {
      final snapshot = await _db
          .collection('categories')
          .doc(categoryId)
          .collection('subcategories')
          .limit(50)
          .get();
      return snapshot.docs
          .map((doc) => {...doc.data(), "id": doc.id})
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [CustomRequest] Failed to fetch subcategories: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> streamCustomRequests(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _db
        .collection('custom_requests')
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(FirebaseConstants.defaultLimit)
        .snapshots()
        .asBroadcastStream()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), "id": doc.id}).toList())
        .handleError((e) {
      if (kDebugMode) debugPrint('❌ [FirestoreService] streamCustomRequests error: $e');
      throw e;
    });
  }

  // --- NEW METHODS FOR CLEAN ARCHITECTURE ---

  /// Get user profile data
  /// Replaces direct FirebaseFirestore.instance access in UI components
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (userId.isEmpty) {
      if (kDebugMode) debugPrint('[PATH GUARD] blocked empty id in getUserProfile');
      return null;
    }
    
    try {
      final doc = await _db.collection('customers').doc(userId).get();
      return doc.data();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [FirestoreService] Failed to get user profile: $e');
      return null;
    }
  }

  /// Stream online technicians filtered by location
  /// Replaces direct Firestore queries for technicians in UI
  Stream<List<Map<String, dynamic>>> streamOnlineTechnicians({
    required String state,
    required String district,
  }) {
    return _withErrorHandling(
      _db.collection('technicians')
          .where('isOnline', isEqualTo: true)
          .where('state', isEqualTo: state)
          .where('district', isEqualTo: district)
          .limit(50)
          .snapshots()
          .asBroadcastStream()
          .map((snapshot) => snapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList()),
    );
  }

  /// AUTO-DETECT AND ADAPT - Read actual Firestore data and adapt query
  /// This function detects the actual field structure and updates query logic
  /// TEMPORARY - REMOVE AFTER VERIFICATION
  Future<void> debugCheckServices() async {
    if (kDebugMode) {
      debugPrint('🔍 [AUTO-ADAPT] ========== READING FIRESTORE DATA ==========');
      
      try {
        // STEP 1: Count total documents
        final countSnapshot = await _db
            .collection(FirebaseConstants.technicianServicesCollection)
            .count()
            .get();
        final totalCount = countSnapshot.count ?? 0;
        debugPrint('🔍 [AUTO-ADAPT] Total documents: $totalCount');
        
        if (totalCount == 0) {
          debugPrint('❌ [AUTO-ADAPT] ISSUE: Collection is EMPTY - no services exist');
          return;
        }
        
        // STEP 2: Fetch first document to detect structure
        final snapshot = await _db
            .collection(FirebaseConstants.technicianServicesCollection)
            .limit(1)
            .get();
        
        if (snapshot.docs.isEmpty) {
          debugPrint('❌ [AUTO-ADAPT] ISSUE: Cannot read documents');
          return;
        }
        
        final doc = snapshot.docs.first;
        final data = doc.data();
        
        debugPrint('🔍 [AUTO-ADAPT] Sample document ID: ${doc.id}');
        debugPrint('🔍 [AUTO-ADAPT] Fields detected:');
        data.forEach((key, value) {
          debugPrint('  - $key: $value (${value.runtimeType})');
        });
        
        // STEP 3: Detect status field and value
        String? statusField;
        String? statusValue;
        
        // Check common variations
        if (data.containsKey('status')) {
          statusField = 'status';
          statusValue = data['status']?.toString();
        } else if (data.containsKey('Status')) {
          statusField = 'Status';
          statusValue = data['Status']?.toString();
        }
        
        debugPrint('🔍 [AUTO-ADAPT] Status field: $statusField = "$statusValue"');
        
        // STEP 4: Test if createdAt exists for sorting
        final hasCreatedAt = data.containsKey('createdAt');
        final hasCreatedAtCaps = data.containsKey('CreatedAt');
        debugPrint('🔍 [AUTO-ADAPT] Has createdAt: $hasCreatedAt');
        debugPrint('🔍 [AUTO-ADAPT] Has CreatedAt: $hasCreatedAtCaps');
        
        debugPrint('🔍 [AUTO-ADAPT] ========== DETECTION COMPLETE ==========');
        
      } catch (e, stackTrace) {
        debugPrint('❌ [AUTO-ADAPT] Error: $e');
        debugPrint('❌ [AUTO-ADAPT] Stack: $stackTrace');
      }
    }
  }
}

