import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as testing from './testing';
import { getAppConfig } from './shared/config';
import * as crypto from 'crypto';

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


if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();

const getDb = () => admin.firestore();

// Helper for lazy loading Razorpay
async function getRazorpay() {
    const Razorpay = (await import('razorpay')).default;
    return new Razorpay({
        key_id: functions.config().razorpay?.key_id || 'rzp_test_placeholder',
        key_secret: functions.config().razorpay?.key_secret || 'placeholder_secret',
    });
}

// Helpers
import { sendPushNotification, NotificationPayload } from './shared/notifications';

// Feature Modules
import * as customerFeatures from './customer_features';
// Smart Matching V2
import { matchAndAssignBooking, handleAssignmentResponse } from './matching/matching_v2';

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

// ==========================================
// 1. CUSTOMER CALLABLES
// ==========================================

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
            // Fraud & Abuse Check
            const riskDoc = await transaction.get(db.collection('risk_profiles').doc(context.auth!.uid));
            if (riskDoc.exists) {
                const riskData = riskDoc.data()!;
                if (riskData.status === 'suspended') {
                    throw new functions.https.HttpsError('permission-denied', 'Account suspended due to policy violations. Contact support.');
                }
                if (riskData.status === 'restricted') {
                    // Logic for restricted users (e.g. cooldown)
                    const lastBooking = await db.collection('bookings')
                        .where('customerId', '==', context.auth!.uid)
                        .orderBy('createdAt', 'desc')
                        .limit(1)
                        .get();
                    if (!lastBooking.empty) {
                        const lastTime = (lastBooking.docs[0].data().createdAt as admin.firestore.Timestamp).toDate().getTime();
                        if (Date.now() - lastTime < 12 * 60 * 60 * 1000) { // 12h cooldown
                            throw new functions.https.HttpsError('resource-exhausted', 'Account restricted. Please wait 12 hours between bookings.');
                        }
                    }
                }
            }

            const activeBookings = await transaction.get(
                db.collection('bookings')
                    .where('customerId', '==', context.auth!.uid)
                    .where('status', 'in', ['pending_payment', 'confirmed', 'assigned', 'on_the_way', 'started'])
            );
            if (activeBookings.size >= 15) throw new functions.https.HttpsError('resource-exhausted', 'Max 15 active bookings allowed');

            transaction.set(db.collection('bookings').doc(bookingId), {
                id: bookingId,
                bookingId,
                customerId: context.auth!.uid,
                customerName: context.auth!.token.name || 'Customer',
                addressSnapshot: address,
                status: finalStatus,
                paymentStatus: 'pending',
                price: totalAmount,
                discountAmount: 0,
                finalAmount: totalAmount,
                couponCode: couponCode || null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                services,
                serviceTitle: services[0].name + (services.length > 1 ? ` (+${services.length - 1} more)` : ''),
                technicianId: null,
                technicianName: 'Finding Professional...',
                scheduledDate,
                scheduledTime,
                scheduledAt: admin.firestore.Timestamp.fromDate(new Date(scheduledDate))
            });
        });
        return { success: true, bookingId, totalAmount };
    } catch (e: any) {
        console.error('Create Booking Error:', e);
        throw new functions.https.HttpsError('internal', e.message);
    }
});

/**
 * Initiate Razorpay Order
 */
