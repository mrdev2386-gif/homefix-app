import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:io';

/// Initialize Firebase App Check with platform-specific providers
/// 
/// DEBUG MODE:
/// - Uses debug provider for both Android and iOS
/// - Generates and logs debug token for Firebase Console registration
/// - Handles token generation failures gracefully (CI/CD environments)
/// 
/// PRODUCTION MODE:
/// - Android: Play Integrity API (requires Google Play Services)
/// - iOS: Device Check (requires Apple infrastructure)
/// 
/// SAFETY:
/// - Never throws - App Check failures don't crash the app
/// - Logs all initialization steps for debugging
/// - Continues app execution even if App Check fails
Future<void> initializeFirebaseAppCheck() async {
  try {
    if (kDebugMode) {
      debugPrint('🔥 [AppCheck] Initializing Firebase App Check (DEBUG mode)...');
      
      // Debug build: Use debug provider for both platforms
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug, // iOS debug support
      );
      debugPrint('✅ [AppCheck] Debug providers activated');

      // Generate and display debug token (non-blocking)
      _generateDebugToken();
    } else {
      // Production build: Use native attestation for maximum security
      debugPrint('🔥 [AppCheck] Initializing Firebase App Check (PRODUCTION mode)...');
      
      if (Platform.isAndroid) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
        );
        debugPrint('✅ [AppCheck] Android: Using Play Integrity API');
      } else if (Platform.isIOS) {
        await FirebaseAppCheck.instance.activate(
          appleProvider: AppleProvider.deviceCheck,
        );
        debugPrint('✅ [AppCheck] iOS: Using Device Check');
      } else {
        debugPrint('⚠️ [AppCheck] Unknown platform - App Check may not be available');
      }
    }
    
    debugPrint('✅ [AppCheck] Firebase App Check initialized successfully');
  } catch (e) {
    debugPrint('❌ [AppCheck] Initialization failed: $e');
    // Don't throw - App Check failures shouldn't crash the app
    debugPrint('   Continuing without App Check enforcement');
  }
}

/// Generate and log debug token asynchronously
/// Handles token generation failures gracefully
Future<void> _generateDebugToken() async {
  try {
    final appCheckToken = await FirebaseAppCheck.instance.getToken(true);
    if (appCheckToken != null && appCheckToken is String && appCheckToken.isNotEmpty) {
      debugPrint('');
      debugPrint('==============================');
      debugPrint('🔥 FIREBASE APP CHECK TOKEN');
      debugPrint(appCheckToken);
      debugPrint('==============================');
      debugPrint('For Firebase Console registration:');
      debugPrint('1. Go to Project Settings > App Check');
      debugPrint('2. Register this debug token for development');
      debugPrint('3. Set enforcement to "Not enforced" during development');
      debugPrint('');
    } else {
      debugPrint('⚠️ [AppCheck] Debug token is empty or null');
    }
  } catch (e) {
    debugPrint('⚠️ [AppCheck] Debug token generation failed: $e');
    debugPrint('   This is normal in CI/CD environments or if Firebase is not fully initialized.');
  }
}
