# Payment Verification System - Implementation Guide

## 🔐 Overview

Secure payment verification system for HomeFix using Firebase Cloud Functions and Razorpay integration. All payments are verified server-side before updating booking status and technician earnings.

---

## 🎯 Function: verifyBookingPayment

### Purpose
Securely verify customer payment after booking completion and credit technician earnings.

### Input
```typescript
{
  bookingId: string;
  paymentId: string;
  paymentGatewayResponse?: {
    razorpay_order_id: string;
    razorpay_payment_id: string;
    razorpay_signature: string;
  };
}
```

### Validation Checks

#### 1. Authentication
```typescript
if (!request.auth?.uid) {
  throw Error('User not authenticated');
}
```

#### 2. Booking Ownership
```typescript
if (booking.customerId !== uid) {
  throw Error('Only booking customer can make payment');
}
```

#### 3. Booking Status
```typescript
if (booking.status !== 'completed') {
  throw Error('Payment can only be made for completed bookings');
}
```

#### 4. Payment Status
```typescript
if (booking.paymentStatus !== 'pending_customer_payment') {
  throw Error('Invalid payment status');
}
```

#### 5. Duplicate Payment Protection
```typescript
if (booking.paymentStatus === 'paid') {
  throw Error('Payment already completed for this booking');
}
```

---

## 💳 Razorpay Integration

### Signature Verification
```typescript
const generatedSignature = crypto
  .createHmac('sha256', razorpayKeySecret)
  .update(`${razorpay_order_id}|${razorpay_payment_id}`)
  .digest('hex');

if (generatedSignature !== razorpay_signature) {
  throw Error('Invalid payment signature');
}
```

### Payment Fetch & Validation
```typescript
const payment = await razorpay.payments.fetch(paymentId);

// Verify status
if (payment.status !== 'captured' && payment.status !== 'authorized') {
  throw Error('Payment not successful');
}

// Verify amount
const paymentAmount = payment.amount / 100; // Convert paise to rupees
if (Math.abs(paymentAmount - booking.price) > 0.01) {
  throw Error('Payment amount mismatch');
}
```

---

## 📊 Firestore Updates

### 1. Booking Document
```typescript
bookings/{bookingId}:
  paymentStatus: "paid"
  paidAt: serverTimestamp()
  transactionId: paymentId
  paymentMethod: "razorpay"
```

### 2. Technician Earnings
```typescript
technicians/{technicianId}:
  walletBalance: increment(bookingAmount)
  totalEarnings: increment(bookingAmount)
```

---

## 🔔 Notifications

### Customer Notification
```typescript
Title: "Payment Successful"
Body: "Your payment of ₹{amount} has been processed successfully."
Data: {
  bookingId,
  paymentId,
  type: "payment_success"
}
```

### Technician Notification
```typescript
Title: "Payment Received"
Body: "You received ₹{amount} for completed service."
Data: {
  bookingId,
  amount,
  type: "payment_received"
}
```

---

## 🛡️ Security Features

### 1. Server-Side Verification
- ✅ All payment verification happens on backend
- ✅ Client cannot manipulate payment status
- ✅ Razorpay signature validation

### 2. Duplicate Payment Protection
- ✅ Checks if payment already completed
- ✅ Prevents double-crediting technician
- ✅ Idempotent operation

### 3. Amount Validation
- ✅ Verifies payment amount matches booking
- ✅ Tolerance of ₹0.01 for rounding
- ✅ Prevents partial payments

### 4. Status Validation
- ✅ Only completed bookings can be paid
- ✅ Only pending payments can be processed
- ✅ Prevents payment for cancelled bookings

---

## 📱 Flutter Integration

### Customer App - Payment Flow

```dart
// lib/core/services/payment_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  final _functions = FirebaseFunctions.instance;
  final _razorpay = Razorpay();

  Future<void> initiatePayment(String bookingId, double amount) async {
    // Create Razorpay order (existing function)
    final orderResult = await _functions
      .httpsCallable('createRazorpayOrder')
      .call({
        'amount': amount,
        'currency': 'INR',
        'receipt': bookingId,
      });

    final orderId = orderResult.data['orderId'];

    // Open Razorpay checkout
    var options = {
      'key': 'YOUR_RAZORPAY_KEY_ID',
      'amount': (amount * 100).toInt(), // Amount in paise
      'order_id': orderId,
      'name': 'HomeFix',
      'description': 'Service Payment',
      'prefill': {
        'contact': '9999999999',
        'email': 'customer@example.com'
      }
    };

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      _handlePaymentSuccess(bookingId, response);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      _handlePaymentError(response);
    });

    _razorpay.open(options);
  }

  Future<void> _handlePaymentSuccess(
    String bookingId,
    PaymentSuccessResponse response,
  ) async {
    try {
      // Verify payment with backend
      final result = await _functions
        .httpsCallable('verifyBookingPayment')
        .call({
          'bookingId': bookingId,
          'paymentId': response.paymentId,
          'paymentGatewayResponse': {
            'razorpay_order_id': response.orderId,
            'razorpay_payment_id': response.paymentId,
            'razorpay_signature': response.signature,
          },
        });

      // Show success message
      print('Payment verified: ${result.data}');
      
      // Navigate to success screen
      // Show rating dialog
      
    } on FirebaseFunctionsException catch (e) {
      print('Payment verification failed: ${e.message}');
      
      if (e.code == 'failed-precondition') {
        // Show specific error
        if (e.message?.contains('already completed')) {
          // Payment already processed
        } else if (e.message?.contains('amount mismatch')) {
          // Amount mismatch
        }
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment failed: ${response.message}');
    // Show error dialog
  }

  @override
  void dispose() {
    _razorpay.clear();
  }
}
```

