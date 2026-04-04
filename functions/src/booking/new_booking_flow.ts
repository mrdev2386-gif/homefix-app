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
import * as notify from '../shared/notification_helper';
import { updateBookingStatusStandalone } from '../shared/status_history_tracker';

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

function createBookingNumber(): string {
    const year = new Date().getFullYear();
    const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
    return `BK-${year}-${random}`;
}

// Helper to refund wallet
async function refundToCustomerWallet(customerId: string, amount: number, bookingId: string, reason: string) {
    const now = admin.firestore.Timestamp.now();
    await db.runTransaction(async (transaction) => {
        const walletRef = db.collection('wallets').doc(customerId);
        const walletDoc = await transaction.get(walletRef);
        const balance = walletDoc.exists ? (walletDoc.data()?.balance || 0) : 0;

        // Refund
        transaction.set(walletRef, {
            balance: balance + amount,
            updatedAt: now
        }, { merge: true });

        // Record txn
        const txnRef = db.collection('walletTransactions').doc();
        transaction.set(txnRef, {
            type: 'booking_refund',
            amount: amount,
            bookingId: bookingId,
            userId: customerId,
            reason: reason,
            createdAt: now
        });
    });
}

// ==========================================
// NEW STATUS ENUM
// ==========================================

type BookingStatus =
    | 'pending_admin'
    | 'ASSIGNED'
    | 'admin_rejected'
    | 'technician_pending'
    | 'technician_accepted'
    | 'technician_rejected'
    | 'awaiting_payment'
    | 'confirmed'
    | 'in_progress'
    | 'completed'
    | 'awaiting_customer_payment'
    | 'cancelled';

type PaymentStatus =
    | 'pending'
    | 'processing'
    | 'paid'
    | 'paid_escrow'
    | 'failed'
    | 'refunded';

// ==========================================
// 1. CREATE BOOKING REQUEST
// ==========================================
// NOTE: App Check Preparation
// This function is currently using Gen1 (firebase-functions v3)
// For production with App Check:
// 1. Migrate to Gen2: import { onCall } from 'firebase-functions/v2/https'
// 2. Add enforceAppCheck option:
//    export const createBookingRequest = onCall(
//        { enforceAppCheck: process.env.NODE_ENV === 'production' },
//        async (request) => { ... }
//    );
// 3. Configure Play Integrity API and SHA-256 certificates in Firebase Console
// 4. Test thoroughly in development before enabling in production
//
// Current: enforceAppCheck = false (development safe)
// Production: enforceAppCheck = true (after setup complete)
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
    quantity?: number; // Support for quantity-based pricing
    durationMinutes?: number;
    couponCode?: string;
    idempotencyKey?: string; // For production safety
    paymentMode?: 'before_work' | 'after_work'; // Payment timing preference
}

interface CreateBookingRequestResponse {
    success: boolean;
    bookingId?: string;
    status?: string;
    message?: string;
    error?: string;
}

