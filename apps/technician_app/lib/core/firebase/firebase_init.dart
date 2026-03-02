import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseInit {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // Step 1: Initialize Firebase core
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[FIREBASE] Core initialized');

    // Step 2: CRITICAL - Activate App Check immediately after init
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
    debugPrint('[APP_CHECK] Activated with provider: ${kDebugMode ? "debug" : "playIntegrity"}');

    // Step 3: Fetch debug token in debug mode
    if (kDebugMode) {
      try {
        final token = await FirebaseAppCheck.instance.getToken(true);
        debugPrint('🔥 Firebase App Check Debug Token: $token');
      } catch (e) {
        debugPrint('[APP_CHECK] Token fetch error: $e');
      }
    }

    _initialized = true;
    debugPrint('[FIREBASE] Initialization complete');
  }
}
