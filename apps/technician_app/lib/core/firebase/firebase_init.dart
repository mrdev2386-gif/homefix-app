import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import '../utils/app_logger.dart';

class FirebaseInit {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.firebase('Firebase Core initialized');

    // Initialize App Check with conditional provider (debug vs release)
    if (kDebugMode) {
      // Debug mode: Use debug provider for development
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      AppLogger.firebase('Firebase App Check activated with debug provider (development)');
      
      // Force generate and print debug token for testing
      try {
        final token = await FirebaseAppCheck.instance.getToken(true);
        debugPrint('🔥 DEBUG TOKEN: $token');
        AppLogger.firebase('Firebase AppCheck Debug Token: $token');
      } catch (e) {
        debugPrint('❌ Failed to get App Check token: $e');
        AppLogger.error('FIREBASE', 'AppCheck token generation failed', data: e);
      }
    } else {
      // Production mode: Use Play Integrity for Android
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
      AppLogger.firebase('Firebase App Check activated with production provider (Play Integrity)');
    }

    _initialized = true;
    AppLogger.firebase('Firebase initialization complete');
  }
}
