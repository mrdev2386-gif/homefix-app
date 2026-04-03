# App Check Fix - Quick Reference

## Problem
```
UNAUTHENTICATED error when calling addToCart or toggleFavorite
```

## Solution

### Option 1: Disable App Check (Development) ⚡ FASTEST

**Firebase Console:**
1. Go to: https://console.firebase.google.com
2. Select your project
3. Click ⚙️ → Project Settings
4. Click "App Check" tab
5. Find your app → Click "Manage"
6. Set enforcement to **"Unenforced"**
7. Save

**Result:** Functions work immediately without App Check

---

### Option 2: Add Debug Provider (Development)

**Firebase Console:**
1. App Check → Apps tab
2. Select your app
3. Click "Debug provider"
4. Copy debug token

**Flutter App (main.dart):**
```dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Add this for development
  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
  }
  
  runApp(MyApp());
}
```

---

### Option 3: Implement Properly (Production)

**Flutter App (main.dart):**
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.deviceCheck,
);
```

**Firebase Console:**
- Enable enforcement for production
- Keep debug provider for development

---

## Verification

### Test in Flutter App:

```dart
// Test addToCart
try {
  await FirebaseFunctions.instance
    .httpsCallable('addToCartCallable')
    .call({
      'serviceId': 'test123',
      'categoryId': 'cat123',
      'technicianId': 'tech123',
      'serviceName': 'Test Service',
      'price': 100,
      'quantity': 1,
    });
  print('✅ addToCart SUCCESS');
} catch (e) {
  print('❌ addToCart FAILED: $e');
}

// Test toggleFavorite
try {
  await FirebaseFunctions.instance
    .httpsCallable('toggleFavoriteCallable')
    .call({
      'serviceId': 'test123',
      'categoryId': 'cat123',
      'isFavorite': true,
    });
  print('✅ toggleFavorite SUCCESS');
} catch (e) {
  print('❌ toggleFavorite FAILED: $e');
}
```

### Expected Output:
```
✅ addToCart SUCCESS
✅ toggleFavorite SUCCESS
```

---

## Function Status

| Function | Auth Required | App Check | Status |
|----------|--------------|-----------|--------|
| addToCartCallable | ✅ | ❌ | Ready |
| toggleFavoriteCallable | ✅ | ❌ | Ready |
| updateCartQuantityCallable | ✅ | ❌ | Ready |
| removeFromCartCallable | ✅ | ❌ | Ready |
| clearCartCallable | ✅ | ❌ | Ready |

---

## Important Notes

### ✅ Security is Maintained
- All functions check `context.auth`
- Only authenticated users can call functions
- User data is protected

### ⚠️ App Check Status
- NOT enforced at function level
- Can be controlled at project level
- Recommended for production

---

## Quick Commands

### Check Firebase Functions Status
```bash
firebase functions:list
```

### Deploy Functions (if needed)
```bash
cd functions
npm run build
firebase deploy --only functions
```

### Check Logs
```bash
firebase functions:log
```

---

## Troubleshooting

### Still getting UNAUTHENTICATED?

1. **Check user is logged in:**
```dart
final user = FirebaseAuth.instance.currentUser;
print('User: ${user?.uid}');
```

2. **Check App Check status:**
   - Firebase Console → App Check
   - Verify enforcement is OFF

3. **Check function deployment:**
```bash
firebase functions:list | findstr addToCart
firebase functions:list | findstr toggleFavorite
```

4. **Check logs:**
```bash
firebase functions:log --only addToCartCallable
firebase functions:log --only toggleFavoriteCallable
```

---

## Summary

✅ **Functions are correctly configured**
✅ **No enforceAppCheck in code**
✅ **Authentication checks present**
❌ **Disable App Check in Firebase Console for development**

**Recommended Action:** Go to Firebase Console and set App Check enforcement to "Unenforced" for development.
