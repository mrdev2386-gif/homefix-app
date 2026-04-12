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
exports.processBookingPayout = exports.adjustWallet = exports.refundBooking = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const config_1 = require("../shared/config");
const utils_1 = require("./utils");
const security_1 = require("../shared/security");
exports.refundBooking = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { bookingId } = data;
    const bookingRef = config_1.db.collection('bookings').doc(bookingId);
    const booking = await bookingRef.get();
    if (!booking.exists)
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    const b = booking.data();
    if (b.paymentStatus !== 'paid') {
        throw new functions.https.HttpsError('failed-precondition', 'Booking is not paid');
    }
    await config_1.db.runTransaction(async (t) => {
        const userRef = config_1.db.collection('customers').doc(b.customerId);
        // const userDoc = await t.get(userRef);
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
    await (0, utils_1.logAdminAction)(context.auth.uid, 'booking_refund', bookingId);
    return { success: true };
}));
exports.adjustWallet = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { userId, type, amount, reason } = data; // type: 'credit' | 'debit'
    const ref = config_1.db.collection('technicians').doc(userId); // Or customers? Let's assume tech for now or handle both
    const user = await ref.get();
    if (!user.exists) {
        const cust = await config_1.db.collection('customers').doc(userId).get();
        if (!cust.exists)
            throw new functions.https.HttpsError('not-found', 'User not found');
        // Handle customer adjustment
        await config_1.db.runTransaction(async (t) => {
            t.update(cust.ref, { walletBalance: admin.firestore.FieldValue.increment(type === 'credit' ? amount : -amount) });
            t.set(cust.ref.collection('wallet_transactions').doc(), {
                type, amount, description: (0, security_1.sanitize)(reason), status: 'completed', createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
    }
    else {
        // Technician adjustment
        await config_1.db.runTransaction(async (t) => {
            t.update(ref, { walletBalance: admin.firestore.FieldValue.increment(type === 'credit' ? amount : -amount) });
            t.set(ref.collection('wallet_transactions').doc(), {
                type, amount, description: (0, security_1.sanitize)(reason), status: 'completed', createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
    }
    await (0, utils_1.logAdminAction)(context.auth.uid, `wallet_${type}`, userId, { amount, reason: (0, security_1.sanitize)(reason) });
    return { success: true };
}));
/**
 * Process a booking payout - marks it as completed
 * Requirements: 4.2, 4.3, 15.1, 15.4, 15.8, 16.1, 16.5, 16.6
 */
exports.processBookingPayout = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    // Verify admin authentication
    await (0, utils_1.assertAdmin)(context);
    const { payoutId } = data;
    // Validate input
    if (!payoutId) {
        throw new functions.https.HttpsError('invalid-argument', 'payoutId is required');
    }
    try {
        // Use transaction to ensure atomicity
        const result = await config_1.db.runTransaction(async (transaction) => {
            const payoutRef = config_1.db.collection('bookingPayouts').doc(payoutId);
            const payoutDoc = await transaction.get(payoutRef);
            // Validate payout exists
            if (!payoutDoc.exists) {
                throw new Error('Payout not found');
            }
            const payoutData = payoutDoc.data();
            // Validate payout status is pending
            if (payoutData.status !== 'pending') {
                throw new Error(`Payout is not in pending status. Current status: ${payoutData.status}`);
            }
            // Update payout status to completed
            transaction.update(payoutRef, {
                status: 'completed',
                paidAt: admin.firestore.FieldValue.serverTimestamp(),
                processedBy: context.auth.uid
            });
            // Create audit log entry atomically
            const auditLogRef = config_1.db.collection('auditLogs').doc();
            transaction.set(auditLogRef, {
                adminId: context.auth.uid,
                adminName: context.auth.token.name || 'Unknown Admin',
                adminEmail: context.auth.token.email || '',
                actionType: 'payout_processed',
                entityType: 'booking_payout',
                entityId: payoutId,
                metadata: {
                    bookingId: payoutData.bookingId,
                    technicianId: payoutData.technicianId,
                    technicianName: payoutData.technicianName,
                    amount: payoutData.technicianEarning,
                    bookingAmount: payoutData.bookingAmount,
                    platformCommission: payoutData.platformCommissionAmount
                },
                ipAddress: context.rawRequest?.ip || 'unknown',
                userAgent: context.rawRequest?.headers['user-agent'] || 'unknown',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            return payoutData;
        });
        return {
            success: true,
            message: 'Payout processed successfully',
            payout: result
        };
    }
    catch (error) {
        console.error('[processBookingPayout] Error:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Failed to process payout');
    }
}));
//# sourceMappingURL=finance.js.map