export const createBookingRequest = functions.region('asia-south1').https.onCall(
    async (data: CreateBookingRequestData, context: functions.https.CallableContext): Promise<CreateBookingRequestResponse> => {

        // 1. Authentication guard
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }

        const customerId = context.auth.uid;
        const { serviceId, technicianId, categoryId, categoryName, scheduledDate, scheduledTime, address, price, idempotencyKey, paymentMode } = data;

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

        // 3. Rate Limiting (Firestore-Based) - PRODUCTION SAFETY
        // Development: 50 bookings/hour | Production: 10 bookings/hour
        // Uses Firestore query to count recent bookings (stateless, scalable)
        const RATE_LIMIT = process.env.NODE_ENV === 'production' ? 10 : 50;
        const oneHourAgo = admin.firestore.Timestamp.fromDate(
            new Date(Date.now() - 60 * 60 * 1000)
        );
        
        try {
            // Query Firestore for recent bookings by this customer
            const recentBookings = await db
                .collection('bookings')
                .where('customerId', '==', customerId)
                .where('createdAt', '>', oneHourAgo)
                .get();
            
            if (recentBookings.size >= RATE_LIMIT) {
                console.warn(`[createBookingRequest] Rate limit exceeded for ${customerId}: ${recentBookings.size} bookings in last hour`);
                throw new functions.https.HttpsError(
                    'resource-exhausted',
                    `Too many booking requests (${recentBookings.size}/${RATE_LIMIT}). Please try again later.`
                );
            }
            
            console.log(`[createBookingRequest] Rate limit check passed: ${recentBookings.size}/${RATE_LIMIT} bookings in last hour`);
        } catch (rateLimitError: any) {
            // Re-throw if it's already an HttpsError
            if (rateLimitError.code === 'resource-exhausted') {
                throw rateLimitError;
            }
            // Log other errors but don't block booking
            console.error(`[createBookingRequest] Rate limit check failed:`, rateLimitError);
        }

        // 4. Input validation
        if (!serviceId || !technicianId || !categoryId || !categoryName || !scheduledDate || !scheduledTime || !address || !price) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
        }

        // 5. Validate service exists and is active/published
        console.log('BOOKING DEBUG serviceId:', serviceId);
        
        const serviceRef = db.collection('technician_services').doc(serviceId);
        const serviceDoc = await serviceRef.get();

        if (!serviceDoc.exists) {
            console.error('SERVICE LOOKUP FAILED', serviceId);
            throw new functions.https.HttpsError('not-found', 'Service not found');
        }

        const serviceData = serviceDoc.data();
        console.log('BOOKING DEBUG serviceData:', serviceData);
        
        if (serviceData.status !== 'approved') {
            throw new functions.https.HttpsError('failed-precondition', 'Service is not available');
        }

        // 5.5. ENFORCE PRICE INTEGRITY (Quantity-Safe Validation)
        const servicePrice = serviceData.price || serviceData.basePrice || 0;
        const quantity = data.quantity || 1;
        const expectedPrice = servicePrice * quantity;
        const priceDiff = Math.abs(price - expectedPrice);
        const tolerance = 1; // Allow ₹1 tolerance for rounding
        
        if (priceDiff > tolerance && expectedPrice > 0) {
            console.error(`[createBookingRequest] PRICE_MISMATCH: Received ${price}, Expected ${expectedPrice} (${servicePrice} × ${quantity}), Diff ${priceDiff}`);
            throw new functions.https.HttpsError('failed-precondition', 'Pricing has changed. Please refresh and try again.');
        }
        
        console.log(`[createBookingRequest] Price validation passed: ${price} ≈ ${expectedPrice} (${servicePrice} × ${quantity})`);

        // 6. Validate technician exists and is active
        console.log('BOOKING DEBUG technicianId:', technicianId);
        
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
            console.log('[createBookingRequest] TRANSACTION READ PHASE');
            
            await db.runTransaction(async (transaction) => {
                // ===== PHASE 1: ALL READS FIRST =====
                console.log('[createBookingRequest] Starting transaction reads');
                
                // Read 1: Idempotency check
                let idemDocExists = false;
                let idemRef: any = null;
                if (idempotencyKey) {
                    idemRef = db.collection('booking_idempotency').doc(`${customerId}_${idempotencyKey}`);
                    const idemDoc = await transaction.get(idemRef) as any;
                    if (idemDoc.exists) {
                        idemDocExists = true;
                    }
                }

                // Read 2: Wallet balance (if before_work payment)
                let walletBalance = 0;
                let walletRef: any = null;
                if (paymentMode === 'before_work') {
                    walletRef = db.collection('wallets').doc(customerId);
                    const walletDoc = await transaction.get(walletRef) as any;
                    walletBalance = walletDoc.exists ? (walletDoc.data()?.balance || 0) : 0;
                }

                // ===== PHASE 2: VALIDATION (after all reads) =====
                console.log('[createBookingRequest] Validating transaction data');
                
                if (idemDocExists) {
                    throw new Error('ALREADY_PROCESSED');
                }

                if (paymentMode === 'before_work' && walletBalance < price) {
                    throw new Error('INSUFFICIENT_WALLET_BALANCE');
                }

                // ===== PHASE 3: ALL WRITES AFTER READS =====
                console.log('[createBookingRequest] TRANSACTION WRITE PHASE');
                
                // Write 1: Set idempotency record
                if (idempotencyKey && idemRef) {
                    transaction.set(idemRef, {
                        bookingId,
                        customerId,
                        status: 'pending_admin',
                        createdAt: now
                    });
                }

                // Write 2: Deduct from wallet if before_work
                if (paymentMode === 'before_work' && walletRef) {
                    transaction.set(walletRef, {
                        balance: walletBalance - price,
                        updatedAt: now
                    }, { merge: true });

                    // Write 3: Record wallet transaction
                    const txnRef = db.collection('walletTransactions').doc();
                    transaction.set(txnRef, {
                        type: 'booking_escrow',
                        amount: -price,
                        bookingId: bookingId,
                        userId: customerId,
                        description: `Escrow deduction for booking ${bookingId}`,
                        createdAt: now
                    });
                }

                // Write 4: Create booking document
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
                    quantity: data.quantity || 1,
                    finalAmount: price,
                    finalPriceSnapshot: price, // AUDIT: Required field for audit trail
                    discountAmount: (serviceData.basePrice && serviceData.offerPrice && serviceData.basePrice > serviceData.offerPrice) ? (serviceData.basePrice - serviceData.offerPrice) : 0,
                    originalPrice: serviceData.basePrice || price,
                    couponCode: data.couponCode || null,

                    // Schedule
                    scheduledDate,
                    scheduledTime,
                    scheduledAt: admin.firestore.Timestamp.fromDate(new Date(scheduledDate)),
                    durationMinutes: data.durationMinutes || serviceData.estimatedDuration || 60,

                    // Status - NEW FLOW
                    status: 'pending_admin_review',
                    paymentStatus: paymentMode === 'before_work' ? 'paid_escrow' : 'pending',
                    paymentMode: paymentMode || 'after_work', // Default to pay after work

                    // Timestamps
                    createdAt: now,
                    updatedAt: now,

                    // For display
                    serviceTitle: serviceData.name || 'Service',
                };

                transaction.set(db.collection('bookings').doc(bookingId), bookingData);
            });

            console.log(`[createBookingRequest] Created booking ${bookingId} with status: pending_admin`);

            // 9. Send notification to ALL admins
            try {
                const adminsSnapshot = await db.collection('admins').get();
                if (!adminsSnapshot.empty) {
                    const adminNotifications = adminsSnapshot.docs.map(adminDoc =>
                        notify.sendUserNotification({
                            userId: adminDoc.id,
                            userType: 'admin',
                            title: 'New Booking Request',
                            body: `New booking from ${context.auth!.token?.name || 'Customer'} for ${serviceData.name || 'Service'}`,
                            type: 'new_request_nearby',
                            data: { bookingId }
                        })
                    );
                    await Promise.allSettled(adminNotifications);
                } else {
                    // Fallback to single admin if collection is empty
                    await notify.sendUserNotification({
                        userId: 'admin',
                        userType: 'admin',
                        title: 'New Booking Request',
                        body: `New booking from ${context.auth!.token?.name || 'Customer'} for ${serviceData.name || 'Service'}`,
                        type: 'new_request_nearby',
                        data: { bookingId }
                    });
                }
            } catch (notifyError) {
                console.error('[createBookingRequest] Admin notification failed:', notifyError);
                // Don't fail booking creation if notification fails
            }

            // 10. Send notification to Technician
            try {
                if (technicianId) {
                    await notify.sendUserNotification({
                        userId: technicianId,
                        userType: 'technician',
                        title: 'Booking Received',
                        body: `You have received a new booking from ${context.auth!.token?.name || 'Customer'} for ${serviceData.name || 'Service'}`,
                        type: 'new_instant_booking',
                        data: { bookingId }
                    });
                }
            } catch (notifyError) {
                console.error('[createBookingRequest] Tech notification failed:', notifyError);
            }

            return {
                success: true,
                bookingId,
                status: 'pending_admin_review',
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

export const adminApproveBooking = functions.region('asia-south1').https.onCall(
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

        // 3. Validation: Current Status must be pending_admin_review
        if (booking.status !== 'pending_admin_review') {
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
                newStatus = 'ASSIGNED';
                message = 'Booking approved. Technician will be notified.';

                await updateBookingStatusStandalone(bookingId, newStatus, {
                    adminApprovedAt: now,
                });

                // Notify technician
                if (booking.technicianId) {
                    await notify.notifyTechnicianNewInstantBooking(
                        booking.technicianId,
                        bookingId,
                        booking.serviceName || 'Service',
                        booking.addressSnapshot?.address || 'Your Location'
                    );
                }

            } else {
                // Reject
                newStatus = 'admin_rejected';
                message = rejectionReason || 'Booking rejected by admin';

                await updateBookingStatusStandalone(bookingId, newStatus, {
                    rejectionReason: message,
                    adminApprovedAt: now,
                });

                // Notify customer
                await notify.notifyCustomerBookingCancelled(
                    booking.customerId,
                    bookingId,
                    rejectionReason || 'Booking rejected by admin'
                );

                // Refund if Pay Before Work
                if (booking.paymentStatus === 'paid_escrow') {
                    const amount = booking.finalAmount || booking.price || 0;
                    await refundToCustomerWallet(booking.customerId, amount, bookingId, 'Admin rejected booking');
                    await bookingDoc.ref.update({ paymentStatus: 'refunded' });
                }
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

export const technicianRespondBooking = functions.region('asia-south1').https.onCall(
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
        if (booking.status !== 'ASSIGNED') {
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
                const isPrePaid = booking.paymentMode === 'before_work' && booking.paymentStatus === 'paid_escrow';
                const isPayAfter = booking.paymentMode === 'after_work';

                newStatus = 'confirmed';
                message = 'Booking confirmed.';

                await updateBookingStatusStandalone(bookingId, newStatus, {
                    technicianAcceptedAt: now,
                });

                // Notify customer
                await notify.sendUserNotification({
                    userId: booking.customerId,
                    userType: 'customer',
                    title: 'Booking Confirmed!',
                    body: `${booking.technicianName || 'Technician'} has accepted your booking. They will arrive on time.`,
                    type: 'booking_confirmed',
                    data: { bookingId, screen: 'booking_details' },
                    priority: 'high'
                });

            } else {
                // Reject
                newStatus = 'technician_rejected';
                message = rejectionReason || 'Booking declined by technician';

                await updateBookingStatusStandalone(bookingId, newStatus, {
                    rejectionReason: message,
                    technicianAcceptedAt: now,
                });

                // Notify customer
                await notify.notifyCustomerBookingCancelled(
                    booking.customerId,
                    bookingId,
                    'The technician has declined your booking.'
                );

                // Refund if Pay Before Work
                if (booking.paymentStatus === 'paid_escrow') {
                    const amount = booking.finalAmount || booking.price || 0;
                    await refundToCustomerWallet(booking.customerId, amount, bookingId, 'Technician declined booking');
                    await bookingDoc.ref.update({ paymentStatus: 'refunded' });
                }

                // Notify admin
                await notify.sendUserNotification({
                    userId: 'admin',
                    userType: 'admin',
                    title: 'Technician Declined Booking',
                    body: `Technician ${booking.technicianName} declined booking ${bookingId}`,
                    type: 'booking_cancelled',
                    data: { bookingId }
                });
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
    paymentMethod: 'wallet';
    paymentDetails?: Record<string, any>;
}

interface CustomerConfirmPaymentResponse {
    success: boolean;
    status?: string;
    message?: string;
    error?: string;
}

export const customerConfirmPayment = functions.region('asia-south1').https.onCall(
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
            if (booking.paymentStatus === 'paid_escrow') {
                newStatus = 'confirmed';
                paymentStatus = 'paid_escrow';
                message = 'Payment already received. Booking confirmed.';
            } else {
                // Deduct from wallet now
                const walletRef = db.collection('wallets').doc(customerId);
                await db.runTransaction(async (transaction) => {
                    const walletDoc = await transaction.get(walletRef);
                    const balance = walletDoc.exists ? (walletDoc.data()?.balance || 0) : 0;

                    const amountToPay = booking.finalAmount || booking.price || 0;
                    if (balance < amountToPay) {
                        throw new Error('INSUFFICIENT_FUNDS');
                    }

                    transaction.set(walletRef, {
                        balance: balance - amountToPay,
                        updatedAt: now
                    }, { merge: true });

                    // Txn record
                    const txnRef = db.collection('walletTransactions').doc();
                    transaction.set(txnRef, {
                        type: 'booking_payment',
                        amount: amountToPay,
                        bookingId: bookingId,
                        userId: customerId,
                        createdAt: now
                    });
                });

                newStatus = 'confirmed';
                paymentStatus = 'paid_escrow';
                message = 'Payment successful! Your booking is confirmed.';
            }

            await updateBookingStatusStandalone(bookingId, newStatus, {
                paymentStatus: 'paid_escrow',
                paymentMethod: 'wallet',
                paidAt: now,
                confirmedAt: now,
            });

            // Notify technician
            await notify.notifyTechnicianNewPayment(
                booking.technicianId,
                bookingId,
                booking.finalAmount || 0
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
// 4.5. MARK WORK COMPLETED (Dedicated)
// ==========================================

export const markWorkCompleted = functions.region('asia-south1').https.onCall(
    async (data: { bookingId: string }, context: functions.https.CallableContext) => {
        if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

        const technicianId = context.auth.uid;
        const { bookingId } = data;

        const bookingDoc = await db.collection('bookings').doc(bookingId).get();
        if (!bookingDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');

        const booking = bookingDoc.data()!;
        if (booking.technicianId !== technicianId) {
            throw new functions.https.HttpsError('permission-denied', 'Not your booking');
        }
        if (booking.status !== 'in_progress') {
            throw new functions.https.HttpsError('failed-precondition', 'Work not started');
        }

        const now = admin.firestore.FieldValue.serverTimestamp();
        const paymentMode = booking.paymentMode || 'after_work';

        if (paymentMode === 'before_work') {
            // Already paid to escrow, now complete and payout
            await processTechnicianEarning(bookingId, technicianId, booking.finalAmount || booking.price || 0, booking.customerId);

            await updateBookingStatusStandalone(bookingId, 'completed', {
                completedAt: now,
                workCompletedAt: now,
                paymentStatus: 'paid',
            });

            await notify.notifyCustomerJobCompleted(
                booking.customerId,
                bookingId,
                booking.technicianName || 'Technician'
            );

            return { success: true, status: 'completed', message: 'Work completed and payout released.' };
        } else {
            // after_work mode -> set status to awaiting payment for QR scan
            await updateBookingStatusStandalone(bookingId, 'awaiting_customer_payment', {
                workCompletedAt: now,
            });

            await notify.sendUserNotification({
                userId: booking.customerId,
                userType: 'customer',
                title: 'Work Completed! 🎉',
                body: 'Please show the QR code to your technician for payment.',
                type: 'job_completed',
                data: { bookingId, screen: 'payment_qr' },
                priority: 'high'
            });

            return { success: true, status: 'awaiting_customer_payment', message: 'Work completed. Waiting for QR payment.' };
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

export const updateBookingStatusGeneric = functions.region('asia-south1').https.onCall(
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
                            booking.customerId
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

                // Refund if Pay Before Work
                if (booking.paymentStatus === 'paid_escrow') {
                    const amount = booking.finalAmount || booking.price || 0;
                    await refundToCustomerWallet(booking.customerId, amount, bookingId, `Cancelled by ${updateData.cancelledBy}`);
                    updateData.paymentStatus = 'refunded';
                }
            }

            if (status === 'in_progress') {
                updateData.startedAt = now;

                // Notify customer
                await notify.notifyCustomerTechnicianEnRoute(
                    booking.customerId,
                    bookingId,
                    booking.technicianName || 'Technician'
                );
            }

            // Extract status from updateData and use history tracker
            const { status: _s, updatedAt: _u, ...extraFields } = updateData;
            await updateBookingStatusStandalone(bookingId, status, extraFields);

            // Send notifications based on status
            if (status === 'completed') {
                await notify.notifyCustomerJobCompleted(
                    booking.customerId,
                    bookingId,
                    booking.technicianName || 'Technician'
                );
            } else if (status === 'cancelled') {
                if (isCustomer && booking.technicianId) {
                    await notify.notifyTechnicianBookingCancelled(
                        booking.technicianId,
                        bookingId,
                        reason || 'Cancelled by customer'
                    );
                } else {
                    await notify.notifyCustomerBookingCancelled(
                        booking.customerId,
                        bookingId,
                        reason || 'Cancelled by technician'
                    );
                }
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
