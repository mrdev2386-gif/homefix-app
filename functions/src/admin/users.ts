import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin, logAdminAction } from './utils';
import { secureCallable, sanitize } from '../shared/security';

/**
 * Get paginated and filtered list of users
 */
export const getUsers = functions.region('asia-south1').https.onCall(
    secureCallable(async (data: any, context: any) => {
    try {
        await assertAdmin(context);
        const { limit = 10, offset = 0, role, status, search } = data;

        let query: admin.firestore.Query = db.collection('users');

        if (role) {
            query = query.where('role', '==', role);
        }

        if (status === 'blocked') {
            query = query.where('isBlocked', '==', true);
        } else if (status === 'active') {
            query = query.where('isBlocked', '==', false);
        }

        // Firestore doesn't support partial search well without full-text search extensions.
        // We will do a basic startAt for name/email if possible, or filter in memory for small datasets.
        // For production-ready, we'd use Algolia. For now, we'll fetch and filter if search is provided.

        const snapshot = await query.orderBy('createdAt', 'desc').get();
        let users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        if (search) {
            const lowerSearch = sanitize(search).toLowerCase();
            users = users.filter((u: any) =>
                u.name?.toLowerCase().includes(lowerSearch) ||
                u.email?.toLowerCase().includes(lowerSearch) ||
                u.phone?.includes(lowerSearch) ||
                u.id.includes(lowerSearch)
            );
        }

        const total = users.length;
        const paginatedUsers = users.slice(offset, offset + limit);

        return {
            users: paginatedUsers,
            total,
            limit,
            offset
        };
    } catch (error: any) {
        console.error('[Admin Users] Error in getUsers:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to fetch users');
    }
  })
);

/**
 * Get full details of a single user
 */
export const getUserById = functions.region('asia-south1').https.onCall(
    secureCallable(async (data: any, context: any) => {
    try {
        await assertAdmin(context);
        const { userId } = data;
        if (!userId) throw new functions.https.HttpsError('invalid-argument', 'Missing userId');

        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'User not found');

        const userData = userDoc.data()!;

        // Fetch wallet balance
        const walletDoc = await db.collection('wallets').doc(userId).get();
        const walletBalance = walletDoc.exists ? (walletDoc.data()?.balance || 0) : 0;

        // Fetch booking history (last 5)
        const bookingsSnap = await db.collection('bookings')
            .where('customerId', '==', userId)
            .orderBy('createdAt', 'desc')
            .limit(5)
            .get();
        const bookingHistory = bookingsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        // Get Auth provider info
        const authUser = await admin.auth().getUser(userId);

        return {
            ...userData,
            walletBalance,
            bookingHistory,
            authProvider: authUser.providerData.map(p => p.providerId),
            lastLogin: authUser.metadata.lastSignInTime,
            disabled: authUser.disabled
        };
    } catch (error: any) {
        console.error('[Admin Users] Error in getUserById:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to fetch user details');
    }
  })
);

/**
 * Update user fields (Name, Role, Status)
 */
export const updateUser = functions.region('asia-south1').https.onCall(
    secureCallable(async (data: any, context: any) => {
    try {
        await assertAdmin(context);
        const { userId, updates } = data;
        if (!userId || !updates) throw new functions.https.HttpsError('invalid-argument', 'Missing userId or updates');

        const userRef = db.collection('users').doc(userId);
        const userDoc = await userRef.get();
        if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'User not found');

        // Security: Prevent self-role-demotion or blocking other admins via this general update
        if (userDoc.data()?.role === 'admin' && updates.role && updates.role !== 'admin') {
            throw new functions.https.HttpsError('permission-denied', 'Cannot change admin role via this method');
        }

        const allowedFields = ['name', 'role', 'phoneNumber', 'isVerified'];
        const cleanUpdates: any = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

        for (const field of allowedFields) {
            if (updates[field] !== undefined) {
                cleanUpdates[field] = (typeof updates[field] === 'string') ? sanitize(updates[field]) : updates[field];
            }
        }

        await userRef.update(cleanUpdates);
        await logAdminAction(context.auth!.uid, 'update_user', userId, { updates: cleanUpdates });

        return { success: true };
    } catch (error: any) {
        console.error('[Admin Users] Error in updateUser:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to update user');
    }
  })
);

/**
 * Block or Unblock a user
 */
export const blockUser = functions.region('asia-south1').https.onCall(
    secureCallable(async (data: any, context: any) => {
    try {
        await assertAdmin(context);
        const { userId, block } = data;
        if (!userId) throw new functions.https.HttpsError('invalid-argument', 'Missing userId');

        const userDoc = await db.collection('users').doc(userId).get();
        if (userDoc.exists && userDoc.data()?.role === 'admin') {
            throw new functions.https.HttpsError('permission-denied', 'Cannot block admin accounts');
        }

        await admin.auth().updateUser(userId, { disabled: block });
        await db.collection('users').doc(userId).update({
            isBlocked: block,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await logAdminAction(context.auth!.uid, block ? 'block_user' : 'unblock_user', userId);
        return { success: true };
    } catch (error: any) {
        console.error('[Admin Users] Error in blockUser:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to update user status');
    }
  })
);

// Keep legacy manageUser for backward compatibility if needed, but we'll use the new ones
export const manageUser = functions.region('asia-south1').https.onCall(
    secureCallable(async (data: any, context: any) => {
    try {
        await assertAdmin(context);
        
        // Support both parameter naming conventions
        const userId = data.userId || data.uid;
        const action = data.action;
        const type = data.type;
        const reason = data.reason;

        if (!userId || !action) {
            console.error('[manageUser] Missing parameters:', { userId, action, data });
            throw new functions.https.HttpsError('invalid-argument', 'Missing userId/uid or action');
        }

        console.log('[manageUser] Processing:', { userId, action, type, reason });

        const userRoleDoc = await db.collection('users').doc(userId).get();
        if (userRoleDoc.exists && userRoleDoc.data()?.role === 'admin') {
            throw new functions.https.HttpsError('permission-denied', 'Cannot block/unblock admin accounts');
        }

        const collection = type === 'technician' ? 'technicians' : 'users';
        const ref = db.collection(collection).doc(userId);

        const updates: any = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

        if (action === 'block' || action === 'unblock') {
            const isBlocked = action === 'block';
            updates.isBlocked = isBlocked;
            updates.suspended = isBlocked;
            if (isBlocked && reason) {
                updates.suspensionReason = sanitize(reason);
                updates.suspendedAt = admin.firestore.FieldValue.serverTimestamp();
                updates.suspendedBy = context.auth!.uid;
            }
            
            await admin.auth().updateUser(userId, { disabled: isBlocked });
            // Also update the 'users' collection regardless of type
            await db.collection('users').doc(userId).update({ isBlocked });
        } else if (action === 'make_test') {
            updates.isTestUser = true;
        }

        await ref.update(updates);
        await logAdminAction(context.auth!.uid, `user_${action}`, userId, { type, reason: sanitize(reason) });

        console.log('[manageUser] Success:', { userId, action, updates });
        return { success: true };
    } catch (error: any) {
        console.error('[manageUser] Error:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to manage user');
    }
  })
);
