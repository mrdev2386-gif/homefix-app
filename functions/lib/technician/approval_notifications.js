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
exports.onTechnicianApproved = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const notifications_1 = require("../shared/notifications");
const db = admin.firestore();
/**
 * Sends approval notification to technician when admin approves their profile
 * Triggered when technician status changes to "approved" or "active"
 *
 * BACKWARD COMPATIBLE: Handles both status values:
 * - status: 'approved' (from Cloud Function approveTechnician)
 * - status: 'active' (from Admin Panel direct Firestore write)
 * - profileApproved: true (fallback for edge cases)
 */
exports.onTechnicianApproved = functions.firestore
    .document('technicians/{techId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after)
        return;
    const techId = context.params.techId;
    // STEP 1: Check if status changed to approved (handles BOTH 'approved' and 'active')
    const wasApproved = before.status === 'approved' ||
        before.status === 'active' ||
        before.profileApproved === true;
    const isNowApproved = after.status === 'approved' ||
        after.status === 'active' ||
        after.profileApproved === true;
    // STEP 2: Only send notification on transition from not-approved to approved
    if (!wasApproved && isNowApproved) {
        console.log(`[TECH_APPROVAL_NOTIFICATION] Technician ${techId} approved. Status: ${after.status}, profileApproved: ${after.profileApproved}`);
        try {
            const techName = after.fullName || 'Technician';
            // STEP 3: Send FCM notification
            await (0, notifications_1.sendPushNotification)(techId, 'technicians', {
                title: '✅ Profile Approved!',
                body: `Congratulations ${techName}! Your profile has been approved. You can now create and list services.`,
                data: {
                    type: 'technician_approved',
                    screen: 'dashboard',
                },
            });
            console.log(`[TECH_APPROVAL_NOTIFICATION] ✅ Notification sent to ${techId}`);
        }
        catch (error) {
            console.error(`[TECH_APPROVAL_NOTIFICATION] ❌ Failed to send notification to ${techId}:`, error);
            // Don't fail the function - notification is best-effort
        }
    }
});
//# sourceMappingURL=approval_notifications.js.map