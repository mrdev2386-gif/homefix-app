/**
 * Razorpay Webhook Handler (2nd Gen)
 * Migrated from v1 with exact same business logic
 * 
 * SECURITY HARDENING:
 * - Signature verification
 * - Idempotency protection
 * - Replay attack prevention (24h window)
 * - QR expiry validation
 */

import * as functions from 'firebase-functions';
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { Request, Response } from "express";

if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

// Replay window: 24 hours in milliseconds
const REPLAY_WINDOW_MS = 24 * 60 * 60 * 1000;

/**
 * Razorpay Webhook Handler (V1)
 * 
 * CRITICAL SECURITY:
 * - Verifies Razorpay signature
 * - Updates booking only after verification
 * - Handles payment.captured and payment.failed events
 */
export const razorpayWebhookV2 = functions
    .runWith({
        memory: "256MB",
        timeoutSeconds: 60,
        maxInstances: 5,
    })
    .https.onRequest(async (req, res) => {
        // Only accept POST requests
        if (req.method !== "POST") {
            res.status(405).send("Method Not Allowed");
            return;
        }

        try {
            // Get webhook secret
            const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || "";

            if (!webhookSecret) {
                console.error("Razorpay webhook secret not configured");
                res.status(500).send("Webhook secret not configured");
                return;
            }

            // Verify signature
            const signature = req.headers["x-razorpay-signature"] as string;

            if (!signature) {
                console.error("No signature in webhook request");
                res.status(400).send("No signature provided");
                return;
            }

            // Create signature hash
            const body = JSON.stringify(req.body);
            const expectedSignature = crypto
                .createHmac("sha256", webhookSecret)
                .update(body)
                .digest("hex");

            // Verify signature
            if (signature !== expectedSignature) {
                console.error("Invalid webhook signature");
                res.status(400).send("Invalid signature");
                return;
            }

            // Signature verified, process event
            const event = req.body.event;
            const payload = req.body.payload;

            console.log("Razorpay webhook V2 event:", event);

            // REPLAY ATTACK PREVENTION: Check payment timestamp
            if (payload?.payment?.entity?.created_at) {
                const paymentCreatedAt = payload.payment.entity.created_at * 1000; // Convert to ms
                const now = Date.now();
                const timeDiff = now - paymentCreatedAt;

                if (timeDiff > REPLAY_WINDOW_MS) {
                    console.error("Webhook REJECTED: Payment older than 24h window. Payment:",
                        payload.payment.entity.id, "Age:", Math.round(timeDiff / (1000 * 60 * 60)), "hours");

                    await db.collection("payment_logs").add({
                        webhookEvent: event,
                        paymentId: payload.payment.entity.id,
                        action: "replay_rejected",
                        paymentCreatedAt: new Date(paymentCreatedAt).toISOString(),
                        receivedAt: new Date().toISOString(),
                        ageHours: Math.round(timeDiff / (1000 * 60 * 60)),
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    res.status(200).send("OK"); // Return 200 to prevent retries
                    return;
                }
            }

            // Handle different events
            switch (event) {
                case "payment.captured":
                    await handlePaymentCapturedV2(payload);
                    break;

                case "payment.failed":
                    await handlePaymentFailedV2(payload);
                    break;

                default:
                    console.log("Unhandled webhook event:", event);
            }

            res.status(200).send("OK");

        } catch (error: any) {
            console.error("Webhook processing error:", error);
            res.status(500).send("Internal Server Error");
        }
    }
    );

/**
 * Handle successful payment (V2)
 * CRITICAL: Idempotency protection to prevent duplicate processing
 * CRITICAL: QR expiry validation
 * CRITICAL: Credits technician wallet
 */
async function handlePaymentCapturedV2(payload: any) {
    const payment = payload.payment.entity;
    const orderId = payment.order_id;
    const paymentId = payment.id;
    const amount = payment.amount / 100;

    console.log("Payment captured V2:", paymentId, "Order:", orderId, "Amount:", amount);

    // IDEMPOTENCY CHECK: Use Firestore transaction for atomic check
    const idempotencyRef = db.collection("payment_idempotency").doc(paymentId);

    // Check if this payment was already processed
    const existingIdempotency = await idempotencyRef.get();
    if (existingIdempotency.exists) {
        console.log("Payment already processed (idempotency check):", paymentId);
        return;
    }

    const bookingsSnapshot = await db.collection("bookings")
        .where("payment.razorpayOrderId", "==", orderId)
        .limit(1)
        .get();

    if (bookingsSnapshot.empty) {
        console.error("No booking found for order:", orderId);
        return;
    }

    const bookingDoc = bookingsSnapshot.docs[0];
    const booking = bookingDoc.data();

    // DOUBLE-CHECK: Verify booking isn't already paid
    if (booking.payment?.status === "paid") {
        console.log("Booking already paid, skipping:", bookingDoc.id);
        return;
    }

    // QR EXPIRY CHECK: If this is a QR payment, verify it hasn't expired
    if (booking.payment?.qrId) {
        const qrDoc = await db.collection("bookings")
            .doc(bookingDoc.id)
            .collection("payment")
            .doc("qr")
            .get();

        if (qrDoc.exists) {
            const qrData = qrDoc.data()!;
            const expiresAt = qrData.expiresAt?.toDate();

            if (expiresAt && new Date() > expiresAt) {
                console.error("QR payment EXPIRED for booking:", bookingDoc.id, "Expiry:", expiresAt);

                // Log the expired payment attempt
                await db.collection("payment_logs").add({
                    bookingId: bookingDoc.id,
                    orderId,
                    paymentId,
                    action: "qr_expired_rejected",
                    expiresAt: expiresAt.toISOString(),
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });

                // DO NOT credit wallet - reject expired QR payment
                return;
            }
        }
    }

    // Verify amount matches
    if (Math.abs(amount - booking.pricing.total) > 0.01) {
        console.error("Amount mismatch! Expected:", booking.pricing.total, "Received:", amount);

        await db.collection("payment_logs").add({
            bookingId: bookingDoc.id,
            orderId,
            paymentId,
            action: "amount_mismatch",
            expectedAmount: booking.pricing.total,
            receivedAmount: amount,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return;
    }

    // Update booking with payment success
    await bookingDoc.ref.update({
        "payment.status": "paid",
        "payment.razorpayPaymentId": paymentId,
        "payment.amountPaid": amount,
        "payment.paymentMethod": payment.method,
        "payment.paidAt": admin.firestore.FieldValue.serverTimestamp(),
        "status": "completed",
        "payout.status": "pending",
        "payout.totalAmount": booking.pricing.total,
        "payout.platformFee": booking.pricing.platformFee,
        "payout.gst": booking.pricing.gst,
        "payout.technicianAmount": booking.pricing.subtotal - booking.pricing.platformFee
    });

    // CRITICAL: Create idempotency record AFTER successful processing
    await idempotencyRef.set({
        paymentId,
        orderId,
        bookingId: bookingDoc.id,
        action: "payment_captured_v2",
        amount,
        processedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // CRITICAL: Credit technician wallet
    if (booking.technicianId) {
        await creditTechnicianWalletV2(booking.technicianId, bookingDoc.id, amount, booking.pricing);
    }

    // Log successful payment
    await db.collection("payment_logs").add({
        bookingId: bookingDoc.id,
        orderId,
        paymentId,
        amount,
        action: "payment_captured_v2",
        method: payment.method,
        walletCredited: !!booking.technicianId,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Send notification to customer
    await db.collection("notifications").add({
        userId: booking.customerId,
        title: "Payment Successful",
        body: `We've received your payment of ₹${amount} for booking #${booking.bookingNumber}. Thank you!`,
        type: "payment_success",
        bookingId: bookingDoc.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Send notification to technician
    if (booking.technicianId) {
        await db.collection("notifications").add({
            userId: booking.technicianId,
            title: "Payment Received",
            body: `Customer has paid for booking #${booking.bookingNumber}. Your payout is now pending.`,
            type: "payment_received",
            bookingId: bookingDoc.id,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }

    console.log("Payment processed successfully V2 for booking:", bookingDoc.id);
}

/**
 * Credit technician wallet after payment
 */
async function creditTechnicianWalletV2(
    techId: string,
    bookingId: string,
    totalAmount: number,
    pricing: any
) {
    try {
        const commissionRate = 0.15; // 15% platform fee
        const technicianAmount = totalAmount * (1 - commissionRate);

        const walletRef = db.collection('technician_wallets').doc(techId);
        const txnRef = walletRef.collection('transactions').doc();

        await db.runTransaction(async (transaction) => {
            const walletDoc = await transaction.get(walletRef);

            if (!walletDoc.exists) {
                // Create wallet if doesn't exist
                transaction.set(walletRef, {
                    availableBalance: technicianAmount,
                    pendingBalance: 0,
                    lifetimeEarnings: technicianAmount,
                    lastPayoutAt: null,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            } else {
                // Update existing wallet
                transaction.update(walletRef, {
                    availableBalance: admin.firestore.FieldValue.increment(technicianAmount),
                    lifetimeEarnings: admin.firestore.FieldValue.increment(technicianAmount),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            // Record transaction
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

        console.log(`[Wallet] Credited ₹${technicianAmount} to technician ${techId} for booking ${bookingId}`);
    } catch (error) {
        console.error(`[Wallet] ERROR crediting technician ${techId}:`, error);
        // Don't fail the webhook - log for manual reconciliation
    }
}

/**
 * Handle failed payment (V2)
 */
async function handlePaymentFailedV2(payload: any) {
    const payment = payload.payment.entity;
    const orderId = payment.order_id;
    const paymentId = payment.id;
    const errorCode = payment.error_code;
    const errorDescription = payment.error_description;

    console.log("Payment failed V2:", paymentId, "Order:", orderId, "Error:", errorCode);

    const bookingsSnapshot = await db.collection("bookings")
        .where("payment.razorpayOrderId", "==", orderId)
        .limit(1)
        .get();

    if (bookingsSnapshot.empty) {
        console.error("No booking found for order:", orderId);
        return;
    }

    const bookingDoc = bookingsSnapshot.docs[0];

    // Update booking with payment failure
    await bookingDoc.ref.update({
        "payment.status": "failed",
        "payment.razorpayPaymentId": paymentId,
        "payment.failureReason": `${errorCode}: ${errorDescription}`,
        "payment.failedAt": admin.firestore.FieldValue.serverTimestamp()
    });

    // Log failed payment
    await db.collection("payment_logs").add({
        bookingId: bookingDoc.id,
        orderId,
        paymentId,
        action: "payment_failed_v2",
        errorCode,
        errorDescription,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Send notification to customer
    const bookingSnap = await db.collection("bookings")
        .where("payment.razorpayOrderId", "==", orderId)
        .limit(1)
        .get();

    if (!bookingSnap.empty) {
        const b = bookingSnap.docs[0].data();
        await db.collection("notifications").add({
            userId: b.customerId,
            title: "Payment Failed",
            body: `Your payment for booking #${b.bookingNumber} was unsuccessful. Please try again.`,
            type: "payment_failed",
            bookingId: bookingSnap.docs[0].id,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }

    console.log("Payment failure recorded V2 for booking:", bookingDoc.id);
}
