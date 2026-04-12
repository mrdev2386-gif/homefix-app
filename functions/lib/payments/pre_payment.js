"use strict";
/**
 * PRE-PAYMENT FLOW (Pay Before Work)
 *
 * Flow:
 * 1. createPrePaymentOrder  → fetch price from DB, create Razorpay order, store pending_payment_intents
 * 2. verifyAndCreateBooking → verify signature, atomically create booking with paymentStatus: 'paid'
 *
 * SECURITY:
 * - Amount ALWAYS from DB (never client)
 * - Booking only created after verified payment
 * - Idempotency via razorpayOrderId
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyAndCreateBooking = exports.createPrePaymentOrder = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const crypto_1 = __importDefault(require("crypto"));
const security_1 = require("../shared/security");
const { razorpay } = require('../config/razorpay');
const db = admin.firestore();
const getRazorpaySecret = () => {
    const secret = functions.config().razorpay?.key_secret;
    if (!secret)
        throw new functions.https.HttpsError('failed-precondition', 'Razorpay not configured');
    return secret;
};
const getRazorpayKeyId = () => {
    const key = functions.config().razorpay?.key_id;
    if (!key)
        throw new functions.https.HttpsError('failed-precondition', 'Razorpay not configured');
    return key;
};
// ============================================================================
// STEP 1: CREATE PRE-PAYMENT ORDER (no booking created yet)
// ============================================================================
exports.createPrePaymentOrder = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { serviceId, technicianId, categoryId, categoryName, scheduledDate, scheduledTime, address, subcategoryId, quantity, paymentMode } = data;
    if (!serviceId || !technicianId || !categoryId || !scheduledDate || !scheduledTime || !address) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required booking fields');
    }
    // Fetch price from DB — NEVER trust client
    const serviceDoc = await db.collection('technician_services').doc(serviceId).get();
    if (!serviceDoc.exists)
        throw new functions.https.HttpsError('not-found', 'Service not found');
    const serviceData = serviceDoc.data();
    if (serviceData.status !== 'approved')
        throw new functions.https.HttpsError('failed-precondition', 'Service not available');
    if (serviceData.technicianId !== technicianId)
        throw new functions.https.HttpsError('invalid-argument', 'Service/technician mismatch');
    const basePrice = serviceData.price;
    // STRICT SAFE PARSING - SINGLE SOURCE OF TRUTH
    // Parse base price with NaN validation
    const parsedPrice = Number(basePrice);
    const calculatedPrice = (!isNaN(parsedPrice) && parsedPrice > 0) ? parsedPrice : 0;
    // Parse offer price with NaN validation
    const parsedOffer = Number(serviceData.offerPrice);
    const offer = (!isNaN(parsedOffer) && parsedOffer > 0) ? parsedOffer : null;
    // CRITICAL FIX: Apply offerPrice if valid (no hasOffer check - field doesn't exist)
    // Edge cases handled:
    // - offerPrice null/undefined → use price
    // - offerPrice = 0 → treat as null
    // - offerPrice NaN → treat as null
    // - offerPrice >= price → ignore offer
    let finalPrice = calculatedPrice;
    if (offer !== null && offer < calculatedPrice) {
        finalPrice = offer;
    }
    console.log('[PRE_PAYMENT PRICE DEBUG]', {
        rawBasePrice: basePrice,
        rawOfferPrice: serviceData.offerPrice,
        parsedPrice,
        parsedOffer,
        calculatedPrice,
        offer,
        finalPrice,
        discountApplied: finalPrice < calculatedPrice,
        validation: `offer=${offer}, price=${calculatedPrice}, valid=${offer !== null && offer < calculatedPrice}`
    });
    if (typeof finalPrice !== 'number' || finalPrice <= 0) {
        console.error('❌ [PRE_PAYMENT] Invalid final price calculated:', finalPrice);
        throw new functions.https.HttpsError('internal', 'Invalid service price');
    }
    // Verify technician
    const techDoc = await db.collection('technicians').doc(technicianId).get();
    if (!techDoc.exists)
        throw new functions.https.HttpsError('not-found', 'Technician not found');
    const techData = techDoc.data();
    if (techData.verificationStatus !== 'approved' && techData.status !== 'approved') {
        throw new functions.https.HttpsError('failed-precondition', 'Technician not verified');
    }
    // Verify customer
    const customerDoc = await db.collection('customers').doc(uid).get();
    if (!customerDoc.exists)
        throw new functions.https.HttpsError('not-found', 'Customer profile not found');
    const amountPaise = Math.round(finalPrice * 100);
    // Create Razorpay order
    const order = await razorpay.orders.create({
        amount: amountPaise,
        currency: 'INR',
        receipt: `pre_${uid}_${Date.now()}`,
        notes: {
            customerId: uid,
            serviceId,
            technicianId,
            paymentMode: 'before_work',
        },
    });
    // Store payment intent — booking NOT created yet
    await db.collection('pending_payment_intents').doc(order.id).set({
        razorpayOrderId: order.id,
        customerId: uid,
        customerName: customerDoc.data()?.name || 'Customer',
        customerPhone: customerDoc.data()?.phone || '',
        technicianId,
        technicianName: techData.name || 'Technician',
        technicianPhone: techData.phone || '',
        serviceId,
        serviceName: serviceData.name || serviceData.title || 'Service',
        categoryId: serviceData.categoryId || categoryId,
        categoryName: categoryName || serviceData.category || 'Service',
        subcategoryId: subcategoryId || null,
        scheduledDate,
        scheduledTime,
        address,
        basePrice: calculatedPrice,
        finalPrice,
        discountAmount: calculatedPrice - finalPrice,
        quantity: quantity || 1,
        paymentMode: 'before_work',
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000)), // 30 min TTL
    });
    console.log(`[PRE_PAYMENT] Order created: ${order.id} for customer: ${uid}, amount: ₹${finalPrice}`);
    return {
        success: true,
        orderId: order.id,
        amount: amountPaise,
        currency: 'INR',
        key: getRazorpayKeyId(),
        finalPrice,
        serviceName: serviceData.name || serviceData.title,
    };
}));
// ============================================================================
// STEP 2: VERIFY PAYMENT + CREATE BOOKING ATOMICALLY
// ============================================================================
exports.verifyAndCreateBooking = functions
    .region('asia-south1')
    .https.onCall((0, security_1.secureCallable)(async (data, context) => {
    console.log('ENTRY FUNCTION CALLED: verifyAndCreateBooking');
    const uid = context.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature, idempotencyKey } = data;
    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing payment verification fields');
    }
    // 1. Verify signature
    const expectedSignature = crypto_1.default
        .createHmac('sha256', getRazorpaySecret())
        .update(`${razorpayOrderId}|${razorpayPaymentId}`)
        .digest('hex');
    if (expectedSignature !== razorpaySignature) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid payment signature');
    }
    // 2. Fetch payment intent
    const intentRef = db.collection('pending_payment_intents').doc(razorpayOrderId);
    const intentDoc = await intentRef.get();
    if (!intentDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Payment intent not found or expired');
    }
    const intent = intentDoc.data();
    if (intent.customerId !== uid) {
        throw new functions.https.HttpsError('permission-denied', 'Unauthorized');
    }
    // 3. Idempotency — if booking already created for this order, return it
    if (intent.status === 'completed' && intent.bookingId) {
        console.log(`[VERIFY_BOOKING] Idempotent hit for order: ${razorpayOrderId}`);
        return { success: true, bookingId: intent.bookingId, bookingStatus: 'pending_admin_review', isDuplicate: true };
    }
    // 4. Verify amount with Razorpay
    const payment = await razorpay.payments.fetch(razorpayPaymentId);
    const paidAmountRupees = payment.amount / 100;
    if (Math.abs(paidAmountRupees - intent.finalPrice) > 1) {
        throw new functions.https.HttpsError('invalid-argument', `Amount mismatch: paid ₹${paidAmountRupees}, expected ₹${intent.finalPrice}`);
    }
    // 5. Store payment verification for booking creation
    // The booking will be created by a separate Cloud Function that processes payment intents
    await db.collection('verified_payments').doc(razorpayOrderId).set({
        razorpayOrderId,
        razorpayPaymentId,
        customerId: uid,
        ...intent,
        status: 'verified',
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {
        success: true,
        message: 'Payment verified. Booking will be created shortly.',
        orderId: razorpayOrderId,
    };
}));
//# sourceMappingURL=pre_payment.js.map