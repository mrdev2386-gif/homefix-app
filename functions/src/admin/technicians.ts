
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin, logAdminAction } from './utils';

export const approveTechnicianApplication = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { appId, approve, reason } = data;

        if (!appId) throw new functions.https.HttpsError('invalid-argument', 'Missing appId');

        const appRef = db.collection('technician_applications').doc(appId);
        const appDoc = await appRef.get();
        if (!appDoc.exists) throw new functions.https.HttpsError('not-found', 'Application not found');
        const appData = appDoc.data()!;

        if (approve) {
            await db.collection('technicians').doc(appId).set({
                uid: appId,
                name: appData.name || '',
                phone: appData.phone || '',
                email: appData.email || '',
                skills: appData.services || [],
                status: 'approved',
                isVerified: true,
                isAvailable: true,
                rating: 5.0,
                jobsCompleted: 0,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            await appRef.update({
                status: 'approved',
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        } else {
            await appRef.update({
                status: 'rejected',
                rejectionReason: reason || 'Not specified',
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        await logAdminAction(context.auth!.uid, approve ? 'tech_app_approve' : 'tech_app_reject', appId, { reason });
        return { success: true };
    } catch (error: any) {
        console.error('[Technician] Error in approveTechnicianApplication:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to process application');
    }
});

export const approveTechnician = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { techId, approve, reason } = data;

        if (!techId) throw new functions.https.HttpsError('invalid-argument', 'Missing techId');

        const techRef = db.collection('technicians').doc(techId);
        const techDoc = await techRef.get();
        if (!techDoc.exists) throw new functions.https.HttpsError('not-found', 'Technician not found');

        await techRef.update({
            status: approve ? 'approved' : 'suspended',
            isVerified: approve,
            rejectionReason: !approve ? reason : admin.firestore.FieldValue.delete(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await logAdminAction(context.auth!.uid, approve ? 'tech_approve' : 'tech_suspend', techId, { reason });
        return { success: true };
    } catch (error: any) {
        console.error('[Technician] Error in approveTechnician:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to update technician status');
    }
});

export const toggleTechAvailability = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { techId, isAvailable } = data;

        if (!techId) throw new functions.https.HttpsError('invalid-argument', 'Missing techId');

        const techRef = db.collection('technicians').doc(techId);
        const techDoc = await techRef.get();
        if (!techDoc.exists) throw new functions.https.HttpsError('not-found', 'Technician not found');

        await techRef.update({
            isAvailable: Boolean(isAvailable),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await logAdminAction(context.auth!.uid, 'tech_toggle_availability', techId, { isAvailable });
        return { success: true };
    } catch (error: any) {
        console.error('[Technician] Error in toggleTechAvailability:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to toggle availability');
    }
});

export const updateTechServices = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { techId, skills } = data;

        if (!techId || !skills) throw new functions.https.HttpsError('invalid-argument', 'Missing techId or skills');

        const techRef = db.collection('technicians').doc(techId);
        const techDoc = await techRef.get();
        if (!techDoc.exists) throw new functions.https.HttpsError('not-found', 'Technician not found');

        await techRef.update({
            skills,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await logAdminAction(context.auth!.uid, 'tech_update_services', techId, { skills });
        return { success: true };
    } catch (error: any) {
        console.error('[Technician] Error in updateTechServices:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to update services');
    }
});
