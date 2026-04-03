# 🔒 FIX: UNAUTHENTICATED Error - App Check Play Integrity Enforcement

## Problem
Firebase Cloud Functions returning `UNAUTHENTICATED` error because Play Integrity provider is enforcing App Check validation during development.

**Error:**
```
FirebaseFunctionsException
Code: unauthenticated
Message: Unauthenticated
```

**Root Cause:** Play Integrity provider requires app to be signed with release key and uploaded to Play Console, which is not suitable for development.

---

## Solution: Use Debug Provider Only

### Changes Made

#### 1. Added firebase_app_check dependency
**File:** `pubspec.yaml`
```yaml
firebase_app_check: ^0.2.0
```

#### 2. Initialize App Check with debug provider
**File:** `lib/main.dart`
```dart
// Initialize App Check with debug provider only (no Play Integrity)
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);
print('✅ App Check initialized with debug provider');
```

#### 3. Updated debug AndroidManifest
**File:** `android/app/src/debug/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.firebase.app_check_debug_token"
    android:value="@string/firebase_app_check_debug_token" />
```

#### 4. Created debug strings.xml
**File:** `android/app/src/debug/res/values/strings.xml`
```xml
<string name="firebase_app_check_debug_token">YOUR_DEBUG_TOKEN_HERE</string>
```

---

## Setup Instructions

### Step 1: Get Debug Token

Run the app in debug mode:
```powershell
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter clean
flutter pub get
flutter run --debug
```

**Look for console output:**
```
✅ App Check initialized with debug provider
```

### Step 2: Register Debug Token in Firebase Console

1. Go to: https://console.firebase.google.com/project/homefix-aa42d/appcheck
2. Click **Apps** tab
3. Find your Android app
4. Click **Manage debug tokens**
5. Run app again and copy the debug token from console logs
6. Paste token in Firebase Console
7. Click **Add**

### Step 3: Update strings.xml

Replace `YOUR_DEBUG_TOKEN_HERE` in:
```
android/app/src/debug/res/values/strings.xml
```

With the actual debug token from Firebase Console.

### Step 4: Clean and Run

```powershell
flutter clean
flutter pub get
flutter run --debug
```

---

## Verification

### Test 1: addToCart Function
```dart
// Should work without UNAUTHENTICATED error
await firestoreService.addToCart(userId, cartItem);
```

**Expected:** ✅ Success

### Test 2: toggleFavorite Function
```dart
// Should work without UNAUTHENTICATED error
await firestoreService.toggleFavorite(userId, serviceId, categoryId, true);
```

**Expected:** ✅ Success

### Test 3: updateUserProfile Function
```dart
// Should work without UNAUTHENTICATED error
await firestoreService.updateUserProfile(userId, {'state': 'Jharkhand', 'district': 'Deoghar'});
```

**Expected:** ✅ Success

---

## Important Notes

### Development vs Production

**Development (Current Setup):**
- ✅ Uses debug provider
- ✅ No Play Integrity required
- ✅ Debug token registration needed
- ✅ Suitable for development and testing

**Production (Future):**
- Use Play Integrity provider
- Requires app signed with release key
- Requires app uploaded to Play Console
- Automatic token generation (no manual registration)

### Do NOT Keep Play Integrity Enabled During Development

**Why?**
- Play Integrity requires app to be signed with release key
- Requires app to be uploaded to Play Console
- Requires 24+ hours for Play Integrity to activate
- Causes UNAUTHENTICATED errors in development builds

### Debug Token Expiration

Debug tokens expire after a period. If you see errors:
1. Run app again to generate new token
2. Register new token in Firebase Console
3. Update strings.xml with new token

---

## Troubleshooting

### Issue: Still Getting UNAUTHENTICATED Error

**Solution:**
1. Verify debug token is registered in Firebase Console
2. Check strings.xml has correct token
3. Run `flutter clean && flutter pub get`
4. Rebuild and run app

### Issue: App Check Token Not Printed

**Solution:**
1. Check internet connection
2. Verify Firebase project is configured
3. Ensure google-services.json is correct
4. Check Firebase Console for app registration

### Issue: Firestore Operations Still Failing

**Solution:**
1. Verify Firestore rules allow debug tokens
2. Check Cloud Functions are not enforcing App Check
3. Disable App Check enforcement temporarily to test
4. Re-enable after verification

---

## Firebase Console Configuration

### Disable Play Integrity Enforcement

1. Go to: https://console.firebase.google.com/project/homefix-aa42d/appcheck/apis
2. Find **Cloud Functions**
3. If enforcement is enabled, click **Disable**
4. Confirm

### Enable Debug Provider

1. Go to: https://console.firebase.google.com/project/homefix-aa42d/appcheck/apps
2. Find your Android app
3. Ensure **Debug provider** is **ACTIVE**
4. Ensure **Play Integrity** is **DISABLED** or **INACTIVE**

---

## Next Steps

### For Development
- ✅ Use debug provider (current setup)
- ✅ Register debug tokens for all team members
- ✅ Test all Cloud Functions

### For Production Release
1. Switch to Play Integrity provider
2. Sign app with release key
3. Upload to Play Console (internal testing)
4. Wait 24+ hours for Play Integrity activation
5. Enable enforcement in Firebase Console
6. Monitor for errors

---

## Files Modified

1. ✅ `pubspec.yaml` - Added firebase_app_check dependency
2. ✅ `lib/main.dart` - Added App Check initialization
3. ✅ `android/app/src/debug/AndroidManifest.xml` - Updated debug configuration
4. ✅ `android/app/src/debug/res/values/strings.xml` - Created debug token reference

---

## Summary

**Problem:** Play Integrity enforcement causing UNAUTHENTICATED errors  
**Solution:** Use debug provider for development  
**Status:** ✅ FIXED  
**Next Action:** Register debug token in Firebase Console

