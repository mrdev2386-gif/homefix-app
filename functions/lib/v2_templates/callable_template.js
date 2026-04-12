"use strict";
/**
 * v2 Callable Function Template
 * Migration from: functions.https.onCall
 *
 * IMPORTANT: Use process.env for configuration, NOT functions.config()
 * Legacy config is deprecated and will not work in 2nd Gen functions.
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
exports.respondToAssignment = exports.assignTechnicianToBooking = exports.initiateRazorpayPayment = exports.createBooking = void 0;
const https_1 = require("firebase-functions/v2/https");
const https = __importStar(require("firebase-functions/v2/https"));
const admin = __importStar(require("firebase-admin"));
const { razorpay } = require('../config/razorpay');
const db = admin.firestore();
/**
 * Example: v2 createBooking callable
 *
 * Key Changes from v1:
 * 1. Import from 'firebase-functions/v2/https'
 * 2. Handler receives (request) instead of (data, context)
 * 3. Access auth via request.auth
 * 4. Region, memory, timeout configured in options object
 */
exports.createBooking = (0, https_1.onCall)({
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
    minInstances: 2,
    maxInstances: 100,
    concurrency: 80,
}, async (request) => {
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
            const riskData = riskDoc.data();
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
    }
    catch (error) {
        console.error("createBooking error:", error);
        throw new https.HttpsError("internal", error.message);
    }
});
/**
 * Example: v2 Razorpay payment initiation callable
 */
exports.initiateRazorpayPayment = (0, https_1.onCall)({
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 30,
    minInstances: 3,
    maxInstances: 100,
}, async (request) => {
    if (!request.auth) {
        throw new https.HttpsError("unauthenticated", "Authentication required");
    }
    const { bookingId, amount } = request.data;
    if (!bookingId || !amount) {
        throw new https.HttpsError("invalid-argument", "Missing bookingId or amount");
    }
    try {
        // Use direct Razorpay instance
        const order = await razorpay.orders.create({
            amount: amount * 100, // Convert to paise
            currency: "INR",
            receipt: bookingId,
            notes: {
                customerId: request.auth.uid,
            },
        });
        // Store order reference
        await db.collection("payment_orders").doc(order.id).set({
            orderId: order.id,
            bookingId,
            customerId: request.auth.uid,
            amount,
            status: "created",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Get key_id from Firebase config for client-side Razorpay checkout
        const functions = await Promise.resolve().then(() => __importStar(require('firebase-functions')));
        const config = functions.config();
        const keyId = config.razorpay?.key_id || '';
        return {
            orderId: order.id,
            keyId: keyId,
        };
    }
    catch (error) {
        console.error("Razorpay order creation error:", error);
        throw new https.HttpsError("internal", "Failed to create payment order");
    }
});
/**
 * Example: v2 assignTechnicianToBooking callable
 */
exports.assignTechnicianToBooking = (0, https_1.onCall)({
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
    minInstances: 1,
    maxInstances: 50,
}, async (request) => {
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
    }
    catch (error) {
        console.error("assignTechnicianToBooking error:", error);
        throw new https.HttpsError("internal", error.message);
    }
});
/**
 * Example: v2 respondToAssignment callable
 */
exports.respondToAssignment = (0, https_1.onCall)({
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 30,
    minInstances: 2,
    maxInstances: 100,
}, async (request) => {
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
        const booking = bookingDoc.data();
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
        }
        else {
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
    }
    catch (error) {
        console.error("respondToAssignment error:", error);
        throw new https.HttpsError("internal", error.message);
    }
});
//# sourceMappingURL=callable_template.js.map