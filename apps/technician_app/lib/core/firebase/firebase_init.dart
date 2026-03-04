import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import '../utils/app_logger.dart';

class FirebaseInit {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // ✅ Step 1: Initialize Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.firebase('Core initialized');

      // ✅ CRITICAL: Disable reCAPTCHA in debug mode to avoid token issues
      if (!kReleaseMode) {
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
        );
        AppLogger.firebase('reCAPTCHA disabled for testing');
      }

      // ✅ Step 2: Select provider safely
      final provider = kReleaseMode
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug;

      AppLogger.firebase('Activating App Check with provider: ${kReleaseMode ? "playIntegrity" : "debug"}');

      // ✅ Step 3: Activate App Check with safe error handling
      // Note: ProviderInstaller warnings are non-critical and safe to ignore
      // They indicate optional security providers are not available
      await FirebaseAppCheck.instance.activate(
        androidProvider: provider,
      );
      AppLogger.firebase('App Check activated successfully');

      // ✅ Step 4: Extract debug token (DEBUG ONLY - NEVER IN RELEASE)
      if (!kReleaseMode) {
        await _extractDebugToken();
      }

      _initialized = true;
      AppLogger.firebase('Firebase initialization complete');
    } catch (e, st) {
      // Log the error but continue - non-critical failures should not crash app
      AppLogger.error('FIREBASE', 'Init failed', data: e, stackTrace: st);
      _initialized = true; // Mark as initialized anyway to prevent repeated attempts
      // Don't rethrow to allow app to continue with degraded functionality
    }
  }

  /// 🔐 Debug token extraction - NEVER LOGS IN RELEASE BUILD
  /// This method ONLY executes in debug mode and only logs to debugPrint
  static Future<void> _extractDebugToken() async {
    AppLogger.debug('FIREBASE', 'Starting debug token extraction');

    // Strategy A
    try {
      AppLogger.debug('FIREBASE', 'Strategy A: Fetching with forceRefresh=true');
      final token = await FirebaseAppCheck.instance.getToken(true);

      if (token != null && token.isNotEmpty) {
        // ONLY log token in kDebugMode and NEVER in release
        if (kDebugMode) {
          debugPrint('🔥 APP_CHECK_DEBUG_TOKEN: $token');
          debugPrint('👉 Copy token to Firebase Console → App Check → Manage debug tokens');
        }
        return;
      } else {
        AppLogger.debug('FIREBASE', 'Strategy A returned null/empty token');
      }
    } catch (e) {
      AppLogger.debug('FIREBASE', 'Strategy A failed', data: e);
    }

    // Strategy B
    try {
      AppLogger.debug('FIREBASE', 'Strategy B: Fetching with forceRefresh=false');
      final token = await FirebaseAppCheck.instance.getToken(false);

      if (token != null && token.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🔥 APP_CHECK_FALLBACK_TOKEN: $token');
        }
        return;
      } else {
        AppLogger.debug('FIREBASE', 'Strategy B returned null/empty token');
      }
    } catch (e) {
      AppLogger.debug('FIREBASE', 'Strategy B failed', data: e);
    }

    // Strategy C - Token listener
    try {
      AppLogger.debug('FIREBASE', 'Strategy C: Setting up token listener');
      FirebaseAppCheck.instance.onTokenChange.listen((token) {
        if (token != null && token.isNotEmpty && kDebugMode) {
          debugPrint('🔥 APP_CHECK_NEW_TOKEN: $token');
        }
      });
    } catch (e) {
      AppLogger.debug('FIREBASE', 'Strategy C failed', data: e);
    }

    AppLogger.debug('FIREBASE', 'Debug token extraction complete');
  }
}