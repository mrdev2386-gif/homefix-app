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
exports.confirmQRPayment = exports.generateTechnicianQR = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const notify = __importStar(require("../shared/notification_helper"));
const db = admin.firestore();
// ==========================================
// GENERATE TECHNICIAN QR CODE
// ==========================================
exports.generateTechnicianQR = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const techId = context.auth.uid;
    const techDoc = await db.collection('technicians').doc(techId).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician not found');
    }
    const techData = techDoc.data();
    const upiId = techData.upiId || `${techId}@homefix`;
    const qrData = `upi://pay?pa=${upiId}&pn=${encodeURIComponent(techData.name || 'Technician')}&cu=INR`;
    await techDoc.ref.update({
        walletQRData: qrData,
        walletQRUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, qrData };
});
// ==========================================
// CONFIRM QR PAYMENT (Called by Technician after scanning)
// FIX 2: NEVER trust client-provided amount - use booking.finalAmount
// ==========================================
exports.confirmQRPayment = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const technicianId = context.auth.uid;
    const { bookingId, customerId } = data;
    // NOTE: amount parameter is ignored for security - we fetch from Firestore
    if (!bookingId || !customerId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    const now = admin.firestore.FieldValue.serverTimestamp();
    // RUN ATOMIC TRANSACTION
    try {
        await db.runTransaction(async (transaction) => {
            // 1. Get Booking
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingDoc = await transaction.get(bookingRef);
            if (!bookingDoc.exists) {
                throw new Error('Booking not found');
            }
            const booking = bookingDoc.data();
            // Security Checks
            if (booking.technicianId !== technicianId) {
                throw new Error('Not your booking');
            }
            if (booking.customerId !== customerId) {
                throw new Error('Customer ID mismatch');
            }
            if (booking.status !== 'awaiting_customer_payment') {
                throw new Error('Booking is not in awaiting_payment status');
            }
            if (booking.paymentStatus === 'paid') {
                throw new Error('Already paid');
            }
            // FIX 2: CRITICAL SECURITY - Never trust client amount, use booking amount
            const finalAmount = booking.finalAmount || booking.price || 0;
            if (finalAmount <= 0) {
                throw new Error('Invalid booking amount');
            }
            // 2. Deduct from Customer Balance (Ledger-based)
            // This will throw if insufficient funds
            const { updateWalletBalance } = await Promise.resolve().then(() => __importStar(require('../finance/wallet_logic')));
            await updateWalletBalance(transaction, customerId, -finalAmount, 'booking_payment_qr', bookingId, `Payment for service ${booking.serviceName}`);
            // 3. Update Booking Status
            transaction.update(bookingRef, {
                status: 'completed',
                paymentStatus: 'paid',
                paymentMethod: 'wallet_qr',
                paidAt: now,
                completedAt: now,
                updatedAt: now
            });
        });
        // 4. Get booking again to get finalAmount for technician earning
        const bookingDoc = await db.collection('bookings').doc(bookingId).get();
        const booking = bookingDoc.data();
        const finalAmount = booking.finalAmount || booking.price || 0;
        // 5. Release Payout to Technician (using server-side amount)
        const { processTechnicianEarning } = await Promise.resolve().then(() => __importStar(require('../finance/wallet_logic')));
        await processTechnicianEarning(bookingId, technicianId, finalAmount, customerId);
        await notify.notifyCustomerPaymentSuccess(customerId, bookingId, finalAmount);
        await notify.notifyTechnicianNewPayment(technicianId, bookingId, finalAmount);
        return { success: true, status: 'completed' };
    }
    catch (err) {
        console.error('[confirmQRPayment] failed:', err);
        throw new functions.https.HttpsError('failed-precondition', err.message);
    }
});
//# sourceMappingURL=payment_qr.js.map