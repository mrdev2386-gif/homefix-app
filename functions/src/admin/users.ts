
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin, logAdminAction } from './utils';

export const manageUser = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { userId, action, type } = data; // action: 'block' | 'unblock' | 'make_test'

        // STRICT VALIDATION: type is REQUIRED
        if (!userId || !action) throw new functions.https.HttpsError('invalid-argument', 'Missing userId or action');
        if (!type || !['customer', 'technician'].includes(type)) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing or invalid type. Must be "customer" or "technician"');
        }

        // CRITICAL SAFEGUARD: Prevent admin accounts from being disabled
        // Check if the target user is an admin
        const userRoleDoc = await db.collection('users').doc(userId).get();
        if (userRoleDoc.exists && userRoleDoc.data()?.role === 'admin') {
            console.error(`[User] BLOCKED: Attempt to ${action} admin account ${userId} by ${context.auth!.uid}`);
            throw new functions.https.HttpsError(
                'permission-denied',
                'Cannot block/unblock admin accounts. Admin accounts are protected from modification.'
            );
        }

        const collection = type === 'technician' ? 'technicians' : 'customers';
        const ref = db.collection(collection).doc(userId);

        // check if user exists first to throw better error
        const doc = await ref.get();
        if (!doc.exists) throw new functions.https.HttpsError('not-found', 'User not found');

        const updates: any = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

        if (action === 'block') {
            updates.isBlocked = true;
            // FINAL FAIL-SAFE: Double-check before disabling at Auth level
            if (userRoleDoc.exists && userRoleDoc.data()?.role === 'admin') {
                throw new functions.https.HttpsError('permission-denied', 'Cannot disable admin account at Auth level');
            }
            await admin.auth().updateUser(userId, { disabled: true });
        } else if (action === 'unblock') {
            updates.isBlocked = false;
            await admin.auth().updateUser(userId, { disabled: false });
        } else if (action === 'make_test') {
            updates.isTestUser = true;
        } else {
            throw new functions.https.HttpsError('invalid-argument', `Invalid action: ${action}`);
        }

        await ref.update(updates);
        await logAdminAction(context.auth!.uid, `user_${action}`, userId, { type });

        return { success: true };
    } catch (error: any) {
        console.error('[User] Error in manageUser:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to manage user');
    }
});

export const deleteTestUser = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { userId, type } = data;

        const collection = type === 'technician' ? 'technicians' : 'customers';
        const doc = await db.collection(collection).doc(userId).get();

        if (!doc.exists) throw new functions.https.HttpsError('not-found', 'User not found');
        if (!doc.data()?.isTestUser) throw new functions.https.HttpsError('failed-precondition', 'Can only delete test users');

        await db.collection(collection).doc(userId).delete();
        try {
            await admin.auth().deleteUser(userId);
        } catch (e: any) {
            console.warn(`[User] Failed to delete auth user ${userId}:`, e);
            // Allow firestore deletion to proceed even if auth deletion fails (e.g. user not found)
        }

        await logAdminAction(context.auth!.uid, 'delete_test_user', userId, { type });
        return { success: true };
    } catch (error: any) {
        console.error('[User] Error in deleteTestUser:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to delete test user');
    }
});
