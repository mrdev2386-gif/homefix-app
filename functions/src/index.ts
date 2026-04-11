import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

// Safe initialization - only initialize if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
console.log("BOOT OK - Functions loading...");

import * as testing from './testing';
import { testAuth } from './testing/testAuth';
import { getAppConfig } from './shared/config';
import * as crypto from 'crypto';



import * as adminDashboard from './admin/dashboard';
import * as adminUsers from './admin/users';
import * as adminTechs from './admin/technicians';
import * as adminServices from './admin/services';
import * as adminBookings from './admin/bookings';
import * as adminFinance from './admin/finance';
import * as adminNotif from './admin/notifications';
import * as notificationsMgmt from './notifications_management';
import * as adminDynamic from './admin/dynamic_content';

// Wallet Operations (Atomic & Safe) - CONSOLIDATED
import * as walletSafety from './shared/wallet_safety';

// Payment Modules (Razorpay after-service payment only)
import * as razorpayPayments from './payments/razorpay';
export const createPaymentOrder = razorpayPayments.createPaymentOrder;
export const verifyPayment = razorpayPayments.verifyPayment;
export const createRazorpayOrder = razorpayPayments.createRazorpayOrder;
export const initiateRefund = razorpayPayments.initiateRefund;
export const handlePaymentFailure = razorpayPayments.handlePaymentFailure;
export const canRetryPayment = razorpayPayments.canRetryPayment;

// Payment Modules (Technician Payouts)
import * as technicianPayouts from './payments/payouts';

// Partner Applications
import * as partnerApplications from './partner/applications';

// Technician Services (YouTube-style service listings)
import * as techServicesManagement from './technician/services_management';

// Chat System
import * as chat from './chat/chat';

// Technician Onboarding & Management
import * as techApp from './technician/application';
import * as techAuth from './technician/auth';
import * as techKyc from './technician/kyc';
import * as techOnboarding from './technician/onboarding';
import * as techProfile from './technician/profile_management';
import * as techTrack from './technician/tracking';
import * as adminTechMgmt from './admin/technician_management';
import * as techBankVerification from './technician/bank_verification';
import * as techBankStatus from './technician/bank_status_checker';
import * as techBankCleanup from './technician/bank_verification_cleanup';

// EXPORTS FOR TECHNICIAN ONBOARDING (SECURE CLOUD FUNCTIONS)
export const createTechnicianProfile = techOnboarding.createTechnicianProfile;
export const saveTechnicianBasicDetails = techOnboarding.saveTechnicianBasicDetails;
export const saveTechnicianDocuments = techOnboarding.saveTechnicianDocuments;
export const saveTechnicianServices = techOnboarding.saveTechnicianServices;
export const submitTechnicianKyc = techOnboarding.submitTechnicianKyc;
export const updateTechnicianStatus = techOnboarding.updateTechnicianStatus;
export const saveTechnicianStepData = techOnboarding.saveTechnicianStepData;

// EXPORTS FOR TECHNICIAN PROFILE MANAGEMENT (SECURE CLOUD FUNCTIONS)
export const updateTechnicianPersonalDetails = techProfile.updateTechnicianPersonalDetails;
export const updateTechnicianBankDetails = techProfile.updateTechnicianBankDetails;
export const reuploadVerificationDocument = techProfile.reuploadVerificationDocument;
export const adminUpdateBankStatus = techProfile.adminUpdateBankStatus;
export const adminUpdateDocumentStatus = techProfile.adminUpdateDocumentStatus;

// EXPORTS FOR BANK VERIFICATION (RAZORPAY FUND ACCOUNT)
export const verifyTechnicianBankAccountSecure = techBankVerification.verifyTechnicianBankAccountSecure;
export const verifyTechnicianBankAccount = techBankVerification.verifyTechnicianBankAccountSecure; // Alias for backward compatibility
export const razorpayBankWebhook = techBankVerification.razorpayBankWebhook;
export const checkBankVerificationStatus = techBankStatus.checkBankVerificationStatus;

// EXPORTS FOR BANK VERIFICATION CLEANUP (SCHEDULED FUNCTIONS)
export const cleanupStuckBankVerifications = techBankCleanup.cleanupStuckBankVerifications;
export const cleanupOldIdempotencyRecords = techBankCleanup.cleanupOldIdempotencyRecords;

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



// Helpers
import { sendPushNotification, NotificationPayload } from './shared/notifications';

