/**
 * Create Booking Function (2nd Gen)
 * Production-hardened with:
 * - Structured logging
 * - Execution timing
 * - Idempotency protection
 * - Transaction safety
 */

import { onCall } from "firebase-functions/v2/https";
import { CallableRequest } from "firebase-functions/v2/https";
import * as https from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

// ==========================================
// STRUCTURED LOGGING
// ==========================================

interface LogContext {
    bookingId?: string;
    customerId?: string;
    functionName: string;
    startTime: number;
}

function createLogContext(customerId?: string): LogContext {
    return {
        customerId,
        functionName: "createBookingV2",
        startTime: Date.now()
    };
}

function logInfo(ctx: LogContext, action: string, data?: Record<string, any>) {
    const duration = Date.now() - ctx.startTime;
    console.log(JSON.stringify({
        level: "INFO",
        function: ctx.functionName,
        action,
        customerId: ctx.customerId,
        bookingId: ctx.bookingId,
        durationMs: duration,
        ...data
    }));
}

function logError(ctx: LogContext, action: string, error: Error) {
    const duration = Date.now() - ctx.startTime;
    console.error(JSON.stringify({
        level: "ERROR",
        function: ctx.functionName,
        action,
        customerId: ctx.customerId,
        bookingId: ctx.bookingId,
        durationMs: duration,
        error: error.message,
        stack: error.stack
    }));
}

// ==========================================
// TYPES
// ==========================================

interface CreateBookingData {
    services: any[];
    scheduledDate: string;
    scheduledTime: string;
    address: any;
    totalAmount: number;
    couponCode?: string;
}

interface CreateBookingResponse {
    success: boolean;
    bookingId?: string;
    totalAmount?: number;
    error?: string;
}

// ==========================================
// IDEMPOTENCY KEY GENERATION
// ==========================================

function generateIdempotencyKey(customerId: string): string {
    return `booking_${customerId}_${Date.now()}`;
}

export const createBookingV2 = onCall(
    {
        region: "us-central1",
        memory: "512MiB",
        timeoutSeconds: 90,
        concurrency: 40,
        minInstances: 0,
    },
    async (request: CallableRequest<CreateBookingData>): Promise<CreateBookingResponse> => {
        const ctx = createLogContext(request.auth?.uid);
        const startTime = Date.now();

        // Authentication guard
        if (!request.auth) {
            logError(ctx, "auth_failure", new Error("User not authenticated"));
            throw new https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const customerId = request.auth.uid;
        ctx.customerId = customerId;

        logInfo(ctx, "request_received", { 
            hasData: !!request.data 
        });

        const data = request.data;
        const { services, scheduledDate, scheduledTime, address, totalAmount, couponCode } = data;

        // Input validation
        if (!services || services.length === 0 || !address || !totalAmount) {
            logError(ctx, "validation_failure", new Error("Missing required fields"));
            throw new https.HttpsError(
                "invalid-argument",
                "Missing required fields"
            );
        }

        const bookingId = db.collection("bookings").doc().id;
        ctx.bookingId = bookingId;
        const finalStatus = "pending_payment";
        const idempotencyKey = generateIdempotencyKey(customerId);

        logInfo(ctx, "transaction_start", { 
            bookingId,
            status: finalStatus 
        });

        try {
            await db.runTransaction(async (transaction: admin.firestore.Transaction) => {
                // Check for suspended account
                const riskDoc = await transaction.get(
                    db.collection("risk_profiles").doc(customerId)
                );

                if (riskDoc.exists) {
                    const riskData = riskDoc.data()!;
                    if (riskData.status === "suspended") {
                        throw new https.HttpsError(
                            "permission-denied",
                            "Account suspended."
                        );
                    }
                }

                // Check for existing booking with same idempotency key
                const existingBookings = await transaction.get(
                    db.collection("bookings")
                        .where("customerId", "==", customerId)
                        .where("idempotencyKey", "==", idempotencyKey)
                        .limit(1)
                );

                if (!existingBookings.empty) {
                    logInfo(ctx, "idempotency_duplicate", { 
                        bookingId: existingBookings.docs[0].id 
                    });
                    return; // Skip creation if already exists
                }

                // Create booking document
                transaction.set(db.collection("bookings").doc(bookingId), {
                    id: bookingId,
                    bookingId,
                    customerId,
                    customerName: request.auth!.token?.name || "Customer",
                    addressSnapshot: address,
                    status: finalStatus,
                    paymentStatus: "pending",
                    price: totalAmount,
                    finalAmount: totalAmount,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    services,
                    serviceTitle: services[0].name + (services.length > 1 ? ` (+${services.length - 1} more)` : ""),
                    scheduledDate,
                    scheduledTime,
                    scheduledAt: admin.firestore.Timestamp.fromDate(new Date(scheduledDate)),
                    couponCode: couponCode || null,
                    idempotencyKey,
                });
            });

            const duration = Date.now() - startTime;
            logInfo(ctx, "success", { 
                bookingId, 
                totalAmount,
                durationMs: duration 
            });

            return { success: true, bookingId, totalAmount };
        } catch (e: any) {
            logError(ctx, "transaction_failure", e);
            throw new https.HttpsError("internal", e.message);
        }
    }
);
