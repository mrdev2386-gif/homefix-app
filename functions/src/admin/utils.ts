
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';

export async function assertAdmin(context: functions.https.CallableContext) {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    const { uid } = context.auth;
    console.log(`[Admin Auth] Verifying user: ${uid}`);

    try {
        if (!context.auth?.token?.admin) {
            console.error(`[Admin Auth] Access DENIED for user ${uid}. Admin claim missing.`);
            throw new functions.https.HttpsError('permission-denied', 'Admin access required');
        }

        console.log(`[Admin Auth] Access GRANTED for user ${uid} via claims`);

    } catch (error) {
        console.error(`[Admin Auth] Error verifying user ${uid}:`, error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', 'Failed to verify admin status');
    }
}

export async function logAdminAction(uid: string, action: string, targetId: string, metadata: any = {}) {
    await db.collection('admin_logs').add({
        adminUid: uid,
        action,
        targetId,
        metadata,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
}
