"use strict";
/**
 * CRITICAL FIX: Customer Payment Confirmation
 *
 * This function handles the final payment confirmation after service completion.
 *
 * FLOW:
 * 1. Customer confirms payment (online or cash)
 * 2. Booking status: awaiting_payment → paid
 * 3. Technician wallet credited atomically
 * 4. Booking marked as completed
 * 5. Notifications sent
 *
 * SAFETY:
 * - Idempotent: Cannot pay twice
 * - Atomic: Wallet credit happens with booking update
 * - Validated: Only assigned technician's booking
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
exports.adminConfirmPayment = exports.customerConfirmPayment = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("../shared/security");
const notification_helper_1 = require("../shared/notification_helper");
const db = admin.firestore();
/**
 * CRITICAL: Customer confirms payment for completed service
 *
 * Called after service completion when customer pays (online or cash)
 * Updates booking to "paid" and credits technician wallet
 */
exports.customerConfirmPayment = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('✅ [customerConfirmPayment] Auth UID:', context.auth?.uid);
    const uid = context.auth?.uid;
    if (!uid) {
        console.error('❌ [customerConfirmPayment] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
    }
    const { bookingId, paymentMethod } = data;
    if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'bookingId is required');
    }
    if (!paymentMethod || !['online', 'cash', 'after_service'].includes(paymentMethod)) {
        throw new functions.https.HttpsError('invalid-argument', 'paymentMethod must be "online", "cash", or "after_service"');
    }
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
        console.error('❌ [customerConfirmPayment] Booking not found:', bookingId);
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }
    const booking = bookingSnap.data();
    // CRITICAL: Verify customer owns this booking
    if (booking.customerId !== uid) {
        console.error('❌ [customerConfirmPayment] Permission denied - customer mismatch');
        throw new functions.https.HttpsError('permission-denied', 'You can only confirm payment for your own bookings');
    }
    // CRITICAL: Verify booking is in awaiting_payment status
    const currentStatus = booking.bookingStatus || booking.status;
    if (currentStatus !== 'awaiting_payment') {
        console.error('❌ [customerConfirmPayment] Invalid status:', currentStatus);
        throw new functions.https.HttpsError('failed-precondition', `Cannot confirm payment for booking in status: ${currentStatus}`);
    }
    // CRITICAL: Prevent duplicate payment
    if (booking.paymentStatus === 'paid' || booking.payment?.status === 'paid') {
        console.warn('⚠️ [customerConfirmPayment] Booking already paid - returning success');
        return {
            success: true,
            message: 'Payment already confirmed',
            bookingStatus: 'paid',
            isDuplicate: true
        };
    }
    const amount = booking.finalAmount || booking.price || 0;
    const technicianId = booking.technicianId;
    if (!technicianId) {
        console.error('❌ [customerConfirmPayment] No technician assigned');
        throw new functions.https.HttpsError('failed-precondition', 'No technician assigned to this booking');
    }
    if (amount <= 0) {
        console.error('❌ [customerConfirmPayment] Invalid amount:', amount);
        throw new functions.https.HttpsError('failed-precondition', 'Invalid booking amount');
    }
    try {
        // ATOMIC TRANSACTION: Update booking + credit wallet
        await db.runTransaction(async (transaction) => {
            // STEP 1: Verify booking hasn't been paid already (double-check in transaction)
            const freshBooking = await transaction.get(bookingRef);
            if (!freshBooking.exists) {
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            }
            const freshData = freshBooking.data();
            if (freshData.paymentStatus === 'paid' || freshData.payment?.status === 'paid') {
                throw new Error('ALREADY_PAID');
            }
            // STEP 2: Update booking status to "paid"
            console.log(`💾 [customerConfirmPayment] Updating booking ${bookingId} to paid status`);
            transaction.update(bookingRef, {
                bookingStatus: 'paid',
                paymentStatus: 'paid',
                'payment.status': 'paid',
                'payment.paidAt': admin.firestore.FieldValue.serverTimestamp(),
                'payment.paymentMethod': paymentMethod,
                'payment.confirmedBy': uid,
                'payment.amountPaid': amount,
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // STEP 3: Credit technician wallet (CRITICAL)
            console.log(`💰 [customerConfirmPayment] Crediting technician ${technicianId} with ₹${amount}`);
            const walletRef = db.collection('technician_wallets').doc(technicianId);
            const walletDoc = await transaction.get(walletRef);
            if (!walletDoc.exists) {
                // Auto-create wallet if doesn't exist
                console.log(`📝 [customerConfirmPayment] Creating wallet for technician ${technicianId}`);
                transaction.set(walletRef, {
                    availableBalance: amount,
                    pendingBalance: 0,
                    lifetimeEarnings: amount,
                    lastPayoutAt: null,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
            else {
                // Increment existing balance
                transaction.update(walletRef, {
                    availableBalance: admin.firestore.FieldValue.increment(amount),
                    lifetimeEarnings: admin.firestore.FieldValue.increment(amount),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            // STEP 4: Log transaction in wallet subcollection
            const transactionRef = walletRef.collection('transactions').doc();
            transaction.set(transactionRef, {
                type: 'credit',
                source: 'booking',
                status: 'completed',
                amount,
                fee: 0,
                referenceId: bookingId,
                description: `Payment for booking ${bookingId}`,
                customerId: uid,
                paymentMethod,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // STEP 5: Log payment confirmation
            const paymentLogRef = db.collection('payment_logs').doc();
            transaction.set(paymentLogRef, {
                bookingId,
                customerId: uid,
                technicianId,
                amount,
                paymentMethod,
                action: 'payment_confirmed',
                confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log(`✅ [customerConfirmPayment] Transaction complete for booking ${bookingId}`);
        });
        // STEP 6: Send notifications (non-blocking)
        try {
            // Notify technician
            const techDoc = await db.collection('technicians').doc(technicianId).get();
            const techData = techDoc.data();
            if (techData?.fcmToken) {
                console.log(`📲 [customerConfirmPayment] Notifying technician ${technicianId}`);
                await (0, notification_helper_1.sendNotificationToToken)({
                    token: techData.fcmToken,
                    title: 'Payment Received',
                    body: `Payment of ₹${amount} received for booking ${bookingId}`,
                    data: {
                        bookingId,
                        type: 'payment_confirmed',
                        amount: amount.toString(),
                    },
                });
            }
            // Notify customer
            const customerDoc = await db.collection('customers').doc(uid).get();
            const customerData = customerDoc.data();
            if (customerData?.fcmToken) {
                console.log(`📲 [customerConfirmPayment] Notifying customer ${uid}`);
                await (0, notification_helper_1.sendNotificationToToken)({
                    token: customerData.fcmToken,
                    title: 'Payment Confirmed',
                    body: `Your payment of ₹${amount} has been confirmed. Thank you!`,
                    data: {
                        bookingId,
                        type: 'payment_confirmed',
                        amount: amount.toString(),
                    },
                });
            }
        }
        catch (notifError) {
            console.warn('⚠️ [customerConfirmPayment] Notification error (non-fatal):', notifError);
            // Don't throw - notifications are non-critical
        }
        console.log(`✅ [customerConfirmPayment] SUCCESS - Booking ${bookingId} paid, wallet credited`);
        return {
            success: true,
            message: 'Payment confirmed successfully',
            bookingStatus: 'paid',
            amount,
            technicianId
        };
    }
    catch (error) {
        if (error.message === 'ALREADY_PAID') {
            console.log(`⚠️ [customerConfirmPayment] Booking already paid (idempotent)`);
            return {
                success: true,
                message: 'Payment already confirmed',
                bookingStatus: 'paid',
                isDuplicate: true
            };
        }
        console.error('❌ [customerConfirmPayment] Transaction error:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Failed to confirm payment');
    }
}));
/**
 * ADMIN: Manually confirm payment (for cash payments verified by admin)
 */
exports.adminConfirmPayment = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('✅ [adminConfirmPayment] Auth UID:', context.auth?.uid);
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
    }
    // Verify admin
    const adminDoc = await db.collection('admins').doc(uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can confirm payments');
    }
    const { bookingId, paymentMethod = 'cash' } = data;
    if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'bookingId is required');
    }
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }
    const booking = bookingSnap.data();
    const amount = booking.finalAmount || booking.price || 0;
    const technicianId = booking.technicianId;
    const customerId = booking.customerId;
    // Same transaction logic as customerConfirmPayment
    await db.runTransaction(async (transaction) => {
        const freshBooking = await transaction.get(bookingRef);
        if (freshBooking.data()?.paymentStatus === 'paid') {
            throw new Error('ALREADY_PAID');
        }
        transaction.update(bookingRef, {
            bookingStatus: 'paid',
            paymentStatus: 'paid',
            'payment.status': 'paid',
            'payment.paidAt': admin.firestore.FieldValue.serverTimestamp(),
            'payment.paymentMethod': paymentMethod,
            'payment.confirmedBy': uid,
            'payment.amountPaid': amount,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Credit wallet
        const walletRef = db.collection('technician_wallets').doc(technicianId);
        const walletDoc = await transaction.get(walletRef);
        if (!walletDoc.exists) {
            transaction.set(walletRef, {
                availableBalance: amount,
                pendingBalance: 0,
                lifetimeEarnings: amount,
                lastPayoutAt: null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        else {
            transaction.update(walletRef, {
                availableBalance: admin.firestore.FieldValue.increment(amount),
                lifetimeEarnings: admin.firestore.FieldValue.increment(amount),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        // Log transaction
        const transactionRef = walletRef.collection('transactions').doc();
        transaction.set(transactionRef, {
            type: 'credit',
            source: 'booking',
            status: 'completed',
            amount,
            fee: 0,
            referenceId: bookingId,
            description: `Payment for booking ${bookingId} (confirmed by admin)`,
            customerId,
            paymentMethod,
            confirmedBy: uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });
    console.log(`✅ [adminConfirmPayment] Payment confirmed by admin for booking ${bookingId}`);
    return {
        success: true,
        message: 'Payment confirmed by admin',
        bookingStatus: 'paid',
        amount
    };
}));
//# sourceMappingURL=customer_payment_confirmation.js.map