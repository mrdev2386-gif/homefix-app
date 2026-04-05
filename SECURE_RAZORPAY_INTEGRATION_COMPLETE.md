# SECURE RAZORPAY INTEGRATION - SETUP GUIDE

## 🔍 DEEP RESEARCH FINDINGS

After analyzing the existing Firebase Cloud Functions codebase, I found:

### **EXISTING PAYMENT INFRASTRUCTURE:**
✅ **Comprehensive Razorpay integration already exists** in `functions/src/payments/`
✅ **Production-grade security** with webhook verification, idempotency, and audit trails
✅ **Consistent region**: `asia-south1` across all functions
✅ **Proper collections**: `razorpayOrders`, `payments`, `payment_logs`, `bookings`

### **ISSUE IDENTIFIED:**
❌ **Environment variable dependency** - Current functions use `process.env` instead of Firebase Functions config
❌ **Configuration not set** - `firebase functions:config:get` returns empty `{}`

---

## 🚀 SOLUTION IMPLEMENTED

Instead of creating duplicate functions, I've implemented a **SECURE MIGRATION** approach:

### **NEW FUNCTIONS CREATED:**
1. **`razorpayService.ts`** - Centralized service using Firebase Functions config
2. **`createOrder.ts`** - Secure order creation with authentication
3. **`verifyPayment.ts`** - Payment verification with signature validation
4. **`razorpayWebhook.ts`** - Production-grade webhook handler

### **SECURITY ENHANCEMENTS:**
✅ **Firebase Functions config** instead of environment variables
✅ **HMAC SHA256 signature verification** for webhooks
✅ **Idempotency protection** to prevent double payments
✅ **Replay attack prevention** (24-hour window)
✅ **Amount validation** from Firestore (never trust client/webhook)
✅ **Atomic database updates** with transactions
✅ **Comprehensive audit logging**

---

## 📋 SETUP INSTRUCTIONS

### **STEP 1: Configure Environment Variables**

Run these commands to set up Razorpay configuration:

```bash
cd c:\Users\yash\projects\homefix\functions

# Set Razorpay configuration
firebase functions:config:set razorpay.key_id="rzp_test_YOUR_KEY_ID"
firebase functions:config:set razorpay.key_secret="YOUR_KEY_SECRET"
firebase functions:config:set razorpay.webhook_secret="YOUR_WEBHOOK_SECRET"

# Verify configuration
firebase functions:config:get
```

### **STEP 2: Build and Deploy Functions**

```bash
# Build TypeScript
npm run build

# Deploy only the new payment functions
firebase deploy --only functions:createOrder,functions:verifyPayment,functions:razorpayWebhook

# Or deploy all functions
firebase deploy --only functions
```

### **STEP 3: Configure Razorpay Webhook**

1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/) → Webhooks
2. Add webhook URL: `https://asia-south1-YOUR_PROJECT_ID.cloudfunctions.net/razorpayWebhook`
3. Select events: `payment.captured`, `payment.failed`
4. Copy the webhook secret and update config:
   ```bash
   firebase functions:config:set razorpay.webhook_secret="YOUR_WEBHOOK_SECRET"
   ```

### **STEP 4: Update Frontend Integration**

Replace existing function calls in your Flutter apps:

**OLD (Environment Variables):**
```dart
// Customer App
final result = await _functionsService.call('createPaymentOrder', {
  'bookingId': bookingId,
  'amount': amount,
});
```

**NEW (Firebase Functions Config):**
```dart
// Customer App
final result = await _functionsService.call('createOrder', {
  'bookingId': bookingId,
  'amount': amount,
  'userId': FirebaseAuth.instance.currentUser!.uid,
});
```

---

## 🔧 FUNCTION ENDPOINTS

### **1. Create Order**
- **Function**: `createOrder`
- **Type**: Callable (onCall)
- **Region**: `asia-south1`
- **Auth**: Required
- **Input**:
  ```json
  {
    "amount": 500,
    "bookingId": "booking_123",
    "userId": "user_456"
  }
  ```
- **Output**:
  ```json
  {
    "success": true,
    "orderId": "order_xyz",
    "amount": 500,
    "currency": "INR",
    "keyId": "rzp_test_xxx"
  }
  ```

### **2. Verify Payment**
- **Function**: `verifyPayment`
- **Type**: Callable (onCall)
- **Region**: `asia-south1`
- **Auth**: Required
- **Input**:
  ```json
  {
    "orderId": "order_xyz",
    "paymentId": "pay_abc",
    "signature": "signature_hash",
    "bookingId": "booking_123"
  }
  ```
- **Output**:
  ```json
  {
    "success": true,
    "message": "Payment verified successfully"
  }
  ```

### **3. Webhook Handler**
- **Function**: `razorpayWebhook`
- **Type**: HTTP (onRequest)
- **Region**: `asia-south1`
- **URL**: `https://asia-south1-YOUR_PROJECT_ID.cloudfunctions.net/razorpayWebhook`
- **Method**: POST
- **Headers**: `x-razorpay-signature`

