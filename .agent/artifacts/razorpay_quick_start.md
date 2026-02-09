# 🚀 RAZORPAY SETUP - QUICK START GUIDE

## ⚡ 5-MINUTE SETUP

### Step 1: Get Razorpay Credentials

1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Sign up / Log in
3. Navigate to **Settings** → **API Keys**
4. Generate **Test Mode** keys:
   - Key ID: `rzp_test_xxxxx`
   - Key Secret: `xxxxx`
5. Copy both keys

### Step 2: Configure Firebase Functions

```bash
# Navigate to functions directory
cd functions

# Set Razorpay configuration
firebase functions:config:set \
  razorpay.key_id="rzp_test_xxxxx" \
  razorpay.key_secret="your_test_secret_key"

# Verify configuration
firebase functions:config:get
```

### Step 3: Set Up Webhook

1. Go to **Razorpay Dashboard** → **Webhooks**
2. Click **"Create New Webhook"**
3. Enter details:
   ```
   Webhook URL: https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/razorpayWebhook
   Active Events:
     ✅ payment.captured
     ✅ payment.failed
   ```
4. Click **"Create Webhook"**
5. Copy the **Webhook Secret** (starts with `whsec_`)
6. Add to Firebase config:
   ```bash
   firebase functions:config:set razorpay.webhook_secret="whsec_xxxxx"
   ```

### Step 4: Deploy Functions

```bash
# Build and deploy
npm run build
firebase deploy --only functions

# Or deploy specific functions
firebase deploy --only functions:createPaymentOrder,functions:razorpayWebhook,functions:verifyPayment
```

### Step 5: Test Payment

Use Razorpay test cards:

**Success:**
```
Card Number: 4111 1111 1111 1111
CVV: 123
Expiry: 12/25
```

**Failure:**
```
Card Number: 4000 0000 0000 0002
CVV: 123
Expiry: 12/25
```

---

## 📋 CONFIGURATION CHECKLIST

- [ ] Razorpay account created
- [ ] Test API keys generated
- [ ] Firebase Functions config set (key_id, key_secret)
- [ ] Webhook created in Razorpay dashboard
- [ ] Webhook secret added to Firebase config
- [ ] Functions deployed
- [ ] Test payment successful
- [ ] Webhook receiving events

---

## 🔧 FIREBASE FUNCTIONS CONFIG

Your config should look like this:

```json
{
  "razorpay": {
    "key_id": "rzp_test_xxxxx",
    "key_secret": "your_secret_key",
    "webhook_secret": "whsec_xxxxx"
  }
}
```

Verify with:
```bash
firebase functions:config:get
```

---

## 🧪 TESTING WORKFLOW

### 1. Create a Test Booking

```typescript
// Customer app
const createBooking = httpsCallable(functions, 'createBooking');
const booking = await createBooking({
    services: [...],
    address: {...},
    totalAmount: 2723
});
```

### 2. Complete the Booking

```typescript
// Admin panel or technician app
const updateBookingStatus = httpsCallable(functions, 'updateBookingStatus');
await updateBookingStatus({
    bookingId: booking.bookingId,
    status: 'completed'
});
```

### 3. Create Payment Order

```typescript
// Customer app
const createPaymentOrder = httpsCallable(functions, 'createPaymentOrder');
const order = await createPaymentOrder({
    bookingId: booking.bookingId
});

console.log('Order ID:', order.orderId);
console.log('Amount:', order.amount);
```

### 4. Open Razorpay Checkout

```typescript
// Customer app
const options = {
    key: 'rzp_test_xxxxx', // Your key ID
    amount: order.amount * 100,
    currency: 'INR',
    order_id: order.orderId,
    name: 'HomeFix',
    description: `Payment for ${order.bookingNumber}`,
    handler: async (response) => {
        // Verify payment
        const verifyPayment = httpsCallable(functions, 'verifyPayment');
        await verifyPayment({
            bookingId: booking.bookingId,
            razorpayOrderId: response.razorpay_order_id,
            razorpayPaymentId: response.razorpay_payment_id,
            razorpaySignature: response.razorpay_signature
        });
        
        alert('Payment successful!');
    }
};

const rzp = new Razorpay(options);
rzp.open();
```

### 5. Verify in Firestore

Check the booking document:
```javascript
bookings/{bookingId}
  payment: {
    status: "paid",
    razorpayOrderId: "order_xxx",
    razorpayPaymentId: "pay_xxx",
    amountPaid: 2723,
    paidAt: Timestamp
  }
  payout: {
    status: "pending",
    technicianAmount: 1888
  }
```

### 6. Check Webhook Logs

```bash
# View Cloud Functions logs
firebase functions:log --only razorpayWebhook

# Should see:
# "Razorpay webhook event: payment.captured"
# "Payment captured: pay_xxx Order: order_xxx Amount: 2723"
# "Payment processed successfully for booking: booking_xxx"
```

---

## 🎯 COMMON ISSUES & FIXES

### Issue 1: Webhook Not Receiving Events

**Fix:**
1. Check webhook URL is correct
2. Ensure functions are deployed
3. Check Razorpay dashboard → Webhooks → Event Logs
4. Verify webhook secret is set correctly

### Issue 2: Signature Verification Failed

