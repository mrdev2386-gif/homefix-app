
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
