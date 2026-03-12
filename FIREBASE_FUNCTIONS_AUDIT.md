# Firebase Functions Audit Report - Gen1 to Gen2 Migration

## 🔍 Audit Date: January 2026
## Current Version: firebase-functions v4.5.0 (Gen1)
## Target Version: firebase-functions v5+ (Gen2)

---

## 📋 AUDIT FINDINGS

### ✅ Files Scanned
1. `backend/functions/src/index.ts` - Main wallet functions (TypeScript)
2. `backend/functions/src/customRequests.js` - Custom requests (JavaScript)
3. `backend/functions/src/submitReview.js` - Review submission (JavaScript)
4. `backend/functions/src/admin/service_moderation.ts` - Service moderation (TypeScript)
5. `backend/functions/verifyTechnicianBankAccount.ts` - Bank verification (TypeScript)

---

## 🚨 CRITICAL ISSUES FOUND

### Issue 1: Gen1 Callable Function Signature
**Location:** All files using `functions.https.onCall()`
**Problem:** Using Gen1 signature `(data, context)` instead of Gen2 `(request)`
**Severity:** CRITICAL - Causes runtime error

**Files Affected:**
- ✗ `index.ts` - 7 callable functions
- ✗ `customRequests.js` - 4 callable functions
- ✗ `submitReview.js` - 1 callable function
- ✗ `service_moderation.ts` - 3 callable functions
- ✗ `verifyTechnicianBankAccount.ts` - 1 callable function

**Total Callable Functions:** 16

### Issue 2: context.auth Usage
**Problem:** All functions use `context.auth` instead of `request.auth`
**Severity:** CRITICAL - Causes "Cannot read properties of undefined" error

**Occurrences:**
- `index.ts`: 8 occurrences of `context.auth`
- `customRequests.js`: 3 occurrences of `context.auth`
- `submitReview.js`: 1 occurrence of `context.auth`
- `service_moderation.ts`: 4 occurrences of `context.auth`
- `verifyTechnicianBankAccount.ts`: 1 occurrence of `context.auth`

**Total:** 17 occurrences

### Issue 3: Missing Authentication Guards
**Problem:** Some functions don't have proper null checks for auth
**Severity:** HIGH - Can cause runtime errors

### Issue 4: Gen1 Import Statements
**Problem:** Using `import * as functions from 'firebase-functions'` (Gen1)
**Severity:** MEDIUM - Should use Gen2 imports

---

## 📊 DETAILED FINDINGS BY FILE

### 1. backend/functions/src/index.ts
**Status:** ⚠️ NEEDS MIGRATION

**Callable Functions (7):**
1. `requestWithdrawal` - Uses `context.auth`, `context.auth.uid`
2. `creditTechnicianWallet` - No auth check (should have one)
3. `approvePayment` - No auth check (should have one)
4. `generateBookingQR` - Uses `context.auth`, `context.auth.uid`
5. `getTechnicianWallet` - Uses `context.auth`, `context.auth.uid`
6. `getTransactionHistory` - Uses `context.auth`, `context.auth.uid`
7. `getPayoutHistory` - Uses `context.auth`, `context.auth.uid`

**HTTP Functions (2):**
1. `razorpayPaymentWebhook` - Uses `functions.https.onRequest()` (OK for Gen2)
2. `razorpayPayoutWebhook` - Uses `functions.https.onRequest()` (OK for Gen2)

**Issues:**
- ✗ All 7 callable functions use Gen1 signature
- ✗ 6 functions access `context.auth` directly
- ✗ Missing `request.auth` null checks in some functions
- ✗ Using `functions.https.HttpsError` (should update to Gen2)

---

### 2. backend/functions/src/customRequests.js
**Status:** ⚠️ NEEDS MIGRATION

**Callable Functions (4):**
1. `createCustomRequest` - Uses `context.auth.uid`
2. `assignTechnicianToRequest` - No auth check
3. `acceptCustomRequest` - Uses `context.auth.uid`
4. `rejectCustomRequest` - No auth check

**Issues:**
- ✗ All 4 functions use Gen1 signature `(data, context)`
- ✗ 2 functions access `context.auth.uid`
- ✗ 2 functions missing auth checks
- ✗ No null checks for `context.auth`

---

### 3. backend/functions/src/submitReview.js
**Status:** ⚠️ NEEDS MIGRATION

