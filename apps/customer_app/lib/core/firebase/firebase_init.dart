import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> initializeFirebaseAppCheck() async {
  if (kDebugMode) {
    // Disable Play Integrity during debug builds
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );

    // Generate debug token
    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      print('');
      print('==============================');
      print('🔥 FIREBASE APP CHECK TOKEN');
      print(token);
      print('==============================');
      print('Copy this token and add it in Firebase Console');
      print('');
    } catch (e) {
      print('Debug token generation failed: $e');
    }
  } else {
    // Production security
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
  }
}
