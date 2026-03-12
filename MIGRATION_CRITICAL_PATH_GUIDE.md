# Firebase Functions Gen1→Gen2 Migration - Critical Path Analysis

**Analysis Date:** March 11, 2026
**Total Functions to Migrate:** ~180 functions
**Critical Files Identified:** 15-16 files (high priority for deployment)
**Complete Migration Scope:** 20 files

---

## Executive Summary: Minimum Viable Deployment

To get the project **building and deploying** without crashing on startup, you need to migrate these files in order:

### TIER 0: Build Blockers (0 LOC - Quick Fixes)
1. **tsconfig.json** (5 mins)
   - Remove deprecated compiler options
   - This is blocking the entire build

2. **src/index.ts** (10 mins)
   - Remove duplicate `onCall` import at line 483
   - This prevents module loading

### TIER 1: Compilation Blockers (597 LOC - 3-4 hours)
3. **src/booking/booking_notifications.ts** (313 lines)
   - Firestore trigger: `functions.firestore.document()` → `onDocumentUpdated()`
   - Exported as: `onBookingStatusChange`
   - Impacts: Booking status notifications

4. **src/custom_requests/custom_request_notifications.ts** (242 lines)
   - Firestore trigger: `functions.firestore.document()` → `onDocumentUpdated()`
   - Exported as: `onCustomRequestStatusChange`
   - Impacts: Custom request notifications

**Why These 4 Files First:**
- Files 1-2 prevent the build from starting
- Files 3-4 cause explicit compilation errors (caught by TypeScript)
- Once these are fixed, the project builds and deploys (even if partially)

---

## TIER 2: Core Functionality (2,344 LOC - 12-16 hours)
These files are directly imported and all their functions are exported from index.ts. Needed for core features to work:

5. **src/booking/booking_lifecycle.ts** (603 lines, 9 functions)
   - Core booking operations: admin approval, technician accept, job start/complete, cancellation
   - **MUST FIX** for any booking workflow

6. **src/technician/onboarding.ts** (539 lines, 8 functions)
   - Technician signup flow
   - **MUST FIX** for technician registration

7. **src/payments/razorpay.ts** (719 lines, 4+ functions)
   - Payment orders, verification, refunds, webhooks
   - **MUST FIX** for payment processing

8. **src/booking/new_booking_flow.ts** (850 lines, 6 functions)
   - Alternative booking flow (might be duplicate of lifecycle)
   - Check if truly needed before migrating

9. **src/customer_features.ts** (481 lines, 4 functions + 1 trigger)
   - Mixed: referral validation, ratings, support requests
   - Includes Firestore trigger `onBookingCompletedAwardReferral`

10. **src/payments/payouts.ts** (449 lines, 8 functions)
    - Payout management for technicians

11. **src/technician/profile_management.ts** (269 lines, 5 functions)
    - Region-specific: uses `functions.region('asia-south1')`
    - Must preserve region in Gen2 migration

12. **src/technician/services_management.ts** (381 lines, 4+ functions)
    - Service CRUD operations

13. **src/technician/bank_verification.ts** (178 lines, 2 functions)
    - Callable + webhook: bank account verification

14. **src/technician/kyc.ts** (171 lines, 2 functions)
    - KYC evaluation and status check

15. **src/technician/application.ts** (399 lines, 10 functions)
    - Multi-step technician application form

16. **src/custom_request.ts** (300 lines, 6 functions)
    - Custom service request workflow

---

## TIER 3: Non-Critical (for MVP - 370 LOC - 3-4 hours)
Can be migrated later or commented out for initial deployment:

17. **src/notifications_management.ts** (150 lines, 4 functions)
    - Notification read/delete operations

18. **src/testing/factory.ts** (120 lines, 3 functions)
    - Test data generation (skip for production)

19. **src/testing/actions.ts** (100 lines, 2 functions)
    - Test actions (skip for production)

20. **src/temp_audit.ts** (50 lines, 1 function)
    - Temporary diagnostic (can comment out)

---

## Migration Pattern: Import Statement Changes

### Old Pattern (Gen1):
```typescript
import * as functions from 'firebase-functions';

// Callable
export const myFunction = functions.https.onCall(async (data, context) => {
  // implementation
});

// Webhook
export const webhook = functions.https.onRequest(async (req, res) => {
  // implementation
});

// Firestore trigger
export const onDocUpdate = functions.firestore
  .document('collection/{docId}')
  .onUpdate(async (change, context) => {
    // implementation
  });

// Regional
export const regional = functions.region('asia-south1').https.onCall(async (data, context) => {
  // implementation
});
```

