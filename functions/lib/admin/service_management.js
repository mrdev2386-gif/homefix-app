"use strict";
/**
 * Admin Service Management - Production Ready
 *
 * ARCHITECTURE:
 * - Single Source of Truth: technician_services/{serviceId}
 * - ALL writes via Cloud Functions (no direct Firestore writes)
 * - Status-based moderation: pending -> approved/rejected/disabled
 * - Admin Panel queries top-level collection
 * - Customer App shows only approved services
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
exports.admin_disableService = exports.admin_rejectService = exports.admin_approveService = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("../shared/security");
const db = admin.firestore();
/**
 * SECURITY: Verify admin role from Firestore
 */
async function verifyAdmin(uid) {
    const adminDoc = await db.collection('admins').doc(uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }
}
/**
 * Log admin action for audit trail
 * STEP 5: ADMIN AUDIT LOGS
 */
async function logAdminAction(adminId, action, serviceId, additionalData) {
    try {
        await db.collection('admin_logs').add({
            adminId,
            action,
            serviceId,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            ...additionalData
        });
        console.log(`[ADMIN_AUDIT] Logged action: ${action} by ${adminId} on service ${serviceId}`);
    }
    catch (error) {
        console.error('[ADMIN_AUDIT] Failed to log action:', error);
        // Don't throw - audit logging failure shouldn't block the main action
    }
}
/**
 * Approve Technician Service
 * Changes status from pending to approved
 */
exports.admin_approveService = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (request, context) => {
    // Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    // CRITICAL FIX: Verify admin role from Firestore
    await verifyAdmin(context.auth.uid);
    const { serviceId } = request;
    if (!serviceId) {
        throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
    }
    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();
    if (!serviceDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Service not found");
    }
    await serviceRef.update({
        status: 'approved',
        isActive: true, // CRITICAL: Activate service on approval
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
        approvedBy: context.auth.uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    // STEP 5: Log admin action
    await logAdminAction(context.auth.uid, 'approve_service', serviceId, {
        previousStatus: serviceDoc.data()?.status,
        newStatus: 'approved'
    });
    console.log(`[ADMIN] Service ${serviceId} approved by ${context.auth.uid}`);
    return {
        success: true,
        serviceId,
        status: 'approved',
        message: 'Service approved successfully'
    };
}));
/**
 * Reject Technician Service
 * Changes status from pending to rejected
 */
exports.admin_rejectService = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (request, context) => {
    // Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    // CRITICAL FIX: Verify admin role from Firestore
    await verifyAdmin(context.auth.uid);
    const { serviceId, reason } = request;
    if (!serviceId) {
        throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
    }
    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();
    if (!serviceDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Service not found");
    }
    await serviceRef.update({
        status: 'rejected',
        isActive: false, // CRITICAL: Keep inactive on rejection
        rejectionReason: (0, security_1.sanitize)(reason) || 'Not specified',
        rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
        rejectedBy: context.auth.uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    // STEP 5: Log admin action
    await logAdminAction(context.auth.uid, 'reject_service', serviceId, {
        previousStatus: serviceDoc.data()?.status,
        newStatus: 'rejected',
        reason: (0, security_1.sanitize)(reason) || 'Not specified'
    });
    console.log(`[ADMIN] Service ${serviceId} rejected by ${context.auth.uid}`);
    return {
        success: true,
        serviceId,
        status: 'rejected',
        message: 'Service rejected'
    };
}));
/**
 * Disable Technician Service
 * Changes status to disabled (SOFT DELETE - never removes document)
 */
exports.admin_disableService = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (request, context) => {
    // Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    // CRITICAL FIX: Verify admin role from Firestore
    await verifyAdmin(context.auth.uid);
    const { serviceId } = request;
    if (!serviceId) {
        throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
    }
    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();
    if (!serviceDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Service not found");
    }
    // SOFT DELETE: Set status to disabled, never delete document
    await serviceRef.update({
        status: 'disabled',
        disabledAt: admin.firestore.FieldValue.serverTimestamp(),
        disabledBy: context.auth.uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    // STEP 5: Log admin action
    await logAdminAction(context.auth.uid, 'disable_service', serviceId, {
        previousStatus: serviceDoc.data()?.status,
        newStatus: 'disabled'
    });
    console.log(`[ADMIN] Service ${serviceId} disabled by ${context.auth.uid}`);
    return {
        success: true,
        serviceId,
        status: 'disabled',
        message: 'Service disabled'
    };
}));
//# sourceMappingURL=service_management.js.map