import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as testing from './testing';
import { getAppConfig } from './shared/config';
import * as crypto from 'crypto';

// v2 Firestore triggers
import {
    onDocumentCreated,
    onDocumentUpdated,
} from 'firebase-functions/v2/firestore';

// Environment variables for Razorpay configuration
const razorpayKeyId = process.env.RAZORPAY_KEY_ID || '';
const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET || '';

import * as adminDashboard from './admin/dashboard';
import * as adminUsers from './admin/users';
import * as adminTechs from './admin/technicians';
import * as adminServices from './admin/services';
import * as adminBookings from './admin/bookings';
import * as adminFinance from './admin/finance';
import * as adminNotif from './admin/notifications';
import * as adminDynamic from './admin/dynamic_content';
import * as technicianFinance from './finance/wallet_logic';
import * as payoutLogic from './finance/payout_logic';

// Payment Modules (New Razorpay Integration)
import * as razorpayPayments from './payments/razorpay';
import * as technicianPayouts from './payments/payouts';

// Partner Applications
import * as partnerApplications from './partner/applications';

// Chat System
import * as chat from './chat/chat';


if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();

const getDb = () => admin.firestore();

// Helper for lazy loading Razorpay
async function getRazorpay() {
    const Razorpay = (await import('razorpay')).default;
    return new Razorpay({
        key_id: razorpayKeyId || 'rzp_test_placeholder',
        key_secret: razorpayKeySecret || 'placeholder_secret',
    });
}

// Helpers
import { sendPushNotification, NotificationPayload } from './shared/notifications';

// Feature Modules
import * as customerFeatures from './customer_features';
// Smart Matching V2
import { matchAndAssignBooking, handleAssignmentResponse } from './matching/matching_v2';
import { matchTechnicians as matchTechs, updateTechnicianAssignment, cleanupStaleTechnicianStatus } from './matching/technician_matching';
export { matchTechniciansV2 } from './matching/matchTechniciansV2';
export { getEligibleTechnicians } from './matching/engine';

export const matchTechnicians = matchTechs;
export const matchTechniciansForService = matchTechs;
export const updateTechnicianLastAssignment = updateTechnicianAssignment;
export const onStaleTechnicianCleanup = cleanupStaleTechnicianStatus;

// Booking Lifecycle
export { createBookingWithAssignment, respondToBooking, updateBookingStatus, handleBookingTimeouts } from './booking/booking_lifecycle';

// v2 Booking Functions
export { createBookingV2 } from './booking/createBookingV2';
export { razorpayWebhookV2 } from './payments/razorpayWebhookV2';

// Production Hardening
export {
    handlePaymentWebhook,
    createBookingIdempotent,
    checkRateLimit,
    updateTechnicianHeartbeat,
    createPayoutLedgerEntry,
    generateWeeklyPayoutReport,
    getTechnicianEarnings,
    trackAnalyticsEvent,
    validateBookingCreation,
    sanitizeBookingInput,
    cleanupStaleTechnicianHeartbeats,
    cleanupRateLimitRecords,
    checkSystemHealth,
    onBookingStateChange,
    generateAnalyticsSnapshot,
    trackTechnicianMetrics
} from './booking/production_hardening';

/**
 * Scheduled function to remind users about items in their cart.
 * Runs every 4 hours.
 */
export const onCartAbandoned = functions.pubsub.schedule('every 4 hours').onRun(async (context) => {
    const fourHoursAgo = new Date(Date.now() - 4 * 60 * 60 * 1000);

    // Suggestion: Cart items are in customers/{uid}/cart_items
    // But we need a list of users who have items added recently but haven't booked.
    // Let's assume there's a 'lastCartUpdate' field on the customer document.

    const abandonedCarts = await db.collection('customers')
        .where('lastCartUpdate', '>', admin.firestore.Timestamp.fromDate(new Date(Date.now() - 24 * 60 * 60 * 1000))) // Limit to last 24h
        .get();

    for (const doc of abandonedCarts.docs) {
        const data = doc.data();
        // Check if they have items and no recent booking
        const cartItems = await doc.ref.collection('cart_items').get();
        if (!cartItems.empty) {
            await sendPushNotification(doc.id, 'customers', {
                title: 'Items waiting in your cart!',
                body: 'Your selected services are still waiting. Book now to get them fixed today!',
                data: { type: 'cart' }
            });
        }
    }
});

