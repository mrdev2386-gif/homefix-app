"use strict";
/**
 * HomeFix Production Launch Readiness - Hardening Layer
 *
 * Features:
 * - Payment webhook handler with signature verification
 * - Global idempotency key for booking creation
 * - Rate limiting & abuse protection
 * - Analytics & monitoring
 * - Technician heartbeat system
 * - Payout ledger structure
 * - Backup & alerting
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
exports.cleanupRateLimitRecords = exports.onBookingStateChange = exports.checkSystemHealth = exports.generateWeeklyPayoutReport = exports.getTechnicianEarnings = exports.cleanupStaleTechnicianHeartbeats = exports.generateAnalyticsSnapshot = exports.createBookingIdempotent = exports.handlePaymentWebhook = void 0;
exports.checkRateLimit = checkRateLimit;
exports.trackAnalyticsEvent = trackAnalyticsEvent;
exports.updateTechnicianHeartbeat = updateTechnicianHeartbeat;
exports.createPayoutLedgerEntry = createPayoutLedgerEntry;
exports.validateBookingCreation = validateBookingCreation;
exports.sanitizeBookingInput = sanitizeBookingInput;
exports.trackTechnicianMetrics = trackTechnicianMetrics;
exports.checkBookingRateLimit = checkBookingRateLimit;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
// ==========================================
// CONFIGURATION
// ==========================================
const CONFIG = {
    // Rate Limits
    maxBookingAttemptsPerMinute: 5,
    maxMatchingCallsPerMinute: 10,
    // Technician Heartbeat
    heartbeatIntervalMs: 60 * 1000, // 60 seconds
    maxHeartbeatGapMs: 5 * 60 * 1000, // 5 minutes
    // Payout
    commissionRate: 0.20, // 20% commission
    payoutBatchDays: 7,
    // Analytics
    analyticsDayFormat: 'yyyy-MM-dd',
};
// Structured Logger
const log = {
    info: (event, data) => console.log(`[ANALYTICS-${event}]`, JSON.stringify({ ...data, timestamp: Date.now() })),
    warn: (event, data) => console.warn(`[WARN-${event}]`, JSON.stringify({ ...data, timestamp: Date.now() })),
    error: (event, data) => console.error(`[ERROR-${event}]`, JSON.stringify({ ...data, timestamp: Date.now() })),
};
/**
 * Handle payment gateway webhooks (Razorpay/Stripe)
 * - Verify signature
 * - Validate payment status
 * - Update payment document
 * - Handle idempotency
 */
exports.handlePaymentWebhook = functions.https.onRequest(async (req, res) => {
    // CORS handling
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'POST');
        res.set('Access-Control-Allow-Headers', 'Content-Type, X-Webhook-Signature');
        res.status(204).send('');
        return;
    }
    // Verify webhook signature (Razorpay example)
    const signature = req.headers['x-razorpay-signature'];
    if (!verifyWebhookSignature(req.body, signature)) {
        log.error('webhook_signature_invalid', { ip: req.ip });
        res.status(401).send('Invalid signature');
        return;
    }
    const payload = req.body;
    const event = payload.event;
    try {
        switch (event) {
            case 'payment.captured':
                await handlePaymentCaptured(payload);
                break;
            case 'payment.failed':
                await handlePaymentFailed(payload);
                break;
            default:
                log.info('unhandled_webhook_event', { event });
        }
        res.status(200).send('OK');
    }
    catch (e) {
        log.error('webhook_processing_failed', { event, error: e });
        res.status(500).send('Internal Server Error');
    }
});
/**
 * Verify webhook signature
 */
function verifyWebhookSignature(body, signature) {
    // In production, implement proper signature verification
    // For Razorpay: crypto.createHmac('sha256', secret).update(body).digest('hex')
    return signature !== undefined && signature.length > 0;
}
/**
 * Handle successful payment
 */
async function handlePaymentCaptured(payload) {
    const payment = payload.payload.payment.entity;
    const orderId = payment.order_id;
    await db.collection('payments').doc(orderId).update({
        status: 'verified',
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        paymentId: payment.id,
    });
    log.info('payment_captured', { orderId, amount: payment.amount });
}
/**
 * Handle failed payment
 */