// Feature Modules
import * as customerFeatures from './customer_features';
// Smart Matching V2
import { matchAndAssignBooking, handleAssignmentResponse } from './matching/matching_v2';
import { matchTechnicians as matchTechs, updateTechnicianAssignment, cleanupStaleTechnicianStatus } from './matching/technician_matching';
export { matchTechniciansV2 } from './matching/matchTechniciansV2';

export const onStaleTechnicianCleanup = cleanupStaleTechnicianStatus;

// Migration Functions
import * as migrateBookingStatus from './admin/migrate_booking_status';
export const migrateBookingStatusFunction = migrateBookingStatus.migrateBookingStatus;
export const verifyBookingStatuses = migrateBookingStatus.verifyBookingStatuses;

// ==========================================
// UNIFIED BOOKING LIFECYCLE FUNCTIONS (SINGLE SOURCE OF TRUTH)
// ==========================================
// CONSOLIDATION: All booking creation logic is now in unified_booking_lifecycle.ts
// DEPRECATED FILES (disabled to prevent accidental imports):
//   - new_booking_flow.ts.DISABLED (had inconsistent pricing logic)
//   - complete_booking_flow.ts.DISABLED (had inconsistent pricing logic)
// 
// PRICING LOGIC (UNIFIED - STRICT SAFE PARSING):
//   const parsedPrice = Number(basePrice);
//   const calculatedPrice = (!isNaN(parsedPrice) && parsedPrice > 0) ? parsedPrice : 0;
//   const parsedOffer = Number(service.offerPrice);
//   const offer = (!isNaN(parsedOffer) && parsedOffer > 0) ? parsedOffer : null;
//   let finalPrice = calculatedPrice;
//   if (offer !== null && offer < calculatedPrice) {
//     finalPrice = offer;
//   }
//   finalAmount = finalPrice
// 
// VERIFICATION LOG: 🔥 CREATE BOOKING FUNCTION HIT - unified_booking_lifecycle.ts
import * as unifiedBookingLifecycle from './booking/unified_booking_lifecycle';
export const createBookingRequest = unifiedBookingLifecycle.createBookingRequest;
export const approveBookingByAdmin = unifiedBookingLifecycle.approveBookingByAdmin;
export const rejectBookingByAdmin = unifiedBookingLifecycle.rejectBookingByAdmin;
export const technicianAcceptBooking = unifiedBookingLifecycle.technicianAcceptBooking;
export const startService = unifiedBookingLifecycle.startService;
export const completeService = unifiedBookingLifecycle.completeService;
export const technicianRejectBooking = unifiedBookingLifecycle.technicianRejectBooking;
export const cancelBooking = unifiedBookingLifecycle.cancelBooking;
export const adminChangeTechnician = unifiedBookingLifecycle.adminChangeTechnician;
export const getAllTechniciansForAdmin = unifiedBookingLifecycle.getAllTechniciansForAdmin;

// Legacy aliases for backward compatibility
export const approveBookingRequest = unifiedBookingLifecycle.approveBookingByAdmin;
export const technicianRespondToJob = unifiedBookingLifecycle.technicianAcceptBooking;
export const technicianStartJob = unifiedBookingLifecycle.startService;
export const completeBooking = unifiedBookingLifecycle.completeService;

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

// Idempotency Cleanup (Scheduled & Manual)
import * as idempotencyCleanup from './booking/idempotency_cleanup';
export const cleanupExpiredIdempotencyRecords = idempotencyCleanup.cleanupExpiredIdempotencyRecords;
export const manualCleanupIdempotency = idempotencyCleanup.manualCleanupIdempotency;

// OTP Rate Limiting (Backend Protection)
import * as otpRateLimiting from './auth/otp_rate_limiting';
export const checkOTPRateLimitCallable = otpRateLimiting.checkOTPRateLimitCallable;
export const cleanupOTPRateLimits = otpRateLimiting.cleanupOTPRateLimits;

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
    // ❌ DISABLED: onBookingStateChange - duplicate trigger (use onBookingStatusChange instead)
    // onBookingStateChange,
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
export const getMyTechnicianServices = techServicesManagement.getMyTechnicianServices;

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
    try {
        const userRecord = await admin.auth().getUser(uid);
        return !!userRecord.customClaims?.admin;
    } catch (error) {
        console.error('Error checking admin status:', error);
        return false;
    }
}

// 1. CUSTOMER CALLABLES

export const processWalletTransaction = walletSafety.creditWalletAtomic;