// ==========================================
// TYPES & INTERFACES
// ==========================================

interface CartServiceItem {
    id: string;
    name: string;
    price: number;
    quantity: number;
    image?: string;
}

interface BookingData {
    services: CartServiceItem[];
    technicianId?: string;
    slotId?: string;
    scheduledDate: string | number | Date;
    scheduledTime: string;
    address: any;
    totalAmount: number;
    couponCode?: string;
}

// ==========================================
// CONFIGURATION & HELPERS
// ==========================================

// Redundant Razorpay instance removed. Use getRazorpay() helper.

async function logActivity(actorType: 'customer' | 'technician' | 'admin' | 'system', actorUid: string, action: string, metadata: any) {
    try {
        await db.collection('activity_logs').add({
            actorType,
            actorUid,
            action,
            metadata,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (e) {
        console.error('Failed to log activity:', e);
    }
}

async function checkRateLimit(uid: string, action: string, limit: number, windowMs: number) {
    const now = Date.now();
    const rateLimitRef = db.collection('rate_limits').doc(`${uid}_${action}`);
    const doc = await rateLimitRef.get();

    if (doc.exists) {
        const data = doc.data()!;
        if (now - data.lastReset < windowMs) {
            if (data.count >= limit) {
                throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded. Try again later.');
            }
            await rateLimitRef.update({ count: admin.firestore.FieldValue.increment(1) });
        } else {
            await rateLimitRef.set({ count: 1, lastReset: now });
        }
    } else {
        await rateLimitRef.set({ count: 1, lastReset: now });
    }
}

export async function isAdmin(uid: string) {
    const adminDoc = await db.collection('admins').doc(uid).get();
    return adminDoc.exists;
}

// 1. CUSTOMER CALLABLES
export const createBooking = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    const { services, scheduledDate, scheduledTime, address, totalAmount, couponCode } = data;
    if (!services || services.length === 0 || !address || !totalAmount) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing fields');
    }
    const bookingId = db.collection('bookings').doc().id;
    const finalStatus = 'pending_payment';
    try {
        await db.runTransaction(async (transaction: admin.firestore.Transaction) => {
            const riskDoc = await transaction.get(db.collection('risk_profiles').doc(context.auth!.uid));
            if (riskDoc.exists) {
                const riskData = riskDoc.data()!;
                if (riskData.status === 'suspended') throw new functions.https.HttpsError('permission-denied', 'Account suspended.');
            }
            transaction.set(db.collection('bookings').doc(bookingId), {
                id: bookingId,
                bookingId,
                customerId: context.auth!.uid,
                customerName: context.auth!.token.name || 'Customer',
                addressSnapshot: address,
                status: finalStatus,
                paymentStatus: 'pending',
                price: totalAmount,
                finalAmount: totalAmount,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                services,
                serviceTitle: services[0].name + (services.length > 1 ? ` (+${services.length - 1} more)` : ''),
                scheduledDate,
                scheduledTime,
                scheduledAt: admin.firestore.Timestamp.fromDate(new Date(scheduledDate))
            });
        });
        return { success: true, bookingId, totalAmount };
    } catch (e: any) {
        throw new functions.https.HttpsError('internal', e.message);
    }
});

export const initiateRazorpayPayment = razorpayPayments.createPaymentOrder;
export const verifyRazorpayPayment = razorpayPayments.verifyPayment;
export const processWalletTransaction = technicianFinance.processWalletTransaction;

// Export Customer Features
export const createServiceRequest = customerFeatures.createServiceRequest;
export const updateUserProfile = customerFeatures.updateUserProfile;
export const updateTechnicianProfile = customerFeatures.updateTechnicianProfile;
export const deleteAccount = customerFeatures.deleteAccount;
export const manageAddress = customerFeatures.manageAddress;
export const managePaymentMethod = customerFeatures.managePaymentMethod;
export const updatePrivacySettings = customerFeatures.updatePrivacySettings;
export const validateReferralCode = customerFeatures.validateReferralCode;
export const submitServiceRating = customerFeatures.submitServiceRating;
export const submitSupportRequest = customerFeatures.submitSupportRequest;

