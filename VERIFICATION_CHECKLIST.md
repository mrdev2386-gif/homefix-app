# VERIFICATION CHECKLIST - Cloud Functions Region Fix

## Pre-Test Verification

### 1. Region Configuration
- [x] Customer app uses `asia-south1` region
- [x] Technician app uses `asia-south1` region
- [x] No default region usage in customer app
- [x] Centralized instance in `firebase_functions_instance.dart`

### 2. Code Changes
- [x] `firebase_functions_instance.dart` updated with asia-south1
- [x] All `FirebaseFunctions.instance` replaced with `FirebaseFunctionsInstance.instance`
- [x] All `FirebaseFunctions.instanceFor(region: 'us-central1')` replaced
- [x] Required imports added to all files
- [x] No duplicate instances created

### 3. Files Modified
- [x] `lib/core/firebase/firebase_functions_instance.dart`
- [x] `lib/core/services/auth_service.dart`
- [x] `lib/core/services/firestore_service.dart`
- [x] `lib/core/services/notifications_service.dart`
- [x] `lib/features/booking/presentation/customer_booking_screen.dart`
- [x] `lib/features/bookings/presentation/rate_technician_screen.dart`
- [x] `lib/features/bookings/presentation/rating_screen.dart`
- [x] `lib/features/job_details/presentation/job_details_screen.dart`
- [x] `lib/features/services/presentation/instant_booking_screen.dart`
- [x] `lib/features/urgent/urgent_booking_screen.dart`

### 4. Build Status
- [x] `flutter clean` completed successfully
- [x] `flutter pub get` completed successfully
- [x] No dependency conflicts

## Runtime Testing

### Test 1: Add to Cart
**Expected**: Success without UNAUTHENTICATED error
**Steps**:
1. Login to customer app
2. Browse services
3. Add service to cart
4. Verify cart updates

**Result**: _______________

### Test 2: Toggle Favorite
**Expected**: Success without UNAUTHENTICATED error
**Steps**:
1. Login to customer app
2. Browse services
3. Click heart icon to favorite
4. Verify favorite status updates

**Result**: _______________

### Test 3: No Retry Triggered
**Expected**: Functions work on first attempt
**Steps**:
1. Monitor console logs
2. Look for "Retrying with refreshed token" messages
3. Should not appear for normal operations

**Result**: _______________

### Test 4: Auth Token Valid
**Expected**: Token automatically refreshed when needed
**Steps**:
1. Monitor console for token refresh logs
2. Verify `[AUTH DEBUG]` logs show valid tokens
3. No "unauthenticated" errors in logs

**Result**: _______________

### Test 5: App Check Logs
**Expected**: No App Check-related errors
**Steps**:
1. Monitor console for App Check messages
2. Should not see "App Check" errors
3. Should not see "UNAUTHENTICATED" errors

**Result**: _______________

## Regression Testing

### Test 6: Address Management
**Expected**: Save/update/delete addresses work
**Steps**:
1. Go to Profile → Addresses
2. Add new address
3. Edit address
4. Delete address
5. Set as default

**Result**: _______________

### Test 7: User Profile Update
**Expected**: Profile updates work
**Steps**:
1. Go to Profile
2. Update name/photo
3. Verify changes saved

**Result**: _______________

### Test 8: Notifications
**Expected**: FCM token saved, notifications work
**Steps**:
1. Check console for "FCM token saved"
2. Verify notifications received
3. Mark as read/delete notifications

**Result**: _______________

## Final Sign-Off

- [ ] All tests passed
- [ ] No UNAUTHENTICATED errors
- [ ] No retry loops
- [ ] App Check not interfering
- [ ] Ready for production

**Tested By**: _______________
**Date**: _______________
**Notes**: _______________
