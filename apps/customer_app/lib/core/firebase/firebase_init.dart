import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> initFirebaseSecurity() async {
try {
if (kDebugMode) {
debugPrint('🔧 [AppCheck] Debug mode - forcing debug provider');
}

```
// 🔥 TEMPORARY: Force debug provider to guarantee token generation
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
);

debugPrint('✅ App Check initialized with AndroidProvider.debug');

// 🔥 Force fetch debug token
if (kDebugMode) {
  try {
    final debugToken = await FirebaseAppCheck.instance.getToken(true);
    debugPrint('🔥 Firebase App Check Debug Token: $debugToken');
  } catch (e) {
    debugPrint('[APP_CHECK] Debug token fetch error: $e');
  }
}

// Listen for token refresh
FirebaseAppCheck.instance.onTokenChange.listen((token) {
  debugPrint('🔐 App Check token refreshed');
});
```

} catch (e) {
debugPrint('❌ App Check init failed: $e');
}
}
