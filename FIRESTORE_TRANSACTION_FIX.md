# Firestore Transaction Fix - createBookingRequest

## Issue
**Error:** `Firestore transactions require all reads to be executed before all writes`

## Root Cause
The transaction in `createBookingRequest` function was performing reads AFTER writes, violating Firestore's transaction ordering requirement.

### Previous (Incorrect) Order:
1. ❌ Read idempotency check
2. ❌ Write idempotency record
3. ❌ Call external function (updateWalletBalance) which performed reads
4. ❌ Write booking document

## Solution
Restructured the transaction to follow Firestore's required order: **ALL READS FIRST, THEN ALL WRITES**

### New (Correct) Order:
```typescript
await db.runTransaction(async (transaction) => {
    // ===== ALL READS FIRST =====
    
    // Read 1: Idempotency check
    let idemDoc;
    if (idempotencyKey) {
        const idemRef = db.collection('booking_idempotency').doc(`${customerId}_${idempotencyKey}`);
        idemDoc = await transaction.get(idemRef);
        if (idemDoc.exists) throw new Error('ALREADY_PROCESSED');
    }

    // Read 2: Wallet balance check (if before_work payment)
    let walletDoc;
    if (paymentMode === 'before_work') {
        const walletRef = db.collection('wallets').doc(customerId);
        walletDoc = await transaction.get(walletRef);
        const balance = walletDoc.exists ? (walletDoc.data()?.balance || 0) : 0;
        
        // Validate sufficient balance
        if (balance < price) {
            throw new Error('INSUFFICIENT_WALLET_BALANCE');
        }
    }

    // ===== ALL WRITES AFTER READS =====
    
    // Write 1: Idempotency record
    if (idempotencyKey) {
        transaction.set(idemRef, { ... });
    }

    // Write 2: Wallet deduction
    if (paymentMode === 'before_work' && walletDoc) {
        transaction.set(walletRef, { balance: currentBalance - price, ... });
    }

    // Write 3: Wallet transaction record
    if (paymentMode === 'before_work' && walletDoc) {
        transaction.set(txnRef, { type: 'booking_escrow', ... });
    }

    // Write 4: Booking document
    transaction.set(bookingRef, bookingData);
});
```

## Key Changes

### 1. Removed External Function Call
**Before:**
```typescript
const { updateWalletBalance } = await import('../finance/wallet_logic');
await updateWalletBalance(transaction, customerId, -price, ...);
```

**After:**
```typescript
// Inline wallet operations to control read/write order
const walletDoc = await transaction.get(walletRef); // READ
// ... validation ...
transaction.set(walletRef, { balance: newBalance }); // WRITE
transaction.set(txnRef, { type: 'booking_escrow' }); // WRITE
```

### 2. Added Balance Validation
- Check wallet balance during READ phase
- Throw `INSUFFICIENT_WALLET_BALANCE` error before any writes
- Prevents partial transaction failures

### 3. Clear Section Markers
- Added `// ===== ALL READS FIRST =====` comment
- Added `// ===== ALL WRITES AFTER READS =====` comment
- Makes transaction structure explicit and maintainable

## Testing Checklist

### Before Testing
- [x] Deploy function: `firebase deploy --only functions:createBookingRequest`
- [x] Verify deployment successful

### Test Cases
- [ ] Create booking with `paymentMode: 'after_work'` (no wallet deduction)
- [ ] Create booking with `paymentMode: 'before_work'` (wallet deduction)
- [ ] Test idempotency with duplicate `idempotencyKey`
- [ ] Test insufficient wallet balance scenario
- [ ] Verify no Firestore transaction errors in logs

### Expected Results
✅ Booking created successfully without transaction errors
✅ Wallet balance deducted correctly (if before_work)
✅ Idempotency prevents duplicate bookings
✅ Insufficient balance throws proper error

## Deployment Status
✅ **Deployed:** `createBookingRequest` function updated successfully
- Region: us-central1
- Runtime: Node.js 22 (Gen1)
- Status: Active

## Related Files
- `functions/src/booking/new_booking_flow.ts` - Fixed transaction logic
- `functions/src/finance/wallet_logic.ts` - Wallet operations (not modified)

## Notes
- This fix maintains all existing functionality
- No breaking changes to API contract
- Improved error handling for wallet operations
- Transaction is now atomic and follows Firestore best practices

---

**Fixed by:** Amazon Q Developer
**Date:** 2025
**Status:** ✅ Deployed and Ready for Testing
