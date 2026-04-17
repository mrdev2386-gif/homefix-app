import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../firebase/functions_instance.dart';
import 'firestore_service.dart';

class BookingService {
  final FirestoreService _firestoreService;

  BookingService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  FirebaseFirestore get db => _firestoreService.db;

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
    String? subcategoryId,
    int? quantity,
    int? durationMinutes,
    String? couponCode,
    String? idempotencyKey,
    String? paymentMode,
    bool isUrgent = false,
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
        'idempotencyKey': idempotencyKey,
        'isUrgent': isUrgent,
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
      
      // Debug logging (no sensitive data)
      if (kDebugMode) {
        debugPrint('[BOOKING_FLOW] Creating booking request');
      }
      
      
      final HttpsCallable callable = FunctionsService.instance.httpsCallable('createBookingRequest');
      final results = await callable.call(payload).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Booking request timed out. Please try again.'),
      );
      
      if (kDebugMode) {
        debugPrint('[BOOKING_FLOW] Cloud Function response: ${results.data}');
      }
      return results.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint("Error creating booking request: $e");
      rethrow;
    }
  }

  Stream<List<Booking>> getCustomerBookings(String customerId) {
    return _firestoreService.streamBookings(customerId, limit: 10);
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      final HttpsCallable callable = FunctionsService.instance.httpsCallable('cancelBooking');
      await callable.call({
        'bookingId': bookingId,
        'reason': reason,
      });
    } catch (e) {
      if (kDebugMode) debugPrint("Error cancelling booking: $e");
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
    return _firestoreService.streamBookingDetail(bookingId);
  }

  Future<Booking?> getBooking(String bookingId) async {
    try {
      return await _firestoreService.streamBookingDetail(bookingId).first;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [BookingService] Error fetching booking: $e');
      return null;
    }
  }
}
