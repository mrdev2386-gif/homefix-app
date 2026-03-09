import * as admin from 'firebase-admin';

// Safe initialization - only initialize if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}
console.log("BOOT OK - Functions loading...");

import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as functions from 'firebase-functions';
import * as testing from './testing';
import { getAppConfig } from './shared/config';
import * as crypto from 'crypto';

// v2 Firestore triggers removed for compatibility

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
import * as notificationsMgmt from './notifications_management';
import * as adminDynamic from './admin/dynamic_content';
import * as technicianFinance from './finance/wallet_logic';
import * as payoutLogic from './finance/payout_logic';
import * as technicianWithdrawal from './finance/technician_withdrawal';
import * as walletReconciliation from './finance/wallet_reconciliation';

// Payment Modules (New Razorpay Integration)
import * as razorpayPayments from './payments/razorpay';
import * as technicianPayouts from './payments/payouts';
import { razorpayWebhookV2 } from './payments/razorpayWebhookV2';

// Partner Applications
import * as partnerApplications from './partner/applications';

// Technician Services (YouTube-style service listings)
import * as technicianServices from './technician/createTechnicianService';
import * as techServicesManagement from './technician/services_management';

// Chat System
import * as chat from './chat/chat';

// Technician Onboarding & Management
import * as techApp from './technician/application';
import * as techAuth from './technician/auth';
import * as techKyc from './technician/kyc';
import * as techOnboarding from './technician/onboarding'; // NEW: Secure onboarding functions
import * as techProfile from './technician/profile_management'; // NEW: Profile management functions
import * as techTrack from './technician/tracking';
import * as adminTechMgmt from './admin/technician_management';
import * as techBankVerification from './technician/bank_verification'; // Razorpay bank verification

// EXPORTS FOR TECHNICIAN ONBOARDING (SECURE CLOUD FUNCTIONS)
export const createTechnicianProfile = techOnboarding.createTechnicianProfile;
export const saveTechnicianBasicDetails = techOnboarding.saveTechnicianBasicDetails;
export const saveTechnicianDocuments = techOnboarding.saveTechnicianDocuments;
export const saveTechnicianServices = techOnboarding.saveTechnicianServices; // TODO: verify usage before deletion
export const submitTechnicianKyc = techOnboarding.submitTechnicianKyc; // TODO: verify usage before deletion
// export const updateTechnicianProfileData = techOnboarding.updateTechnicianProfile; // TODO: verify usage before deletion
export const updateTechnicianStatus = techOnboarding.updateTechnicianStatus; // TODO: verify usage before deletion
export const saveTechnicianStepData = techOnboarding.saveTechnicianStepData;

// EXPORTS FOR TECHNICIAN PROFILE MANAGEMENT (SECURE CLOUD FUNCTIONS)
export const updateTechnicianPersonalDetails = techProfile.updateTechnicianPersonalDetails;
export const updateTechnicianBankDetails = techProfile.updateTechnicianBankDetails;
export const reuploadVerificationDocument = techProfile.reuploadVerificationDocument;
export const adminUpdateBankStatus = techProfile.adminUpdateBankStatus;
export const adminUpdateDocumentStatus = techProfile.adminUpdateDocumentStatus;

// EXPORTS FOR BANK VERIFICATION (RAZORPAY PENNY DROP)
export const verifyTechnicianBankAccount = techBankVerification.verifyTechnicianBankAccount;
export const razorpayBankWebhook = techBankVerification.razorpayBankWebhook;

import * as matchEngine from './matching/engine';
import * as techTriggers from './technician/triggers';
import * as techSec from './technician/security';
import * as customRequest from './custom_request';
import * as techAlerts from './technician/alerts';
import * as instantBooking from './instant_booking';
import * as bookingActions from './booking_actions';
import * as fraudProtection from './fraud_protection';
import { onBookingCreatedMatch } from './matching/matching_v2';


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
// export { getEligibleTechnicians } from './matching/engine';

// export const matchTechnicians = matchTechs;
// TODO: matchTechniciansForService is a duplicate of matchTechnicians - remove in next release
// export const matchTechniciansForService = matchTechs; 
// export const updateTechnicianLastAssignment = updateTechnicianAssignment;
export const onStaleTechnicianCleanup = cleanupStaleTechnicianStatus;

export {
    createBookingRequest,
    adminApproveBooking,
    technicianRespondBooking,
    customerConfirmPayment,
    updateBookingStatusGeneric as updateBookingStatusNew,
    updateBookingStatusGeneric as updateBookingStatus,
    markWorkCompleted
} from './booking/new_booking_flow';