export const initiateRazorpayPayment = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    const { bookingId } = data;

    const bDoc = await db.collection('bookings').doc(bookingId).get();
    if (!bDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
    const booking = bDoc.data()!;

    if (booking.customerId !== context.auth.uid) throw new functions.https.HttpsError('permission-denied', 'Unauthorized');
    if (booking.paymentStatus === 'paid') throw new functions.https.HttpsError('already-exists', 'Already paid');

    try {
        const rzp = await getRazorpay();
        const order = await rzp.orders.create({
            amount: Math.round(booking.finalAmount * 100),
            currency: 'INR',
            receipt: bookingId,
            notes: { bookingId: bookingId, customerId: context.auth.uid }
        });

        await db.collection('bookings').doc(bookingId).update({
            razorpayOrderId: order.id,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return {
            orderId: order.id,
            amount: order.amount,
            currency: order.currency,
            key: functions.config().razorpay?.key_id
        };
    } catch (e: any) {
        console.error('Razorpay Order Error:', e);
        throw new functions.https.HttpsError('internal', 'Could not create Razorpay order');
    }
});

/**
 * Verify Payment and Confirm Booking
 */
export const verifyRazorpayPayment = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    const { bookingId, razorpay_order_id, razorpay_payment_id, razorpay_signature } = data;

    const body = razorpay_order_id + "|" + razorpay_payment_id;
    const expectedSignature = crypto
        .createHmac('sha256', functions.config().razorpay?.key_secret || 'placeholder_secret')
        .update(body.toString())
        .digest('hex');

    if (expectedSignature !== razorpay_signature) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid payment signature');
    }

    try {
        await db.runTransaction(async (transaction) => {
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bSnap = await transaction.get(bookingRef);
            if (!bSnap.exists) throw new Error('Booking not found');
            const booking = bSnap.data()!;

            transaction.update(bookingRef, {
                paymentStatus: 'paid',
                status: 'confirmed',
                razorpayPaymentId: razorpay_payment_id,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            const paymentRef = db.collection('payments').doc();
            transaction.set(paymentRef, {
                id: paymentRef.id,
                bookingId,
                userId: context.auth!.uid,
                razorpayOrderId: razorpay_order_id,
                razorpayPaymentId: razorpay_payment_id,
                amount: booking.finalAmount,
                status: 'success',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        // Trigger Smart Matching V2
        await matchAndAssignBooking(bookingId);

        return { success: true };
    } catch (e: any) {
        console.error('Payment Verification Error:', e);
        throw new functions.https.HttpsError('internal', 'Payment verification failed');
    }
});

// Replaced by new unified cancelBooking callable
// export const cancelBookingByCustomer = ...

// Secure Wallet Transaction (Internal / Triggered by Admin or Payment)
export const processWalletTransaction = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const { type, amount, description, targetUid } = data;

    // Only Admin can credit/debit for others. Customers can only see their own.
    const adminUser = await isAdmin(context.auth.uid);
    if (!adminUser && context.auth.uid !== targetUid) {
        throw new functions.https.HttpsError('permission-denied', 'Unauthorized wallet operation');
    }

    // Logic for depositing via payment gateway would be separate. 
    // This is for manual adjustments or internal transfers.
    if (!adminUser && type === 'credit') {
        throw new functions.https.HttpsError('permission-denied', 'Users cannot manually credit their own wallet');
    }

    try {
        await db.runTransaction(async (t: admin.firestore.Transaction) => {
            const userRef = db.collection('customers').doc(targetUid);
            const userDoc = await t.get(userRef);
            if (!userDoc.exists) throw new Error("User not found");

            const currentBalance = userDoc.data()?.walletBalance || 0;
            const newBalance = type === 'credit' ? currentBalance + amount : currentBalance - amount;

            if (newBalance < 0) throw new Error("Insufficient wallet balance");

            t.update(userRef, {
                walletBalance: newBalance,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            t.set(userRef.collection('wallet_transactions').doc(), {
                type,
                amount,
                description,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'completed'
            });
        });

        await logActivity('system', targetUid, `wallet_${type}`, { amount, description });
        return { success: true };
    } catch (e: any) {
        throw new functions.https.HttpsError('internal', e.message);
    }
});

// Create Custom Service Request
export const createServiceRequest = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const { title, description, preferredDateTime, address } = data;
    if (!title || !description || !address) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing fields');
    }

    const requestId = db.collection('service_requests').doc().id;
    await db.collection('service_requests').doc(requestId).set({
        id: requestId,
        customerId: context.auth.uid,
        title,
        description,
        preferredDateTime: new Date(preferredDateTime),
        address,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await logActivity('customer', context.auth.uid, 'request_created', { requestId });
    return { success: true, requestId };
});

// Update User Profile
export const updateUserProfile = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const uid = context.auth.uid;
    const allowedKeys = ['name', 'email', 'phone', 'photoUrl', 'isOnboarded', 'defaultAddress', 'latitude', 'longitude'];
    const updateData: any = {};

    Object.keys(data).forEach(key => {
        if (allowedKeys.includes(key)) {
            updateData[key] = data[key];
        }
    });

    if (Object.keys(updateData).length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'No valid fields provided for update');
    }

    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    await db.collection('customers').doc(uid).update(updateData);

    return { success: true };
});

export const validateReferralCode = customerFeatures.validateReferralCode;
// export const cancelBooking = customerFeatures.cancelBooking; // Replaced by cancelBookingByCustomer
export const submitServiceRating = customerFeatures.submitServiceRating;
export const submitSupportRequest = customerFeatures.submitSupportRequest;

// Update Technician Profile
export const updateTechnicianProfile = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const uid = context.auth.uid;
    const allowedKeys = ['name', 'email', 'phone', 'photoUrl', 'skills', 'bio', 'experience', 'isOnline', 'geo'];
    const updateData: any = {};

    Object.keys(data).forEach(key => {
        if (allowedKeys.includes(key)) {
            updateData[key] = data[key];
        }
    });

    if (Object.keys(updateData).length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'No valid fields provided for update');
    }

    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    await db.collection('technicians').doc(uid).set(updateData, { merge: true });

    return { success: true };
});

// ==========================================
// 2. ADMIN & TECH CALLABLES
// ==========================================

