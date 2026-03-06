import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

async function assertAdmin(context: functions.https.CallableContext) {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
    if (!adminDoc.exists) throw new functions.https.HttpsError('permission-denied', 'Admin access required');
}

async function sendNotification(userId: string, userType: 'customer' | 'technician', payload: {
    title: string;
    body: string;
    data?: any;
}) {
    try {
        const tokensSnap = await db.collection(userType === 'customer' ? 'customers' : 'technicians')
            .doc(userId)
            .collection('fcmTokens')
            .where('isActive', '==', true)
            .get();

        const tokens = tokensSnap.docs.map(doc => doc.data().token).filter(Boolean);

        if (tokens.length > 0) {
            await admin.messaging().sendMulticast({
                tokens,
                notification: {
                    title: payload.title,
                    body: payload.body,
                },
                data: payload.data || {},
            });
        }
    } catch (error) {
        console.error('Error sending notification:', error);
    }
}

export const approveBooking = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { bookingId } = data;
    if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'Missing bookingId');

    const bookingRef = db.collection('bookings').doc(bookingId);

    try {
        await db.runTransaction(async (t) => {
            const bookingDoc = await t.get(bookingRef);
            if (!bookingDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');

            const booking = bookingDoc.data()!;
            if (booking.status !== 'PENDING_ADMIN_APPROVAL') {
                throw new functions.https.HttpsError('failed-precondition', 'Booking is not pending approval');
            }

            t.update(bookingRef, {
                status: 'ADMIN_APPROVED',
                adminApprovedAt: admin.firestore.FieldValue.serverTimestamp(),
                adminApprovedBy: context.auth!.uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Log activity
            t.set(db.collection('activity_logs').doc(), {
                actorType: 'admin',
                actorUid: context.auth!.uid,
                action: 'booking_approved',
                entityId: bookingId,
                entityType: 'booking',
                metadata: { bookingId, customerId: booking.customerId, technicianId: booking.technicianId },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });

        // Send notification to technician
        const bookingData = (await bookingRef.get()).data();
        if (bookingData?.technicianId) {
            await sendNotification(bookingData.technicianId, 'technician', {
                title: 'New Booking Request',
                body: `You have a new booking for ${bookingData.serviceName}`,
                data: { type: 'booking_approved', bookingId },
            });
        }

        return { success: true, message: 'Booking approved successfully' };
    } catch (error: any) {
        console.error('Error approving booking:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

export const rejectBooking = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { bookingId, reason } = data;
    if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'Missing bookingId');

    const bookingRef = db.collection('bookings').doc(bookingId);

    try {
        await db.runTransaction(async (t) => {
            const bookingDoc = await t.get(bookingRef);
            if (!bookingDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');

            const booking = bookingDoc.data()!;
            if (booking.status !== 'PENDING_ADMIN_APPROVAL') {
                throw new functions.https.HttpsError('failed-precondition', 'Booking is not pending approval');
            }

            t.update(bookingRef, {
                status: 'CANCELLED',
                cancellationReason: reason || 'Rejected by admin',
                cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
                cancelledBy: context.auth!.uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Log activity
            t.set(db.collection('activity_logs').doc(), {
                actorType: 'admin',
                actorUid: context.auth!.uid,
                action: 'booking_rejected',
                entityId: bookingId,
                entityType: 'booking',
                metadata: { bookingId, customerId: booking.customerId, reason },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });

        // Send notification to customer
        const bookingData = (await bookingRef.get()).data();
        if (bookingData?.customerId) {
            await sendNotification(bookingData.customerId, 'customer', {
                title: 'Booking Cancelled',
                body: `Your booking for ${bookingData.serviceName} has been cancelled`,
                data: { type: 'booking_rejected', bookingId },
            });
        }

        return { success: true, message: 'Booking rejected successfully' };
    } catch (error: any) {
        console.error('Error rejecting booking:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
