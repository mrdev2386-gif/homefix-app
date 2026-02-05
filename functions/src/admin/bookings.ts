
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin, logAdminAction } from './utils';

import { sendPushNotification } from '../shared/notifications'; // Ensure this exists

export const adminManageBooking = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { bookingId, action, payload } = data; // action: 'assign' | 'reassign' | 'cancel'

        if (!bookingId || !action) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing bookingId or action');
        }

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await bookingRef.get();
        if (!bookingDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
        const booking = bookingDoc.data()!;

        if (action === 'assign' || action === 'reassign') {
            const { technicianId } = payload;
            if (!technicianId) throw new functions.https.HttpsError('invalid-argument', 'Missing technicianId');

            const techDoc = await db.collection('technicians').doc(technicianId).get();
            if (!techDoc.exists) throw new functions.https.HttpsError('not-found', 'Technician not found');
            const techData = techDoc.data()!;

            await bookingRef.update({
                assignedTechnicianId: technicianId,
                assignedTechnicianName: techData.name || 'Expert',
                status: 'assigned',
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Notify Technician
            try {
                await sendPushNotification(technicianId, 'technicians', {
                    title: 'New Job Assigned',
                    body: `You have been manually assigned to ${booking.serviceTitle}.`,
                    data: { bookingId, type: 'job_assigned' }
                });
            } catch (e) {
                console.error(`[Booking] Failed to notify technician ${technicianId}`, e);
            }

            // Notify Customer
            try {
                await sendPushNotification(booking.customerId, 'customers', {
                    title: 'Professional Assigned',
                    body: `${techData.name} has been assigned to your booking.`,
                    data: { bookingId, type: 'tech_assigned' }
                });
            } catch (e) {
                console.error(`[Booking] Failed to notify customer ${booking.customerId}`, e);
            }

            await logAdminAction(context.auth!.uid, `booking_${action}`, bookingId, { technicianId });
        } else if (action === 'cancel') {
            const { reason } = payload;
            await bookingRef.update({
                status: 'cancelled',
                cancellationReason: reason || 'Cancelled by admin',
                cancelledBy: 'admin',
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Notify Customer
            try {
                await sendPushNotification(booking.customerId, 'customers', {
                    title: 'Booking Cancelled',
                    body: `Your booking has been cancelled by the administrator.`,
                    data: { bookingId, type: 'booking_cancelled' }
                });
            } catch (e) {
                console.error(`[Booking] Failed to notify customer ${booking.customerId}`, e);
            }

            if (booking.assignedTechnicianId) {
                // Notify Technician
                try {
                    await sendPushNotification(booking.assignedTechnicianId, 'technicians', {
                        title: 'Job Cancelled',
                        body: `Job #${bookingId.slice(-6)} has been cancelled.`,
                        data: { bookingId, type: 'job_cancelled' }
                    });
                } catch (e) {
                    console.error(`[Booking] Failed to notify technician ${booking.assignedTechnicianId}`, e);
                }
            }

            await logAdminAction(context.auth!.uid, 'booking_cancel', bookingId, { reason });
        } else {
            throw new functions.https.HttpsError('invalid-argument', `Invalid action: ${action}`);
        }

        return { success: true };
    } catch (error: any) {
        console.error('[Booking] Error in adminManageBooking:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to manage booking');
    }
});
