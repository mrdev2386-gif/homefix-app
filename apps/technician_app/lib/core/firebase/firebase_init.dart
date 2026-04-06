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

    // Initialize App Check with debug provider
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    AppLogger.firebase('Firebase App Check activated with debug provider');
    
    // Force generate and print debug token
    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      debugPrint('🔥 DEBUG TOKEN: $token');
      AppLogger.firebase('Firebase AppCheck Debug Token: $token');
    } catch (e) {
      debugPrint('❌ Failed to get App Check token: $e');
      AppLogger.error('FIREBASE', 'AppCheck token generation failed', data: e);
    }

    _initialized = true;
    AppLogger.firebase('Firebase initialization complete');
  }
}