// Partner Applications
export const submitPartnerApplication = partnerApplications.submitPartnerApplication;

// Custom Request Features
import * as customRequest from './custom_request';
export const createCustomRequest = customRequest.createCustomRequest;
export const acceptCustomRequest = customRequest.acceptCustomRequest;
export const getMyCustomRequests = customRequest.getMyCustomRequests;
export const cancelCustomRequest = customRequest.cancelCustomRequest;
export const getTechnicianInbox = customRequest.getTechnicianInbox;
export const getCustomRequestDetail = customRequest.getCustomRequestDetail;

// Instant Booking Features
import * as instantBooking from './instant_booking';
export const getInstantServices = instantBooking.getInstantServices;



// ==========================================
// 2. ADMIN & TECH CALLABLES
// ==========================================

export const admin_getDashboardStats = adminDashboard.getDashboardStats;
export const admin_getUsers = adminUsers.getUsers;
export const admin_getUserById = adminUsers.getUserById;
export const admin_updateUser = adminUsers.updateUser;
export const admin_blockUser = adminUsers.blockUser;
export const admin_manageUser = adminUsers.manageUser;

export const admin_getTechnicians = adminTechs.getTechnicians;
export const admin_getTechnicianById = adminTechs.getTechnicianById;
export const admin_updateTechnician = adminTechs.updateTechnician;
export const admin_approveTechnicianApplication = adminTechs.approveTechnicianApplication;
export const admin_approveTechnician = adminTechs.approveTechnician;
export const admin_toggleTechAvailability = adminTechs.toggleTechAvailability;
export const admin_updateTechServices = adminTechs.updateTechServices;

export const admin_manageService = adminServices.manageService;
export const createService = adminServices.createService;
export const createSubService = adminServices.createSubService;
export const updateSubService = adminServices.updateSubService;
export const deleteService = adminServices.deleteService;
export const updatePricingConfig = adminServices.updatePricingConfig;
export const deleteSubService = adminServices.deleteSubService;
export const getSubServicePriceHistory = adminServices.getSubServicePriceHistory;

// Service Nesting Migration (PHASE 12)
export const migrateServicesToNested = adminServices.migrateServicesToNested;

export const admin_manageBooking = adminBookings.adminManageBooking;

import * as adminImages from './admin/images';
export const admin_uploadServiceImage = adminImages.uploadServiceImage;

export const admin_refundBooking = adminFinance.refundBooking;
export const admin_adjustWallet = adminFinance.adjustWallet;

export const admin_sendPushNotification = adminNotif.sendPushNotification;

import * as adminRisk from './admin/risk';
export const admin_manageRiskProfile = adminRisk.manageRiskProfile;

import {
    admin_manageProfessionalVideos,
    admin_manageCleaningEssentials,
    admin_manageServiceBanners,
    admin_manageTechnicianCategories,
    admin_manageTechnicianSubcategories
} from './admin/dynamic_content';

import { admin_initializeHomeContent, admin_backfillImages } from './admin/system_initialization';
import { admin_auditServiceCatalog } from './admin/catalog_audit';
export { temp_recovery_diag } from './temp_audit';


export {
    admin_manageProfessionalVideos,
    admin_manageCleaningEssentials,
    admin_manageServiceBanners,
    admin_initializeHomeContent,
    admin_backfillImages,
    admin_auditServiceCatalog,
    admin_manageTechnicianCategories,
    admin_manageTechnicianSubcategories
};

// Technician Finance & Payouts
export const triggerTechnicianPayout = payoutLogic.triggerTechnicianPayout;
export const razorpayPayoutWebhook = payoutLogic.razorpayPayoutWebhook;
export const settleTechnicianBalance = payoutLogic.settleTechnicianBalance;


