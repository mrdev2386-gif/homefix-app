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
exports.onCustomRequestCreatedAlertTechnicians = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const notifications_1 = require("../shared/notifications");
const db = admin.firestore();
/**
 * Triggered when a new custom service request is created.
 * Sends alerts to all active and approved technicians in the customer's district
 * who are interested in the request's category.
 */
exports.onCustomRequestCreatedAlertTechnicians = functions.firestore
    .document('service_requests/{requestId}')
    .onCreate(async (snapshot, context) => {
    const requestData = snapshot.data();
    if (!requestData)
        return;
    const districtNormalized = requestData.districtNormalized || (requestData.district ? requestData.district.toString().trim().toLowerCase() : '');
    const categoryId = requestData.categoryId;
    const categoryName = requestData.categoryName || '';
    const description = requestData.description || '';
    if (!districtNormalized || !categoryId) {
        console.log(`[TECH_ALERT] Missing district (${districtNormalized}) or categoryId (${categoryId}) for request ${context.params.requestId}`);
        return;
    }
    console.log(`[TECH_ALERT] Processing alerts for request ${context.params.requestId} in district: ${districtNormalized}, category: ${categoryId}`);
    // 1. Find eligible technicians
    // - Active status
    // - Approved
    // - Same district (using normalized field)
    // - Handles the category
    const techniciansSnapshot = await db.collection('technicians')
        .where('districtNormalized', '==', districtNormalized)
        .where('status', '==', 'active')
        .where('isApproved', '==', true)
        .where('serviceCategories', 'array-contains', categoryId)
        .get();
    if (techniciansSnapshot.empty) {
        console.log(`[TECH_ALERT] No eligible technicians found in ${districtNormalized} for category ${categoryId}`);
        // Optional: alert admins that no tech is available
        return;
    }
    console.log(`[TECH_ALERT] Found ${techniciansSnapshot.size} eligible technicians. Sending notifications...`);
    const notificationPromises = techniciansSnapshot.docs.map(async (techDoc) => {
        const techId = techDoc.id;
        const techData = techDoc.data();
        // Create notification document in technician's notifications subcollection
        const notificationId = db.collection('technicians').doc(techId).collection('notifications').doc().id;
        const notificationRef = db.collection('technicians').doc(techId).collection('notifications').doc(notificationId);
        const notificationDoc = {
            id: notificationId,
            title: 'New Service Request Nearby!',
            body: `A new ${categoryName || 'service'} request is available in ${districtNormalized.toUpperCase()}.`,
            type: 'custom_request_alert',
            requestId: context.params.requestId,
            categoryId,
            description: description || '',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            priority: 'high'
        };
        await notificationRef.set(notificationDoc);
        // Send FCM push notification
        await (0, notifications_1.sendPushNotification)(techId, 'technicians', {
            title: notificationDoc.title,
            body: notificationDoc.body,
            data: {
                type: 'custom_request_alert',
                requestId: context.params.requestId,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
        });
    });
    await Promise.all(notificationPromises);
    console.log(`[TECH_ALERT] Alerts sent successfully for request ${context.params.requestId}`);
});
//# sourceMappingURL=alerts.js.map