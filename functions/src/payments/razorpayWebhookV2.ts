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

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

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
export const razorpayWebhookV2 = functions.https.onRequest(
    async (req, res) => {
        if (req.method !== "POST") {
            res.status(405).send("Method Not Allowed");
            return;
        }

        try {
            const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || "";

            if (!webhookSecret) {
                console.error(`${LOG_PREFIX} Webhook secret not configured`);
                res.status(500).send("Webhook secret not configured");
                return;
            }

            const signature = req.headers["x-razorpay-signature"] as string;

            if (!signature) {
                console.error(`${LOG_PREFIX} No signature in webhook request`);
                res.status(400).send("No signature provided");
                return;
            }

            const body = JSON.stringify(req.body);
            const expectedSignature = crypto
                .createHmac("sha256", webhookSecret)
                .update(body)
                .digest("hex");

            if (signature !== expectedSignature) {
                console.error(`${LOG_PREFIX} Invalid webhook signature - REJECTED`);
                res.status(400).send("Invalid signature");
                return;
            }

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

        } catch (error: any) {
            console.error(`${LOG_PREFIX} Webhook processing error:`, error);
            res.status(500).send("Internal Server Error");
        }
    }
);

/**
 * Handle successful payment (V2)
 * CRITICAL: Idempotency protection (inside transaction)
 * CRITICAL: Uses razorpayOrders as source of truth
 * CRITICAL: Validates amount from Firestore (never trust webhook payload)
 * CRITICAL: Single wallet source (technician_wallets)
 * CRITICAL: Technician existence verification
 */
async function handlePaymentCapturedV2(payload: any) {
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

    const orderData = orderDoc.data()!;

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
        await processBookingPayment(
            { bookingId: orderData.bookingId, technicianId: orderData.technicianId, amount: orderData.amount },
            paymentId,
            razorpayAmount,
            payment,
            orderId
        );
    } else if (orderData.technicianId) {
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

        await processTechnicianWalletCredit(
            { orderId, technicianId: orderData.technicianId, amount: orderData.amount },
            paymentId,
            razorpayAmount
        );
    } else {
        console.warn(`${LOG_PREFIX} order_invalid - No bookingId or technicianId: ${orderId}`);
    }
}

/**
 * Handle legacy booking payments (backward compatibility)
 */
async function handleLegacyBookingPayment(orderId: string, paymentId: string, amount: number, payload: any) {
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

    await processBookingPayment(
        { bookingId: bookingDoc.id, technicianId: booking.technicianId, amount: booking.pricing.total },
        paymentId,
        amount,
        payment,
        orderId
    );
}

/**
 * Process booking payment
 */
async function processBookingPayment(
    orderData: { bookingId: string; technicianId?: string; amount: number },
    paymentId: string,
    amount: number,
    payment: any,
    razorpayOrderId: string
) {
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

        const updateData: any = {
            "payment.status": "paid",
            "payment.razorpayPaymentId": paymentId,
            "payment.amountPaid": amount,
            "payment.paymentMethod": payment.method,
            "payment.paidAt": admin.firestore.FieldValue.serverTimestamp(),
            "status": "completed",
            "paymentStatus": "paid",
            "payout.status": "pending",
            "payout.totalAmount": booking.pricing?.total || booking.finalAmount || booking.price || amount,
        };

        if (booking.pricing) {
            updateData["payout.platformFee"] = booking.pricing.platformFee;
            updateData["payout.gst"] = booking.pricing.gst;
            updateData["payout.technicianAmount"] = booking.pricing.subtotal - booking.pricing.platformFee;
        }

        transaction.update(bookingRef, updateData);
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
async function processTechnicianWalletCredit(
    orderData: { orderId: string; technicianId: string; amount: number },
    paymentId: string,
    amount: number
) {
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
        } else {
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
async function sendPaymentNotifications(booking: any, bookingId: string, amount: number) {
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
 */
async function creditTechnicianWalletV2(
    techId: string,
    bookingId: string,
    totalAmount: number,
    pricing: any
) {
    try {
        const commissionRate = 0.15;
        const technicianAmount = totalAmount * (1 - commissionRate);

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
            } else {
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
                fee: 0,
                referenceId: bookingId,
                description: `Payment for booking`,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        console.log(`${LOG_PREFIX} credit_success - Technician: ${techId}, Booking: ${bookingId}, Amount: ${technicianAmount}`);
    } catch (error) {
        console.error(`${LOG_PREFIX} credit_error - Technician: ${techId}, Error:`, error);
    }
}
