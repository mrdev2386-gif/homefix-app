import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { processTechnicianEarning } from '../finance/wallet_logic';
import * as notify from '../shared/notification_helper';

const db = admin.firestore();

// ==========================================
// GENERATE TECHNICIAN QR CODE
// ==========================================

export const generateTechnicianQR = functions
  .region('asia-south1')
  .https.onCall(
    async (data, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Auth required');
        }

        const techId = context.auth.uid;
        const techDoc = await db.collection('technicians').doc(techId).get();

        if (!techDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        }

        const techData = techDoc.data()!;
        const upiId = techData.upiId || `${techId}@homefix`;
        const qrData = `upi://pay?pa=${upiId}&pn=${encodeURIComponent(techData.name || 'Technician')}&cu=INR`;

        await techDoc.ref.update({
            walletQRData: qrData,
            walletQRUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true, qrData };
    }
);

// ==========================================
// CONFIRM QR PAYMENT (Called by Technician after scanning)
// ==========================================

export const confirmQRPayment = functions
  .region('asia-south1')
  .https.onCall(
    async (data: { bookingId: string, customerId: string, amount: number }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Auth required');
        }

        const technicianId = context.auth.uid;
        const { bookingId, customerId, amount } = data;

        if (!bookingId || !customerId || !amount) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
        }

        const now = admin.firestore.FieldValue.serverTimestamp();


        // RUN ATOMIC TRANSACTION
        try {
            await db.runTransaction(async (transaction) => {
                // 1. Get Booking
                const bookingRef = db.collection('bookings').doc(bookingId);
                const bookingDoc = await transaction.get(bookingRef);

                if (!bookingDoc.exists) {
                    throw new Error('Booking not found');
                }

                const booking = bookingDoc.data()!;

                // Security Checks
                if (booking.technicianId !== technicianId) {
                    throw new Error('Not your booking');
                }
                if (booking.customerId !== customerId) {
                    throw new Error('Customer ID mismatch');
                }
                if (booking.status !== 'awaiting_customer_payment') {
                    throw new Error('Booking is not in awaiting_payment status');
                }
                if (booking.paymentStatus === 'paid') {
                    throw new Error('Already paid');
                }

                // SECURITY: Never trust client amount, use booking amount
                const finalAmount = booking.finalAmount || booking.price || 0;

                // 2. Deduct from Customer Balance (Ledger-based)
                // This will throw if insufficient funds
                const { updateWalletBalance } = await import('../finance/wallet_logic');
                await updateWalletBalance(
                    transaction,
                    customerId,
                    -finalAmount,
                    'booking_payment_qr',
                    bookingId,
                    `Payment for service ${booking.serviceName}`
                );

                // 3. Update Booking Status
                transaction.update(bookingRef, {
                    status: 'completed',
                    paymentStatus: 'paid',
                    paymentMethod: 'wallet_qr',
                    paidAt: now,
                    completedAt: now,
                    updatedAt: now
                });
            });

            // 4. Release Payout to Technician (Outside customer txn to keep it clean, or handled by trigger)
            // Actually, for strict safety, we can call it here as a separate transaction or same.
            // Since we want 90/10 split, let's call processTechnicianEarning
            const { processTechnicianEarning } = await import('../finance/wallet_logic');
            await processTechnicianEarning(bookingId, technicianId, amount, customerId);

            await notify.notifyCustomerPaymentSuccess(customerId, bookingId, amount);
            await notify.notifyTechnicianNewPayment(technicianId, bookingId, amount);

            return { success: true, status: 'completed' };
        } catch (err: any) {
            console.error('[confirmQRPayment] failed:', err);
            throw new functions.https.HttpsError('failed-precondition', err.message);
        }
    }
);
