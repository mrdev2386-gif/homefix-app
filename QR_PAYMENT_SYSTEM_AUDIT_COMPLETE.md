# QR Payment System - Complete Audit & Implementation Plan

## Executive Summary

**Status**: System is 80% complete but has critical gaps in QR payment flow
**Priority**: HIGH - QR payments currently don't work end-to-end
**Risk**: Medium - Existing withdrawal and webhook systems are solid

---

## Current System Analysis

### ✅ What's Working (Already Implemented)

#### 1. Bank Verification System
- **Status**: COMPLETE ✅
- **Location**: `functions/src/finance/technician_withdrawal.ts`
- **Features**:
  - Single source of truth: `technicians/{uid}` document
  - Razorpay contact + fund account creation
  - Bank verification status tracking
  - Wallet and Profile screens unified

#### 2. Withdrawal System
- **Status**: COMPLETE ✅
- **Location**: `functions/src/finance/technician_withdrawal.ts`
- **Features**:
  - Automatic Razorpay payout (no admin approval)
  - Idempotency protection
  - Rate limiting (3 withdrawals/day, 6h cooldown)
  - Atomic balance deduction
  - ₹10 platform fee
  - Min: ₹100, Max: ₹50,000

#### 3. Razorpay Webhook Handler
- **Status**: COMPLETE ✅
- **Location**: `functions/src/payments/razorpayWebhookV2.ts`
- **Features**:
  - Signature verification
  - Idempotency protection
  - Replay attack prevention (24h window)
  - Amount validation
  - Atomic wallet updates
  - Handles booking payments + wallet credits

#### 4. Frontend Wallet Screen
- **Status**: COMPLETE ✅
- **Location**: `apps/technician_app/lib/screens/wallet_screen.dart`
- **Features**:
  - Real-time balance display
  - Bank account status
  - Transaction history
  - Withdrawal flow
  - QR card UI (placeholder)

---

## ❌ Critical Gaps (What's Missing)

### 1. QR Payment Generation - INCOMPLETE

**Current State**:
- `generateBookingQR` exists but only for booking-specific QR codes
- `generateTechnicianQR` creates UPI string but NOT Razorpay QR
- Frontend `_showReceiveQRSheet()` shows placeholder QR, doesn't call backend

**Problem**:
```dart
// wallet_screen.dart line ~1200
void _showReceiveQRSheet() {
  // Shows static placeholder QR
  // Does NOT call backend function
  // Does NOT generate real Razorpay QR code
}
```

**What's Needed**:
- New Cloud Function: `generateTechnicianWalletQR`
- Frontend integration to call this function
- Display real Razorpay QR image
- Handle QR expiration (30 min)

---

### 2. QR Payment Webhook - MISSING

**Current State**:
- Webhook handles `payment.captured` events
- BUT: Only processes payments linked to `razorpayOrders` collection
- QR payments don't create orders first - they're direct payments

**Problem**:
```typescript
// razorpayWebhookV2.ts
// Webhook expects orderId from payment.order_id
// QR payments might not have order_id or use different flow
```

**What's Needed**:
- Detect QR payments in webhook (check `payment.notes` for QR metadata)
- Extract technician ID from QR payment notes
- Calculate 10% platform fee
- Credit 90% to technician wallet
- Create transaction record

---

### 3. Platform Fee Logic - MISSING FOR QR

**Current State**:
- Booking payments: 15% commission (`creditTechnicianWalletV2`)
- Withdrawal: ₹10 flat fee
- QR payments: NO FEE LOGIC

**What's Needed**:
```typescript
// For QR payments to technician wallet
const platformFeePercent = 0.10; // 10%
const platformFee = totalAmount * platformFeePercent;
const technicianAmount = totalAmount - platformFee;

// Credit technician with 90%
// Platform keeps 10%
```

---

## Implementation Plan

### Phase 1: Backend QR Generation Function

**File**: `functions/src/finance/technician_withdrawal.ts`

