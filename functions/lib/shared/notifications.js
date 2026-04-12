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
exports.sendPushNotification = sendPushNotification;
const admin = __importStar(require("firebase-admin"));
/**
 * Sends a push notification to all valid tokens of a user.
 */
async function sendPushNotification(uid, userType, payload) {
    const db = admin.firestore();
    const tokensSnapshot = await db.collection(userType).doc(uid).collection('fcmTokens').get();
    if (tokensSnapshot.empty) {
        // Fallback for users with legacy token storage
        const userDoc = await db.collection(userType).doc(uid).get();
        const legacyToken = userDoc.data()?.fcmToken;
        if (legacyToken) {
            await _sendToToken(legacyToken, payload, uid, userType);
        }
        return;
    }
    const sendPromises = tokensSnapshot.docs.map(doc => {
        const token = doc.data().token;
        return _sendToToken(token, payload, uid, userType, doc.ref);
    });
    await Promise.all(sendPromises);
}
/**
 * Sends to a specific token and handles cleanup if invalid
 */
async function _sendToToken(token, payload, uid, userType, tokenRef) {
    const message = {
        notification: {
            title: payload.title,
            body: payload.body,
        },
        data: payload.data || {},
        token: token,
        android: {
            priority: 'high',
            notification: {
                channelId: userType === 'customers' ? 'high_importance_channel' : 'job_alerts_channel',
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            }
        },
        apns: {
            payload: {
                aps: {
                    badge: 1,
                    sound: 'default',
                }
            }
        }
    };
    try {
        await admin.messaging().send(message);
    }
    catch (error) {
        console.error(`FCM Error for user ${uid}, token ${token}:`, error.code);
        // Remove token if it's no longer valid
        if (error.code === 'messaging/registration-token-not-registered' ||
            error.code === 'messaging/invalid-registration-token') {
            if (tokenRef) {
                await tokenRef.delete();
            }
            else {
                // Legacy token cleanup
                await admin.firestore().collection(userType).doc(uid).update({
                    fcmToken: admin.firestore.FieldValue.delete()
                });
            }
        }
    }
}
//# sourceMappingURL=notifications.js.map