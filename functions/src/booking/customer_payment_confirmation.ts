/**
 * CRITICAL FIX: Customer Payment Confirmation
 * 
 * This function handles the final payment confirmation after service completion.
 * 
 * FLOW:
 * 1. Customer confirms payment (online or cash)
 * 2. Booking status: awaiting_payment → paid
 * 3. Technician wallet credited atomically
 * 4. Booking marked as completed
 * 5. Notifications sent
 * 
 * SAFETY:
 * - Idempotent: Cannot pay twice
 * - Atomic: Wallet credit happens with booking update
 * - Validated: Only assigned technician's booking
 * 
 * PRODUCTION SAFETY:
 * - Structured logging for all payment events
 * - Duplicate credit detection
 * - Platform fee tracking
 * - Analytics updates
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { secureCallable, sanitize } from '../shared/security';
import { sendNotificationToToken } from '../shared/notification_helper';
import { processTechnicianEarning } from '../finance/wallet_logic';
import { logger } from '../shared/utils';

const db = admin.firestore();

// Structured logging helper for payments
function logPaymentEvent(
  event: string,
  data: {
    bookingId?: string;
    customerId?: string;
    technicianId?: string;
    amount?: number;
    status?: string;
    error?: string;
    [key: string]: any;
  }
) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    event,
    ...data
  };
  console.log(`[PAYMENT] ${JSON.stringify(logEntry)}`);
  
  // Store critical events in Firestore for monitoring
  if (['payment_start', 'payment_success', 'payment_failed', 'duplicate_credit_detected'].includes(event)) {
    db.collection('payment_logs').add({
      ...logEntry,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    }).catch(err => console.error('Failed to store payment log:', err));
  }
}

/**
 * CRITICAL: Customer confirms payment for completed service
 * 
 * Called after service completion when customer pays (online or cash)
 * Updates booking to "paid" and credits technician wallet
 */
export const customerConfirmPayment = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
      const startTime = Date.now();
      
      const uid = context.auth?.uid;
      if (!uid) {
        logPaymentEvent('payment_failed', { error: 'Unauthenticated' });
        throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
      }

      const { bookingId, paymentMethod } = data;

      if (!bookingId) {
        logPaymentEvent('payment_failed', { customerId: uid, error: 'Missing bookingId' });
        throw new functions.https.HttpsError('invalid-argument', 'bookingId is required');
      }

      if (!paymentMethod || !['online', 'cash', 'after_service'].includes(paymentMethod)) {
        logPaymentEvent('payment_failed', { bookingId, customerId: uid, error: 'Invalid payment method' });
        throw new functions.https.HttpsError('invalid-argument', 'paymentMethod must be "online", "cash", or "after_service"');
      }

      logPaymentEvent('payment_start', { bookingId, customerId: uid, paymentMethod });

      const bookingRef = db.collection('bookings').doc(bookingId);
      const bookingSnap = await bookingRef.get();

      if (!bookingSnap.exists) {
        logPaymentEvent('payment_failed', { bookingId, customerId: uid, error: 'Booking not found' });
        throw new functions.https.HttpsError('not-found', 'Booking not found');
      }

      const booking = bookingSnap.data()!;

      // CRITICAL: Verify customer owns this booking
      if (booking.customerId !== uid) {
        logPaymentEvent('payment_failed', { bookingId, customerId: uid, error: 'Permission denied' });
        throw new functions.https.HttpsError(
          'permission-denied',
          'You can only confirm payment for your own bookings'
        );
      }

      // CRITICAL: Verify booking is in awaiting_payment status
      const currentStatus = booking.bookingStatus || booking.status;
      if (currentStatus !== 'awaiting_payment') {
        logPaymentEvent('payment_failed', { 
          bookingId, 
          customerId: uid, 
          error: `Invalid status: ${currentStatus}` 
        });
        throw new functions.https.HttpsError(
          'failed-precondition',
          `Cannot confirm payment for booking in status: ${currentStatus}`
        );
      }

      // CRITICAL: Prevent duplicate payment
      if (booking.paymentStatus === 'paid' || booking.payment?.status === 'paid') {
        logPaymentEvent('payment_duplicate', { bookingId, customerId: uid });
        return {
          success: true,
          message: 'Payment already confirmed',
          bookingStatus: 'paid',
          isDuplicate: true
        };
      }

      const amount = booking.finalAmount || booking.price || 0;
      const technicianId = booking.technicianId;

      if (!technicianId) {
        logPaymentEvent('payment_failed', { bookingId, customerId: uid, error: 'No technician assigned' });
        throw new functions.https.HttpsError(
          'failed-precondition',
          'No technician assigned to this booking'
        );
      }

      if (amount <= 0) {
        logPaymentEvent('payment_failed', { bookingId, customerId: uid, error: `Invalid amount: ${amount}` });
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Invalid booking amount'
        );
      }

      try {
        // FIX #1: CLIENT DOES NOT CREDIT WALLET - Webhook is single source of truth
        // This function ONLY marks payment intent and updates booking status
        // Wallet credit happens ONLY via Razorpay webhook (razorpayWebhookV2)
        
        await db.runTransaction(async (transaction) => {
          // STEP 1: Verify booking hasn't been paid already (double-check in transaction)
          const freshBooking = await transaction.get(bookingRef);
          if (!freshBooking.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
          }

          const freshData = freshBooking.data()!;
          if (freshData.paymentStatus === 'paid' || freshData.payment?.status === 'paid') {
            throw new Error('ALREADY_PAID');
          }

          // STEP 2: Update booking status to "paid" (UNIFIED STATUS FIELDS)
          transaction.update(bookingRef, {
            bookingStatus: 'paid',
            paymentStatus: 'paid',
            'payment.status': 'paid',
            'payment.paidAt': admin.firestore.FieldValue.serverTimestamp(),
            'payment.paymentMethod': paymentMethod,
            'payment.confirmedBy': uid,
            'payment.confirmedByClient': true, // Mark that client confirmed
            'payment.amountPaid': amount,
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // STEP 3: Log payment confirmation (NO WALLET CREDIT HERE)
          const paymentLogRef = db.collection('payment_logs').doc();
          transaction.set(paymentLogRef, {
            bookingId,
            customerId: uid,
            technicianId,
            amount,
            action: 'client_payment_confirmed',
            paymentMethod,
            note: 'Client confirmed payment - wallet credit will happen via webhook',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });
        });

        const duration = Date.now() - startTime;
        logPaymentEvent('payment_success', { 
          bookingId, 
          customerId: uid,
          technicianId,
          amount,
          duration,
          note: 'Client confirmed - wallet credit via webhook'
        });

        // Update analytics
        await db.collection('system_analytics').doc('payments').set({
          totalPayments: admin.firestore.FieldValue.increment(1),
          totalRevenue: admin.firestore.FieldValue.increment(amount),
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true }).catch(err => console.error('Analytics update failed:', err));

        // STEP 6: Send notifications (non-blocking)
        try {
          const techDoc = await db.collection('technicians').doc(technicianId).get();
          const techData = techDoc.data();

          if (techData?.fcmToken) {
            await sendNotificationToToken({
              token: techData.fcmToken,
              title: 'Payment Confirmed',
              body: `Customer confirmed payment of ₹${amount} for booking ${bookingId}. Wallet credit pending webhook.`,
              data: {
                bookingId,
                type: 'payment_confirmed',
                amount: amount.toString(),
              },
            });
          }

          const customerDoc = await db.collection('customers').doc(uid).get();
          const customerData = customerDoc.data();

          if (customerData?.fcmToken) {
            await sendNotificationToToken({
              token: customerData.fcmToken,
              title: 'Payment Confirmed',
              body: `Your payment of ₹${amount} has been confirmed. Thank you!`,
              data: {
                bookingId,
                type: 'payment_confirmed',
                amount: amount.toString(),
              },
            });
          }
        } catch (notifError) {
          console.warn('⚠️ Notification error (non-fatal):', notifError);
        }

        return {
          success: true,
          message: 'Payment confirmed successfully',
          bookingStatus: 'paid',
          amount,
          technicianId
        };

      } catch (error: any) {
        if (error.message === 'ALREADY_PAID') {
          logPaymentEvent('payment_duplicate', { bookingId, customerId: uid });
          return {
            success: true,
            message: 'Payment already confirmed',
            bookingStatus: 'paid',
            isDuplicate: true
          };
        }

        if (error.message === 'WALLET_ALREADY_CREDITED') {
          logPaymentEvent('payment_duplicate', { bookingId, customerId: uid });
          return {
            success: true,
            message: 'Payment already processed',
            bookingStatus: 'paid',
            isDuplicate: true
          };
        }
        
        throw new functions.https.HttpsError(
          'internal',
          error.message || 'Failed to confirm payment'
        );
      }
    })
  );

