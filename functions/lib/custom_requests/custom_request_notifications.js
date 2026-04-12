"use strict";
/**
 * ================================================
 * CUSTOM REQUEST NOTIFICATION TRIGGERS
 * ================================================
 *
 * Sends push notifications when custom request status changes:
 *
 * adminApproved
 *   → Customer: "Your request has been approved"
 *
 * technicianAssigned
 *   → Technician: "New custom job assigned to you"
 *
 * technicianAccepted
 *   → Customer: "Technician has accepted your request"
 *
 * completed
 *   → Customer: "Your custom request is completed - please rate"
 *   → Technician: "Custom job completed"
 *
 * cancelled
 *   → Customer (with reason)
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
exports.onCustomRequestStatusChange = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const notification_helper_1 = require("../shared/notification_helper");
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
/**
 * CUSTOM REQUEST STATUS CHANGE TRIGGER
 * Detects status updates and sends appropriate notifications
 */
exports.onCustomRequestStatusChange = functions.firestore
    .document('custom_requests/{requestId}')
    .onUpdate(async (change, context) => {
    const requestId = context.params.requestId;
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after)
        return;
    const previousStatus = before.status;
    const newStatus = after.status;
    const customerId = after.customerId;
    const technicianId = after.technicianId;
    // Only trigger if status actually changed
    if (previousStatus === newStatus)
        return;
    try {
        console.log(`[CUSTOM REQUEST NOTIFICATION] Status change: ${previousStatus} → ${newStatus}`);
        // ================================================
        // STATUS: adminApproved
        // ================================================
        // Set by: Admin (when admin approves the custom request)
        if (newStatus === 'admin_approved' || newStatus === 'adminApproved') {
            await handleAdminApproved(customerId, requestId, after);
        }
        // ================================================
        // STATUS: technicianAssigned
        // ================================================
        // Set by: Admin (when admin assigns technician)
        if (newStatus === 'technician_assigned' || newStatus === 'technicianAssigned') {
            await handleTechnicianAssigned(customerId, technicianId, requestId, after);
        }
        // ================================================
        // STATUS: technicianAccepted
        // ================================================
        // Set by: Technician (when they accept the custom job)
        if (newStatus === 'technician_accepted' || newStatus === 'technicianAccepted') {
            await handleTechnicianAccepted(customerId, technicianId, requestId, after);
        }
        // ================================================
        // STATUS: completed
        // ================================================
        // Set by: Technician (when service is complete)
        if (newStatus === 'completed') {
            await handleCompleted(customerId, technicianId, requestId, after);
        }
        // ================================================
        // STATUS: cancelled
        // ================================================
        // Set by: Customer or Admin
        if (newStatus === 'cancelled' && previousStatus !== 'cancelled') {
            await handleCancelled(customerId, requestId, after);
        }
        console.log(`[CUSTOM REQUEST NOTIFICATION] Notifications sent for request: ${requestId}`);
    }
    catch (error) {
        console.error(`[CUSTOM REQUEST NOTIFICATION] Error for request ${requestId}:`, error);
        // Don't fail the function - notifications are best-effort
    }
});
// ================================================
// HANDLER: Admin Approved
// ================================================
async function handleAdminApproved(customerId, requestId, request) {
    const serviceName = request.serviceName || 'Custom Service';
    // Notify customer
    await (0, notification_helper_1.sendUserNotification)({
        userId: customerId,
        userType: 'customer',
        title: '✅ Request Approved!',
        body: `Your ${serviceName} request has been approved. A technician will be assigned shortly.`,
        type: 'custom_request_accepted',
        data: {
            requestId,
            screen: 'custom_request_details',
        },
        priority: 'high',
    }).catch(err => console.error('[CUSTOM REQUEST] Customer notification failed:', err));
}
// ================================================
// HANDLER: Technician Assigned
// ================================================
async function handleTechnicianAssigned(customerId, technicianId, requestId, request) {
    const serviceName = request.serviceName || 'Custom Service';
    const technicianName = request.technicianName || 'A technician';
    // Notify customer (optional)
    await (0, notification_helper_1.sendUserNotification)({
        userId: customerId,
        userType: 'customer',
        title: '👷 Technician Assigned',
        body: `${technicianName} has been assigned to your ${serviceName} request.`,
        type: 'custom_request_accepted',
        data: {
            requestId,
            screen: 'custom_request_details',
        },
        priority: 'normal',
    }).catch(err => console.error('[CUSTOM REQUEST] Customer notification failed:', err));
    // Notify technician
    if (technicianId) {
        const customerName = request.customerName || 'A customer';
        await (0, notification_helper_1.sendUserNotification)({
            userId: technicianId,
            userType: 'technician',
            title: '🔔 New Custom Job Assigned!',
            body: `${serviceName} request from ${customerName}. Review and accept/reject.`,
            type: 'new_request_nearby',
            data: {
                requestId,
                screen: 'request_details',
            },
            priority: 'high',
        }).catch(err => console.error('[CUSTOM REQUEST] Technician notification failed:', err));
    }
}
// ================================================
// HANDLER: Technician Accepted
// ================================================
async function handleTechnicianAccepted(customerId, technicianId, requestId, request) {
    const technicianName = request.technicianName || 'Your technician';
    const serviceName = request.serviceName || 'Custom Service';
    // Notify customer
    await (0, notification_helper_1.sendUserNotification)({
        userId: customerId,
        userType: 'customer',
        title: '🎉 Technician Accepted!',
        body: `${technicianName} has accepted your ${serviceName} request.`,
        type: 'custom_request_accepted',
        data: {
            requestId,
            screen: 'custom_request_details',
        },
        priority: 'high',
    }).catch(err => console.error('[CUSTOM REQUEST] Customer notification failed:', err));
}
// ================================================
// HANDLER: Completed
// ================================================
async function handleCompleted(customerId, technicianId, requestId, request) {
    const technicianName = request.technicianName || 'Your technician';
    const serviceName = request.serviceName || 'Custom Service';
    // Notify customer to rate
    await (0, notification_helper_1.sendUserNotification)({
        userId: customerId,
        userType: 'customer',
        title: '✅ Service Completed!',
        body: `${technicianName} has completed your ${serviceName} request. Please rate your experience.`,
        type: 'job_completed',
        data: {
            requestId,
            screen: 'custom_request_details',
        },
        priority: 'normal',
    }).catch(err => console.error('[CUSTOM REQUEST] Customer notification failed:', err));
    // Notify technician
    if (technicianId) {
        await (0, notification_helper_1.sendUserNotification)({
            userId: technicianId,
            userType: 'technician',
            title: '✅ Custom Job Completed',
            body: `You have successfully completed the ${serviceName} request.`,
            type: 'job_completed',
            data: {
                requestId,
                screen: 'request_details',
            },
            priority: 'normal',
        }).catch(err => console.error('[CUSTOM REQUEST] Technician notification failed:', err));
    }
}
// ================================================
// HANDLER: Cancelled
// ================================================
async function handleCancelled(customerId, requestId, request) {
    const reason = request.cancellationReason || 'Request was cancelled';
    // Notify customer
    await (0, notification_helper_1.sendUserNotification)({
        userId: customerId,
        userType: 'customer',
        title: '❌ Request Cancelled',
        body: reason,
        type: 'booking_cancelled',
        data: {
            requestId,
            screen: 'custom_request_details',
        },
        priority: 'high',
    }).catch(err => console.error('[CUSTOM REQUEST] Notification failed:', err));
}
//# sourceMappingURL=custom_request_notifications.js.map