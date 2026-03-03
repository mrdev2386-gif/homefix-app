import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

Future<void> initFirebaseSecurity() async {
  try {
    final provider = kReleaseMode
        ? AndroidProvider.playIntegrity
        : AndroidProvider.debug;

    await FirebaseAppCheck.instance.activate(
      androidProvider: provider,
    );

    debugPrint('✅ App Check activated: ${kReleaseMode ? "PlayIntegrity" : "Debug"}');

    // Extract debug token in non-release builds
    if (!kReleaseMode) {
      try {
        final token = await FirebaseAppCheck.instance.getToken(true);
        if (token != null && token.isNotEmpty) {
          debugPrint('🔥 APP_CHECK_DEBUG_TOKEN: $token');
          debugPrint('👉 Add this token to Firebase Console → App Check → Debug tokens');
        }
      } catch (e) {
        debugPrint('⚠️ Debug token fetch failed: $e');
      }
    }
  } catch (e) {
    debugPrint('❌ App Check init failed: $e');
  }
}
