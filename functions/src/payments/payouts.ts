/**
 * Technician Payout Management
 * 
 * MANUAL payout system (Phase 1):
 * - Admin manually marks payouts as paid
 * - No automatic bank transfers yet
 * - Tracks payout status and history
 * - Provides payout reports
 * 
 * Future (Phase 2):
 * - Integrate with Razorpay Payouts API
 * - Automatic bank transfers
 * - Scheduled payouts
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { Booking } from '../shared/models';
import { assertAdmin, logAdminAction } from '../shared/utils';
import { sendPushNotification } from '../shared/notifications';

// ============================================================================
// PAYOUT LISTING & REPORTS
// ============================================================================

/**
 * Get pending payouts
 * 
 * Returns all bookings with:
 * - payment.status = 'paid'
 * - payout.status = 'pending'
 */
export const getPendingPayouts = functions.region('asia-south1').https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { limit = 50, startAfter } = data;

    let query = db.collection('bookings')
        .where('payment.status', '==', 'paid')
        .where('payout.status', '==', 'pending')
        .orderBy('payment.paidAt', 'desc')
        .limit(limit);

    if (startAfter) {
        const startDoc = await db.collection('bookings').doc(startAfter).get();
        query = query.startAfter(startDoc);
    }

    const snapshot = await query.get();

    const payouts = snapshot.docs.map(doc => {
        const booking = doc.data() as Booking;
        return {
            bookingId: doc.id,
            bookingNumber: booking.bookingNumber,
            technicianId: booking.technicianId,
            technicianName: booking.technicianName,
            serviceName: booking.serviceName,
            totalAmount: booking.payout?.totalAmount || 0,
            platformFee: booking.payout?.platformFee || 0,
            technicianAmount: booking.payout?.technicianAmount || 0,
            paidAt: booking.payment.paidAt,
            customerName: booking.customerName
        };
    });

    return {
        payouts,
        hasMore: snapshot.docs.length === limit
    };
});

/**
 * Get payout history
 */
export const getPayoutHistory = functions.region('asia-south1').https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { technicianId, status, limit = 50, startAfter } = data;

    let query = db.collection('bookings')
        .where('payment.status', '==', 'paid');

    if (technicianId) {
        query = query.where('technicianId', '==', technicianId);
    }

    if (status) {
        query = query.where('payout.status', '==', status);
    }

    query = query.orderBy('payment.paidAt', 'desc').limit(limit);

    if (startAfter) {
        const startDoc = await db.collection('bookings').doc(startAfter).get();
        query = query.startAfter(startDoc);
    }

    const snapshot = await query.get();

    const history = snapshot.docs.map(doc => {
        const booking = doc.data() as Booking;
        return {
            bookingId: doc.id,
            bookingNumber: booking.bookingNumber,
            technicianId: booking.technicianId,
            technicianName: booking.technicianName,
            serviceName: booking.serviceName,
            totalAmount: booking.payout?.totalAmount || 0,
            platformFee: booking.payout?.platformFee || 0,
            technicianAmount: booking.payout?.technicianAmount || 0,
            payoutStatus: booking.payout?.status || 'pending',
            payoutPaidAt: booking.payout?.paidAt,
            payoutMethod: booking.payout?.paymentMethod,
            transactionId: booking.payout?.transactionId,
            paidAt: booking.payment.paidAt
        };
    });

    return {
        history,
        hasMore: snapshot.docs.length === limit
    };
});

/**
 * Get payout summary by technician
 */
export const getPayoutSummary = functions.region('asia-south1').https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { technicianId, startDate, endDate } = data;

    if (!technicianId) {
        throw new functions.https.HttpsError('invalid-argument', 'Technician ID required');
    }

    let query = db.collection('bookings')
        .where('technicianId', '==', technicianId)
        .where('payment.status', '==', 'paid');

    if (startDate) {
        query = query.where('payment.paidAt', '>=', admin.firestore.Timestamp.fromDate(new Date(startDate)));
    }

    if (endDate) {
        query = query.where('payment.paidAt', '<=', admin.firestore.Timestamp.fromDate(new Date(endDate)));
    }

    const snapshot = await query.get();

    let totalEarnings = 0;
    let totalPlatformFee = 0;
    let totalPaid = 0;
    let totalPending = 0;
    let totalOnHold = 0;
    let bookingsCount = 0;

    snapshot.docs.forEach(doc => {
        const booking = doc.data() as Booking;
        const techAmount = booking.payout?.technicianAmount || 0;
        const platformFee = booking.payout?.platformFee || 0;

        totalEarnings += techAmount;
        totalPlatformFee += platformFee;
        bookingsCount++;

        if (booking.payout?.status === 'paid') {
            totalPaid += techAmount;
        } else if (booking.payout?.status === 'on_hold') {
            totalOnHold += techAmount;
        } else {
            totalPending += techAmount;
        }
    });

    return {
        technicianId,
        totalEarnings,
        totalPlatformFee,
        totalPaid,
        totalPending,
        totalOnHold,
        bookingsCount,
        averageEarningPerBooking: bookingsCount > 0 ? totalEarnings / bookingsCount : 0
    };
});

