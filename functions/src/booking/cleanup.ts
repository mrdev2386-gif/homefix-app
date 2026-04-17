import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as notify from '../shared/notification_helper';

const db = admin.firestore();

export const cleanupStaleBookings = functions
    .runWith({ maxInstances: 1, timeoutSeconds: 540, memory: '256MB' })
    .pubsub.schedule('every 6 hours')
    .onRun(async (context) => {
        console.log('Running cleanupStaleBookings at', new Date().toISOString());
        const now = Date.now();
        const twentyFourHoursAgo = now - (24 * 60 * 60 * 1000);

        // Cancel bookings stuck in technician_pending for 24+ hours
        const staleBookings = await db.collection('bookings')
            .where('status', '==', 'technician_pending')
            .where('adminApprovedAt', '<', admin.firestore.Timestamp.fromMillis(twentyFourHoursAgo))
            .get();

        for (const doc of staleBookings.docs) {
            await doc.ref.update({
                status: 'cancelled',
                cancellationReason: 'Technician did not respond within 24 hours',
                cancelledBy: 'system',
                cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            await notify.notifyCustomerBookingCancelled(
                doc.data().customerId,
                doc.id,
                'Technician did not respond. Please try booking again.'
            );
        }

        console.log(`Cancelled ${staleBookings.size} stale bookings`);
    });
