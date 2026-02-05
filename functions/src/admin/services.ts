
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin, logAdminAction } from './utils';

export const manageService = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { action, serviceId, payload } = data; // action: 'create' | 'update' | 'delete'

    if (action === 'create') {
        const docRef = db.collection('services').doc(); // Auto-ID or slug? Let's use auto for now
        await docRef.set({
            ...payload,
            isActive: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        await logAdminAction(context.auth!.uid, 'service_create', docRef.id, payload);
        return { id: docRef.id };
    }

    if (action === 'update') {
        if (!serviceId) throw new functions.https.HttpsError('invalid-argument', 'Service ID required');
        await db.collection('services').doc(serviceId).update({
            ...payload,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        await logAdminAction(context.auth!.uid, 'service_update', serviceId, payload);
    }

    if (action === 'delete') {
        if (!serviceId) throw new functions.https.HttpsError('invalid-argument', 'Service ID required');
        await db.collection('services').doc(serviceId).update({
            isActive: false,
            deletedAt: admin.firestore.FieldValue.serverTimestamp()
        }); // Soft delete
        await logAdminAction(context.auth!.uid, 'service_delete', serviceId);
    }

    return { success: true };
});
