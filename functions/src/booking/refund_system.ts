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
