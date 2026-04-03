import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../firebase/functions_instance.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseFirestore get db => _db;

  /// Creates a new booking request (NEW FLOW)
  /// 
  /// This replaces createBookingV2 with the admin-approval flow:
  /// 1. Customer creates booking → status: pending_admin
  /// 2. Admin approves → status: technician_pending
  /// 3. Technician accepts → status: awaiting_payment
  /// 4. Customer pays → status: confirmed
  Future<Map<String, dynamic>> createBookingRequest({
    required String serviceId,
    required String technicianId,
    required String categoryId,
    required String categoryName,
    required String scheduledDate,
    required String scheduledTime,
    required Map<String, dynamic> address,
    required double price,
    String? subcategoryId,
    int? quantity,
    int? durationMinutes,
    String? couponCode,
    String? idempotencyKey,
    String? paymentMode,
  }) async {
    try {
      // Sanitize address - remove FieldValue and non-JSON types
      final cleanAddress = <String, dynamic>{};
      address.forEach((key, value) {
        if (value == null) return;
        final valueStr = value.toString();
        if (valueStr.contains('FieldValue') || valueStr.contains('Instance of')) return;
        if (value is String || value is num || value is bool || value is List || value is Map) {
          cleanAddress[key] = value;
        }
      });
      
      // Build payload with only valid JSON types
      final payload = {
        'serviceId': serviceId,
        'technicianId': technicianId,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'address': cleanAddress,
        'price': price,
        'idempotencyKey': idempotencyKey ?? 'BK_${DateTime.now().millisecondsSinceEpoch}',
      };
      
      // Add optional fields only if provided
      if (subcategoryId != null && subcategoryId.isNotEmpty) {
        payload['subcategoryId'] = subcategoryId;
      }
      if (quantity != null && quantity > 0) {
        payload['quantity'] = quantity;
      }
      if (durationMinutes != null) {
        payload['durationMinutes'] = durationMinutes;
      }
      if (couponCode != null && couponCode.isNotEmpty) {
        payload['couponCode'] = couponCode;
      }
      if (paymentMode != null && paymentMode.isNotEmpty) {
        payload['paymentMode'] = paymentMode;
      }
      
      // CRITICAL: Ensure auth is ready before ANY function call
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      // Debug logging
      print('[AUTH DEBUG] UID: ${user.uid}');
      print('[AUTH DEBUG] Token: ${await user.getIdToken()}');
      print('[BOOKING_FLOW] Sending booking payload: $payload');
      
      
      final HttpsCallable callable = FunctionsService.instance.httpsCallable('createBookingRequest');
      final results = await callable.call(payload);
      
      print('[BOOKING_FLOW] Cloud Function response: ${results.data}');
      return results.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint("Error creating booking request: $e");
      rethrow;
    }
  }

  Stream<List<Booking>> getCustomerBookings(String customerId) {
    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList())
        .handleError((e) {
      // FIX 3 & 4: Firestore Network Resilience - handle UNAVAILABLE and other errors gracefully
      final errorStr = e.toString().toLowerCase();
      final bool isUnavailable = errorStr.contains('unavailable') || errorStr.contains('network');
      
      if (kDebugMode) {
        if (isUnavailable) {
          debugPrint('⚠️ [BookingService] Network unavailable - returning empty list');
        } else {
          debugPrint('❌ [BookingService] Error fetching customer bookings (logged once): $e');
        }
      }
      // Return empty list, NEVER crash, NEVER infinite loader
      return <Booking>[];
    });
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      final HttpsCallable callable = FunctionsService.instance.httpsCallable('updateBookingStatusNew');
      await callable.call({
        'bookingId': bookingId,
        'status': 'cancelled',
        'reason': reason,
      });
    } catch (e) {
      if (kDebugMode) debugPrint("Error cancelling booking via Function: $e");
      rethrow;
    }
  }

  /// Confirm payment for a booking (NEW FLOW)
  /// 
  /// Call this when status is 'awaiting_payment'
  /// paymentMethod: 'online' or 'cash'
  Future<Map<String, dynamic>> confirmPayment({
    required String bookingId,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      final HttpsCallable callable = FunctionsService.instance.httpsCallable('customerConfirmPayment');
      final results = await callable.call({
        'bookingId': bookingId,
        'paymentMethod': paymentMethod,
        'paymentDetails': paymentDetails,
      });
      return results.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint("Error confirming payment: $e");
      rethrow;
    }
  }

  Stream<Booking?> getBookingStream(String bookingId) {
    return _db.collection('bookings').doc(bookingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Booking.fromFirestore(doc);
    }).handleError((e) {
      // FIX 3 & 4: Network resilience
      final errorStr = e.toString().toLowerCase();
      final bool isUnavailable = errorStr.contains('unavailable') || errorStr.contains('network');
      if (kDebugMode) {
        if (isUnavailable) {
          debugPrint('⚠️ [BookingService] Network unavailable for booking $bookingId');
        } else {
          debugPrint('❌ [BookingService] Error fetching booking $bookingId: $e');
        }
      }
      return null;
    });
  }

  Future<Booking?> getBooking(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return null;
    return Booking.fromFirestore(doc);
  }
}
