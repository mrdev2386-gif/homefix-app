
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { updateBookingStatusUnified } from './shared/booking_flow';
import { isAdmin as checkIsAdmin } from './index'; // Use existing helper

const db = admin.firestore();

// ==========================================
// TECHNICIAN ACTIONS
// ==========================================

/**
 * Technician: Schedule Inspection
 */
export const scheduleInspection = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { bookingId, scheduledAt } = data;

    await updateBookingStatusUnified(bookingId, 'inspection_scheduled',
        { uid: context.auth.uid, role: 'technician' },
        { logAction: true }
    );

    await db.collection('bookings').doc(bookingId).update({
        inspectionScheduledAt: admin.firestore.Timestamp.fromDate(new Date(scheduledAt))
    });

    return { success: true };
});

/**
 * Technician: Start Inspection (Arrived at location)
 */
export const startInspection = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { bookingId } = data;

    await updateBookingStatusUnified(bookingId, 'inspection_in_progress',
        { uid: context.auth.uid, role: 'technician' },
        { logAction: true }
    );

    return { success: true };
});

/**
 * Technician: Submit Inspection Report & Quote
 */
export const submitInspectionReport = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { bookingId, subServices, notes, images } = data;

    // Validate subServices
    if (!subServices || !Array.isArray(subServices) || subServices.length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'At least one service item required');
    }

    // Calculation logic - FETCH MASTER PRICES to prevent tampering
    let subtotal = 0;
    const validatedSubServices = [];

    for (const item of subServices) {
        if (!item.subServiceId) throw new functions.https.HttpsError('invalid-argument', 'Missing subServiceId');

        const ssDoc = await db.collection('subServices').doc(item.subServiceId).get();
        if (!ssDoc.exists) throw new functions.https.HttpsError('not-found', `Sub-service ${item.subServiceId} not found`);

        const masterData = ssDoc.data()!;
        const price = masterData.price || 0;
        const quantity = item.quantity || 1;

        subtotal += (price * quantity);
        validatedSubServices.push({
            id: item.subServiceId,
            name: masterData.name || 'Service Item',
            price: price,
            quantity: quantity,
            total: price * quantity
        });
    }

    const platformFee = Math.round(subtotal * 0.15); // 15% platform fee
    const gst = Math.round((subtotal + platformFee) * 0.18); // 18% GST
    const total = subtotal + platformFee + gst;
    const technicianAmount = Math.round(subtotal * 0.85); // Tech takes 85% of subtotal

    const pricingData = {
        subServices: validatedSubServices,
        subtotal,
        platformFee,
        technicianAmount,
        gst,
        total
    };

    await updateBookingStatusUnified(bookingId, 'awaiting_approval',
        { uid: context.auth.uid, role: 'technician' },
        {
            pricingData,
            inspectionReport: { notes, images },
            logAction: true
        }
    );

    return { success: true };
});

/**
 * Technician: Start Job (Work in progress)
 */
export const startJob = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { bookingId } = data;

    await updateBookingStatusUnified(bookingId, 'in_progress',
        { uid: context.auth.uid, role: 'technician' },
        { logAction: true }
    );

    return { success: true };
});

/**
 * Technician: Complete Job
 */
export const completeJob = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { bookingId } = data;

    await updateBookingStatusUnified(bookingId, 'completed',
        { uid: context.auth.uid, role: 'technician' },
        { logAction: true }
    );

    return { success: true };
});

// ==========================================
// CUSTOMER ACTIONS
// ==========================================

/**
 * Customer: Approve Quote
 */
export const approveJobQuote = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { bookingId } = data;

    await updateBookingStatusUnified(bookingId, 'approved',
        { uid: context.auth.uid, role: 'customer' },
        { logAction: true }
    );

    return { success: true };
});

/**
 * Customer: Reject Quote
 */
export const rejectJobQuote = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { bookingId, reason } = data;

    await updateBookingStatusUnified(bookingId, 'rejected',
        { uid: context.auth.uid, role: 'customer' },
        { reason, logAction: true }
    );

    return { success: true };
});

/**
 * Customer: Cancel Booking (Booking status becomes 'cancelled')
 */
export const cancelBookingByCustomer = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { bookingId, reason } = data;

    await updateBookingStatusUnified(bookingId, 'cancelled',
        { uid: context.auth.uid, role: 'customer' },
        { reason, logAction: true }
    );

    return { success: true };
});