export const admin_getDashboardStats = adminDashboard.getDashboardStats;
export const admin_manageUser = adminUsers.manageUser;
export const admin_deleteTestUser = adminUsers.deleteTestUser;

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
    findEligibleTechniciansCount
} from './admin/dynamic_content';

export {
    admin_manageProfessionalVideos,
    admin_manageCleaningEssentials,
    admin_manageServiceBanners,
    findEligibleTechniciansCount
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
export const cancelBookingByCustomer = bookingActions.cancelBookingByCustomer;


// ==========================================
// 3. TRIGGERS
// ==========================================

export const onUserCreated = functions.auth.user().onCreate(async (user: admin.auth.UserRecord) => {
    // Determine if it's a customer or technician based on some criteria? 
    // Usually handled by the app calling 'saveUserProfile', but this is a backup.
    console.log(`New user created: ${user.uid}`);
});

// ==========================================
// 3. TRIGGERS & NOTIFICATIONS
// ==========================================

export const onBookingCreated = functions.firestore.document('bookings/{bookingId}')
    .onCreate(async (snap, context) => {
        const booking = snap.data();
        if (!booking) return;

        // Notify Customer
        await sendPushNotification(booking.customerId, 'customers', {
            title: 'Booking Received',
            body: `Your booking for ${booking.serviceTitle} has been received.`,
            data: { bookingId: context.params.bookingId, type: 'booking_status' }
        });

        // Notify Technician (if assigned immediately)
        if (booking.assignedTechnicianId) {
            await sendPushNotification(booking.assignedTechnicianId, 'technicians', {
                title: 'New Job Assigned!',
                body: `You have a new booking for ${booking.serviceTitle}.`,
                data: { bookingId: context.params.bookingId, type: 'job_request' }
            });
        }
    });

export const onBookingStatusChange = functions.firestore.document('bookings/{bookingId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        if (!before || !after) return;

        const bookingId = context.params.bookingId;

        // 1. Handle Status Change
        if (before.status !== after.status) {
            const status = after.status;
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
                        body: `Get ready! Our professional is headed to your location.`,
                        data: { bookingId, type: 'tracking' }
                    };
                    break;
                case 'started':
                    customerPayload = {
                        title: 'Service Started',
                        body: `The pro has started the service. Relax while we fix it!`,
                        data: { bookingId, type: 'booking_status' }
                    };
                    break;
                case 'completed':
                    customerPayload = {
                        title: 'Service Completed!',
                        body: `How was your experience? Please rate the service.`,
                        data: { bookingId, type: 'rating' }
                    };
                    const techAmount = after.finalAmount * 0.8;
                    techPayload = {
                        title: 'Payment Credited',
                        body: `₹${techAmount.toFixed(2)} has been added to your pending balance for ${after.serviceTitle}.`,
                        data: { bookingId, type: 'earnings' }
                    };
                    if (after.assignedTechnicianId) {
                        await technicianFinance.processTechnicianEarning(
                            bookingId,
                            after.assignedTechnicianId,
                            after.finalAmount,
                            after.services.map((s: any) => s.id)
                        );
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

            if (customerPayload) await sendPushNotification(after.customerId, 'customers', customerPayload);
            if (techPayload && after.assignedTechnicianId) {
                await sendPushNotification(after.assignedTechnicianId, 'technicians', techPayload);
            }
        }

        // 2. Handle Technician Assignment (if not already handled by status)
        if (!before.assignedTechnicianId && after.assignedTechnicianId) {
            await sendPushNotification(after.assignedTechnicianId, 'technicians', {
                title: 'New Job Request',
                body: `New job request for ${after.serviceTitle} at ${after.scheduledTime}.`,
                data: { bookingId, type: 'job_request' }
            });
        }
    });

export const onTechnicianApplicationUpdate = functions.firestore.document('technician_applications/{appId}')
    .onUpdate(async (change, context) => {
        const after = change.after.data();
        const before = change.before.data();
        if (!after || !before) return;

        if (before.status !== after.status) {
            const userId = context.params.appId; // appId is typically userId
            let title = 'Application Update';
            if (after.status === 'approved') title = 'Application Approved';
            else if (after.status === 'rejected') title = 'Application Rejected';

            await sendPushNotification(userId, 'technicians', {
                title,
                body: `Your application status is now: ${after.status}`,
                data: { type: 'application_status', status: after.status }
            });
        }
    });

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

export const onPaymentUpdate = functions.firestore.document('bookings/{bookingId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        if (!before || !after) return;

        if (before.paymentStatus !== after.paymentStatus && after.paymentStatus === 'paid') {
            await sendPushNotification(after.customerId, 'customers', {
                title: 'Payment Successful',
                body: `Payment for booking #${context.params.bookingId.slice(-6)} was successful.`,
                data: { bookingId: context.params.bookingId, type: 'payment' }
            });
        }
    });

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
        const img = d.image || d.imageUrl || d.imageAssetPath || "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80";
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