// ============================================================================
// PAYOUT MANAGEMENT
// ============================================================================

/**
 * Mark payout as paid (Manual)
 * 
 * Admin marks that they have transferred money to technician
 */
export const markPayoutPaid = functions.region('asia-south1').https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { bookingId, paymentMethod, transactionId, notes } = data;
    const adminId = context.auth!.uid;

    if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'Booking ID required');
    }

    if (!paymentMethod) {
        throw new functions.https.HttpsError('invalid-argument', 'Payment method required');
    }

    // Get booking
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking = bookingDoc.data() as Booking;

    // Validate payment is completed
    if (booking.payment.status !== 'paid') {
        throw new functions.https.HttpsError('failed-precondition', 'Payment not completed yet');
    }

    // Validate payout is pending
    if (booking.payout?.status === 'paid') {
        throw new functions.https.HttpsError('already-exists', 'Payout already marked as paid');
    }

    // Update payout status
    await bookingRef.update({
        'payout.status': 'paid',
        'payout.paidBy': adminId,
        'payout.paidAt': admin.firestore.FieldValue.serverTimestamp(),
        'payout.paymentMethod': paymentMethod,
        'payout.transactionId': transactionId || '',
        'payout.notes': notes || ''
    });

    // Log action
    await logAdminAction(adminId, 'payout_marked_paid', bookingId, {
        technicianId: booking.technicianId,
        technicianName: booking.technicianName,
        amount: booking.payout?.technicianAmount || 0,
        paymentMethod,
        transactionId
    });

    // Log in payout history
    await db.collection('payout_logs').add({
        bookingId,
        technicianId: booking.technicianId,
        technicianName: booking.technicianName,
        amount: booking.payout?.technicianAmount || 0,
        platformFee: booking.payout?.platformFee || 0,
        action: 'payout_paid',
        paymentMethod,
        transactionId: transactionId || '',
        paidBy: adminId,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Send notification to technician
    if (booking.technicianId) {
        await sendPushNotification(booking.technicianId, 'technicians', {
            title: 'Payout Processed',
            body: `Your payout of ₹${booking.payout?.technicianAmount} for booking #${booking.bookingNumber} has been marked as completed.`,
            data: {
                type: 'payout_processed',
                bookingId: bookingDoc.id,
                method: paymentMethod
            }
        });
    }

    return { success: true };
});

/**
 * Put payout on hold
 * 
 * Admin can put payout on hold (e.g., dispute, quality issue)
 */
export const putPayoutOnHold = functions.region('asia-south1').https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { bookingId, reason } = data;
    const adminId = context.auth!.uid;

    if (!bookingId || !reason) {
        throw new functions.https.HttpsError('invalid-argument', 'Booking ID and reason required');
    }

    // Get booking
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking = bookingDoc.data() as Booking;

    // Validate payment is completed
    if (booking.payment.status !== 'paid') {
        throw new functions.https.HttpsError('failed-precondition', 'Payment not completed yet');
    }

    // Update payout status
    await bookingRef.update({
        'payout.status': 'on_hold',
        'payout.onHoldReason': reason
    });

    // Log action
    await logAdminAction(adminId, 'payout_on_hold', bookingId, {
        technicianId: booking.technicianId,
        reason
    });

    return { success: true };
});

/**
 * Release payout from hold
 */
export const releasePayoutFromHold = functions.region('asia-south1').https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { bookingId } = data;
    const adminId = context.auth!.uid;

    if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'Booking ID required');
    }

    // Get booking
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking = bookingDoc.data() as Booking;

    // Validate payout is on hold
    if (booking.payout?.status !== 'on_hold') {
        throw new functions.https.HttpsError('failed-precondition', 'Payout is not on hold');
    }

    // Update payout status
    await bookingRef.update({
        'payout.status': 'pending',
        'payout.onHoldReason': admin.firestore.FieldValue.delete()
    });

    // Log action
    await logAdminAction(adminId, 'payout_released', bookingId, {
        technicianId: booking.technicianId
    });

    return { success: true };
});

/**
 * Bulk mark payouts as paid
 * 
 * Admin can mark multiple payouts as paid at once
 */