**Fix:**
1. Ensure webhook secret matches Razorpay dashboard
2. Check Firebase config: `firebase functions:config:get`
3. Redeploy functions after config change

### Issue 3: Payment Order Creation Fails

**Fix:**
1. Check booking status is "completed"
2. Verify pricing is locked (pricingLockedAt exists)
3. Ensure user is booking owner
4. Check Cloud Functions logs

### Issue 4: Amount Mismatch

**Fix:**
1. Verify booking.pricing.total is correct
2. Check for rounding errors (use Math.round)
3. Ensure amount is in paise (multiply by 100)

---

## 🔐 SECURITY CHECKLIST

- [ ] Webhook signature verification enabled
- [ ] Amount validation on server side
- [ ] Firestore rules prevent client writes to payment
- [ ] Admin-only access to payout functions
- [ ] All payment logs are backend-only
- [ ] Rate limiting enabled for payment creation

---

## 📱 CLIENT-SIDE INTEGRATION

### Flutter (Customer App)

```dart
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  
  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }
  
  Future<void> _initiatePayment() async {
    // Create payment order
    final createOrder = FirebaseFunctions.instance.httpsCallable('createPaymentOrder');
    final result = await createOrder.call({'bookingId': widget.bookingId});
    
    final options = {
      'key': 'rzp_test_xxxxx',
      'amount': result.data['amount'] * 100,
      'currency': 'INR',
      'order_id': result.data['orderId'],
      'name': 'HomeFix',
      'description': 'Payment for ${result.data['bookingNumber']}',
      'prefill': {
        'contact': result.data['customerPhone'],
        'name': result.data['customerName']
      }
    };
    
    _razorpay.open(options);
  }
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Verify payment
    final verifyPayment = FirebaseFunctions.instance.httpsCallable('verifyPayment');
    await verifyPayment.call({
      'bookingId': widget.bookingId,
      'razorpayOrderId': response.orderId,
      'razorpayPaymentId': response.paymentId,
      'razorpaySignature': response.signature
    });
    
    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment successful!'))
    );
  }
  
  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}'))
    );
  }
  
  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}
```

### Next.js (Admin Panel)

```typescript
// app/(admin)/payouts/page.tsx
'use client';

import { useState, useEffect } from 'react';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';

export default function PayoutsPage() {
  const [pendingPayouts, setPendingPayouts] = useState([]);
  
  useEffect(() => {
    loadPendingPayouts();
  }, []);
  
  const loadPendingPayouts = async () => {
    const getPendingPayouts = httpsCallable(functions, 'getPendingPayouts');
    const result = await getPendingPayouts({ limit: 50 });
    setPendingPayouts(result.data.payouts);
  };
  
  const markAsPaid = async (bookingId: string) => {
    const paymentMethod = prompt('Payment method (bank_transfer/upi):');
    const transactionId = prompt('Transaction ID:');
    
    const markPayoutPaid = httpsCallable(functions, 'markPayoutPaid');
    await markPayoutPaid({
      bookingId,
      paymentMethod,
      transactionId
    });
    
    alert('Payout marked as paid!');
    loadPendingPayouts();
  };
  
  return (
    <div>
      <h1>Pending Payouts</h1>
      <table>
        <thead>
          <tr>
            <th>Booking</th>
            <th>Technician</th>
            <th>Amount</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {pendingPayouts.map((payout) => (
            <tr key={payout.bookingId}>
              <td>{payout.bookingNumber}</td>
              <td>{payout.technicianName}</td>
              <td>₹{payout.technicianAmount}</td>
              <td>
                <button onClick={() => markAsPaid(payout.bookingId)}>
                  Mark as Paid
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

---

## 🚀 GO LIVE CHECKLIST

### Before Going Live

- [ ] Test payment flow end-to-end
- [ ] Test webhook events
- [ ] Test refund flow
- [ ] Test payout marking
- [ ] Verify all security rules
- [ ] Test with different payment methods (card, UPI, netbanking)
- [ ] Test failure scenarios
- [ ] Review all Cloud Functions logs

### Going Live

1. **Generate Live Keys**
   - Razorpay Dashboard → Settings → API Keys
   - Switch to **Live Mode**
   - Generate new keys

2. **Update Firebase Config**
   ```bash
   firebase functions:config:set \
     razorpay.key_id="rzp_live_xxxxx" \
     razorpay.key_secret="your_live_secret"
   ```

3. **Update Webhook**
   - Create new webhook for production URL
   - Copy new webhook secret
   - Update Firebase config

4. **Deploy**
   ```bash
   npm run build
   firebase deploy --only functions
   ```

5. **Update Client Apps**
   - Replace test key with live key
   - Deploy updated apps

6. **Monitor**
   - Watch Cloud Functions logs
   - Monitor Razorpay dashboard
   - Check payment success rate

---

## 📞 SUPPORT

**Razorpay Documentation:**
- [Payment Gateway](https://razorpay.com/docs/payments/)
- [Webhooks](https://razorpay.com/docs/webhooks/)
- [Test Cards](https://razorpay.com/docs/payments/payments/test-card-details/)

**Firebase Documentation:**
- [Cloud Functions](https://firebase.google.com/docs/functions)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

---

**Quick Start Guide v1.0**
**System Status: ✅ READY TO TEST**
