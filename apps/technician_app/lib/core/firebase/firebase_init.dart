import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseInit {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // ✅ Step 1: Initialize Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[FIREBASE] Core initialized');

      // 🔍 DIAGNOSTIC: Print Firebase project configuration
      debugPrint('[FIREBASE_CONFIG] Project ID: ${Firebase.app().options.projectId}');
      debugPrint('[FIREBASE_CONFIG] App ID: ${Firebase.app().options.appId}');
      debugPrint('[FIREBASE_CONFIG] API Key: ${Firebase.app().options.apiKey}');

      // 🔥 CRITICAL: Small delay to allow Firebase internal services to settle
      // (safe in debug, harmless in release)
      await Future.delayed(const Duration(milliseconds: 300));

      // ✅ Step 2: Select provider safely
      final provider = kReleaseMode
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug;

      debugPrint('[APP_CHECK_DIAG] Release mode: $kReleaseMode');
      debugPrint(
        '[APP_CHECK_DIAG] Provider: ${kReleaseMode ? "playIntegrity" : "debug"}',
      );

      // ✅ Step 3: Activate App Check
      await FirebaseAppCheck.instance.activate(
        androidProvider: provider,
      );
      debugPrint(
        '[APP_CHECK] Activated with provider: ${kReleaseMode ? "playIntegrity" : "debug"}',
      );

      // ✅ Step 4: Extract debug token (DEBUG ONLY)
      if (!kReleaseMode) {
        await _extractDebugToken();
      }

      _initialized = true;
      debugPrint('[FIREBASE] Initialization complete');
    } catch (e, st) {
      debugPrint('[FIREBASE_ERROR] Init failed: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  /// 🔥 Multi-strategy debug token extraction
  static Future<void> _extractDebugToken() async {
    debugPrint('[APP_CHECK_DIAG] Starting token extraction...');

    // Strategy A
    try {
      debugPrint(
        '[APP_CHECK_DIAG] Strategy A: Fetching with forceRefresh=true',
      );
      final token = await FirebaseAppCheck.instance.getToken(true);

      if (token != null && token.isNotEmpty) {
        debugPrint('🔥 APP_CHECK_TOKEN_PRIMARY: $token');
        debugPrint(
          '👉 COPY THIS TOKEN INTO Firebase → App Check → Manage debug tokens',
        );
        return;
      } else {
        debugPrint('[APP_CHECK_DIAG] Strategy A returned null/empty token');
      }
    } catch (e) {
      debugPrint('[APP_CHECK_DIAG] Strategy A failed: $e');
    }

    // Strategy B
    try {
      debugPrint(
        '[APP_CHECK_DIAG] Strategy B: Fetching with forceRefresh=false',
      );
      final token = await FirebaseAppCheck.instance.getToken(false);

      if (token != null && token.isNotEmpty) {
        debugPrint('🔥 APP_CHECK_TOKEN_FALLBACK: $token');
        debugPrint(
          '👉 COPY THIS TOKEN INTO Firebase → App Check → Manage debug tokens',
        );
        return;
      } else {
        debugPrint('[APP_CHECK_DIAG] Strategy B returned null/empty token');
      }
    } catch (e) {
      debugPrint('[APP_CHECK_DIAG] Strategy B failed: $e');
    }

    // Strategy C
    try {
      debugPrint('[APP_CHECK_DIAG] Strategy C: Setting up token listener');

      FirebaseAppCheck.instance.onTokenChange.listen((token) {
        if (token != null && token.isNotEmpty) {
          debugPrint('🔥 APP_CHECK_TOKEN_LISTENER: $token');
          debugPrint(
            '👉 COPY THIS TOKEN INTO Firebase → App Check → Manage debug tokens',
          );
        }
      });
    } catch (e) {
      debugPrint('[APP_CHECK_DIAG] Strategy C setup failed: $e');
    }

    debugPrint('[APP_CHECK_DIAG] Token extraction complete');
  }
}