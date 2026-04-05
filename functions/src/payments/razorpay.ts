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
const Razorpay = require('razorpay');
import crypto from 'crypto';
import { sendPushNotification } from '../shared/notifications';
import { secureCallable } from '../shared/security';
import { logger } from '../shared/utils';

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

// Lazy-loaded Razorpay instance
let razorpayInstance: any = null;

// Initialize Razorpay (lazy loading) - PURE CommonJS
// Store keys in Firebase Functions config: firebase functions:config:set razorpay.key_id="xxx" razorpay.key_secret="xxx"
const getRazorpayInstance = () => {
    if (razorpayInstance) {
        return razorpayInstance;
    }

    const { key_id, key_secret } = getRazorpayConfig();

    console.log('[RAZORPAY] Initializing Razorpay SDK...');
    console.log('[RAZORPAY] Razorpay class:', typeof Razorpay);

    razorpayInstance = new Razorpay({
        key_id,
        key_secret
    }) as any;

    console.log('[RAZORPAY] TYPE:', typeof razorpayInstance);
    console.log('[RAZORPAY] CONTACTS:', razorpayInstance.contacts);
    console.log('[RAZORPAY] Instance created:', !!razorpayInstance);
    console.log('[RAZORPAY] typeof instance.orders:', typeof razorpayInstance.orders);
    console.log('[RAZORPAY] typeof instance.orders.create:', typeof razorpayInstance.orders?.create);
    console.log('[RAZORPAY] typeof instance.payments:', typeof razorpayInstance.payments);
    console.log('[RAZORPAY] typeof instance.payments.fetch:', typeof razorpayInstance.payments?.fetch);

    // Strict validation - methods MUST be functions
    if (!razorpayInstance.orders) {
        console.error('[RAZORPAY] FULL INSTANCE:', JSON.stringify(razorpayInstance, null, 2));
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Razorpay instance.orders is undefined'
        );
    }

    if (typeof razorpayInstance.orders.create !== 'function') {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Razorpay instance not properly initialized - orders.create is not a function'
        );
    }

    if (!razorpayInstance.payments) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Razorpay instance.payments is undefined'
        );
    }

    if (typeof razorpayInstance.payments.fetch !== 'function') {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Razorpay instance not properly initialized - payments.fetch is not a function'
        );
    }

    console.log('[RAZORPAY] ✅ Razorpay SDK initialized successfully');
    return razorpayInstance;
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
        const razorpay = getRazorpayInstance();

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
 * - Validates booking is in payable state (awaiting_payment OR completed)
 * - Validates pricing is locked
 * - Amount comes ONLY from Firestore
 * - Supports DUAL PAYMENT FLOW:
 *   1. Online payment (before service) - status: awaiting_payment
 *   2. After-service payment - status: completed
 * 
 * Called by: Customer app after booking creation (online) OR after work completion (after-service)
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

    // Validation 2: Check payment method
    const paymentMethod = booking.payment?.paymentMethod || booking.paymentMethod || 'after_service';
    
    // Validation 3: Booking must be in a payable state based on payment method
    if (paymentMethod === 'online') {
        // Online payment: must be in awaiting_payment or pending state
        const validStatuses = ['awaiting_payment', 'pending', 'approved_by_admin', 'pending_admin_approval'];
        if (!validStatuses.includes(booking.status) && !validStatuses.includes(booking.bookingStatus)) {
            throw new functions.https.HttpsError(
                'failed-precondition',
                `Online payment not allowed. Booking status is "${booking.status || booking.bookingStatus}".`
            );
        }
    } else {
        // After-service payment: must be completed
        const validStatuses = ['awaiting_payment', 'completed', 'service_completed'];
        if (!validStatuses.includes(booking.status) && !validStatuses.includes(booking.bookingStatus)) {
            throw new functions.https.HttpsError(
                'failed-precondition',
                `Payment not allowed. Booking status is "${booking.status || booking.bookingStatus}".`
            );
        }
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
        // Initialize Razorpay
        const razorpay = getRazorpayInstance();

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
                paymentMethod
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
            'payment.paymentMethod': paymentMethod,
            'payment.retryCount': admin.firestore.FieldValue.increment(1),
            'razorpayOrderId': order.id,
            'paymentStatus': 'processing',
            'paymentMethod': paymentMethod
        });

        // Log the order creation
        await db.collection('payment_logs').add({
            bookingId,
            orderId: order.id,
            amount: bookingTotal,
            currency: 'INR',
            paymentMethod,
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
            paymentMethod
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
 * Verify payment (called by client after Razorpay checkout success)
 * 
 * This is a fallback in case webhook fails or is delayed
 * Still verifies signature for security
 * FIX 4: TRANSACTION SAFETY - Prevents race conditions
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

    // Verify order ID matches
    const existingOrderId = booking.payment?.razorpayOrderId || booking.razorpayOrderId;
    if (existingOrderId !== razorpayOrderId) {
        throw new functions.https.HttpsError('invalid-argument', 'Order ID mismatch');
    }

    // Verify signature
    if (!verifyPaymentSignature(razorpayOrderId, razorpayPaymentId, razorpaySignature)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid payment signature');
    }

    const bookingTotal = booking.pricing?.total || booking.finalAmount || booking.price;

    // Fetch payment details from Razorpay to get amount
    try {
        const razorpay = getRazorpayInstance();
        const payment = await razorpay.payments.fetch(razorpayPaymentId);

        const amount = (payment.amount as number) / 100; // Convert paise to rupees

        // Verify amount
        if (Math.abs(amount - bookingTotal) > 0.01) {
            throw new functions.https.HttpsError('invalid-argument', 'Amount mismatch');
        }

        // FIX 4: TRANSACTION SAFETY - Wrap booking update in Firestore transaction
        await db.runTransaction(async (transaction) => {
            // Re-read booking inside transaction to check current state
            const currentBookingDoc = await transaction.get(bookingRef);
            
            if (!currentBookingDoc.exists) {
                throw new Error('Booking not found in transaction');
            }
            
            const currentBooking: any = currentBookingDoc.data();
            
            // FIX 4: Check if already paid inside transaction (race condition protection)
            const isPaid = (currentBooking.payment && currentBooking.payment.status === 'paid') || 
                          currentBooking.paymentStatus === 'paid';
            
            if (isPaid) {
                console.log(`[RAZORPAY] Payment already processed in transaction - Booking: ${bookingId}`);
                // Don't throw error, just skip update - this is idempotent
                return;
            }

            // Update booking atomically
            const isNewFlow = currentBooking.status === 'awaiting_payment' || 
                            currentBooking.status === 'pending_admin_review' || 
                            currentBooking.status === 'pending';
            const newStatus = isNewFlow ? 'confirmed' : 'completed';

            const updateData: any = {
                'payment.status': 'paid',
                'payment.razorpayPaymentId': razorpayPaymentId,
                'payment.razorpaySignature': razorpaySignature,
                'payment.amountPaid': amount,
                'payment.paymentMethod': payment.method,
                'payment.paidAt': admin.firestore.FieldValue.serverTimestamp(),
                'status': newStatus,
                'updatedAt': admin.firestore.FieldValue.serverTimestamp(),
                'paymentStatus': 'paid',

                // Initialize payout
                'payout.status': 'pending',
                'payout.totalAmount': bookingTotal,
            };

            if (currentBooking.pricing) {
                updateData['payout.platformFee'] = currentBooking.pricing.platformFee;
                updateData['payout.gst'] = currentBooking.pricing.gst;
                updateData['payout.technicianAmount'] = currentBooking.pricing.subtotal - currentBooking.pricing.platformFee;
            }

            transaction.update(bookingRef, updateData);
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
        
        console.log(`[RAZORPAY] Payment verified successfully - Booking: ${bookingId}, Amount: ${amount}`);

        return { success: true, message: 'Payment verified successfully' };

    } catch (error: any) {
        logger.error('verifyPayment_failed', { bookingId, userId }, error);
        throw error;
    }
})
);

// ============================================================================
// REFUND MANAGEMENT (Admin only)
// ============================================================================

/**
 * Initiate refund (Admin only)
 * FIX 2: STRONG IDEMPOTENCY - Prevents duplicate refunds on retry
 */
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
                refundId: booking.refund.requestId || 'processing',
                message: 'Refund is already being processed',
                isDuplicate: true
            };
        }
        
        if (refundStatus === 'processed' || refundStatus === 'completed') {
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
        const razorpay = getRazorpayInstance();

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

        // Update booking with success
        await bookingRef.update({
            'payment.status': refundAmount >= (booking.payment.amountPaid || 0) ? 'refunded' : 'partially_refunded',
            'refund.status': 'processed',
            'refund.razorpayRefundId': refund.id,
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
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: adminId
        });

        console.log(`[RAZORPAY] Refund processed successfully - Booking: ${bookingId}, Refund ID: ${refund.id}`);

        return { success: true, refundId: refund.id };

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
