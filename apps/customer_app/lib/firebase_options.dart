
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyADfM4cMfTlz3Cth0QwalYntQv3AoU9daI',
    appId: '1:663243229047:web:generic_web_id',
    messagingSenderId: '663243229047',
    projectId: 'homefix-aa42d',
    authDomain: 'homefix-aa42d.firebaseapp.com',
    storageBucket: 'homefix-aa42d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADfM4cMfTlz3Cth0QwalYntQv3AoU9daI',
    appId: '1:663243229047:android:8c42de21fe943a63f4372',
    messagingSenderId: '663243229047',
    projectId: 'homefix-aa42d',
    storageBucket: 'homefix-aa42d.firebasestorage.app',
  );
}
