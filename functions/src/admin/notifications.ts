
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin, logAdminAction } from './utils';

import * as notify from '../shared/notification_helper';

export const sendPushNotification = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { target, title, body, imageUrl } = data; // target: 'all' | 'customers' | 'technicians' | 'uid'

    if (target.startsWith('user_')) {
        const uid = target.replace('user_', '');
        // Determine type based on some logic or default to general
        await notify.sendUserNotification({
            userId: uid,
            userType: 'technician', // Admin should specify this, but default to technician for now or try to detect
            title,
            body,
            type: 'admin_broadcast',
            imageUrl,
            priority: 'high'
        });
    } else {
        // Topic broadcast - for now we don't create 10k Firestore records for topics
        // unless we use a "global_notifications" collection the app checks.
        await admin.messaging().send({
            topic: target,
            notification: { title, body },
            data: { type: 'admin_broadcast' }
        });
    }

    await logAdminAction(context.auth!.uid, 'send_notification', target, { title, body });
    return { success: true };
});
