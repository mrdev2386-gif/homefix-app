"use strict";
/**
 * FIRESTORE SECURITY AUDIT - Validates rule enforcement
 *
 * CRITICAL CHECKS:
 * - No client-side Firestore writes to protected collections
 * - All write operations go through Cloud Functions
 * - Admin role validation
 * - User ownership validation
 * - Protected field modification prevention
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.PROTECTED_COLLECTIONS = void 0;
exports.assertAuthenticated = assertAuthenticated;
exports.verifyAdmin = verifyAdmin;
exports.verifyOwnership = verifyOwnership;
exports.verifyTechnicianApproved = verifyTechnicianApproved;
exports.verifyCustomerExists = verifyCustomerExists;
exports.verifyBookingOwnership = verifyBookingOwnership;
exports.verifyProtectedFieldsNotModified = verifyProtectedFieldsNotModified;
exports.validateBookingStatusTransition = validateBookingStatusTransition;
exports.validateWalletOperation = validateWalletOperation;
exports.logSecurityEvent = logSecurityEvent;
exports.checkSuspiciousActivity = checkSuspiciousActivity;
exports.sanitizeInput = sanitizeInput;
exports.isProtectedCollection = isProtectedCollection;
exports.generateSecurityReport = generateSecurityReport;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const db = admin.firestore();
/**
 * Assert user is authenticated
 */
function assertAuthenticated(context) {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
}
/**
 * Verify user is admin
 */
async function verifyAdmin(uid) {
    try {
        const adminDoc = await db.collection('admins').doc(uid).get();
        return adminDoc.exists;
    }
    catch (error) {
        console.error('[SECURITY] Error verifying admin:', error);
        return false;
    }
}
/**
 * Verify user owns document
 */
function verifyOwnership(uid, ownerId) {
    return uid === ownerId;
}
/**
 * Verify technician is approved
 */
async function verifyTechnicianApproved(technicianId) {
    try {
        const techDoc = await db.collection('technicians').doc(technicianId).get();
        if (!techDoc.exists)
            return false;
        return techDoc.data()?.verificationStatus === 'approved';
    }
    catch (error) {
        console.error('[SECURITY] Error verifying technician:', error);
        return false;
    }
}
/**
 * Verify customer exists
 */
async function verifyCustomerExists(customerId) {
    try {
        const customerDoc = await db.collection('users').doc(customerId).get();
        return customerDoc.exists;
    }
    catch (error) {
        console.error('[SECURITY] Error verifying customer:', error);
        return false;
    }
}
/**
 * Verify booking ownership
 */
async function verifyBookingOwnership(bookingId, uid, role) {
    try {
        const bookingDoc = await db.collection('bookings').doc(bookingId).get();
        if (!bookingDoc.exists)
            return false;
        const booking = bookingDoc.data();
        if (role === 'admin') {
            return await verifyAdmin(uid);
        }
        else if (role === 'customer') {
            return booking.customerId === uid;
        }
        else if (role === 'technician') {
            return booking.technicianId === uid;
        }
        return false;
    }
    catch (error) {
        console.error('[SECURITY] Error verifying booking ownership:', error);
        return false;
    }
}
/**
 * Verify protected field not modified
 *
 * Protected fields that only admins/Cloud Functions can modify:
 * - Booking status
 * - Payment status
 * - Wallet balance
 * - Verification status
 */
function verifyProtectedFieldsNotModified(oldData, newData, protectedFields) {
    for (const field of protectedFields) {
        if (oldData[field] !== newData[field]) {
            console.warn(`[SECURITY] Protected field modified: ${field}`);
            return false;
        }
    }
    return true;
}
/**
 * Validate booking status transition
 */
function validateBookingStatusTransition(currentStatus, newStatus, role) {
    // Define allowed transitions per role
    const allowedTransitions = {
        customer: {
            'pending_admin_approval': ['cancelled'],
            'approved_by_admin': ['cancelled'],
            'technician_accepted': ['cancelled'],
            'service_in_progress': ['cancelled'],
            'service_completed': ['completed'],
        },
        technician: {
            'approved_by_admin': ['technician_accepted', 'technician_rejected'],
            'technician_accepted': ['service_in_progress', 'cancelled'],
            'service_in_progress': ['service_completed'],
        },
        admin: {
            'pending_admin_approval': ['approved_by_admin', 'rejected_by_admin'],
            'approved_by_admin': ['technician_accepted', 'cancelled'],
            'technician_accepted': ['service_in_progress', 'cancelled'],
            'service_in_progress': ['service_completed', 'cancelled'],
            'service_completed': ['completed', 'cancelled'],
        },
    };
    const transitions = allowedTransitions[role]?.[currentStatus] || [];
    return transitions.includes(newStatus);
}
/**
 * Validate wallet operation
 */
