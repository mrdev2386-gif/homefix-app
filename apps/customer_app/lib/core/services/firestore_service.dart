import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  // Create a new booking
  Future<String> createBooking(Booking booking) async {
    final docRef = _db.collection('bookings').doc();
    final bookingData = booking.toMap();
    await docRef.set(bookingData);
    return docRef.id;
  }

  // Get Services - supports simple filtering
  Stream<List<HomeService>> streamServices({bool isTopOnly = false, String? category, int? limit}) {
    Query query = _db.collection('services').where('isActive', isEqualTo: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    if (isTopOnly) {
      // If it's for the top rated section, we filter by rating > 4.5
      query = query.where('rating', isGreaterThanOrEqualTo: 4.5);
    }
    
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    
    return query.snapshots().map((snapshot) {
      final services = snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).toList();
      // Sort by rating descending for top ones, or by order
      if (isTopOnly) {
        services.sort((a, b) => b.rating.compareTo(a.rating));
      } else {
        services.sort((a, b) => a.order.compareTo(b.order));
      }
      return services;
    });
  }
  
  // Get Banners - removed orderBy to avoid index requirement
  Stream<List<BannerModel>> streamBanners() {
    return _db.collection('home_banners')
        .snapshots()
        .map((snapshot) {
          final banners = snapshot.docs.map((doc) => BannerModel.fromFirestore(doc))
            .where((b) => b.active)
            .toList();
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
    final collection = _db.collection('customers').doc(userId).collection('addresses');
    if (address.id.isEmpty) {
      final docRef = collection.doc();
      await docRef.set(address.copyWith(id: docRef.id).toMap());
    } else {
      await collection.doc(address.id).set(address.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    await _db.collection('customers').doc(userId).collection('addresses').doc(addressId).delete();
  }

  // --- Cart Management ---
  Stream<List<CartItem>> streamCart(String userId) {
    return _db.collection('customers').doc(userId).collection('cart')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList());
  }

  Future<void> addToCart(String userId, CartItem item) async {
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

  Future<void> acceptProposal(Proposal proposal, ServiceRequest request) async {
    final batch = _db.batch();
    batch.update(_db.collection('proposals').doc(proposal.id), {'status': 'accepted'});
    batch.update(_db.collection('service_requests').doc(request.id), {'status': 'accepted'});

    final bookingRef = _db.collection('bookings').doc();
    final booking = Booking(
      id: bookingRef.id,
      customerId: request.customerId,
      technicianId: proposal.technicianId,
      services: [],
      serviceId: 'custom',
      serviceTitle: request.title,
      scheduledAt: proposal.proposedDateTime,
      addressSnapshot: request.address ?? {},
      status: 'accepted',
      price: proposal.quotedPrice,
      finalAmount: proposal.quotedPrice,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    batch.set(bookingRef, booking.toMap());

    final notifRef = _db.collection('notifications').doc();
    batch.set(notifRef, {
      'userId': proposal.technicianId,
      'title': 'Proposal Accepted!',
      'body': 'Your quote for ${request.title} was accepted.',
      'type': 'booking',
      'referenceId': bookingRef.id,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
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

  Stream<UserModel> streamUserModel(String userId) {
    return _db.collection('customers').doc(userId).snapshots().map((doc) => UserModel.fromFirestore(doc));
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

  // --- Favorites ---
  Future<void> toggleFavorite(String userId, String serviceId, bool isFavorite) async {
    final docRef = _db.collection('customers').doc(userId).collection('favorites').doc(serviceId);
    if (isFavorite) await docRef.set({'addedAt': FieldValue.serverTimestamp()});
    else await docRef.delete();
  }

  Stream<List<String>> streamFavoriteIds(String userId) {
    return _db.collection('customers').doc(userId).collection('favorites').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Stream<List<HomeService>> streamFavoriteServices(String userId) {
    return streamFavoriteIds(userId).asyncMap((ids) async {
      if (ids.isEmpty) return [];
      final snapshot = await _db.collection('services').where(FieldPath.documentId, whereIn: ids).get();
      return snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).toList();
    });
  }

  // --- Dashboard Data ---
  Stream<List<ProfessionalReel>> streamProfessionalReels() {
    return _db
        .collection('celebrating_professionals')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final reels = snapshot.docs.map((doc) => ProfessionalReel.fromFirestore(doc)).toList();
          reels.sort((a, b) => a.order.compareTo(b.order));
          return reels;
        });
  }

  Stream<List<CleaningCategory>> streamCleaningCategories() {
    return _db
        .collection('cleaning_categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final categories = snapshot.docs.map((doc) => CleaningCategory.fromFirestore(doc)).toList();
          categories.sort((a, b) => a.order.compareTo(b.order));
          return categories;
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
}