**Callable Functions (1):**
1. `submitReview` - Uses `context.auth.uid`

**Issues:**
- ✗ Uses Gen1 signature `(data, context)`
- ✗ Accesses `context.auth.uid` without null check
- ✗ No proper error handling for undefined auth

---

### 4. backend/functions/src/admin/service_moderation.ts
**Status:** ⚠️ NEEDS MIGRATION

**Callable Functions (3):**
1. `approveService` - Uses `context.auth` in `verifyAdminRole()`
2. `rejectService` - Uses `context.auth` in `verifyAdminRole()`
3. `disableService` - Uses `context.auth` in `verifyAdminRole()`

**Issues:**
- ✗ All 3 functions use Gen1 signature
- ✗ `verifyAdminRole()` accesses `context.auth.token?.admin`
- ✗ Uses `context.auth!.uid` with non-null assertion
- ✗ No proper null checks

---

### 5. backend/functions/verifyTechnicianBankAccount.ts
**Status:** ⚠️ NEEDS MIGRATION

**Callable Functions (1):**
1. `verifyTechnicianBankAccount` - Uses `context.auth.uid`

**HTTP Functions (1):**
1. `razorpayWebhook` - Uses `functions.https.onRequest()` (OK for Gen2)

**Issues:**
- ✗ Callable function uses Gen1 signature
- ✗ Accesses `context.auth.uid` without proper null check
- ✗ Uses `context.auth.uid` in error handling

---

## 🔧 MIGRATION PLAN

### Phase 1: Update package.json
- [ ] Upgrade `firebase-functions` to v5+
- [ ] Update Node.js to 18+ (already set)

### Phase 2: Update Imports
- [ ] Change from `import * as functions` to specific imports
- [ ] Use `onCall` from `firebase-functions/v2/https`
- [ ] Use `onRequest` from `firebase-functions/v2/https`

### Phase 3: Migrate Callable Functions
- [ ] Update all 16 callable functions
- [ ] Change signature from `(data, context)` to `(request)`
- [ ] Replace `context.auth` with `request.auth`
- [ ] Add proper null checks

### Phase 4: Update Error Handling
- [ ] Update `HttpsError` usage
- [ ] Ensure proper error messages

### Phase 5: Testing & Deployment
- [ ] Build and test locally
- [ ] Deploy to Firebase
- [ ] Verify all functions work

---

## 📝 MIGRATION CHECKLIST

### index.ts
- [ ] Update imports
- [ ] Migrate `requestWithdrawal`
- [ ] Migrate `creditTechnicianWallet`
- [ ] Migrate `approvePayment`
- [ ] Migrate `generateBookingQR`
- [ ] Migrate `getTechnicianWallet`
- [ ] Migrate `getTransactionHistory`
- [ ] Migrate `getPayoutHistory`

### customRequests.js
- [ ] Update imports
- [ ] Migrate `createCustomRequest`
- [ ] Migrate `assignTechnicianToRequest`
- [ ] Migrate `acceptCustomRequest`
- [ ] Migrate `rejectCustomRequest`

### submitReview.js
- [ ] Update imports
- [ ] Migrate `submitReview`

### service_moderation.ts
- [ ] Update imports
- [ ] Update `verifyAdminRole()` helper
- [ ] Migrate `approveService`
- [ ] Migrate `rejectService`
- [ ] Migrate `disableService`

### verifyTechnicianBankAccount.ts
- [ ] Update imports
- [ ] Migrate `verifyTechnicianBankAccount`

---

## ✅ EXPECTED RESULTS AFTER MIGRATION

1. ✅ No `context.auth` references
2. ✅ All functions use `request.auth`
3. ✅ Proper null checks: `if (!request.auth) throw new Error(...)`
4. ✅ Gen2 imports from `firebase-functions/v2/https`
5. ✅ No runtime errors
6. ✅ Compatible with firebase-functions v5+

---

## 🚀 NEXT STEPS

1. Review this audit report
2. Proceed with Phase 1: Update package.json
3. Proceed with Phase 2-5: Migrate all functions
4. Run `npm run build` to verify TypeScript compilation
5. Deploy and test

---

**Audit Status:** ✅ COMPLETE  
**Recommendation:** PROCEED WITH MIGRATION  
**Estimated Time:** 2-3 hours  
**Risk Level:** LOW (Breaking changes are isolated to function signatures)
