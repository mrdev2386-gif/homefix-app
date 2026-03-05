import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FunctionsService {
  late final FirebaseFunctions _functions;

  FunctionsService() {
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  }

  // Check for non-serializable types in debug mode
  void _debugCheckParameters(Map<String, dynamic> params) {
    if (!kDebugMode) return;
    try {
      _debugIsValidParameterType(params);
    } catch (e) {
      debugPrint('⚠️ Cloud Function Parameter Error: $e');
      // We don't throw here to avoid crashing, but we log loud warning
    }
  }

  void _debugIsValidParameterType(dynamic value) {
    if (value == null) return;
    if (value is String || value is num || value is bool) return;
    if (value is List) {
      for (final item in value) {
        _debugIsValidParameterType(item);
      }
      return;
    }
    if (value is Map) {
      for (final key in value.keys) {
        if (key is! String) throw Exception('Map keys must be Strings. Found: ${key.runtimeType}');
        _debugIsValidParameterType(value[key]);
      }
      return;
    }
    // Fail on custom objects (DateTime, Position, etc.) - STRICT FIX
    throw Exception('Invalid type for Cloud Function: ${value.runtimeType}. Convert to ISO String (DateTime) or Map (Objects) or use toJsonSafe().');
  }

  /// Helper to make data safe for JSON/Cloud Functions
  static Map<String, dynamic> toJsonSafe(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _makeValueSafe(value)));
  }

  static dynamic _makeValueSafe(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    if (value is DateTime) return value.millisecondsSinceEpoch; // Standardize to millis
    // Handle Timestamp if imported from cloud_firestore
    if (value.runtimeType.toString() == 'Timestamp') return value.millisecondsSinceEpoch; 
    
    if (value is List) {
      return value.map((item) => _makeValueSafe(item)).toList();
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _makeValueSafe(v)));
    }
    
    // Attempt .toJson() if available
    try {
      if (value.toJson != null) return _makeValueSafe(value.toJson());
    } catch (_) {}

    // Fallback: toString() to prevent crash, but warn
    debugPrint('⚠️ Warning: Forced string conversion for ${value.runtimeType}');
    return value.toString();
  }

  // Booking logic consolidated in BookingService and BookingProvider


  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      debugPrint('[updateUserProfile] UID: ${currentUser.uid}');
      debugPrint('[updateUserProfile] Reloading user...');
      
      // Reload user to refresh auth state
      await currentUser.reload();
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Force refresh ID token
      final token = await currentUser.getIdToken(true);
      debugPrint('[updateUserProfile] Token refreshed: ${token?.substring(0, 20)}...');
      
      // Wait for token to propagate
      await Future.delayed(const Duration(seconds: 2));
      
      debugPrint('[updateUserProfile] Payload: $userData');

      final callable = _functions.httpsCallable(
        'updateUserProfile',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      debugPrint('[updateUserProfile] Calling function...');
      final response = await callable.call(userData);
      
      debugPrint('[updateUserProfile] Response: ${response.data}');
      debugPrint('[updateUserProfile] ✅ SUCCESS');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[updateUserProfile] ❌ FirebaseFunctionsException');
      debugPrint('[updateUserProfile] Code: ${e.code}');
      debugPrint('[updateUserProfile] Message: ${e.message}');
      debugPrint('[updateUserProfile] Details: ${e.details}');
      rethrow;
    } catch (e) {
      debugPrint('[updateUserProfile] ❌ Error: $e');
      rethrow;
    }
  }

  // Create custom service request
  Future<Map<String, dynamic>> createServiceRequest(Map<String, dynamic> requestData) async {
    _debugCheckParameters(requestData);
    try {
      HttpsCallable callable = _functions.httpsCallable('createCustomServiceRequest');
      final result = await callable.call(requestData);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // Payment System
  Future<Map<String, dynamic>> initiateRazorpayPayment(String bookingId) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('initiateRazorpayPayment');
      final result = await callable.call({'bookingId': bookingId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyRazorpayPayment(Map<String, dynamic> paymentData) async {
    _debugCheckParameters(paymentData);
    try {
      HttpsCallable callable = _functions.httpsCallable('verifyRazorpayPayment');
      await callable.call(paymentData);
    } catch (e) {
      rethrow;
    }
  }

  // Referral System
  Future<Map<String, dynamic>> validateReferralCode(String code) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('validateReferralCode');
      final result = await callable.call({'code': code});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // Booking Cancellation override
  Future<void> cancelBookingExtended(String bookingId, String reason) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('updateBookingStatusNew');
      await callable.call({'bookingId': bookingId, 'status': 'cancelled', 'reason': reason});
    } catch (e) {
      rethrow;
    }
  }

  // Service Rating
  Future<void> submitServiceRating(String bookingId, double rating, String comment) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('submitServiceRating');
      await callable.call({
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Support Request
  Future<void> submitSupportRequest(String category, String message) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('submitSupportRequest');
      await callable.call({
        'category': category,
        'message': message,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Matching Logic for Cleaning Essentials
  Future<Map<String, dynamic>> findEligibleTechniciansCount(String categoryId, Map<String, double> userLocation) async {
    // Explicitly safe payload for location
    final safePayload = {
      'categoryId': categoryId,
      'userLocation': {
        'latitude': userLocation['latitude'] ?? 0.0,
        'longitude': userLocation['longitude'] ?? 0.0,
      }
    };
    
    _debugCheckParameters(safePayload);
    try {
      HttpsCallable callable = _functions.httpsCallable('findEligibleTechniciansCount');
      final result = await callable.call(safePayload);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // Save FCM Token securely
  Future<void> saveFcmToken(String token, String userType) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('saveFcmToken');
      await callable.call({
        'token': token,
        'userType': userType, // 'customer' or 'technician'
      });
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
      // Don't throw - token save failure shouldn't break the flow
    }
  }

  // Submit Partner Application
  Future<Map<String, dynamic>> submitPartnerApplication(Map<String, dynamic> applicationData) async {
    _debugCheckParameters(applicationData);
    try {
      HttpsCallable callable = _functions.httpsCallable('submitPartnerApplication');
      final result = await callable.call(applicationData);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // Save Address securely
  Future<Map<String, dynamic>> saveAddress(Map<String, dynamic> addressData) async {
    _debugCheckParameters(addressData);
    try {
      HttpsCallable callable = _functions.httpsCallable('manageAddress');
      final result = await callable.call(addressData);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // CUSTOM REQUEST FUNCTIONS
  // ==========================================

  /// Create a new custom service request (Step 3)
  Future<Map<String, dynamic>> createCustomServiceRequest(Map<String, dynamic> requestData) async {
    _debugCheckParameters(requestData);
    try {
      HttpsCallable callable = _functions.httpsCallable('createCustomServiceRequest');
      final result = await callable.call(requestData).timeout(
        const Duration(seconds: 30),
      );
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Technician: Accept or Reject a custom request
  Future<Map<String, dynamic>> technicianRespondServiceRequest(String requestId, String action, {String? reason}) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('technicianRespondServiceRequest');
      final result = await callable.call({
        'requestId': requestId,
        'action': action, // 'accept' or 'reject'
        if (reason != null) 'rejectionReason': reason,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Customer: Confirm payment for custom request
  Future<Map<String, dynamic>> customerConfirmServicePayment(String requestId, String paymentMethod) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('customerConfirmServicePayment');
      final result = await callable.call({
        'requestId': requestId,
        'paymentMethod': paymentMethod, // 'now' or 'after_service'
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Accept a proposal for a service request securely
  Future<Map<String, dynamic>> acceptProposal(String proposalId, String requestId) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('acceptProposal');
      final result = await callable.call({
        'proposalId': proposalId,
        'requestId': requestId,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }
}
