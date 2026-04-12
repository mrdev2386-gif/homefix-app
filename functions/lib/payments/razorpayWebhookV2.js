"use strict";
/**
 * Razorpay Webhook Handler (1st Gen) - FINTECH GRADE
 *
 * SECURITY HARDENING:
 * - Signature verification
 * - Idempotency protection (inside transaction)
 * - Replay attack prevention (24h window)
 * - Event filtering (payment.captured only)
 * - Currency & amount validation
 * - Technician existence verification
 * - Single wallet source of truth (technician_wallets)
 * - Structured security logging
 * - Retry-safe HTTP responses (200 for safe ignores)
 * - Defensive null safety for malformed payloads
 * - Wallet auto-create inside transaction
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
exports.razorpayWebhookV2 = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
// Replay window: 24 hours in milliseconds
const REPLAY_WINDOW_MS = 24 * 60 * 60 * 1000;
// Log prefix for security events
const LOG_PREFIX = "[RAZORPAY_WEBHOOK]";
/**
 * Razorpay Webhook Handler (Gen1) - Production Secure
 */
exports.razorpayWebhookV2 = functions.https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
        res.status(405).send("Method Not Allowed");
        return;
    }
    try {
        const config = functions.config();
        const webhookSecret = config.razorpay?.webhook_secret || '';
        if (!webhookSecret) {
            console.error(`${LOG_PREFIX} Webhook secret not configured`);
            res.status(500).send("Webhook secret not configured");
            return;
        }
        const signature = req.headers["x-razorpay-signature"];
        if (!signature) {
            console.error(`${LOG_PREFIX} No signature in webhook request`);
            res.status(400).send("No signature provided");
            return;
        }
        // CRITICAL: Use raw body for signature verification, NOT JSON.stringify
        // Razorpay signature is computed on the raw request body
        const body = req.rawBody || JSON.stringify(req.body);
        const expectedSignature = crypto
            .createHmac("sha256", webhookSecret)
            .update(body)
            .digest("hex");
        if (signature !== expectedSignature) {
            console.error(`${LOG_PREFIX} Invalid webhook signature - REJECTED`);
            console.error(`${LOG_PREFIX} Expected: ${expectedSignature.substring(0, 10)}..., Received: ${signature.substring(0, 10)}...`);
            // Log invalid signature attempt
            await db.collection("payment_logs").add({
                action: "webhook_invalid_signature",
                expectedSignature: expectedSignature.substring(0, 10) + "...",
                receivedSignature: signature.substring(0, 10) + "...",
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            }).catch(err => console.error(`${LOG_PREFIX} Failed to log invalid signature:`, err));
            res.status(400).send("Invalid signature");
            return;
        }
        console.log(`${LOG_PREFIX} Signature verified successfully`);
        // STEP 5: DEFENSIVE NULL SAFETY - Validate payload structure
        const event = req.body.event;
        const payloadPayment = req.body.payload?.payment;
        const payment = payloadPayment?.entity;
        // Log with structured format
        console.log(`${LOG_PREFIX} Event: ${event}, Payment ID: ${payment?.id}`);
        // Check for missing payment entity
        if (!payment) {
            console.warn(`${LOG_PREFIX} missing_payment_entity - No payment entity in payload`);
            // Still return 200 because signature was valid - this is a Razorpay issue, not fraud
            res.status(200).send("OK");
            return;
        }
        // Validate required payment fields
        if (!payment.id) {
            console.warn(`${LOG_PREFIX} missing_payment_id - Payment ID missing`);
            res.status(200).send("OK");
            return;
        }
        if (typeof payment.amount === 'undefined') {
            console.warn(`${LOG_PREFIX} missing_amount - Amount missing from payment`);
            res.status(200).send("OK");
            return;
        }
        if (!payment.currency) {
            console.warn(`${LOG_PREFIX} missing_currency - Currency missing from payment`);
            res.status(200).send("OK");
            return;
        }
        if (typeof payment.captured === 'undefined') {
            console.warn(`${LOG_PREFIX} missing_captured_flag - Captured flag missing from payment`);
            res.status(200).send("OK");
            return;
        }
        // STEP 1: RETRY-SAFE EVENT FILTERING - Only process payment.captured
        if (event !== "payment.captured") {
            console.log(`${LOG_PREFIX} event_ignored - Event: ${event}`);
            // Safe to retry - Razorpay will retry non-payment events
            res.status(200).send("OK");
            return;
        }
        if (payment.status !== "captured") {
            console.log(`${LOG_PREFIX} status_ignored - Payment status: "${payment.status}"`);
            // Payment not captured - safe to ignore, not fraud
            res.status(200).send("OK");
            return;
        }
        if (payment.captured !== true) {
            console.log(`${LOG_PREFIX} captured_flag_false - Payment captured flag is false`);
            // Not captured - safe to ignore
            res.status(200).send("OK");
            return;
        }
        // REPLAY ATTACK PREVENTION - 24h window check
        if (payment.created_at) {
            const paymentCreatedAt = payment.created_at * 1000;
            const now = Date.now();
            const timeDiff = now - paymentCreatedAt;
            if (timeDiff > REPLAY_WINDOW_MS) {
                console.warn(`${LOG_PREFIX} replay_rejected - Payment older than 24h. ID: ${payment.id}, Age: ${Math.round(timeDiff / (1000 * 60 * 60))}h`);
                await db.collection("payment_logs").add({
                    webhookEvent: event,
                    paymentId: payment.id,
                    action: "replay_rejected",
                    paymentCreatedAt: new Date(paymentCreatedAt).toISOString(),
                    receivedAt: new Date().toISOString(),
                    ageHours: Math.round(timeDiff / (1000 * 60 * 60)),
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
                // Return 200 to prevent Razorpay retry storms for old payments
                res.status(200).send("OK");
                return;
            }
        }
        await handlePaymentCapturedV2(req.body.payload);
        res.status(200).send("OK");
    }
    catch (error) {
        console.error(`${LOG_PREFIX} Webhook processing error:`, error);
        res.status(500).send("Internal Server Error");
    }
});
/**
 * Handle successful payment (V2)
 * CRITICAL: Idempotency protection (inside transaction)
 * CRITICAL: Uses razorpayOrders as source of truth
 * CRITICAL: Validates amount from Firestore (never trust webhook payload)
 * CRITICAL: Single wallet source (technician_wallets)
 * CRITICAL: Technician existence verification
 */
