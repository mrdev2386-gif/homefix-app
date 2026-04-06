# Wallet System - Remaining Work

## ✅ COMPLETED

- [x] Fixed wallet "Add Bank" data fetching issue
- [x] Unified bank verification flow (Profile + Wallet use same screen)
- [x] Single source of truth established (`technicians` document)
- [x] Correct status parsing with `bankVerified` flag

---

## 🔄 REMAINING WORK

### 1. QR Payment System (HIGH PRIORITY)

**Current State**: QR button exists but shows placeholder

**Required Implementation**:

#### Backend Function: `generateBookingQR`
```typescript
// functions/src/finance/qr_payment.ts
export const generateBookingQR = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    // 1. Validate technician authentication
    // 2. Get technician details
    // 3. Create Razorpay QR code
    const qrCode = await razorpay.qrCodes.create({
      type: 'upi_qr',
      name: `Technician_${technicianId}`,
      usage: 'multiple_use',  // Can be reused
      fixed_amount: false,     // Dynamic amount
      customer_id: razorpayContactId,
      notes: {
        technicianId,
        type: 'service_payment'
      }
    });
    
    // 4. Return QR image and ID
    return {
      success: true,
      qrImageUrl: qrCode.image_url,
      qrId: qrCode.id,
      qrString: qrCode.qr_string
    };
  });
```

#### Payment Webhook Handler
```typescript
// functions/src/payments/qr_webhook.ts
export const razorpayQRWebhook = functions.https.onRequest(async (req, res) => {
  // 1. Verify webhook signature
  // 2. Extract payment details
  // 3. Calculate platform fee (10%)
  const platformFee = amount * 0.10;
  const technicianAmount = amount - platformFee;
  
  // 4. Update technician wallet
  await db.collection('technician_wallets').doc(technicianId).update({
    availableBalance: admin.firestore.FieldValue.increment(technicianAmount),
    lifetimeEarnings: admin.firestore.FieldValue.increment(technicianAmount)
  });
  
  // 5. Create transaction record
  await db.collection('technician_wallets')
    .doc(technicianId)
    .collection('transactions')
    .add({
      type: 'credit',
      source: 'qr_payment',
      amount: technicianAmount,
      platformFee: platformFee,
      grossAmount: amount,
      status: 'completed',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  
  // 6. Send notification
  res.status(200).send('OK');
});
```

#### Frontend Update
```dart
// apps/technician_app/lib/screens/wallet_screen.dart
void _showReceiveQRSheet() async {
  try {
    // Call backend to generate QR
    final result = await _walletService.generateTechnicianQR();
    
    if (result.success) {
      // Show QR code image
      showModalBottomSheet(
        context: context,
        builder: (context) => QRCodeSheet(
          qrImageUrl: result.qrImageUrl,
          technicianName: tech.fullName,
        ),
      );
    }
  } catch (e) {
    // Show error
  }
}
```

---

### 2. Platform Fee Calculation (HIGH PRIORITY)

**Required**:
- All QR payments must deduct 10% platform fee
- Transaction records must show:
  - Gross amount (what customer paid)
  - Platform fee (10%)
  - Net amount (what technician receives)

**Example**:
```
Customer pays: ₹1000
Platform fee: ₹100 (10%)
Technician gets: ₹900
```

---

### 3. Wallet Transaction Display (MEDIUM PRIORITY)

**Current State**: Transactions show but may not display platform fees

**Required**:
- Show platform fee in transaction details
- Add filter for QR payments
- Show gross vs net amounts clearly

---

### 4. Cleanup (LOW PRIORITY)

**Files to Review**:
- `apps/technician_app/lib/screens/add_bank_account_screen.dart` - May be unused now
- `technician_bank_accounts` collection - May have orphaned data

**Actions**:
- Verify if `AddBankAccountScreen` is used elsewhere
- If not, delete it
- Clean up any references to `technician_bank_accounts` collection

---

### 5. Security Considerations

**QR Payment Security**:
- ✅ Payments go to platform account (not directly to technician)
- ✅ Webhook signature verification required
- ✅ Platform fee deducted server-side (not client-side)
- ✅ Transaction records immutable
- ⚠️ Need to prevent duplicate payment processing (idempotency)

**Idempotency Pattern**:
```typescript
// Check if payment already processed
const existingTxn = await db.collection('payment_logs')
  .where('razorpayPaymentId', '==', paymentId)
  .limit(1)
  .get();

if (!existingTxn.empty) {
  console.log('Payment already processed');
  return res.status(200).send('OK');
}
```

---

## Priority Order

1. **CRITICAL**: QR Payment Backend (`generateBookingQR` + webhook)
2. **HIGH**: Platform Fee Calculation
3. **MEDIUM**: Transaction Display Updates
4. **LOW**: Code Cleanup

---

## Estimated Effort

- QR Payment System: 4-6 hours
- Platform Fee Logic: 2 hours
- Transaction Display: 2 hours
- Cleanup: 1 hour

**Total**: ~10 hours of development

---

## Next Steps

1. Create spec for QR Payment System
2. Implement `generateBookingQR` function
3. Implement QR webhook handler
4. Update frontend to call backend
5. Test end-to-end flow
6. Deploy and monitor

---

## Questions to Answer

1. Should QR codes be:
   - Per-technician (reusable)?
   - Per-booking (single-use)?
   - **Recommendation**: Per-technician, reusable

2. Should platform fee be:
   - Fixed 10%?
   - Configurable per service?
   - **Recommendation**: Fixed 10% for now

3. Should payments be:
   - Instant to wallet?
   - Held for 24-48 hours?
   - **Recommendation**: Instant (already verified technician)

---

**Document Created**: December 2024  
**Status**: Planning Phase  
**Next Action**: Create QR Payment Spec
