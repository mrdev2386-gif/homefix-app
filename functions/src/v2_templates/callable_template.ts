/**
 * v2 Callable Function Template
 * Migration from: functions.https.onCall
 * 
 * IMPORTANT: Use process.env for configuration, NOT functions.config()
 * Legacy config is deprecated and will not work in 2nd Gen functions.
 */

import { onCall } from "firebase-functions/v2/https";
import { CallableRequest } from "firebase-functions/v2/https";
import * as https from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Environment variables - REQUIRED for 2nd Gen functions
const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID || '';
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || '';

const db = admin.firestore();

/**
 * v2 Callable Options Interface
 */
interface V2CallableOptions {
    region?: string;
    memory?: "128MiB" | "256MiB" | "512MiB" | "1GiB" | "2GiB";
    timeoutSeconds?: number;
    minInstances?: number;
    maxInstances?: number;
    concurrency?: number;
}

/**
 * Example: v2 createBooking callable
 * 
 * Key Changes from v1:
 * 1. Import from 'firebase-functions/v2/https'
 * 2. Handler receives (request) instead of (data, context)
 * 3. Access auth via request.auth
 * 4. Region, memory, timeout configured in options object
 */
export const createBooking = onCall(
    {
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 60,
        minInstances: 2,
        maxInstances: 100,
        concurrency: 80,
    },
    async (request: CallableRequest<any>) => {
        // v2: Check auth on request object
        if (!request.auth) {
            throw new https.HttpsError("unauthenticated", "User must be authenticated");
        }

        const uid = request.auth.uid;
        const data = request.data;

        // Validate input
        const { services, scheduledDate, scheduledTime, address, totalAmount } = data;
        if (!services || services.length === 0 || !address || !totalAmount) {
            throw new https.HttpsError("invalid-argument", "Missing required fields");
        }

        try {
            // Risk check
            const riskDoc = await db.collection("risk_profiles").doc(uid).get();
            if (riskDoc.exists) {
                const riskData = riskDoc.data()!;
                if (riskData.status === "suspended") {
                    throw new https.HttpsError("permission-denied", "Account suspended");
                }
            }

            const bookingId = db.collection("bookings").doc().id;

            await db.runTransaction(async (transaction) => {
                transaction.set(db.collection("bookings").doc(bookingId), {
                    id: bookingId,
                    bookingId,
                    customerId: uid,
                    customerName: request.auth?.token?.name || "Customer",
                    addressSnapshot: address,
                    status: "pending_payment",
                    paymentStatus: "pending",
                    price: totalAmount,
                    finalAmount: totalAmount,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    services,
                    serviceTitle: services[0].name + (services.length > 1 ? ` (+${services.length - 1} more)` : ""),
                    scheduledDate,
                    scheduledTime,
                });
            });

            return { success: true, bookingId, totalAmount };
        } catch (error: any) {
            console.error("createBooking error:", error);
            throw new https.HttpsError("internal", error.message);
        }
    }
);

/**
 * Example: v2 Razorpay payment initiation callable
 */
