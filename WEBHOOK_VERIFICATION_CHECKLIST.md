# ✅ RAZORPAY WEBHOOK VERIFICATION CHECKLIST

## PRE-DEPLOYMENT VERIFICATION

### 1. Configuration Check

```bash
# Verify webhook secret is set
firebase functions:config:get razorpay

# Expected output:
# {
#   "razorpay": {
#     "key_id": "rzp_test_...",
#     "key_secret": "...",
#     "webhook_secret": "whsec_..."
#   }
# }
```

**Checklist**:
- [ ] `razorpay.key_id` is set
- [ ] `razorpay.key_secret` is set
- [ ] `razorpay.webhook_secret` is set
- [ ] All values are non-empty strings

### 2. Code Review

**File**: `functions/src/payments/razorpayWebhookV2.ts`

#### Response Handling
```typescript
// ✅ Check: Response sent ONLY after processing
// Line ~100: res.status(200).send("OK");
// Should be AFTER: await handlePaymentCapturedV2(req.body.payload);
```

**Verification**:
- [ ] Response sent after `handlePaymentCapturedV2` completes
- [ ] No response sent before DB updates
- [ ] Invalid signatures return 400
- [ ] Internal errors return 500

#### Idempotency Protection
```typescript
// ✅ Check: Double-check pattern implemented
// Line ~200: if (orderData.status === "paid") { return; }
// Line ~300: if (orderDoc.exists && orderDoc.data()?.status === "paid") { throw ... }
```

**Verification**:
- [ ] Pre-transaction check exists
- [ ] Transaction-level check exists
- [ ] Order marked as paid FIRST in transaction
- [ ] Duplicate attempts logged

#### Signature Verification
```typescript
// ✅ Check: HMAC SHA256 verification
// Line ~50: const body = req.rawBody || JSON.stringify(req.body);
// Line ~55: const expectedSignature = crypto.createHmac("sha256", webhookSecret)...
```

**Verification**:
- [ ] Uses `req.rawBody` (not `JSON.stringify`)
- [ ] Uses HMAC SHA256
- [ ] Compares with `x-razorpay-signature` header
- [ ] Returns 400 on mismatch

#### Replay Prevention
```typescript
// ✅ Check: 24-hour window
// Line ~150: const REPLAY_WINDOW_MS = 24 * 60 * 60 * 1000;
// Line ~160: if (timeDiff > REPLAY_WINDOW_MS) { res.status(200).send("OK"); }
```

**Verification**:
- [ ] 24-hour window defined
- [ ] Timestamp validation implemented
- [ ] Old payments return 200 (safe ignore)
- [ ] Replay attempts logged

### 3. Build Verification

```bash
# Build functions
cd functions
npm run build

# Expected: No errors
# Check for TypeScript errors
```

**Checklist**:
- [ ] Build completes without errors
- [ ] No TypeScript errors
- [ ] No missing imports
- [ ] No undefined variables

### 4. Deployment Verification

```bash
# Deploy functions
firebase deploy --only functions

# Expected: Deployment successful
# Check for errors in deployment log
```

**Checklist**:
- [ ] Deployment completes successfully
- [ ] No errors in deployment log
- [ ] Function is active in Firebase Console
- [ ] Webhook URL is accessible

---

## POST-DEPLOYMENT VERIFICATION

### 1. Webhook URL Test

```bash
# Test webhook endpoint
curl -X POST https://asia-south1-{project-id}.cloudfunctions.net/razorpayWebhookV2 \
  -H "Content-Type: application/json" \
  -H "x-razorpay-signature: invalid_signature" \
  -d '{"event":"payment.captured","payload":{"payment":{"entity":{"id":"pay_123","amount":10000,"currency":"INR","status":"captured","captured":true}}}}'

# Expected: 400 Bad Request (invalid signature)
```

**Checklist**:
- [ ] Invalid signature returns 400
- [ ] Response is immediate
- [ ] No errors in logs

### 2. Razorpay Dashboard Configuration

**Steps**:
1. Go to Razorpay Dashboard → Settings → Webhooks
2. Add webhook URL: `https://asia-south1-{project-id}.cloudfunctions.net/razorpayWebhookV2`
3. Select events: `payment.captured`, `payment.failed`
4. Copy webhook secret
5. Set in Firebase: `firebase functions:config:set razorpay.webhook_secret="..."`

