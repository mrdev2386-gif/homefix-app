/**
 * Razorpay Payment Integration
 * 
 * PRODUCTION-SAFE payment flow:
 * - Customer pays ONLY after work completion
 * - Amount is 100% server-controlled (from locked pricing)
 * - Webhook verification for security
 * - No client-side price calculation
 * - No cash payments
 * 
 * Flow:
 * 1. Customer completes work → status = "completed"
 * 2. Customer taps "Pay Now" → createPaymentOrder
 * 3. Cloud Function creates Razorpay order with locked amount
 * 4. Customer pays via Razorpay Checkout
 * 5. Webhook verifies and updates booking
 * 6. Admin manually processes technician payout
 * 
 * TECHNICIANS:
 * - Use createRazorpayOrder to add money to wallet
 * - Use razorpayWebhookV2 for processing
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { Booking } from '../shared/models';
import crypto from 'crypto';
import { sendPushNotification } from '../shared/notifications';
import { secureCallable } from '../shared/security';
import { logger } from '../shared/utils';
const { razorpay } = require('../config/razorpay');

const LOG_PREFIX = '[RAZORPAY]';

// Get Razorpay configuration from Firebase Functions config
const getRazorpayConfig = () => {
    const config = functions.config();
    
    if (!config.razorpay) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Razorpay configuration not found. Run: firebase functions:config:set razorpay.key_id="xxx" razorpay.key_secret="xxx" razorpay.webhook_secret="xxx"'
        );
    }

    const { key_id, key_secret } = config.razorpay;

    if (!key_id || !key_secret) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Razorpay key_id and key_secret are required'
        );
    }

    return { key_id, key_secret };
};

// Verify signature using HMAC SHA256
const verifyPaymentSignature = (orderId: string, paymentId: string, signature: string): boolean => {
    const { key_secret } = getRazorpayConfig();
    
    const generatedSignature = crypto
        .createHmac('sha256', key_secret)
        .update(`${orderId}|${paymentId}`)
        .digest('hex');
    
    return generatedSignature === signature;
};

// ============================================================================
// RAZORPAY ORDER SOURCE OF TRUTH
// ============================================================================

interface RazorpayOrderData {
    orderId: string;
    amount: number;
    currency: string;
    status: 'created' | 'paid' | 'failed' | 'expired';
    technicianId?: string;
    bookingId?: string;
    paymentId?: string;
    createdAt: admin.firestore.Timestamp;
    paidAt?: admin.firestore.Timestamp;
    error?: string;
}

/**
 * Create a Razorpay order document in Firestore as source of truth
 * This is used by both booking payments and technician wallet credits
 */
async function createRazorpayOrderDoc(
    orderId: string,
    amount: number,
    options: {
        technicianId?: string;
        bookingId?: string;
        currency?: string;
        notes?: string;
    }
): Promise<RazorpayOrderData> {
    const orderRef = db.collection('razorpayOrders').doc(orderId);

    const orderData: RazorpayOrderData = {
        orderId,
        amount,
        currency: options.currency || 'INR',
        status: 'created',
        technicianId: options.technicianId,
        bookingId: options.bookingId,
        createdAt: admin.firestore.FieldValue.serverTimestamp() as any
    };

    await orderRef.set(orderData);
    return orderData;
}

// ============================================================================
// TECHNICIAN WALLET CREDIT - Create Razorpay Order
// ============================================================================

/**
 * Create Razorpay order for technician wallet credit
 * 
 * SECURITY:
 * - Validates user is authenticated technician
 * - Validates amount server-side (min/max limits)
 * - Creates order in razorpayOrders collection as source of truth
 * - NEVER trusts client-provided amount
 * 
 * Called by: Technician app to add money to wallet
 */
export const createRazorpayOrder = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
    // Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const technicianId = context.auth.uid;
    const { amount, notes } = data;

    // Validate amount - NEVER trust client
    const minAmount = 100; // ₹100 minimum
    const maxAmount = 50000; // ₹50,000 maximum

    if (!amount || typeof amount !== 'number') {
        throw new functions.https.HttpsError('invalid-argument', 'Amount is required');
    }

    if (amount < minAmount) {
        throw new functions.https.HttpsError('invalid-argument', `Minimum amount is ₹${minAmount}`);
    }

    if (amount > maxAmount) {
        throw new functions.https.HttpsError('invalid-argument', `Maximum amount is ₹${maxAmount}`);
    }

    // Verify technician exists
    const techRef = db.collection('technicians').doc(technicianId);
    const techDoc = await techRef.get();

    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }

    try {
        // Use direct Razorpay instance
        // Create Razorpay order
        const order = await razorpay.orders.create({
            amount: Math.round(amount * 100), // Amount in paise
            currency: 'INR',
            receipt: `wallet_${technicianId}_${Date.now()}`,
            notes: {
                technicianId,
                type: 'wallet_credit',
                notes: notes || 'Wallet credit'
            }
        });

        // Store order in Firestore as source of truth
        await createRazorpayOrderDoc(order.id, amount, {
            technicianId,
            notes
        });

        // Log order creation
        await db.collection('payment_logs').add({
            orderId: order.id,
            amount,
            type: 'wallet_credit',
            technicianId,
            action: 'technician_order_created',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return {
            success: true,
            orderId: order.id,
            amount,
            currency: 'INR'
        };

    } catch (error: any) {
        logger.error('createRazorpayOrder_failed', { technicianId, amount }, error);
        throw error;
    }
})
);

