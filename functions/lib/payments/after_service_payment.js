"use strict";
/**
 * After-Service Payment Confirmation
 *
 * SECURITY:
 * - Only technician or admin can confirm payment received
 * - Validates booking exists and is completed
 * - Validates payment method is after_service
 * - Updates payment status atomically
 */
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
exports.confirmAfterServicePayment = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const config_1 = require("../shared/config");
const security_1 = require("../shared/security");
const utils_1 = require("../shared/utils");
const status_history_tracker_1 = require("../shared/status_history_tracker");
/**
 * Confirm after-service payment received
 * Called by technician after customer pays in cash/UPI/other method
 */
exports.confirmAfterServicePayment = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { bookingId } = data;
    const uid = context.auth.uid;
    if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'bookingId is required');
    }
    // Get booking
    const bookingRef = config_1.db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }
    const booking = bookingDoc.data();
    // Check if user is technician or admin
    const isTechnician = booking.technicianId === uid;
    const adminDoc = await config_1.db.collection('admins').doc(uid).get();
    const isAdmin = adminDoc.exists;
    if (!isTechnician && !isAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Only assigned technician or admin can confirm payment');
    }
    // Validate booking status
    if (booking.status !== 'service_completed' && booking.bookingStatus !== 'service_completed') {
        throw new functions.https.HttpsError('failed-precondition', 'Service must be completed before confirming payment');
    }
    // Validate payment method
    const paymentMethod = booking.payment?.paymentMethod || booking.paymentMethod;
    if (paymentMethod !== 'after_service') {
        throw new functions.https.HttpsError('failed-precondition', 'This booking is not set for after-service payment');
    }
    // Check if already paid
    const isPaid = booking.payment?.status === 'paid' || booking.paymentStatus === 'paid';
    if (isPaid) {
        throw new functions.https.HttpsError('already-exists', 'Payment already confirmed');
    }
    const amount = booking.pricing?.total || booking.finalAmount || booking.price || 0;
    // Update booking with payment confirmation using transaction and helper
    await config_1.db.runTransaction(async (transaction) => {
        const freshDoc = await transaction.get(bookingRef);
        if (!freshDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }
        const freshBooking = freshDoc.data();
        // Use updateBookingStatus helper to ensure both status and bookingStatus are updated
        (0, status_history_tracker_1.updateBookingStatus)(transaction, bookingRef, 'completed', freshBooking, {
            'payment.status': 'paid',
            'payment.paidAt': admin.firestore.FieldValue.serverTimestamp(),
            'payment.confirmedBy': uid,
            'payment.amountPaid': amount,
            'paymentStatus': 'paid',
            'completedAt': admin.firestore.FieldValue.serverTimestamp(),
        });
    });
    // Log payment confirmation
    await config_1.db.collection('payment_logs').add({
        bookingId,
        amount,
        action: 'after_service_payment_confirmed',
        confirmedBy: uid,
        confirmedByRole: isTechnician ? 'technician' : 'admin',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    // Send notification to customer
    await config_1.db.collection('notifications').add({
        userId: booking.customerId,
        title: 'Payment Confirmed',
        body: `Your payment of ₹${amount} has been confirmed. Thank you!`,
        type: 'payment_confirmed',
        bookingId,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    utils_1.logger.info('after_service_payment_confirmed', { bookingId, amount, confirmedBy: uid });
    return {
        success: true,
        message: 'Payment confirmed successfully',
        bookingStatus: 'completed'
    };
}));
//# sourceMappingURL=after_service_payment.js.map