**Add New Function**:
```typescript
export const generateTechnicianWalletQR = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }

    const technicianId = context.auth.uid;
    
    // Verify technician exists
    const techDoc = await db.collection('technicians').doc(technicianId).get();
    if (!techDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Technician not found');
    }

    const techData = techDoc.data()!;
    
    // Check for existing active QR
    const existingQR = await db.collection('technician_qr_codes')
      .where('technicianId', '==', technicianId)
      .where('status', '==', 'active')
      .where('expiresAt', '>', admin.firestore.Timestamp.now())
      .limit(1)
      .get();

    if (!existingQR.empty) {
      const qrData = existingQR.docs[0].data();
      return {
        success: true,
        qrImageUrl: qrData.qrImageUrl,
        qrId: qrData.qrId,
        expiresAt: qrData.expiresAt.toDate().toISOString()
      };
    }

    // Create new Razorpay QR code
    const rzp = getRazorpayInstance();
    
    const qrCode = await (rzp as any).qrCodes.create({
      type: 'upi_qr',
      name: `${techData.name || 'Technician'}_Wallet`,
      usage: 'multiple_use', // Can be used multiple times
      fixed_amount: false, // Customer enters amount
      description: 'Payment to technician wallet',
      notes: {
        technicianId,
        technicianName: techData.name,
        paymentType: 'wallet_credit',
        platformFee: '10%'
      }
    });

    const expiresAt = new Date(Date.now() + 30 * 60 * 1000); // 30 min

    // Store QR metadata
    await db.collection('technician_qr_codes').add({
      qrId: qrCode.id,
      technicianId,
      qrImageUrl: qrCode.image_url,
      status: 'active',
      paymentType: 'wallet_credit',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt)
    });

    return {
      success: true,
      qrImageUrl: qrCode.image_url,
      qrId: qrCode.id,
      expiresAt: expiresAt.toISOString()
    };
  });
```

**Export in** `functions/src/index.ts`:
```typescript
export { generateTechnicianWalletQR } from './finance/technician_withdrawal';
```

---

### Phase 2: Webhook QR Payment Handler

**File**: `functions/src/payments/razorpayWebhookV2.ts`

**Modify** `handlePaymentCapturedV2`:
```typescript
async function handlePaymentCapturedV2(payload: any) {
  const payment = payload?.payment?.entity;
  const orderId = payment?.order_id;
  const paymentId = payment?.id;
  const razorpayAmount = (payment?.amount ?? 0) / 100;
  
  // NEW: Check if this is a QR payment (no order_id)
  if (!orderId && payment?.notes?.paymentType === 'wallet_credit') {
    await handleQRWalletPayment(payment, paymentId, razorpayAmount);
    return;
  }
  
  // Existing order-based payment logic...
}
```