**Checklist**:
- [ ] Webhook URL added to Razorpay
- [ ] Events selected: `payment.captured`, `payment.failed`
- [ ] Webhook secret copied
- [ ] Webhook secret set in Firebase
- [ ] Functions redeployed

### 3. Test Payment Flow

**Steps**:
1. Create a test booking
2. Initiate payment via `createPaymentOrder`
3. Complete payment in Razorpay Checkout
4. Verify webhook is triggered
5. Check booking status is updated

**Checklist**:
- [ ] Booking created successfully
- [ ] Payment order created
- [ ] Razorpay Checkout opens
- [ ] Payment completes
- [ ] Webhook triggered (check logs)
- [ ] Booking status updated to "confirmed" or "completed"
- [ ] Payment status updated to "paid"

### 4. Duplicate Webhook Test

**Steps**:
1. Manually trigger webhook twice with same payment ID
2. Check that only first webhook processes payment
3. Check that second webhook is ignored
4. Verify logs show duplicate detection

**Checklist**:
- [ ] First webhook processes payment
- [ ] Second webhook returns 200 (safe ignore)
- [ ] Booking payment status is "paid" (not duplicated)
- [ ] `payment_logs` shows duplicate detection
- [ ] No duplicate wallet credits

### 5. Error Handling Test

**Test Invalid Signature**:
```bash
curl -X POST https://asia-south1-{project-id}.cloudfunctions.net/razorpayWebhookV2 \
  -H "Content-Type: application/json" \
  -H "x-razorpay-signature: invalid" \
  -d '{"event":"payment.captured"}'

# Expected: 400 Bad Request
```

**Checklist**:
- [ ] Invalid signature returns 400
- [ ] No payment processed
- [ ] Error logged

**Test Missing Signature**:
```bash
curl -X POST https://asia-south1-{project-id}.cloudfunctions.net/razorpayWebhookV2 \
  -H "Content-Type: application/json" \
  -d '{"event":"payment.captured"}'

# Expected: 400 Bad Request
```

**Checklist**:
- [ ] Missing signature returns 400
- [ ] No payment processed
- [ ] Error logged

**Test Invalid Event**:
```bash
# Manually trigger webhook with wrong event type
# Expected: 200 OK (safe ignore)
```

**Checklist**:
- [ ] Invalid event returns 200
- [ ] No payment processed
- [ ] Event logged as ignored

### 6. Performance Test

**Steps**:
1. Monitor webhook processing time in logs
2. Check that processing completes in < 3 seconds
3. Verify response is sent quickly

**Checklist**:
- [ ] Webhook processing < 3 seconds
- [ ] Response sent immediately
- [ ] No timeout errors
- [ ] No performance degradation

### 7. Logging Verification

**Check Payment Logs**:
```typescript
// Query payment logs
db.collection("payment_logs")
    .orderBy("createdAt", "desc")
    .limit(10)
    .get()
    .then(snapshot => {
        snapshot.forEach(doc => {
            console.log(doc.data());
        });
    });
```

**Expected Logs**:
- `action: "payment_captured_v2"` - Successful payment
- `action: "webhook_duplicate_ignored"` - Duplicate webhook
- `action: "replay_rejected"` - Old payment
- `action: "webhook_invalid_signature"` - Invalid signature

**Checklist**:
- [ ] Payment logs are being created
- [ ] Logs have correct action types
- [ ] Logs have timestamps
- [ ] Logs have payment IDs

### 8. Database Verification

**Check Razorpay Orders**:
```typescript
// Query razorpayOrders collection
db.collection("razorpayOrders")
    .orderBy("createdAt", "desc")
    .limit(10)
    .get()
    .then(snapshot => {
        snapshot.forEach(doc => {
            console.log(doc.data());
        });
    });
```

**Expected Fields**:
- `orderId`: Razorpay order ID
- `amount`: Payment amount
- `status`: "created" or "paid"
- `paymentId`: Razorpay payment ID (after payment)
- `paidAt`: Timestamp (after payment)

