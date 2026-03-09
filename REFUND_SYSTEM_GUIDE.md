# Refund System - Implementation Guide

## 🔐 Overview

Secure refund processing system for HomeFix using Firebase Cloud Functions and Razorpay API. All refunds are processed by admins with automatic wallet adjustments and duplicate protection.

---

## 🎯 Function: refundBookingPayment

### Purpose
Process refunds for paid bookings and adjust technician wallet balances.

### Input
```typescript
{
  bookingId: string;
  refundReason: string;
}
```

### Authorization
- ✅ Only admins can process refunds
- ❌ Customers and technicians cannot initiate refunds

### Validation Checks

#### 1. Admin Verification
```typescript
const adminDoc = await db.collection('admins').doc(uid).get();
if (!adminDoc.exists) {
  throw Error('Only admins can process refunds');
}
```

#### 2. Payment Status
```typescript
if (booking.paymentStatus !== 'paid') {
  throw Error('Cannot refund booking with payment status: ${status}');
}
```

#### 3. Duplicate Refund Protection
```typescript
if (booking.paymentStatus === 'refunded') {
  throw Error('Refund already processed for this booking');
}
```

#### 4. Transaction ID Validation
```typescript
if (!booking.transactionId) {
  throw Error('No transaction ID found for this booking');
}
```

#### 5. Wallet Balance Check
```typescript
if (newWalletBalance < 0) {
  throw Error('Insufficient wallet balance');
}
```

---

## 💳 Razorpay Refund Integration

### Refund API Call
```typescript
const refund = await razorpay.payments.refund(transactionId, {
  amount: bookingPrice * 100,  // Convert to paise
  notes: {
    bookingId,
    reason: refundReason
  }
});
```

### Status Validation
```typescript
if (refund.status !== 'processed' && refund.status !== 'pending') {
  throw Error('Refund failed with status: ${refund.status}');
}
```

---

## 📊 Firestore Updates

### 1. Booking Document
```typescript
bookings/{bookingId}:
  paymentStatus: "refunded"
  refundedAt: serverTimestamp()
  refundReason: "Customer complaint"
  refundedBy: adminUid
  refundId: "rfnd_razorpay123"
```

### 2. Technician Wallet Adjustment
```typescript
technicians/{technicianId}:
  walletBalance: currentBalance - bookingAmount
  totalEarnings: max(0, currentEarnings - bookingAmount)
```

**Important:** Prevents negative wallet balance

---

## 🔔 Notifications

### Customer Notification
```typescript
Title: "Refund Processed"
Body: "Your refund of ₹{amount} has been processed successfully."
Data: {
  bookingId,
  refundId,
  type: "refund_processed"
}
```

### Technician Notification
```typescript
Title: "Booking Payment Refunded"
Body: "₹{amount} has been deducted from your wallet due to refund."
Data: {
  bookingId,
  amount,
  type: "payment_refunded"
}
```

---

## 🛡️ Security Features

### 1. Admin-Only Access
- ✅ Only users in `/admins` collection can refund
- ✅ Prevents unauthorized refunds
- ✅ Complete audit trail

### 2. Duplicate Refund Protection
- ✅ Checks if already refunded
- ✅ Prevents double-refunding
- ✅ Idempotent operation

### 3. Wallet Balance Protection
- ✅ Validates sufficient balance before deduction
- ✅ Prevents negative wallet values
- ✅ Clear error messages

### 4. Transaction Validation
- ✅ Requires valid transaction ID
- ✅ Verifies Razorpay refund status
- ✅ Stores refund ID for tracking

---

## 📱 Admin Panel Integration

### Refund Button Implementation
```typescript
// Admin panel - Booking details page
async function handleRefund(bookingId: string) {
  const reason = await showRefundReasonDialog();
  
  if (!reason) return;
  
  try {
    const result = await FirebaseFunctions.instance
      .httpsCallable('refundBookingPayment')
      .call({
        bookingId,
        refundReason: reason,
      });
    
    showSuccessMessage('Refund processed successfully');
    refreshBookingDetails();
    
  } catch (error) {
    if (error.code === 'failed-precondition') {
      if (error.message.includes('Insufficient wallet')) {
        showErrorDialog(
          'Cannot Process Refund',
          'Technician has insufficient wallet balance. Please contact support.'
        );
      } else if (error.message.includes('already processed')) {
        showErrorDialog(
          'Refund Already Processed',
          'This booking has already been refunded.'
        );
      }
    }
  }
}
```

### Refund Reason Dialog
```typescript
async function showRefundReasonDialog(): Promise<string | null> {
  return new Promise((resolve) => {
    const dialog = document.createElement('dialog');
    dialog.innerHTML = `
      <h2>Refund Reason</h2>
      <select id="refundReason">
        <option value="">Select reason...</option>
        <option value="Service not satisfactory">Service not satisfactory</option>
        <option value="Technician did not show up">Technician did not show up</option>
        <option value="Customer complaint">Customer complaint</option>
        <option value="Duplicate payment">Duplicate payment</option>
        <option value="Other">Other</option>
      </select>
      <textarea id="customReason" placeholder="Additional details..."></textarea>
      <button id="confirm">Process Refund</button>
      <button id="cancel">Cancel</button>
    `;
    
    document.body.appendChild(dialog);
    dialog.showModal();
    
    dialog.querySelector('#confirm').addEventListener('click', () => {
      const reason = dialog.querySelector('#refundReason').value;
      const custom = dialog.querySelector('#customReason').value;
      resolve(custom || reason);
      dialog.close();
    });
    
    dialog.querySelector('#cancel').addEventListener('click', () => {
      resolve(null);
      dialog.close();
    });
  });
}
```