// Fraud & Abuse Protection
import * as fraudProtection from './fraud_protection';
export const onBookingStatusUpdateRiskCheck = fraudProtection.onBookingStatusUpdateRiskCheck;
export const onReviewRiskCheck = fraudProtection.onReviewRiskCheck;
export const onPaymentStatusRiskCheck = fraudProtection.onPaymentStatusRiskCheck;
export const onTechnicianProfileUpdateRiskCheck = fraudProtection.onTechnicianProfileUpdateRiskCheck;


// SMART MATCHING V2
export const assignTechnicianToBooking = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    // Check Admin or System role
    if (!(await isAdmin(context.auth.uid))) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can force assignment');
    }
    return await matchAndAssignBooking(data.bookingId, { forceAssign: true });
});

export const respondToAssignment = handleAssignmentResponse;

// ==========================================
// FCM TOKEN MANAGEMENT
// ==========================================

/**
 * Saves FCM token for a user (customer or technician)
 * Supports multiple devices by storing tokens in a subcollection
 */
export const saveFcmToken = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "User not logged in");
    }

    const { token, platform = 'unknown', userType = 'customer' } = data;

    if (!token) {
        throw new functions.https.HttpsError("invalid-argument", "Token is required");
    }

    try {
        // Determine the correct collection based on userType
        const collectionPath = userType === 'technician' ? 'technicians' : 'customers';
        const userDocRef = db.collection(collectionPath).doc(uid);

        // Check if user document exists
        const userDoc = await userDocRef.get();
        if (!userDoc.exists) {
            // Try the other collection
            const otherCollection = userType === 'technician' ? 'customers' : 'technicians';
            const otherUserDoc = await db.collection(otherCollection).doc(uid).get();
            if (!otherUserDoc.exists) {
                throw new functions.https.HttpsError("not-found", "User not found");
            }
            // Use the correct collection
        }

        // Generate a unique token ID (using hash of token + platform for consistency)
        const tokenId = `${platform}_${token.substring(0, 8)}_${Date.now()}`;

        // Save token to subcollection
        await userDocRef.collection('fcmTokens').doc(tokenId).set({
            token,
            platform,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
            invalidCount: 0,
            isActive: true,
        }, { merge: true });

        console.log(`[FCM] Token saved for ${userType}:${uid}`);
        return { success: true, tokenId };
    } catch (error: any) {
        console.error(`[FCM] Failed to save token for ${uid}:`, error);
        throw new functions.https.HttpsError("internal", "Failed to save token");
    }
});

/**
 * Removes FCM token for a user
 * Called on logout or token refresh
 */
export const removeFcmToken = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "User not logged in");
    }

    const { token, userType = 'customer' } = data;

    if (!token) {
        throw new functions.https.HttpsError("invalid-argument", "Token is required");
    }

    try {
        const collectionPath = userType === 'technician' ? 'technicians' : 'customers';

        // Find and delete the token
        const tokensSnapshot = await db.collection(collectionPath)
            .doc(uid)
            .collection('fcmTokens')
            .where('token', '==', token)
            .limit(1)
            .get();

        if (!tokensSnapshot.empty) {
            await tokensSnapshot.docs[0].ref.delete();
            console.log(`[FCM] Token removed for ${userType}:${uid}`);
        }

        return { success: true };
    } catch (error: any) {
        console.error(`[FCM] Failed to remove token for ${uid}:`, error);
        throw new functions.https.HttpsError("internal", "Failed to remove token");
    }
});

/**
 * Removes all FCM tokens for a user
 * Called on complete logout
 */
export const removeAllFcmTokens = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "User not logged in");
    }

    const { userType = 'customer' } = data;

    try {
        const collectionPath = userType === 'technician' ? 'technicians' : 'customers';

        // Delete all tokens
        const tokensSnapshot = await db.collection(collectionPath)
            .doc(uid)
            .collection('fcmTokens')
            .get();

        const batch = db.batch();
        tokensSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });

        if (!tokensSnapshot.empty) {
            await batch.commit();
            console.log(`[FCM] All tokens removed for ${userType}:${uid}`);
        }

        return { success: true, deletedCount: tokensSnapshot.size };
    } catch (error: any) {
        console.error(`[FCM] Failed to remove all tokens for ${uid}:`, error);
        throw new functions.https.HttpsError("internal", "Failed to remove tokens");
    }
});

