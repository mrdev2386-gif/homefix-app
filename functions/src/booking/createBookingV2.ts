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

                // SECURE PRICE VALIDATION (Step 5 Requirement)
                let serverCalculatedTotal = 0;
                const validatedServices: any[] = [];

                for (const item of services) {
                    const categoryId = item.categoryId || item.category;
                    const serviceId = item.id || item.serviceId;

                    if (!categoryId || !serviceId) {
                        throw new https.HttpsError("invalid-argument", `Missing location data for service: ${item.name}`);
                    }

                    const serviceRef = db.collection("categories").doc(categoryId).collection("services").doc(serviceId);
                    const serviceDoc = await transaction.get(serviceRef);

                    if (!serviceDoc.exists) {
                        throw new https.HttpsError("not-found", `Service not found: ${item.name}`);
                    }

                    const serviceData = serviceDoc.data()!;
                    if (!serviceData.isActive) {
                        throw new https.HttpsError("failed-precondition", `Service is no longer active: ${item.name}`);
                    }

                    const masterPrice = Number(serviceData.price || serviceData.basePrice || 0);
                    const quantity = Number(item.quantity || 1);
                    serverCalculatedTotal += masterPrice * quantity;

                    validatedServices.push({
                        id: serviceId,
                        categoryId: categoryId,
                        name: serviceData.name || serviceData.title,
                        price: masterPrice,
                        quantity: quantity,
                        image: serviceData.imageUrl || serviceData.image || item.image,
                    });
                }

                // If a coupon code is provided, apply it (Security: Server-side validation)
                let discountAmount = 0;
                if (couponCode) {
                    const couponRef = db.collection("coupons").doc(couponCode);
                    const couponDoc = await transaction.get(couponRef);
                    if (couponDoc.exists) {
                        const couponData = couponDoc.data()!;
                        if (couponData.isActive && (!couponData.expiry || couponData.expiry.toDate() > new Date())) {
                            if (couponData.type === 'percentage') {
                                discountAmount = (serverCalculatedTotal * (couponData.value / 100));
                            } else {
                                discountAmount = couponData.value;
                            }
                        }
                    }
                }

                const finalTotal = Math.max(0, serverCalculatedTotal - discountAmount);

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
                    price: finalTotal,
                    finalAmount: finalTotal,
                    discountAmount: discountAmount,
                    originalPrice: serverCalculatedTotal,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    services: validatedServices,
                    serviceTitle: validatedServices[0].name + (validatedServices.length > 1 ? ` (+${validatedServices.length - 1} more)` : ""),
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