// ==========================================
// SECURE BOOKING LIFECYCLE FUNCTIONS
// ==========================================
import * as bookingLifecycle from './booking/booking_lifecycle';
export const notifyAdminNewBooking = bookingLifecycle.notifyAdminNewBooking;
export const approveBookingByAdmin = bookingLifecycle.approveBookingByAdmin;
export const rejectBookingByAdmin = bookingLifecycle.rejectBookingByAdmin;
export const technicianAcceptBooking = bookingLifecycle.technicianAcceptBooking;
export const technicianStartJob = bookingLifecycle.technicianStartJob;
export const completeBooking = bookingLifecycle.completeBooking;
export const cancelBooking = bookingLifecycle.cancelBooking;
export const technicianRejectBooking = bookingLifecycle.technicianRejectBooking;
export const verifyBookingPayment = bookingLifecycle.verifyBookingPayment;

// Refund System
import * as refundSystem from './booking/refund_system';
export const refundBookingPayment = refundSystem.refundBookingPayment;

// QR Wallet Payment
import * as paymentQR from './booking/payment_qr';
export const generateTechnicianQR = paymentQR.generateTechnicianQR;
export const confirmQRPayment = paymentQR.confirmQRPayment;

// Stale Booking Cleanup
import * as bookingCleanup from './booking/cleanup';
export const cleanupStaleBookings = bookingCleanup.cleanupStaleBookings;

// ================================================
// BOOKING & CUSTOM REQUEST NOTIFICATIONS TRIGGERS
// ================================================

// Booking Status Change Notifications
import * as bookingNotifications from './booking/booking_notifications';
export const onBookingStatusChange = bookingNotifications.onBookingStatusChange;

// Custom Request Status Change Notifications
import * as customRequestNotifications from './custom_requests/custom_request_notifications';
export const onCustomRequestStatusChange = customRequestNotifications.onCustomRequestStatusChange;

