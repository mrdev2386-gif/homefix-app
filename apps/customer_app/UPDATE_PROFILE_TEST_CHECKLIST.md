# updateUserProfile - Manual Test Checklist

## Prerequisites
- [ ] Customer app built and running
- [ ] Firebase Functions deployed (updateUserProfile in us-central1)
- [ ] Firestore rules deployed
- [ ] User authenticated in app
- [ ] Terminal open for `firebase functions:log`

---

## STEP 1: Verify Function is Triggered

### 1.1 Open Firebase Functions Log
```bash
cd C:\Users\yash\projects\homefix
firebase functions:log --region us-central1
```

### 1.2 Open Edit Profile Screen
- [ ] Navigate to Profile tab in customer app
- [ ] Tap "Edit Profile" button
- [ ] Verify screen loads with current name, email, phone

### 1.3 Modify Profile Data
- [ ] Change name to: `Test User ${timestamp}`
- [ ] Change email to: `test${timestamp}@example.com`
- [ ] Change phone to: `9999999999`
- [ ] Tap "SAVE CHANGES" button

### 1.4 Check Console Logs (App)
In Flutter console, verify these logs appear:
```
[EditProfileScreen] Starting profile update
[EditProfileScreen] Payload: {name: Test User..., email: test..., phone: 9999999999}
[updateUserProfile] UID: <user_uid>
[updateUserProfile] Payload: {name: Test User..., email: test..., phone: 9999999999}
[updateUserProfile] Calling function...
```

---

## STEP 2: Verify Log Appears in Firebase Functions

### 2.1 Check Firebase Functions Log Terminal
Look for these logs in the terminal running `firebase functions:log`:

```
[updateUserProfile] UID: <user_uid>
[updateUserProfile] Payload: {name: Test User..., email: test..., phone: 9999999999}
[updateUserProfile] Calling function...
[updateUserProfile] Response: {success: true}
[updateUserProfile] ✅ SUCCESS
```

### 2.2 Verify No Errors
- [ ] No "FirebaseFunctionsException" in logs
- [ ] No "❌ Error:" in logs
- [ ] No "permission-denied" errors
- [ ] No "unauthenticated" errors

### 2.3 Check for Protected Field Rejection
If you try to send protected fields (walletBalance, isSuspended, etc.):
```
[updateUserProfile] Rejected protected field: walletBalance for uid: <uid>
[updateUserProfile] ❌ FirebaseFunctionsException
[updateUserProfile] Code: permission-denied
[updateUserProfile] Message: Cannot modify protected field: walletBalance
```

---

## STEP 3: Verify Profile Updated in Firestore

### 3.1 Open Firebase Console
- [ ] Go to https://console.firebase.google.com
- [ ] Select project: homefix-prod
- [ ] Navigate to Firestore Database

### 3.2 Check customers Collection
- [ ] Click on `customers` collection
- [ ] Find document with your UID
- [ ] Verify fields updated:
  - [ ] `name` = "Test User ${timestamp}"
  - [ ] `email` = "test${timestamp}@example.com"
  - [ ] `phone` = "9999999999"
  - [ ] `updatedAt` = current timestamp

### 3.3 Verify Protected Fields Unchanged
- [ ] `walletBalance` = original value (not modified)
- [ ] `isSuspended` = original value (not modified)
- [ ] `referralCode` = original value (not modified)
- [ ] `referredBy` = original value (not modified)
- [ ] `isApproved` = original value (not modified)

---

## STEP 4: Test Error Scenarios

### 4.1 Test Unauthenticated Call
- [ ] Sign out from app
- [ ] Try to edit profile
- [ ] Verify error: "User not authenticated"
- [ ] Check logs: `[updateUserProfile] UID: null`

### 4.2 Test Protected Field Rejection
- [ ] Create a test script that sends:
```dart
await functionsService.updateUserProfile({
  'name': 'Test',
  'walletBalance': 1000, // Protected field
});
```
- [ ] Verify error: "Cannot modify protected field: walletBalance"
- [ ] Check logs: `[updateUserProfile] Rejected protected field: walletBalance`

