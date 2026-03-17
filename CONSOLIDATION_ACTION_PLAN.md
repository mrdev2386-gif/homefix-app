# HomeFix Duplication Consolidation - Action Plan

**Priority:** CRITICAL
**Timeline:** IMMEDIATE (before production deployment)
**Owner:** DevOps/Backend Team

---

## PHASE 1: ANALYSIS & PLANNING (COMPLETE)

✅ Identified 3 duplicate booking implementations
✅ Identified 2 duplicate wallet implementations
✅ Identified 2 duplicate security implementations
✅ Identified conflicting Firestore schemas
✅ Created audit report

---

## PHASE 2: CONSOLIDATION (ACTION REQUIRED)

### STEP 1: CONSOLIDATE BOOKING LIFECYCLE

**Decision:** Keep `unified_booking_lifecycle.ts`, Delete `booking_lifecycle.ts`

**Reason:**
- `unified_booking_lifecycle.ts` uses state machine validation
- `unified_booking_lifecycle.ts` uses transactions
- `unified_booking_lifecycle.ts` uses `bookingStatus` field (consistent with `booking_creation.ts`)
- `booking_lifecycle.ts` is older, no state machine, no transactions

**Actions:**

1. **Verify all functions from `booking_lifecycle.ts` exist in `unified_booking_lifecycle.ts`:**
   - ✅ `approveBookingByAdmin` - EXISTS
   - ✅ `technicianAcceptBooking` - EXISTS
   - ✅ `completeBooking` - EXISTS (as `completeService`)
   - ✅ `cancelBooking` - EXISTS
   - ✅ `technicianRejectBooking` - EXISTS
   - ⚠️ `rejectBookingByAdmin` - MISSING (need to add)
   - ⚠️ `technicianStartJob` - MISSING (need to add as `startService`)
   - ⚠️ `verifyBookingPayment` - MISSING (need to add)
   - ⚠️ `notifyAdminNewBooking` - MISSING (need to add as trigger)

2. **Add missing functions to `unified_booking_lifecycle.ts`:**
   - Add `rejectBookingByAdmin` function
   - Add `verifyBookingPayment` function
   - Add `notifyAdminNewBooking` trigger

3. **Update `index.ts`:**
   - Remove imports from `booking_lifecycle.ts`
   - Keep imports from `unified_booking_lifecycle.ts`
   - Add missing function exports

4. **Delete `booking_lifecycle.ts`**

5. **Update all Firestore queries:**
   - Change `where('status', ...)` to `where('bookingStatus', ...)`
   - Change status values to match new schema

---

### STEP 2: CONSOLIDATE BOOKING CREATION

**Decision:** Merge `booking_creation.ts` into `unified_booking_lifecycle.ts`

**Reason:**
- `booking_creation.ts` is only 150 lines
- Creates bookings with `bookingStatus` field (consistent)
- Should be part of booking lifecycle

**Actions:**

1. **Copy `createBookingRequest` function to `unified_booking_lifecycle.ts`**

2. **Update `index.ts`:**
   - Import from `unified_booking_lifecycle.ts`
   - Export `createBookingRequest`

3. **Delete `booking_creation.ts`**

---

### STEP 3: CONSOLIDATE WALLET OPERATIONS

**Decision:** Keep `wallet_safety.ts`, Delete `wallet_logic.ts`

**Reason:**
- `wallet_safety.ts` has idempotency protection
- `wallet_safety.ts` has atomic operations
- `wallet_safety.ts` has balance validation
- `wallet_logic.ts` is older, no safety guards

**Actions:**

1. **Verify all functions from `wallet_logic.ts` exist in `wallet_safety.ts`:**
   - ⚠️ `updateWalletBalance` - MISSING (need to add)
   - ⚠️ `processTechnicianEarning` - MISSING (need to add)
   - ✅ `processWalletTransaction` - EXISTS (as callable)

2. **Add missing functions to `wallet_safety.ts`:**
   - Add `updateWalletBalance` function (wrapper around creditWalletAtomic/debitWalletAtomic)
   - Add `processTechnicianEarning` function

3. **Update `index.ts`:**
   - Remove imports from `wallet_logic.ts`
   - Keep imports from `wallet_safety.ts`
   - Update function exports

4. **Delete `wallet_logic.ts`**

5. **Update all Firestore queries:**
   - Change `balance` field to `availableBalance`
   - Change transaction location from root to subcollection
   - Update all wallet operation calls

---

