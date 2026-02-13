/**
 * Razorpay Webhook Handler (2nd Gen)
 * Migrated from v1 with exact same business logic
 */

import { onRequest } from "firebase-functions/v2/https";
import * as https from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { Request, Response } from "express";

if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * Razorpay Webhook Handler (2nd Gen)
 * 
 * CRITICAL SECURITY:
 * - Verifies Razorpay signature
 * - Updates booking only after verification
 * - Handles payment.captured and payment.failed events
 */
export const razorpayWebhookV2 = onRequest(
    {
        region: "us-central1",
        memory: "512MiB",
        timeoutSeconds: 60,
        concurrency: 80,
        minInstances: 0,
    },
    async (req: Request, res: Response) => {
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
 */
async function handlePaymentCapturedV2(payload: any) {
    const payment = payload.payment.entity;
    const orderId = payment.order_id;
    const paymentId = payment.id;
    const amount = payment.amount / 100;

    console.log("Payment captured V2:", paymentId, "Order:", orderId, "Amount:", amount);

    // IDEMPOTENCY CHECK: Check if this payment was already processed
    const existingPaymentLog = await db.collection("payment_logs")
        .where("paymentId", "==", paymentId)
        .where("action", "==", "payment_captured_v2")
        .limit(1)
        .get();

    if (!existingPaymentLog.empty) {
        console.log("Payment already processed, skipping (idempotency check):", paymentId);
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

    // Log successful payment
    await db.collection("payment_logs").add({
        bookingId: bookingDoc.id,
        orderId,
        paymentId,
        amount,
        action: "payment_captured_v2",
        method: payment.method,
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