---

## 🧪 Testing Guide

### Test 1: Successful Refund
```typescript
// 1. Complete booking and payment
await completeBooking(bookingId);
await verifyBookingPayment({ bookingId, paymentId });

// 2. Process refund
const result = await refundBookingPayment({
  bookingId,
  refundReason: 'Customer complaint'
});

// 3. Verify updates
const booking = await getBooking(bookingId);
expect(booking.paymentStatus).toBe('refunded');
expect(booking.refundId).toBeDefined();

const technician = await getTechnician(technicianId);
expect(technician.walletBalance).toBe(previousBalance - bookingAmount);
```

### Test 2: Duplicate Refund Protection
```typescript
// 1. Process first refund
await refundBookingPayment({ bookingId, refundReason: 'Test' });

// 2. Try second refund
try {
  await refundBookingPayment({ bookingId, refundReason: 'Test 2' });
  fail('Should have thrown error');
} catch (e) {
  expect(e.code).toBe('failed-precondition');
  expect(e.message).toContain('already processed');
}
```

### Test 3: Insufficient Wallet Balance
```typescript
// Technician wallet: ₹100
// Booking amount: ₹500

try {
  await refundBookingPayment({ bookingId, refundReason: 'Test' });
  fail('Should have thrown error');
} catch (e) {
  expect(e.code).toBe('failed-precondition');
  expect(e.message).toContain('Insufficient wallet balance');
}
```

### Test 4: Unauthorized Access
```typescript
// Non-admin user tries to refund
try {
  await refundBookingPayment({ bookingId, refundReason: 'Test' });
  fail('Should have thrown error');
} catch (e) {
  expect(e.code).toBe('permission-denied');
  expect(e.message).toContain('Only admins');
}
```

### Test 5: Invalid Payment Status
```typescript
// Booking payment status: 'pending'

try {
  await refundBookingPayment({ bookingId, refundReason: 'Test' });
  fail('Should have thrown error');
} catch (e) {
  expect(e.code).toBe('failed-precondition');
  expect(e.message).toContain('Cannot refund booking');
}
```

---

## 🚀 Deployment

### Deploy Function
```powershell
cd C:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions:refundBookingPayment
```

### Verify Deployment
```powershell
firebase functions:list | findstr "refund"
```

---

## 📊 Database Schema

### Booking Document (Updated)
```typescript
{
  // Existing fields...
  paymentStatus: 'pending' | 'pending_customer_payment' | 'paid' | 'refunded';
  
  // Payment fields
  paidAt?: Timestamp;
  transactionId?: string;
  paymentMethod?: string;
  
  // Refund fields
  refundedAt?: Timestamp;
  refundReason?: string;
  refundedBy?: string;
  refundId?: string;
}
```

---

## 🔄 Refund Flow Diagram

```
Admin Reviews Complaint
         ↓
Admin Initiates Refund
         ↓
Call refundBookingPayment()
         ↓
Validate:
  - Admin permission ✓
  - Payment status = 'paid' ✓
  - Not already refunded ✓
  - Transaction ID exists ✓
         ↓
Process Razorpay Refund
         ↓
Verify Refund Status
         ↓
Check Technician Wallet Balance
         ↓
Update Firestore:
  - booking.paymentStatus = 'refunded'
  - technician.walletBalance -= amount
         ↓
Send Notifications
         ↓
Return Success
```

---

## ⚠️ Error Handling

### Common Errors

**1. Insufficient Wallet Balance**
```
Code: failed-precondition
Message: "Insufficient wallet balance. Current: ₹100, Required: ₹500"
Action: Contact technician or adjust manually
```

**2. Already Refunded**
```
Code: failed-precondition
Message: "Refund already processed for this booking"
Action: Check refund history
```

**3. Invalid Payment Status**
```
Code: failed-precondition
Message: "Cannot refund booking with payment status: pending"
Action: Verify booking is paid
```

**4. Unauthorized Access**
```
Code: permission-denied
Message: "Only admins can process refunds"
Action: Verify admin credentials
```

**5. Razorpay Refund Failed**
```
Code: internal
Message: "Refund failed with status: failed"
Action: Check Razorpay dashboard, retry
```

---

## 🎯 Use Cases

### 1. Service Not Satisfactory
- Customer complains about poor service
- Admin reviews complaint
- Admin processes refund with reason
- Customer receives money back
- Technician wallet adjusted

### 2. Technician No-Show
- Technician doesn't arrive
- Customer reports issue
- Admin verifies and refunds
- Technician penalized

### 3. Duplicate Payment
- Customer accidentally pays twice
- Admin identifies duplicate
- Admin refunds extra payment
- One payment remains valid

### 4. Cancellation After Payment
- Booking cancelled after payment
- Admin processes refund
- Both parties notified

---

## 📝 Best Practices

1. **Always provide clear refund reason** - Helps with analytics and dispute resolution
2. **Verify complaint before refunding** - Prevent abuse
3. **Check wallet balance first** - Avoid failed refunds
4. **Document refund decisions** - Maintain audit trail
5. **Monitor refund patterns** - Identify problematic technicians

---

## 🔗 Related Documentation

- [Payment Verification System](PAYMENT_VERIFICATION_SYSTEM.md)
- [Booking Lifecycle Functions](BOOKING_LIFECYCLE_FUNCTIONS.md)
- [Firestore Security Rules](FIRESTORE_SECURITY_RULES.md)

---

**Implementation Date:** 2026-01-XX
**Status:** ✅ Complete and Ready for Deployment
**Payment Gateway:** Razorpay
**Security Level:** High