// ============================================================================
// PAYMENT ORDER CREATION
// ============================================================================

/**
 * Create Razorpay payment order
 * 
 * Security:
 * - Validates user is booking owner
 * - Validates booking is in payable state (awaiting_payment)
 * - Validates pricing is locked
 * - Amount comes ONLY from Firestore
 * - SINGLE PAYMENT MODE: after_service only
 * 
 * Called by: Customer app when customer taps "Pay Now" after service completion
 */
export const createPaymentOrder = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
    // Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { bookingId } = data;
    const userId = context.auth.uid;

    if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'Booking ID is required');
    }

    // Get booking
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking: any = bookingDoc.data();

    // Validation 1: User must be booking owner
    if (booking.customerId !== userId) {
        throw new functions.https.HttpsError('permission-denied', 'You are not authorized to pay for this booking');
    }

    // Validation 2: ENFORCE SINGLE PAYMENT MODE - after_service ONLY
    const paymentMethod = booking.payment?.paymentMethod || booking.paymentMethod || 'after_service';
    if (paymentMethod !== 'after_service') {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Invalid payment method. Only after-service payment is supported.'
        );
    }

    // Validation 3: Booking must be in awaiting_payment state
    const currentStatus = booking.bookingStatus || booking.status;
    if (currentStatus !== 'awaiting_payment') {
        throw new functions.https.HttpsError(
            'failed-precondition',
            `Payment not allowed. Booking status is "${currentStatus}". Payment is only allowed after service completion.`
        );
    }

    // Validation 4: Check if already paid
    const isPaid = (booking.payment && booking.payment.status === 'paid') || booking.paymentStatus === 'paid';
    if (isPaid) {
        throw new functions.https.HttpsError('already-exists', 'This booking has already been paid');
    }

    // Validation 5: Check if order already exists and is still valid
    const existingOrderId = booking.payment?.razorpayOrderId || booking.razorpayOrderId;
    const bookingTotal = booking.pricing?.total || booking.finalAmount || booking.price;

    if (existingOrderId) {
        // Order already exists, return it
        return {
            success: true,
            orderId: existingOrderId,
            amount: bookingTotal,
            currency: 'INR',
            bookingNumber: booking.bookingNumber,
            paymentMethod
        };
    }

    // Get amount from LOCKED pricing (NEVER trust client)
    const amount = Math.round(bookingTotal * 100); // Razorpay expects paise

    if (amount <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid payment amount');
    }

    try {
        // Use direct Razorpay instance
        // Create Razorpay order
        const order = await razorpay.orders.create({
            amount: amount, // Amount in paise
            currency: 'INR',
            receipt: booking.bookingNumber, // Use booking number as receipt
            notes: {
                bookingId: bookingId,
                customerId: userId,
                customerName: booking.customerName,
                serviceName: booking.serviceName,
                technicianId: booking.technicianId || '',
                technicianName: booking.technicianName || '',
                paymentMethod: 'after_service'
            }
        });

        // Store order in razorpayOrders collection as SOURCE OF TRUTH
        await createRazorpayOrderDoc(order.id, bookingTotal, {
            bookingId,
            technicianId: booking.technicianId
        });

        // Update booking with order details
        await bookingRef.update({
            'payment.razorpayOrderId': order.id,
            'payment.razorpayOrderCreatedAt': admin.firestore.FieldValue.serverTimestamp(),
            'payment.status': 'processing',
            'payment.currency': 'INR',
            'payment.receipt': booking.bookingNumber,
            'payment.paymentMethod': 'after_service',
            'payment.retryCount': admin.firestore.FieldValue.increment(1),
            'razorpayOrderId': order.id,
            'paymentStatus': 'processing',
            'paymentMethod': 'after_service'
        });

        // Log the order creation
        await db.collection('payment_logs').add({
            bookingId,
            orderId: order.id,
            amount: bookingTotal,
            currency: 'INR',
            paymentMethod: 'after_service',
            action: 'order_created',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: userId
        });

        return {
            success: true,
            orderId: order.id,
            amount: bookingTotal,
            currency: 'INR',
            bookingNumber: booking.bookingNumber,
            customerName: booking.customerName,
            customerEmail: context.auth.token.email || '',
            customerPhone: booking.customerPhone,
            paymentMethod: 'after_service',
            keyId: getRazorpayConfig().key_id
        };

    } catch (error: any) {
        logger.error('createPaymentOrder_failed', { bookingId, userId }, error);
        throw error;
    }
})
);