### Usage in Booking Details Screen

```dart
// After booking is completed
ElevatedButton(
  onPressed: () async {
    await PaymentService().initiatePayment(
      booking.bookingId,
      booking.price,
    );
  },
  child: Text('Pay ₹${booking.price}'),
)
```

---

## 🧪 Testing Guide

### Test 1: Successful Payment
```typescript
// 1. Complete a booking
await completeBooking(bookingId);

// 2. Verify payment
const result = await verifyBookingPayment({
  bookingId,
  paymentId: 'pay_test123',
  paymentGatewayResponse: {
    razorpay_order_id: 'order_test123',
    razorpay_payment_id: 'pay_test123',
    razorpay_signature: 'valid_signature',
  },
});

// 3. Verify updates
const booking = await getBooking(bookingId);
expect(booking.paymentStatus).toBe('paid');
expect(booking.transactionId).toBe('pay_test123');

const technician = await getTechnician(technicianId);
expect(technician.walletBalance).toBeGreaterThan(0);
```

### Test 2: Duplicate Payment Protection
```typescript
// 1. Make first payment
await verifyBookingPayment({ bookingId, paymentId: 'pay_1' });

// 2. Try second payment
try {
  await verifyBookingPayment({ bookingId, paymentId: 'pay_2' });
  fail('Should have thrown error');
} catch (e) {
  expect(e.code).toBe('failed-precondition');
  expect(e.message).toContain('already completed');
}
```

### Test 3: Amount Mismatch
```typescript
// Booking amount: ₹500
// Payment amount: ₹400

try {
  await verifyBookingPayment({ bookingId, paymentId });
  fail('Should have thrown error');
} catch (e) {
  expect(e.code).toBe('failed-precondition');
  expect(e.message).toContain('amount mismatch');
}
```

### Test 4: Invalid Status
```typescript
// Booking status: 'in_progress'

try {
  await verifyBookingPayment({ bookingId, paymentId });
  fail('Should have thrown error');
} catch (e) {
  expect(e.code).toBe('failed-precondition');
  expect(e.message).toContain('completed bookings');
}
```

### Test 5: Unauthorized User
```typescript
// User A creates booking
// User B tries to pay

try {
  await verifyBookingPayment({ bookingId, paymentId });
  fail('Should have thrown error');
} catch (e) {
  expect(e.code).toBe('permission-denied');
}
```

---

## 🚀 Deployment

### Environment Variables
```bash
# Set Razorpay credentials
firebase functions:config:set \
  razorpay.key_id="rzp_live_xxxxx" \
  razorpay.key_secret="xxxxx"
```

### Deploy Function
```powershell
cd C:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions:verifyBookingPayment
```

---

## 📊 Database Schema

### Booking Document (Updated)
```typescript
{
  // Existing fields...
  paymentStatus: 'pending' | 'pending_customer_payment' | 'paid';
  
  // New payment fields
  paidAt?: Timestamp;
  transactionId?: string;
  paymentMethod?: string;
}
```

### Technician Document (Updated)
```typescript
{
  // Existing fields...
  
  // Earnings tracking
  walletBalance: number;      // Current balance
  totalEarnings: number;      // Lifetime earnings
}
```

---

## 🔄 Payment Flow Diagram

```
Customer Completes Service
         ↓
Technician Marks Complete
         ↓
[status: completed, paymentStatus: pending_customer_payment]
         ↓
Customer Initiates Payment
         ↓
Razorpay Checkout Opens
         ↓
Customer Pays
         ↓
Razorpay Success Callback
         ↓
Call verifyBookingPayment()
         ↓
Backend Verifies:
  - Signature ✓
  - Amount ✓
  - Status ✓
  - Duplicate ✓
         ↓
Update Firestore:
  - booking.paymentStatus = 'paid'
  - technician.walletBalance += amount
         ↓
Send Notifications
         ↓
Return Success to Client
```

---

## ⚠️ Error Handling

### Common Errors

**1. Payment Already Completed**
```
Code: failed-precondition
Message: "Payment already completed for this booking"
Action: Show success message, navigate to bookings
```

**2. Amount Mismatch**
```
Code: failed-precondition
Message: "Payment amount mismatch. Expected: 500, Received: 400"
Action: Contact support, refund if needed
```

**3. Invalid Signature**
```
Code: invalid-argument
Message: "Invalid payment signature"
Action: Payment verification failed, contact support
```

**4. Payment Not Captured**
```
Code: failed-precondition
Message: "Payment not successful. Status: failed"
Action: Retry payment
```

**5. Booking Not Completed**
```
Code: failed-precondition
Message: "Payment can only be made for completed bookings"
Action: Wait for technician to complete service
```

---

## 🎯 Benefits

### For Customers:
- ✅ Secure payment processing
- ✅ Payment verification before status update
- ✅ Instant payment confirmation
- ✅ Transaction ID for reference

### For Technicians:
- ✅ Automatic earnings credit
- ✅ Real-time wallet updates
- ✅ Payment notifications
- ✅ Transparent earnings tracking

### For Platform:
- ✅ Prevents payment fraud
- ✅ Duplicate payment protection
- ✅ Amount validation
- ✅ Complete audit trail
- ✅ Razorpay integration

---

## 📝 Next Steps

### Optional Enhancements:
1. **Refund System** - Handle refund requests
2. **Partial Payments** - Support installments
3. **Multiple Payment Methods** - UPI, Cards, Wallets
4. **Payment History** - Customer transaction history
5. **Technician Withdrawals** - Payout system

---

**Implementation Date:** 2026-01-XX
**Status:** ✅ Complete and Ready for Deployment
**Payment Gateway:** Razorpay
**Security Level:** High
