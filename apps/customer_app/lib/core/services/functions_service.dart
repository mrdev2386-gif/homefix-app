import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase/functions_instance.dart' as FunctionsInstance;

class FunctionsService {

  FunctionsService();

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

  // ==========================================
  // PAYMENT FUNCTIONS
  // ==========================================

  /// Create Razorpay payment order (backend only)
  Future<Map<String, dynamic>> createPaymentOrder({required String bookingId}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('createPaymentOrder');
      final result = await callable.call({'bookingId': bookingId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify payment after Razorpay checkout
  Future<Map<String, dynamic>> verifyPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('verifyPayment');
      final result = await callable.call({
        'bookingId': bookingId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Handle payment failure or cancellation
  Future<Map<String, dynamic>> handlePaymentFailure({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String errorCode,
    required String errorDescription,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('handlePaymentFailure');
      final result = await callable.call({
        'bookingId': bookingId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'errorCode': errorCode,
        'errorDescription': errorDescription,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // END PAYMENT FUNCTIONS
  // ==========================================

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    _debugCheckParameters(userData);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      await currentUser.getIdToken(true);
      
      debugPrint('[AUTH DEBUG] UID: ${currentUser.uid}');
      debugPrint('[AUTH DEBUG] Token: ${await currentUser.getIdToken()}');
      debugPrint('[updateUserProfile] Payload: $userData');

      
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable(
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      debugPrint('[AUTH DEBUG] UID: ${user.uid}');
      debugPrint('[AUTH DEBUG] Token: ${await user.getIdToken()}');
      
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('createCustomServiceRequest');
      final result = await callable.call(requestData);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }





  // Referral System
  Future<Map<String, dynamic>> validateReferralCode(String code) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('validateReferralCode');
      final result = await callable.call({'code': code});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // Booking Cancellation override
  Future<void> cancelBookingExtended(String bookingId, String reason) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('updateBookingStatusNew');
      await callable.call({'bookingId': bookingId, 'status': 'cancelled', 'reason': reason});
    } catch (e) {
      rethrow;
    }
  }

  // Service Rating
  Future<void> submitServiceRating(String bookingId, double rating, String comment) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('submitServiceRating');
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('submitSupportRequest');
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
    final safePayload = {
      'categoryId': categoryId,
      'userLocation': {
        'latitude': userLocation['latitude'] ?? 0.0,
        'longitude': userLocation['longitude'] ?? 0.0,
      }
    };
    
    _debugCheckParameters(safePayload);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('findEligibleTechniciansCount');
      final result = await callable.call(safePayload);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  // Save FCM Token securely
  Future<void> saveFcmToken(String token, String userType) async {
    try {
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('saveFcmToken');
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('submitPartnerApplication');
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('manageAddress');
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
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('createCustomServiceRequest');
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('technicianRespondServiceRequest');
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('customerConfirmServicePayment');
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await user.getIdToken(true);
      
      
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('acceptProposal');
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
