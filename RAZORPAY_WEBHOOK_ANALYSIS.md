# RAZORPAY WEBHOOK & PAYMENT VERIFICATION - PRODUCTION HARDENING ANALYSIS

## 🔍 CURRENT IMPLEMENTATION ANALYSIS

### **WEBHOOK HANDLER (razorpayWebhookV2.ts)**

#### **Issue 1: RAW BODY USAGE** ❌
**Current Code:**
```typescript
const body = JSON.stringify(req.body);
const expectedSignature = crypto
    .createHmac("sha256", webhookSecret)
    .update(body)
    .digest("hex");
```

**Problem:**
- Using `JSON.stringify(req.body)` is INCORRECT
- Razorpay signature verification requires the RAW request body
- JSON.stringify may produce different output than original payload
- This can cause signature verification to fail intermittently

**Fix Required:**
```typescript
const body = req.rawBody;  // Use raw body, not JSON.stringify
const expectedSignature = crypto
    .createHmac("sha256", webhookSecret)
    .update(body)
    .digest("hex");
```

#### **Issue 2: IDEMPOTENCY PROTECTION** ✅ GOOD
**Current Implementation:**
```typescript
// STEP 3: Idempotency check - Check if order is already paid
if (orderData.status === "paid") {
    console.log(`${LOG_PREFIX} duplicate_ignored - Order already paid: ${orderId}`);
    return;
}
```

**Status:** ✅ IMPLEMENTED
- Checks if order is already paid before processing
- Prevents duplicate payments
- Uses Firestore as source of truth

#### **Issue 3: TRANSACTION PROTECTION** ✅ GOOD
**Current Implementation:**
```typescript
await db.runTransaction(async (transaction) => {
    // Re-read order to check status inside transaction
    const orderRef = db.collection("razorpayOrders").doc(razorpayOrderId);
    const orderDoc = await transaction.get(orderRef);

    if (orderDoc.exists && orderDoc.data()?.status === "paid") {
        console.log(`${LOG_PREFIX} duplicate_ignored - Order already paid in transaction: ${razorpayOrderId}`);
        throw new Error("IDEMPOTENCY_CHECK_FAILED");
    }
    // Mark order as paid FIRST to prevent race conditions
    if (orderDoc.exists) {
        transaction.update(orderRef, {
            status: "paid",
            paymentId,
            paidAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }
});
```

**Status:** ✅ IMPLEMENTED
- Uses atomic transactions
- Re-reads order inside transaction
- Marks order as paid FIRST to prevent race conditions
- Prevents double updates

---

### **PAYMENT VERIFICATION (verifyPayment in razorpay.ts)**

#### **Issue 1: IDEMPOTENCY CHECK** ✅ GOOD
**Current Code:**
```typescript
// Check if already processed
const isPaid = (booking.payment && booking.payment.status === 'paid') || booking.paymentStatus === 'paid';
if (isPaid) {
    return { success: true, message: 'Payment already processed' };
}
```

**Status:** ✅ IMPLEMENTED
- Checks if payment already processed
- Returns success without double-updating
- Prevents duplicate payments

#### **Issue 2: SIGNATURE VERIFICATION** ✅ GOOD
**Current Code:**
```typescript
// Verify signature
if (!verifyPaymentSignature(razorpayOrderId, razorpayPaymentId, razorpaySignature)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid payment signature');
}
```

**Status:** ✅ IMPLEMENTED
- Uses HMAC SHA256 verification
- Validates signature before processing
- Rejects invalid signatures

#### **Issue 3: AMOUNT VALIDATION** ✅ GOOD
**Current Code:**
```typescript
// Verify amount
if (Math.abs(amount - bookingTotal) > 0.01) {
    throw new functions.https.HttpsError('invalid-argument', 'Amount mismatch');
}
```

**Status:** ✅ IMPLEMENTED
- Validates amount from Firestore
- Never trusts client amount
- Prevents payment tampering

---

## 🎯 PRODUCTION HARDENING CHECKLIST

### **Critical Issues to Fix**
- ❌ **CRITICAL**: Webhook uses `JSON.stringify(req.body)` instead of `req.rawBody`
- ✅ Idempotency protection exists
- ✅ Transaction protection exists
- ✅ Signature verification exists
- ✅ Amount validation exists

### **Logging Improvements Needed**
- ⚠️ Add more detailed logging for webhook failures
- ⚠️ Add logging for duplicate webhook detection
- ⚠️ Add logging for invalid signature attempts

---

## 🔧 FIXES TO APPLY

### **STEP 1: Fix Webhook Raw Body**
**File:** `functions/src/payments/razorpayWebhookV2.ts`

Replace:
```typescript
const body = JSON.stringify(req.body);
```

With:
```typescript
const body = req.rawBody;
```

### **STEP 2: Enhance Logging**
Add detailed logs for:
- Duplicate webhook detection
- Invalid signature attempts
- Successful payment processing

### **STEP 3: Verify Idempotency**
Confirm idempotency checks are in place:
- ✅ Webhook handler checks order status
- ✅ verifyPayment checks booking status
- ✅ Transactions prevent race conditions

---

## 📊 VERIFICATION RESULTS

### **Current State**
| Feature | Status | Notes |
|---------|--------|-------|
| Raw body usage | ❌ NEEDS FIX | Using JSON.stringify instead of rawBody |
| Signature verification | ✅ GOOD | HMAC SHA256 implemented |
| Idempotency protection | ✅ GOOD | Checks order/booking status |
| Transaction safety | ✅ GOOD | Atomic updates with re-read |
| Amount validation | ✅ GOOD | Validates from Firestore |
| Logging | ⚠️ PARTIAL | Needs enhancement |

---

## 🚀 NEXT STEPS

1. Fix webhook raw body usage
2. Enhance logging for production monitoring
3. Test webhook with duplicate payloads
4. Test payment verification with invalid signatures
5. Deploy and monitor

---

**Status: READY FOR HARDENING**