"use strict";
/**
 * NOTIFICATION RELIABILITY - Enhanced Error Handling & Retry
 *
 * Ensures critical notifications are not silently lost
 * Logs failures and implements retry mechanism
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
exports.sendNotificationReliably = sendNotificationReliably;
exports.retryFailedNotifications = retryFailedNotifications;
exports.cleanupOldNotificationLogs = cleanupOldNotificationLogs;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * Send notification with reliability tracking
 * Logs all attempts and failures for monitoring
 */
async function sendNotificationReliably(params) {
    const { userId, userType, title, body, data = {}, token, priority = 'high', critical = false, } = params;
    const logRef = db.collection('notification_logs').doc();
    const now = admin.firestore.Timestamp.now();
    try {
        // Get FCM token if not provided
        let fcmToken = token;
        if (!fcmToken) {
            const userDoc = await db.collection(userType === 'customer' ? 'customers' : userType === 'admin' ? 'admins' : 'technicians').doc(userId).get();
            fcmToken = userDoc.data()?.fcmToken;
            if (!fcmToken) {
                // Try to get from fcmTokens subcollection
                const tokensSnapshot = await db
                    .collection(userType === 'customer' ? 'customers' : userType === 'admin' ? 'admins' : 'technicians')
                    .doc(userId)
                    .collection('fcmTokens')
                    .where('isActive', '==', true)
                    .limit(1)
                    .get();
                if (!tokensSnapshot.empty) {
                    fcmToken = tokensSnapshot.docs[0].data().token;
                }
            }
        }
        if (!fcmToken) {
            // Log failure - no token available
            await logRef.set({
                userId,
                userType,
                title,
                body,
                data,
                status: 'failed',
                error: 'No FCM token available',
                retryCount: 0,
                createdAt: now,
            });
            console.warn(`[NOTIFICATION] No FCM token for ${userType}:${userId}`);
            return { success: false, error: 'No FCM token available' };
        }
        // Prepare message
        const message = {
            notification: {
                title,
                body,
            },
            token: fcmToken,
            data,
            android: {
                priority: priority === 'high' ? 'high' : 'normal',
                notification: {
                    channelId: 'high_importance_channel',
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        };
        // Send notification
        const messageId = await admin.messaging().send(message);
        // Log success
        await logRef.set({
            userId,
            userType,
            title,
            body,
            data,
            token: fcmToken,
            status: 'sent',
            retryCount: 0,
            createdAt: now,
            sentAt: now,
        });
        console.log(`[NOTIFICATION] ✅ Sent to ${userType}:${userId} - MessageID: ${messageId}`);
        return { success: true, messageId };
    }
    catch (error) {
        const errorMessage = error.message || 'Unknown error';
        const errorCode = error.code || 'unknown';
        console.error(`[NOTIFICATION] ❌ Failed to send to ${userType}:${userId}:`, errorCode, errorMessage);
        // Log failure
        await logRef.set({
            userId,
            userType,
            title,
            body,
            data,
            token,
            status: critical ? 'retry_pending' : 'failed',
            error: `${errorCode}: ${errorMessage}`,
            retryCount: 0,
            createdAt: now,
        });
        // Handle specific error codes
        if (errorCode === 'messaging/registration-token-not-registered' ||
            errorCode === 'messaging/invalid-registration-token') {
            // Token is invalid - remove it
            console.log(`[NOTIFICATION] Removing invalid token for ${userType}:${userId}`);
            try {
                await db
                    .collection(userType === 'customer' ? 'customers' : userType === 'admin' ? 'admins' : 'technicians')
                    .doc(userId)
                    .update({
                    fcmToken: admin.firestore.FieldValue.delete(),
                });
            }
            catch (cleanupError) {
                console.error('[NOTIFICATION] Failed to cleanup invalid token:', cleanupError);
            }
        }
        return { success: false, error: errorMessage };
    }
}
/**
 * Retry failed critical notifications
 * Can be called manually or scheduled
 */
async function retryFailedNotifications(maxRetries = 3) {
    console.log('[NOTIFICATION_RETRY] Starting retry of failed notifications...');
    try {
        // Get failed notifications that need retry
        const failedNotifications = await db
            .collection('notification_logs')
            .where('status', '==', 'retry_pending')
            .where('retryCount', '<', maxRetries)
            .limit(100)
            .get();
        if (failedNotifications.empty) {
            console.log('[NOTIFICATION_RETRY] No notifications to retry');
            return { retriedCount: 0, successCount: 0, failedCount: 0 };
        }
        console.log(`[NOTIFICATION_RETRY] Found ${failedNotifications.size} notifications to retry`);
        let successCount = 0;
        let failedCount = 0;
        for (const doc of failedNotifications.docs) {
            const notification = doc.data();
            // Retry sending
            const result = await sendNotificationReliably({
                userId: notification.userId,
                userType: notification.userType,
                title: notification.title,
                body: notification.body,
                data: notification.data,
                token: notification.token,
                critical: true,
            });
            if (result.success) {
                successCount++;
                // Update log to mark as sent
                await doc.ref.update({
                    status: 'sent',
                    sentAt: admin.firestore.Timestamp.now(),
                    lastRetryAt: admin.firestore.Timestamp.now(),
                    retryCount: notification.retryCount + 1,
                });
            }
            else {
                failedCount++;
                // Update retry count
                await doc.ref.update({
                    retryCount: notification.retryCount + 1,
                    lastRetryAt: admin.firestore.Timestamp.now(),
                    status: notification.retryCount + 1 >= maxRetries ? 'failed' : 'retry_pending',
                });
            }
        }
        console.log(`[NOTIFICATION_RETRY] ✅ Completed: ${successCount} succeeded, ${failedCount} failed`);
        return {
            retriedCount: failedNotifications.size,
            successCount,
            failedCount,
        };
    }
    catch (error) {
        console.error('[NOTIFICATION_RETRY] ❌ Error during retry:', error.message);
        throw error;
    }
}
/**
 * Cleanup old notification logs (older than 30 days)
 */
async function cleanupOldNotificationLogs() {
    console.log('[NOTIFICATION_CLEANUP] Starting cleanup...');
    try {
        const cutoffTime = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000));
        const oldLogs = await db
            .collection('notification_logs')
            .where('createdAt', '<', cutoffTime)
            .limit(500)
            .get();
        if (oldLogs.empty) {
            console.log('[NOTIFICATION_CLEANUP] No old logs found');
            return 0;
        }
        const batch = db.batch();
        oldLogs.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        console.log(`[NOTIFICATION_CLEANUP] ✅ Deleted ${oldLogs.size} old logs`);
        return oldLogs.size;
    }
    catch (error) {
        console.error('[NOTIFICATION_CLEANUP] ❌ Error:', error.message);
        throw error;
    }
}
//# sourceMappingURL=notification_reliability.js.map