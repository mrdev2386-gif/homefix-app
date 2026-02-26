
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin, logAdminAction } from './utils';

export const refundBooking = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { bookingId } = data;

    const bookingRef = db.collection('bookings').doc(bookingId);
    const booking = await bookingRef.get();

    if (!booking.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
    const b = booking.data()!;

    if (b.paymentStatus !== 'paid') {
        throw new functions.https.HttpsError('failed-precondition', 'Booking is not paid');
    }

    await db.runTransaction(async (t) => {
        const userRef = db.collection('customers').doc(b.customerId);
        const userDoc = await t.get(userRef);

        t.update(userRef, {
            walletBalance: admin.firestore.FieldValue.increment(b.finalAmount),
        });

        t.set(userRef.collection('wallet_transactions').doc(), {
            type: 'credit',
            amount: b.finalAmount,
            description: `Refund for booking #${bookingId}`,
            status: 'completed',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        t.update(bookingRef, {
            status: 'refunded',
            paymentStatus: 'refunded',
            refundedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    });

    await logAdminAction(context.auth!.uid, 'booking_refund', bookingId);
    return { success: true };
});

export const adjustWallet = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { userId, type, amount, reason } = data; // type: 'credit' | 'debit'

    const ref = db.collection('technicians').doc(userId); // Or customers? Let's assume tech for now or handle both
    const user = await ref.get();
    if (!user.exists) {
        const cust = await db.collection('customers').doc(userId).get();
        if (!cust.exists) throw new functions.https.HttpsError('not-found', 'User not found');
        // Handle customer adjustment
        await db.runTransaction(async t => {
            t.update(cust.ref, { walletBalance: admin.firestore.FieldValue.increment(type === 'credit' ? amount : -amount) });
            t.set(cust.ref.collection('wallet_transactions').doc(), {
                type, amount, description: reason, status: 'completed', createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
    } else {
        // Technician adjustment
        await db.runTransaction(async t => {
            t.update(ref, { walletBalance: admin.firestore.FieldValue.increment(type === 'credit' ? amount : -amount) });
            t.set(ref.collection('wallet_transactions').doc(), {
                type, amount, description: reason, status: 'completed', createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
    }

    await logAdminAction(context.auth!.uid, `wallet_${type}`, userId, { amount, reason });
    return { success: true };
});

/**
 * Process a booking payout - marks it as completed
 * Requirements: 4.2, 4.3, 15.1, 15.4, 15.8, 16.1, 16.5, 16.6
 */
export const processBookingPayout = functions.https.onCall(async (data, context) => {
    // Verify admin authentication
    await assertAdmin(context);

    const { payoutId } = data;

    // Validate input
    if (!payoutId) {
        throw new functions.https.HttpsError('invalid-argument', 'payoutId is required');
    }

    try {
        // Use transaction to ensure atomicity
        const result = await db.runTransaction(async (transaction) => {
            const payoutRef = db.collection('bookingPayouts').doc(payoutId);
            const payoutDoc = await transaction.get(payoutRef);

            // Validate payout exists
            if (!payoutDoc.exists) {
                throw new Error('Payout not found');
            }

            const payoutData = payoutDoc.data()!;

            // Validate payout status is pending
            if (payoutData.status !== 'pending') {
                throw new Error(`Payout is not in pending status. Current status: ${payoutData.status}`);
            }

            // Update payout status to completed
            transaction.update(payoutRef, {
                status: 'completed',
                paidAt: admin.firestore.FieldValue.serverTimestamp(),
                processedBy: context.auth!.uid
            });

            // Create audit log entry atomically
            const auditLogRef = db.collection('auditLogs').doc();
            transaction.set(auditLogRef, {
                adminId: context.auth!.uid,
                adminName: context.auth!.token.name || 'Unknown Admin',
                adminEmail: context.auth!.token.email || '',
                actionType: 'payout_processed',
                entityType: 'booking_payout',
                entityId: payoutId,
                metadata: {
                    bookingId: payoutData.bookingId,
                    technicianId: payoutData.technicianId,
                    technicianName: payoutData.technicianName,
                    amount: payoutData.technicianEarning,
                    bookingAmount: payoutData.bookingAmount,
                    platformCommission: payoutData.platformCommissionAmount
                },
                ipAddress: context.rawRequest?.ip || 'unknown',
                userAgent: context.rawRequest?.headers['user-agent'] || 'unknown',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            return payoutData;
        });

        return {
            success: true,
            message: 'Payout processed successfully',
            payout: result
        };
    } catch (error: any) {
        console.error('[processBookingPayout] Error:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Failed to process payout');
    }
});
