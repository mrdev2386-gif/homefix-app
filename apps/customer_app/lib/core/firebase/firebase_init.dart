import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );

    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      debugPrint('🔥 Firebase App Check Debug Token: $token');
      debugPrint('📋 Copy this token and register it in Firebase Console → App Check → Manage Debug Tokens');
    } catch (e) {
      debugPrint('❌ App Check Token Error: $e');
    }
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
  }
}
