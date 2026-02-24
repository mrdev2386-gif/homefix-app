/**
 * @deprecated LEGACY FILE - DO NOT USE
 * 
 * This file contains the OLD booking creation logic that bypasses admin approval.
 * Use ./new_booking_flow.ts instead.
 * 
 * OLD FLOW (DEPRECATED):
 * - Customer creates booking → status: pending_payment/pending
 * - Auto technician assignment (immediate)
 * - No admin approval required
 * 
 * NEW FLOW (ACTIVE):
 * - Customer creates booking request → status: pending_admin
 * - Admin approves → status: technician_pending
 * - Technician accepts → status: awaiting_payment
 * - Customer pays → status: confirmed
 *
 * Create Booking V2 — Production-Hardened
 *
 * Pipeline:
 *   1. Auth + input validation
 *   2. Risk check (suspended account)
 *   3. Server-side price validation per service
 *   4. Idempotency guard
 *   5. Atomic booking creation (status: pending_payment)
 *   6. Immediate technician search
 *   7. If technician found → update booking to searching_technician / assigned
 *   8. Return { bookingId, technicianAssigned, assignedTechnicianId? }
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

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
        functionName: 'createBookingV2',
        startTime: Date.now(),
    };
}

function logInfo(ctx: LogContext, action: string, data?: Record<string, any>) {
    console.log(JSON.stringify({
        level: 'INFO',
        function: ctx.functionName,
        action,
        customerId: ctx.customerId,
        bookingId: ctx.bookingId,
        durationMs: Date.now() - ctx.startTime,
        ...data,
    }));
}

function logWarn(ctx: LogContext, action: string, data?: Record<string, any>) {
    console.warn(JSON.stringify({
        level: 'WARN',
        function: ctx.functionName,
        action,
        customerId: ctx.customerId,
        bookingId: ctx.bookingId,
        durationMs: Date.now() - ctx.startTime,
        ...data,
    }));
}

function logError(ctx: LogContext, action: string, error: any) {
    console.error(JSON.stringify({
        level: 'ERROR',
        function: ctx.functionName,
        action,
        customerId: ctx.customerId,
        bookingId: ctx.bookingId,
        durationMs: Date.now() - ctx.startTime,
        error: error?.message || String(error),
        stack: error?.stack,
    }));
}

// ==========================================
// TYPES
// ==========================================

interface ServiceItem {
    id: string;
    categoryId: string;
    subServiceId?: string;
    name?: string;
    price?: number;
    quantity?: number;
    image?: string;
}

interface CreateBookingData {
    userId?: string;
    services: ServiceItem[];
    scheduledDate: string;
    scheduledTime: string;
    scheduledAt?: string;
    address: Record<string, any>;
    addressId?: string;
    totalAmount: number;
    couponCode?: string;
}

interface CreateBookingResponse {
    success: boolean;
    bookingId?: string;
    totalAmount?: number;
    technicianAssigned: boolean;
    assignedTechnicianId?: string;
    assignedTechnicianName?: string;
    error?: string;
}

// ==========================================
// TECHNICIAN SEARCH HELPER
// ==========================================

/**
 * Searches for an available technician for the given booking.
 * Uses categoryId from the first service item for matching.
 * Returns null if no technician is found (safe fallback).
 */
