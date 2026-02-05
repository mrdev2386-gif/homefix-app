
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin, logAdminAction } from './utils';

export const sendPushNotification = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { target, title, body } = data; // target: 'all' | 'customers' | 'technicians' | 'uid'

    const message: admin.messaging.Message = {
        notification: { title, body },
        topic: target // if target is uid, handle differently
    };

    // In prod, better to separate UIDs vs Topics.
    // Assuming topics are subscribed by apps.

    if (target.startsWith('user_')) {
        // Send to specific token if we had it from UID, for now assume topic unless we lookup token
        // Implementing topic send for bulk
        await admin.messaging().sendToTopic(target, { notification: { title, body } });
    } else {
        await admin.messaging().sendToCondition(`'${target}' in topics`, { notification: { title, body } });
    }

    await logAdminAction(context.auth!.uid, 'send_notification', target, { title, body });
    return { success: true };
});
