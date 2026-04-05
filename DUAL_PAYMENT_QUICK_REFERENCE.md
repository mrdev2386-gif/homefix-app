# DUAL PAYMENT SYSTEM - QUICK REFERENCE

## 🎯 PAYMENT METHODS

| Method | When Payment | Status Flow | Use Case |
|--------|-------------|-------------|----------|
| **online** | BEFORE service | `awaiting_payment` → `confirmed` → ... → `completed` | Prepaid bookings, high-value services |
| **after_service** | AFTER service | `pending` → ... → `service_completed` → `completed` | Traditional model, trust-based |

---

## 🔧 BACKEND FUNCTIONS

### 1. Create Booking
```javascript
createBookingRequest({
  serviceId: 'xxx',
  technicianId: 'yyy',
  paymentMethod: 'online' | 'after_service', // NEW FIELD
  // ... other fields
})
```

### 2. Create Payment Order
```javascript
createPaymentOrder({
  bookingId: 'xxx'
})
// Works for BOTH payment methods
// Returns: { orderId, amount, paymentMethod }
```

### 3. Confirm After-Service Payment (NEW)
```javascript
confirmAfterServicePayment({
  bookingId: 'xxx'
})
// Only for after_service bookings
// Only technician/admin can call
```

### 4. Webhook Handler
```javascript
// razorpayWebhookV2 - automatically handles both flows
// Sets status based on paymentMethod:
// - online → confirmed
// - after_service → completed
```

---

## 📱 FLUTTER INTEGRATION

### Customer App - Booking Creation

```dart
// 1. Add payment method selection
enum PaymentMethod { online, afterService }

// 2. Create booking with selected method
final result = await createBookingRequest({
  'paymentMethod': selectedMethod == PaymentMethod.online 
    ? 'online' 
    : 'after_service',
  // ... other fields
});

// 3. If online, proceed to payment
if (selectedMethod == PaymentMethod.online) {
  await initiateRazorpayPayment(result['bookingId']);
}
```

### Technician App - Payment Confirmation

```dart
// Show "Confirm Payment" button after service completion
// Only for after_service bookings

if (booking.paymentMethod == 'after_service' && 
    booking.status == 'service_completed') {
  ElevatedButton(
    onPressed: () async {
      await confirmAfterServicePayment({'bookingId': booking.id});
    },
    child: Text('Confirm Payment Received'),
  );
}
```

---

## 🔒 VALIDATION RULES

### Online Payment
- ✅ Payment MUST be completed before service starts
- ✅ Booking status: `awaiting_payment` → `confirmed` after payment
- ✅ Technician blocked from starting until payment received

### After-Service Payment
- ✅ Service can start WITHOUT payment
- ✅ Payment confirmed AFTER service completion
- ✅ Only technician/admin can confirm payment

---

## 📊 BOOKING STATUS FLOW

### Online Payment Flow
```
awaiting_payment (customer pays)
    ↓
confirmed (payment received)
    ↓
approved_by_admin
    ↓
technician_accepted
    ↓
service_in_progress
    ↓
service_completed
    ↓
completed
```

### After-Service Payment Flow
```
pending
    ↓
approved_by_admin
    ↓
technician_accepted
    ↓
service_in_progress
    ↓
service_completed (customer pays)
    ↓
completed (technician confirms)
```

---

## 🔍 FIRESTORE QUERIES

### Get Bookings Awaiting Payment
```javascript
// Online bookings waiting for payment
db.collection('bookings')
  .where('paymentMethod', '==', 'online')
  .where('status', '==', 'awaiting_payment')
  .get();

// After-service bookings waiting for confirmation
db.collection('bookings')
  .where('paymentMethod', '==', 'after_service')
  .where('status', '==', 'service_completed')
  .where('paymentStatus', '==', 'pending')
  .get();
```

---

## 🚨 COMMON ERRORS

| Error | Cause | Solution |
|-------|-------|----------|
| "Payment must be completed before starting service" | Technician trying to start online booking without payment | Customer must complete payment first |
| "Service must be completed before confirming payment" | Technician trying to confirm payment too early | Complete service first |
| "This booking is not set for after-service payment" | Trying to confirm payment for online booking | Use Razorpay payment flow instead |
| "Payment already confirmed" | Duplicate confirmation attempt | Payment already processed |

---

## 📋 DEPLOYMENT CHECKLIST

- [ ] Deploy Cloud Functions
  - [ ] `createBookingRequest`
  - [ ] `createPaymentOrder`
  - [ ] `confirmAfterServicePayment` (NEW)
  - [ ] `razorpayWebhookV2`
  - [ ] `startService`
- [ ] Deploy Firestore Rules
- [ ] Update Customer App
  - [ ] Add payment method selection UI
  - [ ] Handle awaiting_payment status
- [ ] Update Technician App
  - [ ] Add payment confirmation button
  - [ ] Handle payment status checks
- [ ] Test Both Flows
  - [ ] Online payment end-to-end
  - [ ] After-service payment end-to-end

---

## 🔗 RELATED FILES

### Backend
- `functions/src/payments/razorpay.ts` - Payment order creation
- `functions/src/payments/razorpayWebhookV2.ts` - Webhook handler
- `functions/src/payments/after_service_payment.ts` - NEW: After-service confirmation
- `functions/src/booking/unified_booking_lifecycle.ts` - Booking creation & status updates
- `functions/src/index.ts` - Function exports

### Security
- `firestore.rules` - Updated to allow `awaiting_payment` status

### Documentation
- `DUAL_PAYMENT_SYSTEM_COMPLETE.md` - Full implementation guide

---

## 💡 TIPS

1. **Default to after_service** for backward compatibility
2. **Show payment method clearly** in booking UI
3. **Monitor payment_logs** collection for debugging
4. **Use Firestore listeners** for real-time payment status updates
5. **Test webhook locally** using Razorpay test mode

---

## 📞 SUPPORT

Questions? Check:
1. Firebase Functions logs
2. `payment_logs` collection
3. Full documentation: `DUAL_PAYMENT_SYSTEM_COMPLETE.md`

Contact: 9508322397