async function findAvailableTechnician(
    categoryId: string,
    serviceIds: string[],
    bookingLocation: { latitude: number; longitude: number } | null
): Promise<{ id: string; name: string } | null> {
    try {
        console.log(`[createBookingV2] Searching technicians for categoryId=${categoryId}, services=${serviceIds.join(',')}`);

        // Query: approved + online technicians
        // We try multiple field name variants for robustness
        let snapshot = await db.collection('technicians')
            .where('isApproved', '==', true)
            .where('isOnline', '==', true)
            .get();

        if (snapshot.empty) {
            // Fallback: try 'status' == 'approved' + 'isAvailable' == true
            console.log('[createBookingV2] No isApproved+isOnline techs, trying status+isAvailable...');
            snapshot = await db.collection('technicians')
                .where('status', '==', 'approved')
                .where('isAvailable', '==', true)
                .get();
        }

        console.log(`[createBookingV2] Total online/approved technicians found: ${snapshot.size}`);

        if (snapshot.empty) {
            console.warn('[createBookingV2] No online/approved technicians in DB at all');
            return null;
        }

        const MAX_DISTANCE_KM = 50; // Generous radius for now
        let bestTech: { id: string; name: string; score: number } | null = null;
        let bestScore = -1;

        for (const doc of snapshot.docs) {
            const tech = doc.data();
            const techId = doc.id;

            // Check if technician serves this category
            const techCategories: string[] = tech.categories || tech.categoryIds || [];
            const techServices: string[] = tech.services || tech.serviceIds || tech.skills || [];

            const servesCategory = techCategories.includes(categoryId);
            const servesAnyService = serviceIds.some(sid => techServices.includes(sid));

            console.log(`[createBookingV2] Tech ${techId}: categories=${JSON.stringify(techCategories)}, services=${JSON.stringify(techServices)}, servesCategory=${servesCategory}, servesAnyService=${servesAnyService}`);

            // Accept if serves category OR any service (lenient matching for dev/test)
            if (!servesCategory && !servesAnyService) {
                console.log(`[createBookingV2] Tech ${techId} skipped — no category/service match`);
                continue;
            }

            // Distance check (if location available)
            if (bookingLocation && (tech.location?.lat || tech.geo?.lat)) {
                const techLat = tech.location?.lat || tech.geo?.lat || 0;
                const techLng = tech.location?.lng || tech.geo?.lng || 0;
                const dist = haversineKm(
                    bookingLocation.latitude, bookingLocation.longitude,
                    techLat, techLng
                );
                console.log(`[createBookingV2] Tech ${techId} distance: ${dist.toFixed(2)}km`);
                if (dist > MAX_DISTANCE_KM) {
                    console.log(`[createBookingV2] Tech ${techId} skipped — too far (${dist.toFixed(1)}km)`);
                    continue;
                }
            }

            // Simple score: rating + new-tech boost
            const rating = tech.rating || tech.avgRating || 0;
            const completedOrders = tech.totalCompletedOrders || tech.completedJobs || 0;
            const score = (rating / 5.0) * 0.6 + (completedOrders < 10 ? 0.4 : 0.2);

            if (score > bestScore) {
                bestScore = score;
                bestTech = {
                    id: techId,
                    name: tech.name || tech.displayName || 'Technician',
                    score: bestScore,
                };
            }
        }

        if (bestTech) {
            console.log(`[createBookingV2] Best technician selected: ${bestTech.id} (score=${bestScore.toFixed(3)})`);
        } else {
            console.warn('[createBookingV2] No matching technician found after filtering');
        }

        return bestTech;
    } catch (err: any) {
        console.error(`[createBookingV2] Technician search error: ${err.message}`);
        return null; // Safe fallback — never crash the booking
    }
}

function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a = Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function toRad(deg: number): number {
    return deg * (Math.PI / 180);
}

// ==========================================
// MAIN CALLABLE FUNCTION
// ==========================================