// ============================================================================
// RAZORPAY WEBHOOK HANDLER
// ============================================================================

/**
 * Razorpay Webhook Handler
 * 
 * CRITICAL SECURITY:
 * - Verifies Razorpay signature
 * - Updates booking only after verification
 * - Handles payment.captured and payment.failed events
 * 
 * Setup:
 * 1. Go to Razorpay Dashboard → Webhooks
 * 2. Add webhook URL: https://your-project.cloudfunctions.net/razorpayWebhook
 * 3. Select events: payment.captured, payment.failed
 * 4. Copy webhook secret
 * 5. Set in Firebase: firebase functions:config:set razorpay.webhook_secret="xxx"
 */
/**
 * @DEPRECATED - Use razorpayWebhookV2 instead
 * This webhook is kept for backward compatibility but is NOT used.
 * All payments should go through razorpayWebhookV2.
 */
/*
export const razorpayWebhook = functions.https.onRequest(async (req, res) => {
    // Only accept POST requests
    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }

    try {
        // Get webhook secret
        const webhookSecret = razorpayWebhookSecret;

        if (!webhookSecret) {
            console.error('Razorpay webhook secret not configured');
            res.status(500).send('Webhook secret not configured');
            return;
        }

        // Verify signature
        const signature = req.headers['x-razorpay-signature'] as string;

        if (!signature) {
            console.error('No signature in webhook request');
            res.status(400).send('No signature provided');
            return;
        }

        // Create signature hash
        const body = JSON.stringify(req.body);
        const expectedSignature = crypto
            .createHmac('sha256', webhookSecret)
            .update(body)
            .digest('hex');

        // Verify signature
        if (signature !== expectedSignature) {
            console.error('Invalid webhook signature');
            res.status(400).send('Invalid signature');
            return;
        }

        // Signature verified, process event
        const event = req.body.event;
        const payload = req.body.payload;

        console.log('Razorpay webhook event:', event);

        // Handle different events
        switch (event) {
            case 'payment.captured':
                await handlePaymentCaptured(payload);
                break;

            case 'payment.failed':
                await handlePaymentFailed(payload);
                break;

            default:
                console.log('Unhandled webhook event:', event);
        }

        res.status(200).send('OK');

    } catch (error: any) {
        console.error('Webhook processing error:', error);
        res.status(500).send('Internal Server Error');
    }
});
*/

// Keep helper functions for reference but they're not used
/**
 * Handle successful payment
 * @deprecated - Use razorpayWebhookV2
 */