### 4.3 Test Invalid Data
- [ ] Send empty payload: `{}`
- [ ] Verify error: "No valid fields provided for update"

### 4.4 Test Timeout
- [ ] Simulate slow network (DevTools > Network > Slow 3G)
- [ ] Try to update profile
- [ ] Verify timeout after 30 seconds
- [ ] Check logs: `[updateUserProfile] ❌ Error: TimeoutException`

---

## STEP 5: Verify App Check Integration

### 5.1 Check App Check Token
- [ ] In Firebase console, go to App Check
- [ ] Verify customer app is registered
- [ ] Verify attestation provider is enabled

### 5.2 Test with App Check Disabled (if needed)
- [ ] Temporarily disable App Check in Firebase console
- [ ] Update profile
- [ ] Verify it still works
- [ ] Re-enable App Check

---

## STEP 6: Production Verification

### 6.1 Verify Region
- [ ] Check function URL: `https://us-central1-homefix-prod.cloudfunctions.net/updateUserProfile`
- [ ] Verify region is `us-central1` (not us-east1, europe-west1, etc.)

### 6.2 Verify Function Exists
```bash
firebase functions:list --region us-central1
```
- [ ] `updateUserProfile` appears in list
- [ ] Status is "active"

### 6.3 Verify Firestore Rules
```bash
firebase firestore:get-rules
```
- [ ] Rules include protection for walletBalance, isSuspended, etc.
- [ ] Rules allow Cloud Function writes only

---

## STEP 7: Performance Check

### 7.1 Measure Response Time
- [ ] Update profile
- [ ] Check logs for response time
- [ ] Should be < 2 seconds
- [ ] If > 5 seconds, check Cloud Function performance

### 7.2 Check Cold Start
- [ ] First call after deployment
- [ ] Should be < 5 seconds (cold start)
- [ ] Subsequent calls should be < 1 second

---

## STEP 8: Security Verification

### 8.1 Verify Auth Context
- [ ] Check logs: `[updateUserProfile] UID: <uid>`
- [ ] Verify UID matches authenticated user
- [ ] Verify no other user's UID can be modified

### 8.2 Verify Rate Limiting
- [ ] Update profile 15 times in 60 seconds
- [ ] Verify 11th call is rate limited
- [ ] Check logs: `Rate limit exceeded`

### 8.3 Verify Merge:true
- [ ] Update only `name` field
- [ ] Verify other fields (email, phone) are NOT deleted
- [ ] Check Firestore: all fields still present

---

## FINAL CHECKLIST

- [ ] Function triggered from app
- [ ] Logs appear in Firebase Functions
- [ ] Profile updated in Firestore
- [ ] Protected fields rejected
- [ ] Unauthenticated calls blocked
- [ ] Error handling works
- [ ] Response time acceptable
- [ ] Rate limiting active
- [ ] Merge:true working
- [ ] Region correct (us-central1)
- [ ] App Check integrated
- [ ] Security rules enforced

---

## Troubleshooting

### No logs appear in Firebase Functions
- [ ] Check region: `firebase functions:list --region us-central1`
- [ ] Check function name: should be `updateUserProfile`
- [ ] Check URL in code: `https://us-central1-homefix-prod.cloudfunctions.net/updateUserProfile`
- [ ] Check Firebase console: function deployed?

### "User not authenticated" error
- [ ] Verify user is signed in
- [ ] Check Firebase Auth in console
- [ ] Check `FirebaseAuth.instance.currentUser` is not null

### "Cannot modify protected field" error
- [ ] Remove protected fields from payload
- [ ] Only send: name, email, phone, photoUrl, isOnboarded, profileCompleted, district

### "Permission denied" error
- [ ] Check Firestore rules
- [ ] Verify Cloud Function is filtering protected fields
- [ ] Check `merge: true` is used in Cloud Function

### Profile not updating in Firestore
- [ ] Check Cloud Function logs for errors
- [ ] Verify Firestore rules allow the write
- [ ] Check if transaction failed
- [ ] Verify `updatedAt` timestamp is present

---

**Test Date:** ___________  
**Tester:** ___________  
**Status:** ✅ PASS / ❌ FAIL
