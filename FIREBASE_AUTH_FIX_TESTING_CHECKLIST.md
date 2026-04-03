# 🧪 Firebase Functions Authentication Testing Checklist

## 📋 PRE-DEPLOYMENT CHECKLIST

### Backend Verification
- [ ] `functions/src/shared/security.ts` updated with auth enforcement
- [ ] All functions use `secureCallable()` wrapper
- [ ] All functions use `.region('asia-south1')`
- [ ] `npm run build` completes without errors
- [ ] No TypeScript compilation errors

### Frontend Verification
- [ ] `FunctionsHelper.dart` updated with enhanced logging
- [ ] `main.dart` updated with auth initialization
- [ ] All function calls use `FunctionsHelper.getCallable()`
- [ ] Region is `asia-south1` in all places
- [ ] `flutter pub get` completes without errors

---

## 🚀 DEPLOYMENT CHECKLIST

### Step 1: Deploy Backend
```bash
cd c:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions
```

- [ ] Build completes successfully
- [ ] Deployment completes successfully
- [ ] All functions show in Firebase Console
- [ ] Functions show region: `asia-south1`

### Step 2: Rebuild App
```bash
cd c:\Users\yash\projects\homefix\apps\customer_app
flutter clean
flutter pub get
flutter run
```

- [ ] Clean completes successfully
- [ ] Pub get completes successfully
- [ ] App builds without errors
- [ ] App launches successfully

---

## ✅ FUNCTIONAL TESTING

### Test 1: App Initialization
**Expected Logs**:
```
🔥 Initializing Firebase...
✅ Firebase initialized successfully
🔒 Activating App Check (debug mode)...
✅ App Check activated
🔑 Waiting for Firebase Auth to initialize...
✅ Firebase Auth ready
🚀 Starting HomeFix App...
```

- [ ] All initialization logs appear
- [ ] No errors during initialization
- [ ] App reaches login/home screen

### Test 2: User Authentication
**Action**: Login with Google/Phone

**Expected**:
- [ ] Login succeeds without errors
- [ ] User UID appears in logs
- [ ] User redirected to home screen

### Test 3: Update User Profile
**Action**: Update profile (name, email, etc.)

**Frontend Logs**:
```
========================================
📡 [FunctionsHelper] Preparing to call: updateUserProfile
========================================
✅ [FunctionsHelper] User authenticated
   UID: <user_id>
🔄 [FunctionsHelper] Refreshing auth token...
✅ [FunctionsHelper] Token refreshed successfully
📡 [FunctionsHelper] Creating callable: updateUserProfile
✅ [FunctionsHelper] Callable created successfully
========================================
```

**Backend Logs** (Firebase Console):
```
[updateUserProfile] 🔍 Incoming request
[updateUserProfile] Auth context: { hasAuth: true, uid: '<user_id>', token: 'present' }
[updateUserProfile] ✅ AUTHENTICATED: UID=<user_id>
[updateUserProfile] ✅ SUCCESS
```

- [ ] Frontend logs show authentication flow
- [ ] Backend logs show auth validation
- [ ] Profile updates successfully
- [ ] No UNAUTHENTICATED errors

### Test 4: Add to Cart
**Action**: Add service to cart

**Expected**:
- [ ] Function call succeeds
- [ ] Item appears in cart
- [ ] Firestore updated correctly
- [ ] No UNAUTHENTICATED errors

### Test 5: Toggle Favorite
**Action**: Add/remove service from favorites

**Expected**:
- [ ] Function call succeeds
- [ ] Favorite status updates
- [ ] Firestore updated correctly
- [ ] No UNAUTHENTICATED errors

### Test 6: Create Booking
**Action**: Create a new booking

**Expected**:
- [ ] Function call succeeds
- [ ] Booking created in Firestore
- [ ] Booking ID returned
- [ ] No UNAUTHENTICATED errors

### Test 7: Submit Rating
**Action**: Rate a completed booking

**Expected**:
- [ ] Function call succeeds
- [ ] Rating saved in Firestore
- [ ] Technician rating updated
- [ ] No UNAUTHENTICATED errors

### Test 8: Create Custom Request
**Action**: Create custom service request

**Expected**:
- [ ] Function call succeeds
- [ ] Request created in Firestore
- [ ] Request ID returned
- [ ] No UNAUTHENTICATED errors

### Test 9: Validate Referral Code
**Action**: Enter referral code

**Expected**:
- [ ] Function call succeeds
- [ ] Code validation works
- [ ] Appropriate response returned
- [ ] No UNAUTHENTICATED errors

### Test 10: Submit Support Request
**Action**: Submit support ticket

**Expected**:
- [ ] Function call succeeds
- [ ] Ticket created in Firestore
- [ ] Ticket ID returned
- [ ] No UNAUTHENTICATED errors

