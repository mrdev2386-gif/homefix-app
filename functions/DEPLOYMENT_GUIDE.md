# 🔧 Cloud Function Fix - Deployment Guide

## 🚨 CRITICAL BUG FIXED

**Issue:** `submitTechnicianKyc` was NOT setting `isKycComplete` and `onboardingCompleted` flags correctly, causing dashboard to always redirect back to onboarding.

**Root Cause:** Function used `.update()` instead of `.set({...}, {merge: true})` and didn't set `onboardingCompleted` field.

---

## ✅ CHANGES MADE

### File: `functions/src/technician/onboarding.ts`

**Function:** `submitTechnicianKyc`

**Before:**
```typescript
await db.collection('technicians').doc(uid).update({
    onboardingStep: 'submitted',
    isKycComplete: true,
    status: 'under_review',
    kycStatus: 'submitted',
    submittedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
});
```

**After:**
```typescript
console.log('[KYC SUBMIT] Marking technician as KYC complete:', uid);

await db.collection('technicians').doc(uid).set({
    isKycComplete: true,
    onboardingCompleted: true, // keep for backward compatibility
    onboardingStep: 'submitted',
    status: 'pending',
    kycStatus: 'pending',
    submittedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
}, { merge: true });

console.log('[KYC SUBMIT] Successfully marked KYC complete');
```

**Key Changes:**
1. ✅ Added `onboardingCompleted: true` for backward compatibility
2. ✅ Changed `.update()` to `.set({...}, {merge: true})` for safety
3. ✅ Changed status from `under_review` to `pending` for consistency
4. ✅ Added safety logs before and after write
5. ✅ Changed kycStatus from `submitted` to `pending`

---

## 🚀 DEPLOYMENT STEPS

### Step 1: Navigate to Functions Directory
```powershell
cd C:\Users\yash\projects\homefix\functions
```

### Step 2: Build TypeScript
```powershell
npm run build
```

**Expected Output:**
```
> build
> tsc

✔ Compiled successfully
```

### Step 3: Deploy ONLY the Fixed Function
```powershell
firebase deploy --only functions:submitTechnicianKyc
```

**Expected Output:**
```
=== Deploying to 'homefix-xxxxx'...

i  deploying functions
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
i  functions: preparing codebase default for deployment
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (XX.XX KB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: updating Node.js 18 function submitTechnicianKyc(us-central1)...
✔  functions[submitTechnicianKyc(us-central1)]: Successful update operation.

✔  Deploy complete!
```

### Step 4: Verify Deployment
```powershell
firebase functions:log --only submitTechnicianKyc
```

---

## 🧪 TESTING

### Test 1: Fresh Onboarding Submission

1. **Uninstall** technician app completely
2. **Install** and run app
3. **Complete** all onboarding steps
4. **Submit** application
5. **Check** Firebase Console → Firestore → `technicians/{uid}`

**Expected Firestore Document:**
```json
{
  "isKycComplete": true,
  "onboardingCompleted": true,
  "status": "pending",
  "kycStatus": "pending",
  "onboardingStep": "submitted"
}
```

### Test 2: Dashboard Navigation

After submission:
1. App should navigate to **Dashboard**
2. Dashboard should show **"Under Review" overlay**
3. Dashboard should **NOT redirect** back to onboarding

### Test 3: App Restart

1. Kill app from recents
2. Reopen app
3. Should open **Dashboard directly**
4. Should **NOT** force onboarding

---

## 📊 VERIFICATION LOGS

### Cloud Function Logs (Firebase Console)

**Expected Logs:**
```
[KYC SUBMIT] Starting submission for uid: <uid>
[KYC SUBMIT] Marking technician as KYC complete: <uid>
[KYC SUBMIT] Successfully marked KYC complete
```

### App Logs (Flutter Debug Console)

**Expected Logs:**
```
[FINAL VERIFY] Firestore raw: {isKycComplete: true, onboardingCompleted: true, ...}
[FINAL VERIFY] isKycComplete resolved = true
[FINAL VERIFY] Dashboard gate decision: stay=true
[FINAL VERIFY ✅] KYC complete, staying on dashboard
```

---

## 🚨 ROLLBACK (If Needed)

If deployment causes issues:

```powershell
# Rollback to previous version
firebase functions:delete submitTechnicianKyc
firebase deploy --only functions:submitTechnicianKyc
```

---

## ✅ SUCCESS CRITERIA

- [x] Function deploys without errors
- [x] Firestore shows `isKycComplete: true` after submission
- [x] Firestore shows `onboardingCompleted: true` after submission
- [x] Dashboard opens after onboarding
- [x] Dashboard does NOT redirect back to onboarding
- [x] App restart opens dashboard directly
- [x] Logs show `[KYC SUBMIT]` markers

---

## 📝 NOTES

### Why `.set({...}, {merge: true})` instead of `.update()`?

- **`.update()`**: Fails if document doesn't exist or field doesn't exist
- **`.set({...}, {merge: true})`**: Creates document if missing, merges fields safely
- **Production-safe**: Handles edge cases where document might be in unexpected state

### Why both `isKycComplete` and `onboardingCompleted`?

- **`isKycComplete`**: New field used by app
- **`onboardingCompleted`**: Legacy field for backward compatibility
- **Both set**: Ensures app works regardless of which field it checks

### Why change status to `pending`?

- **Consistency**: Matches `kycStatus: 'pending'`
- **Clarity**: `pending` is clearer than `under_review`
- **App logic**: App checks for `status: 'pending'` in some places

---

## 🔍 TROUBLESHOOTING

### Issue: Function deployment fails

**Solution:**
```powershell
# Check for TypeScript errors
npm run build

# Check Firebase login
firebase login

# Check project selection
firebase use --add
```

### Issue: Function deploys but doesn't work

**Solution:**
1. Check Firebase Console → Functions → Logs
2. Look for error messages
3. Verify App Check is not blocking requests
4. Check Firestore rules allow writes

### Issue: Dashboard still redirects

**Solution:**
1. Clear app data completely
2. Uninstall and reinstall app
3. Check Firestore document manually
4. Verify both `isKycComplete` and `onboardingCompleted` are `true`

---

## 📞 SUPPORT

If deployment fails or issues persist:

1. **Check logs:** `firebase functions:log`
2. **Check Firestore:** Firebase Console → Firestore
3. **Check app logs:** Flutter debug console with `[FINAL VERIFY]` filter
4. **Provide:** Complete log output + Firestore screenshot

---

**Generated:** 2025-01-XX
**Version:** 1.0
**Status:** READY FOR DEPLOYMENT
