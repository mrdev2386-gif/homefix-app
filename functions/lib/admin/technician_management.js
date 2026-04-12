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
exports.suspendTechnician = exports.approveTechnician = exports.approveKYC = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("../shared/security");
const notifications_1 = require("../shared/notifications");
const db = admin.firestore();
exports.approveKYC = functions.region('asia-south1').https.onCall(async (data, context) => {
    // DEPRECATED: This function is no longer used
    // Use approveTechnician() instead for all approval operations
    console.error('[DEPRECATED] approveKYC() called - use approveTechnician() instead');
    throw new functions.https.HttpsError('failed-precondition', 'DEPRECATED: Use approveTechnician() instead');
});
exports.approveTechnician = functions.region('asia-south1').https.onCall(async (data, context) => {
    try {
        console.log('[ADMIN APPROVAL] Raw incoming data:', JSON.stringify(data));
        console.log('[ADMIN APPROVAL] Context auth:', context.auth?.uid);
        await (0, security_1.assertAdmin)(context);
        // Handle both techId and technicianId parameter names
        const technicianId = data?.techId || data?.technicianId;
        const approve = data?.approve !== undefined ? data.approve : true;
        const reason = data?.reason;
        console.log('[ADMIN APPROVAL] Extracted values:', {
            technicianId,
            approve,
            reason,
            originalData: data
        });
        if (!technicianId || technicianId.trim() === '') {
            console.error('[ADMIN APPROVAL] Invalid technicianId:', technicianId);
            throw new functions.https.HttpsError('invalid-argument', 'Missing or empty technician ID (techId or technicianId)');
        }
        console.log('[ADMIN APPROVAL] Processing for technicianId:', technicianId, 'approve:', approve);
        const techRef = db.collection('technicians').doc(technicianId);
        const techDoc = await techRef.get();
        if (!techDoc.exists) {
            console.error('[ADMIN APPROVAL] Technician not found:', technicianId);
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        }
        if (approve) {
            // APPROVE: Set ALL required fields for technician activation
            await techRef.update({
                // Primary approval flags
                isApproved: true, // Required by technician app
                adminApproved: true, // Required by technician app
                isVerified: true, // Legacy compatibility
                // Status fields
                status: 'approved', // Main status
                kycStatus: 'approved', // KYC-specific status
                // Activation
                isActive: true, // Allow going online
                // Metadata
                approvedAt: admin.firestore.FieldValue.serverTimestamp(),
                approvedBy: context.auth.uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                // Clear rejection fields
                rejectionReason: admin.firestore.FieldValue.delete(),
                suspensionReason: admin.firestore.FieldValue.delete()
            });
            console.log('[ADMIN APPROVAL] ✅ Technician approved and activated:', technicianId);
            await (0, notifications_1.sendPushNotification)(technicianId, 'technicians', {
                title: 'Welcome to HomeFix!',
                body: 'Your profile has been approved. You can now go online and accept bookings.',
                data: { type: 'profile_status', status: 'approved' }
            });
        }
        else {
            // REJECT/SUSPEND: Clear approval flags
            await techRef.update({
                status: 'suspended',
                isApproved: false,
                adminApproved: false,
                isVerified: false,
                isActive: false,
                isOnline: false, // Force offline
                kycStatus: 'rejected',
                rejectionReason: reason || 'Not specified',
                rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
                rejectedBy: context.auth.uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log('[ADMIN APPROVAL] ❌ Technician suspended:', technicianId);
            await (0, notifications_1.sendPushNotification)(technicianId, 'technicians', {
                title: 'Profile Status Update',
                body: reason || 'Your profile has been suspended. Contact support for details.',
                data: { type: 'profile_status', status: 'suspended' }
            });
        }
        return { success: true };
    }
    catch (error) {
        console.error('[ADMIN APPROVAL ❌] Full error details:', {
            message: error?.message,
            stack: error?.stack,
            data: error?.data,
            code: error?.code
        });
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', error?.message || 'Approval failed');
    }
});
exports.suspendTechnician = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, security_1.assertAdmin)(context);
    const { technicianId, reason } = data;
    await db.collection('technicians').doc(technicianId).update({
        status: 'suspended',
        isActive: false,
        isOnline: false, // Force offline
        suspensionReason: reason,
        suspendedBy: context.auth.uid,
        suspendedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    // Kill any active sessions? Firebase Auth revocation is separate.
    return { success: true };
});
//# sourceMappingURL=technician_management.js.map