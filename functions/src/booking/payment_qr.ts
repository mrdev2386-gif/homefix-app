import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { processTechnicianEarning } from '../finance/wallet_logic';
import * as notify from '../shared/notification_helper';

const db = admin.firestore();

// ==========================================
// GENERATE TECHNICIAN QR CODE
// ==========================================

export const generateTechnicianQR = functions.https.onCall(
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
// CONFIRM QR PAYMENT
// ==========================================

export const confirmQRPayment = functions.https.onCall(
    async (data: { bookingId: string, transactionId?: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Auth required');
        }

        const customerId = context.auth.uid;
        const { bookingId, transactionId } = data;

        const booking = await db.collection('bookings').doc(bookingId).get();

        if (!booking.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const bookingData = booking.data()!;

        if (bookingData.customerId !== customerId) {
            throw new functions.https.HttpsError('permission-denied', 'Not your booking');
        }

        if (bookingData.status !== 'work_completed') {
            throw new functions.https.HttpsError('failed-precondition', 'Work not completed');
        }

        const now = admin.firestore.FieldValue.serverTimestamp();

        await booking.ref.update({
            status: 'completed',
            paymentStatus: 'paid',
            paymentMethod: 'qr_wallet',
            paymentTransactionId: transactionId || null,
            paidAt: now,
            completedAt: now,
            updatedAt: now,
        });

        // Process earnings
        await processTechnicianEarning(
            bookingId,
            bookingData.technicianId,
            bookingData.finalAmount,
            [bookingData.serviceId]
        );

        // Notify technician
        await notify.notifyTechnicianNewPayment(
            bookingData.technicianId,
            bookingId,
            bookingData.finalAmount
        );

        return { success: true, status: 'completed' };
    }
);