export const createBookingV2 = functions.https.onCall(
    async (data: CreateBookingData, context: functions.https.CallableContext): Promise<CreateBookingResponse> => {
        const ctx = createLogContext(context.auth?.uid);

        // ── 1. Authentication guard ─────────────────────────────────────────
        if (!context.auth) {
            logError(ctx, 'auth_failure', new Error('User not authenticated'));
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }

        const customerId = context.auth.uid;
        ctx.customerId = customerId;

        logInfo(ctx, 'request_received', {
            serviceCount: data?.services?.length ?? 0,
            totalAmount: data?.totalAmount,
            hasAddress: !!data?.address,
            scheduledDate: data?.scheduledDate,
            scheduledTime: data?.scheduledTime,
        });

        // ── 2. Input validation ─────────────────────────────────────────────
        const { services, scheduledDate, scheduledTime, address, totalAmount, couponCode } = data;

        if (!services || services.length === 0) {
            throw new functions.https.HttpsError('invalid-argument', 'No services provided');
        }
        if (!address) {
            throw new functions.https.HttpsError('invalid-argument', 'Address is required');
        }
        if (!totalAmount || totalAmount <= 0) {
            throw new functions.https.HttpsError('invalid-argument', 'Invalid total amount');
        }
        if (!scheduledDate) {
            throw new functions.https.HttpsError('invalid-argument', 'scheduledDate is required');
        }
        if (!scheduledTime) {
            throw new functions.https.HttpsError('invalid-argument', 'scheduledTime is required');
        }

        // Validate each service has required IDs
        for (const svc of services) {
            if (!svc.id) {
                throw new functions.https.HttpsError('invalid-argument', `Service is missing 'id' field`);
            }
            if (!svc.categoryId) {
                throw new functions.https.HttpsError('invalid-argument', `Service "${svc.name || svc.id}" is missing 'categoryId'`);
            }
        }

        logInfo(ctx, 'validation_passed', { serviceCount: services.length });

        const bookingId = db.collection('bookings').doc().id;
        ctx.bookingId = bookingId;

        // ── 3. Booking creation transaction ─────────────────────────────────
        try {
            await db.runTransaction(async (transaction: admin.firestore.Transaction) => {
                // Risk check
                const riskDoc = await transaction.get(db.collection('risk_profiles').doc(customerId));
                if (riskDoc.exists) {
                    const riskData = riskDoc.data()!;
                    if (riskData.status === 'suspended') {
                        throw new functions.https.HttpsError('permission-denied', 'Account suspended.');
                    }
                }

                // Server-side price validation
                let serverCalculatedTotal = 0;
                const validatedServices: any[] = [];

                for (const item of services) {
                    const categoryId = item.categoryId;
                    const serviceId = item.id;
                    const quantity = Number(item.quantity || 1);

                    logInfo(ctx, 'validating_service', { categoryId, serviceId, quantity });

                    // Try nested path: categories/{categoryId}/services/{serviceId}
                    const serviceRef = db
                        .collection('categories')
                        .doc(categoryId)
                        .collection('services')
                        .doc(serviceId);
                    const serviceDoc = await transaction.get(serviceRef);

                    let masterPrice: number;
                    let serviceName: string;
                    let serviceImage: string;

                    if (serviceDoc.exists) {
                        const serviceData = serviceDoc.data()!;
                        if (serviceData.isActive === false) {
                            throw new functions.https.HttpsError(
                                'failed-precondition',
                                `Service is no longer active: ${item.name || serviceId}`
                            );
                        }
                        masterPrice = Number(serviceData.price || serviceData.basePrice || item.price || 0);
                        serviceName = serviceData.name || serviceData.title || item.name || 'Service';
                        serviceImage = serviceData.imageUrl || serviceData.image || item.image || '';
                    } else {
                        // Service doc not found — use client-provided price with a warning
                        logWarn(ctx, 'service_doc_not_found', { categoryId, serviceId });
                        masterPrice = Number(item.price || 0);
                        serviceName = item.name || 'Service';
                        serviceImage = item.image || '';
                    }

                    serverCalculatedTotal += masterPrice * quantity;

                    validatedServices.push({
                        id: serviceId,
                        categoryId,
                        subServiceId: item.subServiceId || null,
                        name: serviceName,
                        price: masterPrice,
                        quantity,
                        image: serviceImage,
                    });
                }

                // Coupon application
                let discountAmount = 0;
                if (couponCode) {
                    try {
                        const couponDoc = await transaction.get(db.collection('coupons').doc(couponCode));
                        if (couponDoc.exists) {
                            const couponData = couponDoc.data()!;
                            if (couponData.isActive && (!couponData.expiry || couponData.expiry.toDate() > new Date())) {
                                discountAmount = couponData.type === 'percentage'
                                    ? serverCalculatedTotal * (couponData.value / 100)
                                    : couponData.value;
                            }
                        }
                    } catch (couponErr) {
                        logWarn(ctx, 'coupon_lookup_failed', { couponCode });
                    }
                }

                const finalTotal = Math.max(0, serverCalculatedTotal - discountAmount);

                // Idempotency check (simple: check for recent booking with same customerId + scheduledDate + scheduledTime)
                const idempotencyKey = `${customerId}_${scheduledDate}_${scheduledTime}`;
                const existingQuery = await transaction.get(
                    db.collection('bookings')
                        .where('customerId', '==', customerId)
                        .where('idempotencyKey', '==', idempotencyKey)
                        .limit(1)
                );

                if (!existingQuery.empty) {
                    const existingId = existingQuery.docs[0].id;
                    logWarn(ctx, 'idempotency_duplicate', { existingBookingId: existingId });
                    // Return existing booking ID by throwing a special marker
                    throw Object.assign(new Error('IDEMPOTENT_DUPLICATE'), { existingBookingId: existingId });
                }

                // Build scheduledAt timestamp
                let scheduledAtTimestamp: admin.firestore.Timestamp;
                try {
                    const dateStr = data.scheduledAt || scheduledDate;
                    scheduledAtTimestamp = admin.firestore.Timestamp.fromDate(new Date(dateStr));
                } catch {
                    scheduledAtTimestamp = admin.firestore.Timestamp.fromDate(new Date(scheduledDate));
                }

                // Create booking document
                const primaryService = validatedServices[0];
                const serviceTitle = primaryService.name +
                    (validatedServices.length > 1 ? ` (+${validatedServices.length - 1} more)` : '');

                transaction.set(db.collection('bookings').doc(bookingId), {
                    id: bookingId,
                    bookingId,
                    customerId,
                    customerName: context.auth!.token?.name || 'Customer',
                    addressSnapshot: address,
                    addressId: data.addressId || null,
                    status: 'pending_payment',
                    paymentStatus: 'pending',
                    price: finalTotal,
                    finalAmount: finalTotal,
                    discountAmount,
                    originalPrice: serverCalculatedTotal,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    services: validatedServices,
                    serviceTitle,
                    categoryId: primaryService.categoryId,
                    scheduledDate,
                    scheduledTime,
                    scheduledAt: scheduledAtTimestamp,
                    couponCode: couponCode || null,
                    idempotencyKey,
                    technicianAssigned: false,
                    assignedTechnicianId: null,
                    assignedTechnicianName: null,
                });

                logInfo(ctx, 'booking_document_created', { bookingId, finalTotal });
            });
        } catch (e: any) {
            // Handle idempotency duplicate
            if (e.message === 'IDEMPOTENT_DUPLICATE' && e.existingBookingId) {
                logInfo(ctx, 'returning_existing_booking', { existingBookingId: e.existingBookingId });
                return {
                    success: true,
                    bookingId: e.existingBookingId,
                    totalAmount,
                    technicianAssigned: false,
                };
            }

            logError(ctx, 'transaction_failure', e);
            throw new functions.https.HttpsError('internal', `Booking creation failed: ${e.message}`);
        }

        // ── 4. Technician search (outside transaction — safe to fail) ────────
        logInfo(ctx, 'technician_search_start', { bookingId });

        let technicianAssigned = false;
        let assignedTechnicianId: string | undefined;
        let assignedTechnicianName: string | undefined;

        try {
            const primaryService = services[0];
            const categoryId = primaryService.categoryId;
            const serviceIds = services.map(s => s.id);

            // Extract location from address
            const bookingLocation = (address.latitude && address.longitude)
                ? { latitude: Number(address.latitude), longitude: Number(address.longitude) }
                : (address.lat && address.lng)
                    ? { latitude: Number(address.lat), longitude: Number(address.lng) }
                    : null;

            logInfo(ctx, 'technician_search_params', {
                categoryId,
                serviceIds,
                hasLocation: !!bookingLocation,
                latitude: bookingLocation?.latitude,
                longitude: bookingLocation?.longitude,
            });

            const technician = await findAvailableTechnician(categoryId, serviceIds, bookingLocation);

            if (technician) {
                // Assign technician to booking
                await db.collection('bookings').doc(bookingId).update({
                    status: 'searching_technician',
                    technicianAssigned: true,
                    assignedTechnicianId: technician.id,
                    assignedTechnicianName: technician.name,
                    technicianAssignedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                // Update technician's lastAssignedAt
                await db.collection('technicians').doc(technician.id).update({
                    lastAssignedAt: admin.firestore.FieldValue.serverTimestamp(),
                }).catch(err => {
                    console.warn(`[createBookingV2] Could not update technician lastAssignedAt: ${err.message}`);
                });

                technicianAssigned = true;
                assignedTechnicianId = technician.id;
                assignedTechnicianName = technician.name;

                logInfo(ctx, 'technician_assigned', {
                    bookingId,
                    technicianId: technician.id,
                    technicianName: technician.name,
                });
            } else {
                // No technician found — safe fallback
                await db.collection('bookings').doc(bookingId).update({
                    status: 'searching_technician',
                    technicianAssigned: false,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    adminNotes: 'No technician available at booking time. Will retry.',
                });

                logWarn(ctx, 'no_technician_found', { bookingId, categoryId });
            }
        } catch (techErr: any) {
            // Technician search failure must NEVER crash the booking
            logError(ctx, 'technician_search_error', techErr);

            // Safe fallback: mark as searching
            try {
                await db.collection('bookings').doc(bookingId).update({
                    status: 'searching_technician',
                    technicianAssigned: false,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    adminNotes: `Technician search error: ${techErr.message}`,
                });
            } catch (updateErr: any) {
                logError(ctx, 'fallback_update_failed', updateErr);
            }
        }

        logInfo(ctx, 'booking_complete', {
            bookingId,
            technicianAssigned,
            assignedTechnicianId,
        });

        return {
            success: true,
            bookingId,
            totalAmount,
            technicianAssigned,
            assignedTechnicianId,
            assignedTechnicianName,
        };
    }
);