// Production Hardening
export {
    handlePaymentWebhook,
    createBookingIdempotent,
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

export { checkRateLimit } from './shared/utils';

// ==========================================
// TECHNICIAN SERVICE LISTINGS (YouTube-style)
// ==========================================

// Technician Services Management (Single Source of Truth)
// Using services_management.ts as the authoritative implementation
export const addTechnicianService = techServicesManagement.addTechnicianService;
export const createTechnicianService = techServicesManagement.addTechnicianService;
export const updateTechnicianService = techServicesManagement.updateTechnicianService;
export const deleteTechnicianService = techServicesManagement.deleteTechnicianService;
export const toggleTechnicianServiceStatus = techServicesManagement.toggleTechnicianServiceStatus;
export const getMyTechnicianServices = technicianServices.getMyTechnicianServices;

/**
 * Scheduled function to remind users about items in their cart.
 * Runs every 4 hours.
 */
export const onCartAbandoned = onSchedule(
    {
        schedule: 'every 4 hours',
        timeZone: 'Asia/Kolkata',
        memory: '256MiB'
    },
    async (event) => {
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


export async function isAdmin(uid: string) {
    const adminDoc = await db.collection('admins').doc(uid).get();
    return adminDoc.exists;
}

// 1. CUSTOMER CALLABLES
// createBooking is legacy - use createBookingRequest instead

export const initiateRazorpayPayment = razorpayPayments.createPaymentOrder;
export const verifyRazorpayPayment = razorpayPayments.verifyPayment;
export const processWalletTransaction = technicianFinance.processWalletTransaction;

export const updateUserProfile = customerFeatures.updateUserProfile;
export const updateTechnicianProfile = customerFeatures.updateTechnicianProfile; // TODO: verify usage before deletion
// cancelBooking moved to booking_lifecycle.ts
// TODO: verify usage before deletion
// export const deleteAccount = customerFeatures.deleteAccount;
export const manageAddress = customerFeatures.manageAddress;

// Address Management (Secure)
import * as addressManagement from './customer/address_management';
export const setPrimaryAddress = addressManagement.setPrimaryAddress;
export const manageAddressSecure = addressManagement.manageAddress;
export const validateAddressForBooking = addressManagement.validateAddressForBooking;

// Cart Management (Secure)
import * as cartManagement from './customer/cart_management';
export const addToCartCallable = cartManagement.addToCartCallable;
export const updateCartQuantityCallable = cartManagement.updateCartQuantityCallable;
export const removeFromCartCallable = cartManagement.removeFromCartCallable;
export const clearCartCallable = cartManagement.clearCartCallable;

// Favorites Management (Secure)
import * as favoritesManagement from './customer/favorites_management';
export const toggleFavoriteCallable = favoritesManagement.toggleFavoriteCallable;
// TODO: verify usage before deletion
export const managePaymentMethod = customerFeatures.managePaymentMethod; // TODO: verify usage before deletion
// TODO: verify usage before deletion
// export const updatePrivacySettings = customerFeatures.updatePrivacySettings; // TODO: verify usage before deletion
export const validateReferralCode = customerFeatures.validateReferralCode;
export const submitServiceRating = customerFeatures.submitServiceRating;
export const submitSupportRequest = customerFeatures.submitSupportRequest;

// Partner Applications
export const submitPartnerApplication = partnerApplications.submitPartnerApplication;

// Custom Service Request Features
export const createCustomServiceRequest = customRequest.createCustomServiceRequest;
export const adminApproveServiceRequest = customRequest.adminApproveServiceRequest;
export const technicianRespondServiceRequest = customRequest.technicianRespondServiceRequest;
export const customerConfirmServicePayment = customRequest.customerConfirmServicePayment;
export const getTechnicianInbox = customRequest.getTechnicianInbox;
export const getCustomRequestDetail = customRequest.getCustomRequestDetail;

// Instant Booking Features
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
export const admin_approveTechnicianApplication = adminTechs.adminApproveTechnician;
export const admin_approveTechnician = adminTechMgmt.approveTechnician;
export const admin_approveKYC = adminTechMgmt.approveKYC;
export const admin_suspendTechnician = adminTechMgmt.suspendTechnician;
export const admin_toggleTechAvailability = adminTechs.toggleTechAvailability;
export const admin_updateTechServices = adminTechs.updateTechServices;

export const admin_manageService = adminServices.manageService;
export const createService = adminServices.createService;
export const updateService = adminServices.updateService;
export const createSubService = adminServices.createSubService;
export const updateSubService = adminServices.updateSubService;
export const deleteService = adminServices.deleteService;
export const updatePricingConfig = adminServices.updatePricingConfig;
export const deleteSubService = adminServices.deleteSubService;
export const getSubServicePriceHistory = adminServices.getSubServicePriceHistory;

// Service Nesting Migration (PHASE 12)
// export const migrateServicesToNested = adminServices.migrateServicesToNested;

// Admin Service Management (Production-Ready)
import * as adminServiceMgmt from './admin/service_management';
export const admin_approveService = adminServiceMgmt.admin_approveService;
export const admin_rejectService = adminServiceMgmt.admin_rejectService;
export const admin_disableService = adminServiceMgmt.admin_disableService;

export const admin_manageBooking = adminBookings.adminManageBooking;

import * as adminImages from './admin/images';
export const admin_uploadServiceImage = adminImages.uploadServiceImage;

export const admin_refundBooking = adminFinance.refundBooking;
export const admin_adjustWallet = adminFinance.adjustWallet;
export const admin_processBookingPayout = adminFinance.processBookingPayout;

export const admin_sendPushNotification = adminNotif.sendPushNotification;

import * as adminRisk from './admin/risk';
export const admin_manageRiskProfile = adminRisk.manageRiskProfile;

import * as adminReviews from './admin/reviews';
export const admin_manageReview = adminReviews.manageReview;

// Review Aggregation Trigger
import { onReviewCreated } from './reviews/review_triggers';
export { onReviewCreated };

import * as adminDisputes from './admin/disputes';
export const admin_manageDispute = adminDisputes.manageDispute;

import * as bookingModeration from './admin/booking_moderation';
export const approveBooking = bookingModeration.approveBooking;
export const rejectBooking = bookingModeration.rejectBooking;

import {
    admin_manageProfessionalVideos,
    admin_manageCleaningEssentials,
    admin_manageServiceBanners,
    admin_manageCategories,
    admin_manageServices,
    admin_manageHomeSections,
    admin_manageCategory,
    admin_manageNestedService,
    admin_manageNestedSubService,
    findEligibleTechniciansCount
} from './admin/dynamic_content';

import { admin_initializeHomeContent, admin_backfillImages } from './admin/system_initialization';
import { admin_auditServiceCatalog } from './admin/catalog_audit';
// export { temp_recovery_diag } from './temp_audit';


// export {
//     admin_manageProfessionalVideos,
//     admin_manageCleaningEssentials,
//     admin_manageServiceBanners,
//     admin_manageTechnicianCategories,
//     admin_manageTechnicianSubcategories,
//     admin_manageHomeSections,
//     admin_manageCategory,
//     admin_manageNestedService,
//     admin_manageNestedSubService,
//     admin_initializeHomeContent,
//     admin_backfillImages,
//     admin_auditServiceCatalog,
//     findEligibleTechniciansCount
// };

export {
    admin_manageHomeSections,
    admin_manageCategory,
    admin_manageNestedService,
    admin_manageNestedSubService,
    admin_initializeHomeContent,
    admin_backfillImages,
    admin_auditServiceCatalog,
    findEligibleTechniciansCount
};

// Technician Finance & Payouts
export const triggerTechnicianPayout = payoutLogic.triggerTechnicianPayout;
export const razorpayPayoutWebhook = payoutLogic.razorpayPayoutWebhook;
export const settleTechnicianBalance = payoutLogic.settleTechnicianBalance;

// Technician Withdrawal & QR (Admin-Controlled)
export const requestWithdrawal = technicianWithdrawal.requestWithdrawal;
export const approveWithdrawal = technicianWithdrawal.approveWithdrawal;
export const rejectWithdrawal = technicianWithdrawal.rejectWithdrawal;
export const getWithdrawalRequests = technicianWithdrawal.getWithdrawalRequests;
export const getPendingWithdrawalRequests = technicianWithdrawal.getPendingWithdrawalRequests;
export const getTransactionHistory = technicianWithdrawal.getTransactionHistory;
export const getTechnicianPayoutHistory = technicianWithdrawal.getPayoutHistory;
export const generateBookingQR = technicianWithdrawal.generateBookingQR;

// Wallet Reconciliation (Scheduled & Admin)
export const runWalletReconciliation = walletReconciliation.runWalletReconciliation;
// export const triggerManualReconciliation = walletReconciliation.triggerManualReconciliation;
// export const getReconciliationAnomalies = walletReconciliation.getReconciliationAnomalies;
// export const markWalletReviewed = walletReconciliation.markWalletReviewed;


// Fraud & Abuse Protection
export const onBookingStatusUpdateRiskCheck = fraudProtection.onBookingStatusUpdateRiskCheck;
export const onReviewRiskCheck = fraudProtection.onReviewRiskCheck;
export const onPaymentStatusRiskCheck = fraudProtection.onPaymentStatusRiskCheck;
export const onTechnicianProfileUpdateRiskCheck = fraudProtection.onTechnicianProfileUpdateRiskCheck;


// SMART MATCHING V2
export const assignTechnicianToBooking = functions.https.onCall(async (data: any, context: any) => {
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
export const saveFcmToken = functions.https.onCall(async (data: any, context: any) => {
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

        // Use base64 encoded token as doc ID (safe and unique)
        const tokenHash = Buffer.from(token).toString('base64').substring(0, 150);
        const tokenDocRef = userDocRef.collection('fcmTokens').doc(tokenHash);

        // Save token to subcollection
        await tokenDocRef.set({
            token,
            platform,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
            invalidCount: 0,
            isActive: true,
        }, { merge: true });

        // Update legacy field for backward compatibility
        await userDocRef.set({ fcmToken: token }, { merge: true });

        console.log(`[FCM] Token saved for ${userType}:${uid}`);
        return { success: true, tokenId: tokenHash };
    } catch (error: any) {
        console.error(`[FCM] Failed to save token for ${uid}:`, error);
        throw new functions.https.HttpsError("internal", "Failed to save token");
    }
});

/**
 * Removes FCM token for a user
 * Called on logout or token refresh
 */
export const removeFcmToken = functions.https.onCall(async (data: any, context: any) => {
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
/*
export const removeAllFcmTokens = functions.https.onCall(async (data: any, context: any) => {
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
*/

/**
 * Gets all FCM tokens for a user (admin use only)
 */
/*
export const getFcmTokens = functions.https.onCall(async (data: any, context: any) => {
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
*/


// Notification Management
export const markNotificationRead = notificationsMgmt.markNotificationRead;
export const markAllNotificationsRead = notificationsMgmt.markAllNotificationsRead;
export const deleteNotificationCallable = notificationsMgmt.deleteNotificationCallable;
export const deleteAllNotificationsCallable = notificationsMgmt.deleteAllNotificationsCallable;

// Booking Actions - Removed stub functions (unimplemented)
// If needed in future, implement in booking_actions.ts first

// ==========================================
// 3. TRIGGERS
// ==========================================

// Auth trigger: Create minimal technician document when user is created
export const onUserCreated = techAuth.createTechnicianOnAuthCreate;

// ==========================================
// 3. TRIGGERS & NOTIFICATIONS (V2)
// ==========================================

// Legacy Firestore Triggers Removed (Deduplicated)

// ==========================================
// 4. TECHNICIAN ONBOARDING (NEW)
// ==========================================

import * as notificationTriggers from './notification_triggers';

export const onNewReviewNotification = notificationTriggers.onNewReviewNotification;
export const onBookingCancelledNotification = notificationTriggers.onBookingCancelledNotification;
export const onTechnicianLikeNotification = notificationTriggers.onTechnicianLikeNotification;
export const onTechnicianApplicationStatusTrigger = notificationTriggers.onTechnicianApplicationStatusTrigger;

// ==========================================
// 4. TECHNICIAN ONBOARDING (NEW)
// ==========================================

// Application Flow
// export const initiatePhoneVerification = techApp.initiatePhoneVerification;
// export const savePersonalDetails = techApp.savePersonalDetails;
export const submitKYC = techApp.submitKYC;
// export const saveSkillSelection = techApp.saveSkillSelection;
// export const saveExperienceDetails = techApp.saveExperienceDetails;
// export const saveAvailability = techApp.saveAvailability;
// export const saveServiceArea = techApp.saveServiceArea;
// export const saveBankDetails = techApp.saveBankDetails;
// export const completeTraining = techApp.completeTraining;
// export const submitApplication = techApp.submitApplication;
// export const submitFullApplication = techApp.submitTechnicianApplication;
export const syncTechnicianApprovalToServices = techTriggers.syncTechnicianApprovalToServices;

// KYC Evaluation (Backend-controlled)
export const evaluateTechnicianKyc = techKyc.evaluateTechnicianKyc;
export const checkKycStatus = techKyc.checkKycStatus;

// Admin Management
export const approveKYC = adminTechMgmt.approveKYC;
export const approveTechnician = adminTechMgmt.approveTechnician;
export const suspendTechnician = adminTechMgmt.suspendTechnician;

// Tracking & Security
// export const bindDevice = techSec.bindDevice;
// export const updateLocation = techTrack.updateLocation;
export const toggleOnlineStatus = techTrack.toggleOnlineStatus;

export const onCustomRequestCreatedAlertTechnicians = techAlerts.onCustomRequestCreatedAlertTechnicians;

// ==========================================
// V2 PAYMENT UPDATE TRIGGER
// ==========================================

// onPaymentUpdate Trigger Removed

// Database migration tool (Disabled for production safety)
// export const migrateDatabaseReq = functions.https.onRequest(async (req: any, res: any) => { ... });

export const onBookingCompletedAwardReferral = customerFeatures.onBookingCompletedAwardReferral;

// ==========================================
// 4. TESTING TOOLS
// ==========================================
// export const test_createCustomer = testing.createTestCustomer;
// export const test_createTechnician = testing.createTestTechnician;
// export const test_generateBooking = testing.generateTestBooking;
// export const test_simulatePayment = testing.simulatePayment;
// export const test_resetData = testing.resetTestData;

// ==========================================
// 5. RAZORPAY PAYMENT INTEGRATION
// ==========================================

// Payment Functions
// export const createPaymentOrder = razorpayPayments.createPaymentOrder; // Duplicate of initiateRazorpayPayment
// razorpayWebhook removed - use razorpayWebhookV2 only (see below)
export { razorpayWebhookV2 };
// export const verifyPayment = razorpayPayments.verifyPayment; // Duplicate of verifyRazorpayPayment
export const initiateRefund = razorpayPayments.initiateRefund;

// Technician wallet credit - NEW secure callable
export const createRazorpayOrder = razorpayPayments.createRazorpayOrder;

// Payout Functions (Admin)
export const getPendingPayouts = technicianPayouts.getPendingPayouts;
export const getPayoutHistory = technicianPayouts.getPayoutHistory;
export const getPayoutSummary = technicianPayouts.getPayoutSummary;
// export const markPayoutPaid = technicianPayouts.markPayoutPaid;
// export const putPayoutOnHold = technicianPayouts.putPayoutOnHold;
// export const releasePayoutFromHold = technicianPayouts.releasePayoutFromHold;
// export const bulkMarkPayoutsPaid = technicianPayouts.bulkMarkPayoutsPaid;
// export const getPayoutAnalytics = technicianPayouts.getPayoutAnalytics;

// ==========================================
// 6. CHAT SYSTEM
// ==========================================

export const getOrCreateChat = chat.getOrCreateChat;
export const sendChatMessage = chat.sendChatMessage;
export const markMessagesRead = chat.markMessagesRead;
export const getChatDetails = chat.getChatDetails;

