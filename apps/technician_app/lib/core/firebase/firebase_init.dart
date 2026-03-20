import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_app_check/firebase_app_check.dart'; // DISABLED FOR DEVELOPMENT
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import '../utils/app_logger.dart';

class FirebaseInit {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // CRITICAL: Initialize Firebase FIRST
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.firebase('Core initialized');

    // APP CHECK DISABLED FOR DEVELOPMENT
    // NO App Check SDK initialization
    // Firebase Functions will work without App Check enforcement
    debugPrint('⚠️ [APP CHECK] DISABLED - App Check is not initialized');
    debugPrint('   Firebase Functions will work without App Check enforcement');
    debugPrint('   This is normal for local development');
    
    /*
    // CRITICAL: App Check MUST run ONLY AFTER Firebase.initializeApp()
    // Use debug provider for local/dev testing - DO NOT use PlayIntegrity
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );

    // Debug log after activation
    print('[APP CHECK] Debug provider enabled');
    AppLogger.firebase('App Check activated with debug provider');

    // Listen for token changes
    FirebaseAppCheck.instance.onTokenChange.listen((token) {
      debugPrint('[APP CHECK] Token changed: $token');
    });
    */

    _initialized = true;

    print('✅ [FIREBASE] Firebase initialization complete');
    AppLogger.firebase('Firebase initialization complete');
  }
}