**Add New Handler**:
```typescript
async function handleQRWalletPayment(
  payment: any,
  paymentId: string,
  totalAmount: number
) {
  const technicianId = payment.notes?.technicianId;
  
  if (!technicianId) {
    console.error(`${LOG_PREFIX} QR payment missing technicianId`);
    return;
  }

  console.log(`${LOG_PREFIX} qr_payment - Technician: ${technicianId}, Amount: ${totalAmount}`);

  // Idempotency check
  const idempotencyRef = db.collection('payment_idempotency').doc(paymentId);
  const existingPayment = await idempotencyRef.get();
  
  if (existingPayment.exists) {
    console.log(`${LOG_PREFIX} duplicate_ignored - QR payment already processed: ${paymentId}`);
    return;
  }

  // Calculate platform fee (10%)
  const platformFeePercent = 0.10;
  const platformFee = totalAmount * platformFeePercent;
  const technicianAmount = totalAmount - platformFee;

  // Verify technician exists
  const techDoc = await db.collection('technicians').doc(technicianId).get();
  if (!techDoc.exists) {
    console.error(`${LOG_PREFIX} technician_not_found - ID: ${technicianId}`);
    return;
  }

  // Atomic wallet credit with idempotency
  await db.runTransaction(async (transaction) => {
    // Mark payment as processed FIRST
    transaction.set(idempotencyRef, {
      paymentId,
      technicianId,
      totalAmount,
      platformFee,
      technicianAmount,
      processedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    const walletRef = db.collection('technician_wallets').doc(technicianId);
    const walletDoc = await transaction.get(walletRef);

    if (!walletDoc.exists) {
      transaction.set(walletRef, {
        availableBalance: technicianAmount,
        pendingBalance: 0,
        lifetimeEarnings: technicianAmount,
        lastPayoutAt: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } else {
      transaction.update(walletRef, {
        availableBalance: admin.firestore.FieldValue.increment(technicianAmount),
        lifetimeEarnings: admin.firestore.FieldValue.increment(technicianAmount),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // Create transaction record
    const txnRef = walletRef.collection('transactions').doc();
    transaction.set(txnRef, {
      type: 'credit',
      source: 'qr_payment',
      status: 'completed',
      amount: technicianAmount,
      fee: platformFee,
      grossAmount: totalAmount,
      referenceId: paymentId,
      paymentId,
      description: `QR payment received (10% platform fee deducted)`,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  });

  // Log platform fee collection
  await db.collection('platform_fees').add({
    paymentId,
    technicianId,
    source: 'qr_payment',
    totalAmount,
    feePercent: platformFeePercent,
    feeAmount: platformFee,
    technicianAmount,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Send notification
  await db.collection('notifications').add({
    userId: technicianId,
    title: 'Payment Received',
    body: `You received ₹${technicianAmount.toFixed(2)} via QR payment (₹${platformFee.toFixed(2)} platform fee).`,
    type: 'qr_payment_received',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  console.log(`${LOG_PREFIX} qr_credit_success - Technician: ${technicianId}, Net: ${technicianAmount}, Fee: ${platformFee}`);
}
```

---

### Phase 3: Frontend Integration

**File**: `apps/technician_app/lib/screens/wallet_screen.dart`

**Replace** `_showReceiveQRSheet()`:
```dart
void _showReceiveQRSheet() async {
  final tech = Provider.of<TechnicianProvider>(context, listen: false).technician;
  if (tech == null) return;

  // Show loading
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    builder: (context) => _buildQRLoadingSheet(),
  );

  try {
    // Call backend to generate QR
    final result = await _walletService.generateTechnicianWalletQR();
    
    // Close loading
    Navigator.pop(context);
    
    if (result.success && result.qrImageUrl != null) {
      // Show QR with real image
      _showQRCodeSheet(tech, result.qrImageUrl!, result.expiresAt);
    } else {
      throw Exception(result.error ?? 'Failed to generate QR');
    }
  } catch (e) {
    Navigator.pop(context); // Close loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to generate QR: $e'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}

Widget _buildQRLoadingSheet() {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    padding: const EdgeInsets.all(48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: AppTheme.primaryColor),
        const SizedBox(height: 24),
        Text(
          'Generating QR Code...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    ),
  );
}

void _showQRCodeSheet(
  TechnicianModel tech,
  String qrImageUrl,
  DateTime? expiresAt,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 56,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Name
          Text(
            tech.fullName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            'Scan to pay via Razorpay',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
          
          // REAL QR CODE IMAGE
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Image.network(
              qrImageUrl,
              width: 240,
              height: 240,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: 240,
                  height: 240,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Failed to load QR', style: TextStyle(color: Colors.red)),
                  ],
                );
              },
            ),
          ),
          
          // Expiry info
          if (expiresAt != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 16, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Text(
                    'Expires at ${DateFormat('h:mm a').format(expiresAt)}',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 28),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: qrImageUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('QR link copied')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: const Text('Copy Link'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.primaryColor),
                    foregroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Share QR image
                    Share.share('Pay me via Razorpay: $qrImageUrl');
                  },
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
```

