"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.manualCleanupIdempotency = exports.cleanupExpiredIdempotencyRecords = exports.cleanupStaleBookings = exports.adminConfirmPayment = exports.customerConfirmPayment = exports.confirmQRPayment = exports.generateTechnicianQR = exports.refundBookingPayment = exports.completeBooking = exports.technicianStartJob = exports.technicianRespondToJob = exports.approveBookingRequest = exports.getAllTechniciansForAdmin = exports.adminChangeTechnician = exports.cancelBooking = exports.technicianRejectBooking = exports.completeService = exports.startService = exports.technicianAcceptBooking = exports.rejectBookingByAdmin = exports.approveBookingByAdmin = exports.createBookingRequest = exports.verifyBookingStatuses = exports.migrateBookingStatusFunction = exports.onStaleTechnicianCleanup = exports.matchTechniciansV2 = exports.cleanupOldIdempotencyRecords = exports.cleanupStuckBankVerifications = exports.checkBankVerificationStatus = exports.razorpayBankWebhook = exports.verifyTechnicianBankAccount = exports.verifyTechnicianBankAccountSecure = exports.adminUpdateDocumentStatus = exports.adminUpdateBankStatus = exports.reuploadVerificationDocument = exports.updateTechnicianBankDetails = exports.updateTechnicianPersonalDetails = exports.saveTechnicianStepData = exports.updateTechnicianStatus = exports.submitTechnicianKyc = exports.saveTechnicianServices = exports.saveTechnicianDocuments = exports.saveTechnicianBasicDetails = exports.createTechnicianProfile = exports.canRetryPayment = exports.handlePaymentFailure = exports.initiateRefund = exports.createRazorpayOrder = exports.verifyPayment = exports.createPaymentOrder = void 0;
exports.getInstantServices = exports.getCustomRequestDetail = exports.getTechnicianInbox = exports.customerConfirmServicePayment = exports.technicianRespondServiceRequest = exports.adminApproveServiceRequest = exports.createCustomServiceRequest = exports.submitPartnerApplication = exports.submitSupportRequest = exports.submitServiceRating = exports.validateReferralCode = exports.managePaymentMethod = exports.toggleFavoriteCallable = exports.clearCartCallable = exports.removeFromCartCallable = exports.updateCartQuantityCallable = exports.addToCartCallable = exports.validateAddressForBooking = exports.manageAddressSecure = exports.setPrimaryAddress = exports.manageAddress = exports.updateTechnicianProfile = exports.updateUserProfile = exports.processWalletTransaction = exports.getMyTechnicianServices = exports.toggleTechnicianServiceStatus = exports.deleteTechnicianService = exports.updateTechnicianService = exports.createTechnicianService = exports.addTechnicianService = exports.checkRateLimit = exports.trackTechnicianMetrics = exports.generateAnalyticsSnapshot = exports.checkSystemHealth = exports.cleanupRateLimitRecords = exports.cleanupStaleTechnicianHeartbeats = exports.sanitizeBookingInput = exports.validateBookingCreation = exports.trackAnalyticsEvent = exports.getTechnicianEarnings = exports.generateWeeklyPayoutReport = exports.createPayoutLedgerEntry = exports.updateTechnicianHeartbeat = exports.createBookingIdempotent = exports.handlePaymentWebhook = exports.onCustomRequestStatusChange = exports.onBookingStatusChangeNotify = exports.onBookingStatusChange = exports.cleanupOTPRateLimits = exports.checkOTPRateLimitCallable = void 0;
exports.triggerTechnicianPayout = exports.findEligibleTechniciansCount = exports.admin_auditServiceCatalog = exports.admin_backfillImages = exports.admin_initializeHomeContent = exports.admin_manageNestedSubService = exports.admin_manageNestedService = exports.admin_manageCategory = exports.admin_manageHomeSections = exports.markBookingActive = exports.updateBookingPayment = exports.rejectBooking = exports.approveBooking = exports.admin_manageDispute = exports.onReviewCreated = exports.admin_manageReview = exports.admin_manageRiskProfile = exports.admin_sendPushNotification = exports.admin_processBookingPayout = exports.admin_adjustWallet = exports.admin_refundBooking = exports.admin_uploadServiceImage = exports.admin_manageBooking = exports.admin_disableService = exports.admin_rejectService = exports.admin_approveService = exports.getSubServicePriceHistory = exports.deleteSubService = exports.updatePricingConfig = exports.deleteService = exports.updateSubService = exports.createSubService = exports.updateService = exports.createService = exports.admin_manageService = exports.admin_updateTechServices = exports.admin_toggleTechAvailability = exports.admin_suspendTechnician = exports.admin_approveKYC = exports.admin_approveTechnician = exports.admin_approveTechnicianApplication = exports.admin_updateTechnician = exports.admin_getTechnicianById = exports.admin_getTechnicians = exports.admin_manageUser = exports.admin_blockUser = exports.admin_updateUser = exports.admin_getUserById = exports.admin_getUsers = exports.admin_getDashboardStats = void 0;
exports.onCustomRequestCreatedAlertTechnicians = exports.toggleOnlineStatus = exports.suspendTechnician = exports.approveTechnician = exports.approveKYC = exports.checkKycStatus = exports.evaluateTechnicianKyc = exports.onTechnicianApproved = exports.syncTechnicianApprovalToServices = exports.submitKYC = exports.onTechnicianApplicationStatusTrigger = exports.onTechnicianLikeNotification = exports.onBookingCancelledNotification = exports.onNewReviewNotification = exports.onUserCreated = exports.deleteAllNotificationsCallable = exports.deleteNotificationCallable = exports.markAllNotificationsRead = exports.markNotificationRead = exports.removeFcmToken = exports.saveFcmToken = exports.respondToAssignment = exports.adminRejectBooking = exports.adminApproveBooking = exports.assignTechnician = exports.assignTechnicianToBooking = exports.onTechnicianProfileUpdateRiskCheck = exports.onPaymentStatusRiskCheck = exports.onReviewRiskCheck = exports.onBookingStatusUpdateRiskCheck = exports.onBookingPaidGenerateInvoice = exports.markWalletReviewed = exports.getReconciliationAnomalies = exports.triggerManualReconciliation = exports.walletReconciliationDisabled = exports.getMyWithdrawalRequests = exports.getWithdrawalRequests = exports.rejectWithdrawalRequest = exports.approveWithdrawalRequest = exports.createWithdrawalRequest = exports.generateTechnicianWalletQR = exports.generateBookingQR = exports.getTechnicianPayoutHistory = exports.requestWithdrawal = exports.autoRetryCompensations = exports.getPendingCompensations = exports.retryRefundCompensation = exports.migrateSingleWallet = exports.settleTechnicianBalance = exports.razorpayPayoutWebhook = void 0;
exports.testBankVerification = exports.testRazorpayConnection = exports.testAuth = exports.getChatDetails = exports.markMessagesRead = exports.sendChatMessage = exports.getOrCreateChat = exports.getPayoutSummary = exports.getPayoutHistory = exports.getPendingPayouts = void 0;
exports.isAdmin = isAdmin;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
// Safe initialization - only initialize if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
console.log("BOOT OK - Functions loading...");
const testAuth_1 = require("./testing/testAuth");
Object.defineProperty(exports, "testAuth", { enumerable: true, get: function () { return testAuth_1.testAuth; } });
const adminDashboard = __importStar(require("./admin/dashboard"));
const adminUsers = __importStar(require("./admin/users"));
const adminTechs = __importStar(require("./admin/technicians"));
const adminServices = __importStar(require("./admin/services"));
const adminBookings = __importStar(require("./admin/bookings"));
const adminFinance = __importStar(require("./admin/finance"));
const adminNotif = __importStar(require("./admin/notifications"));
const notificationsMgmt = __importStar(require("./notifications_management"));
// Wallet Operations (Atomic & Safe) - CONSOLIDATED
const walletSafety = __importStar(require("./shared/wallet_safety"));
// Payment Modules (Razorpay after-service payment only)
const razorpayPayments = __importStar(require("./payments/razorpay"));
exports.createPaymentOrder = razorpayPayments.createPaymentOrder;
exports.verifyPayment = razorpayPayments.verifyPayment;
exports.createRazorpayOrder = razorpayPayments.createRazorpayOrder;
exports.initiateRefund = razorpayPayments.initiateRefund;
exports.handlePaymentFailure = razorpayPayments.handlePaymentFailure;
exports.canRetryPayment = razorpayPayments.canRetryPayment;
// Payment Modules (Technician Payouts)
const technicianPayouts = __importStar(require("./payments/payouts"));
// Partner Applications
const partnerApplications = __importStar(require("./partner/applications"));
// Technician Services (YouTube-style service listings)
const techServicesManagement = __importStar(require("./technician/services_management"));
// Chat System
const chat = __importStar(require("./chat/chat"));
// Technician Onboarding & Management
const techApp = __importStar(require("./technician/application"));
const techAuth = __importStar(require("./technician/auth"));
const techKyc = __importStar(require("./technician/kyc"));
const techOnboarding = __importStar(require("./technician/onboarding"));
const techProfile = __importStar(require("./technician/profile_management"));
const techTrack = __importStar(require("./technician/tracking"));
const adminTechMgmt = __importStar(require("./admin/technician_management"));
const techBankVerification = __importStar(require("./technician/bank_verification"));
const techBankStatus = __importStar(require("./technician/bank_status_checker"));
const techBankCleanup = __importStar(require("./technician/bank_verification_cleanup"));
// EXPORTS FOR TECHNICIAN ONBOARDING (SECURE CLOUD FUNCTIONS)
exports.createTechnicianProfile = techOnboarding.createTechnicianProfile;
exports.saveTechnicianBasicDetails = techOnboarding.saveTechnicianBasicDetails;
exports.saveTechnicianDocuments = techOnboarding.saveTechnicianDocuments;
exports.saveTechnicianServices = techOnboarding.saveTechnicianServices;
exports.submitTechnicianKyc = techOnboarding.submitTechnicianKyc;
exports.updateTechnicianStatus = techOnboarding.updateTechnicianStatus;
exports.saveTechnicianStepData = techOnboarding.saveTechnicianStepData;
// EXPORTS FOR TECHNICIAN PROFILE MANAGEMENT (SECURE CLOUD FUNCTIONS)
exports.updateTechnicianPersonalDetails = techProfile.updateTechnicianPersonalDetails;
exports.updateTechnicianBankDetails = techProfile.updateTechnicianBankDetails;
exports.reuploadVerificationDocument = techProfile.reuploadVerificationDocument;
exports.adminUpdateBankStatus = techProfile.adminUpdateBankStatus;
exports.adminUpdateDocumentStatus = techProfile.adminUpdateDocumentStatus;
// EXPORTS FOR BANK VERIFICATION (RAZORPAY FUND ACCOUNT)
exports.verifyTechnicianBankAccountSecure = techBankVerification.verifyTechnicianBankAccountSecure;
exports.verifyTechnicianBankAccount = techBankVerification.verifyTechnicianBankAccountSecure; // Alias for backward compatibility
exports.razorpayBankWebhook = techBankVerification.razorpayBankWebhook;
exports.checkBankVerificationStatus = techBankStatus.checkBankVerificationStatus;
// EXPORTS FOR BANK VERIFICATION CLEANUP (SCHEDULED FUNCTIONS)
exports.cleanupStuckBankVerifications = techBankCleanup.cleanupStuckBankVerifications;
exports.cleanupOldIdempotencyRecords = techBankCleanup.cleanupOldIdempotencyRecords;
const techTriggers = __importStar(require("./technician/triggers"));
const customRequest = __importStar(require("./custom_request"));
const techAlerts = __importStar(require("./technician/alerts"));
const instantBooking = __importStar(require("./instant_booking"));
const fraudProtection = __importStar(require("./fraud_protection"));
const db = admin.firestore();
const getDb = () => admin.firestore();
// Feature Modules
const customerFeatures = __importStar(require("./customer_features"));
// Smart Matching V2
const matching_v2_1 = require("./matching/matching_v2");
const technician_matching_1 = require("./matching/technician_matching");
var matchTechniciansV2_1 = require("./matching/matchTechniciansV2");
Object.defineProperty(exports, "matchTechniciansV2", { enumerable: true, get: function () { return matchTechniciansV2_1.matchTechniciansV2; } });
exports.onStaleTechnicianCleanup = technician_matching_1.cleanupStaleTechnicianStatus;
// Migration Functions
const migrateBookingStatus = __importStar(require("./admin/migrate_booking_status"));
exports.migrateBookingStatusFunction = migrateBookingStatus.migrateBookingStatus;
exports.verifyBookingStatuses = migrateBookingStatus.verifyBookingStatuses;
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
const unifiedBookingLifecycle = __importStar(require("./booking/unified_booking_lifecycle"));
exports.createBookingRequest = unifiedBookingLifecycle.createBookingRequest;
exports.approveBookingByAdmin = unifiedBookingLifecycle.approveBookingByAdmin;
exports.rejectBookingByAdmin = unifiedBookingLifecycle.rejectBookingByAdmin;
exports.technicianAcceptBooking = unifiedBookingLifecycle.technicianAcceptBooking;
exports.startService = unifiedBookingLifecycle.startService;
exports.completeService = unifiedBookingLifecycle.completeService;
exports.technicianRejectBooking = unifiedBookingLifecycle.technicianRejectBooking;
exports.cancelBooking = unifiedBookingLifecycle.cancelBooking;
exports.adminChangeTechnician = unifiedBookingLifecycle.adminChangeTechnician;
exports.getAllTechniciansForAdmin = unifiedBookingLifecycle.getAllTechniciansForAdmin;
// Legacy aliases for backward compatibility
exports.approveBookingRequest = unifiedBookingLifecycle.approveBookingByAdmin;
exports.technicianRespondToJob = unifiedBookingLifecycle.technicianAcceptBooking;
exports.technicianStartJob = unifiedBookingLifecycle.startService;
exports.completeBooking = unifiedBookingLifecycle.completeService;
// Refund System
const refundSystem = __importStar(require("./booking/refund_system"));
exports.refundBookingPayment = refundSystem.refundBookingPayment;
// QR Wallet Payment
const paymentQR = __importStar(require("./booking/payment_qr"));
exports.generateTechnicianQR = paymentQR.generateTechnicianQR;
exports.confirmQRPayment = paymentQR.confirmQRPayment;
// CRITICAL FIX: Customer Payment Confirmation
const customerPaymentConfirmation = __importStar(require("./booking/customer_payment_confirmation"));
exports.customerConfirmPayment = customerPaymentConfirmation.customerConfirmPayment;
exports.adminConfirmPayment = customerPaymentConfirmation.adminConfirmPayment;
// Stale Booking Cleanup
const bookingCleanup = __importStar(require("./booking/cleanup"));
exports.cleanupStaleBookings = bookingCleanup.cleanupStaleBookings;
// Idempotency Cleanup (Scheduled & Manual)
const idempotencyCleanup = __importStar(require("./booking/idempotency_cleanup"));
exports.cleanupExpiredIdempotencyRecords = idempotencyCleanup.cleanupExpiredIdempotencyRecords;
exports.manualCleanupIdempotency = idempotencyCleanup.manualCleanupIdempotency;
// OTP Rate Limiting (Backend Protection)
const otpRateLimiting = __importStar(require("./auth/otp_rate_limiting"));
exports.checkOTPRateLimitCallable = otpRateLimiting.checkOTPRateLimitCallable;
exports.cleanupOTPRateLimits = otpRateLimiting.cleanupOTPRateLimits;
// ================================================
// BOOKING & CUSTOM REQUEST NOTIFICATIONS TRIGGERS
// ================================================
// Booking Status Change Notifications
const bookingNotifications = __importStar(require("./booking/booking_notifications"));
exports.onBookingStatusChange = bookingNotifications.onBookingStatusChange;
// Booking Status Change Notifications (CRITICAL FIX)
const bookingStatusNotifications = __importStar(require("./booking/booking_status_notifications"));
exports.onBookingStatusChangeNotify = bookingStatusNotifications.onBookingStatusChange;
// Custom Request Status Change Notifications
const customRequestNotifications = __importStar(require("./custom_requests/custom_request_notifications"));
exports.onCustomRequestStatusChange = customRequestNotifications.onCustomRequestStatusChange;
// Production Hardening
var production_hardening_1 = require("./booking/production_hardening");
Object.defineProperty(exports, "handlePaymentWebhook", { enumerable: true, get: function () { return production_hardening_1.handlePaymentWebhook; } });
Object.defineProperty(exports, "createBookingIdempotent", { enumerable: true, get: function () { return production_hardening_1.createBookingIdempotent; } });
Object.defineProperty(exports, "updateTechnicianHeartbeat", { enumerable: true, get: function () { return production_hardening_1.updateTechnicianHeartbeat; } });
Object.defineProperty(exports, "createPayoutLedgerEntry", { enumerable: true, get: function () { return production_hardening_1.createPayoutLedgerEntry; } });
Object.defineProperty(exports, "generateWeeklyPayoutReport", { enumerable: true, get: function () { return production_hardening_1.generateWeeklyPayoutReport; } });
Object.defineProperty(exports, "getTechnicianEarnings", { enumerable: true, get: function () { return production_hardening_1.getTechnicianEarnings; } });
Object.defineProperty(exports, "trackAnalyticsEvent", { enumerable: true, get: function () { return production_hardening_1.trackAnalyticsEvent; } });
Object.defineProperty(exports, "validateBookingCreation", { enumerable: true, get: function () { return production_hardening_1.validateBookingCreation; } });
Object.defineProperty(exports, "sanitizeBookingInput", { enumerable: true, get: function () { return production_hardening_1.sanitizeBookingInput; } });
Object.defineProperty(exports, "cleanupStaleTechnicianHeartbeats", { enumerable: true, get: function () { return production_hardening_1.cleanupStaleTechnicianHeartbeats; } });
Object.defineProperty(exports, "cleanupRateLimitRecords", { enumerable: true, get: function () { return production_hardening_1.cleanupRateLimitRecords; } });
Object.defineProperty(exports, "checkSystemHealth", { enumerable: true, get: function () { return production_hardening_1.checkSystemHealth; } });
// ❌ DISABLED: onBookingStateChange - duplicate trigger (use onBookingStatusChange instead)
// onBookingStateChange,
Object.defineProperty(exports, "generateAnalyticsSnapshot", { enumerable: true, get: function () { return production_hardening_1.generateAnalyticsSnapshot; } });
Object.defineProperty(exports, "trackTechnicianMetrics", { enumerable: true, get: function () { return production_hardening_1.trackTechnicianMetrics; } });
var utils_1 = require("./shared/utils");
Object.defineProperty(exports, "checkRateLimit", { enumerable: true, get: function () { return utils_1.checkRateLimit; } });
// ==========================================
// TECHNICIAN SERVICE LISTINGS (YouTube-style)
// ==========================================
// Technician Services Management (Single Source of Truth)
// Using services_management.ts as the authoritative implementation
exports.addTechnicianService = techServicesManagement.addTechnicianService;
exports.createTechnicianService = techServicesManagement.addTechnicianService;
exports.updateTechnicianService = techServicesManagement.updateTechnicianService;
exports.deleteTechnicianService = techServicesManagement.deleteTechnicianService;
exports.toggleTechnicianServiceStatus = techServicesManagement.toggleTechnicianServiceStatus;
exports.getMyTechnicianServices = techServicesManagement.getMyTechnicianServices;
// ==========================================
// CONFIGURATION & HELPERS
// ==========================================
async function logActivity(actorType, actorUid, action, metadata) {
    try {
        await db.collection('activity_logs').add({
            actorType,
            actorUid,
            action,
            metadata,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    catch (e) {
        console.error('Failed to log activity:', e);
    }
}
async function isAdmin(uid) {
    try {
        const userRecord = await admin.auth().getUser(uid);
        return !!userRecord.customClaims?.admin;
    }
    catch (error) {
        console.error('Error checking admin status:', error);
        return false;
    }
}
// 1. CUSTOMER CALLABLES
exports.processWalletTransaction = walletSafety.creditWalletAtomic;
exports.updateUserProfile = customerFeatures.updateUserProfile;
exports.updateTechnicianProfile = customerFeatures.updateTechnicianProfile;
exports.manageAddress = customerFeatures.manageAddress;
// Address Management (Secure)
const addressManagement = __importStar(require("./customer/address_management"));
exports.setPrimaryAddress = addressManagement.setPrimaryAddress;
exports.manageAddressSecure = addressManagement.manageAddress;
exports.validateAddressForBooking = addressManagement.validateAddressForBooking;
// Cart Management (Secure)
const cartManagement = __importStar(require("./customer/cart_management"));
exports.addToCartCallable = cartManagement.addToCartCallable;
exports.updateCartQuantityCallable = cartManagement.updateCartQuantityCallable;
exports.removeFromCartCallable = cartManagement.removeFromCartCallable;
exports.clearCartCallable = cartManagement.clearCartCallable;
// Favorites Management (Secure)
const favoritesManagement = __importStar(require("./customer/favorites_management"));
exports.toggleFavoriteCallable = favoritesManagement.toggleFavoriteCallable;
exports.managePaymentMethod = customerFeatures.managePaymentMethod;
exports.validateReferralCode = customerFeatures.validateReferralCode;
exports.submitServiceRating = customerFeatures.submitServiceRating;
exports.submitSupportRequest = customerFeatures.submitSupportRequest;
// Partner Applications
exports.submitPartnerApplication = partnerApplications.submitPartnerApplication;
// Custom Service Request Features
exports.createCustomServiceRequest = customRequest.createCustomServiceRequest;
exports.adminApproveServiceRequest = customRequest.adminApproveServiceRequest;
exports.technicianRespondServiceRequest = customRequest.technicianRespondServiceRequest;
exports.customerConfirmServicePayment = customRequest.customerConfirmServicePayment;
exports.getTechnicianInbox = customRequest.getTechnicianInbox;
exports.getCustomRequestDetail = customRequest.getCustomRequestDetail;
// Instant Booking Features
exports.getInstantServices = instantBooking.getInstantServices;
// ==========================================
// 2. ADMIN & TECH CALLABLES
// ==========================================
exports.admin_getDashboardStats = adminDashboard.getDashboardStats;
exports.admin_getUsers = adminUsers.getUsers;
exports.admin_getUserById = adminUsers.getUserById;
exports.admin_updateUser = adminUsers.updateUser;
exports.admin_blockUser = adminUsers.blockUser;
exports.admin_manageUser = adminUsers.manageUser;
exports.admin_getTechnicians = adminTechs.getTechnicians;
exports.admin_getTechnicianById = adminTechs.getTechnicianById;
exports.admin_updateTechnician = adminTechs.updateTechnician;
exports.admin_approveTechnicianApplication = adminTechs.adminApproveTechnician;
exports.admin_approveTechnician = adminTechMgmt.approveTechnician;
exports.admin_approveKYC = adminTechMgmt.approveKYC;
exports.admin_suspendTechnician = adminTechMgmt.suspendTechnician;
exports.admin_toggleTechAvailability = adminTechs.toggleTechAvailability;
exports.admin_updateTechServices = adminTechs.updateTechServices;
exports.admin_manageService = adminServices.manageService;
exports.createService = adminServices.createService;
exports.updateService = adminServices.updateService;
exports.createSubService = adminServices.createSubService;
exports.updateSubService = adminServices.updateSubService;
exports.deleteService = adminServices.deleteService;
exports.updatePricingConfig = adminServices.updatePricingConfig;
exports.deleteSubService = adminServices.deleteSubService;
exports.getSubServicePriceHistory = adminServices.getSubServicePriceHistory;
// Admin Service Management (Production-Ready)
const adminServiceMgmt = __importStar(require("./admin/service_management"));
exports.admin_approveService = adminServiceMgmt.admin_approveService;
exports.admin_rejectService = adminServiceMgmt.admin_rejectService;
exports.admin_disableService = adminServiceMgmt.admin_disableService;
exports.admin_manageBooking = adminBookings.adminManageBooking;
const adminImages = __importStar(require("./admin/images"));
exports.admin_uploadServiceImage = adminImages.uploadServiceImage;
exports.admin_refundBooking = adminFinance.refundBooking;
exports.admin_adjustWallet = adminFinance.adjustWallet;
exports.admin_processBookingPayout = adminFinance.processBookingPayout;
exports.admin_sendPushNotification = adminNotif.sendPushNotification;
const adminRisk = __importStar(require("./admin/risk"));
exports.admin_manageRiskProfile = adminRisk.manageRiskProfile;
const adminReviews = __importStar(require("./admin/reviews"));
exports.admin_manageReview = adminReviews.manageReview;
// Review Aggregation Trigger
const review_triggers_1 = require("./reviews/review_triggers");
Object.defineProperty(exports, "onReviewCreated", { enumerable: true, get: function () { return review_triggers_1.onReviewCreated; } });
const adminDisputes = __importStar(require("./admin/disputes"));
exports.admin_manageDispute = adminDisputes.manageDispute;
const bookingModeration = __importStar(require("./admin/booking_moderation"));
exports.approveBooking = bookingModeration.approveBooking;
exports.rejectBooking = bookingModeration.rejectBooking;
exports.updateBookingPayment = bookingModeration.updateBookingPayment;
exports.markBookingActive = bookingModeration.markBookingActive;
const dynamic_content_1 = require("./admin/dynamic_content");
Object.defineProperty(exports, "admin_manageHomeSections", { enumerable: true, get: function () { return dynamic_content_1.admin_manageHomeSections; } });
Object.defineProperty(exports, "admin_manageCategory", { enumerable: true, get: function () { return dynamic_content_1.admin_manageCategory; } });
Object.defineProperty(exports, "admin_manageNestedService", { enumerable: true, get: function () { return dynamic_content_1.admin_manageNestedService; } });
Object.defineProperty(exports, "admin_manageNestedSubService", { enumerable: true, get: function () { return dynamic_content_1.admin_manageNestedSubService; } });
Object.defineProperty(exports, "findEligibleTechniciansCount", { enumerable: true, get: function () { return dynamic_content_1.findEligibleTechniciansCount; } });
const system_initialization_1 = require("./admin/system_initialization");
Object.defineProperty(exports, "admin_initializeHomeContent", { enumerable: true, get: function () { return system_initialization_1.admin_initializeHomeContent; } });
Object.defineProperty(exports, "admin_backfillImages", { enumerable: true, get: function () { return system_initialization_1.admin_backfillImages; } });
const catalog_audit_1 = require("./admin/catalog_audit");
Object.defineProperty(exports, "admin_auditServiceCatalog", { enumerable: true, get: function () { return catalog_audit_1.admin_auditServiceCatalog; } });
// Technician Finance & Payouts
const payoutLogic = __importStar(require("./finance/payout_logic"));
const technicianWithdrawal = __importStar(require("./finance/technician_withdrawal"));
const withdrawalRequests = __importStar(require("./finance/withdrawal_requests"));
const walletReconciliation = __importStar(require("./finance/wallet_reconciliation"));
const walletMigration = __importStar(require("./finance/wallet_migration"));
const refundCompensation = __importStar(require("./finance/refund_compensation"));
exports.triggerTechnicianPayout = payoutLogic.triggerTechnicianPayout;
exports.razorpayPayoutWebhook = payoutLogic.razorpayPayoutWebhook;
exports.settleTechnicianBalance = payoutLogic.settleTechnicianBalance;
// Wallet Migration (FIX 2: WALLET MIGRATION CHECK)
// TEMPORARILY DISABLED - Health check failure
// export const migrateAllWallets = walletMigration.migrateAllWallets;
exports.migrateSingleWallet = walletMigration.migrateSingleWallet;
// Refund Compensation (FIX 3: REFUND + WALLET CONSISTENCY)
exports.retryRefundCompensation = refundCompensation.retryRefundCompensation;
// TEMPORARILY DISABLED - Health check failure
// export const retryAllPendingCompensations = refundCompensation.retryAllPendingCompensations;
exports.getPendingCompensations = refundCompensation.getPendingCompensations;
exports.autoRetryCompensations = refundCompensation.autoRetryCompensations;
// DEPRECATED: Technician Withdrawal (Automatic Razorpay Payouts - No Admin Approval)
// Use withdrawal_requests.ts instead for admin-approved withdrawals
exports.requestWithdrawal = technicianWithdrawal.requestWithdrawal;
// TEMPORARILY DISABLED - Health check failure
// export const getTransactionHistory = technicianWithdrawal.getTransactionHistory;
exports.getTechnicianPayoutHistory = technicianWithdrawal.getPayoutHistory;
exports.generateBookingQR = technicianWithdrawal.generateBookingQR;
exports.generateTechnicianWalletQR = technicianWithdrawal.generateTechnicianWalletQR;
// NEW: Withdrawal Requests with Admin Approval
exports.createWithdrawalRequest = withdrawalRequests.createWithdrawalRequest;
exports.approveWithdrawalRequest = withdrawalRequests.approveWithdrawalRequest;
exports.rejectWithdrawalRequest = withdrawalRequests.rejectWithdrawalRequest;
exports.getWithdrawalRequests = withdrawalRequests.getWithdrawalRequests;
exports.getMyWithdrawalRequests = withdrawalRequests.getMyWithdrawalRequests;
// Wallet Reconciliation (Scheduled & Admin)
exports.walletReconciliationDisabled = walletReconciliation.walletReconciliationDisabled;
exports.triggerManualReconciliation = walletReconciliation.triggerManualReconciliation;
exports.getReconciliationAnomalies = walletReconciliation.getReconciliationAnomalies;
exports.markWalletReviewed = walletReconciliation.markWalletReviewed;
const invoiceLogic = __importStar(require("./finance/invoice_logic"));
exports.onBookingPaidGenerateInvoice = invoiceLogic.onBookingPaidGenerateInvoice;
// Fraud & Abuse Protection
exports.onBookingStatusUpdateRiskCheck = fraudProtection.onBookingStatusUpdateRiskCheck;
exports.onReviewRiskCheck = fraudProtection.onReviewRiskCheck;
exports.onPaymentStatusRiskCheck = fraudProtection.onPaymentStatusRiskCheck;
exports.onTechnicianProfileUpdateRiskCheck = fraudProtection.onTechnicianProfileUpdateRiskCheck;
// SMART MATCHING V2
exports.assignTechnicianToBooking = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }
    if (!(await isAdmin(context.auth.uid))) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can force assignment');
    }
    return await (0, matching_v2_1.matchAndAssignBooking)(data.bookingId, { forceAssign: true });
});
// Add missing function aliases for admin panel compatibility
exports.assignTechnician = exports.assignTechnicianToBooking;
exports.adminApproveBooking = exports.approveBookingByAdmin;
exports.adminRejectBooking = exports.technicianRejectBooking;
exports.respondToAssignment = matching_v2_1.handleAssignmentResponse;
// ==========================================
// FCM TOKEN MANAGEMENT
// ==========================================
/**
 * Saves FCM token for a user (customer or technician)
 * Supports multiple devices by storing tokens in a subcollection
 */
