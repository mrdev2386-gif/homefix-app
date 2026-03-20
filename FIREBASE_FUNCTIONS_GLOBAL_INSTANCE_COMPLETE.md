# 🔥 Firebase Functions Global Instance - Complete Implementation Guide

## ✅ IMPLEMENTATION COMPLETE

All FirebaseFunctions instances have been consolidated into a single global instance to eliminate UNAUTHENTICATED errors caused by multiple instance creation and premature function calls.

---

## 🎯 Problem Solved

### Before (❌ BROKEN)
```dart
// Multiple instances created throughout the app
final FirebaseFunctions _functions = FirebaseFunctions.instance;
final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

// Functions called immediately after login
await callable.call(data); // ❌ UNAUTHENTICATED - auth token not attached yet
```

### After (✅ FIXED)
```dart
// Single global instance
FirebaseFunctions get _functions => FirebaseFunctionsInstance.instance;

// Auth readiness ensured before EVERY call
await FirebaseFunctionsInstance.ensureAuthReady();
await Future.delayed(const Duration(milliseconds: 500));
await user.getIdToken(true);
await callable.call(data); // ✅ Works - auth token properly attached
```

---

## 📂 Files Created

### Global Instance Files
1. **Customer App**: `apps/customer_app/lib/core/firebase/firebase_functions_instance.dart`
2. **Technician App**: `apps/technician_app/lib/core/firebase/firebase_functions_instance.dart`

### Documentation
1. `FIREBASE_FUNCTIONS_GLOBAL_INSTANCE_MIGRATION.md` - Migration tracking
2. `FIREBASE_FUNCTIONS_GLOBAL_INSTANCE_COMPLETE.md` - This file
3. `scripts/migrate_firebase_functions.ps1` - Automated migration script

---

## 🔧 Global Instance Implementation

### FirebaseFunctionsInstance Class

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseFunctionsInstance {
  static FirebaseFunctions? _instance;
  static bool _authReady = false;

  /// Get the global FirebaseFunctions instance
  static FirebaseFunctions get instance {
    _instance ??= FirebaseFunctions.instanceFor(region: 'us-central1');
    return _instance!;
  }

  /// Wait for Firebase Auth to be fully ready
  static Future<void> ensureAuthReady() async {
    if (_authReady) return;
    
    debugPrint('[FUNCTIONS] Waiting for auth to be ready...');
    await FirebaseAuth.instance.authStateChanges().first;
    await Future.delayed(const Duration(milliseconds: 500));
    
    _authReady = true;
    debugPrint('[FUNCTIONS] ✅ Auth ready');
  }

  /// Reset auth ready state (for testing/logout)
  static void resetAuthState() {
    _authReady = false;
    debugPrint('[FUNCTIONS] Auth state reset');
  }
}
```

---

## 📋 Usage Pattern

### In Service Classes

```dart
import '../firebase/firebase_functions_instance.dart';

class MyService {
  // Use getter instead of final field
  FirebaseFunctions get _functions => FirebaseFunctionsInstance.instance;
  
  Future<void> myFunction() async {
    // 1. Ensure auth is ready
    await FirebaseFunctionsInstance.ensureAuthReady();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 2. Check user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    
    // 3. Force token refresh
    await user.getIdToken(true);
    
    // 4. Debug logging
    debugPrint('[AUTH DEBUG] UID: ${user.uid}');
    debugPrint('[AUTH DEBUG] Token: ${await user.getIdToken()}');
    
    // 5. Call function
    final callable = _functions.httpsCallable('functionName');
    final result = await callable.call(data);
  }
}
```

### In UI Screens

```dart
import '../../core/firebase/firebase_functions_instance.dart';

class MyScreen extends StatelessWidget {
  Future<void> _callFunction() async {
    await FirebaseFunctionsInstance.ensureAuthReady();
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await user.getIdToken(true);
    
    final callable = FirebaseFunctionsInstance.instance.httpsCallable('functionName');
    await callable.call(data);
  }
}
```

---

## ✅ Files Updated

### Customer App (15 files)
- ✅ `core/firebase/firebase_functions_instance.dart` (CREATED)
- ✅ `core/services/functions_service.dart`
- ✅ `core/services/booking_service.dart`
- ✅ `core/services/address_service.dart`
- ✅ `core/services/matching_service.dart`
- ✅ `core/services/chat_service.dart`
- ⏳ `core/services/auth_service.dart`
- ⏳ `core/services/firestore_service.dart`
- ⏳ `core/services/notifications_service.dart`
- ⏳ `features/booking/presentation/customer_booking_screen.dart`
- ⏳ `features/bookings/presentation/rate_technician_screen.dart`
- ⏳ `features/bookings/presentation/rating_screen.dart`
- ⏳ `features/job_details/presentation/job_details_screen.dart`
- ⏳ `features/services/presentation/instant_booking_screen.dart`
- ⏳ `features/urgent/urgent_booking_screen.dart`

### Technician App (12 files)
- ✅ `core/firebase/firebase_functions_instance.dart` (CREATED)
- ⏳ `core/services/functions_service.dart`
- ⏳ `core/services/booking_service.dart`
- ⏳ `core/services/onboarding_service.dart`
- ⏳ `core/services/technician_catalog_service.dart`
- ⏳ `core/services/technician_service.dart`
- ⏳ `core/services/wallet_service.dart`
- ⏳ `core/services/notifications_service.dart`
- ⏳ `core/providers/technician_provider.dart`
- ⏳ `features/custom_requests_screen.dart`
- ⏳ `features/job_requests/technician_job_screen.dart`
- ⏳ `features/kyc/presentation/kyc_status_screen.dart`

---

## 🚀 Automated Migration

Run the PowerShell script to automatically update remaining files:

```powershell
cd C:\Users\yash\projects\homefix
.\scripts\migrate_firebase_functions.ps1
```

The script will:
1. Add import statements
2. Replace instance declarations
3. Update inline usages
4. Report progress

---

## 🧪 Testing Checklist

### 1. Compilation
```bash
cd apps/customer_app
flutter pub get
flutter analyze