### STEP 4: CONSOLIDATE SECURITY UTILITIES

**Decision:** Keep `security_audit.ts`, Delete `security.ts`

**Reason:**
- `security_audit.ts` is more comprehensive
- `security_audit.ts` has audit logging
- `security_audit.ts` has suspicious activity detection
- `security.ts` is older, less comprehensive

**Actions:**

1. **Verify all functions from `security.ts` exist in `security_audit.ts`:**
   - ⚠️ `checkRateLimit` - MISSING (need to add)
   - ⚠️ `encrypt` - MISSING (need to add)
   - ⚠️ `decrypt` - MISSING (need to add)
   - ⚠️ `sanitizeString` - MISSING (need to add)
   - ⚠️ `sanitizeAadhaar` - MISSING (need to add)
   - ⚠️ `sanitizeEmail` - MISSING (need to add)
   - ⚠️ `sanitizePhone` - MISSING (need to add)
   - ⚠️ `assertAuthenticated` - MISSING (need to add)
   - ⚠️ `assertAdmin` - MISSING (need to add)

2. **Add missing functions to `security_audit.ts`:**
   - Add all encryption/decryption functions
   - Add all sanitization functions
   - Add assertion functions

3. **Update `index.ts`:**
   - Remove imports from `security.ts`
   - Keep imports from `security_audit.ts`
   - Update function exports

4. **Delete `security.ts`**

---

## PHASE 3: FIRESTORE SCHEMA MIGRATION

### Booking Collection Migration

**Current Schema (from `booking_lifecycle.ts`):**
```
status: "pending_admin_approval" | "waiting_technician_acceptance" | "accepted" | "in_progress" | "completed"
```

**New Schema (from `unified_booking_lifecycle.ts`):**
```
bookingStatus: "pending_admin_approval" | "approved_by_admin" | "technician_accepted" | "service_in_progress" | "service_completed" | "completed"
```

**Migration Script:**
```javascript
// Migrate all bookings
db.collection('bookings').get().then(snapshot => {
  snapshot.forEach(doc => {
    const data = doc.data();
    const newStatus = mapOldStatusToNew(data.status);
    doc.ref.update({
      bookingStatus: newStatus,
      status: admin.firestore.FieldValue.delete() // Remove old field
    });
  });
});

function mapOldStatusToNew(oldStatus) {
  const mapping = {
    'pending_admin_approval': 'pending_admin_approval',
    'waiting_technician_acceptance': 'approved_by_admin',
    'accepted': 'technician_accepted',
    'in_progress': 'service_in_progress',
    'completed': 'service_completed'
  };
  return mapping[oldStatus] || oldStatus;
}
```

### Wallet Collection Migration

**Current Schema (from `wallet_logic.ts`):**
```
wallets/{userId}
├── balance: number

walletTransactions/{txnId}
├── userId: string
├── amount: number
```

**New Schema (from `wallet_safety.ts`):**
```
wallets/{userId}
├── availableBalance: number
├── pendingBalance: number
├── lifetimeEarnings: number

wallets/{userId}/transactions/{txnId}
├── type: "credit" | "debit"
├── amount: number
```

**Migration Script:**
```javascript
// Migrate all wallets
db.collection('wallets').get().then(snapshot => {
  snapshot.forEach(doc => {
    const data = doc.data();
    doc.ref.update({
      availableBalance: data.balance || 0,
      pendingBalance: 0,
      lifetimeEarnings: data.balance || 0,
      balance: admin.firestore.FieldValue.delete() // Remove old field
    });
  });
});

// Migrate all transactions
db.collection('walletTransactions').get().then(snapshot => {
  snapshot.forEach(doc => {
    const data = doc.data();
    const userId = data.userId;
    const newTxnRef = db.collection('wallets').doc(userId).collection('transactions').doc();
    newTxnRef.set({
      type: data.type === 'technician_payout' ? 'credit' : 'debit',
      source: data.type,
      status: 'completed',
      amount: data.amount,
      referenceId: data.bookingId || '',
      description: data.description || '',
      balanceBefore: 0,
      balanceAfter: 0,
      createdAt: data.createdAt
    });
    // Delete old transaction
    doc.ref.delete();
  });
});
```

---

## PHASE 4: CODE UPDATES

### Update `index.ts`

**Remove:**
```typescript
import * as bookingLifecycle from './booking/booking_lifecycle';
import * as bookingCreation from './booking/booking_creation';
import * as walletLogic from './finance/wallet_logic';
import * as security from './shared/security';
```

