import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendNotificationToToken } from '../shared/notification_helper';
import { secureCallable } from '../shared/security';

const db = admin.firestore();

// ==========================================
// REFUND BOOKING PAYMENT
// FIX 4: Use functions.config() for Razorpay keys (consistent with all other payment functions)
// FIX 5: DEPRECATED - Use initiateRefund from razorpay.ts instead
// ==========================================

/**
 * @deprecated HARD DISABLED - Use initiateRefund from razorpay.ts instead
 * This function has been permanently disabled to prevent duplicate refund paths.
 * All refund requests MUST use the initiateRefund function from razorpay.ts.
 */
export const refundBookingPayment = functions
  .region('asia-south1')
  .https.onCall(secureCallable(async (data: any, context: any) => {
  // HARD DISABLED - Force migration to new refund system
  throw new functions.https.HttpsError(
    'failed-precondition',
    'DEPRECATED: This refund function is disabled. Use initiateRefund from razorpay.ts instead. Contact admin for migration.'
  );
}));

  // Verify admin
  const adminDoc = await db.collection('admins').doc(uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can process refunds');
  }

  // Get booking
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking not found');
  }

  const booking = bookingSnap.data()!;

  // Validate payment status
  if (booking.paymentStatus !== 'paid') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Cannot refund booking with payment status: ${booking.paymentStatus}`
    );
  }

  // FIX 6: Idempotency check - prevent duplicate refunds
  if (booking.paymentStatus === 'refunded' || booking.refund?.status === 'processed') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Refund already processed for this booking'
    );
  }

  // Validate transaction ID exists
  if (!booking.transactionId) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'No transaction ID found for this booking'
    );
  }

  // FIX 6: Mark refund as processing BEFORE calling Razorpay API
  await bookingRef.update({
    'refund.status': 'processing',
    'refund.requestedAt': admin.firestore.FieldValue.serverTimestamp(),
    'refund.requestedBy': uid,
    'refund.reason': refundReason
  });

  try {
    // FIX 4: Use functions.config() instead of process.env
    const config = functions.config();
    const razorpayKeyId = config.razorpay?.key_id || '';
    const razorpayKeySecret = config.razorpay?.key_secret || '';

    if (!razorpayKeyId || !razorpayKeySecret) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Razorpay configuration not found. Run: firebase functions:config:set razorpay.key_id="xxx" razorpay.key_secret="xxx"'
      );
    }

    // Process refund with Razorpay
    const Razorpay = (await import('razorpay')).default;
    const razorpay = new Razorpay({
      key_id: razorpayKeyId,
      key_secret: razorpayKeySecret,
    });

    const refundAmount = booking.price * 100;

    const refund = await razorpay.payments.refund(booking.transactionId, {
      amount: refundAmount,
      notes: { bookingId, reason: refundReason },
    });

    if (refund.status !== 'processed' && refund.status !== 'pending') {
      throw new functions.https.HttpsError('internal', `Refund failed with status: ${refund.status}`);
    }

    // Update booking
    await bookingRef.update({
      paymentStatus: 'refunded',
      'refund.status': 'processed',
      'refund.processedAt': admin.firestore.FieldValue.serverTimestamp(),
      'refund.refundId': refund.id,
      refundedAt: admin.firestore.FieldValue.serverTimestamp(),
      refundReason,
      refundedBy: uid,
      refundId: refund.id,
    });

    // FIX 3A: Update technician wallet using technician_wallets (single source of truth)
    const walletRef = db.collection('technician_wallets').doc(booking.technicianId);
    const walletSnap = await walletRef.get();

    if (walletSnap.exists) {
      const walletData = walletSnap.data()!;
      const currentBalance = walletData.availableBalance || 0;
      const newBalance = currentBalance - booking.price;

      if (newBalance < 0) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          `Insufficient wallet balance. Current: ₹${currentBalance}, Required: ₹${booking.price}`
        );
      }

      await walletRef.update({
        availableBalance: newBalance,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // Log transaction
      await walletRef.collection('transactions').add({
        type: 'debit',
        source: 'refund',
        status: 'completed',
        amount: booking.price,
        fee: 0,
        referenceId: bookingId,
        description: `Refund for booking`,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // Notify customer
    const customerDoc = await db.collection('customers').doc(booking.customerId).get();
    const customerData = customerDoc.data();

    if (customerData?.fcmToken) {
      await sendNotificationToToken({
        token: customerData.fcmToken,
        title: 'Refund Processed',
        body: `Your refund of ₹${booking.price} has been processed successfully.`,
        data: { bookingId, refundId: refund.id, type: 'refund_processed' },
      });
    }

    // Notify technician
    const techDoc = await db.collection('technicians').doc(booking.technicianId).get();
    const techNotifData = techDoc.data();

    if (techNotifData?.fcmToken) {
      await sendNotificationToToken({
        token: techNotifData.fcmToken,
        title: 'Booking Payment Refunded',
        body: `₹${booking.price} has been deducted from your wallet due to refund.`,
        data: { bookingId, amount: booking.price, type: 'payment_refunded' },
      });
    }

    return { success: true, paymentStatus: 'refunded', refundId: refund.id, amount: booking.price };
  } catch (error: any) {
    console.error('Refund processing error:', error);
    
    // FIX 6: Mark refund as failed on error
    await bookingRef.update({
      'refund.status': 'failed',
      'refund.failureReason': error.message,
      'refund.failedAt': admin.firestore.FieldValue.serverTimestamp()
    });
    
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', `Refund processing failed: ${error.message}`);
  }
}));