export const updateUserProfile = customerFeatures.updateUserProfile;
export const updateTechnicianProfile = customerFeatures.updateTechnicianProfile;
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
export const managePaymentMethod = customerFeatures.managePaymentMethod;
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
export const updateBookingPayment = bookingModeration.updateBookingPayment;
export const markBookingActive = bookingModeration.markBookingActive;

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
import * as payoutLogic from './finance/payout_logic';
import * as technicianWithdrawal from './finance/technician_withdrawal';
import * as walletReconciliation from './finance/wallet_reconciliation';
import * as walletMigration from './finance/wallet_migration';
import * as refundCompensation from './finance/refund_compensation';

export const triggerTechnicianPayout = payoutLogic.triggerTechnicianPayout;
export const razorpayPayoutWebhook = payoutLogic.razorpayPayoutWebhook;
export const settleTechnicianBalance = payoutLogic.settleTechnicianBalance;

// Wallet Migration (FIX 2: WALLET MIGRATION CHECK)
export const migrateAllWallets = walletMigration.migrateAllWallets;
export const migrateSingleWallet = walletMigration.migrateSingleWallet;

// Refund Compensation (FIX 3: REFUND + WALLET CONSISTENCY)
export const retryRefundCompensation = refundCompensation.retryRefundCompensation;
export const retryAllPendingCompensations = refundCompensation.retryAllPendingCompensations;
export const getPendingCompensations = refundCompensation.getPendingCompensations;
export const autoRetryCompensations = refundCompensation.autoRetryCompensations;

// Technician Withdrawal (Automatic Razorpay Payouts - No Admin Approval)
export const requestWithdrawal = technicianWithdrawal.requestWithdrawal;
export const getTransactionHistory = technicianWithdrawal.getTransactionHistory;
export const getTechnicianPayoutHistory = technicianWithdrawal.getPayoutHistory;
export const generateBookingQR = technicianWithdrawal.generateBookingQR;
export const generateTechnicianWalletQR = technicianWithdrawal.generateTechnicianWalletQR;

// Wallet Reconciliation (Scheduled & Admin)
export const walletReconciliationDisabled = walletReconciliation.walletReconciliationDisabled;
export const triggerManualReconciliation = walletReconciliation.triggerManualReconciliation;
export const getReconciliationAnomalies = walletReconciliation.getReconciliationAnomalies;
export const markWalletReviewed = walletReconciliation.markWalletReviewed;
import * as invoiceLogic from './finance/invoice_logic';
export const onBookingPaidGenerateInvoice = invoiceLogic.onBookingPaidGenerateInvoice;

// Fraud & Abuse Protection
export const onBookingStatusUpdateRiskCheck = fraudProtection.onBookingStatusUpdateRiskCheck;
export const onReviewRiskCheck = fraudProtection.onReviewRiskCheck;
export const onPaymentStatusRiskCheck = fraudProtection.onPaymentStatusRiskCheck;
export const onTechnicianProfileUpdateRiskCheck = fraudProtection.onTechnicianProfileUpdateRiskCheck;

// SMART MATCHING V2
export const assignTechnicianToBooking = functions.region('asia-south1').https.onCall(
    async (data, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }
        if (!(await isAdmin(context.auth.uid))) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can force assignment');
        }
        return await matchAndAssignBooking(data.bookingId, { forceAssign: true });
    }
);

// Add missing function aliases for admin panel compatibility
export const assignTechnician = assignTechnicianToBooking;
export const adminApproveBooking = approveBookingByAdmin;
export const adminRejectBooking = technicianRejectBooking;

export const respondToAssignment = handleAssignmentResponse;

// ==========================================
// FCM TOKEN MANAGEMENT
// ==========================================

/**
 * Saves FCM token for a user (customer or technician)
 * Supports multiple devices by storing tokens in a subcollection
 */
