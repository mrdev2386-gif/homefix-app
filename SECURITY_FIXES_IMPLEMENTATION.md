# 🔧 Security Fixes - Corrected Code Implementations

## CRITICAL FIX #1: Admin Authorization in Service Management

**File:** `functions/src/admin/service_management.ts`

Replace the entire file with this secured version:

```typescript
/**
 * Admin Service Management - SECURITY HARDENED
 * 
 * CRITICAL FIXES:
 * - ✅ Admin authorization enforced on ALL functions
 * - ✅ Firestore-based admin verification
 * - ✅ Audit logging for all actions
 */

import { onCall } from "firebase-functions/v2/https";
import { CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as https from "firebase-functions/v2/https";

const db = admin.firestore();

/**
 * SECURITY: Verify admin role from Firestore
 */
async function verifyAdmin(uid: string): Promise<void> {
  const adminDoc = await db.collection('admins').doc(uid).get();
  if (!adminDoc.exists) {
    throw new https.HttpsError("permission-denied", "Admin access required");
  }
}

/**
 * Log admin action for audit trail
 */
async function logAdminAction(
  adminId: string,
  action: string,
  serviceId: string,
  additionalData?: any
) {
  try {
    await db.collection('admin_logs').add({
      adminId,
      action,
      serviceId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      ...additionalData
    });
    console.log(`[ADMIN_AUDIT] ${action} by ${adminId} on service ${serviceId}`);
  } catch (error) {
    console.error('[ADMIN_AUDIT] Failed to log action:', error);
  }
}

/**
 * Approve Technician Service - SECURED
 */
export const admin_approveService = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 30 },
  async (request: CallableRequest<{ serviceId: string }>) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    // CRITICAL FIX: Verify admin role
    await verifyAdmin(request.auth.uid);

    const { serviceId } = request.data;
    if (!serviceId) {
      throw new https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
    }

    await serviceRef.update({
      status: 'approved',
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      approvedBy: request.auth.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await logAdminAction(request.auth.uid, 'approve_service', serviceId, {
      previousStatus: serviceDoc.data()?.status,
      newStatus: 'approved'
    });

    console.log(`[ADMIN] Service ${serviceId} approved by ${request.auth.uid}`);

    return {
      success: true,
      serviceId,
      status: 'approved',
      message: 'Service approved successfully'
    };
  }
);

/**
 * Reject Technician Service - SECURED
 */
export const admin_rejectService = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 30 },
  async (request: CallableRequest<{ serviceId: string; reason?: string }>) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    // CRITICAL FIX: Verify admin role
    await verifyAdmin(request.auth.uid);

    const { serviceId, reason } = request.data;
    if (!serviceId) {
      throw new https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
    }

    await serviceRef.update({
      status: 'rejected',
      rejectionReason: reason || 'Not specified',
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      rejectedBy: request.auth.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await logAdminAction(request.auth.uid, 'reject_service', serviceId, {
      previousStatus: serviceDoc.data()?.status,
      newStatus: 'rejected',
      reason: reason || 'Not specified'
    });

    console.log(`[ADMIN] Service ${serviceId} rejected by ${request.auth.uid}`);

    return {
      success: true,
      serviceId,
      status: 'rejected',
      message: 'Service rejected'
    };
  }
);

/**
 * Disable Technician Service - SECURED
 */
export const admin_disableService = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 30 },
  async (request: CallableRequest<{ serviceId: string }>) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    // CRITICAL FIX: Verify admin role
    await verifyAdmin(request.auth.uid);

    const { serviceId } = request.data;
    if (!serviceId) {
      throw new https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
    }

    await serviceRef.update({
      status: 'disabled',
      disabledAt: admin.firestore.FieldValue.serverTimestamp(),
      disabledBy: request.auth.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await logAdminAction(request.auth.uid, 'disable_service', serviceId, {
      previousStatus: serviceDoc.data()?.status,
      newStatus: 'disabled'
    });

    console.log(`[ADMIN] Service ${serviceId} disabled by ${request.auth.uid}`);

    return {
      success: true,
      serviceId,
      status: 'disabled',
      message: 'Service disabled'
    };
  }
);
```

---

## CRITICAL FIX #2: Payment Verification with Transaction

**File:** `functions/src/booking/booking_lifecycle.ts`

Replace the `verifyBookingPayment` function:

```typescript
/**
 * Verify Booking Payment - RACE CONDITION FIXED
 * Uses transaction to prevent double payment
 */
export const verifyBookingPayment = functions.https.onCall(async (request) => {
  const { bookingId, paymentId, paymentGatewayResponse } = request.data;
  const uid = request.auth?.uid;

  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');
  if (!paymentId) throw new functions.https.HttpsError('invalid-argument', 'paymentId required');

  const bookingRef = db.collection('bookings').doc(bookingId);

  try {
    // CRITICAL FIX: Use transaction for atomic payment verification
    const result = await db.runTransaction(async (transaction) => {
      const bookingSnap = await transaction.get(bookingRef);

      if (!bookingSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
      }

      const booking = bookingSnap.data()!;

      // Verify customer owns booking
      if (booking.customerId !== uid) {
        throw new functions.https.HttpsError('permission-denied', 'Only booking customer can make payment');
      }

      // Validate booking status
      if (booking.status !== 'completed') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Payment can only be made for completed bookings'
        );
      }

      // CRITICAL: Duplicate payment protection INSIDE transaction
      if (booking.paymentStatus === 'paid') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Payment already completed for this booking'
        );
      }

      // Validate payment status
      if (booking.paymentStatus !== 'pending_customer_payment') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          `Invalid payment status: ${booking.paymentStatus}`
        );
      }

      // Verify payment with Razorpay (outside transaction for API call)
      // This is safe because we check payment status inside transaction
      return { booking, bookingRef };
    });

    // Verify payment with Razorpay
    const crypto = await import('crypto');
    const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET || '';

    // Verify signature if provided
    if (paymentGatewayResponse?.razorpay_signature) {
      const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = paymentGatewayResponse;
      
      const generatedSignature = crypto
        .createHmac('sha256', razorpayKeySecret)
        .update(`${razorpay_order_id}|${razorpay_payment_id}`)
        .digest('hex');

      if (generatedSignature !== razorpay_signature) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid payment signature');
      }
    }

    // Fetch payment details from Razorpay
    const Razorpay = (await import('razorpay')).default;
    const razorpay = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID || '',
      key_secret: razorpayKeySecret,
    });

    const payment = await razorpay.payments.fetch(paymentId);

    // Verify payment status
    if (payment.status !== 'captured' && payment.status !== 'authorized') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Payment not successful. Status: ${payment.status}`
      );
    }

    // Verify payment amount matches booking
    const paymentAmount = Number(payment.amount) / 100;
    if (Math.abs(paymentAmount - result.booking.price) > 0.01) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Payment amount mismatch. Expected: ${result.booking.price}, Received: ${paymentAmount}`
      );
    }

    // CRITICAL FIX: Update booking and technician wallet atomically
    await db.runTransaction(async (transaction) => {
      // Re-check payment status to prevent race condition
      const bookingSnap = await transaction.get(bookingRef);
      const booking = bookingSnap.data()!;

      if (booking.paymentStatus === 'paid') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Payment already completed'
        );
      }

      // Update booking payment status
      transaction.update(bookingRef, {
        paymentStatus: 'paid',
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        transactionId: paymentId,
        paymentMethod: payment.method || 'razorpay',
      });

      // Update technician earnings atomically
      const techRef = db.collection('technicians').doc(booking.technicianId);
      transaction.update(techRef, {
        walletBalance: admin.firestore.FieldValue.increment(booking.price),
        totalEarnings: admin.firestore.FieldValue.increment(booking.price),
      });
    });

    // Send notifications (outside transaction)
    const customerDoc = await db.collection('customers').doc(result.booking.customerId).get();
    const customerData = customerDoc.data();

    if (customerData?.fcmToken) {
      await sendNotificationToToken({
        token: customerData.fcmToken,
        title: 'Payment Successful',
        body: `Your payment of ₹${result.booking.price} has been processed successfully.`,
        data: { bookingId, paymentId, type: 'payment_success' },
      });
    }

    const techDoc = await db.collection('technicians').doc(result.booking.technicianId).get();
    const techData = techDoc.data();

    if (techData?.fcmToken) {
      await sendNotificationToToken({
        token: techData.fcmToken,
        title: 'Payment Received',
        body: `You received ₹${result.booking.price} for completed service.`,
        data: { bookingId, amount: result.booking.price, type: 'payment_received' },
      });
    }

    return {
      success: true,
      paymentStatus: 'paid',
      amount: result.booking.price,
      transactionId: paymentId,
    };
  } catch (error: any) {
    console.error('Payment verification error:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      `Payment verification failed: ${error.message}`
    );
  }
});
```

---

## CRITICAL FIX #3: Encrypt Aadhaar Numbers

**File:** `functions/src/technician/onboarding.ts`

Update the `saveTechnicianDocuments` function:

```typescript
import { encrypt } from '../shared/security'; // Add this import

/**
 * Save documents/KYC during onboarding - AADHAAR ENCRYPTED
 */
export const saveTechnicianDocuments = functions.https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;
    const {
        aadhaarNumber,
        aadhaarFrontUrl,
        aadhaarBackUrl,
        profilePhotoUrl,
        documentType
    } = data;

    // Validate required fields
    if (!aadhaarNumber || aadhaarNumber.length !== 12) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Valid 12-digit Aadhaar number is required'
        );
    }

    if (!aadhaarFrontUrl || !profilePhotoUrl) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Document images and profile photo are required'
        );
    }

    // Get current technician to verify onboarding state
    const techDoc = await db.collection('technicians').doc(uid).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError(
            'not-found',
            'Technician profile not found'
        );
    }

    const techData = techDoc.data();
    const currentStep = techData?.onboardingStep;

    // Allow if in documents step or earlier
    if (currentStep && currentStep !== 'documents' && currentStep !== 'basicDetails') {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Cannot modify documents at this stage'
        );
    }

    // CRITICAL FIX: Encrypt Aadhaar before storing
    const encryptedAadhaar = encrypt(aadhaarNumber);
    
    // Mask Aadhaar for display (store last 4 digits)
    const maskedAadhaar = `XXXX-XXXX-${aadhaarNumber.substring(8)}`;

    // Update technician profile with documents
    await db.collection('technicians').doc(uid).update({
        aadhaarNumber: encryptedAadhaar, // ENCRYPTED
        aadhaarMasked: maskedAadhaar,
        aadhaarFrontUrl: aadhaarFrontUrl,
        aadhaarBackUrl: aadhaarBackUrl || '',
        profilePhotoUrl: profilePhotoUrl,
        documentType: documentType || 'Aadhaar Card',
        onboardingStep: 'services',
        'stepsCompleted.kyc': true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`[SECURITY] Aadhaar encrypted and stored for technician ${uid}`);

    return {
        success: true,
        nextStep: 'services'
    };
});
```

---

## ADDITIONAL FIX: Input Sanitization Helper

**File:** `functions/src/shared/security.ts`

Add these sanitization functions:

```typescript
/**
 * Sanitize string input to prevent XSS
 */
export function sanitizeString(input: string, maxLength: number = 500): string {
  if (!input) return '';
  
  return input
    .trim()
    .replace(/[<>]/g, '') // Remove HTML tags
    .replace(/[^\w\s\-.,!?@#$%&*()]/g, '') // Remove special chars except common punctuation
    .substring(0, maxLength);
}

/**
 * Sanitize Aadhaar number (digits only)
 */
export function sanitizeAadhaar(aadhaar: string): string {
  if (!aadhaar) return '';
  return aadhaar.replace(/[^0-9]/g, '').substring(0, 12);
}

/**
 * Sanitize email
 */
export function sanitizeEmail(email: string): string {
  if (!email) return '';
  return email.trim().toLowerCase().substring(0, 100);
}

/**
 * Sanitize phone number (digits only)
 */
export function sanitizePhone(phone: string): string {
  if (!phone) return '';
  return phone.replace(/[^0-9+]/g, '').substring(0, 15);
}
```

Then use in onboarding functions:

```typescript
import { sanitizeString, sanitizeAadhaar, sanitizeEmail } from '../shared/security';

// In saveTechnicianBasicDetails:
const sanitizedFullName = sanitizeString(fullName, 100);
const sanitizedEmail = sanitizeEmail(email || '');
const sanitizedDistrict = sanitizeString(district || '', 50);

// In saveTechnicianDocuments:
const sanitizedAadhaar = sanitizeAadhaar(aadhaarNumber);
if (sanitizedAadhaar.length !== 12) {
  throw new functions.https.HttpsError('invalid-argument', 'Invalid Aadhaar format');
}
```

---

## DEPLOYMENT CHECKLIST

After applying these fixes:

1. ✅ Test admin authorization
   ```bash
   # Try to approve service as non-admin (should fail)
   # Try to approve service as admin (should succeed)
   ```

2. ✅ Test payment verification
   ```bash
   # Try to pay for same booking twice (should fail on second attempt)
   ```

3. ✅ Test Aadhaar encryption
   ```bash
   # Check Firestore - aadhaarNumber should be encrypted string
   # Verify decryption works when needed
   ```

4. ✅ Deploy to Firebase
   ```bash
   cd functions
   npm run build
   firebase deploy --only functions
   ```

5. ✅ Monitor logs
   ```bash
   firebase functions:log
   ```

---

## TESTING COMMANDS

```bash
# Test admin authorization
curl -X POST https://us-central1-YOUR-PROJECT.cloudfunctions.net/admin_approveService \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"serviceId": "test123"}'

# Should return 403 if not admin
# Should return 200 if admin

# Test payment verification race condition
# Run two simultaneous payment verifications
# Only one should succeed
```

---

## SECURITY VERIFICATION

After deployment, verify:

1. ✅ Admin functions reject non-admin users
2. ✅ Payment verification prevents double payment
3. ✅ Aadhaar numbers are encrypted in Firestore
4. ✅ Input sanitization prevents XSS
5. ✅ All audit logs are created

---

**CRITICAL:** Test all fixes in development environment before deploying to production!