/**
 * Gets all FCM tokens for a user (admin use only)
 */
export const getFcmTokens = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "User not logged in");
    }

    const { userType = 'customer' } = data;

    try {
        const collectionPath = userType === 'technician' ? 'technicians' : 'customers';

        const tokensSnapshot = await db.collection(collectionPath)
            .doc(uid)
            .collection('fcmTokens')
            .where('isActive', '==', true)
            .get();

        const tokens = tokensSnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        return { success: true, tokens };
    } catch (error: any) {
        console.error(`[FCM] Failed to get tokens for ${uid}:`, error);
        throw new functions.https.HttpsError("internal", "Failed to get tokens");
    }
});


import * as bookingActions from './booking_actions';

// Technician Actions
export const scheduleInspection = bookingActions.scheduleInspection;
export const startInspection = bookingActions.startInspection;
export const submitInspectionReport = bookingActions.submitInspectionReport;
export const startJob = bookingActions.startJob;
export const completeJob = bookingActions.completeJob;

// Customer Actions
export const approveJobQuote = bookingActions.approveJobQuote;
export const rejectJobQuote = bookingActions.rejectJobQuote;
// cancelBookingByCustomer is exported from booking_lifecycle.ts

// ==========================================
// 3. TRIGGERS
// ==========================================

export const onUserCreated = functions.auth.user().onCreate(async (user: admin.auth.UserRecord) => {
    // Determine if it's a customer or technician based on some criteria? 
    // Usually handled by the app calling 'saveUserProfile', but this is a backup.
    console.log(`New user created: ${user.uid}`);
});

// ==========================================
// 3. TRIGGERS & NOTIFICATIONS (V2)
// ==========================================

// V2 Firestore Trigger: onBookingCreated
export const onBookingCreated = onDocumentCreated(
    {
        document: 'bookings/{bookingId}',
        region: 'us-central1',
        memory: '256MiB',
        timeoutSeconds: 60,
        minInstances: 1,
    },
    async (event: any) => {
        const snap = event.data;
        if (!snap) return;

        const booking = snap.data();
        const bookingId = event.params.bookingId;

        // Notify Customer
        await sendPushNotification(booking.customerId, 'customers', {
            title: 'Booking Received',
            body: `Your booking for ${booking.serviceTitle} has been received.`,
            data: { bookingId, type: 'booking_status' }
        });

        // Notify Technician (if assigned immediately)
        if (booking.assignedTechnicianId) {
            await sendPushNotification(booking.assignedTechnicianId, 'technicians', {
                title: 'New Job Assigned!',
                body: `You have a new booking for ${booking.serviceTitle}.`,
                data: { bookingId, type: 'job_request' }
            });
        }
    }
);

