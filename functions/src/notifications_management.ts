import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { secureCallable } from './shared/security';

const db = admin.firestore();

/**
 * Marks a specific notification as read
 */
export const markNotificationRead = functions.https.onCall(
    secureCallable(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not logged in');

    const { notificationId } = data;
    if (!notificationId) throw new functions.https.HttpsError('invalid-argument', 'Notification ID is required');

    const notifRef = db.collection('notifications').doc(notificationId);
    const notifDoc = await notifRef.get();

    if (!notifDoc.exists) throw new functions.https.HttpsError('not-found', 'Notification not found');
    if (notifDoc.data()?.userId !== uid) throw new functions.https.HttpsError('permission-denied', 'Unauthorized access');

    await notifRef.update({ isRead: true, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    return { success: true };
  })
);

/**
 * Marks all notifications for the current user as read
 */
export const markAllNotificationsRead = functions.https.onCall(
    secureCallable(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not logged in');

    const snapshot = await db.collection('notifications')
        .where('userId', '==', uid)
        .where('isRead', '==', false)
        .get();

    const batch = db.batch();
    snapshot.docs.forEach(doc => {
        batch.update(doc.ref, { isRead: true, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    });

    if (!snapshot.empty) await batch.commit();
    return { success: true, count: snapshot.size };
  })
);

/**
 * Deletes a specific notification
 */
export const deleteNotificationCallable = functions.https.onCall(
    secureCallable(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not logged in');

    const { notificationId } = data;
    if (!notificationId) throw new functions.https.HttpsError('invalid-argument', 'Notification ID is required');

    const notifRef = db.collection('notifications').doc(notificationId);
    const notifDoc = await notifRef.get();

    if (!notifDoc.exists) return { success: true }; // Already deleted
    if (notifDoc.data()?.userId !== uid) throw new functions.https.HttpsError('permission-denied', 'Unauthorized access');

    await notifRef.delete();
    return { success: true };
  })
);

/**
 * Deletes all notifications for the current user
 */
export const deleteAllNotificationsCallable = functions.https.onCall(
    secureCallable(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not logged in');

    const snapshot = await db.collection('notifications')
        .where('userId', '==', uid)
        .get();

    const batch = db.batch();
    snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
    });

    if (!snapshot.empty) await batch.commit();
    return { success: true, count: snapshot.size };
  })
);
