import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase/functions_instance.dart';

class FunctionsHelper {
  static const String _region = 'asia-south1';

  /// Get a callable function with proper authentication
  /// 
  /// CRITICAL: This method ensures:
  /// 1. User is logged in
  /// 2. Auth token is fresh (force refresh)
  /// 3. Correct region is used
  /// 4. Comprehensive logging for debugging
  static Future<HttpsCallable> getCallable(String functionName) async {
    if (kDebugMode) debugPrint('\n========================================');
    if (kDebugMode) debugPrint('📡 [FunctionsHelper] Preparing to call: $functionName');
    if (kDebugMode) debugPrint('========================================');

    // STEP 1: Verify user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) debugPrint('❌ [FunctionsHelper] ERROR: User not logged in');
      throw Exception("User not logged in. Please authenticate first.");
    }

    if (kDebugMode) {
      debugPrint('✅ [FunctionsHelper] User authenticated');
      debugPrint('   UID: ${user.uid}');
      debugPrint('   Email: ${user.email ?? "N/A"}');
      debugPrint('   Email Verified: ${user.emailVerified}');
    }

    // STEP 2: Force token refresh to ensure it's valid
    try {
      if (kDebugMode) debugPrint('🔄 [FunctionsHelper] Refreshing auth token...');
      final token = await user.getIdToken(true);
      if (kDebugMode) {
        debugPrint('✅ [FunctionsHelper] Token refreshed successfully');
        if (token != null && token.length > 20) {
          debugPrint('   Token preview: ${token.substring(0, 20)}...');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [FunctionsHelper] ERROR: Failed to refresh token: $e');
      throw Exception("Failed to refresh authentication token: $e");
    }

    // STEP 3: Create Functions instance with correct region
    if (kDebugMode) debugPrint('🌍 [FunctionsHelper] Using region: $_region');

    // STEP 4: Create callable function
    if (kDebugMode) debugPrint('📡 [FunctionsHelper] Creating callable: $functionName');
    final callable = FunctionsService.instance.httpsCallable(
      functionName,
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 60),
      ),
    );

    if (kDebugMode) {
      debugPrint('✅ [FunctionsHelper] Callable created successfully');
      debugPrint('========================================\n');
    }

    return callable;
  }

  /// Call a function with automatic error handling and logging
  static Future<T> callFunction<T>({
    required String functionName,
    Map<String, dynamic>? data,
    required T Function(dynamic) parser,
  }) async {
    try {
      final callable = await getCallable(functionName);
      
      if (kDebugMode) {
        debugPrint('📤 [FunctionsHelper] Calling $functionName with data:');
        debugPrint('   ${data ?? "(no data)"}');
      }

      final result = await callable.call(data);
      
      if (kDebugMode) {
        debugPrint('✅ [FunctionsHelper] $functionName completed successfully');
        debugPrint('   Response: ${result.data}');
      }

      return parser(result.data);
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FunctionsHelper] FirebaseFunctionsException in $functionName');
        debugPrint('   Code: ${e.code}');
        debugPrint('   Message: ${e.message}');
        debugPrint('   Details: ${e.details}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FunctionsHelper] Unexpected error in $functionName');
        debugPrint('   Error: $e');
      }
      rethrow;
    }
  }
}
