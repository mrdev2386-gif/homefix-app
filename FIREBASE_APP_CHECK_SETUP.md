# Firebase App Check Setup Guide

## Issue
Cloud Functions returning `403 App attestation failed` error in debug mode.

## Solution

### Step 1: Updated Firebase Initialization ✅

File: `apps/customer_app/lib/core/firebase/firebase_init.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    // Debug provider for development
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    print("✅ Firebase App Check Debug Mode Enabled");
  } else {
    // Production security
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
    print("✅ Firebase App Check Production Mode Enabled");
  }

  // Force token refresh and log
  final token = await FirebaseAppCheck.instance.getToken(true);
  print("🔥 App Check Token: $token");
}
```

### Step 2: Get Debug Token

Run the app and check logs for:

```
✅ Firebase App Check Debug Mode Enabled
🔥 App Check Token: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

**Copy the token from logs.**

### Step 3: Register Debug Token in Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **App Check** → **Apps**
4. Find **customer_app** (Android)
5. Click **Manage Debug Tokens**
6. Click **Add Debug Token**
7. Paste the token from logs
8. Click **Save**

### Step 4: Verify Cloud Functions Work

After registering the token, test these functions:

- ✅ `setPrimaryAddress` - Set primary address
- ✅ `manageAddressSecure` - Add/edit/delete addresses
- ✅ `validateAddressForBooking` - Validate address before booking

**Expected Result:**
- No more `403 App attestation failed` errors
- Cloud Functions execute successfully
- Address selection works

### Step 5: Safety Rules

**Debug Mode (Development):**
- Uses `AndroidProvider.debug`
- Requires manual token registration
- Only active when `kDebugMode == true`

**Production Mode (Release):**
- Uses `AndroidProvider.playIntegrity` (Android)
- Uses `AppleProvider.appAttest` (iOS)
- Automatic attestation
- No manual token needed

### Troubleshooting

**Issue: Token not showing in logs**
- Ensure `kDebugMode` is true
- Check Firebase initialization is called in `main.dart`

**Issue: Still getting 403 errors**
- Verify token is registered in Firebase Console
- Wait 5 minutes for token to propagate
- Restart the app

**Issue: Production build fails**
- Ensure `kDebugMode` check is present
- Production uses `playIntegrity`, not `debug`

### Important Notes

1. **Never use debug provider in production**
   - Debug mode only active when `kDebugMode == true`
   - Release builds automatically use production providers

2. **Token Registration Required**
   - Each development device needs its own debug token
   - Tokens must be registered in Firebase Console
   - Tokens are device-specific

3. **Security**
   - Debug tokens bypass attestation checks
   - Only use for development/testing
   - Production uses secure attestation

### Commands

**Run app and get token:**
```bash
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter run
```

**Check logs for token:**
```
grep "App Check Token" logs.txt
```

### Status

- ✅ Firebase initialization updated
- ⏳ Waiting for debug token registration
- ⏳ Verify Cloud Functions work

### Next Steps

1. Run the app
2. Copy debug token from logs
3. Register token in Firebase Console
4. Test address selection
5. Verify no 403 errors

---

**Last Updated:** 2026-01-XX
**Status:** Ready for Testing
