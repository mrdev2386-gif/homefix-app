"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.markBookingActive = exports.updateBookingPayment = exports.rejectBooking = exports.approveBooking = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("../shared/security");
const status_history_tracker_1 = require("../shared/status_history_tracker");
const db = admin.firestore();
// Normalize booking status to handle different variations
function normalizeBookingStatus(status) {
    if (!status)
        return '';
    return status.toLowerCase()
        .replace(/[-\s]/g, '_')
        .replace(/pending_admin.*/, 'pending_admin_approval');
}
async function assertAdmin(uid) {
    if (!uid)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    // Use custom claims for admin verification
    const userRecord = await admin.auth().getUser(uid);
    if (!userRecord.customClaims?.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }
}
async function sendNotification(userId, userType, payload) {
    try {
        const tokensSnap = await db.collection(userType === 'customer' ? 'users' : 'technicians')
            .doc(userId)
            .collection('fcmTokens')
            .where('isActive', '==', true)
            .get();
        const tokens = tokensSnap.docs.map(doc => doc.data().token).filter(Boolean);
        if (tokens.length > 0) {
            const messaging = admin.messaging();
            await messaging.sendEachForMulticast({
                tokens,
                notification: {
                    title: payload.title,
                    body: payload.body,
                },
                data: payload.data || {},
            });
        }
    }
    catch (error) {
        console.error('Error sending notification:', error);
    }
}
exports.approveBooking = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    const uid = context.auth?.uid;
    await assertAdmin(uid);
    const { bookingId } = data;
    if (!bookingId)
        throw new functions.https.HttpsError('invalid-argument', 'Missing bookingId');
    const bookingRef = db.collection('bookings').doc(bookingId);
    try {
        await db.runTransaction(async (t) => {
            const bookingDoc = await t.get(bookingRef);
            if (!bookingDoc.exists)
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            const booking = bookingDoc.data();
            const normalizedStatus = normalizeBookingStatus(booking.status);
            if (!['pending_admin_approval', 'pending_admin_review', 'pending_admin'].includes(normalizedStatus)) {
                throw new functions.https.HttpsError('failed-precondition', `Booking is not pending approval. Current status: ${booking.status}`);
            }
            // Use status history tracker for atomic update
            (0, status_history_tracker_1.updateBookingStatus)(t, bookingRef, 'ASSIGNED', booking, {
                bookingStatus: 'approved_by_admin',
                technicianId: booking.technicianId,
                adminApprovedAt: admin.firestore.FieldValue.serverTimestamp(),
                adminApprovedBy: uid,
            });
            // Log activity
            t.set(db.collection('activity_logs').doc(), {
                actorType: 'admin',
                actorUid: uid,
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
    }
    catch (error) {
        console.error('Error approving booking:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message);
    }
}));
exports.rejectBooking = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    const uid = context.auth?.uid;
    await assertAdmin(uid);
    const { bookingId, reason } = data;
    if (!bookingId)
        throw new functions.https.HttpsError('invalid-argument', 'Missing bookingId');
    const bookingRef = db.collection('bookings').doc(bookingId);
    try {
        await db.runTransaction(async (t) => {
            const bookingDoc = await t.get(bookingRef);
            if (!bookingDoc.exists)
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            const booking = bookingDoc.data();
            const normalizedStatus = normalizeBookingStatus(booking.status);
            if (!['pending_admin_approval', 'pending_admin_review', 'pending_admin'].includes(normalizedStatus)) {
                throw new functions.https.HttpsError('failed-precondition', `Booking is not pending approval. Current status: ${booking.status}`);
            }
            // Use status history tracker for atomic update
            (0, status_history_tracker_1.updateBookingStatus)(t, bookingRef, 'CANCELLED', booking, {
                cancellationReason: (0, security_1.sanitize)(reason) || 'Rejected by admin',
                cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
                cancelledBy: uid,
            });
            // Log activity
            t.set(db.collection('activity_logs').doc(), {
                actorType: 'admin',
                actorUid: uid,
                action: 'booking_rejected',
                entityId: bookingId,
                entityType: 'booking',
                metadata: { bookingId, customerId: booking.customerId, reason: (0, security_1.sanitize)(reason) },
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
    }
    catch (error) {
        console.error('Error rejecting booking:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message);
    }
}));
exports.updateBookingPayment = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    const uid = context.auth?.uid;
    await assertAdmin(uid);
    const { bookingId, paymentStatus } = data;
    if (!bookingId)
        throw new functions.https.HttpsError('invalid-argument', 'Missing bookingId');
    if (!paymentStatus)
        throw new functions.https.HttpsError('invalid-argument', 'Missing paymentStatus');
    const bookingRef = db.collection('bookings').doc(bookingId);
    try {
        await db.runTransaction(async (t) => {
            const bookingDoc = await t.get(bookingRef);
            if (!bookingDoc.exists)
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            const booking = bookingDoc.data();
            t.update(bookingRef, {
                paymentStatus: paymentStatus,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                ...(paymentStatus === 'PAID' && { paidAt: admin.firestore.FieldValue.serverTimestamp() })
            });
            // Log activity
            t.set(db.collection('activity_logs').doc(), {
                actorType: 'admin',
                actorUid: uid,
                action: 'payment_status_updated',
                entityId: bookingId,
                entityType: 'booking',
                metadata: { bookingId, paymentStatus, customerId: booking.customerId },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        return { success: true, message: 'Payment status updated successfully' };
    }
    catch (error) {
        console.error('Error updating payment status:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message);
    }
}));
exports.markBookingActive = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    const uid = context.auth?.uid;
    await assertAdmin(uid);
    const { bookingId } = data;
    if (!bookingId)
        throw new functions.https.HttpsError('invalid-argument', 'Missing bookingId');
    const bookingRef = db.collection('bookings').doc(bookingId);
    try {
        await db.runTransaction(async (t) => {
            const bookingDoc = await t.get(bookingRef);
            if (!bookingDoc.exists)
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            const booking = bookingDoc.data();
            if (booking.status !== 'TECHNICIAN_ACCEPTED') {
                throw new functions.https.HttpsError('failed-precondition', 'Booking must be accepted by technician first');
            }
            // Use status history tracker for atomic update
            (0, status_history_tracker_1.updateBookingStatus)(t, bookingRef, 'IN_PROGRESS', booking, {
                serviceStartedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Log activity
            t.set(db.collection('activity_logs').doc(), {
                actorType: 'admin',
                actorUid: uid,
                action: 'booking_started',
                entityId: bookingId,
                entityType: 'booking',
                metadata: { bookingId, customerId: booking.customerId, technicianId: booking.technicianId },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        return { success: true, message: 'Booking marked as active successfully' };
    }
    catch (error) {
        console.error('Error marking booking active:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message);
    }
}));
//# sourceMappingURL=booking_moderation.js.map