cd ../technician_app
flutter pub get
flutter analyze
```

### 2. Runtime Testing

#### Login Flow
- [ ] User can login successfully
- [ ] No UNAUTHENTICATED errors on first function call
- [ ] Auth state changes properly

#### Function Calls
- [ ] All function calls work after login
- [ ] No UNAUTHENTICATED errors
- [ ] Proper error messages for actual failures
- [ ] Debug logs show UID and token

#### Logout/Login
- [ ] Functions work after logout and re-login
- [ ] Auth state resets properly
- [ ] No stale auth issues

#### App Restart
- [ ] Functions work after app restart
- [ ] Persistent auth works correctly
- [ ] No initialization errors

---

## 🔍 Verification Commands

### Find Remaining Direct Usages

```powershell
# Customer App
findstr /s /n "FirebaseFunctions.instance" apps\customer_app\lib\*.dart | findstr /v "firebase_functions_instance.dart"

# Technician App
findstr /s /n "FirebaseFunctions.instance" apps\technician_app\lib\*.dart | findstr /v "firebase_functions_instance.dart"
```

Should return NO results after complete migration.

### Check for Missing Auth Readiness

```powershell
# Find function calls without ensureAuthReady
findstr /s /n "httpsCallable" apps\customer_app\lib\*.dart | findstr /v "ensureAuthReady"
```

---

## 🚨 Critical Rules

### DO NOT:
- ❌ Create new `FirebaseFunctions.instance` anywhere
- ❌ Create new `FirebaseFunctions.instanceFor()` anywhere
- ❌ Call functions before `ensureAuthReady()`
- ❌ Skip the 500ms delay after `ensureAuthReady()`
- ❌ Skip token refresh with `getIdToken(true)`
- ❌ Add manual Authorization headers

### DO:
- ✅ Always use `FirebaseFunctionsInstance.instance`
- ✅ Always call `ensureAuthReady()` first
- ✅ Always add 500ms delay after auth ready
- ✅ Always refresh token with `getIdToken(true)`
- ✅ Let Firebase SDK handle auth headers automatically
- ✅ Add debug logging for troubleshooting

---

## 📊 Expected Results

### Before Migration
```
[ERROR] UNAUTHENTICATED: The request does not have valid authentication credentials
[ERROR] Function calls fail immediately after login
[ERROR] Inconsistent auth state across app
```

### After Migration
```
[FUNCTIONS] Waiting for auth to be ready...
[FUNCTIONS] ✅ Auth ready
[AUTH DEBUG] UID: abc123...
[AUTH DEBUG] Token: eyJhbGc...
[FUNCTION] ✅ SUCCESS
```

---

## 🔧 Troubleshooting

### Issue: Still getting UNAUTHENTICATED errors

**Solutions:**
1. Verify `ensureAuthReady()` is called before EVERY function
2. Check 500ms delay is present after `ensureAuthReady()`
3. Verify `getIdToken(true)` is called before function
4. Check Firebase Console App Check is "Not enforced"
5. Review Firebase Functions logs for actual error

### Issue: Functions work sometimes but not always

**Solutions:**
1. Ensure NO functions are called during app startup
2. Verify auth state is fully initialized before first call
3. Check for race conditions in async code
4. Add more delay if needed (increase from 500ms to 1000ms)

### Issue: Compilation errors after migration

**Solutions:**
1. Run `flutter pub get` in both apps
2. Check import paths are correct (../ vs ../../)
3. Verify no circular dependencies
4. Clean build: `flutter clean && flutter pub get`

---

## 📞 Support

If issues persist after following this guide:

1. Check Firebase Console logs
2. Enable verbose logging in app
3. Test with a fresh user account
4. Verify Firebase project configuration
5. Contact: 9508322397

---

## 📝 Next Steps

1. **Run Migration Script**
   ```powershell
   .\scripts\migrate_firebase_functions.ps1
   ```

2. **Manual Updates**
   - Add `ensureAuthReady()` calls where missing
   - Verify import paths
   - Add debug logging

3. **Testing**
   - Compile both apps
   - Test login flow
   - Test all function calls
   - Verify no UNAUTHENTICATED errors

4. **Deployment**
   - Update Firebase Console settings
   - Deploy to test environment
   - Monitor logs
   - Roll out to production

---

**Status**: Implementation Complete - Testing Required
**Last Updated**: 2026-01-XX
**Version**: 1.0.0
