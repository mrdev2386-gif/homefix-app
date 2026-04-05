# Razorpay Initialization Fix - Quick Reference

## Changes Made

### 1. **bank_verification.ts** (Line 8)
```diff
- const Razorpay = require('razorpay');
+ const RazorpayLib = require('razorpay');
+ const Razorpay = RazorpayLib.default || RazorpayLib;
```

### 2. **bank_verification.ts** (Lines 30-50)
```diff
- if (!instance || !instance.contacts || !instance.fundAccount) {
-     throw new Error('Razorpay instance not properly initialized - missing methods');
- }

+ if (!instance) {
+     throw new functions.https.HttpsError(
+         'failed-precondition',
+         'Razorpay instance is null'
+     );
+ }
+ 
+ if (typeof instance.contacts?.create !== 'function') {
+     throw new functions.https.HttpsError(
+         'failed-precondition',
+         'Razorpay instance not properly initialized - contacts.create is not a function'
+     );
+ }
+ 
+ if (typeof instance.fundAccount?.create !== 'function') {
+     throw new functions.https.HttpsError(
+         'failed-precondition',
+         'Razorpay instance not properly initialized - fundAccount.create is not a function'
+     );
+ }
```

### 3. **razorpay.ts** (Line 6)
```diff
- import Razorpay from 'razorpay';
+ const RazorpayLib = require('razorpay');
+ const Razorpay = RazorpayLib.default || RazorpayLib;
```

### 4. **razorpay.ts** (Lines 50-85)
Added strict validation for `orders.create` and `payments.fetch` methods.

### 5. **testRazorpay.ts** (Line 2)
```diff
- import Razorpay from 'razorpay';
+ const RazorpayLib = require('razorpay');
+ const Razorpay = RazorpayLib.default || RazorpayLib;
```

---

## Why This Fix Works

### Problem
The Razorpay npm package exports as ESM with a `.default` property. When using CommonJS `require()`, the SDK wasn't being properly unwrapped, causing methods to be undefined.

### Solution
```typescript
const RazorpayLib = require('razorpay');
const Razorpay = RazorpayLib.default || RazorpayLib;
```

This handles both:
- **ESM exports:** Uses `RazorpayLib.default`
- **CommonJS exports:** Falls back to `RazorpayLib`

### Validation
Before calling any method, we now verify:
```typescript
if (typeof instance.contacts?.create !== 'function') {
    throw new Error('Method not available');
}
```

---

## Deployment

```bash
cd c:\Users\yash\projects\homefix
firebase deploy --only functions
```

---

## Verification

### Test Bank Verification
```bash
firebase functions:call verifyTechnicianBankAccountSecure \
  --data '{"accountHolderName":"Test","accountNumber":"123456789012","ifscCode":"SBIN0001234"}'
```

### Test Razorpay Connection
```bash
firebase functions:call testRazorpayConnection
```

### Check Logs
```bash
firebase functions:log
```

---

## Expected Output

✅ **Success:**
```
[BANK_VERIFY] Razorpay SDK initialized successfully
[BANK_VERIFY] contacts.create type: function
[BANK_VERIFY] fundAccount.create type: function
```

❌ **Before Fix:**
```
Error: razorpay.contacts.create is not a function
Razorpay instance not properly initialized - missing methods
```

---

## Files Modified
- ✅ `functions/src/technician/bank_verification.ts`
- ✅ `functions/src/payments/razorpay.ts`
- ✅ `functions/src/payments/testRazorpay.ts`

## No Breaking Changes
All changes are backward compatible. Existing code will continue to work.