export const onBookingStatusChange = onDocumentUpdated(
    {
        document: 'bookings/{bookingId}',
        region: 'us-central1',
        memory: '256MiB',
        timeoutSeconds: 60,
        minInstances: 1,
    },
    async (event: any) => {
        const startTime = Date.now();
        const before = event.data.before.data();
        const after = event.data.after.data();
        if (!before || !after) {
            console.log(JSON.stringify({ level: "WARN", function: "onBookingStatusChange", action: "missing_data", durationMs: Date.now() - startTime }));
            return;
        }

        const bookingId = event.params.bookingId;
        const bookingContext = { bookingId, customerId: after.customerId, technicianId: after.assignedTechnicianId };

        // 1. Handle Status Change with guard against duplicate processing
        if (before.status !== after.status) {
            const status = after.status;
            console.log(JSON.stringify({
                level: "INFO",
                function: "onBookingStatusChange",
                action: "status_change",
                ...bookingContext,
                fromStatus: before.status,
                toStatus: status,
                durationMs: Date.now() - startTime
            }));

            let customerPayload: NotificationPayload | null = null;
            let techPayload: NotificationPayload | null = null;

            switch (status) {
                case 'confirmed':
                    customerPayload = {
                        title: 'Booking Confirmed!',
                        body: `Your booking for ${after.serviceTitle} is confirmed.`,
                        data: { bookingId, type: 'booking_status' }
                    };
                    break;
                case 'assigned':
                    customerPayload = {
                        title: 'Technician Assigned',
                        body: `Expert ${after.assignedTechnicianName} has been assigned to your service.`,
                        data: { bookingId, type: 'booking_status' }
                    };
                    break;
                case 'on_the_way':
                    customerPayload = {
                        title: 'Technician is On The Way!',
                        body: 'Get ready! Our professional is headed to your location.',
                        data: { bookingId, type: 'tracking' }
                    };
                    break;
                case 'started':
                    customerPayload = {
                        title: 'Service Started',
                        body: 'The pro has started the service. Relax while we fix it!',
                        data: { bookingId, type: 'booking_status' }
                    };
                    break;
                case 'completed':
                    // GUARD: Check if earnings already processed
                    if (after.earningsProcessed) {
                        console.log(JSON.stringify({
                            level: "WARN",
                            function: "onBookingStatusChange",
                            action: "earnings_already_processed",
                            ...bookingContext,
                            durationMs: Date.now() - startTime
                        }));
                    } else {
                        customerPayload = {
                            title: 'Service Completed!',
                            body: 'How was your experience? Please rate the service.',
                            data: { bookingId, type: 'rating' }
                        };
                        const techAmount = after.finalAmount * 0.8;
                        techPayload = {
                            title: 'Payment Credited',
                            body: `₹${techAmount.toFixed(2)} has been added to your pending balance for ${after.serviceTitle}.`,
                            data: { bookingId, type: 'earnings' }
                        };
                        if (after.assignedTechnicianId) {
                            try {
                                await technicianFinance.processTechnicianEarning(
                                    bookingId,
                                    after.assignedTechnicianId,
                                    after.finalAmount,
                                    after.services.map((s: any) => s.id)
                                );
                                console.log(JSON.stringify({
                                    level: "INFO",
                                    function: "onBookingStatusChange",
                                    action: "earnings_processed",
                                    ...bookingContext,
                                    amount: techAmount,
                                    durationMs: Date.now() - startTime
                                }));
                            } catch (error: any) {
                                console.error(JSON.stringify({
                                    level: "ERROR",
                                    function: "onBookingStatusChange",
                                    action: "earnings_processing_failed",
                                    ...bookingContext,
                                    error: error.message,
                                    durationMs: Date.now() - startTime
                                }));
                            }
                        }
                    }
                    break;
                case 'cancelled':
                    customerPayload = {
                        title: 'Booking Cancelled',
                        body: `Your booking for ${after.serviceTitle} was cancelled. Refund initialized if paid.`,
                        data: { bookingId, type: 'booking_status' }
                    };
                    if (after.assignedTechnicianId) {
                        techPayload = {
                            title: 'Job Cancelled',
                            body: `The customer cancelled the booking for ${after.serviceTitle}.`,
                            data: { bookingId, type: 'job_update' }
                        };
                    }
                    break;
            }

            if (customerPayload) {
                await sendPushNotification(after.customerId, 'customers', customerPayload);
            }
            if (techPayload && after.assignedTechnicianId) {
                await sendPushNotification(after.assignedTechnicianId, 'technicians', techPayload);
            }
        }

        // 2. Handle Technician Assignment (guard against duplicate notifications)
        if (!before.assignedTechnicianId && after.assignedTechnicianId) {
            console.log(JSON.stringify({
                level: "INFO",
                function: "onBookingStatusChange",
                action: "technician_assigned",
                ...bookingContext,
                durationMs: Date.now() - startTime
            }));
            await sendPushNotification(after.assignedTechnicianId, 'technicians', {
                title: 'New Job Request',
                body: `New job request for ${after.serviceTitle} at ${after.scheduledTime}.`,
                data: { bookingId, type: 'job_request' }
            });
        }
    }
);