**Checklist**:
- [ ] Orders are created with correct amount
- [ ] Status changes from "created" to "paid"
- [ ] Payment ID is recorded
- [ ] Timestamp is recorded

**Check Bookings**:
```typescript
// Query booking after payment
db.collection("bookings")
    .doc(bookingId)
    .get()
    .then(doc => {
        console.log(doc.data());
    });
```

**Expected Fields**:
- `payment.status`: "paid"
- `payment.razorpayPaymentId`: Payment ID
- `payment.amountPaid`: Amount
- `payment.paidAt`: Timestamp
- `status`: "confirmed" or "completed"

**Checklist**:
- [ ] Payment status is "paid"
- [ ] Payment ID is recorded
- [ ] Amount is correct
- [ ] Booking status is updated
- [ ] Timestamp is recorded

---

## MONITORING SETUP

### 1. Firebase Functions Monitoring

```bash
# View live logs
firebase functions:log --follow

# View logs for specific function
firebase functions:log --follow razorpayWebhookV2

# View error logs
firebase functions:log | grep ERROR
```

**Checklist**:
- [ ] Logs are being generated
- [ ] No error messages
- [ ] Webhook processing times are reasonable

### 2. Firestore Monitoring

**Create Alert for Failed Payments**:
```typescript
// Query failed payments
db.collection("payment_logs")
    .where("action", "==", "payment_failed")
    .orderBy("createdAt", "desc")
    .get()
```

**Checklist**:
- [ ] Monitor for failed payments
- [ ] Alert on unusual patterns
- [ ] Track error rates

### 3. Razorpay Dashboard Monitoring

**Steps**:
1. Go to Razorpay Dashboard → Webhooks
2. Check webhook delivery status
3. Monitor for failed deliveries
4. Check retry attempts

**Checklist**:
- [ ] Webhook deliveries are successful
- [ ] No failed deliveries
- [ ] No excessive retries
- [ ] Response times are good

---

## PRODUCTION READINESS CHECKLIST

### Security
- [ ] Signature verification is working
- [ ] Webhook secret is set in Firebase
- [ ] Webhook secret matches Razorpay
- [ ] No secrets in code or logs
- [ ] HTTPS is enforced

### Reliability
- [ ] Idempotency protection is working
- [ ] Duplicate webhooks are handled
- [ ] Replay attacks are prevented
- [ ] Error handling is comprehensive
- [ ] Timeouts are handled

### Performance
- [ ] Webhook processing < 3 seconds
- [ ] Response is sent immediately
- [ ] No blocking operations
- [ ] Async tasks are non-blocking
- [ ] Database queries are optimized

### Monitoring
- [ ] Logs are being generated
- [ ] Payment logs are being created
- [ ] Errors are being logged
- [ ] Monitoring is set up
- [ ] Alerts are configured

### Testing
- [ ] Test payment flow works
- [ ] Duplicate webhooks are handled
- [ ] Error cases are handled
- [ ] Invalid signatures are rejected
- [ ] Performance is acceptable

---

## TROUBLESHOOTING QUICK REFERENCE

| Issue | Cause | Solution |
|-------|-------|----------|
| Webhook not triggering | URL not configured | Add URL to Razorpay dashboard |
| Invalid signature errors | Secret mismatch | Verify secret in Firebase matches Razorpay |
| Duplicate payments | Idempotency not working | Check transaction logic |
| Slow processing | DB queries | Optimize Firestore queries |
| Webhook retries | Returning 500 | Check logs for errors |
| Missing logs | Logging not working | Verify Firestore access |

---

## SIGN-OFF

**Verification Date**: _______________

**Verified By**: _______________

**Status**: 
- [ ] All checks passed
- [ ] Ready for production
- [ ] Issues found (list below)

**Issues Found**:
```
1. 
2. 
3. 
```

**Notes**:
```
[Add any additional notes here]
```

---

## NEXT STEPS

1. ✅ Complete all verification checks
2. ✅ Deploy to production
3. ✅ Monitor webhook processing
4. ✅ Track payment metrics
5. ✅ Set up alerts for failures

---

**Status**: 🚀 **PRODUCTION-READY**