async function handlePaymentCapturedV2(payload) {
    // STEP 5: Additional null safety for handlePaymentCapturedV2
    const payment = payload?.payment?.entity;
    if (!payment) {
        console.error(`${LOG_PREFIX} handlePaymentCapturedV2 - No payment entity in payload`);
        return;
    }
    const orderId = payment?.order_id;
    const paymentId = payment?.id;
    const razorpayAmount = (payment?.amount ?? 0) / 100;
    const razorpayCurrency = payment?.currency || "";
    // NEW: Check if this is a QR wallet payment (no order_id)
    if (!orderId && payment?.notes?.paymentType === 'wallet_credit') {
        console.log(`${LOG_PREFIX} Detected QR wallet payment - Payment ID: ${paymentId}`);
        await handleQRWalletPayment(payment, paymentId, razorpayAmount);
        return;
    }
    if (!orderId) {
        console.error(`${LOG_PREFIX} missing_order_id - Cannot process payment without order ID`);
        await db.collection("payment_logs").add({
            paymentId: paymentId,
            action: "missing_order_id",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return;
    }
    console.log(`${LOG_PREFIX} credit_attempt - Payment: ${paymentId}, Order: ${orderId}, Amount: ${razorpayAmount}, Currency: ${razorpayCurrency}`);
    // STEP 4: Currency Validation - MUST be INR
    if (razorpayCurrency.toUpperCase() !== "INR") {
        console.warn(`${LOG_PREFIX} currency_mismatch - Expected: INR, Received: ${razorpayCurrency}, Payment: ${paymentId}`);
        await db.collection("payment_logs").add({
            orderId,
            paymentId,
            action: "currency_mismatch",
            expectedCurrency: "INR",
            receivedCurrency: razorpayCurrency,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        // Return 200 - currency mismatch is not fraud, just invalid for our system
        return;
    }
    // Amount must be > 0
    if (razorpayAmount <= 0) {
        console.warn(`${LOG_PREFIX} invalid_amount - Amount: ${razorpayAmount}, Payment: ${paymentId}`);
        return;
    }
    // STEP 7: Verify Razorpay Order Integrity - Load from razorpayOrders as SOURCE OF TRUTH
    const orderRef = db.collection("razorpayOrders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
        console.warn(`${LOG_PREFIX} order_not_found - Order: ${orderId}, attempting legacy payment`);
        await handleLegacyBookingPayment(orderId, paymentId, razorpayAmount, payload);
        return;
    }
    const orderData = orderDoc.data();
    // Verify order has required fields
    if (!orderData.orderId || !orderData.amount || !orderData.status) {
        console.warn(`${LOG_PREFIX} order_integrity_failed - Missing required fields, Order: ${orderId}`);
        await db.collection("payment_logs").add({
            orderId,
            paymentId,
            action: "order_integrity_failed",
            reason: "missing_required_fields",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        // Return early - invalid order data
        return;
    }
    // STEP 3: Idempotency check - Check if order is already paid
    if (orderData.status === "paid") {
        console.log(`${LOG_PREFIX} duplicate_ignored - Order already paid: ${orderId}`);
        // Log duplicate webhook detection
        await db.collection("payment_logs").add({
            orderId,
            paymentId: payment.id,
            action: "webhook_duplicate_ignored",
            reason: "Order already marked as paid",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        }).catch(err => console.error(`${LOG_PREFIX} Failed to log duplicate:`, err));
        // Already processed - safe to return 200, no need to retry
        return;
    }
    // STEP 4: Amount Validation - NEVER trust webhook payload
    const expectedAmount = orderData.amount;
    if (Math.abs(razorpayAmount - expectedAmount) > 0.01) {
        console.warn(`${LOG_PREFIX} amount_mismatch - Expected: ${expectedAmount}, Received: ${razorpayAmount}, Order: ${orderId}`);
        await db.collection("payment_logs").add({
            orderId,
            paymentId,
            action: "amount_mismatch",
            expectedAmount,
            receivedAmount: razorpayAmount,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        // Amount mismatch - could be fraud, but log and ignore safely
        return;
    }
    // Determine payment type
    if (orderData.bookingId) {
        await processBookingPayment({ bookingId: orderData.bookingId, technicianId: orderData.technicianId, amount: orderData.amount }, paymentId, razorpayAmount, payment, orderId);
    }
    else if (orderData.technicianId) {
        // STEP 5: Technician Existence & Wallet Guard
        const techRef = db.collection("technicians").doc(orderData.technicianId);
        const techDoc = await techRef.get();
        if (!techDoc.exists) {
            console.warn(`${LOG_PREFIX} technician_missing - Technician ID: ${orderData.technicianId}`);
            await db.collection("payment_logs").add({
                orderId,
                paymentId,
                action: "technician_not_found",
                technicianId: orderData.technicianId,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            // Technician not found - cannot credit wallet, but not fraud
            return;
        }
        const techData = techDoc.data();
        if (techData?.status === "suspended" || techData?.status === "deactivated") {
            console.warn(`${LOG_PREFIX} technician_rejected - Status: ${techData.status}, ID: ${orderData.technicianId}`);
            // Technician suspended - reject payment
            await db.collection("payment_logs").add({
                orderId,
                paymentId,
                action: "technician_suspended",
                technicianId: orderData.technicianId,
                status: techData.status,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            return;
        }
        await processTechnicianWalletCredit({ orderId, technicianId: orderData.technicianId, amount: orderData.amount }, paymentId, razorpayAmount);
    }
    else {
        console.warn(`${LOG_PREFIX} order_invalid - No bookingId or technicianId: ${orderId}`);
    }
}
/**
 * Handle QR wallet payment with 10% platform fee
 * This is called when customer scans technician's wallet QR code
 */
async function handleQRWalletPayment(payment, paymentId, totalAmount) {
    const technicianId = payment.notes?.technicianId;
    if (!technicianId) {
        console.error(`${LOG_PREFIX} QR payment missing technicianId - Payment: ${paymentId}`);
        await db.collection("payment_logs").add({
            paymentId,
            action: "qr_payment_missing_technician",
            notes: payment.notes,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return;
    }
    console.log(`${LOG_PREFIX} qr_wallet_payment - Technician: ${technicianId}, Total: ${totalAmount}`);
    // Idempotency check - prevent duplicate processing
    const idempotencyRef = db.collection('payment_idempotency').doc(paymentId);
    const existingPayment = await idempotencyRef.get();
    if (existingPayment.exists) {
        console.log(`${LOG_PREFIX} duplicate_ignored - QR payment already processed: ${paymentId}`);
        return;
    }
    // Calculate platform fee (10%)
    const platformFeePercent = 0.10;
    const platformFee = totalAmount * platformFeePercent;
    const technicianAmount = totalAmount - platformFee;
    console.log(`${LOG_PREFIX} Fee calculation - Total: ${totalAmount}, Platform Fee (10%): ${platformFee}, Technician: ${technicianAmount}`);
    // Verify technician exists and is active
    const techDoc = await db.collection('technicians').doc(technicianId).get();
    if (!techDoc.exists) {
        console.error(`${LOG_PREFIX} technician_not_found - ID: ${technicianId}`);
        await db.collection("payment_logs").add({
            paymentId,
            action: "qr_technician_not_found",
            technicianId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return;
    }
    const techData = techDoc.data();
    if (techData?.status === 'suspended' || techData?.status === 'deactivated') {
        console.warn(`${LOG_PREFIX} technician_suspended - ID: ${technicianId}, Status: ${techData.status}`);
        await db.collection("payment_logs").add({
            paymentId,
            action: "qr_technician_suspended",
            technicianId,
            status: techData.status,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return;
    }
    // Atomic wallet credit with idempotency
    try {
        await db.runTransaction(async (transaction) => {
            // Mark payment as processed FIRST (idempotency)
            transaction.set(idempotencyRef, {
                paymentId,
                technicianId,
                totalAmount,
                platformFee,
                technicianAmount,
                paymentType: 'qr_wallet',
                processedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            const walletRef = db.collection('technician_wallets').doc(technicianId);
            const walletDoc = await transaction.get(walletRef);
            if (!walletDoc.exists) {
                // Create new wallet
                transaction.set(walletRef, {
                    availableBalance: technicianAmount,
                    pendingBalance: 0,
                    lifetimeEarnings: technicianAmount,
                    lastPayoutAt: null,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                console.log(`${LOG_PREFIX} wallet_created - Technician: ${technicianId}`);
            }
            else {
                // Update existing wallet
                transaction.update(walletRef, {
                    availableBalance: admin.firestore.FieldValue.increment(technicianAmount),
                    lifetimeEarnings: admin.firestore.FieldValue.increment(technicianAmount),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
            // Create transaction record
            const txnRef = walletRef.collection('transactions').doc();
            transaction.set(txnRef, {
                type: 'credit',
                source: 'qr_payment',
                status: 'completed',
                amount: technicianAmount,
                fee: platformFee,
                grossAmount: totalAmount,
                referenceId: paymentId,
                paymentId,
                description: `QR payment received (10% platform fee: ₹${platformFee.toFixed(2)})`,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        // Log platform fee collection
        await db.collection('platform_fees').add({
            paymentId,
            technicianId,
            source: 'qr_wallet_payment',
            totalAmount,
            feePercent: platformFeePercent,
            feeAmount: platformFee,
            technicianAmount,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        // Log successful payment
        await db.collection('payment_logs').add({
            paymentId,
            technicianId,
            action: 'qr_wallet_credit_success',
            totalAmount,
            platformFee,
            technicianAmount,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        // Send notification to technician
        await db.collection('notifications').add({
            userId: technicianId,
            title: 'Payment Received',
            body: `You received ₹${technicianAmount.toFixed(2)} via QR payment (₹${platformFee.toFixed(2)} platform fee deducted).`,
            type: 'qr_payment_received',
            data: {
                paymentId,
                totalAmount,
                platformFee,
                technicianAmount
            },
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`${LOG_PREFIX} qr_credit_success - Technician: ${technicianId}, Net: ₹${technicianAmount}, Fee: ₹${platformFee}`);
    }
    catch (error) {
        console.error(`${LOG_PREFIX} qr_payment_failed - Technician: ${technicianId}, Error:`, error);
        await db.collection('payment_logs').add({
            paymentId,
            technicianId,
            action: 'qr_wallet_credit_failed',
            error: error.message,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        throw error;
    }
}
/**
 * STEP 2: SHARED HELPER - Extract platform fee safely from multiple sources
 * This ensures consistent platform fee calculation across client verify and webhook
 */
function extractPlatformFeeSafely(booking) {
    let platformFee = 0;
    // Try pricing.platformFee first (preferred)
    if (booking.pricing && booking.pricing.platformFee != null) {
        platformFee = booking.pricing.platformFee;
    }
    // Fallback to flat platformFee field
    else if (booking.platformFee != null) {
        platformFee = booking.platformFee;
    }
    return platformFee;
}
/**
 * STEP 2: SHARED HELPER - Calculate technician amount safely
 * Ensures technician amount is never negative
 */
function calculateTechnicianAmountSafely(bookingTotal, platformFee, bookingId) {
    let technicianAmount = bookingTotal - platformFee;
    // Ensure never negative
    if (technicianAmount < 0) {
        console.warn(`[RAZORPAY] Negative technician amount prevented - Booking: ${bookingId}, Total: ${bookingTotal}, Fee: ${platformFee}`);
        technicianAmount = 0;
    }
    return technicianAmount;
}
/**
 * Handle legacy booking payments (backward compatibility)
 */
async function handleLegacyBookingPayment(orderId, paymentId, amount, payload) {
    const payment = payload?.payment?.entity;
    const idempotencyRef = db.collection("payment_idempotency").doc(paymentId);
    const existingIdempotency = await idempotencyRef.get();
    if (existingIdempotency.exists) {
        console.log(`${LOG_PREFIX} duplicate_ignored - Legacy payment already processed: ${paymentId}`);
        return;
    }
    const bookingsSnapshot = await db.collection("bookings")
        .where("payment.razorpayOrderId", "==", orderId)
        .limit(1)
        .get();
    if (bookingsSnapshot.empty) {
        console.warn(`${LOG_PREFIX} booking_not_found - Order: ${orderId}`);
        return;
    }
    const bookingDoc = bookingsSnapshot.docs[0];
    const booking = bookingDoc.data();
    if (booking.payment?.status === "paid") {
        console.log(`${LOG_PREFIX} duplicate_ignored - Booking already paid: ${bookingDoc.id}`);
        return;
    }
    await processBookingPayment({ bookingId: bookingDoc.id, technicianId: booking.technicianId, amount: booking.pricing.total }, paymentId, amount, payment, orderId);
}
/**
 * Process booking payment
 */
async function processBookingPayment(orderData, paymentId, amount, payment, razorpayOrderId) {
    const bookingRef = db.collection("bookings").doc(orderData.bookingId);
    const bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
        console.warn(`${LOG_PREFIX} booking_not_found - Booking: ${orderData.bookingId}`);
        return;
    }
    const bookingData = bookingDoc.data();
    if (!bookingData) {
        console.error(`${LOG_PREFIX} booking_data_missing - Booking ${bookingDoc.id} has no data`);
        return;
    }
    const booking = bookingData;
    if (booking.payment?.status === "paid") {
        console.log(`${LOG_PREFIX} duplicate_ignored - Booking already paid: ${orderData.bookingId}`);
        return;
    }
    // Use transaction for atomic update with idempotency inside
    await db.runTransaction(async (transaction) => {
        // Re-read booking inside transaction to check current state
        const currentBookingDoc = await transaction.get(bookingRef);
        if (!currentBookingDoc.exists) {
            console.error(`${LOG_PREFIX} booking_missing_in_transaction - Booking: ${orderData.bookingId}`);
            throw new Error("BOOKING_NOT_FOUND");
        }
        const currentBooking = currentBookingDoc.data();
        // Check if already paid inside transaction
        if (currentBooking?.payment?.status === "paid") {
            console.log(`${LOG_PREFIX} duplicate_ignored - Booking already paid in transaction: ${orderData.bookingId}`);
            throw new Error("IDEMPOTENCY_CHECK_FAILED");
        }
        // STEP 3: ADD PAYMENT PROCESSING LOCK (ANTI-RACE)
        // Prevent simultaneous client + webhook processing
        if (currentBooking?.payment?.status === 'processing') {
            console.log(`${LOG_PREFIX} webhook_concurrent_attempt - Payment already being processed: ${orderData.bookingId}`);
            // Log concurrent attempt
            transaction.set(db.collection('payment_logs').doc(), {
                bookingId: orderData.bookingId,
                orderId: razorpayOrderId,
                paymentId,
                status: 'webhook_concurrent_attempt',
                action: 'webhook_race_prevented',
                source: 'webhook',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            throw new Error("CONCURRENT_PROCESSING");
        }
        // Set processing lock before any updates
        transaction.update(bookingRef, {
            'payment.status': 'processing'
        });
        // Re-read order to check status inside transaction
        const orderRef = db.collection("razorpayOrders").doc(razorpayOrderId);
        const orderDoc = await transaction.get(orderRef);
        if (orderDoc.exists && orderDoc.data()?.status === "paid") {
            console.log(`${LOG_PREFIX} duplicate_ignored - Order already paid in transaction: ${razorpayOrderId}`);
            throw new Error("IDEMPOTENCY_CHECK_FAILED");
        }
        // Mark order as paid FIRST to prevent race conditions
        if (orderDoc.exists) {
            transaction.update(orderRef, {
                status: "paid",
                paymentId,
                paidAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        const updateData = {
            "payment.status": "paid",
            "payment.razorpayPaymentId": paymentId,
            "payment.amountPaid": amount,
            "payment.paymentMethod": payment.method,
            "payment.paidAt": admin.firestore.FieldValue.serverTimestamp(),
            "paymentStatus": "paid",
            "payout.status": "pending",
            "payout.totalAmount": booking.pricing?.total || booking.finalAmount || booking.price || amount,
        };
        // Determine status based on payment method
        const paymentMethod = booking.payment?.paymentMethod || booking.paymentMethod || 'after_service';
        if (paymentMethod === 'online') {
            // Online payment: move to confirmed (ready for service)
            updateData["status"] = "confirmed";
            updateData["bookingStatus"] = "confirmed";
        }
        else {
            // After-service payment: mark as completed
            updateData["status"] = "completed";
            updateData["bookingStatus"] = "completed";
        }
        if (booking.pricing) {
            updateData["payout.platformFee"] = booking.pricing.platformFee;
            updateData["payout.gst"] = booking.pricing.gst;
            updateData["payout.technicianAmount"] = booking.pricing.subtotal - booking.pricing.platformFee;
        }
        transaction.update(bookingRef, updateData);
        // STEP 5: LOG ALL EDGE EVENTS - Log webhook processing
        transaction.set(db.collection('payment_logs').doc(), {
            bookingId: orderData.bookingId,
            orderId: razorpayOrderId,
            paymentId,
            amount,
            action: 'webhook_processed',
            method: payment?.method,
            source: 'webhook',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    });
    if (orderData.technicianId) {
        await creditTechnicianWalletV2(orderData.technicianId, orderData.bookingId, amount, booking.pricing);
    }
    await db.collection("payment_logs").add({
        bookingId: orderData.bookingId,
        orderId: razorpayOrderId,
        paymentId,
        amount,
        action: "payment_captured_v2",
        method: payment?.method,
        walletCredited: !!orderData.technicianId,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await sendPaymentNotifications(booking, orderData.bookingId, amount);
    console.log(`${LOG_PREFIX} credit_success - Booking: ${orderData.bookingId}, Amount: ${amount}`);
}
/**
 * Process technician wallet credit
 * CRITICAL: Uses atomic transaction to prevent double credit
 */
async function processTechnicianWalletCredit(orderData, paymentId, amount) {
    const { technicianId, orderId } = orderData;
    console.log(`${LOG_PREFIX} credit_attempt - Technician: ${technicianId}, Amount: ${amount}`);
    // STEP 2: WALLET AUTO-CREATE GUARD - Use transaction for atomic wallet credit
    await db.runTransaction(async (transaction) => {
        // Re-read order inside transaction for idempotency
        const orderRef = db.collection("razorpayOrders").doc(orderId);
        const orderDoc = await transaction.get(orderRef);
        if (orderDoc.exists && orderDoc.data()?.status === "paid") {
            console.log(`${LOG_PREFIX} duplicate_ignored - Order already paid in transaction: ${orderId}`);
            throw new Error("IDEMPOTENCY_CHECK_FAILED");
        }
        // Mark order as paid FIRST to prevent race conditions
        if (orderDoc.exists) {
            transaction.update(orderRef, {
                status: "paid",
                paymentId,
                paidAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        const walletRef = db.collection("technician_wallets").doc(technicianId);
        const walletDoc = await transaction.get(walletRef);
        // STEP 2: Wallet Auto-Create - Create if doesn't exist, update if exists
        if (!walletDoc.exists) {
            // Create new wallet document with initial balance
            transaction.set(walletRef, {
                availableBalance: amount,
                pendingBalance: 0,
                lifetimeEarnings: amount,
                lastPayoutAt: null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log(`${LOG_PREFIX} wallet_created - New wallet for technician: ${technicianId}`);
        }
        else {
            // Increment existing balance atomically
            transaction.update(walletRef, {
                availableBalance: admin.firestore.FieldValue.increment(amount),
                lifetimeEarnings: admin.firestore.FieldValue.increment(amount),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        const txnRef = db.collection("technician_wallets").doc(technicianId)
            .collection("transactions").doc();
        transaction.set(txnRef, {
            type: "credit",
            source: "razorpay",
            status: "completed",
            amount: amount,
            fee: 0,
            referenceId: orderId,
            paymentId,
            description: "Wallet credit via Razorpay",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    });
    await db.collection("payment_logs").add({
        orderId,
        paymentId,
        technicianId,
        amount,
        action: "wallet_credit_v2",
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await db.collection("notifications").add({
        userId: technicianId,
        title: "Wallet Credited",
        body: `Your wallet has been credited with ₹${amount}.`,
        type: "wallet_credit",
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`${LOG_PREFIX} credit_success - Wallet credited for technician: ${technicianId}, Amount: ${amount}`);
}
/**
 * Send payment notifications
 */
async function sendPaymentNotifications(booking, bookingId, amount) {
    await db.collection("notifications").add({
        userId: booking.customerId,
        title: "Payment Successful",
        body: `We've received your payment of ₹${amount} for booking #${booking.bookingNumber}. Thank you!`,
        type: "payment_success",
        bookingId,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    if (booking.technicianId) {
        await db.collection("notifications").add({
            userId: booking.technicianId,
            title: "Payment Received",
            body: `Customer has paid for booking #${booking.bookingNumber}. Your payout is now pending.`,
            type: "payment_received",
            bookingId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }
}
/**
 * Credit technician wallet after booking payment
 * STEP 1: Uses safe platform fee extraction and prevents negative amounts
 */
async function creditTechnicianWalletV2(techId, bookingId, totalAmount, pricing) {
    try {
        // STEP 1: FIX PLATFORM FEE SOURCE - Safe extraction from multiple sources
        let platformFee = 0;
        if (pricing && pricing.platformFee != null) {
            platformFee = pricing.platformFee;
        }
        // Calculate technician amount
        let technicianAmount = totalAmount - platformFee;
        // STEP 1: Ensure technicianAmount NEVER negative
        if (technicianAmount < 0) {
            console.warn(`${LOG_PREFIX} Negative technician amount prevented in wallet credit - Booking: ${bookingId}, Total: ${totalAmount}, Fee: ${platformFee}`);
            technicianAmount = 0;
            // Log edge case
            await db.collection('payment_logs').add({
                bookingId,
                technicianId: techId,
                status: 'negative_amount_prevented',
                action: 'wallet_credit_edge_case',
                totalAmount,
                platformFee,
                source: 'webhook',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            }).catch(err => console.error(`${LOG_PREFIX} Failed to log edge case:`, err));
        }
        const walletRef = db.collection('technician_wallets').doc(techId);
        const txnRef = walletRef.collection('transactions').doc();
        await db.runTransaction(async (transaction) => {
            const walletDoc = await transaction.get(walletRef);
            if (!walletDoc.exists) {
                // STEP 2: Wallet Auto-Create with proper initial values
                transaction.set(walletRef, {
                    availableBalance: technicianAmount,
                    pendingBalance: 0,
                    lifetimeEarnings: technicianAmount,
                    lastPayoutAt: null,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
            else {
                // Increment existing balance atomically
                transaction.update(walletRef, {
                    availableBalance: admin.firestore.FieldValue.increment(technicianAmount),
                    lifetimeEarnings: admin.firestore.FieldValue.increment(technicianAmount),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
            transaction.set(txnRef, {
                type: 'credit',
                source: 'booking',
                status: 'completed',
                amount: technicianAmount,
                fee: platformFee,
                referenceId: bookingId,
                description: `Payment for booking`,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        console.log(`${LOG_PREFIX} credit_success - Technician: ${techId}, Booking: ${bookingId}, Amount: ${technicianAmount}, Platform Fee: ${platformFee}`);
    }
    catch (error) {
        console.error(`${LOG_PREFIX} credit_error - Technician: ${techId}, Error:`, error);
    }
}
//# sourceMappingURL=razorpayWebhookV2.js.map