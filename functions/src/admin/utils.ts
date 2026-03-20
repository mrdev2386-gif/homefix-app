import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Admin utility functions
 */

/**
 * Assert user is admin
 */
export async function assertAdmin(context: functions.https.CallableContext): Promise<string> {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
        );
    }
    
    const uid = context.auth.uid;
    const db = admin.firestore();
    
    const adminDoc = await db.collection('admins').doc(uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only admins can perform this action'
        );
    }
    
    return uid;
}

/**
 * Log admin action for audit trail
 */
export async function logAdminAction(
    adminUid: string,
    action: string,
    targetId: string,
    metadata?: any
): Promise<void> {
    try {
        const db = admin.firestore();
        await db.collection('admin_logs').add({
            adminUid,
            action,
            targetId,
            metadata: metadata || {},
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (error) {
        console.error('Failed to log admin action:', error);
        // Don't throw - logging failure shouldn't break the operation
    }
}
