import * as admin from 'firebase-admin';

export type UserType = 'customers' | 'technicians' | 'admins';

export interface NotificationPayload {
    title: string;
    body: string;
    data?: { [key: string]: string };
}

/**
 * Sends a push notification to all valid tokens of a user.
 */
export async function sendPushNotification(
    uid: string,
    userType: UserType,
    payload: NotificationPayload
) {
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
async function _sendToToken(
    token: string,
    payload: NotificationPayload,
    uid: string,
    userType: UserType,
    tokenRef?: admin.firestore.DocumentReference
) {
    const message: admin.messaging.Message = {
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
    } catch (error: any) {
        console.error(`FCM Error for user ${uid}, token ${token}:`, error.code);

        // Remove token if it's no longer valid
        if (error.code === 'messaging/registration-token-not-registered' ||
            error.code === 'messaging/invalid-registration-token') {
            if (tokenRef) {
                await tokenRef.delete();
            } else {
                // Legacy token cleanup
                await admin.firestore().collection(userType).doc(uid).update({
                    fcmToken: admin.firestore.FieldValue.delete()
                });
            }
        }
    }
}
