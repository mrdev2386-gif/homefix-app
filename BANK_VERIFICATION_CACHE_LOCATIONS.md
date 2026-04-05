# Bank Verification Cache - Exact Locations Reference

## 📍 CACHE POINT 1: IDEMPOTENCY CACHE

### Location
**File:** `functions/src/technician/bank_verification.ts`
**Lines:** 127-140 (DISABLED)

### Original Code (Before Disabling)
```ts
// ============================================================================
// CRITICAL FIX 1: IDEMPOTENCY CHECK
// ============================================================================
const idempotencyKey = generateIdempotencyKey(uid, accountNumber);
const idempotencyRef = admin.firestore().collection('verificationRequests').doc(idempotencyKey);
const idempotencyDoc = await idempotencyRef.get();

if (idempotencyDoc.exists) {
  const previousResult = idempotencyDoc.data()!;
  console.log(`[BANK_VERIFY] Idempotent request detected - Technician: ${uid}`);
  
  // Return previous result
  const cachedResponse = {
    success: previousResult.success,
    status: previousResult.status,
    message: previousResult.message || 'Previous verification result',
    fundAccountId: previousResult.fundAccountId,
    cached: true
  };
  console.log('BANK VERIFY RESPONSE SENT');
  return cachedResponse;
}
```

### Current Code (Disabled)
```ts
// 🔧 TEMPORARILY DISABLED - Uncomment to enable in production
// if (!force) {
//   const idempotencyKey = generateIdempotencyKey(uid, accountNumber);
//   const idempotencyRef = admin.firestore().collection('verificationRequests').doc(idempotencyKey);
//   const idempotencyDoc = await idempotencyRef.get();
//
//   if (idempotencyDoc.exists) {
//     const previousResult = idempotencyDoc.data()!;
//     console.log(`[BANK_VERIFY] Idempotent request detected - Technician: ${uid}`);
//     
//     const cachedResponse = {
//       success: previousResult.success,
//       status: previousResult.status,
//       message: previousResult.message || 'Previous verification result',
//       fundAccountId: previousResult.fundAccountId,
//       cached: true
//     };
//     console.log('BANK VERIFY RESPONSE SENT');
//     return cachedResponse;
//   }
// }
```

### Firestore Collection
```
Collection: verificationRequests
Document ID: {idempotencyKey}
  - technicianId: string
  - success: boolean
  - status: string
  - message: string
  - fundAccountId: string
  - createdAt: timestamp
  - expiresAt: timestamp
```

### Problem
- Stores verification result with 24-hour expiry
- If verification failed, returns `{success: false}` for 24 hours
- No way to retry without changing account number

---

## 📍 CACHE POINT 2: ALREADY VERIFIED CHECK

### Location
**File:** `functions/src/technician/bank_verification.ts`
**Lines:** 179-198 (DISABLED)

### Original Code (Before Disabling)
```ts
// ============================================================================
// CRITICAL FIX 4: PREVENT DUPLICATE FUND ACCOUNT
// ============================================================================
if (techData.bankVerified === true && techData.bankVerificationStatus === 'verified' && techData.fundAccountId) {
  console.log(`[BANK_VERIFY] Already verified - Technician: ${uid}`);
  
  // Log attempt
  await admin.firestore().collection('payment_logs').add({
    technicianId: uid,
    action: 'bank_verification_attempt',
    status: 'already_verified',
    accountNumber: `***${accountNumber.slice(-4)}`,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  const alreadyVerifiedResponse = {
    success: true,
    status: 'verified',
    message: 'Bank account already verified',
    fundAccountId: techData.fundAccountId
  };
  console.log('BANK VERIFY RESPONSE SENT');
  return alreadyVerifiedResponse;
}
```

### Current Code (Disabled)
```ts
// 🔧 TEMPORARILY DISABLED - Uncomment to enable in production
// if (!force && techData.bankVerified === true && techData.bankVerificationStatus === 'verified' && techData.fundAccountId) {
//   console.log(`[BANK_VERIFY] Already verified - Technician: ${uid}`);
//   
//   await admin.firestore().collection('payment_logs').add({
//     technicianId: uid,
//     action: 'bank_verification_attempt',
//     status: 'already_verified',
//     accountNumber: `***${accountNumber.slice(-4)}`,
//     createdAt: admin.firestore.FieldValue.serverTimestamp()
//   });
//
//   const alreadyVerifiedResponse = {
//     success: true,
//     status: 'verified',
//     message: 'Bank account already verified',
//     fundAccountId: techData.fundAccountId
//   };
//   console.log('BANK VERIFY RESPONSE SENT');
//   return alreadyVerifiedResponse;
// }
```

### Firestore Document
```
Collection: technicians
Document ID: {uid}
Fields:
  - bankVerified: boolean
  - bankVerificationStatus: string ("verified" | "failed" | "verifying")
  - fundAccountId: string
  - bankVerificationMessage: string
  - bankAccountNumber: string
  - bankIfsc: string
  - bankHolderName: string
  - bankVerifiedAt: timestamp
  - bankSubmittedAt: timestamp
```

