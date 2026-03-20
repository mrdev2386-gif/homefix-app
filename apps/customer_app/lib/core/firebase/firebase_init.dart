import 'package:flutter/foundation.dart';
// import 'package:firebase_app_check/firebase_app_check.dart'; // DISABLED FOR DEVELOPMENT

/// Firebase App Check - DISABLED FOR DEVELOPMENT
/// 
/// App Check has been completely disabled to avoid authentication issues
/// during local development and testing.
/// 
/// IMPORTANT:
/// - NO App Check SDK initialization
/// - NO debug provider
/// - NO PlayIntegrity provider
/// - Firebase Functions will work without App Check enforcement
/// 
/// To re-enable for production:
/// 1. Uncomment the import above
/// 2. Uncomment the activation code below
/// 3. Configure proper providers (PlayIntegrity for Android, DeviceCheck for iOS)
/// 4. Enable enforcement in Firebase Console
Future<void> initializeFirebaseAppCheck() async {
  // DISABLED: App Check initialization commented out for development
  debugPrint('⚠️ [APP CHECK] DISABLED - App Check is not initialized');
  debugPrint('   Firebase Functions will work without App Check enforcement');
  debugPrint('   This is normal for local development');
  
  /*
  try {
    debugPrint('🔥 [APP CHECK] Initializing Firebase App Check (DEBUG mode)...');
    
    // CRITICAL: Use debug provider for local/dev testing
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
    
    // Debug log after activation
    print('[APP CHECK] Debug provider enabled');
    debugPrint('✅ [APP CHECK] Debug provider activated');

    // Generate and display debug token (non-blocking)
    _generateDebugToken();
    
    debugPrint('✅ [APP CHECK] Firebase App Check initialized successfully');
  } catch (e) {
    debugPrint('❌ [APP CHECK] Initialization failed: $e');
    // Don't throw - App Check failures shouldn't crash the app
    debugPrint('   Continuing without App Check enforcement');
  }
  */
}

/*
/// Generate and log debug token asynchronously
/// Handles token generation failures gracefully
Future<void> _generateDebugToken() async {
  try {
    final appCheckToken = await FirebaseAppCheck.instance.getToken(true);
    if (appCheckToken != null && appCheckToken is String && appCheckToken.isNotEmpty) {
      debugPrint('');
      debugPrint('==============================');
      debugPrint('🔥 FIREBASE APP CHECK DEBUG TOKEN');
      debugPrint(appCheckToken);
      debugPrint('==============================');
      debugPrint('For Firebase Console registration:');
      debugPrint('1. Go to Project Settings > App Check');
      debugPrint('2. Register this debug token for development');
      debugPrint('3. Set enforcement to "Not enforced" during development');
      debugPrint('');
    } else {
      debugPrint('⚠️ [APP CHECK] Debug token is empty or null');
    }
  } catch (e) {
    debugPrint('⚠️ [APP CHECK] Debug token generation failed: $e');
    debugPrint('   This is normal in CI/CD environments or if Firebase is not fully initialized.');
  }
}
*/
