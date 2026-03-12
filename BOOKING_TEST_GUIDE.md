# Quick Test Guide - Booking Transaction Fix

## 🚀 Quick Start

### 1. Verify Deployment
```bash
firebase functions:log --only createBookingRequest --limit 5
```

### 2. Test Booking Creation

#### Test Case 1: Pay After Work (No Wallet Deduction)
```dart
// In customer app
await bookingProvider.createBooking(
  serviceId: 'service_123',
  technicianId: 'tech_456',
  paymentMode: 'after_work',
  // ... other fields
);
```

**Expected:**
- ✅ Booking created with status: `pending_admin_review`
- ✅ No wallet deduction
- ✅ No Firestore transaction errors

#### Test Case 2: Pay Before Work (Wallet Deduction)
```dart
// In customer app
await bookingProvider.createBooking(
  serviceId: 'service_123',
  technicianId: 'tech_456',
  paymentMode: 'before_work',
  // ... other fields
);
```

**Expected:**
- ✅ Booking created with status: `pending_admin_review`
- ✅ Wallet balance deducted by booking price
- ✅ Wallet transaction created with type: `booking_escrow`
- ✅ No Firestore transaction errors

#### Test Case 3: Insufficient Balance
```dart
// Set wallet balance to ₹10
// Try to book service for ₹500
await bookingProvider.createBooking(
  serviceId: 'service_123',
  technicianId: 'tech_456',
  paymentMode: 'before_work',
  price: 500,
);
```

**Expected:**
- ❌ Error: `INSUFFICIENT_WALLET_BALANCE`
- ✅ No booking created
- ✅ Wallet balance unchanged

#### Test Case 4: Idempotency Check
```dart
// Create booking with idempotency key
final result1 = await bookingProvider.createBooking(
  idempotencyKey: 'unique_key_123',
  // ... other fields
);

// Try again with same key
final result2 = await bookingProvider.createBooking(
  idempotencyKey: 'unique_key_123',
  // ... other fields
);
```

**Expected:**
- ✅ First call creates booking
- ✅ Second call returns existing booking
- ✅ Only one booking created in Firestore

## 🔍 Monitoring

### Check Firebase Console Logs
1. Go to: https://console.firebase.google.com/project/homefix-aa42d/functions/logs
2. Filter by: `createBookingRequest`
3. Look for:
   - ✅ `[createBookingRequest] Created booking {id} with status: pending_admin`
   - ✅ `[createBookingRequest] Price validation passed`
   - ✅ `[createBookingRequest] Rate limit check passed`
   - ❌ No "Firestore transaction" errors

### Check Firestore Collections

#### bookings/{bookingId}
```json
{
  "status": "pending_admin_review",
  "paymentStatus": "paid_escrow" | "pending",
  "paymentMode": "before_work" | "after_work",
  "price": 500,
  "finalAmount": 500,
  "createdAt": "2025-01-XX...",
  "customerId": "...",
  "technicianId": "..."
}
```

#### wallets/{customerId}
```json
{
  "balance": 450, // Reduced by booking price
  "updatedAt": "2025-01-XX..."
}
```

#### walletTransactions/{txnId}
```json
{
  "type": "booking_escrow",
  "amount": -500,
  "bookingId": "...",
  "userId": "...",
  "description": "Escrow deduction for booking ...",
  "createdAt": "2025-01-XX..."
}
```

## ⚠️ Common Issues

### Issue: "Firestore transactions require all reads before writes"
**Status:** ✅ FIXED
**Solution:** Transaction restructured with all reads before writes

### Issue: "INSUFFICIENT_WALLET_BALANCE"
**Status:** ✅ Expected behavior
**Solution:** Add funds to wallet or use 'after_work' payment mode

### Issue: Rate limit exceeded
**Status:** ✅ Expected behavior (50/hour in dev, 10/hour in prod)
**Solution:** Wait 1 hour or test with different customer account

## 📊 Success Metrics

After testing, verify:
- [ ] No Firestore transaction errors in logs
- [ ] Bookings created successfully
- [ ] Wallet deductions accurate
- [ ] Idempotency working correctly
- [ ] Rate limiting functioning
- [ ] Price validation enforced (±₹1 tolerance)
- [ ] Admin notifications sent
- [ ] Technician notifications sent

## 🎯 Next Steps

Once all tests pass:
1. Test complete booking flow (admin approval → technician accept → payment → completion)
2. Test cancellation and refund scenarios
3. Monitor production logs for 24 hours
4. Update README with new booking flow documentation

---

**Status:** ✅ Ready for Testing
**Last Updated:** 2025-01-XX
