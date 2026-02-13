/**
 * v2 HTTP Webhook Function Template
 * Migration from: functions.https.onRequest
 */

import { onRequest } from "firebase-functions/v2/https";
import * as https from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { Request, Response } from "express";

const db = admin.firestore();

/**
 * v2 Razorpay Payment Webhook Handler
 * 
 * Key Changes from v1:
 * 1. Import from 'firebase-functions/v2/https'
 * 2. Handler receives (req, res) as separate parameters
 * 3. Full control over CORS headers
 * 4. Access to raw body for signature verification
 */
export const handlePaymentWebhook = onRequest(
    {
        region: "us-central1",
        memory: "512MiB",
        timeoutSeconds: 30,
        minInstances: 3,      // Keep warm for payment reliability
        maxInstances: 500,    // Scale for webhook spikes
        concurrency: 100,      // Handle concurrent webhooks
    },
    async (req: Request, res: Response) => {
        // CORS handling
        res.set("Access-Control-Allow-Origin", "*");
        res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
        res.set("Access-Control-Allow-Headers", "Content-Type, X-Razorpay-Signature");

        if (req.method === "OPTIONS") {
            res.status(204).send("");
            return;
        }

        if (req.method !== "POST") {
            res.status(405).send("Method Not Allowed");
            return;
        }

        // Verify webhook signature
        const signature = req.headers["x-razorpay-signature"] as string;
        const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || "";

        if (!verifyRazorpaySignature(req.body, signature, webhookSecret)) {
            console.error("Invalid webhook signature");
            res.status(401).send("Invalid signature");
            return;
        }

        try {
            const event = req.body.event;
            const payload = req.body.payload;

            console.log(`Processing webhook event: ${event}`);

            switch (event) {
                case "payment.authorized":
                    await handlePaymentAuthorized(payload);
                    break;
                case "payment.failed":
                    await handlePaymentFailed(payload);
                    break;
                case "payment.captured":
                    await handlePaymentCaptured(payload);
                    break;
                case "refund.created":
                    await handleRefundCreated(payload);
                    break;
                case "refund.processed":
                    await handleRefundProcessed(payload);
                    break;
                default:
                    console.log(`Unhandled webhook event: ${event}`);
            }

            res.status(200).json({ received: true });
        } catch (error: any) {
            console.error("Webhook processing error:", error);
            res.status(500).json({ error: "Webhook processing failed" });
        }
    }
);

/**
 * Razorpay webhook signature verification
 */
function verifyRazorpaySignature(body: any, signature: string, secret: string): boolean {
    if (!signature || !secret) {
        console.error("Missing signature or secret");
        return false;
    }

    const expectedSignature = crypto
        .createHmac("sha256", secret)
        .update(JSON.stringify(body))
        .digest("hex");

    return signature === expectedSignature;
}

/**
 * Handle payment.authorized event
 */