export const bulkMarkPayoutsPaid = functions.region('asia-south1').https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { bookingIds, paymentMethod, notes } = data;
    const adminId = context.auth!.uid;

    if (!bookingIds || !Array.isArray(bookingIds) || bookingIds.length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Booking IDs array required');
    }

    if (bookingIds.length > 100) {
        throw new functions.https.HttpsError('invalid-argument', 'Maximum 100 bookings at a time');
    }

    if (!paymentMethod) {
        throw new functions.https.HttpsError('invalid-argument', 'Payment method required');
    }

    const results = {
        success: [] as string[],
        failed: [] as { bookingId: string; reason: string }[]
    };

    // Process each booking
    for (const bookingId of bookingIds) {
        try {
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingDoc = await bookingRef.get();

            if (!bookingDoc.exists) {
                results.failed.push({ bookingId, reason: 'Booking not found' });
                continue;
            }

            const booking = bookingDoc.data() as Booking;

            // Validate
            if (booking.payment.status !== 'paid') {
                results.failed.push({ bookingId, reason: 'Payment not completed' });
                continue;
            }

            if (booking.payout?.status === 'paid') {
                results.failed.push({ bookingId, reason: 'Already paid' });
                continue;
            }

            // Update
            await bookingRef.update({
                'payout.status': 'paid',
                'payout.paidBy': adminId,
                'payout.paidAt': admin.firestore.FieldValue.serverTimestamp(),
                'payout.paymentMethod': paymentMethod,
                'payout.notes': notes || ''
            });

            // Log
            await db.collection('payout_logs').add({
                bookingId,
                technicianId: booking.technicianId,
                technicianName: booking.technicianName,
                amount: booking.payout?.technicianAmount || 0,
                action: 'bulk_payout_paid',
                paymentMethod,
                paidBy: adminId,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            results.success.push(bookingId);

        } catch (error: any) {
            results.failed.push({ bookingId, reason: error.message });
        }
    }

    // Log bulk action
    await logAdminAction(adminId, 'bulk_payout_paid', 'multiple', {
        successCount: results.success.length,
        failedCount: results.failed.length,
        paymentMethod
    });

    return results;
});

// ============================================================================
// PAYOUT ANALYTICS
// ============================================================================

/**
 * Get payout analytics
 */
export const getPayoutAnalytics = functions.region('asia-south1').https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { startDate, endDate } = data;

    let query = db.collection('bookings')
        .where('payment.status', '==', 'paid');

    if (startDate) {
        query = query.where('payment.paidAt', '>=', admin.firestore.Timestamp.fromDate(new Date(startDate)));
    }

    if (endDate) {
        query = query.where('payment.paidAt', '<=', admin.firestore.Timestamp.fromDate(new Date(endDate)));
    }

    const snapshot = await query.get();

    let totalRevenue = 0;
    let totalPlatformFee = 0;
    let totalTechnicianPayout = 0;
    let totalPaid = 0;
    let totalPending = 0;
    let totalOnHold = 0;

    const technicianStats: { [key: string]: any } = {};

    snapshot.docs.forEach(doc => {
        const booking = doc.data() as Booking;
        const total = booking.payout?.totalAmount || 0;
        const platformFee = booking.payout?.platformFee || 0;
        const techAmount = booking.payout?.technicianAmount || 0;

        totalRevenue += total;
        totalPlatformFee += platformFee;
        totalTechnicianPayout += techAmount;

        if (booking.payout?.status === 'paid') {
            totalPaid += techAmount;
        } else if (booking.payout?.status === 'on_hold') {
            totalOnHold += techAmount;
        } else {
            totalPending += techAmount;
        }

        // Technician stats
        const techId = booking.technicianId || 'unknown';
        if (!technicianStats[techId]) {
            technicianStats[techId] = {
                technicianId: techId,
                technicianName: booking.technicianName || 'Unknown',
                totalEarnings: 0,
                totalPaid: 0,
                totalPending: 0,
                bookingsCount: 0
            };
        }

        technicianStats[techId].totalEarnings += techAmount;
        technicianStats[techId].bookingsCount++;

        if (booking.payout?.status === 'paid') {
            technicianStats[techId].totalPaid += techAmount;
        } else {
            technicianStats[techId].totalPending += techAmount;
        }
    });

    return {
        overview: {
            totalRevenue,
            totalPlatformFee,
            totalTechnicianPayout,
            totalPaid,
            totalPending,
            totalOnHold,
            bookingsCount: snapshot.size
        },
        topTechnicians: Object.values(technicianStats)
            .sort((a: any, b: any) => b.totalEarnings - a.totalEarnings)
            .slice(0, 10)
    };
});