// ==========================================
// 4. TECHNICIAN ONBOARDING (NEW)
// ==========================================

export const onTechnicianApplicationUpdate = onDocumentUpdated(
    {
        document: 'technician_applications/{appId}',
        region: 'us-central1',
        memory: '256MiB',
        timeoutSeconds: 30,
        minInstances: 1,
    },
    async (event: any) => {
        const after = event.data.after.data();
        const before = event.data.before.data();
        if (!after || !before) return;

        if (before.status !== after.status) {
            const userId = event.params.appId;
            let title = 'Application Update';
            if (after.status === 'approved') title = 'Application Approved';
            else if (after.status === 'rejected') title = 'Application Rejected';

            await sendPushNotification(userId, 'technicians', {
                title,
                body: `Your application status is now: ${after.status}`,
                data: { type: 'application_status', status: after.status }
            });
        }
    }
);

// ==========================================
// 4. TECHNICIAN ONBOARDING (NEW)
// ==========================================

import * as techApp from './technician/application';
import * as techTrack from './technician/tracking';
import * as adminTechMgmt from './admin/technician_management';
import * as matchEngine from './matching/engine';

// Application Flow
export const initiatePhoneVerification = techApp.initiatePhoneVerification;
export const savePersonalDetails = techApp.savePersonalDetails;
export const submitKYC = techApp.submitKYC;
export const saveSkillSelection = techApp.saveSkillSelection;
export const saveExperienceDetails = techApp.saveExperienceDetails;
export const saveAvailability = techApp.saveAvailability;
export const saveServiceArea = techApp.saveServiceArea;
export const saveBankDetails = techApp.saveBankDetails;
export const completeTraining = techApp.completeTraining;
export const submitApplication = techApp.submitApplication;
export const submitFullApplication = techApp.submitFullApplication;

// Admin Management
export const approveKYC = adminTechMgmt.approveKYC;
export const approveTechnician = adminTechMgmt.approveTechnician;
export const suspendTechnician = adminTechMgmt.suspendTechnician;

import * as techSec from './technician/security';

// Tracking & Security
export const bindDevice = techSec.bindDevice;
export const updateLocation = techTrack.updateLocation;
export const toggleOnlineStatus = techTrack.toggleOnlineStatus;

// Matching & Booking
import { onBookingCreatedMatch } from './matching/matching_v2';
export const onNewBookingMatch = onBookingCreatedMatch; // Trigger
// export const respondToBooking = matchEngine.respondToBooking; // Use handleAssignmentResponse instead

// ==========================================
// V2 PAYMENT UPDATE TRIGGER
// ==========================================

export const onPaymentUpdate = onDocumentUpdated(
    {
        document: 'bookings/{bookingId}',
        region: 'us-central1',
        memory: '256MiB',
        timeoutSeconds: 30,
        minInstances: 0,
    },
    async (event: any) => {
        const before = event.data.before.data();
        const after = event.data.after.data();
        if (!before || !after) return;

        if (before.paymentStatus !== after.paymentStatus && after.paymentStatus === 'paid') {
            await sendPushNotification(after.customerId, 'customers', {
                title: 'Payment Successful',
                body: `Payment for booking #${event.params.bookingId.slice(-6)} was successful.`,
                data: { bookingId: event.params.bookingId, type: 'payment' }
            });
        }
    }
);