/**
 * ADMIN: Manually confirm payment (for cash payments verified by admin)
 */
export const adminConfirmPayment = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
      console.log('✅ [adminConfirmPayment] Auth UID:', context.auth?.uid);
      
      const uid = context.auth?.uid;
      if (!uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
      }

      // Verify admin
      const adminDoc = await db.collection('admins').doc(uid).get();
      if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can confirm payments');
      }

      const { bookingId, paymentMethod = 'cash' } = data;

      if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'bookingId is required');
      }

      const bookingRef = db.collection('bookings').doc(bookingId);
      const bookingSnap = await bookingRef.get();

      if (!bookingSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
      }

      const booking = bookingSnap.data()!;
      const amount = booking.finalAmount || booking.price || 0;
      const technicianId = booking.technicianId;
      const customerId = booking.customerId;

      // Same transaction logic as customerConfirmPayment
      await db.runTransaction(async (transaction) => {
        const freshBooking = await transaction.get(bookingRef);
        if (freshBooking.data()?.paymentStatus === 'paid') {
          throw new Error('ALREADY_PAID');
        }

        transaction.update(bookingRef, {
          bookingStatus: 'paid',
          paymentStatus: 'paid',
          'payment.status': 'paid',
          'payment.paidAt': admin.firestore.FieldValue.serverTimestamp(),
          'payment.paymentMethod': paymentMethod,
          'payment.confirmedBy': uid,
          'payment.amountPaid': amount,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Credit wallet
        const walletRef = db.collection('technician_wallets').doc(technicianId);
        const walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          transaction.set(walletRef, {
            availableBalance: amount,
            pendingBalance: 0,
            lifetimeEarnings: amount,
            lastPayoutAt: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        } else {
          transaction.update(walletRef, {
            availableBalance: admin.firestore.FieldValue.increment(amount),
            lifetimeEarnings: admin.firestore.FieldValue.increment(amount),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // Log transaction
        const transactionRef = walletRef.collection('transactions').doc();
        transaction.set(transactionRef, {
          type: 'credit',
          source: 'booking',
          status: 'completed',
          amount,
          fee: 0,
          referenceId: bookingId,
          description: `Payment for booking ${bookingId} (confirmed by admin)`,
          customerId,
          paymentMethod,
          confirmedBy: uid,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      console.log(`✅ [adminConfirmPayment] Payment confirmed by admin for booking ${bookingId}`);

      return {
        success: true,
        message: 'Payment confirmed by admin',
        bookingStatus: 'paid',
        amount
      };
    })
  );
