# Cloud Functions Authentication Fix - COMPLETE

## Problem
UNAUTHENTICATED error when calling `addToCart` and `toggleFavorite` Cloud Functions.

## Root Cause Analysis
1. **Region Mismatch**: `firebase_functions_instance.dart` was configured for `asia-south1` but functions are deployed to default `us-central1`
2. **Auth Not Ready**: Functions were being called before Firebase Auth fully initialized
3. **No Token Refresh**: Auth tokens weren't being refreshed before function calls

## Fixes Applied

### 1. Fixed Region Configuration
**File**: `lib/core/firebase/firebase_functions_instance.dart`
- Changed from `FirebaseFunctions.instanceFor(region: 'asia-south1')` 
- To `FirebaseFunctions.instance` (uses default us-central1)

### 2. Added Auth Readiness Checks
**File**: `lib/core/services/firestore_service.dart`

#### addToCart Function
```dart
// STEP 1: Wait for auth to be ready
await FirebaseAuth.instance.authStateChanges().first;

// STEP 2: Ensure user is logged in
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  throw Exception('User not logged in');
}

// STEP 3: Force refresh token
final token = await user.getIdToken(true);
print('🔑 UID: ${user.uid}');
print('🔑 Token: ${token?.substring(0, 20)}...');

// STEP 4: Call function with default region
final callable = FirebaseFunctions.instance.httpsCallable('addToCartCallable');
await callable.call(item.toMap());
```

#### toggleFavorite Function
```dart
// STEP 1: Wait for auth to be ready
await FirebaseAuth.instance.authStateChanges().first;

// STEP 2: Ensure user is logged in
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  throw Exception('User not logged in');
}

// STEP 3: Force refresh token
final token = await user.getIdToken(true);
print('🔑 UID: ${user.uid}');
print('🔑 Token: ${token?.substring(0, 20)}...');

// STEP 4: Call function with default region
final callable = FirebaseFunctions.instance.httpsCallable('toggleFavoriteCallable');
await callable.call({...});
```

### 3. App Check Already Disabled in Debug
**File**: `lib/core/firebase/firebase_init.dart`
```dart
Future<void> initializeFirebaseAppCheck() async {
  if (kReleaseMode) {
    // Only activate in release mode
    await FirebaseAppCheck.instance.activate(...);
  } else {
    debugPrint('⚠️ [APP CHECK] Skipped in debug mode');
  }
}
```

## Cloud Functions Verification

### Cart Management Functions
**File**: `functions/src/customer/cart_management.ts`
- ✅ `addToCartCallable` - Properly checks `context.auth`
- ✅ `updateCartQuantityCallable` - Properly checks `context.auth`
- ✅ `removeFromCartCallable` - Properly checks `context.auth`
- ✅ `clearCartCallable` - Properly checks `context.auth`

### Favorites Management Functions
**File**: `functions/src/customer/favorites_management.ts`
- ✅ `toggleFavoriteCallable` - Properly checks `context.auth`

All functions correctly validate authentication:
```typescript
if (!context.auth) {
  throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
}
const uid = context.auth.uid;
```

## Debug Logging Added

### Console Output
```
🛒 [FirestoreService.addToCart] Called with userId=xxx, item=AC Repair
🔑 [FirestoreService.addToCart] UID: xxx
🔑 [FirestoreService.addToCart] Token: eyJhbGciOiJSUzI1NiIs...
🛒 [FirestoreService.addToCart] Calling Cloud Function addToCartCallable
✅ [FirestoreService.addToCart] Cloud Function succeeded
```

```
❤️ [FirestoreService.toggleFavorite] Called with userId=xxx, serviceId=xxx
🔑 [FirestoreService.toggleFavorite] UID: xxx
🔑 [FirestoreService.toggleFavorite] Token: eyJhbGciOiJSUzI1NiIs...
❤️ [FirestoreService.toggleFavorite] Calling Cloud Function toggleFavoriteCallable
✅ [FirestoreService.toggleFavorite] Cloud Function succeeded
```

## Verification Steps

1. **Test addToCart**:
   - Open service details
   - Click "Add to Cart"
   - Check console for auth logs
   - Verify item appears in cart

2. **Test toggleFavorite**:
   - Click heart icon on any service
   - Check console for auth logs
   - Verify favorite status updates

3. **Expected Behavior**:
   - No UNAUTHENTICATED errors
   - Console shows UID and token
   - Functions execute successfully
   - UI updates immediately (optimistic)

## Files Modified

1. `lib/core/firebase/firebase_functions_instance.dart` - Fixed region
2. `lib/core/services/firestore_service.dart` - Added auth checks to addToCart and toggleFavorite

## Architecture

```
Flutter App (Debug Mode)
    ↓
Firebase Auth (wait for ready)
    ↓
Get ID Token (force refresh)
    ↓
Cloud Functions (us-central1)
    ↓
Validate Auth Context
    ↓
Execute Function
    ↓
Update Firestore
```

## Security

- ✅ App Check disabled in debug mode
- ✅ Auth token refreshed before each call
- ✅ Functions validate `context.auth`
- ✅ User can only access their own data
- ✅ Firestore rules enforce security

## Status: COMPLETE ✅

All fixes applied. Ready for testing.