async function handlePaymentAuthorized(payload: any): Promise<void> {
    const paymentId = payload.payment?.entity?.id;
    const orderId = payload.payment?.entity?.order_id;

    if (!paymentId || !orderId) {
        console.error("Missing payment or order ID");
        return;
    }

    // Update payment record
    await db.collection("payment_orders").doc(orderId).update({
        paymentId,
        status: "authorized",
        authorizedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update associated booking
    const paymentDoc = await db.collection("payment_orders").doc(orderId).get();
    const paymentData = paymentDoc.data();

    if (paymentData?.bookingId) {
        await db.collection("bookings").doc(paymentData.bookingId).update({
            paymentStatus: "authorized",
            razorpayPaymentId: paymentId,
            authorizedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    console.log(`Payment ${paymentId} authorized for order ${orderId}`);
}

/**
 * Handle payment.failed event
 */
async function handlePaymentFailed(payload: any): Promise<void> {
    const paymentId = payload.payment?.entity?.id;
    const orderId = payload.payment?.entity?.order_id;

    if (!paymentId || !orderId) {
        console.error("Missing payment or order ID");
        return;
    }

    // Update payment record
    await db.collection("payment_orders").doc(orderId).update({
        paymentId,
        status: "failed",
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        errorCode: payload.payment?.entity?.error?.code,
        errorDescription: payload.payment?.entity?.error?.description,
    });

    // Notify customer
    const paymentDoc = await db.collection("payment_orders").doc(orderId).get();
    const paymentData = paymentDoc.data();

    if (paymentData?.bookingId) {
        await db.collection("bookings").doc(paymentData.bookingId).update({
            paymentStatus: "failed",
            status: "payment_failed",
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    console.log(`Payment ${paymentId} failed for order ${orderId}`);
}

/**
 * Handle payment.captured event
 */
async function handlePaymentCaptured(payload: any): Promise<void> {
    const paymentId = payload.payment?.entity?.id;
    const orderId = payload.payment?.entity?.order_id;
    const amount = payload.payment?.entity?.amount;

    if (!paymentId || !orderId) {
        console.error("Missing payment or order ID");
        return;
    }

    await db.collection("payment_orders").doc(orderId).update({
        paymentId,
        status: "captured",
        capturedAmount: amount / 100,
        capturedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const paymentDoc = await db.collection("payment_orders").doc(orderId).get();
    const paymentData = paymentDoc.data();

    if (paymentData?.bookingId) {
        await db.collection("bookings").doc(paymentData.bookingId).update({
            paymentStatus: "paid",
            paymentId,
            status: "confirmed",
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Trigger matching
        await db.collection("matching_queue").add({
            bookingId: paymentData.bookingId,
            priority: "normal",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    console.log(`Payment ${paymentId} captured for order ${orderId}`);
}

/**
 * Handle refund.created event
 */
async function handleRefundCreated(payload: any): Promise<void> {
    const refundId = payload.refund?.entity?.id;
    const paymentId = payload.refund?.entity?.payment_id;
    const amount = payload.refund?.entity?.amount;

    if (!refundId || !paymentId) {
        console.error("Missing refund or payment ID");
        return;
    }

    await db.collection("refunds").doc(refundId).set({
        refundId,
        paymentId,
        amount: amount / 100,
        status: "created",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Refund ${refundId} created for payment ${paymentId}`);
}

/**
 * Handle refund.processed event
 */
async function handleRefundProcessed(payload: any): Promise<void> {
    const refundId = payload.refund?.entity?.id;
    const paymentId = payload.refund?.entity?.payment_id;

    if (!refundId || !paymentId) {
        console.error("Missing refund or payment ID");
        return;
    }

    await db.collection("refunds").doc(refundId).update({
        status: "processed",
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Find associated booking via payment order
    const paymentOrders = await db.collection("payment_orders")
        .where("paymentId", "==", paymentId)
        .get();

    if (!paymentOrders.empty) {
        const orderDoc = paymentOrders.docs[0];
        const orderData = orderDoc.data();

        if (orderData?.bookingId) {
            await db.collection("bookings").doc(orderData.bookingId).update({
                paymentStatus: "refunded",
                status: "cancelled",
                refundedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    }

    console.log(`Refund ${refundId} processed for payment ${paymentId}`);
}

/**
 * v2 Generic HTTP Request Handler Template
 */
export const healthCheck = onRequest(
    {
        region: "us-central1",
        memory: "128MiB",
        timeoutSeconds: 10,
        minInstances: 1,
        maxInstances: 10,
    },
    async (req: Request, res: Response) => {
        try {
            // Health check
            const health = {
                status: "healthy",
                timestamp: new Date().toISOString(),
                region: "us-central1",
                version: "v2",
            };

            res.status(200).json(health);
        } catch (error: any) {
            res.status(500).json({
                status: "unhealthy",
                error: error.message,
            });
        }
    }
);