### Problem
- Checks technician document for verification status
- If marked verified, never retries even if data changed
- Prevents fixing incorrect verifications

---

## 🔄 HOW TO RESTORE CACHE

### Step 1: Locate Cache Point 1
**File:** `functions/src/technician/bank_verification.ts`
**Search for:** `// 🔧 TEMPORARILY DISABLED - Uncomment to enable in production` (first occurrence)

### Step 2: Uncomment Cache Point 1
```ts
if (!force) {
  const idempotencyKey = generateIdempotencyKey(uid, accountNumber);
  const idempotencyRef = admin.firestore().collection('verificationRequests').doc(idempotencyKey);
  const idempotencyDoc = await idempotencyRef.get();

  if (idempotencyDoc.exists) {
    const previousResult = idempotencyDoc.data()!;
    console.log(`[BANK_VERIFY] Idempotent request detected - Technician: ${uid}`);
    
    const cachedResponse = {
      success: previousResult.success,
      status: previousResult.status,
      message: previousResult.message || 'Previous verification result',
      fundAccountId: previousResult.fundAccountId,
      cached: true
    };
    console.log('BANK VERIFY RESPONSE SENT');
    return cachedResponse;
  }
}
```

### Step 3: Locate Cache Point 2
**File:** `functions/src/technician/bank_verification.ts`
**Search for:** `// 🔧 TEMPORARILY DISABLED - Uncomment to enable in production` (second occurrence)

### Step 4: Uncomment Cache Point 2
```ts
if (!force && techData.bankVerified === true && techData.bankVerificationStatus === 'verified' && techData.fundAccountId) {
  console.log(`[BANK_VERIFY] Already verified - Technician: ${uid}`);
  
  await admin.firestore().collection('payment_logs').add({
    technicianId: uid,
    action: 'bank_verification_attempt',
    status: 'already_verified',
    accountNumber: `***${accountNumber.slice(-4)}`,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  const alreadyVerifiedResponse = {
    success: true,
    status: 'verified',
    message: 'Bank account already verified',
    fundAccountId: techData.fundAccountId
  };
  console.log('BANK VERIFY RESPONSE SENT');
  return alreadyVerifiedResponse;
}
```

### Step 5: Rebuild and Deploy
```bash
cd c:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions:verifyTechnicianBankAccountSecure
```

---

## 🧪 TESTING CACHE BEHAVIOR

### Test 1: Verify Cache is Disabled
```dart
// Call 1
final result1 = await FirebaseFunctions.instance
  .httpsCallable('verifyTechnicianBankAccountSecure')
  .call({
    'accountHolderName': 'John Doe',
    'accountNumber': '123456789012',
    'ifscCode': 'SBIN0001234'
  });

// Call 2 (same data)
final result2 = await FirebaseFunctions.instance
  .httpsCallable('verifyTechnicianBankAccountSecure')
  .call({
    'accountHolderName': 'John Doe',
    'accountNumber': '123456789012',
    'ifscCode': 'SBIN0001234'
  });

// Expected: Both calls make fresh API calls
// Check logs for two separate "Creating fund account" messages
```

### Test 2: Verify Force Flag Works
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('verifyTechnicianBankAccountSecure')
  .call({
    'accountHolderName': 'John Doe',
    'accountNumber': '123456789012',
    'ifscCode': 'SBIN0001234',
    'force': true  // Force fresh verification
  });

// Expected: Fresh API call made
// Check logs for "Force flag: true"
```

---

## 📊 CACHE EXPIRY

### Idempotency Cache
- **Expiry:** 24 hours for success, 1 hour for failure
- **Collection:** `verificationRequests`
- **Key:** SHA256 hash of `uid:accountNumber`

### Already Verified Check
- **Expiry:** Until manually cleared or updated
- **Collection:** `technicians`
- **Fields:** `bankVerified`, `bankVerificationStatus`, `fundAccountId`

---

## 🔍 DEBUGGING CACHE ISSUES

### Issue: Stale Failure Cached
**Cause:** Idempotency cache returning old failure
**Solution:** 
1. Delete from `verificationRequests` collection
2. Or pass `force: true` to bypass cache

### Issue: Already Verified Blocking Retry
**Cause:** Already verified check preventing retry
**Solution:**
1. Clear technician bank fields
2. Or pass `force: true` to bypass cache

### Issue: Cache Not Disabled
**Cause:** Code not properly commented out
**Solution:**
1. Verify both cache points are commented
2. Check for `// 🔧 TEMPORARILY DISABLED` comments
3. Rebuild and redeploy

---

## ✅ VERIFICATION

### Cache is Disabled When:
- [ ] Both cache points are commented out
- [ ] Firebase logs show "CACHE DISABLED"
- [ ] Fresh API calls made every time
- [ ] Force flag works when passed

### Cache is Enabled When:
- [ ] Both cache points are uncommented
- [ ] `!force` condition added to both
- [ ] Firebase logs show "Idempotent request detected" or "Already verified"
- [ ] Cached results returned on retry

---

**Status:** ✅ CACHE LOCATIONS DOCUMENTED - READY FOR RESTORATION
