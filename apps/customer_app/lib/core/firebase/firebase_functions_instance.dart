import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// GLOBAL FIREBASE FUNCTIONS INSTANCE
/// 
/// CRITICAL RULES:
/// 1. Single instance for entire app
/// 2. Initialized ONLY AFTER Firebase.initializeApp()
/// 3. Region set to 'us-central1'
/// 4. All function calls MUST wait for auth to be ready
/// 5. NO other FirebaseFunctions instances should be created
class FirebaseFunctionsInstance {
  static FirebaseFunctions? _instance;
  static bool _authReady = false;

  /// Get the global FirebaseFunctions instance
  /// MUST be called AFTER Firebase.initializeApp()
  static FirebaseFunctions get instance {
    _instance ??= FirebaseFunctions.instanceFor(region: 'asia-south1');
    return _instance!;
  }

  /// Wait for Firebase Auth to be fully ready
  /// MUST be called before ANY function call
  static Future<void> ensureAuthReady() async {
    if (_authReady) return;

    debugPrint('[FUNCTIONS] Waiting for auth to be ready...');
    
    // Wait for auth state to be determined
    await FirebaseAuth.instance.authStateChanges().first;
    
    // Add delay for auth token to attach
    await Future.delayed(const Duration(milliseconds: 500));
    
    _authReady = true;
    debugPrint('[FUNCTIONS] ✅ Auth ready');
  }

  /// Reset auth ready state (for testing/logout)
  static void resetAuthState() {
    _authReady = false;
    debugPrint('[FUNCTIONS] Auth state reset');
  }
}