### New Pattern (Gen2):
```typescript
import { onCall } from 'firebase-functions/v2/https';
import { onRequest } from 'firebase-functions/v2/https';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';

// Callable
export const myFunction = onCall(async (request) => {
  const { data, auth } = request;
  // implementation - note: returns value directly, not in response object
});

// Webhook
export const webhook = onRequest(async (req, res) => {
  // implementation remains mostly the same
});

// Firestore trigger
export const onDocUpdate = onDocumentUpdated('collection/{docId}', async (event) => {
  const { data: after, changeType } = event;
  // implementation - parameters are different
});

// Regional
export const regional = onCall(
  { region: 'asia-south1' },
  async (request) => {
    // implementation
  }
);
```

---

## Effort Estimation

| Tier | Files | LOC | Hours | Risk |
|------|-------|-----|-------|------|
| **0 (Blockers)** | 2 | 400 | 0.5 | **CRITICAL** |
| **1 (Compilation)** | 2 | 555 | 4 | **CRITICAL** |
| **2 (Core)** | 12 | 5,449 | 18-24 | **HIGH** |
| **3 (Optional)** | 4 | 370 | 3 | **LOW** |
| **TOTAL (All)** | **20** | **~6,774** | **25-31 hours** | - |

---

## Recommended Implementation Strategy

### Phase 1: Build Success (30 mins)
1. Fix tsconfig.json
2. Fix index.ts duplicate import
3. **Result:** Project builds successfully

### Phase 2: Deployment Ready (3-4 hours)
1. Migrate booking_notifications.ts
2. Migrate custom_request_notifications.ts
3. **Result:** Project deploys without compilation errors

### Phase 3: Core Features (12-16 hours)
1. booking_lifecycle.ts
2. technician/onboarding.ts
3. payments/razorpay.ts
4. (If used) booking/new_booking_flow.ts
5. Other Tier 2 files
6. **Result:** Core platform functionality works

### Phase 4: Complete (3-4 hours)
1. Tier 3 files or comment out for MVP
2. **Result:** Full feature parity

---

## Key Considerations

### 1. **Context API Changes (IMPORTANT)**
Gen1: `(data, context)` where `context.auth`, `context.params`
Gen2: `request` where `request.auth`, `request.data`, `request.params`

### 2. **Return Values**
Gen1: Must return in response/set status
Gen2: Return value directly from function

### 3. **Regional Functions**
Gen1: `functions.region('asia-south1').https.onCall(...)`
Gen2: `onCall({ region: 'asia-south1' }, ...)`

### 4. **Firestore Triggers**
Gen1: `.document('path/{param}').onUpdate(...)`
Gen2: `onDocumentUpdated('path/{param}', ...)`
- Parameter access changes from `change.before/after` to event structure

### 5. **Error Handling**
Gen1: `throw new functions.https.HttpsError('code', 'message')`
Gen2: `throw new HttpsError('code', 'message')` (import from firebase-functions/v2/https)

---

## Files NOT in Top 20 (Can Defer or Skip)

- Admin dashboard functions
- Admin service management
- Admin booking moderation
- Match engine functions
- Chat functions
- Review systems
- Fraud protection triggers
- Finance/wallet logic helpers
- Partner applications
- Instant booking helpers
- Any #TODO or disabled functions

These are either helpers, low-priority features, or already partially v2-compatible.

---

## Testing Strategy Post-Migration

1. **Unit test the changed functions:**
   - Each Callable function: Check response format
   - Each Trigger: Check event handling

2. **Integration test critical paths:**
   - Create booking → Approve → Accept → Complete
   - Register technician → Verify docs → List services
   - Process payment → Verify → Refund

3. **Manual QA:**
   - Test on deployed staging instance with real Firebase project

---

## Success Criteria

✅ Project builds without errors
✅ Project deploys successfully  
✅ Core booking flow works end-to-end
✅ Technician registration works
✅ Payment processing works
✅ Notifications trigger correctly

---

## Notes for Implementation

- Don't migrate all 180 functions at once - focus on the critical path
- Use the templates in `v2_templates/` folder as reference  
- After each Tier, run `npm run build` to catch issues
- Commit frequently so regressions are easy to identify
- If a helper file is only used by one main function, migrate them together
