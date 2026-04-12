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
exports.onTechnicianProfileUpdateRiskCheck = exports.onPaymentStatusRiskCheck = exports.onReviewRiskCheck = exports.onBookingStatusUpdateRiskCheck = void 0;
exports.evaluateTechnicianRejectionRisk = evaluateTechnicianRejectionRisk;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const risk_engine_1 = require("./shared/risk_engine");
const db = admin.firestore();
/**
 * 1. EXCESSIVE CANCELLATIONS & REFUND GAMING
 * Triggered on booking update to check for cancellations
 */
exports.onBookingStatusUpdateRiskCheck = functions.firestore
    .document('bookings/{bookingId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after)
        return;
    // --- CUSTOMER RISK ---
    // Detect Cancellation
    if (before.status !== 'cancelled' && after.status === 'cancelled' && after.cancelledBy === 'customer') {
        const customerId = after.customerId;
        await evaluateCustomerCancellationRisk(customerId);
    }
    // Detect Refund
    if (before.paymentStatus !== 'refunded' && after.paymentStatus === 'refunded') {
        const customerId = after.customerId;
        await evaluateCustomerRefundRisk(customerId);
    }
    // --- TECHNICIAN RISK ---
    // Detect No-Show (Assigned but cancelled without progression)
    if (after.status === 'cancelled' && after.cancelledBy === 'system' && after.assignedTechnicianId) {
        // Assume system cancels if tech doesn't show up after X time
        await (0, risk_engine_1.updateRiskProfile)(after.assignedTechnicianId, 'technician', risk_engine_1.RISK_INCREMENTS.MEDIUM, 'no_show_suspected');
    }
    // Detect Service Completed Unusually Fast
    if (before.status !== 'completed' && after.status === 'completed') {
        const startTime = after.startedAt?.toDate();
        const endTime = after.completedAt?.toDate();
        if (startTime && endTime) {
            const durationMinutes = (endTime.getTime() - startTime.getTime()) / (1000 * 60);
            if (durationMinutes < 5) { // Threshold for fake completion
                await (0, risk_engine_1.updateRiskProfile)(after.assignedTechnicianId, 'technician', risk_engine_1.RISK_INCREMENTS.MEDIUM, 'fake_completion_suspected', { durationMinutes });
            }
        }
    }
});
/**
 * 2. RATING ABUSE
 * Triggered when a new review is added
 */
exports.onReviewRiskCheck = functions.firestore
    .document('reviews/{reviewId}')
    .onCreate(async (snap, context) => {
    const review = snap.data();
    if (!review)
        return;
    const { rating, customerId, reviewText } = review;
    // Detect Low Rating Pattern without text
    if (rating <= 2 && (!reviewText || reviewText.length < 5)) {
        const lastReviews = await db.collection('reviews')
            .where('customerId', '==', customerId)
            .orderBy('createdAt', 'desc')
            .limit(5)
            .get();
        const lowRatings = lastReviews.docs.filter(d => (d.data().rating <= 2 && !d.data().reviewText));
        if (lowRatings.length >= 3) {
            await (0, risk_engine_1.updateRiskProfile)(customerId, 'customer', risk_engine_1.RISK_INCREMENTS.MEDIUM, 'rating_abuse', { count: lowRatings.length });
        }
    }
});
/**
 * 3. PAYMENT ABUSE
 * Triggered on failed payment record
 */
exports.onPaymentStatusRiskCheck = functions.firestore
    .document('payments/{paymentId}')
    .onCreate(async (snap, context) => {
    const payment = snap.data();
    if (payment?.status === 'failed') {
        const userId = payment.userId;
        const recentFailures = await db.collection('payments')
            .where('userId', '==', userId)
            .where('status', '==', 'failed')
            .orderBy('createdAt', 'desc')
            .limit(10)
            .get();
        if (recentFailures.size >= 3) {
            await (0, risk_engine_1.updateRiskProfile)(userId, 'customer', risk_engine_1.RISK_INCREMENTS.MEDIUM, 'payment_abuse');
        }
    }
});
// --- INTERNAL EVALUATION HELPERS ---
async function evaluateCustomerCancellationRisk(customerId) {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const recentBookings = await db.collection('bookings')
        .where('customerId', '==', customerId)
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
        .get();
    const cancellations = recentBookings.docs.filter(d => d.data().status === 'cancelled' && d.data().cancelledBy === 'customer');
    const totalCount = recentBookings.size;
    const cancellationRate = totalCount > 0 ? (cancellations.length / totalCount) : 0;
    if (cancellations.length >= 3 || (totalCount >= 5 && cancellationRate > 0.5)) {
        await (0, risk_engine_1.updateRiskProfile)(customerId, 'customer', risk_engine_1.RISK_INCREMENTS.MEDIUM, 'high_cancellation', { rate: cancellationRate, count: cancellations.length });
    }
}
async function evaluateCustomerRefundRisk(customerId) {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const recentRefunds = await db.collection('bookings')
        .where('customerId', '==', customerId)
        .where('paymentStatus', '==', 'refunded')
        .where('updatedAt', '>=', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .get();
    if (recentRefunds.size >= 3) {
        await (0, risk_engine_1.updateRiskProfile)(customerId, 'customer', risk_engine_1.RISK_INCREMENTS.MEDIUM, 'refund_gaming');
    }
}
/**
 * 4. TECHNICIAN REJECTION ABUSE & STATUS MONITORING
 */
exports.onTechnicianProfileUpdateRiskCheck = functions.firestore
    .document('technicians/{techId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after)
        return;
    const techId = context.params.techId;
    // If tech was restricted/suspended by risk engine, propagate to availability
    const riskDoc = await db.collection('risk_profiles').doc(techId).get();
    if (riskDoc.exists) {
        const risk = riskDoc.data();
        if ((risk.status === 'suspended' || risk.status === 'restricted') && after.isAvailable === true) {
            await db.collection('technicians').doc(techId).update({
                isAvailable: false,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    }
});
// Hook for Rejection Analysis
async function evaluateTechnicianRejectionRisk(techId) {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    // This is a simplified check. Ideally we track rejections in a subcollection or counter.
    // For now, let's look at bookings where this tech was the lastRejectedTechId
    const recentRejections = await db.collection('bookings')
        .where('lastRejectedTechId', '==', techId)
        .where('updatedAt', '>=', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .get();
    // We also need total assignments to calculate rate, but that's hard to get history of without a log.
    // Let's just catch excessive raw rejections for now.
    if (recentRejections.size >= 5) {
        await (0, risk_engine_1.updateRiskProfile)(techId, 'technician', risk_engine_1.RISK_INCREMENTS.MINOR, 'frequent_rejections', { count: recentRejections.size });
    }
}
//# sourceMappingURL=fraud_protection.js.map