---

## 🔐 SECURITY TESTING

### Test 11: Unauthenticated Access
**Action**: Call function without login

**Expected**:
- [ ] Function call fails
- [ ] Error: "User not logged in"
- [ ] No data modification
- [ ] Clear error message

### Test 12: Invalid Token
**Action**: Call function with expired token

**Expected**:
- [ ] Token refresh attempted
- [ ] New token obtained
- [ ] Function call succeeds
- [ ] OR clear error if refresh fails

### Test 13: Wrong Region
**Action**: Temporarily change region to `us-central1`

**Expected**:
- [ ] Function call fails
- [ ] Clear error message
- [ ] No data modification

---

## 🐛 ERROR HANDLING TESTING

### Test 14: Network Timeout
**Action**: Call function with poor network

**Expected**:
- [ ] Timeout after 60 seconds
- [ ] Clear timeout error
- [ ] App doesn't crash
- [ ] User can retry

### Test 15: Invalid Data
**Action**: Call function with invalid parameters

**Expected**:
- [ ] Function rejects invalid data
- [ ] Clear validation error
- [ ] No data modification
- [ ] User can correct and retry

### Test 16: Permission Denied
**Action**: Try to access admin-only function

**Expected**:
- [ ] Function rejects request
- [ ] Error: "Permission denied"
- [ ] No data modification
- [ ] Clear error message

---

## 📊 PERFORMANCE TESTING

### Test 17: First Call Performance
**Action**: Call function immediately after login

**Measure**:
- [ ] Token refresh time: < 500ms
- [ ] Function call time: < 2s
- [ ] Total time: < 3s
- [ ] Acceptable user experience

### Test 18: Subsequent Calls Performance
**Action**: Call same function multiple times

**Measure**:
- [ ] No token refresh needed
- [ ] Function call time: < 1s
- [ ] Consistent performance
- [ ] No degradation

### Test 19: Concurrent Calls
**Action**: Call multiple functions simultaneously

**Expected**:
- [ ] All calls succeed
- [ ] No race conditions
- [ ] Correct data updates
- [ ] No UNAUTHENTICATED errors

---

## 🔄 EDGE CASE TESTING

### Test 20: Logout and Login
**Action**: Logout, then login again

**Expected**:
- [ ] Logout clears auth state
- [ ] Login creates new session
- [ ] Functions work after re-login
- [ ] No stale token issues

### Test 21: App Restart
**Action**: Kill and restart app

**Expected**:
- [ ] Auth state persists
- [ ] Functions work immediately
- [ ] No re-authentication needed
- [ ] Smooth user experience

### Test 22: Token Expiry
**Action**: Wait for token to expire (1 hour)

**Expected**:
- [ ] Token refresh triggered automatically
- [ ] Function call succeeds
- [ ] No user intervention needed
- [ ] Seamless experience

---

## 📝 LOGGING VERIFICATION

### Test 23: Frontend Logs
**Check**:
- [ ] All function calls logged
- [ ] Auth state logged
- [ ] Token refresh logged
- [ ] Errors logged with details
- [ ] Success logged

### Test 24: Backend Logs
**Check** (Firebase Console):
- [ ] All function invocations logged
- [ ] Auth context logged
- [ ] UID validation logged
- [ ] Errors logged with details
- [ ] Success logged

---

## ✅ FINAL VERIFICATION

### All Tests Passed?
- [ ] All 24 tests completed
- [ ] No UNAUTHENTICATED errors
- [ ] All functions work correctly
- [ ] Logs show proper authentication flow
- [ ] Performance is acceptable
- [ ] Error handling works correctly

### Production Readiness
- [ ] Backend deployed to production
- [ ] App tested on multiple devices
- [ ] No critical bugs found
- [ ] Documentation updated
- [ ] Team notified of changes

---

## 🚨 ROLLBACK PLAN

If tests fail:

1. **Identify Issue**:
   - Check logs for specific error
   - Identify which test failed
   - Determine root cause

2. **Quick Fix**:
   - If minor: Fix and redeploy
   - If major: Rollback to previous version

3. **Rollback Commands**:
   ```bash
   # Rollback functions
   firebase functions:delete <function_name>
   git checkout HEAD~1 functions/
   firebase deploy --only functions
   
   # Rollback app
   git checkout HEAD~1 apps/customer_app/
   flutter clean && flutter pub get && flutter run
   ```

---

## 📞 SUPPORT

**Issues During Testing?**
- Check `FIREBASE_AUTH_FIX_QUICK_REF.md` for quick troubleshooting
- Check `FIREBASE_FUNCTIONS_AUTH_FIX_COMPLETE.md` for detailed guide
- Contact: 9508322397

---

**Testing Status**: ⏳ PENDING
**Date**: 2024
**Tester**: _____________
**Sign-off**: _____________