exports.saveFcmToken = functions.region('asia-south1').https.onCall(async (data, context) => {
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
    }
    catch (error) {
        console.error(`[FCM] Failed to save token for ${uid}:`, error);
        throw new functions.https.HttpsError('internal', 'Failed to save token');
    }
});
/**
 * Removes FCM token for a user
 * Called on logout or token refresh
 */
exports.removeFcmToken = functions.region('asia-south1').https.onCall(async (data, context) => {
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
    }
    catch (error) {
        console.error(`[FCM] Failed to remove token for ${uid}:`, error);
        throw new functions.https.HttpsError('internal', 'Failed to remove token');
    }
});
// Notification Management
exports.markNotificationRead = notificationsMgmt.markNotificationRead;
exports.markAllNotificationsRead = notificationsMgmt.markAllNotificationsRead;
exports.deleteNotificationCallable = notificationsMgmt.deleteNotificationCallable;
exports.deleteAllNotificationsCallable = notificationsMgmt.deleteAllNotificationsCallable;
// ==========================================
// 3. TRIGGERS
// ==========================================
// Auth trigger: Create minimal technician document when user is created
exports.onUserCreated = techAuth.createTechnicianOnAuthCreate;
// ==========================================
// NOTIFICATION TRIGGERS
// ==========================================
const notificationTriggers = __importStar(require("./notification_triggers"));
exports.onNewReviewNotification = notificationTriggers.onNewReviewNotification;
exports.onBookingCancelledNotification = notificationTriggers.onBookingCancelledNotification;
exports.onTechnicianLikeNotification = notificationTriggers.onTechnicianLikeNotification;
exports.onTechnicianApplicationStatusTrigger = notificationTriggers.onTechnicianApplicationStatusTrigger;
// ==========================================
// TECHNICIAN ONBOARDING
// ==========================================
// Application Flow
exports.submitKYC = techApp.submitKYC;
exports.syncTechnicianApprovalToServices = techTriggers.syncTechnicianApprovalToServices;
// Technician Approval Notifications
const techApprovalNotif = __importStar(require("./technician/approval_notifications"));
exports.onTechnicianApproved = techApprovalNotif.onTechnicianApproved;
// KYC Evaluation (Backend-controlled)
exports.evaluateTechnicianKyc = techKyc.evaluateTechnicianKyc;
exports.checkKycStatus = techKyc.checkKycStatus;
// Admin Management
exports.approveKYC = adminTechMgmt.approveKYC;
exports.approveTechnician = adminTechMgmt.approveTechnician;
exports.suspendTechnician = adminTechMgmt.suspendTechnician;
// Tracking & Security
exports.toggleOnlineStatus = techTrack.toggleOnlineStatus;
exports.onCustomRequestCreatedAlertTechnicians = techAlerts.onCustomRequestCreatedAlertTechnicians;
// ==========================================
// CUSTOMER FEATURES
// ==========================================
// TEMPORARILY DISABLED - Health check failure
// export const onBookingCompletedAwardReferral = customerFeatures.onBookingCompletedAwardReferral;
// Payout Functions (Admin)
exports.getPendingPayouts = technicianPayouts.getPendingPayouts;
exports.getPayoutHistory = technicianPayouts.getPayoutHistory;
exports.getPayoutSummary = technicianPayouts.getPayoutSummary;
// ==========================================
// CHAT SYSTEM
// ==========================================
exports.getOrCreateChat = chat.getOrCreateChat;
exports.sendChatMessage = chat.sendChatMessage;
exports.markMessagesRead = chat.markMessagesRead;
exports.getChatDetails = chat.getChatDetails;
// Razorpay Connection Tests
const testRazorpay = __importStar(require("./payments/testRazorpay"));
exports.testRazorpayConnection = testRazorpay.testRazorpayConnection;
exports.testBankVerification = testRazorpay.testBankVerification;
//# sourceMappingURL=index.js.map