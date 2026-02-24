
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin, logAdminAction } from './utils';

export const adminApproveTechnician = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { techId, approve, reason } = data;

        if (!techId) throw new functions.https.HttpsError('invalid-argument', 'Missing techId');

        const appRef = db.collection('technician_applications').doc(techId);
        const appDoc = await appRef.get();
        if (!appDoc.exists) throw new functions.https.HttpsError('not-found', 'Application not found');
        const appData = appDoc.data()!;

        if (approve) {
            await db.collection('technicians').doc(techId).set({
                uid: techId,
                name: appData.fullName || '',
                email: appData.email || '',
                experienceYears: appData.experienceYears || 0,
                primaryCategoryId: appData.primaryCategoryId || '',
                serviceCategories: appData.categoryIds || [],
                services: appData.serviceIds || [],
                subServices: appData.subcategoryIds || [],
                district: appData.district || '',
                districtNormalized: appData.districtNormalized || (appData.district ? appData.district.toString().trim().toLowerCase() : ''),
                status: 'approved',
                isApproved: true,
                isActive: true,
                rating: 5.0,
                totalJobs: 0,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            await appRef.update({
                status: 'approved',
                isApproved: true,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        } else {
            await appRef.update({
                status: 'rejected',
                isApproved: false,
                rejectionReason: reason || 'Not specified',
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            await db.collection('technicians').doc(techId).update({
                status: 'rejected',
                isApproved: false,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        await logAdminAction(context.auth!.uid, approve ? 'tech_app_approve' : 'tech_app_reject', techId, { reason });
        return { success: true };
    } catch (error: any) {
        console.error('[Technician] Error in adminApproveTechnician:', error);
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

/**
 * Update technician services
 */
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

/**
 * Get paginated and filtered list of technicians
 */
export const getTechnicians = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { limit = 10, offset = 0, status, search, city } = data;

        let query: admin.firestore.Query = db.collection('technicians');

        if (status) {
            query = query.where('status', '==', status);
        }

        if (city) {
            query = query.where('city', '==', city);
        }

        const snapshot = await query.orderBy('createdAt', 'desc').get();
        let techs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        if (search) {
            const lowerSearch = search.toLowerCase();
            techs = techs.filter((t: any) =>
                t.name?.toLowerCase().includes(lowerSearch) ||
                t.email?.toLowerCase().includes(lowerSearch) ||
                t.phone?.includes(search) ||
                t.id.includes(search)
            );
        }

        const total = techs.length;
        const paginatedTechs = techs.slice(offset, offset + limit);

        return {
            techs: paginatedTechs,
            total,
            limit,
            offset
        };
    } catch (error: any) {
        console.error('[Admin Techs] Error in getTechnicians:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to fetch technicians');
    }
});

/**
 * Get full details of a technician
 */
export const getTechnicianById = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { techId } = data;
        if (!techId) throw new functions.https.HttpsError('invalid-argument', 'Missing techId');

        const techDoc = await db.collection('technicians').doc(techId).get();
        if (!techDoc.exists) throw new functions.https.HttpsError('not-found', 'Technician not found');

        const techData = techDoc.data()!;

        // Fetch wallet & earnings
        const walletDoc = await db.collection('wallets').doc(techId).get();
        const wallet = walletDoc.exists ? walletDoc.data() : { balance: 0, pendingBalance: 0 };

        // Fetch job history (last 5)
        const jobsSnap = await db.collection('bookings')
            .where('assignedTechnicianId', '==', techId)
            .orderBy('createdAt', 'desc')
            .limit(5)
            .get();
        const jobHistory = jobsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        // Fetch application documents if available
        const appDoc = await db.collection('technician_applications').doc(techId).get();
        const documents = appDoc.exists ? appDoc.data()?.documents : null;

        // Fetch ratings & reviews (last 5)
        const reviewsSnap = await db.collection('reviews')
            .where('technicianId', '==', techId)
            .orderBy('createdAt', 'desc')
            .limit(5)
            .get();
        const reviews = reviewsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        return {
            ...techData,
            wallet,
            jobHistory,
            documents,
            reviews
        };
    } catch (error: any) {
        console.error('[Admin Techs] Error in getTechnicianById:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to fetch technician details');
    }
});

/**
 * Update technician profile
 */
export const updateTechnician = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { techId, updates } = data;
        if (!techId || !updates) throw new functions.https.HttpsError('invalid-argument', 'Missing techId or updates');

        const techRef = db.collection('technicians').doc(techId);
        const techDoc = await techRef.get();
        if (!techDoc.exists) throw new functions.https.HttpsError('not-found', 'Technician not found');

        const allowedFields = ['name', 'phone', 'email', 'skills', 'city', 'status', 'isVerified', 'isAvailable'];
        const cleanUpdates: any = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

        for (const field of allowedFields) {
            if (updates[field] !== undefined) {
                cleanUpdates[field] = updates[field];
            }
        }

        await techRef.update(cleanUpdates);

        // If status changed to suspended, maybe block in Auth too?
        if (updates.status === 'suspended' || updates.status === 'blocked') {
            await admin.auth().updateUser(techId, { disabled: true });
            await db.collection('users').doc(techId).update({ isBlocked: true });
        } else if (updates.status === 'approved') {
            await admin.auth().updateUser(techId, { disabled: false });
            await db.collection('users').doc(techId).update({ isBlocked: false });
        }

        await logAdminAction(context.auth!.uid, 'update_technician', techId, { updates: cleanUpdates });
        return { success: true };
    } catch (error: any) {
        console.error('[Admin Techs] Error in updateTechnician:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to update technician');
    }
});
