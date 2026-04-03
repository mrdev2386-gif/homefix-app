# Firebase Cloud Functions - Quick Fix Reference

## 🎯 What Was Fixed

### 1. App Check Configuration
**Before**: Disabled (causing UNAUTHENTICATED errors)
**After**: Enabled with debug provider

```dart
// main.dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);
```

### 2. Centralized Firebase Init
**Created**: `lib/core/firebase/firebase_init.dart`
- Single source of truth for initialization
- Prevents duplicate initialization

### 3. Verified Existing Implementation
✅ All Cloud Functions already use:
- Region: `asia-south1`
- Token refresh before calls
- Fresh instance creation
- Retry logic on auth errors

## 🚀 Quick Start

```powershell
# 1. Clean build
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter clean
flutter pub get

# 2. Run app
flutter run

# 3. Verify logs
# Look for:
# ✅ [Firebase] Initialized successfully
# ✅ App Check activated in DEBUG mode
```

## 🧪 Test Cloud Functions

### Cart Operations
```dart
// Should work without UNAUTHENTICATED errors
await firestoreService.addToCart(userId, cartItem);
await firestoreService.updateCartItemQuantity(userId, itemId, 2);
await firestoreService.removeFromCart(userId, itemId);
```

### Address Management
```dart
await firestoreService.saveAddress(userId, address);
await firestoreService.setDefaultAddress(userId, addressId);
```

### Favorites
```dart
await firestoreService.toggleFavorite(userId, categoryId, serviceId, true);
```

## 🔍 Debugging

### Check User Auth
```dart
final user = FirebaseAuth.instance.currentUser;
print('User: ${user?.uid}');
print('Token: ${await user?.getIdToken()}');
```

### Check Function Logs
```dart
print('🔑 [Function] AUTH UID: ${user.uid}');
print('📦 [Function] CALL DATA: $data');
```

### Common Issues

**Issue**: UNAUTHENTICATED error
**Fix**: App Check now enabled in debug mode

**Issue**: Wrong region
**Fix**: Already using `asia-south1` everywhere

**Issue**: Stale token
**Fix**: Already refreshing with `getIdToken(true)`

## 📋 Files Modified

1. `lib/main.dart` - Added App Check activation
2. `pubspec.yaml` - Re-enabled firebase_app_check
3. `lib/core/firebase/firebase_init.dart` - Created (new file)

## 📊 Architecture

```
App Start
  ↓
Firebase.initializeApp() ✅
  ↓
FirebaseAppCheck.activate(debug) ✅
  ↓
User Login
  ↓
Token Refresh ✅
  ↓
Cloud Functions (asia-south1) ✅
```

## ⚠️ Production Checklist

Before deploying to production:

- [ ] Change App Check to `AndroidProvider.playIntegrity`
- [ ] Enable App Check enforcement in Cloud Functions
- [ ] Test with production Firebase project
- [ ] Monitor error rates in Firebase Console

## 🎯 Success Criteria

✅ No UNAUTHENTICATED errors
✅ Cart operations work
✅ Address management works
✅ Favorites work
✅ All Cloud Functions respond correctly

---

**Run**: `clean_rebuild.bat` to apply fixes
**Docs**: See `FIREBASE_CLOUD_FUNCTIONS_COMPLETE_FIX.md` for details
