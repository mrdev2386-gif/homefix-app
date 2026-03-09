import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          AppLogger.firebase('App Check activated with DEBUG provider');

          // Force debug token logging in debug mode
          if (!kReleaseMode) {
            await _extractDebugToken();
          }
        } catch (e) {
          AppLogger.error('FIREBASE', 'App Check activation failed', data: e);
          // Continue even if App Check fails
        }
      }

      // ✅ Step 3: Disable reCAPTCHA in debug mode
      if (!kReleaseMode) {
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
        );
        AppLogger.firebase('reCAPTCHA disabled for testing');
      }

      _initialized = true;
      AppLogger.firebase('Firebase initialization complete');
    } catch (e, st) {
      AppLogger.error('FIREBASE', 'Init failed', data: e, stackTrace: st);
      _initialized = true;
    }
  }

  /// 🔐 Debug token extraction - NEVER LOGS IN RELEASE BUILD
  /// This method ONLY executes in debug mode and only logs to debugPrint
  static Future<void> _extractDebugToken() async {
    AppLogger.debug('FIREBASE', 'Starting debug token extraction');

    try {
      AppLogger.debug('FIREBASE', 'Fetching App Check token with forceRefresh=true');
      final token = await FirebaseAppCheck.instance.getToken(true);

      if (kDebugMode) {
        if (token != null) {
          debugPrint('✅ Firebase App Check Debug Mode Enabled');
          debugPrint('🔥 Firebase App Check Debug Token: $token');
          debugPrint('📋 Register token in Firebase Console → App Check → Debug Tokens');
        } else {
          debugPrint('❌ App Check token returned null');
        }
      }
      return;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ App Check Token Error: $e');
      }
      AppLogger.debug('FIREBASE', 'Token extraction failed', data: e);
    }

    AppLogger.debug('FIREBASE', 'Debug token extraction complete');
  }
}