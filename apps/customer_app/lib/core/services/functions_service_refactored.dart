import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static const String _region = 'us-central1';
  static const String _projectId = 'homefix-prod';

  FunctionsService() {
    // Set region explicitly
    _functions.useFunctionsEmulator('localhost', 5001);
  }

  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      // STEP 1: Verify authentication
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      final uid = currentUser.uid;
      debugPrint('[updateUserProfile] UID: $uid');
      debugPrint('[updateUserProfile] Payload: $userData');

      // STEP 2: Create callable with explicit region
      final callable = _functions
          .httpsCallableFromUrl(
            'https://$_region-$_projectId.cloudfunctions.net/updateUserProfile',
          )
          .withOptions(
            HttpsCallableOptions(
              timeout: const Duration(seconds: 30),
            ),
          );

      // STEP 3: Call function with await
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

  // Check for non-serializable types in debug mode
  void _debugCheckParameters(Map<String, dynamic> params) {
    if (!kDebugMode) return;
    try {
      _debugIsValidParameterType(params);
    } catch (e) {
      debugPrint('⚠️ Cloud Function Parameter Error: $e');
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
    throw Exception('Invalid type for Cloud Function: ${value.runtimeType}. Convert to ISO String (DateTime) or Map (Objects) or use toJsonSafe().');
  }

  static Map<String, dynamic> toJsonSafe(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _makeValueSafe(value)));
  }

  static dynamic _makeValueSafe(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value.runtimeType.toString() == 'Timestamp') return value.millisecondsSinceEpoch;
    
    if (value is List) {
      return value.map((item) => _makeValueSafe(item)).toList();
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _makeValueSafe(v)));
    }
    
    try {
      if (value.toJson != null) return _makeValueSafe(value.toJson());
    } catch (_) {}

    debugPrint('⚠️ Warning: Forced string conversion for ${value.runtimeType}');
    return value.toString();
  }

  Future<Map<String, dynamic>> validateReferralCode(String code) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('validateReferralCode');
      final result = await callable.call({'code': code});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelBookingExtended(String bookingId, String reason) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('updateBookingStatusNew');
      await callable.call({'bookingId': bookingId, 'status': 'cancelled', 'reason': reason});
    } catch (e) {
      rethrow;
    }
  }

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
      HttpsCallable callable = _functions.httpsCallable('findEligibleTechniciansCount');
      final result = await callable.call(safePayload);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveFcmToken(String token, String userType) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('saveFcmToken');
      await callable.call({
        'token': token,
        'userType': userType,
      });
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

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

  Future<Map<String, dynamic>> technicianRespondServiceRequest(String requestId, String action, {String? reason}) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('technicianRespondServiceRequest');
      final result = await callable.call({
        'requestId': requestId,
        'action': action,
        if (reason != null) 'rejectionReason': reason,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> customerConfirmServicePayment(String requestId, String paymentMethod) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('customerConfirmServicePayment');
      final result = await callable.call({
        'requestId': requestId,
        'paymentMethod': paymentMethod,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

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
