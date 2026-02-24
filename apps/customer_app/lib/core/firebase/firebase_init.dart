import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> initFirebaseSecurity() async {
  try {
    // Use debug provider in debug mode to avoid 403 errors during development
    // Use play integrity in release for production security
    final androidProvider = kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity;
    
    if (kDebugMode) {
      debugPrint('🔧 [AppCheck] Debug mode - using debug provider (no 403 expected)');
    }
    
    await FirebaseAppCheck.instance.activate(
      androidProvider: androidProvider,
    );

    debugPrint('✅ App Check initialized with $androidProvider');

    // Listen for token refreshes (reduces log noise by consolidating events)
    FirebaseAppCheck.instance.onTokenChange.listen((token) {
      debugPrint('🔐 App Check token refreshed');
    });
  } catch (e) {
    debugPrint('❌ App Check init failed: $e');
    // Non-blocking - app can still work without App Check in edge cases
  }
}
