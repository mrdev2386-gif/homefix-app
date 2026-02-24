/**
 * NEW Booking Flow - Cloud Functions
 * 
 * Flow:
 * 1. Customer creates booking request → status: pending_admin
 * 2. Admin approves → status: technician_pending
 * 3. Technician accepts → status: awaiting_payment
 * 4. Customer pays → status: confirmed
 * 5. Service completed → status: completed
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { processTechnicianEarning } from '../finance/wallet_logic';
import { checkRateLimit } from '../shared/utils';

if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

// ==========================================
// HELPER FUNCTIONS
// ==========================================

async function isAdmin(uid: string): Promise<boolean> {
    const adminDoc = await db.collection('admins').doc(uid).get();
    return adminDoc.exists;
}

async function sendNotification(
    userId: string,
    userType: 'customer' | 'technician' | 'admin',
    title: string,
    body: string,
    data: Record<string, string> = {}
) {
    try {
        // Get user's FCM tokens
        const tokensSnapshot = await db.collection(userType === 'technician' ? 'technicians' : 'customers')
            .doc(userId)
            .collection('fcmTokens')
            .where('isActive', '==', true)
            .get();

        if (tokensSnapshot.empty) {
            console.log(`[Notification] No active tokens for ${userType}:${userId}`);
            return;
        }

        const tokens = tokensSnapshot.docs.map(doc => doc.data().token);

        // Send to all tokens
        const messages = tokens.map(token => ({
            token,
            notification: { title, body },
            data,
        }));

        // Batch send in chunks of 500
        for (let i = 0; i < messages.length; i += 500) {
            const chunk = messages.slice(i, i + 500);
            await admin.messaging().sendAll(chunk);
        }

        console.log(`[Notification] Sent to ${userType}:${userId}, tokens: ${tokens.length}`);
    } catch (error) {
        console.error(`[Notification] Failed to send to ${userType}:${userId}:`, error);
    }
}

function createBookingNumber(): string {
    const year = new Date().getFullYear();
    const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
    return `BK-${year}-${random}`;
}

// ==========================================
// NEW STATUS ENUM
// ==========================================

type BookingStatus =
    | 'pending_admin'
    | 'admin_approved'
    | 'admin_rejected'
    | 'technician_pending'
    | 'technician_accepted'
    | 'technician_rejected'
    | 'awaiting_payment'
    | 'confirmed'
    | 'in_progress'
    | 'completed'
    | 'cancelled';

type PaymentStatus =
    | 'pending'
    | 'processing'
    | 'paid'
    | 'failed'
    | 'refunded';

// ==========================================
// 1. CREATE BOOKING REQUEST
// ==========================================
interface CreateBookingRequestData {
    serviceId: string;
    technicianId: string;
    categoryId: string;
    categoryName: string;
    subcategoryId?: string;
    scheduledDate: string;
    scheduledTime: string;
    address: Record<string, any>;
    price: number;
    durationMinutes?: number;
    couponCode?: string;
    idempotencyKey?: string; // For production safety
}

interface CreateBookingRequestResponse {
    success: boolean;
    bookingId?: string;
    status?: string;
    message?: string;
    error?: string;
}

export const createBookingRequest = functions.https.onCall(
    async (data: CreateBookingRequestData, context: functions.https.CallableContext): Promise<CreateBookingRequestResponse> => {

        // 1. Authentication guard
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }

        const customerId = context.auth.uid;
        const { serviceId, technicianId, categoryId, categoryName, scheduledDate, scheduledTime, address, price, idempotencyKey } = data;

        // 2. Idempotency Check
        if (idempotencyKey) {
            const existing = await db.collection('booking_idempotency')
                .doc(`${customerId}_${idempotencyKey}`)
                .get();
            if (existing.exists) {
                console.log(`[createBookingRequest] Idempotent hit: ${idempotencyKey}`);
                const existingData = existing.data()!;
                return {
                    success: true,
                    bookingId: existingData.bookingId,
                    status: existingData.status,
                    message: 'Retrieved existing booking request.'
                };
            }
        }

        // 3. Rate Limiting (Hardening)
        await checkRateLimit(customerId, 'create_booking', 5, 60);

        // 4. Input validation
        if (!serviceId || !technicianId || !categoryId || !categoryName || !scheduledDate || !scheduledTime || !address || !price) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
        }

        // 5. Validate service exists and is active/published
        let serviceData: any;

        // Check if it's a technician-specific service
        const techServiceRef = db.collection('technicians').doc(technicianId)
            .collection('technician_services').doc(serviceId);
        const techServiceDoc = await techServiceRef.get();

        if (techServiceDoc.exists) {
            serviceData = techServiceDoc.data();
            if (serviceData.status !== 'active' || serviceData.isPublished === false || serviceData.technicianApproved === false) {
                throw new functions.https.HttpsError('failed-precondition', 'This service is currently unavailable');
            }
        } else {
            // Fallback to global services (if applicable)
            const globalServiceDoc = await db.collection('categories').doc(categoryId)
                .collection('services').doc(serviceId).get();

            if (!globalServiceDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Service not found');
            }
            serviceData = globalServiceDoc.data();
            if (serviceData.isActive === false) {
                throw new functions.https.HttpsError('failed-precondition', 'This service is currently inactive');
            }
        }

        // 5.5. ENFORCE PRICE INTEGRITY (Harden)
        const expectedPrice = serviceData.price || serviceData.basePrice || 0;
        if (Math.abs(expectedPrice - price) > 0.01) {
            console.error(`[createBookingRequest] PRICE_FRAUD_PREVENTION: Data price ${price} does not match server price ${expectedPrice}`);
            throw new functions.https.HttpsError('failed-precondition', 'Pricing has changed. Please refresh and try again.');
        }

        // 6. Validate technician exists and is active
        const techDoc = await db.collection('technicians').doc(technicianId).get();

        if (!techDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        }

        const techData = techDoc.data()!;

        if (techData.isActive === false || (techData.status !== 'approved' && techData.status !== 'active')) {
            throw new functions.https.HttpsError('failed-precondition', 'Technician is not available at this time');
        }

        // 7. Check for suspended account (risk check)
        const riskDoc = await db.collection('risk_profiles').doc(customerId).get();
        if (riskDoc.exists && riskDoc.data()!.status === 'suspended') {
            throw new functions.https.HttpsError('permission-denied', 'Account suspended');
        }

        // 8. Create booking with status = pending_admin
        const bookingId = db.collection('bookings').doc().id;
        const now = admin.firestore.Timestamp.now();

        try {
            await db.runTransaction(async (transaction) => {
                // Double check idempotency inside transaction for absolute safety
                if (idempotencyKey) {
                    const idemRef = db.collection('booking_idempotency').doc(`${customerId}_${idempotencyKey}`);
                    const idemDoc = await transaction.get(idemRef);
                    if (idemDoc.exists) throw new Error('ALREADY_PROCESSED');

                    transaction.set(idemRef, {
                        bookingId,
                        customerId,
                        status: 'pending_admin',
                        createdAt: now
                    });
                }

                // Build booking data
                const bookingData = {
                    // IDs
                    id: bookingId,
                    bookingId,
                    bookingNumber: createBookingNumber(),
                    customerId,
                    customerName: context.auth!.token?.name || 'Customer',

                    // Service info
                    serviceId,
                    technicianId,
                    categoryId,
                    categoryName,
                    subcategoryId: data.subcategoryId || null,
                    serviceName: serviceData.name || serviceData.title || 'Service',
                    technicianName: techData.name || techData.displayName || 'Technician',

                    // Location
                    addressSnapshot: {
                        ...address,
                        district: address.district || '',
                        districtNormalized: address.district ? address.district.toString().trim().toLowerCase() : ''
                    },

                    // Pricing
                    price: price,
                    finalAmount: price,
                    finalPriceSnapshot: price, // AUDIT: Required field for audit trail
                    discountAmount: 0,
                    originalPrice: price,
                    couponCode: data.couponCode || null,

                    // Schedule
                    scheduledDate,
                    scheduledTime,
                    scheduledAt: admin.firestore.Timestamp.fromDate(new Date(scheduledDate)),
                    durationMinutes: data.durationMinutes || serviceData.estimatedDuration || 60,

                    // Status - NEW FLOW
                    status: 'pending_admin',
                    paymentStatus: 'pending' as PaymentStatus,

                    // Timestamps
                    createdAt: now,
                    updatedAt: now,

                    // For display
                    serviceTitle: serviceData.name || 'Service',
                };

                transaction.set(db.collection('bookings').doc(bookingId), bookingData);
            });

            console.log(`[createBookingRequest] Created booking ${bookingId} with status: pending_admin`);

            // 9. Send notification to admin
            await sendNotification(
                'admin',
                'admin',
                'New Booking Request',
                `New booking from ${context.auth!.token?.name || 'Customer'} for ${serviceData.name || 'Service'}`,
                { bookingId, type: 'new_booking' }
            );

            return {
                success: true,
                bookingId,
                status: 'pending_admin',
                message: 'Booking request created. Waiting for admin approval.'
            };

        } catch (error: any) {
            if (error.message === 'ALREADY_PROCESSED') {
                const existing = await db.collection('booking_idempotency').doc(`${customerId}_${idempotencyKey}`).get();
                return {
                    success: true,
                    bookingId: existing.data()?.bookingId,
                    status: existing.data()?.status,
                    message: 'Retrieved existing booking request.'
                };
            }
            console.error('[createBookingRequest] Error:', error);
            throw new functions.https.HttpsError('internal', error.message || 'Failed to create booking');
        }
    }
);

// ==========================================
// 2. ADMIN APPROVE BOOKING
// ==========================================

interface AdminApproveData {
    bookingId: string;
    action: 'approve' | 'reject';
    rejectionReason?: string;
}

interface AdminApproveResponse {
    success: boolean;
    status?: string;
    message?: string;
    error?: string;
}

export const adminApproveBooking = functions.https.onCall(
    async (data: AdminApproveData, context: functions.https.CallableContext): Promise<AdminApproveResponse> => {

        // 1. Authentication + Admin check
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }

        const isUserAdmin = await isAdmin(context.auth.uid);
        if (!isUserAdmin) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can approve bookings');
        }

        const { bookingId, action, rejectionReason } = data;

        if (!bookingId || !action) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
        }

        // 2. Get booking
        const bookingDoc = await db.collection('bookings').doc(bookingId).get();

        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingDoc.data()!;

        // 3. Validation: Current Status must be pending_admin
        if (booking.status !== 'pending_admin') {
            console.log(`[adminApproveBooking] Idempotency: Booking ${bookingId} already in status ${booking.status}`);
            return {
                success: true,
                status: booking.status,
                message: `Booking is already in ${booking.status} state.`
            };
        }

        const now = admin.firestore.Timestamp.now();
        let newStatus: BookingStatus;
        let message: string;

        try {
            if (action === 'approve') {
                newStatus = 'technician_pending';
                message = 'Booking approved. Technician will be notified.';

                await bookingDoc.ref.update({
                    status: newStatus,
                    adminApprovedAt: now,
                    updatedAt: now,
                });

                // Notify technician
                if (booking.technicianId) {
                    await sendNotification(
                        booking.technicianId,
                        'technician',
                        'New Booking Assignment',
                        `You have a new booking request for ${booking.serviceName || 'Service'}`,
                        { bookingId, type: 'booking_assigned' }
                    );
                }

            } else {
                // Reject
                newStatus = 'admin_rejected';
                message = rejectionReason || 'Booking rejected by admin';

                await bookingDoc.ref.update({
                    status: newStatus,
                    rejectionReason: message,
                    adminApprovedAt: now,
                    updatedAt: now,
                });

                // Notify customer
                await sendNotification(
                    booking.customerId,
                    'customer',
                    'Booking Rejected',
                    `Your booking for ${booking.serviceName || 'Service'} has been rejected. ${rejectionReason || ''}`,
                    { bookingId, type: 'booking_rejected' }
                );
            }

            return {
                success: true,
                status: newStatus,
                message
            };

        } catch (error: any) {
            console.error('[adminApproveBooking] Error:', error);
            throw new functions.https.HttpsError('internal', error.message || 'Failed to process booking');
        }
    }
);

// ==========================================
// 3. TECHNICIAN RESPOND TO BOOKING
// ==========================================

interface TechnicianRespondData {
    bookingId: string;
    action: 'accept' | 'reject';
    rejectionReason?: string;
}

interface TechnicianRespondResponse {
    success: boolean;
    status?: string;
    message?: string;
    error?: string;
}

export const technicianRespondBooking = functions.https.onCall(
    async (data: TechnicianRespondData, context: functions.https.CallableContext): Promise<TechnicianRespondResponse> => {

        // 1. Authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }

        const technicianId = context.auth.uid;
        const { bookingId, action, rejectionReason } = data;

        if (!bookingId || !action) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
        }

        // 2. Get booking
        const bookingDoc = await db.collection('bookings').doc(bookingId).get();

        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingDoc.data()!;

        // 3. Validate technician is assigned to this booking
        if (booking.technicianId !== technicianId) {
            throw new functions.https.HttpsError('permission-denied',
                'You are not assigned to this booking');
        }

        // 4. Validate current status
        if (booking.status !== 'technician_pending') {
            console.log(`[technicianRespondBooking] Idempotency: Booking ${bookingId} already in status ${booking.status}`);
            return {
                success: true,
                status: booking.status,
                message: `Booking is already in ${booking.status} state.`
            };
        }

        const now = admin.firestore.Timestamp.now();
        let newStatus: BookingStatus;
        let message: string;

        try {
            if (action === 'accept') {
                newStatus = 'awaiting_payment';
                message = 'Booking accepted. Waiting for customer payment.';

                await bookingDoc.ref.update({
                    status: newStatus,
                    technicianAcceptedAt: now,
                    updatedAt: now,
                });

                // Notify customer to pay
                await sendNotification(
                    booking.customerId,
                    'customer',
                    'Technician Accepted!',
                    `${booking.technicianName || 'Technician'} has accepted your booking. Please proceed with payment.`,
                    { bookingId, type: 'payment_required' }
                );

            } else {
                // Reject
                newStatus = 'technician_rejected';
                message = rejectionReason || 'Booking declined by technician';

                await bookingDoc.ref.update({
                    status: newStatus,
                    rejectionReason: message,
                    technicianAcceptedAt: now,
                    updatedAt: now,
                });

                // Notify customer
                await sendNotification(
                    booking.customerId,
                    'customer',
                    'Booking Declined',
                    `The technician has declined your booking. Please select another technician.`,
                    { bookingId, type: 'booking_declined' }
                );

                // Notify admin
                await sendNotification(
                    'admin',
                    'admin',
                    'Technician Declined Booking',
                    `Technician ${booking.technicianName} declined booking ${bookingId}`,
                    { bookingId, type: 'booking_declined' }
                );
            }

            return {
                success: true,
                status: newStatus,
                message
            };

        } catch (error: any) {
            console.error('[technicianRespondBooking] Error:', error);
            throw new functions.https.HttpsError('internal', error.message || 'Failed to process response');
        }
    }
);

// ==========================================
// 4. CUSTOMER CONFIRM PAYMENT
// ==========================================

interface CustomerConfirmPaymentData {
    bookingId: string;
    paymentMethod: 'online' | 'cash';
    paymentDetails?: Record<string, any>;
}

interface CustomerConfirmPaymentResponse {
    success: boolean;
    status?: string;
    message?: string;
    error?: string;
}

export const customerConfirmPayment = functions.https.onCall(
    async (data: CustomerConfirmPaymentData, context: functions.https.CallableContext): Promise<CustomerConfirmPaymentResponse> => {

        // 1. Authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }

        const customerId = context.auth.uid;
        const { bookingId, paymentMethod, paymentDetails } = data;

        if (!bookingId || !paymentMethod) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
        }

        // 2. Get booking
        const bookingDoc = await db.collection('bookings').doc(bookingId).get();

        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingDoc.data()!;

        // 3. Validate customer owns this booking
        if (booking.customerId !== customerId) {
            throw new functions.https.HttpsError('permission-denied',
                'You do not own this booking');
        }

        // 4. Validate current status
        if (booking.status !== 'awaiting_payment') {
            console.log(`[customerConfirmPayment] Idempotency: Booking ${bookingId} already in status ${booking.status}`);
            return {
                success: true,
                status: booking.status,
                message: `Booking is already in ${booking.status} state.`
            };
        }

        const now = admin.firestore.Timestamp.now();
        let newStatus: BookingStatus;
        let paymentStatus: PaymentStatus;
        let message: string;

        try {
            if (paymentMethod === 'online') {
                // For online payment, we'd typically create a Razorpay order first
                // For now, assume payment is processed
                newStatus = 'confirmed';
                paymentStatus = 'paid';
                message = 'Payment successful! Your booking is confirmed.';
            } else {
                // Pay after service
                newStatus = 'confirmed';
                paymentStatus = 'pending'; // Will be collected after service
                message = 'Booking confirmed! Pay after service completion.';
            }

            await bookingDoc.ref.update({
                status: newStatus,
                paymentStatus,
                paymentMethod,
                paymentDetails: paymentDetails || null,
                paidAt: paymentMethod === 'online' ? now : null,
                confirmedAt: now,
                updatedAt: now,
            });

            // Notify technician
            await sendNotification(
                booking.technicianId,
                'technician',
                'Booking Confirmed',
                `Booking confirmed by customer. Please arrive at scheduled time.`,
                { bookingId, type: 'booking_confirmed' }
            );

            return {
                success: true,
                status: newStatus,
                message
            };

        } catch (error: any) {
            console.error('[customerConfirmPayment] Error:', error);
            throw new functions.https.HttpsError('internal', error.message || 'Failed to process payment');
        }
    }
);

// ==========================================
// 5. UPDATE BOOKING STATUS (Generic)
// ==========================================

interface UpdateBookingStatusData {
    bookingId: string;
    status: BookingStatus;
    reason?: string;
}

interface UpdateBookingStatusResponse {
    success: boolean;
    status?: string;
    message?: string;
    error?: string;
}

export const updateBookingStatusGeneric = functions.https.onCall(
    async (data: UpdateBookingStatusData, context: functions.https.CallableContext): Promise<UpdateBookingStatusResponse> => {

        // This is a generic status update for completed/cancelled
        // Only allowed for specific status transitions

        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }

        const userId = context.auth.uid;
        const { bookingId, status, reason } = data;

        if (!bookingId || !status) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
        }

        // Only allow these status changes via this function
        const allowedTransitions = ['completed', 'cancelled', 'in_progress'];
        if (!allowedTransitions.includes(status)) {
            throw new functions.https.HttpsError('invalid-argument',
                `Invalid status. Use specific functions for other status changes.`);
        }

        // Get booking
        const bookingDoc = await db.collection('bookings').doc(bookingId).get();

        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingDoc.data()!;
        const isUserAdmin = await isAdmin(userId);

        // Validate permission
        const isCustomer = booking.customerId === userId;
        const isTechnician = booking.technicianId === userId;

        if (!isUserAdmin && !isCustomer && !isTechnician) {
            throw new functions.https.HttpsError('permission-denied', 'Not authorized');
        }

        // Validate status transition
        const validTransitions: Record<string, string[]> = {
            'confirmed': ['in_progress', 'cancelled'],
            'in_progress': ['completed', 'cancelled'],
            'technician_accepted': ['in_progress', 'cancelled'],
            'awaiting_payment': ['confirmed', 'cancelled'],
        };

        const allowed = validTransitions[booking.status] || [];
        if (!allowed.includes(status)) {
            throw new functions.https.HttpsError('failed-precondition',
                `Cannot change from ${booking.status} to ${status}`);
        }

        const now = admin.firestore.Timestamp.now();

        try {
            const updateData: Record<string, any> = {
                status,
                updatedAt: now,
            };

            if (status === 'completed') {
                updateData.completedAt = now;

                // Process technician earnings
                if (booking.technicianId && booking.finalAmount) {
                    try {
                        const serviceIds = booking.serviceId ? [booking.serviceId] : [];
                        await processTechnicianEarning(
                            bookingId,
                            booking.technicianId,
                            booking.finalAmount,
                            serviceIds
                        );
                        console.log(`[updateBookingStatus] Earnings processed for booking ${bookingId}`);
                        updateData.earningsProcessed = true;
                    } catch (err) {
                        console.error(`[updateBookingStatus] Failed to process earnings for ${bookingId}:`, err);
                    }
                }
            }
            if (status === 'cancelled') {
                updateData.cancelledAt = now;
                updateData.cancellationReason = reason || 'Cancelled by user';
                updateData.cancelledBy = isCustomer ? 'customer' : (isTechnician ? 'technician' : 'admin');
            }
            if (status === 'in_progress') {
                updateData.startedAt = now;

                // Notify customer
                await sendNotification(
                    booking.customerId,
                    'customer',
                    'Service Started',
                    'The technician has started your service.',
                    { bookingId, type: 'service_started' }
                );
            }

            await bookingDoc.ref.update(updateData);

            // Send notifications based on status
            if (status === 'completed') {
                await sendNotification(
                    booking.customerId,
                    'customer',
                    'Service Completed',
                    `Your ${booking.serviceName || 'service'} has been completed. Please rate your experience.`,
                    { bookingId, type: 'booking_completed' }
                );
            } else if (status === 'cancelled') {
                const otherParty = isCustomer ? booking.technicianId : booking.customerId;
                const otherType = isCustomer ? 'technician' : 'customer';
                await sendNotification(
                    otherParty,
                    otherType,
                    'Booking Cancelled',
                    `The booking has been cancelled. ${reason || ''}`,
                    { bookingId, type: 'booking_cancelled' }
                );
            }

            return {
                success: true,
                status,
                message: `Booking ${status}`
            };

        } catch (error: any) {
            console.error('[updateBookingStatus] Error:', error);
            throw new functions.https.HttpsError('internal', error.message || 'Failed to update status');
        }
    }
);

// ==========================================
// EXPORTS SUMMARY
// ==========================================
/**
 * Exported functions for the NEW booking flow:
 * 
 * 1. createBookingRequest - Customer creates booking (status: pending_admin)
 * 2. adminApproveBooking - Admin approves/rejects (status: technician_pending / admin_rejected)
 * 3. technicianRespondBooking - Technician accepts/rejects (status: awaiting_payment / technician_rejected)
 * 4. customerConfirmPayment - Customer confirms payment (status: confirmed)
 * 5. updateBookingStatus - Generic status update for completed/cancelled
 */