async function validateWalletOperation(userId, operationType, amount) {
    if (amount <= 0) {
        return { valid: false, reason: 'Amount must be positive' };
    }
    if (operationType === 'debit') {
        const walletDoc = await db.collection('wallets').doc(userId).get();
        if (!walletDoc.exists) {
            return { valid: false, reason: 'Wallet not found' };
        }
        const balance = walletDoc.data()?.availableBalance || 0;
        if (balance < amount) {
            return { valid: false, reason: 'Insufficient balance' };
        }
    }
    return { valid: true };
}
/**
 * Audit trail - log all sensitive operations
 */
async function logSecurityEvent(eventType, userId, resource, action, details) {
    try {
        await db.collection('security_audit_logs').add({
            eventType,
            userId,
            resource,
            action,
            details: details || {},
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: details?.ipAddress || 'unknown',
        });
    }
    catch (error) {
        console.error('[SECURITY] Error logging security event:', error);
    }
}
/**
 * Check for suspicious activity
 */
async function checkSuspiciousActivity(userId, activityType, timeWindowMinutes = 60) {
    try {
        const cutoffTime = new Date(Date.now() - timeWindowMinutes * 60 * 1000);
        const snapshot = await db
            .collection('security_audit_logs')
            .where('userId', '==', userId)
            .where('eventType', '==', activityType)
            .where('timestamp', '>=', cutoffTime)
            .get();
        const count = snapshot.size;
        // Flag as suspicious if more than 10 attempts in time window
        const suspicious = count > 10;
        return { suspicious, count };
    }
    catch (error) {
        console.error('[SECURITY] Error checking suspicious activity:', error);
        return { suspicious: false, count: 0 };
    }
}
/**
 * Validate input sanitization
 */
function sanitizeInput(input, type) {
    if (type === 'string') {
        if (typeof input !== 'string')
            return null;
        return input.trim().substring(0, 500); // Max 500 chars
    }
    if (type === 'number') {
        const num = parseFloat(input);
        return isNaN(num) ? null : num;
    }
    if (type === 'email') {
        if (typeof input !== 'string')
            return null;
        const email = input.trim().toLowerCase();
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email) ? email : null;
    }
    if (type === 'phone') {
        if (typeof input !== 'string')
            return null;
        const phone = input.replace(/\D/g, '');
        return phone.length >= 10 ? phone : null;
    }
    return null;
}
/**
 * Verify no client-side Firestore writes
 *
 * This should be checked in Firestore rules:
 * - Bookings: No direct writes (only via Cloud Functions)
 * - Wallets: No direct writes (only via Cloud Functions)
 * - Technician services: Only technician can create (with status='pending')
 * - Reviews: Only customer can create (immutable after)
 */
exports.PROTECTED_COLLECTIONS = [
    'bookings',
    'wallets',
    'technician_wallets',
    'wallet_transactions',
    'notifications',
    'admin_logs',
    'security_audit_logs',
];
/**
 * Verify collection is protected
 */
function isProtectedCollection(collection) {
    return exports.PROTECTED_COLLECTIONS.includes(collection);
}
/**
 * Generate security report
 */
async function generateSecurityReport() {
    try {
        const cutoffTime = new Date(Date.now() - 24 * 60 * 60 * 1000); // Last 24 hours
        const [suspiciousSnapshot, unauthorizedSnapshot, protectedSnapshot] = await Promise.all([
            db
                .collection('security_audit_logs')
                .where('eventType', '==', 'suspicious_activity')
                .where('timestamp', '>=', cutoffTime)
                .get(),
            db
                .collection('security_audit_logs')
                .where('eventType', '==', 'unauthorized_attempt')
                .where('timestamp', '>=', cutoffTime)
                .get(),
            db
                .collection('security_audit_logs')
                .where('eventType', '==', 'protected_field_modification')
                .where('timestamp', '>=', cutoffTime)
                .get(),
        ]);
        return {
            timestamp: new Date(),
            suspiciousActivities: suspiciousSnapshot.size,
            unauthorizedAttempts: unauthorizedSnapshot.size,
            protectedFieldModifications: protectedSnapshot.size,
        };
    }
    catch (error) {
        console.error('[SECURITY] Error generating security report:', error);
        return {
            timestamp: new Date(),
            suspiciousActivities: 0,
            unauthorizedAttempts: 0,
            protectedFieldModifications: 0,
        };
    }
}
//# sourceMappingURL=security_audit.js.map