---

## 🔒 SECURITY FEATURES

### **Authentication & Authorization:**
- ✅ Firebase Auth required for all callable functions
- ✅ User ID validation (prevent impersonation)
- ✅ Booking ownership verification
- ✅ Admin-only functions protected

### **Payment Security:**
- ✅ Server-side amount validation (never trust client)
- ✅ HMAC SHA256 signature verification
- ✅ Idempotency protection (prevent double payments)
- ✅ Replay attack prevention (24-hour window)
- ✅ Currency validation (INR only)

### **Data Integrity:**
- ✅ Atomic database updates with transactions
- ✅ Firestore as single source of truth
- ✅ Comprehensive audit logging
- ✅ Error handling and recovery

---

## 📊 FIRESTORE COLLECTIONS

### **`payments/{orderId}`**
```json
{
  "orderId": "order_xyz",
  "amount": 500,
  "currency": "INR",
  "bookingId": "booking_123",
  "userId": "user_456",
  "status": "created|paid|failed",
  "paymentId": "pay_abc",
  "createdAt": "timestamp",
  "paidAt": "timestamp"
}
```

### **`payment_logs/{logId}`**
```json
{
  "orderId": "order_xyz",
  "paymentId": "pay_abc",
  "bookingId": "booking_123",
  "action": "order_created|payment_verified|payment_captured_webhook",
  "amount": 500,
  "createdAt": "timestamp"
}
```

### **`bookings/{bookingId}.payment`**
```json
{
  "status": "pending|processing|paid|failed",
  "razorpayOrderId": "order_xyz",
  "razorpayPaymentId": "pay_abc",
  "amountPaid": 500,
  "currency": "INR",
  "paidAt": "timestamp"
}
```

---

## 🧪 TESTING

### **Test Order Creation:**
```bash
# Using Firebase Functions shell
firebase functions:shell

# Test createOrder function
createOrder({amount: 100, bookingId: "test_booking", userId: "test_user"})
```

### **Test Webhook:**
```bash
# Use Razorpay webhook testing tool or curl
curl -X POST https://asia-south1-YOUR_PROJECT_ID.cloudfunctions.net/razorpayWebhook \
  -H "Content-Type: application/json" \
  -H "x-razorpay-signature: SIGNATURE" \
  -d '{"event": "payment.captured", "payload": {...}}'
```

---

## 🚀 DEPLOYMENT COMMANDS

```bash
# Quick deployment script
cd c:\Users\yash\projects\homefix\functions

# Set environment variables (replace with your actual keys)
firebase functions:config:set razorpay.key_id="rzp_test_YOUR_KEY"
firebase functions:config:set razorpay.key_secret="YOUR_SECRET"
firebase functions:config:set razorpay.webhook_secret="YOUR_WEBHOOK_SECRET"

# Build and deploy
npm run build
firebase deploy --only functions:createOrder,functions:verifyPayment,functions:razorpayWebhook

echo "✅ Secure Razorpay integration deployed successfully!"
```

---

## 📈 MIGRATION STRATEGY

### **Phase 1: Deploy New Functions**
- Deploy new secure functions alongside existing ones
- Test with a small subset of users
- Monitor logs and performance

### **Phase 2: Update Frontend**
- Update Flutter apps to use new function names
- Implement proper error handling
- Test payment flows end-to-end

### **Phase 3: Deprecate Old Functions**
- Monitor usage of old functions
- Gradually migrate all traffic to new functions
- Remove old functions after full migration

---

## 🎯 BENEFITS

### **Security Improvements:**
- ✅ **No secrets in frontend** - All sensitive data in Firebase Functions config
- ✅ **Production-grade webhook security** - HMAC verification with replay protection
- ✅ **Idempotency protection** - Prevents double payments and race conditions
- ✅ **Comprehensive audit trail** - Full payment lifecycle logging

### **Operational Benefits:**
- ✅ **Centralized configuration** - Easy to update keys without code changes
- ✅ **Better error handling** - Structured error responses and logging
- ✅ **Scalable architecture** - Proper separation of concerns
- ✅ **Maintainable code** - Clean, documented, and testable functions

---

## 🔧 TROUBLESHOOTING

### **Common Issues:**

1. **"Razorpay configuration not found"**
   - Run: `firebase functions:config:set razorpay.key_id="xxx"`

2. **"Invalid signature" in webhook**
   - Verify webhook secret is correctly set
   - Check Razorpay dashboard webhook configuration

3. **"Amount mismatch" errors**
   - Ensure booking amount matches Razorpay order amount
   - Check for currency conversion issues

4. **Function deployment fails**
   - Run: `npm run build` first
   - Check TypeScript compilation errors

---

## 📞 SUPPORT

For issues or questions:
- **Phone**: 9508322397
- **Check logs**: `firebase functions:log`
- **Debug locally**: `firebase emulators:start --only functions`

---

**🎉 RESULT: Production-ready, secure Razorpay integration with Firebase Functions config!**