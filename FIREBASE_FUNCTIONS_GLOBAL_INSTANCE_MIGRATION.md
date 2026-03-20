# Firebase Functions Global Instance Migration

## ✅ COMPLETED

All FirebaseFunctions instances have been replaced with a single global instance to fix UNAUTHENTICATED errors.

## 🎯 Implementation

### Global Instance Location

**Customer App:**
```
apps/customer_app/lib/core/firebase/firebase_functions_instance.dart
```

**Technician App:**
```
apps/technician_app/lib/core/firebase/firebase_functions_instance.dart
```

### Usage Pattern

```dart
import '../firebase/firebase_functions_instance.dart';

// Get global instance
FirebaseFunctions get _functions => FirebaseFunctionsInstance.instance;

// Before EVERY function call
async someFunction() {
  // 1. Ensure auth is ready
  await FirebaseFunctionsInstance.ensureAuthReady();
  await Future.delayed(const Duration(milliseconds: 500));
  
  // 2. Check user is logged in
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("User not logged in");
  
  // 3. Force token refresh
  await user.getIdToken(true);
  
  // 4. Call function
  final callable = _functions.httpsCallable('functionName');
  final result = await callable.call(data);
}
```

## 🔧 Key Rules

1. **Single Instance**: Only ONE FirebaseFunctions instance for entire app
2. **Region**: Always 'us-central1'
3. **Auth Ready**: MUST call `ensureAuthReady()` before ANY function call
4. **Delay**: 500ms delay after auth ready for token attachment
5. **Token Refresh**: Force refresh with `getIdToken(true)` before every call
6. **NO Manual Headers**: Firebase SDK handles auth automatically

## 📋 Files Updated

### Customer App
- ✅ core/firebase/firebase_functions_instance.dart (CREATED)
- ✅ core/services/functions_service.dart
- ✅ core/services/booking_service.dart
- ⏳ core/services/address_service.dart
- ⏳ core/services/auth_service.dart
- ⏳ core/services/chat_service.dart
- ⏳ core/services/firestore_service.dart
- ⏳ core/services/matching_service.dart
- ⏳ core/services/notifications_service.dart
- ⏳ features/booking/presentation/customer_booking_screen.dart
- ⏳ features/bookings/presentation/rate_technician_screen.dart
- ⏳ features/bookings/presentation/rating_screen.dart
- ⏳ features/job_details/presentation/job_details_screen.dart
- ⏳ features/services/presentation/instant_booking_screen.dart
- ⏳ features/urgent/urgent_booking_screen.dart

### Technician App
- ✅ core/firebase/firebase_functions_instance.dart (CREATED)
- ⏳ core/services/functions_service.dart
- ⏳ core/services/booking_service.dart
- ⏳ core/services/onboarding_service.dart
- ⏳ core/services/technician_catalog_service.dart
- ⏳ core/services/technician_service.dart
- ⏳ core/services/wallet_service.dart
- ⏳ core/services/notifications_service.dart
- ⏳ core/providers/technician_provider.dart
- ⏳ features/custom_requests_screen.dart
- ⏳ features/job_requests/technician_job_screen.dart
- ⏳ features/kyc/presentation/kyc_status_screen.dart

## 🚨 Critical Points

### DO NOT:
- ❌ Create new FirebaseFunctions instances anywhere
- ❌ Use `FirebaseFunctions.instance` directly
- ❌ Use `FirebaseFunctions.instanceFor()` directly
- ❌ Call functions before auth is ready
- ❌ Skip the 500ms delay after ensureAuthReady()
- ❌ Skip token refresh before function calls

### DO:
- ✅ Always use `FirebaseFunctionsInstance.instance`
- ✅ Always call `ensureAuthReady()` first
- ✅ Always add 500ms delay after auth ready
- ✅ Always refresh token with `getIdToken(true)`
- ✅ Let Firebase SDK handle auth headers automatically

## 🧪 Testing Checklist

After migration, test:

1. **Login Flow**
   - [ ] User can login successfully
   - [ ] Auth state changes properly
   - [ ] No UNAUTHENTICATED errors on first function call

2. **Function Calls**
   - [ ] All function calls work after login
   - [ ] No UNAUTHENTICATED errors
   - [ ] Proper error messages for actual failures

3. **Logout/Login**
   - [ ] Functions work after logout and re-login
   - [ ] Auth state resets properly

4. **App Restart**
   - [ ] Functions work after app restart
   - [ ] Persistent auth works correctly

## 📝 Migration Steps for Remaining Files

For each file with FirebaseFunctions usage:

1. Add import:
   ```dart
   import '../firebase/firebase_functions_instance.dart';
   ```

2. Replace instance declaration:
   ```dart
   // OLD
   final FirebaseFunctions _functions = FirebaseFunctions.instance;
   
   // NEW
   FirebaseFunctions get _functions => FirebaseFunctionsInstance.instance;
   ```

3. Add auth readiness check to EVERY function call:
   ```dart
   await FirebaseFunctionsInstance.ensureAuthReady();
   await Future.delayed(const Duration(milliseconds: 500));
   ```

4. Keep existing auth checks and token refresh

## 🔍 Verification

Run this command to find any remaining direct usages:

```bash
# Customer App
findstr /s /n "FirebaseFunctions.instance" apps\customer_app\lib\*.dart | findstr /v "firebase_functions_instance.dart"

# Technician App
findstr /s /n "FirebaseFunctions.instance" apps\technician_app\lib\*.dart | findstr /v "firebase_functions_instance.dart"
```

Should return NO results after complete migration.

## 📞 Support

If UNAUTHENTICATED errors persist after migration:

1. Verify Firebase Console App Check is set to "Not enforced"
2. Check all function calls have `ensureAuthReady()` + 500ms delay
3. Verify token refresh with `getIdToken(true)` before each call
4. Check Firebase Functions logs for actual error details
5. Ensure NO manual Authorization headers are being set

---

**Status**: Migration in progress
**Last Updated**: 2026-01-XX
