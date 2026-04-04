
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin, logAdminAction } from './utils';
import { updateBookingStatus } from '../shared/status_history_tracker';

import { sendPushNotification } from '../shared/notifications'; // Ensure this exists

export const adminManageBooking = functions.region('asia-south1').https.onCall(async (data, context) => {
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

            await db.runTransaction(async (t) => {
                const bookingDoc = await t.get(bookingRef);
                if (!bookingDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
                const booking = bookingDoc.data()!;

                // If reassigning, remove from old technician
                if (booking.assignedTechnicianId && booking.assignedTechnicianId !== technicianId) {
                    t.update(db.collection('technicians').doc(booking.assignedTechnicianId), {
                        currentAssignments: admin.firestore.FieldValue.arrayRemove(bookingId)
                    });
                }

                // Use status history tracker for atomic update
                updateBookingStatus(t, bookingRef, 'assigned', booking, {
                    assignedTechnicianId: technicianId,
                    assignedTechnicianName: techData.name || 'Expert',
                });

                t.update(db.collection('technicians').doc(technicianId), {
                    currentAssignments: admin.firestore.FieldValue.arrayUnion(bookingId)
                });
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

            // Use unified flow for cancellation to ensure tech cleanup and potentially refund logic
            const { updateBookingStatusUnified } = require('../shared/booking_flow');
            await updateBookingStatusUnified(bookingId, 'cancelled',
                { uid: context.auth!.uid, role: 'admin' },
                { reason: reason || 'Cancelled by admin', logAction: true }
            );

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
