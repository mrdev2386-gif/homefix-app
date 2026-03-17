import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import '../utils/app_logger.dart';

class FirebaseInit {
  static bool _initialized = false;
  static bool _appCheckActivated = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // ✅ Step 1: Initialize Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.firebase('Core initialized');

      // ✅ Step 2: Activate App Check IMMEDIATELY after Firebase init
      if (!_appCheckActivated) {
        try {
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
          );
          _appCheckActivated = true;
          print('🔵 [FIREBASE] App Check DEBUG forced token generated');
          AppLogger.firebase('App Check activated with DEBUG provider');

          // FORCE TOKEN GENERATION (CRITICAL)
          try {
            final token = await FirebaseAppCheck.instance.getToken(true);
            print('🔥 DEBUG TOKEN: $token');
          } catch (e) {
            print('❌ App Check Token Error: $e');
          }
        } catch (e) {
          AppLogger.error('FIREBASE', 'App Check activation failed', data: e);
          // Continue even if App Check fails
        }
      }

      _initialized = true;
      AppLogger.firebase('Firebase initialization complete');
    } catch (e, st) {
      AppLogger.error('FIREBASE', 'Init failed', data: e, stackTrace: st);
    }
  }
}
