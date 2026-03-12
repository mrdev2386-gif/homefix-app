# Quick Reference - Firestore Transaction Structure

## ✅ createBookingRequest - Transaction Pattern

### CORRECT Pattern Used

```typescript
// ===== STEP 1: OUTSIDE TRANSACTION =====
// Rate limiter query (uses db.collection)
const recentBookings = await db
    .collection('bookings')
    .where('customerId', '==', customerId)
    .where('createdAt', '>', oneHourAgo)
    .get();  // ✅ OUTSIDE - queries not allowed in transactions

if (recentBookings.size >= RATE_LIMIT) {
    throw new functions.https.HttpsError('resource-exhausted', ...);
}

// ===== STEP 2: INSIDE TRANSACTION =====
await db.runTransaction(async (transaction) => {
    
    // ===== ALL READS FIRST =====
    
    // Read 1
    const idemDoc = await transaction.get(idemRef);  // ✅ transaction.get()
    
    // Read 2
    const walletDoc = await transaction.get(walletRef);  // ✅ transaction.get()
    
    // Validation (in READ phase)
    if (balance < price) {
        throw new Error('INSUFFICIENT_WALLET_BALANCE');  // ✅ Fail fast
    }
    
    // ===== ALL WRITES AFTER READS =====
    
    // Write 1
    transaction.set(idemRef, { ... });  // ✅ transaction.set()
    
    // Write 2
    transaction.set(walletRef, { ... });  // ✅ transaction.set()
    
    // Write 3
    transaction.set(txnRef, { ... });  // ✅ transaction.set()
    
    // Write 4
    transaction.set(bookingRef, bookingData);  // ✅ transaction.set()
});

// ===== STEP 3: OUTSIDE TRANSACTION =====
// Notifications (outside transaction)
await notify.sendUserNotification(...);
```

---

## ❌ INCORRECT Patterns (DO NOT USE)

### Pattern 1: Query Inside Transaction
```typescript
// ❌ WRONG - Queries not allowed in transactions
await db.runTransaction(async (transaction) => {
    const recentBookings = await db
        .collection('bookings')
        .where('customerId', '==', customerId)
        .get();  // ❌ ERROR: Queries not allowed
});
```

### Pattern 2: Write Before Read
```typescript
// ❌ WRONG - Write before read
await db.runTransaction(async (transaction) => {
    transaction.set(walletRef, { ... });  // ❌ Write first
    const walletDoc = await transaction.get(walletRef);  // ❌ Read after
});
```

### Pattern 3: Using db.get() Inside Transaction
```typescript
// ❌ WRONG - Using db.get() instead of transaction.get()
await db.runTransaction(async (transaction) => {
    const walletDoc = await db.collection('wallets').doc(customerId).get();  // ❌ db.get()
    transaction.set(walletRef, { ... });
});
```

### Pattern 4: External Function Call Inside Transaction
```typescript
// ❌ WRONG - External function call inside transaction
await db.runTransaction(async (transaction) => {
    const walletDoc = await transaction.get(walletRef);
    await updateWalletBalance(transaction, customerId, -price);  // ❌ External call
    transaction.set(bookingRef, bookingData);
});
```

---

## ✅ Correct Patterns Summary

| Operation | Location | Method | Status |
|-----------|----------|--------|--------|
| Rate limiting query | OUTSIDE | `db.collection().where().get()` | ✅ |
| Read document | INSIDE | `transaction.get()` | ✅ |
| Write document | INSIDE | `transaction.set()` | ✅ |
| Validation | INSIDE (READ phase) | Direct check | ✅ |
| Notifications | OUTSIDE | `notify.send...()` | ✅ |

---

## 🔑 Key Rules

1. **All reads before writes** - No reads after first write
2. **Use transaction.get()** - Not db.get() inside transaction
3. **Use transaction.set()** - Not db.set() inside transaction
4. **No queries inside** - Firestore queries not allowed in transactions
5. **Validate in READ phase** - Check conditions before writes
6. **Atomic operations** - All writes succeed or all fail

---

## 📍 Location in Code

**File:** `functions/src/booking/new_booking_flow.ts`

**Function:** `createBookingRequest` (Lines 145-385)

**Transaction:** Lines 246-290

**Rate Limiter:** Lines 155-189 (OUTSIDE)

---

## 🚀 Deployment

```bash
# Build
npm run build

# Deploy
firebase deploy --only functions:createBookingRequest
```

---

## ✅ Status

- [x] Rate limiter outside transaction
- [x] All reads use transaction.get()
- [x] All writes after reads
- [x] No external function calls
- [x] Validation in READ phase
- [x] Build successful
- [x] Deployed successfully

**Production Ready:** ✅ YES

---

**Last Updated:** 2025-01-XX
**Status:** ✅ VERIFIED & DEPLOYED