**Add to** `wallet_service.dart`:
```dart
/// Generate QR code for receiving payments
Future<QRPaymentResult> generateTechnicianWalletQR() async {
  final technicianId = _technicianId;
  if (technicianId == null) {
    throw Exception('User not authenticated');
  }

  try {
    final callable = FirebaseFunctionsService.instance
        .httpsCallable('generateTechnicianWalletQR');
    
    final result = await callable.call({});
    
    return QRPaymentResult.fromMap(result.data);
  } catch (e) {
    throw WalletException('Failed to generate QR: $e');
  }
}
```

---

## Testing Checklist

### Backend Testing

1. **QR Generation**:
   ```bash
   # Test function
   firebase functions:shell
   > generateTechnicianWalletQR({}, {auth: {uid: 'test-tech-id'}})
   ```

2. **Webhook QR Payment**:
   - Use Razorpay test mode
   - Scan QR with test UPI
   - Verify webhook receives payment
   - Check 10% fee deduction
   - Verify wallet credit

3. **Idempotency**:
   - Send same webhook twice
   - Verify only one credit

### Frontend Testing

1. **QR Display**:
   - Click "Receive Payment"
   - Verify loading state
   - Verify QR image loads
   - Check expiry time display

2. **QR Refresh**:
   - Generate QR
   - Wait 30 min
   - Generate again
   - Verify new QR created

3. **Error Handling**:
   - Test with no internet
   - Test with invalid technician
   - Verify error messages

---

## Deployment Steps

### 1. Deploy Backend Functions
```bash
cd functions
npm run build
firebase deploy --only functions:generateTechnicianWalletQR
firebase deploy --only functions:razorpayWebhookV2
```

### 2. Configure Razorpay Webhook
- Go to Razorpay Dashboard → Webhooks
- Ensure webhook URL is set: `https://your-project.cloudfunctions.net/razorpayWebhookV2`
- Ensure events selected: `payment.captured`, `payment.failed`
- Verify webhook secret matches Firebase config

### 3. Test in Staging
- Use Razorpay test mode
- Test complete flow
- Verify logs in Firebase Console

### 4. Deploy Frontend
```bash
cd apps/technician_app
flutter build apk --release
# Or deploy to Play Store
```

### 5. Monitor Production
- Watch Firebase Functions logs
- Monitor `payment_logs` collection
- Check `platform_fees` collection
- Verify wallet balances

---

## Security Considerations

### ✅ Already Implemented
- Webhook signature verification
- Idempotency protection
- Replay attack prevention
- Amount validation
- Atomic transactions

### ⚠️ Additional Recommendations
1. **Rate Limiting**: Add rate limit on QR generation (max 10/hour per technician)
2. **QR Expiry**: Implement auto-cleanup of expired QRs
3. **Fraud Detection**: Monitor for suspicious payment patterns
4. **Audit Trail**: Log all QR generations and payments

---

## Cost Analysis

### Razorpay Fees
- QR Code: Free
- UPI Payment: 0% (free for UPI)
- Payout (withdrawal): ₹3-10 per transaction

### Platform Revenue (10% Fee)
- Customer pays: ₹1000
- Platform keeps: ₹100
- Technician gets: ₹900
- Technician withdraws: ₹900 - ₹10 = ₹890 to bank

---

## Next Steps

1. ✅ Review this document
2. ⬜ Implement Phase 1 (Backend QR generation)
3. ⬜ Implement Phase 2 (Webhook handler)
4. ⬜ Implement Phase 3 (Frontend integration)
5. ⬜ Test end-to-end in staging
6. ⬜ Deploy to production
7. ⬜ Monitor for 48 hours

---

## Support & Troubleshooting

### Common Issues

**QR not generating**:
- Check Razorpay API keys
- Verify technician exists
- Check Firebase Functions logs

**Webhook not triggering**:
- Verify webhook URL in Razorpay
- Check webhook secret
- Test with Razorpay webhook tester

**Wrong amount credited**:
- Check platform fee calculation
- Verify webhook payload
- Check `payment_logs` collection

---

**Document Version**: 1.0  
**Last Updated**: 2026-04-05  
**Author**: Kiro AI Assistant