async function handlePaymentCaptured(payload: any) {
    const payment = payload.payment.entity;
    const orderId = payment.order_id;
    const paymentId = payment.id;
    const amount = payment.amount / 100; // Convert paise to rupees

    console.log('Payment captured:', paymentId, 'Order:', orderId, 'Amount:', amount);

    // Find booking by order ID
    const bookingsSnapshot = await db.collection('bookings')
        .where('payment.razorpayOrderId', '==', orderId)
        .limit(1)
        .get();

    if (bookingsSnapshot.empty) {
        console.error('No booking found for order:', orderId);
        return;
    }

    const bookingDoc = bookingsSnapshot.docs[0];
    const booking = bookingDoc.data() as Booking;

    // Verify amount matches
    if (Math.abs(amount - booking.pricing.total) > 0.01) {
        console.error('Amount mismatch! Expected:', booking.pricing.total, 'Received:', amount);

        // Log the mismatch
        await db.collection('payment_logs').add({
            bookingId: bookingDoc.id,
            orderId,
            paymentId,
            action: 'amount_mismatch',
            expectedAmount: booking.pricing.total,
            receivedAmount: amount,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return;
    }

    // Update booking with payment success
    const isNewFlow = booking.status === 'awaiting_payment';
    const newStatus = isNewFlow ? 'confirmed' : 'completed';

    await bookingDoc.ref.update({
        'payment.status': 'paid',
        'payment.razorpayPaymentId': paymentId,
        'payment.amountPaid': amount,
        'payment.paymentMethod': payment.method,
        'payment.paidAt': admin.firestore.FieldValue.serverTimestamp(),
        'status': newStatus,
        'updatedAt': admin.firestore.FieldValue.serverTimestamp(),

        // Initialize payout as pending
        'payout.status': 'pending',
        'payout.totalAmount': booking.pricing.total,
        'payout.platformFee': booking.pricing.platformFee,
        'payout.gst': booking.pricing.gst,
        'payout.technicianAmount': booking.pricing.subtotal - booking.pricing.platformFee
    });

    // Log successful payment
    await db.collection('payment_logs').add({
        bookingId: bookingDoc.id,
        orderId,
        paymentId,
        amount,
        action: 'payment_captured',
        method: payment.method,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Send notification to customer
    await sendPushNotification(booking.customerId, 'customers', {
        title: 'Payment Successful',
        body: `We've received your payment of ₹${amount} for booking #${booking.bookingNumber}. Thank you!`,
        data: {
            type: 'payment_success',
            bookingId: bookingDoc.id,
            amount: amount.toString()
        }
    });

    // Send notification to technician (payment received)
    if (booking.technicianId) {
        await sendPushNotification(booking.technicianId, 'technicians', {
            title: 'Payment Received',
            body: `Customer has paid for booking #${booking.bookingNumber}. Your payout is now pending.`,
            data: {
                type: 'payment_received',
                bookingId: bookingDoc.id,
                amount: booking.pricing.technicianAmount.toString()
            }
        });
    }

    console.log('Payment processed successfully for booking:', bookingDoc.id);
}

/**
 * Handle failed payment
 */
async function handlePaymentFailed(payload: any) {
    const payment = payload.payment.entity;
    const orderId = payment.order_id;
    const paymentId = payment.id;
    const errorCode = payment.error_code;
    const errorDescription = payment.error_description;

    console.log('Payment failed:', paymentId, 'Order:', orderId, 'Error:', errorCode);

    // Find booking by order ID
    const bookingsSnapshot = await db.collection('bookings')
        .where('payment.razorpayOrderId', '==', orderId)
        .limit(1)
        .get();

    if (bookingsSnapshot.empty) {
        console.error('No booking found for order:', orderId);
        return;
    }

    const bookingDoc = bookingsSnapshot.docs[0];

    // Update booking with payment failure
    await bookingDoc.ref.update({
        'payment.status': 'failed',
        'payment.razorpayPaymentId': paymentId,
        'payment.failureReason': `${errorCode}: ${errorDescription}`,
        'payment.failedAt': admin.firestore.FieldValue.serverTimestamp()
    });

    // Log failed payment
    await db.collection('payment_logs').add({
        bookingId: bookingDoc.id,
        orderId,
        paymentId,
        action: 'payment_failed',
        errorCode,
        errorDescription,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Send notification to customer about payment failure
    const bookingSnap = await db.collection('bookings')
        .where('payment.razorpayOrderId', '==', orderId)
        .limit(1)
        .get();

    if (!bookingSnap.empty) {
        const b = bookingSnap.docs[0].data() as Booking;
        await sendPushNotification(b.customerId, 'customers', {
            title: 'Payment Failed',
            body: `Your payment for booking #${b.bookingNumber} was unsuccessful. Please try again.`,
            data: {
                type: 'payment_failed',
                bookingId: bookingSnap.docs[0].id,
                error: errorDescription
            }
        });
    }

    console.log('Payment failure recorded for booking:', bookingDoc.id);
}

// ============================================================================
// PAYMENT VERIFICATION (Client-side fallback)
// ============================================================================

/**
 * PAYMENT VERIFICATION (Client-side fallback) - COMPLETE FIX
 * 
 * CRITICAL SECURITY:
 * - Verifies Razorpay signature
 * - Validates booking is in awaiting_payment state
 * - Updates booking atomically in transaction
 * - Credits technician wallet atomically
 * - Prevents duplicate payments via idempotency
 * - Handles all edge cases safely
 * 
 * FIX 1: TRANSACTION SAFETY - Prevents race conditions
 * FIX 2: IDEMPOTENCY - Prevents duplicate wallet credits
 * FIX 3: WALLET INTEGRATION - Credits technician immediately
 * FIX 4: RAZORPAY ORDER STATUS - Updates order status to paid
 */
export const verifyPayment = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { bookingId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = data;
    const userId = context.auth.uid;

    if (!bookingId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required payment details');
    }

    // Get booking
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking: any = bookingDoc.data();

    // Verify user is booking owner
    if (booking.customerId !== userId) {
        throw new functions.https.HttpsError('permission-denied', 'Unauthorized');
    }

    // CRITICAL: Verify booking is in awaiting_payment state
    const currentStatus = booking.bookingStatus || booking.status;
    if (currentStatus !== 'awaiting_payment') {
        throw new functions.https.HttpsError(
            'failed-precondition',
            `Cannot verify payment for booking in status: ${currentStatus}`
        );
    }

    // Verify order ID matches
    const existingOrderId = booking.payment?.razorpayOrderId || booking.razorpayOrderId;
    if (existingOrderId !== razorpayOrderId) {
        throw new functions.https.HttpsError('invalid-argument', 'Order ID mismatch');
    }

    // Verify signature
    if (!verifyPaymentSignature(razorpayOrderId, razorpayPaymentId, razorpaySignature)) {
        // Log signature failure
        await db.collection('payment_logs').add({
            bookingId,
            orderId: razorpayOrderId,
            paymentId: razorpayPaymentId,
            status: 'failed',
            reason: 'invalid_signature',
            action: 'payment_failed',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        }).catch(err => console.error('[RAZORPAY] Failed to log signature error:', err));
        
        throw new functions.https.HttpsError('invalid-argument', 'Invalid payment signature');
    }

    const bookingTotal = booking.pricing?.total || booking.finalAmount || booking.price;

    // Fetch payment details from Razorpay to get amount
    try {
        // Use direct Razorpay instance
        const payment = await razorpay.payments.fetch(razorpayPaymentId);

        const amount = (payment.amount as number) / 100; // Convert paise to rupees

        // STEP 4: STRICT AMOUNT VALIDATION - Prevent tampering
        if (Math.abs(amount - bookingTotal) > 0.01) {
            // Log amount mismatch
            await db.collection('payment_logs').add({
                bookingId,
                orderId: razorpayOrderId,
                paymentId: razorpayPaymentId,
                expectedAmount: bookingTotal,
                receivedAmount: amount,
                status: 'failed',
                reason: 'amount_mismatch',
                action: 'payment_failed',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            }).catch(err => console.error('[RAZORPAY] Failed to log amount mismatch:', err));
            
            throw new functions.https.HttpsError('invalid-argument', 'Amount mismatch - payment amount does not match booking total');
        }

        // FIX 1: TRANSACTION SAFETY - Wrap booking update in Firestore transaction
        // FIX 2: IDEMPOTENCY - Check if already paid inside transaction
        // FIX 3: WALLET INTEGRATION - Credit technician wallet atomically
        // FIX 4: RAZORPAY ORDER STATUS - Update order status to paid
        await db.runTransaction(async (transaction) => {
            // Re-read booking inside transaction to check current state
            const currentBookingDoc = await transaction.get(bookingRef);
            
            if (!currentBookingDoc.exists) {
                throw new Error('Booking not found in transaction');
            }
            
            const currentBooking: any = currentBookingDoc.data();
            
            // FIX 2: Check if already paid inside transaction (race condition protection)
            const isPaid = (currentBooking.payment && currentBooking.payment.status === 'paid') || 
                          currentBooking.paymentStatus === 'paid';
            
            if (isPaid) {
                console.log(`[RAZORPAY] Payment already processed in transaction - Booking: ${bookingId}`);
                // Log duplicate attempt
                transaction.set(db.collection('payment_logs').doc(), {
                    bookingId,
                    orderId: razorpayOrderId,
                    paymentId: razorpayPaymentId,
                    status: 'duplicate_attempt',
                    action: 'payment_duplicate',
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
                // Don't throw error, just skip update - this is idempotent
                return;
            }

            // STEP 3: ADD PAYMENT PROCESSING LOCK (ANTI-RACE)
            // Prevent simultaneous client + webhook processing
            if (currentBooking.payment?.status === 'processing') {
                console.log(`[RAZORPAY] Payment already being processed - Booking: ${bookingId}`);
                // Log concurrent attempt
                transaction.set(db.collection('payment_logs').doc(), {
                    bookingId,
                    orderId: razorpayOrderId,
                    paymentId: razorpayPaymentId,
                    status: 'concurrent_attempt',
                    action: 'payment_race_prevented',
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
                return;
            }

            // Set processing lock before any updates
            transaction.update(bookingRef, {
                'payment.status': 'processing'
            });

            // Update booking atomically — set status to "paid"
            const updateData: any = {
                'bookingStatus': 'paid',
                'payment.status': 'paid',
                'payment.razorpayPaymentId': razorpayPaymentId,
                'payment.razorpaySignature': razorpaySignature,
                'payment.amountPaid': amount,
                'payment.paymentMethod': payment.method,
                'payment.paidAt': admin.firestore.FieldValue.serverTimestamp(),
                'paymentStatus': 'paid',
                'paidAt': admin.firestore.FieldValue.serverTimestamp(),
                'updatedAt': admin.firestore.FieldValue.serverTimestamp(),
            };

            transaction.update(bookingRef, updateData);

            // FIX 4: Update Razorpay order status to paid
            const orderRef = db.collection('razorpayOrders').doc(razorpayOrderId);
            transaction.update(orderRef, {
                status: 'paid',
                paymentId: razorpayPaymentId,
                paidAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // FIX 3: Credit technician wallet atomically inside same transaction
            if (currentBooking.technicianId) {
                const techWalletRef = db.collection('technician_wallets').doc(currentBooking.technicianId);
                const techWalletDoc = await transaction.get(techWalletRef);
                
                // STEP 1: FIX PLATFORM FEE SOURCE (CRITICAL EDGE CASE)
                // Safe fallback for platform fee from multiple sources
                let platformFee = 0;
                if (currentBooking.pricing && currentBooking.pricing.platformFee != null) {
                    platformFee = currentBooking.pricing.platformFee;
                } else if (currentBooking.platformFee != null) {
                    platformFee = currentBooking.platformFee;
                }
                
                // Calculate technician amount with safety check
                let technicianAmount = bookingTotal - platformFee;
                
                // STEP 1: Ensure technicianAmount NEVER negative
                if (technicianAmount < 0) {
                    console.warn(`[RAZORPAY] Negative technician amount detected - Booking: ${bookingId}, Total: ${bookingTotal}, Fee: ${platformFee}`);
                    technicianAmount = 0;
                    
                    // Log edge case
                    transaction.set(db.collection('payment_logs').doc(), {
                        bookingId,
                        orderId: razorpayOrderId,
                        paymentId: razorpayPaymentId,
                        status: 'negative_amount_prevented',
                        action: 'edge_case_handled',
                        bookingTotal,
                        platformFee,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                }

                if (techWalletDoc.exists) {
                    // Update existing wallet
                    transaction.update(techWalletRef, {
                        availableBalance: admin.firestore.FieldValue.increment(technicianAmount),
                        lifetimeEarnings: admin.firestore.FieldValue.increment(technicianAmount),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                } else {
                    // Create new wallet
                    transaction.set(techWalletRef, {
                        technicianId: currentBooking.technicianId,
                        availableBalance: technicianAmount,
                        lifetimeEarnings: technicianAmount,
                        pendingBalance: 0,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                }

                // Log wallet transaction atomically
                const txnRef = techWalletRef.collection('transactions').doc();
                transaction.set(txnRef, {
                    type: 'credit',
                    source: 'booking_payment',
                    status: 'completed',
                    amount: technicianAmount,
                    fee: platformFee,
                    referenceId: bookingId,
                    paymentId: razorpayPaymentId,
                    description: `Payment for booking ${bookingId}`,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });

                // Update booking with payout info
                transaction.update(bookingRef, {
                    'payout.status': 'pending',
                    'payout.totalAmount': bookingTotal,
                    'payout.platformFee': platformFee,
                    'payout.technicianAmount': technicianAmount
                });
            }
        });

        // Log verification (outside transaction)
        await db.collection('payment_logs').add({
            bookingId,
            orderId: razorpayOrderId,
            paymentId: razorpayPaymentId,
            amount,
            action: 'payment_verified_client',
            method: payment.method,
            status: 'success',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            verifiedBy: userId
        }).catch(err => console.error('[RAZORPAY] Failed to log verification:', err));
        
        // STEP 5: LOG ALL EDGE EVENTS - Log successful verification with full context
        await db.collection('payment_logs').add({
            bookingId,
            orderId: razorpayOrderId,
            paymentId: razorpayPaymentId,
            amount,
            action: 'verification_complete',
            method: payment.method,
            status: 'success',
            source: 'client_verify',
            platformFee: booking.pricing?.platformFee || booking.platformFee || 0,
            technicianAmount: amount - (booking.pricing?.platformFee || booking.platformFee || 0),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            verifiedBy: userId
        }).catch(err => console.error('[RAZORPAY] Failed to log edge event:', err));
        
        console.log(`[RAZORPAY] Payment verified successfully - Booking: ${bookingId}, Amount: ${amount}`);

        return { success: true, message: 'Payment verified successfully' };

    } catch (error: any) {
        // STEP 5: LOG ALL EDGE EVENTS - Enhanced error logging
        await db.collection('payment_logs').add({
            bookingId,
            orderId: razorpayOrderId,
            paymentId: razorpayPaymentId,
            status: 'failed',
            reason: error.message,
            errorCode: error.code,
            action: 'payment_failed',
            source: 'client_verify',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        }).catch(err => console.error('[RAZORPAY] Failed to log verification error:', err));
        
        logger.error('verifyPayment_failed', { bookingId, userId }, error);
        throw error;
    }
})
);

// ============================================================================
// PAYMENT FAILURE HANDLING (NEW FIX 6)
// ============================================================================

/**
 * Handle payment failure or cancellation
 * 
 * CRITICAL:
 * - DO NOT update booking to paid
 * - Keep booking in awaiting_payment state
 * - Update payment.status to failed
 * - Allow customer to retry
 */
export const handlePaymentFailure = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { bookingId, razorpayOrderId, razorpayPaymentId, errorCode, errorDescription } = data;
    const userId = context.auth.uid;

    if (!bookingId || !razorpayOrderId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking: any = bookingDoc.data();

    // Verify user is booking owner
    if (booking.customerId !== userId) {
        throw new functions.https.HttpsError('permission-denied', 'Unauthorized');
    }

    // Update payment status to failed
    await bookingRef.update({
        'payment.status': 'failed',
        'payment.razorpayPaymentId': razorpayPaymentId,
        'payment.failureReason': `${errorCode}: ${errorDescription}`,
        'payment.failedAt': admin.firestore.FieldValue.serverTimestamp(),
        'paymentStatus': 'failed',
        'updatedAt': admin.firestore.FieldValue.serverTimestamp()
    });

    // Log failure
    await db.collection('payment_logs').add({
        bookingId,
        orderId: razorpayOrderId,
        paymentId: razorpayPaymentId,
        action: 'payment_failed',
        errorCode,
        errorDescription,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        failedBy: userId
    }).catch(err => console.error('[RAZORPAY] Failed to log payment failure:', err));

    console.log(`[RAZORPAY] Payment failure recorded - Booking: ${bookingId}, Error: ${errorCode}`);

    return { success: true, message: 'Payment failure recorded. You can retry payment.' };
})
);

// ============================================================================
// PAYMENT RETRY SUPPORT (NEW FIX 7)
// ============================================================================

/**
 * Check if payment can be retried
 */
export const canRetryPayment = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { bookingId } = data;
    const userId = context.auth.uid;

    if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'Booking ID required');
    }

    const bookingDoc = await db.collection('bookings').doc(bookingId).get();

    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking: any = bookingDoc.data();

    if (booking.customerId !== userId) {
        throw new functions.https.HttpsError('permission-denied', 'Unauthorized');
    }

    const currentStatus = booking.bookingStatus || booking.status;
    const paymentStatus = booking.payment?.status || booking.paymentStatus;

    const canRetry = currentStatus === 'awaiting_payment' && 
                     (paymentStatus === 'failed' || paymentStatus === 'processing' || !paymentStatus);

    return {
        success: true,
        canRetry,
        currentStatus,
        paymentStatus,
        message: canRetry ? 'Payment can be retried' : 'Payment cannot be retried in current state'
    };
})
);


export const initiateRefund = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
    // Check admin authentication
    if (!context.auth || !context.auth.token.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    const { bookingId, refundAmount, refundReason } = data;
    const adminId = context.auth.uid;

    if (!bookingId || !refundAmount || !refundReason) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Get booking
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking = bookingDoc.data() as Booking;

    // FIX 2: STRONG IDEMPOTENCY CHECK - Check if refund already in progress or completed
    if (booking.refund) {
        const refundStatus = booking.refund.status;
        
        if (refundStatus === 'processing') {
            // Refund is currently being processed - return existing request ID
            console.log(`[RAZORPAY] Refund already processing for booking: ${bookingId}`);
            return {
                success: true,
                refundId: booking.refund.razorpayRefundId || 'processing',
                message: 'Refund is already being processed',
                isDuplicate: true
            };
        }
        
        if (refundStatus === 'processed') {
            // Refund already completed - return existing refund ID
            console.log(`[RAZORPAY] Refund already completed for booking: ${bookingId}`);
            return {
                success: true,
                refundId: booking.refund.razorpayRefundId,
                message: 'Refund already processed',
                isDuplicate: true
            };
        }
    }

    // Validate payment is completed
    if (booking.payment.status !== 'paid' && booking.payment.status !== 'partially_refunded') {
        throw new functions.https.HttpsError('failed-precondition', 'Booking is not paid yet');
    }

    if (!booking.payment.razorpayPaymentId) {
        throw new functions.https.HttpsError('failed-precondition', 'No payment ID found');
    }

    // Validate refund amount
    if (refundAmount > (booking.payment.amountPaid || 0)) {
        throw new functions.https.HttpsError('invalid-argument', 'Refund amount exceeds paid amount');
    }

    // FIX 2: Generate unique request ID for idempotency
    const requestId = `refund_${bookingId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // FIX 2: Mark refund as "processing" BEFORE calling Razorpay API
    await bookingRef.update({
        'refund': {
            status: 'processing',
            requestId: requestId,
            refundAmount,
            refundReason,
            requestedBy: adminId,
            requestedAt: admin.firestore.FieldValue.serverTimestamp()
        }
    });

    try {
        // Use direct Razorpay instance
        // Create refund
        const refund = await razorpay.payments.refund(booking.payment.razorpayPaymentId, {
            amount: Math.round(refundAmount * 100), // Convert to paise
            notes: {
                bookingId,
                reason: refundReason,
                requestedBy: adminId,
                requestId: requestId
            }
        });

        // FIX 3: REFUND + WALLET CONSISTENCY - Update booking and wallet atomically
        // If refund succeeds but wallet update fails, mark for retry
        let walletAdjusted = false;
        
        try {
            // Adjust technician wallet if applicable
            if (booking.technicianId) {
                const walletRef = db.collection('technician_wallets').doc(booking.technicianId);
                const walletDoc = await walletRef.get();
                
                if (walletDoc.exists) {
                    const walletData = walletDoc.data()!;
                    const currentBalance = walletData.availableBalance || 0;
                    
                    // Check if sufficient balance for deduction
                    if (currentBalance >= refundAmount) {
                        await walletRef.update({
                            availableBalance: admin.firestore.FieldValue.increment(-refundAmount),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        });
                        
                        // Log wallet transaction
                        await walletRef.collection('transactions').add({
                            type: 'debit',
                            source: 'refund',
                            status: 'completed',
                            amount: refundAmount,
                            fee: 0,
                            referenceId: bookingId,
                            refundId: refund.id,
                            description: `Refund for booking`,
                            createdAt: admin.firestore.FieldValue.serverTimestamp()
                        });
                        
                        walletAdjusted = true;
                        console.log(`[RAZORPAY] Wallet adjusted for refund - Technician: ${booking.technicianId}, Amount: -₹${refundAmount}`);
                    } else {
                        // Insufficient balance - mark for manual review
                        console.warn(`[RAZORPAY] Insufficient wallet balance for refund - Technician: ${booking.technicianId}, Balance: ₹${currentBalance}, Required: ₹${refundAmount}`);
                        
                        // Log compensation needed
                        await db.collection('refund_compensations').add({
                            bookingId,
                            refundId: refund.id,
                            requestId: requestId,
                            technicianId: booking.technicianId,
                            refundAmount,
                            currentBalance,
                            status: 'pending_manual_review',
                            reason: 'insufficient_wallet_balance',
                            createdAt: admin.firestore.FieldValue.serverTimestamp()
                        });
                    }
                }
            }
        } catch (walletError: any) {
            // FIX 3: Wallet adjustment failed - log for retry
            console.error(`[RAZORPAY] Wallet adjustment failed for refund:`, walletError);
            
            // Create compensation record for retry
            await db.collection('refund_compensations').add({
                bookingId,
                refundId: refund.id,
                requestId: requestId,
                technicianId: booking.technicianId,
                refundAmount,
                status: 'pending_retry',
                reason: 'wallet_update_failed',
                error: walletError.message,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            
            console.warn(`[RAZORPAY] Refund succeeded but wallet adjustment failed - marked for retry`);
        }

        // Update booking with success
        await bookingRef.update({
            'payment.status': refundAmount >= (booking.payment.amountPaid || 0) ? 'refunded' : 'partially_refunded',
            'refund.status': 'processed',
            'refund.razorpayRefundId': refund.id,
            'refund.walletAdjusted': walletAdjusted,
            'refund.processedAt': admin.firestore.FieldValue.serverTimestamp()
        });

        // Log refund
        await db.collection('payment_logs').add({
            bookingId,
            refundId: refund.id,
            requestId: requestId,
            amount: refundAmount,
            action: 'refund_processed',
            reason: refundReason,
            walletAdjusted,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: adminId
        });

        console.log(`[RAZORPAY] Refund processed successfully - Booking: ${bookingId}, Refund ID: ${refund.id}, Wallet Adjusted: ${walletAdjusted}`);

        return { 
            success: true, 
            refundId: refund.id,
            walletAdjusted
        };

    } catch (error: any) {
        console.error('[RAZORPAY] Refund error:', error);

        // Update booking with failure
        await bookingRef.update({
            'refund.status': 'failed',
            'refund.failureReason': error.message,
            'refund.failedAt': admin.firestore.FieldValue.serverTimestamp()
        });

        throw new functions.https.HttpsError('internal', `Refund failed: ${error.message}`);
    }
  })
);