export const saveFcmToken = functions.region('asia-south1').https.onCall(
    async (data, context) => {
        const uid = context.auth?.uid;
        if (!uid) {
            throw new functions.https.HttpsError('unauthenticated', 'User not logged in');
        }

        const { token, platform = 'unknown', userType = 'customer' } = data;

        if (!token) {
            throw new functions.https.HttpsError('invalid-argument', 'Token is required');
        }

        try {
            const collectionPath = userType === 'technician' ? 'technicians' : 'users';
            const userDocRef = db.collection(collectionPath).doc(uid);

            const tokenHash = Buffer.from(token).toString('base64').substring(0, 150);
            const tokenDocRef = userDocRef.collection('fcmTokens').doc(tokenHash);

            await tokenDocRef.set({
                token,
                platform,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
                invalidCount: 0,
                isActive: true,
            }, { merge: true });

            await userDocRef.set({ fcmToken: token }, { merge: true });

            console.log(`[FCM] Token saved for ${userType}:${uid}`);
            return { success: true, tokenId: tokenHash };
        } catch (error: any) {
            console.error(`[FCM] Failed to save token for ${uid}:`, error);
            throw new functions.https.HttpsError('internal', 'Failed to save token');
        }
    }
);

/**
 * Removes FCM token for a user
 * Called on logout or token refresh
 */
export const removeFcmToken = functions.region('asia-south1').https.onCall(
    async (data, context) => {
        const uid = context.auth?.uid;
        if (!uid) {
            throw new functions.https.HttpsError('unauthenticated', 'User not logged in');
        }

        const { token, userType = 'customer' } = data;

        if (!token) {
            throw new functions.https.HttpsError('invalid-argument', 'Token is required');
        }

        try {
            const collectionPath = userType === 'technician' ? 'technicians' : 'users';

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
            throw new functions.https.HttpsError('internal', 'Failed to remove token');
        }
    }
);

// Notification Management
export const markNotificationRead = notificationsMgmt.markNotificationRead;
export const markAllNotificationsRead = notificationsMgmt.markAllNotificationsRead;
export const deleteNotificationCallable = notificationsMgmt.deleteNotificationCallable;
export const deleteAllNotificationsCallable = notificationsMgmt.deleteAllNotificationsCallable;

// ==========================================
// 3. TRIGGERS
// ==========================================

// Auth trigger: Create minimal technician document when user is created
export const onUserCreated = techAuth.createTechnicianOnAuthCreate;

// ==========================================
// NOTIFICATION TRIGGERS
// ==========================================

import * as notificationTriggers from './notification_triggers';

export const onNewReviewNotification = notificationTriggers.onNewReviewNotification;
export const onBookingCancelledNotification = notificationTriggers.onBookingCancelledNotification;
export const onTechnicianLikeNotification = notificationTriggers.onTechnicianLikeNotification;
export const onTechnicianApplicationStatusTrigger = notificationTriggers.onTechnicianApplicationStatusTrigger;

// ==========================================
// TECHNICIAN ONBOARDING
// ==========================================

// Application Flow
export const submitKYC = techApp.submitKYC;
export const syncTechnicianApprovalToServices = techTriggers.syncTechnicianApprovalToServices;

// Technician Approval Notifications
import * as techApprovalNotif from './technician/approval_notifications';
export const onTechnicianApproved = techApprovalNotif.onTechnicianApproved;

// KYC Evaluation (Backend-controlled)
export const evaluateTechnicianKyc = techKyc.evaluateTechnicianKyc;
export const checkKycStatus = techKyc.checkKycStatus;

// Admin Management
export const approveKYC = adminTechMgmt.approveKYC;
export const approveTechnician = adminTechMgmt.approveTechnician;
export const suspendTechnician = adminTechMgmt.suspendTechnician;

// Tracking & Security
export const toggleOnlineStatus = techTrack.toggleOnlineStatus;

export const onCustomRequestCreatedAlertTechnicians = techAlerts.onCustomRequestCreatedAlertTechnicians;

// ==========================================
// CUSTOMER FEATURES
// ==========================================

export const onBookingCompletedAwardReferral = customerFeatures.onBookingCompletedAwardReferral;



// Payout Functions (Admin)
export const getPendingPayouts = technicianPayouts.getPendingPayouts;
export const getPayoutHistory = technicianPayouts.getPayoutHistory;
export const getPayoutSummary = technicianPayouts.getPayoutSummary;

// ==========================================
// CHAT SYSTEM
// ==========================================

export const getOrCreateChat = chat.getOrCreateChat;
export const sendChatMessage = chat.sendChatMessage;
export const markMessagesRead = chat.markMessagesRead;
export const getChatDetails = chat.getChatDetails;

// ==========================================
// DEBUG & TESTING
// ==========================================

export { testAuth };

// Razorpay Connection Tests
import * as testRazorpay from './payments/testRazorpay';
export const testRazorpayConnection = testRazorpay.testRazorpayConnection;
export const testBankVerification = testRazorpay.testBankVerification;
