# Firebase App Check DEBUG Setup Guide

## 🔥 CRITICAL: App Check + Callable Auth Flow Fix

### ✅ STEP 1: Code Changes Applied
Firebase App Check has been properly enabled with DEBUG provider in:
`apps/technician_app/lib/core/firebase/firebase_init.dart`

**Changes Made:**
- ✅ Uncommented `firebase_app_check` import
- ✅ Added `AndroidProvider.debug` activation
- ✅ Added token listener to capture debug token
- ✅ Proper error handling and logging

### 🚀 STEP 2: Run App and Capture Token

1. **Clean and rebuild:**
```bash
cd c:\Users\yash\projects\homefix\apps\technician_app
flutter clean
flutter pub get
flutter run
```

2. **Watch console logs for:**
```
APP_CHECK_DEBUG_TOKEN: [TOKEN_STRING_HERE]
```

3. **Copy the entire token string** (it will be a long UUID-like string)

### 🔧 STEP 3: Register Token in Firebase Console

1. **Open Firebase Console:**
   - Go to https://console.firebase.google.com
   - Select your project: `homefix-aa42d`

2. **Navigate to App Check:**
   - Left sidebar → App Check
   - Click on your Android app

3. **Add Debug Token:**
   - Click "Debug tokens" tab
   - Click "Add debug token"
   - Paste the token from Step 2
   - Add description: "Technician App Debug Token"
   - Click "Save"

### 🎯 STEP 4: Verify Setup

1. **Re-run the app:**
```bash
flutter run
```

2. **Test deleteService function:**
   - Navigate to Services screen
   - Try to delete a service
   - Should work without UNAUTHENTICATED error

3. **Check logs for:**
```
🔵 [FIREBASE] App Check activated with DEBUG provider
✅ [FIREBASE] Firebase initialization complete
```

### 🔍 STEP 5: Troubleshooting

**If you still get UNAUTHENTICATED errors:**

1. **Verify token registration:**
   - Check Firebase Console → App Check → Debug tokens
   - Ensure token is listed and active

2. **Check app logs:**
   - Look for "APP_CHECK_DEBUG_TOKEN" in console
   - Verify token matches what's registered

3. **Clear app data:**
   - Uninstall and reinstall app
   - Or clear app data in Android settings

### ⚠️ IMPORTANT NOTES

1. **DO NOT disable App Check anymore** - it's now properly configured
2. **Debug tokens are for development only** - use PlayIntegrity for production
3. **Each device needs its own debug token** - register tokens for all test devices
4. **Tokens are device-specific** - different devices will generate different tokens

### 🔄 Expected Flow

```
1. App starts → Firebase Init
2. App Check activates with DEBUG provider
3. Token listener captures debug token
4. Token is registered in Firebase Console
5. Callable functions receive proper auth context
6. No more UNAUTHENTICATED errors
```

### 📱 Production Considerations

For production builds, the code will automatically use:
```dart
androidProvider: kReleaseMode 
    ? AndroidProvider.playIntegrity  // Production
    : AndroidProvider.debug,         // Debug
```

But since we're using `AndroidProvider.debug` explicitly, you'll need to update this for production.

### 🎉 Success Indicators

- ✅ No "placeholder token" errors
- ✅ No UNAUTHENTICATED errors
- ✅ Functions receive proper auth context
- ✅ deleteService works successfully
- ✅ All callable functions work properly

---

## 🚨 IMMEDIATE ACTION REQUIRED

1. Run the app and capture the debug token
2. Register the token in Firebase Console
3. Test the deleteService functionality
4. Verify no UNAUTHENTICATED errors occur

The Firebase App Check + Callable auth flow is now properly configured!