export const initiateRazorpayPayment = onCall(
    {
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 30,
        minInstances: 3,
        maxInstances: 100,
    },
    async (request: CallableRequest<{ bookingId: string; amount: number }>) => {
        if (!request.auth) {
            throw new https.HttpsError("unauthenticated", "Authentication required");
        }

        const { bookingId, amount } = request.data;

        if (!bookingId || !amount) {
            throw new https.HttpsError("invalid-argument", "Missing bookingId or amount");
        }

        try {
            const Razorpay = (await import("razorpay")).default;
            const razorpay = new Razorpay({
                key_id: RAZORPAY_KEY_ID,
                key_secret: RAZORPAY_KEY_SECRET,
            });

            const order = await razorpay.orders.create({
                amount: amount * 100, // Convert to paise
                currency: "INR",
                receipt: bookingId,
                notes: {
                    customerId: request.auth!.uid,
                },
            });

            // Store order reference
            await db.collection("payment_orders").doc(order.id).set({
                orderId: order.id,
                bookingId,
                customerId: request.auth!.uid,
                amount,
                status: "created",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return {
                orderId: order.id,
                keyId: RAZORPAY_KEY_ID,
            };
        } catch (error: any) {
            console.error("Razorpay order creation error:", error);
            throw new https.HttpsError("internal", "Failed to create payment order");
        }
    }
);

/**
 * Example: v2 assignTechnicianToBooking callable
 */
export const assignTechnicianToBooking = onCall(
    {
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 60,
        minInstances: 1,
        maxInstances: 50,
    },
    async (request: CallableRequest<{ bookingId: string; technicianId: string }>) => {
        if (!request.auth) {
            throw new https.HttpsError("unauthenticated", "Auth required");
        }

        // Admin check
        const adminDoc = await db.collection("admins").doc(request.auth.uid).get();
        if (!adminDoc.exists) {
            throw new https.HttpsError("permission-denied", "Only admins can force assignment");
        }

        const { bookingId, technicianId } = request.data;

        try {
            await db.runTransaction(async (transaction) => {
                const bookingRef = db.collection("bookings").doc(bookingId);
                const bookingDoc = await transaction.get(bookingRef);

                if (!bookingDoc.exists) {
                    throw new https.HttpsError("not-found", "Booking not found");
                }

                const technicianRef = db.collection("technicians").doc(technicianId);
                const techDoc = await transaction.get(technicianRef);

                if (!techDoc.exists) {
                    throw new https.HttpsError("not-found", "Technician not found");
                }

                // Update booking
                transaction.update(bookingRef, {
                    assignedTechnicianId: technicianId,
                    assignedTechnicianName: techDoc.data()?.name || "Unknown",
                    status: "assigned",
                    assignedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                // Update technician status
                transaction.update(technicianRef, {
                    status: "assigned",
                    currentBookingId: bookingId,
                    lastAssignmentAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            });

            return { success: true, bookingId, technicianId };
        } catch (error: any) {
            console.error("assignTechnicianToBooking error:", error);
            throw new https.HttpsError("internal", error.message);
        }
    }
);

/**
 * Example: v2 respondToAssignment callable
 */
export const respondToAssignment = onCall(
    {
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 30,
        minInstances: 2,
        maxInstances: 100,
    },
    async (request: CallableRequest<{ 
        bookingId: string; 
        action: "accept" | "reject" 
        technicianId?: string 
    }>) => {
        if (!request.auth) {
            throw new https.HttpsError("unauthenticated", "Technician must be authenticated");
        }

        const { bookingId, action, technicianId } = request.data;
        const uid = technicianId || request.auth.uid;

        try {
            const bookingRef = db.collection("bookings").doc(bookingId);
            const bookingDoc = await bookingRef.get();

            if (!bookingDoc.exists) {
                throw new https.HttpsError("not-found", "Booking not found");
            }

            const booking = bookingDoc.data()!;

            if (action === "accept") {
                await bookingRef.update({
                    status: "confirmed",
                    confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                // Notify customer
                await db.collection("notifications").add({
                    userId: booking.customerId,
                    title: "Technician Assigned",
                    body: `Expert has accepted your booking.`,
                    type: "booking_confirmed",
                    bookingId,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            } else {
                // Reject - trigger re-matching
                await bookingRef.update({
                    status: "pending_assignment",
                    assignedTechnicianId: admin.firestore.FieldValue.delete(),
                    assignedTechnicianName: admin.firestore.FieldValue.delete(),
                    rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                // Trigger re-matching
                await db.collection("matching_queue").add({
                    bookingId,
                    priority: "high",
                    retryCount: 0,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            return { success: true, bookingId, action };
        } catch (error: any) {
            console.error("respondToAssignment error:", error);
            throw new https.HttpsError("internal", error.message);
        }
    }
);
