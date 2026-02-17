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
  
  // Create a new booking (Harden: Use FunctionsService instead of direct write)
  // This method is now legacy, all callers should move to FunctionsService.createBooking
  Future<String> createBooking(Booking booking) async {
    final callable = FirebaseFunctions.instance.httpsCallable('createBookingV2');
    final result = await callable.call(booking.toMap());
    return result.data['bookingId'] ?? "";
  }

  // Get Services - supports simple filtering (UNIFIED: Now uses collectionGroup to support nested categories as source)
  Stream<List<HomeService>> streamServices({
    bool isTopOnly = false, 
    String? category, 
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    // Single source of truth is nested: categories/{catId}/services
    // We use collectionGroup to fetch them all globally
    Query query = _db.collectionGroup('services')
        .where('isActive', isEqualTo: true)
        .orderBy('order') // MANDATORY: Proper ordering for index consistency
        .limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    if (isTopOnly) {
      // Note: This would require a composite index (collectionGroup + isActive + order + rating)
      // If index is missing, it will throw an error with the link to create it.
      query = query.where('rating', isGreaterThanOrEqualTo: 4.5);
    }
    
    if (category != null && category.isNotEmpty) {
      // Note: Filter by category field must still exist on the service document
      query = query.where('categoryId', isEqualTo: category);
    }
    
    return query.snapshots().map((snapshot) {
      final List<HomeService> services = [];
      
      for (var doc in snapshot.docs) {
        try {
          final service = HomeService.fromFirestore(doc);
          if (service == null) continue;
          
          // AUDIT: Defensive check for imageUrl
          if (service.imageUrl == null || service.imageUrl!.isEmpty) {
            debugPrint('⚠️ [FirestoreService] Skipping service ${doc.id} due to missing imageUrl');
            continue;
          }
          services.add(service);
        } catch (e) {
          debugPrint('❌ [FirestoreService] Error parsing service ${doc.id}: $e');
        }
      }

      // We maintain the Firestore order (by 'order' field)
      return services;
    }).handleError((error) {
       if (error.toString().contains('failed-precondition')) {
         debugPrint('🚨 [FirestoreService] MISSING INDEX ERROR. Please create the required index using the link in the Firebase console.');
       }
       debugPrint('❌ [FirestoreService] Stream error: $error');
       return <HomeService>[];
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
                  debugPrint('⚠️ [FirestoreService] Skipping banner ${doc.id} due to missing imageUrl');
                  continue;
                }
                banners.add(banner);
              }
            } catch (e) {
              debugPrint('❌ [FirestoreService] Error parsing banner ${doc.id}: $e');
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
    return _db.collection('customers').doc(userId).collection('addresses')
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


  // --- Cart Management ---
  Stream<List<CartItem>> streamCart(String userId) {
    return _db.collection('customers').doc(userId).collection('cart')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList());
  }

  Future<void> addToCart(String userId, CartItem item) async {
    // SECURITY: Verify serviceId existence before adding to cart
    final serviceDoc = await _db
        .collection('categories')
        .doc(item.categoryId)
        .collection('services')
        .doc(item.serviceId)
        .get();

    if (!serviceDoc.exists) {
      throw 'Service no longer exists';
    }

    final cartRef = _db.collection('customers').doc(userId).collection('cart');
    
    // Check if item already exists
    final existing = await cartRef.where('serviceId', isEqualTo: item.serviceId).get();
    
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final currentQty = doc.data()['quantity'] as int? ?? 0;
      final newQty = currentQty + item.quantity;
      await doc.reference.update({
        'quantity': newQty,
        'totalPrice': newQty * (doc.data()['price'] as double? ?? 0.0),
      });
    } else {
      final docRef = cartRef.doc();
      await docRef.set(item.copyWith(id: docRef.id).toMap());
    }
    
    // Track for abandonment reminders
    await _db.collection('customers').doc(userId).set({
      'lastCartUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateCartItemQuantity(String userId, String itemId, int quantity) async {
    final docRef = _db.collection('customers').doc(userId).collection('cart').doc(itemId);
    final doc = await docRef.get();
    if (doc.exists) {
      final price = doc.data()?['price'] as double? ?? 0.0;
      await docRef.update({
        'quantity': quantity,
        'totalPrice': quantity * price,
      });
      // Track for abandonment reminders
      await _db.collection('customers').doc(userId).set({
        'lastCartUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> removeFromCart(String userId, String itemId) async {
    await _db.collection('customers').doc(userId).collection('cart').doc(itemId).delete();
  }

  Future<void> clearCart(String userId) async {
    final cartRef = _db.collection('customers').doc(userId).collection('cart');
    final batch = _db.batch();
    final snapshot = await cartRef.get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
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
    final query = await _db.collection('customers').where('referralCode', isEqualTo: referralCode).get();
    if (query.docs.isEmpty) throw 'Invalid referral code';

    final referrerId = query.docs.first.id;
    if (referrerId == currentUserId) throw 'Cannot refer yourself';

    final batch = _db.batch();
    batch.update(_db.collection('customers').doc(referrerId), {'walletBalance': FieldValue.increment(50.0)});
    batch.update(_db.collection('customers').doc(currentUserId), {
      'walletBalance': FieldValue.increment(50.0),
      'referredBy': referralCode,
    });

    final tRef1 = _db.collection('wallet_transactions').doc();
    batch.set(tRef1, {
      'userId': referrerId,
      'amount': 50.0,
      'type': 'credit',
      'reason': 'Referral Bonus',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final tRef2 = _db.collection('wallet_transactions').doc();
    batch.set(tRef2, {
      'userId': currentUserId,
      'amount': 50.0,
      'type': 'credit',
      'reason': 'Referral Bonus',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // --- User Profile ---
  Future<void> updateUserDefaultAddress(String userId, String address) async {
    await _db.collection('customers').doc(userId).set({'defaultAddress': address, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
  
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _db.collection('customers').doc(userId).get();
    return doc.data();
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _db.collection('customers').doc(userId).update(data);
  }

  /// Update user profile image URL
  /// CRITICAL: Only updates profileImageUrl field
  Future<void> updateProfileImageUrl(String userId, String imageUrl) async {
    await _db.collection('customers').doc(userId).set({
      'photoUrl': imageUrl,
      'profileImageUrl': imageUrl, // Keep both for compatibility
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    await _db.collection('customers').doc(userId).set(data, SetOptions(merge: true));
  }

  Future<void> becomeTechnician(String userId, Map<String, dynamic> data) async {
    await _db.collection('technician_applications').doc(userId).set({
      ...data,
      'userId': userId,
      'status': 'pending',
      'appliedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Favorites --- Harden: Added categoryId to ensure correct service lookup in nested structure
  Future<void> toggleFavorite(String userId, String categoryId, String serviceId, bool isFavorite) async {
    final docRef = _db.collection('customers').doc(userId).collection('favorites').doc(serviceId);
    if (isFavorite) {
      await docRef.set({
        'serviceId': serviceId,
        'categoryId': categoryId,
        'addedAt': FieldValue.serverTimestamp()
      });
    } else {
      await docRef.delete();
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
      for (const item in items) {
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
  Stream<List<ProfessionalReel>> streamProfessionalReels() {
    debugPrint("[Firestore] streaming celebrating_professionals...");
    return _db
        .collection('celebrating_professionals')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          debugPrint("[Firestore] celebrating_professionals docs: ${snapshot.docs.length}");
          final reels = snapshot.docs.map((doc) => ProfessionalReel.fromFirestore(doc)).toList();
          reels.sort((a, b) => a.order.compareTo(b.order));
          return reels;
        });
  }

  Stream<List<CleaningEssential>> streamCleaningEssentials() {
    debugPrint("[Firestore] streaming cleaning_essentials...");
    return _db
        .collection('cleaning_essentials')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          debugPrint("[Firestore] cleaning_essentials docs: ${snapshot.docs.length}");
          final essentials = snapshot.docs.map((doc) => CleaningEssential.fromFirestore(doc)).toList();
          // Sort by order field in-memory
          essentials.sort((a, b) => a.order.compareTo(b.order));
          return essentials;
        });
  }

  Stream<List<Map<String, dynamic>>> streamServiceSpotlight() {
    return _db.collection('service_spotlight').limit(6).snapshots().asyncMap((snapshot) async {
      final spotlights = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final serviceId = data['serviceId'] as String? ?? data['id'];
        int techCount = 0;
        if (serviceId != null && serviceId.isNotEmpty) {
          final techSnapshot = await _db.collection('technicians').where('serviceId', isEqualTo: serviceId).where('status', isEqualTo: 'approved').where('isAvailable', isEqualTo: true).get();
          techCount = techSnapshot.docs.length;
        }
        spotlights.add({'id': doc.id, ...data, 'availableTechnicians': techCount});
      }
      return spotlights;
    });
  }

  Stream<List<ServiceBanner>> streamServiceBottomBanners() {
    debugPrint("[Firestore] streaming service_bottom_banners...");
    return _db
        .collection('service_bottom_banners')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          debugPrint("[Firestore] service_bottom_banners docs: ${snapshot.docs.length}");
          final List<ServiceBanner> banners = [];
          for (var doc in snapshot.docs) {
            try {
              final banner = ServiceBanner.fromFirestore(doc);
              // AUDIT: Defensive check for imageUrl
              if (banner.imageUrl.isEmpty) {
                debugPrint('⚠️ [FirestoreService] Skipping bottom banner ${doc.id} due to missing imageUrl');
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
    return _db.collection('technician_categories')
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
    Query query = _db.collection('technician_subcategories')
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
    final snapshot = await _db.collection('technician_categories')
        .where('isActive', isEqualTo: true)
        .get();
    
    final categories = snapshot.docs
      .map((doc) => TechnicianCategory.fromFirestore(doc))
      .toList();
    categories.sort((a, b) => a.order.compareTo(b.order));
    return categories;
  }

  Future<List<TechnicianSubcategory>> getTechnicianSubcategories() async {
    final snapshot = await _db.collection('technician_subcategories')
        .where('isActive', isEqualTo: true)
        .get();
    
    final subcategories = snapshot.docs
      .map((doc) => TechnicianSubcategory.fromFirestore(doc))
      .toList();
    subcategories.sort((a, b) => a.order.compareTo(b.order));
    return subcategories;
  }
}
