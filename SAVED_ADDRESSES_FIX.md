# Saved Addresses Screen Fix

## Issue
Primary addresses saved in the customer profile were not appearing in the Saved Addresses UI because of collection path mismatch.

## Root Cause
- `saveAddress()` method uses Cloud Function which saves addresses to `customers/{uid}/addresses`
- `streamAddresses()` method was reading from `users/{uid}/addresses` 
- Collection path mismatch caused addresses to not appear in the UI

## Changes Made

### 1. Fixed streamAddresses() Collection Path
**File:** `apps/customer_app/lib/core/services/firestore_service.dart`

**Before:**
```dart
return _db.collection('users').doc(userId).collection('addresses')
```

**After:**
```dart
return _db.collection('customers').doc(userId).collection('addresses')
```

### 2. Fixed streamPrimaryAddress() Collection Path and Field
**File:** `apps/customer_app/lib/core/services/firestore_service.dart`

**Before:**
```dart
return _db
    .collection('users')
    .doc(userId)
    .collection('addresses')
    .where('isPrimary', isEqualTo: true)
```

**After:**
```dart
return _db
    .collection('customers')
    .doc(userId)
    .collection('addresses')
    .where('isDefault', isEqualTo: true)
```

## How It Works Now

1. **Address Saving Flow:**
   - User adds/edits address via UI
   - `saveAddress()` calls Cloud Function `manageAddress`
   - Cloud Function saves address to `customers/{uid}/addresses/{addressId}`
   - If `isDefault: true`, also updates `customers/{uid}` profile with primary address data

2. **Address Display Flow:**
   - Saved Addresses screen calls `streamAddresses(userId)`
   - Method now correctly reads from `customers/{uid}/addresses`
   - Addresses appear in UI with proper sorting (newest first)
   - Primary address shows "PRIMARY" badge

## Expected Behavior After Fix

✅ **Address Saving:**
- Address saved to `customers/{uid}/addresses/{addressId}`
- Primary address data also saved to `customers/{uid}` profile

✅ **Address Display:**
- All saved addresses appear in Saved Addresses screen
- Primary address shows "PRIMARY" badge
- Addresses sorted by creation date (newest first)

✅ **Address Management:**
- Edit/delete buttons work correctly
- Set Primary button works for non-primary addresses
- Address selection works in booking flow

## Testing Steps

1. Open customer app
2. Go to Profile → Saved Addresses
3. Add new address with "Set as Primary" checked
4. Verify address appears in list with "PRIMARY" badge
5. Add another address without primary flag
6. Verify both addresses appear in list
7. Test edit/delete functionality

## Files Modified

- `apps/customer_app/lib/core/services/firestore_service.dart`
  - Fixed `streamAddresses()` collection path
  - Fixed `streamPrimaryAddress()` collection path and field name