**Keep:**
```typescript
import * as unifiedBookingLifecycle from './booking/unified_booking_lifecycle';
import * as walletSafety from './shared/wallet_safety';
import * as securityAudit from './shared/security_audit';
```

**Update Exports:**
```typescript
// Booking Functions
export const createBookingRequest = unifiedBookingLifecycle.createBookingRequest;
export const approveBookingByAdmin = unifiedBookingLifecycle.approveBookingByAdmin;
export const rejectBookingByAdmin = unifiedBookingLifecycle.rejectBookingByAdmin;
export const technicianAcceptBooking = unifiedBookingLifecycle.technicianAcceptBooking;
export const startService = unifiedBookingLifecycle.startService;
export const completeService = unifiedBookingLifecycle.completeService;
export const technicianRejectBooking = unifiedBookingLifecycle.technicianRejectBooking;
export const cancelBooking = unifiedBookingLifecycle.cancelBooking;
export const verifyBookingPayment = unifiedBookingLifecycle.verifyBookingPayment;

// Wallet Functions
export const creditWalletAtomic = walletSafety.creditWalletAtomic;
export const debitWalletAtomic = walletSafety.debitWalletAtomic;
export const getWalletBalance = walletSafety.getWalletBalance;
export const validateWalletIntegrity = walletSafety.validateWalletIntegrity;
export const checkPayoutDuplicate = walletSafety.checkPayoutDuplicate;
export const checkRefundDuplicate = walletSafety.checkRefundDuplicate;

// Security Functions
export const verifyAdmin = securityAudit.verifyAdmin;
export const verifyOwnership = securityAudit.verifyOwnership;
export const sanitizeInput = securityAudit.sanitizeInput;
export const logSecurityEvent = securityAudit.logSecurityEvent;
```

---

## PHASE 5: TESTING

### Unit Tests

- [ ] Test `createBookingRequest` creates booking with `bookingStatus` field
- [ ] Test `approveBookingByAdmin` updates `bookingStatus` correctly
- [ ] Test `creditWalletAtomic` updates `availableBalance` correctly
- [ ] Test `debitWalletAtomic` validates balance before debit
- [ ] Test wallet transactions stored in subcollection
- [ ] Test security functions work correctly

### Integration Tests

- [ ] Test complete booking flow with new schema
- [ ] Test wallet operations with new schema
- [ ] Test admin panel with new schema
- [ ] Test customer app with new schema
- [ ] Test technician app with new schema

### End-to-End Tests

- [ ] Customer creates booking
- [ ] Admin approves booking
- [ ] Technician accepts job
- [ ] Service completes
- [ ] Payment processed
- [ ] Wallet updated
- [ ] Review created

---

## PHASE 6: DEPLOYMENT

### Pre-Deployment

- [ ] All tests passing
- [ ] Code review completed
- [ ] Firestore schema migration tested
- [ ] Backup of production data
- [ ] Rollback plan documented

### Deployment Steps

1. **Backup production data**
2. **Run Firestore schema migration**
3. **Deploy updated Cloud Functions**
4. **Update admin panel**
5. **Update customer app**
6. **Update technician app**
7. **Monitor logs for errors**
8. **Verify all functions working**

### Post-Deployment

- [ ] Monitor error rates
- [ ] Check booking creation
- [ ] Check wallet operations
- [ ] Check admin panel
- [ ] Verify no duplicate functions
- [ ] Verify single source of truth

---

## ROLLBACK PLAN

If issues occur:

1. **Restore Firestore backup**
2. **Revert Cloud Functions deployment**
3. **Revert app deployments**
4. **Verify system stability**
5. **Investigate root cause**
6. **Fix and redeploy**

---

## TIMELINE

| Phase | Duration | Status |
|-------|----------|--------|
| Analysis & Planning | ✅ Complete | DONE |
| Consolidation | 2-3 hours | TODO |
| Schema Migration | 1-2 hours | TODO |
| Code Updates | 1 hour | TODO |
| Testing | 2-3 hours | TODO |
| Deployment | 1-2 hours | TODO |
| **Total** | **~8-11 hours** | **PENDING** |

---

## SIGN-OFF

- [ ] Backend Lead Approval
- [ ] DevOps Lead Approval
- [ ] QA Lead Approval
- [ ] Product Manager Approval

---

**Status:** 🔴 **BLOCKED - AWAITING CONSOLIDATION**

**Next Action:** Begin Phase 2 consolidation immediately.