export const migrateDatabaseReq = functions.https.onRequest(async (req: any, res: any) => {
    console.log('Starting migration via Request...');

    const results: any = {};

    // 1. Services
    const servicesSnap = await db.collection('services').get();
    const serviceBatch = db.batch();
    servicesSnap.docs.forEach(doc => {
        const d = doc.data();
        const update: any = {};
        if (d.title && !d.name) { update.name = d.title; update.title = admin.firestore.FieldValue.delete(); }
        if (d.basePrice !== undefined && d.price === undefined) { update.price = Number(d.basePrice); update.basePrice = admin.firestore.FieldValue.delete(); }
        if (d.category && !d.categoryId) { update.categoryId = d.category; update.category = admin.firestore.FieldValue.delete(); }
        const img = d.image || d.imageUrl || d.imageAssetPath || "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80";
        update.image = img;
        if (d.imageUrl) update.imageUrl = admin.firestore.FieldValue.delete();
        if (d.imageAssetPath) update.imageAssetPath = admin.firestore.FieldValue.delete();
        if (d.serviceId !== doc.id) update.serviceId = doc.id;
        if (Object.keys(update).length > 0) serviceBatch.update(doc.ref, update);
    });
    await serviceBatch.commit();
    results.servicesUpdated = servicesSnap.size;

    // 2. Technicians
    const techsSnap = await db.collection('technicians').get();
    const techBatch = db.batch();
    techsSnap.docs.forEach(doc => {
        const d = doc.data();
        const update: any = {};
        if (d.skills && typeof d.skills === 'string') {
            update.skills = d.skills.split(',').map((s: string) => s.trim());
        }
        if (Object.keys(update).length > 0) techBatch.update(doc.ref, update);
    });
    await techBatch.commit();
    results.techsUpdated = techsSnap.size;

    // 3. Reviews
    const reviewsSnap = await db.collection('reviews').get();
    const reviewBatch = db.batch();
    reviewsSnap.docs.forEach(doc => {
        const d = doc.data();
        if (d.rating !== undefined && typeof d.rating !== 'number') {
            reviewBatch.update(doc.ref, { rating: Number(d.rating) });
        }
    });
    await reviewBatch.commit();
    results.reviewsUpdated = reviewsSnap.size;

    // 4. Users
    const usersSnap = await db.collection('users').get();
    const userBatch = db.batch();
    usersSnap.docs.forEach(doc => {
        const d = doc.data();
        const update: any = {};
        if (d.phone || d.phoneNumber) {
            let p = d.phone || d.phoneNumber;
            if (/^\d{10}$/.test(p)) update.phoneNumber = '+91' + p;
            else update.phoneNumber = p;
            if (d.phone) update.phone = admin.firestore.FieldValue.delete();
        }
        if (d.role && !['customer', 'technician', 'admin'].includes(d.role)) update.role = 'customer';
        if (Object.keys(update).length > 0) userBatch.update(doc.ref, update);
    });
    await userBatch.commit();
    results.usersUpdated = usersSnap.size;

    res.json({ success: true, results });
});

export const onBookingCompletedAwardReferral = customerFeatures.onBookingCompletedAwardReferral;

// ==========================================
// 4. TESTING TOOLS
// ==========================================
export const test_createCustomer = testing.createTestCustomer;
export const test_createTechnician = testing.createTestTechnician;
export const test_generateBooking = testing.generateTestBooking;
export const test_simulatePayment = testing.simulatePayment;
export const test_resetData = testing.resetTestData;

// ==========================================
// 5. RAZORPAY PAYMENT INTEGRATION
// ==========================================

// Payment Functions
export const createPaymentOrder = razorpayPayments.createPaymentOrder;
export const razorpayWebhook = razorpayPayments.razorpayWebhook;
export const verifyPayment = razorpayPayments.verifyPayment;
export const initiateRefund = razorpayPayments.initiateRefund;

// Payout Functions (Admin)
export const getPendingPayouts = technicianPayouts.getPendingPayouts;
export const getPayoutHistory = technicianPayouts.getPayoutHistory;
export const getPayoutSummary = technicianPayouts.getPayoutSummary;
export const markPayoutPaid = technicianPayouts.markPayoutPaid;
export const putPayoutOnHold = technicianPayouts.putPayoutOnHold;
export const releasePayoutFromHold = technicianPayouts.releasePayoutFromHold;
export const bulkMarkPayoutsPaid = technicianPayouts.bulkMarkPayoutsPaid;
export const getPayoutAnalytics = technicianPayouts.getPayoutAnalytics;

// ==========================================
// 6. CHAT SYSTEM
// ==========================================

export const getOrCreateChat = chat.getOrCreateChat;
export const sendChatMessage = chat.sendChatMessage;
export const markMessagesRead = chat.markMessagesRead;
export const getChatDetails = chat.getChatDetails;

