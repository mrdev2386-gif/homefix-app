import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendNotificationToToken } from '../shared/notification_helper';

const db = admin.firestore();

// ==========================================
// REFUND BOOKING PAYMENT
// ==========================================
export const refundBookingPayment = functions.https.onCall(async (request) => {
  const { bookingId, refundReason } = request.data;
  const uid = request.auth?.uid;

  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');
  if (!refundReason) throw new functions.https.HttpsError('invalid-argument', 'refundReason required');

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

  // Duplicate refund protection
  if (booking.paymentStatus === 'refunded') {
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

  try {
    // Process refund with Razorpay
    const Razorpay = (await import('razorpay')).default;
    const razorpay = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID || '',
      key_secret: process.env.RAZORPAY_KEY_SECRET || '',
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
      refundedAt: admin.firestore.FieldValue.serverTimestamp(),
      refundReason,
      refundedBy: uid,
      refundId: refund.id,
    });

    // Update technician wallet
    const techRef = db.collection('technicians').doc(booking.technicianId);
    const techSnap = await techRef.get();
    const techData = techSnap.data();

    if (techData) {
      const newWalletBalance = (techData.walletBalance || 0) - booking.price;

      if (newWalletBalance < 0) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          `Insufficient wallet balance. Current: ₹${techData.walletBalance}, Required: ₹${booking.price}`
        );
      }

      await techRef.update({
        walletBalance: newWalletBalance,
        totalEarnings: Math.max(0, (techData.totalEarnings || 0) - booking.price),
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
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', `Refund processing failed: ${error.message}`);
  }
});
