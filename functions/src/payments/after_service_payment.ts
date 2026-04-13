/**
 * After-Service Payment Confirmation
 * 
 * SECURITY:
 * - Only technician or admin can confirm payment received
 * - Validates booking exists and is completed
 * - Validates payment method is after_service
 * - Updates payment status atomically
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { secureCallable } from '../shared/security';
import { logger } from '../shared/utils';
import { updateBookingStatus } from '../shared/status_history_tracker';

/**
 * Confirm after-service payment received
 * Called by technician after customer pays in cash/UPI/other method
 */
export const confirmAfterServicePayment = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
      }

      const { bookingId } = data;
      const uid = context.auth.uid;

      if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'bookingId is required');
      }

      // Get booking
      const bookingRef = db.collection('bookings').doc(bookingId);
      const bookingDoc = await bookingRef.get();

      if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
      }

      const booking: any = bookingDoc.data();

      // Check if user is technician or admin
      const isTechnician = booking.technicianId === uid;
      const adminDoc = await db.collection('admins').doc(uid).get();
      const isAdmin = adminDoc.exists;

      if (!isTechnician && !isAdmin) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only assigned technician or admin can confirm payment'
        );
      }

      // Validate booking status
      if (booking.status !== 'service_completed' && booking.bookingStatus !== 'service_completed') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Service must be completed before confirming payment'
        );
      }

      // Validate payment method
      const paymentMethod = booking.payment?.paymentMethod || booking.paymentMethod;
      if (paymentMethod !== 'after_service') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'This booking is not set for after-service payment'
        );
      }

      // Check if already paid
      const isPaid = booking.payment?.status === 'paid' || booking.paymentStatus === 'paid';
      if (isPaid) {
        throw new functions.https.HttpsError('already-exists', 'Payment already confirmed');
      }

      const amount = booking.pricing?.total || booking.finalAmount || booking.price || 0;

      // Update booking with payment confirmation using transaction and helper
      await db.runTransaction(async (transaction) => {
        const freshDoc = await transaction.get(bookingRef);
        if (!freshDoc.exists) {
          throw new functions.https.HttpsError('not-found', 'Booking not found');
        }
        const freshBooking = freshDoc.data()!;

        // Use updateBookingStatus helper to ensure both status and bookingStatus are updated
        updateBookingStatus(transaction, bookingRef, 'completed', freshBooking, {
          'payment.status': 'paid',
          'payment.paidAt': admin.firestore.FieldValue.serverTimestamp(),
          'payment.confirmedBy': uid,
          'payment.amountPaid': amount,
          'paymentStatus': 'paid',
          'completedAt': admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // Log payment confirmation
      await db.collection('payment_logs').add({
        bookingId,
        amount,
        action: 'after_service_payment_confirmed',
        confirmedBy: uid,
        confirmedByRole: isTechnician ? 'technician' : 'admin',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // Send notification to customer
      await db.collection('notifications').add({
        userId: booking.customerId,
        title: 'Payment Confirmed',
        body: `Your payment of ₹${amount} has been confirmed. Thank you!`,
        type: 'payment_confirmed',
        bookingId,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('after_service_payment_confirmed', { bookingId, amount, confirmedBy: uid });

      return {
        success: true,
        message: 'Payment confirmed successfully',
        bookingStatus: 'completed'
      };
    })
  );
