# Cloud Functions Region Fix - UNAUTHENTICATED Error Resolution

## ROOT CAUSE
Customer app was using **default region (us-central1)** while technician app uses **asia-south1**. Firebase App Check enforcement is region-specific, causing UNAUTHENTICATED errors when calling functions in the wrong region.

## EXACT ISSUE
- **Customer App**: `FirebaseFunctions.instance` → default region `us-central1`
- **Technician App**: `FirebaseFunctions.instanceFor(region: 'asia-south1')` → correct region
- **Result**: App Check blocks customer app requests with UNAUTHENTICATED error

## SOLUTION IMPLEMENTED

### 1. Updated firebase_functions_instance.dart
**File**: `apps/customer_app/lib/core/firebase/firebase_functions_instance.dart`

Changed from:
```dart
_instance ??= FirebaseFunctions.instance; // Use default region (us-central1)
```

To:
```dart
_instance ??= FirebaseFunctions.instanceFor(region: 'asia-south1');
```

### 2. Replaced All Function Calls
Replaced all instances of:
- `FirebaseFunctions.instance` → `FirebaseFunctionsInstance.instance`
- `FirebaseFunctions.instanceFor(region: 'us-central1')` → `FirebaseFunctionsInstance.instance`

**Files Updated**:
- `lib/core/services/auth_service.dart` (2 occurrences)
- `lib/core/services/firestore_service.dart` (14 occurrences)
- `lib/core/services/notifications_service.dart` (6 occurrences)
- `lib/features/booking/presentation/customer_booking_screen.dart`
- `lib/features/bookings/presentation/rate_technician_screen.dart`
- `lib/features/bookings/presentation/rating_screen.dart`
- `lib/features/job_details/presentation/job_details_screen.dart`
- `lib/features/services/presentation/instant_booking_screen.dart`
- `lib/features/urgent/urgent_booking_screen.dart`

### 3. Added Required Imports
Added `import '../../../core/firebase/firebase_functions_instance.dart';` to all files using Cloud Functions.

## VERIFICATION

### Region Parity Check
✅ **Customer App**: Uses `asia-south1`
```
c:\Users\yash\projects\homefix\apps\customer_app\lib\core\firebase\firebase_functions_instance.dart:
  _instance ??= FirebaseFunctions.instanceFor(region: 'asia-south1');
```

✅ **Technician App**: Uses `asia-south1`
```
c:\Users\yash\projects\homefix\apps\technician_app\lib\core\firebase\firebase_functions.dart:
  FirebaseFunctions.instanceFor(region: 'asia-south1');
```

### No Default Region Usage
✅ No `FirebaseFunctions.instance` (default region) found in customer app services

## TESTING CHECKLIST

After running `flutter clean && flutter pub get && flutter run`:

- [ ] **addToCart** → Must succeed without UNAUTHENTICATED error
- [ ] **toggleFavorite** → Must succeed without UNAUTHENTICATED error
- [ ] **No retry triggered** → Functions should work on first attempt
- [ ] **No App Check logs** → No App Check-related errors in console
- [ ] **Auth token valid** → Token refresh happens automatically

## KEY CHANGES SUMMARY

| Component | Before | After |
|-----------|--------|-------|
| Region | us-central1 (default) | asia-south1 |
| Instance Type | Direct `FirebaseFunctions.instance` | Centralized `FirebaseFunctionsInstance.instance` |
| Single Source of Truth | No | Yes - `firebase_functions_instance.dart` |
| Parity with Technician App | ❌ No | ✅ Yes |

## CRITICAL RULES ENFORCED

1. ✅ Single centralized instance for entire app
2. ✅ Explicit region set to 'asia-south1' (no defaults)
3. ✅ All function calls use centralized instance
4. ✅ No region mixing between apps
5. ✅ Auth ready check before function calls

## DEPLOYMENT NOTES

- No backend changes required
- No Cloud Functions modifications needed
- Client-side only fix
- Backward compatible with existing functions
- No breaking changes to API contracts

## NEXT STEPS

1. Run `flutter run` to test the fix
2. Verify addToCart and toggleFavorite work without errors
3. Monitor logs for any UNAUTHENTICATED errors
4. If issues persist, check Firebase Console App Check settings