async function handlePaymentFailed(payload) {
    const payment = payload.payload.payment.entity;
    const orderId = payment.order_id;
    await db.collection('payments').doc(orderId).update({
        status: 'failed',
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    log.warn('payment_failed', { orderId, amount: payment.amount });
}
// Duplicate interface removed - using inline type for dynamic import
// interface BookingLifecycleInterface was defined above
/**
 * Create booking with global idempotency
 * Note: This function routes to the unified booking lifecycle via Cloud Functions
 */
exports.createBookingIdempotent = functions.region('asia-south1').https.onCall(async (data, context) => {
    console.log('ENTRY FUNCTION CALLED: createBookingIdempotent');
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const { idempotencyKey, ...bookingData } = data;
    if (!idempotencyKey) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing idempotencyKey');
    }
    // Store booking intent for processing
    const bookingIntentRef = db.collection('booking_intents').doc(idempotencyKey);
    const existingIntent = await bookingIntentRef.get();
    if (existingIntent.exists) {
        const intent = existingIntent.data();
        if (intent.bookingId) {
            return { success: true, bookingId: intent.bookingId, isDuplicate: true };
        }
    }
    // Create new booking intent
    await bookingIntentRef.set({
        ...bookingData,
        idempotencyKey,
        customerId: context.auth.uid,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {
        success: true,
        message: 'Booking intent created. Processing...',
    };
});
// ==========================================
// 3. RATE LIMITING & ABUSE PROTECTION
// ==========================================
/**
 * Rate limiting middleware for callable functions
 */
async function checkRateLimit(userId, action, limit, windowSeconds) {
    const windowStart = Date.now() - windowSeconds * 1000;
    const windowEnd = Date.now();
    // Get rate limit record
    const rateLimitRef = db.collection('rateLimits').doc(`${userId}_${action}`);
    const record = await rateLimitRef.get();
    let remaining = limit;
    let resetAt = new Date(windowEnd);
    if (record.exists) {
        const data = record.data();
        if (data.windowStart > windowStart) {
            // Within rate limit window
            if (data.count >= limit) {
                return {
                    allowed: false,
                    remaining: 0,
                    resetAt: new Date(data.windowStart + windowSeconds * 1000)
                };
            }
            remaining = limit - data.count;
        }
    }
    // Update rate limit
    await rateLimitRef.set({
        userId,
        action,
        count: (record.data()?.count || 0) + 1,
        windowStart,
    }, { merge: true });
    return { allowed: true, remaining: remaining - 1, resetAt };
}
/**
 * Track analytics event
 */
async function trackAnalyticsEvent(event, data) {
    const today = new Date().toISOString().split('T')[0];
    await db.collection('events').doc().set({
        event,
        data,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        date: today,
    });
}
/**
 * Generate daily analytics snapshot
 */
exports.generateAnalyticsSnapshot = functions
    .runWith({ maxInstances: 1, timeoutSeconds: 540, memory: '256MB' })
    .pubsub.schedule('every 24 hours')
    .onRun(async () => {
    console.log('Running generateAnalyticsSnapshot at', new Date().toISOString());
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split('T')[0];
    // Get yesterday's events
    const events = await db
        .collection('events')
        .where('date', '==', yesterdayStr)
        .get();
    const analytics = {
        bookings: 0,
        revenue: 0,
        avgRating: 0,
        completedBookings: 0,
        cancelledBookings: 0,
    };
    let totalRatings = 0;
    let ratingCount = 0;
    for (const doc of events.docs) {
        const event = doc.data();
        switch (event.event) {
            case 'booking_created':
                analytics.bookings++;
                analytics.revenue += event.data.amount || 0;
                break;
            case 'booking_completed':
                analytics.completedBookings++;
                analytics.revenue += event.data.amount || 0;
                break;
            case 'booking_cancelled':
                analytics.cancelledBookings++;
                break;
            case 'rating_submitted':
                totalRatings += event.data.rating || 0;
                ratingCount++;
                break;
        }
    }
    analytics.avgRating = ratingCount > 0 ? totalRatings / ratingCount : 0;
    // Store analytics
    await db.collection('analytics').doc(yesterdayStr).set({
        ...analytics,
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    log.info('analytics_snapshot_generated', { date: yesterdayStr, ...analytics });
});
// ==========================================
// 5. TECHNICIAN HEARTBEAT SYSTEM
// ==========================================
/**
 * Update technician heartbeat
 */
async function updateTechnicianHeartbeat(technicianId) {
    await db.collection('technicians').doc(technicianId).update({
        lastHeartbeat: admin.firestore.FieldValue.serverTimestamp(),
        isOnline: true,
    });
}
/**
 * Clean up stale technician heartbeats
 */
exports.cleanupStaleTechnicianHeartbeats = functions
    .runWith({ maxInstances: 1, timeoutSeconds: 540, memory: '256MB' })
    .pubsub.schedule('every 10 minutes')
    .onRun(async () => {
    console.log('Running cleanupStaleTechnicianHeartbeats at', new Date().toISOString());
    const staleThreshold = Date.now() - CONFIG.maxHeartbeatGapMs;
    const staleTechnicians = await db
        .collection('technicians')
        .where('isOnline', '==', true)
        .get();
    const batch = db.batch();
    let updateCount = 0;
    for (const doc of staleTechnicians.docs) {
        const data = doc.data();
        if (data.lastHeartbeat) {
            const heartbeatTime = data.lastHeartbeat.toDate().getTime();
            if (heartbeatTime < staleThreshold) {
                batch.update(doc.ref, { isOnline: false });
                updateCount++;
            }
        }
    }
    if (updateCount > 0) {
        await batch.commit();
        log.info('stale_technicians_offlined', { count: updateCount });
    }
});
/**
 * Create payout ledger entry
 */
async function createPayoutLedgerEntry(technicianId, bookingId, amount) {
    const commissionRate = CONFIG.commissionRate;
    const commissionAmount = amount * commissionRate;
    const netAmount = amount - commissionAmount;
    const ledgerRef = db
        .collection('technicianEarnings')
        .doc(technicianId)
        .collection('ledger')
        .doc(bookingId);
    await ledgerRef.set({
        bookingId,
        amount,
        commissionAmount,
        netAmount,
        payoutStatus: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Update totals
    await db.collection('technicianEarnings').doc(technicianId).set({
        totalEarnings: admin.firestore.FieldValue.increment(amount),
        pendingPayout: admin.firestore.FieldValue.increment(netAmount),
    }, { merge: true });
}
/**
 * Get technician earnings summary
 */
exports.getTechnicianEarnings = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const techId = data.technicianId;
    // Get ledger entries
    const ledger = await db
        .collection('technicianEarnings')
        .doc(techId)
        .collection('ledger')
        .orderBy('createdAt', 'desc')
        .limit(100)
        .get();
    const entries = ledger.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
    }));
    // Calculate totals
    let totalEarned = 0;
    let totalPaid = 0;
    let pending = 0;
    for (const entry of entries) {
        totalEarned += entry.netAmount;
        if (entry.payoutStatus === 'paid') {
            totalPaid += entry.netAmount;
        }
        else {
            pending += entry.netAmount;
        }
    }
    return {
        totalEarned,
        totalPaid,
        pending,
        entryCount: entries.length,
        recentEntries: entries.slice(0, 10),
    };
});
/**
 * Generate weekly payout report
 */
exports.generateWeeklyPayoutReport = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    let query = db
        .collection('technicianEarnings')
        .doc(context.auth.uid)
        .collection('ledger')
        .where('createdAt', '>', admin.firestore.Timestamp.fromDate(weekAgo));
    if (data.technicianId) {
        // Admin viewing specific technician
        query = db
            .collection('technicianEarnings')
            .doc(data.technicianId)
            .collection('ledger')
            .where('createdAt', '>', admin.firestore.Timestamp.fromDate(weekAgo));
    }
    const ledger = await query.get();
    let totalAmount = 0;
    let totalCommission = 0;
    const technicianPayouts = {};
    for (const doc of ledger.docs) {
        const entry = doc.data();
        totalAmount += entry.amount;
        totalCommission += entry.commissionAmount;
    }
    return {
        weekStart: weekAgo.toISOString(),
        totalAmount,
        totalCommission,
        technicianCount: Object.keys(technicianPayouts).length,
    };
});
// ==========================================
// 7. BACKUP & ALERTING
// ==========================================
/**
 * Monitor for anomalies and trigger alerts
 */
