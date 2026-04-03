# Firebase App Check Debug Token - Quick Reference

## ✅ IMPLEMENTATION COMPLETE

Both customer and technician apps now force generate and print Firebase App Check debug tokens on startup.

---

## 🚀 QUICK START

### Run Customer App
```bash
cd apps/customer_app
flutter run
```

### Run Technician App
```bash
cd apps/technician_app
flutter run
```

### Expected Console Output
```
🔥 DEBUG TOKEN: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

---

## 📋 FILES MODIFIED

### 1. Customer App
**File**: `apps/customer_app/lib/main.dart`
**Lines**: 56-68
**Change**: Added debug token generation after App Check activation

### 2. Technician App
**File**: `apps/technician_app/lib/core/firebase/firebase_init.dart`
**Lines**: 1-37
**Change**: Added App Check import and debug token generation in init flow

---

## 🔍 CODE ADDED

### Customer App
```dart
// Force generate and print debug token
try {
  final token = await FirebaseAppCheck.instance.getToken(true);
  print('🔥 DEBUG TOKEN: $token');
  AppLogger.firebase('AppCheck', 'Debug token generated: $token');
} catch (e) {
  print('❌ Failed to get App Check token: $e');
  AppLogger.error('AppCheck', 'Token generation failed', e);
}
```

### Technician App
```dart
// Initialize App Check with debug provider
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);

// Force generate and print debug token
try {
  final token = await FirebaseAppCheck.instance.getToken(true);
  print('🔥 DEBUG TOKEN: $token');
  AppLogger.firebase('AppCheck Debug Token: $token');
} catch (e) {
  print('❌ Failed to get App Check token: $e');
  AppLogger.error('AppCheck token generation failed', data: e);
}
```

---

## ✅ VERIFICATION

### What to Look For

1. **Console Output**: Look for 🔥 emoji with token
2. **No Errors**: Should not see ❌ error messages
3. **Token Format**: UUID format (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX)

### Success Indicators

- ✅ App launches without errors
- ✅ Debug token printed to console
- ✅ Token is a valid UUID string
- ✅ No App Check errors in logs

---

## 🔐 SECURITY

### Current Configuration
- **Provider**: Debug (AndroidProvider.debug, AppleProvider.debug)
- **Behavior**: Generates debug tokens for development
- **Production**: NOT suitable for production (no Play Integrity)

### Production Configuration
For production, change to:
```dart
androidProvider: AndroidProvider.playIntegrity,
appleProvider: AppleProvider.appAttest,
```

---

## 🛠️ TROUBLESHOOTING

### Token is null
- Run `flutter pub get`
- Rebuild the app
- Check Firebase project configuration

### Token not printed
- Check console output
- Verify Firebase initialization completed
- Look for error messages

### App Check errors
- Verify Firebase project has App Check enabled
- Check `google-services.json` is correct
- Ensure internet connection is available

---

## 📞 NEXT STEPS

1. Run the app
2. Copy the debug token from console
3. Register token in Firebase Console:
   - Firebase Console → App Check
   - Select your app
   - Add debug token
4. Test App Check protection

---

## 🎯 SUMMARY

### Changes Made
- ✅ Customer app: Added token generation after App Check activation
- ✅ Technician app: Added App Check to FirebaseInit with token generation
- ✅ Both apps: Print token to console with 🔥 emoji
- ✅ Both apps: Error handling with try-catch
- ✅ Both apps: AppLogger integration

### What Was NOT Changed
- ✅ No duplicate Firebase initialization
- ✅ No breaking changes
- ✅ All existing functionality preserved
- ✅ Async main/init functions maintained

---

**Status**: ✅ **READY FOR TESTING**

Run the apps and look for:
```
🔥 DEBUG TOKEN: <your-token-here>
```