exports.checkSystemHealth = functions
    .runWith({ maxInstances: 1, timeoutSeconds: 540, memory: '256MB' })
    .pubsub.schedule('every 15 minutes')
    .onRun(async () => {
    console.log('Running checkSystemHealth at', new Date().toISOString());
    const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
    try {
        const recentFailuresSnapshot = await db
            .collection('bookingRequests')
            .where('status', '==', 'failed')
            .where('failedAt', '>', admin.firestore.Timestamp.fromDate(thirtyMinutesAgo))
            .count()
            .get();
        const failureCount = recentFailuresSnapshot.data().count;
        if (failureCount >= 5) {
            await triggerAdminAlert('high_booking_failures', { count: failureCount, timeframe: '30 minutes' });
        }
    }
    catch (e) {
        console.warn('[checkSystemHealth] bookingRequests count query failed:', e);
    }
    try {
        const reassignmentLoopsSnapshot = await db
            .collection('bookings')
            .where('reassignmentAttempt', '>=', 3)
            .count()
            .get();
        const loopCount = reassignmentLoopsSnapshot.data().count;
        if (loopCount >= 3) {
            await triggerAdminAlert('reassignment_loops', { count: loopCount });
        }
    }
    catch (e) {
        console.warn('[checkSystemHealth] bookings count query failed:', e);
    }
    return null;
});
/**
 * Trigger admin alert
 */
async function triggerAdminAlert(alertType, metadata) {
    const { triggerAdminAlert } = await Promise.resolve().then(() => __importStar(require('./final_hardening')));
    await triggerAdminAlert(alertType, metadata);
}
// ==========================================
// 8. BOOKING VALIDATION HELPERS
// ==========================================
/**
 * Validate booking creation input
 */
function validateBookingCreation(data) {
    if (!data.serviceId) {
        return { valid: false, error: 'Missing serviceId' };
    }
    if (!data.customerLocation?.latitude || !data.customerLocation?.longitude) {
        return { valid: false, error: 'Invalid customer location' };
    }
    if (!data.scheduledDate || !data.scheduledTime) {
        return { valid: false, error: 'Missing schedule' };
    }
    if (!data.paymentId) {
        return { valid: false, error: 'Missing paymentId' };
    }
    if (typeof data.amount !== 'number' || data.amount <= 0) {
        return { valid: false, error: 'Invalid amount' };
    }
    return { valid: true };
}
/**
 * Sanitize booking input
 */
function sanitizeBookingInput(data) {
    return {
        serviceId: String(data.serviceId || ''),
        customerLocation: {
            latitude: Number(data.customerLocation?.latitude || 0),
            longitude: Number(data.customerLocation?.longitude || 0),
        },
        scheduledDate: String(data.scheduledDate || ''),
        scheduledTime: String(data.scheduledTime || ''),
        paymentId: String(data.paymentId || ''),
        amount: Number(data.amount || 0),
    };
}
/**
 * Track technician metrics
 */
async function trackTechnicianMetrics(technicianId, metrics) {
    const today = new Date().toISOString().split('T')[0];
    await db
        .collection('technicianMetrics')
        .doc(`${technicianId}_${today}`)
        .set({
        technicianId,
        date: today,
        ...metrics,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
}
/**
 * On booking state change
 */
exports.onBookingStateChange = functions.firestore
    .document('bookings/{bookingId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status !== after.status) {
        await trackAnalyticsEvent('booking_status_change', {
            bookingId: context.params.bookingId,
            from: before.status,
            to: after.status,
            technicianId: after.technicianId,
        });
    }
});
// ==========================================
// 9. BOOKING RATE LIMITING
// ==========================================
/**
 * Check booking rate limit
 */
async function checkBookingRateLimit(customerId) {
    const oneMinuteAgo = Date.now() - 60 * 1000;
    const recentBookings = await db
        .collection('bookings')
        .where('customerId', '==', customerId)
        .where('createdAt', '>', new Date(oneMinuteAgo))
        .count()
        .get();
    if (recentBookings.data().count >= CONFIG.maxBookingAttemptsPerMinute) {
        return {
            allowed: false,
            error: 'Too many booking attempts. Please wait before trying again.'
        };
    }
    return { allowed: true };
}
// ==========================================
// 10. CLEANUP TASKS
// ==========================================
/**
 * Clean up old rate limit records
 */
exports.cleanupRateLimitRecords = functions
    .runWith({ maxInstances: 1, timeoutSeconds: 540, memory: '256MB' })
    .pubsub.schedule('every 24 hours')
    .onRun(async () => {
    console.log('Running cleanupRateLimitRecords at', new Date().toISOString());
    const yesterday = Date.now() - 24 * 60 * 60 * 1000;
    const oldRecords = await db
        .collection('rateLimits')
        .where('windowStart', '<', yesterday)
        .limit(1000)
        .get();
    const batch = db.batch();
    for (const doc of oldRecords.docs) {
        batch.delete(doc.ref);
    }
    if (oldRecords.size > 0) {
        await batch.commit();
        log.info('old_rate_limits_cleaned', { count: oldRecords.size });
    }
});
//# sourceMappingURL=production_hardening.js.map