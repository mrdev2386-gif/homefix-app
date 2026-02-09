import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin } from './utils';
import { calculateDistance } from '../shared/geoutils';

export const admin_manageProfessionalVideos = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { action, videoId, videoData } = data; // action: 'add' | 'update' | 'delete' | 'reorder'

    if (action === 'add') {
        const snapshot = await db.collection('celebrating_professionals').get();
        if (snapshot.size >= 5) {
            throw new functions.https.HttpsError('failed-precondition', 'Maximum 5 videos allowed');
        }
        const docRef = db.collection('celebrating_professionals').doc();
        await docRef.set({
            ...videoData,
            isActive: true,
            order: snapshot.size,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, id: docRef.id };
    }

    if (action === 'update') {
        if (!videoId) throw new functions.https.HttpsError('invalid-argument', 'Missing videoId');
        await db.collection('celebrating_professionals').doc(videoId).update({
            ...videoData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }

    if (action === 'delete') {
        if (!videoId) throw new functions.https.HttpsError('invalid-argument', 'Missing videoId');
        await db.collection('celebrating_professionals').doc(videoId).delete();
        return { success: true };
    }

    if (action === 'reorder') {
        const { orders } = data; // orders: [{id: '...', order: 1}, ...]
        if (!Array.isArray(orders)) throw new functions.https.HttpsError('invalid-argument', 'Orders must be an array');

        const batch = db.batch();
        orders.forEach((item: any) => {
            batch.update(db.collection('celebrating_professionals').doc(item.id), {
                order: item.order,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        await batch.commit();
        return { success: true };
    }

    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
});

export const admin_manageCleaningEssentials = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { action, categoryId, categoryData } = data;

    if (action === 'add') {
        const docRef = db.collection('cleaning_categories').doc();
        await docRef.set({
            ...categoryData,
            isActive: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, id: docRef.id };
    }

    if (action === 'update') {
        if (!categoryId) throw new functions.https.HttpsError('invalid-argument', 'Missing categoryId');
        await db.collection('cleaning_categories').doc(categoryId).update({
            ...categoryData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }

    if (action === 'delete') {
        if (!categoryId) throw new functions.https.HttpsError('invalid-argument', 'Missing categoryId');
        await db.collection('cleaning_categories').doc(categoryId).delete();
        return { success: true };
    }

    if (action === 'reorder') {
        const { orders } = data;
        if (!Array.isArray(orders)) throw new functions.https.HttpsError('invalid-argument', 'Orders must be an array');

        const batch = db.batch();
        orders.forEach((item: any) => {
            batch.update(db.collection('cleaning_categories').doc(item.id), {
                order: item.order,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        await batch.commit();
        return { success: true };
    }

    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
});

export const findEligibleTechniciansCount = functions.https.onCall(async (data, context) => {
    const { categoryId, userLocation } = data; // userLocation: {latitude, longitude}

    if (!categoryId || !userLocation || userLocation.latitude === undefined || userLocation.longitude === undefined) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing categoryId or userLocation');
    }

    const RADIUS_KM = 25;
    const { latitude, longitude } = userLocation;

    // 1. Get Technicians
    const snapshot = await db.collection('technicians')
        .where('status', '==', 'active')
        .get();

    const matches: any[] = [];

    snapshot.docs.forEach(doc => {
        const tech = doc.data();

        // 2. Skill Match
        // Assuming skills is an object like skilledServices: { [serviceId]: true }
        // or a list of categoryIds.
        // Let's check common patterns in this codebase.
        const skills = tech.skills || tech.servicedCategories || [];
        const hasSkill = Array.isArray(skills)
            ? skills.includes(categoryId)
            : !!skills[categoryId];

        if (hasSkill && tech.coordinates) { // Using 'coordinates' based on matching/engine.ts
            const techLoc = { lat: tech.coordinates.latitude, lng: tech.coordinates.longitude };
            const distance = calculateDistance({ lat: latitude, lng: longitude }, techLoc);

            if (distance <= RADIUS_KM) {
                matches.push({
                    id: doc.id,
                    distance: distance
                });
            }
        }
    });

    return {
        success: true,
        count: matches.length,
        isAvailable: matches.length > 0,
        technicians: matches.slice(0, 5) // Return a few for verification
    };
});

export const admin_manageServiceBanners = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { action, bannerId, bannerData } = data; // action: 'add' | 'update' | 'delete' | 'reorder'

    if (action === 'add') {
        const snapshot = await db.collection('service_bottom_banners').get();
        if (snapshot.size >= 10) { // Reasonably high limit but 3 displayed
            throw new functions.https.HttpsError('failed-precondition', 'Maximum 10 banners allowed');
        }
        const docRef = db.collection('service_bottom_banners').doc();
        await docRef.set({
            ...bannerData,
            isActive: bannerData.isActive !== undefined ? bannerData.isActive : true,
            order: bannerData.order !== undefined ? bannerData.order : snapshot.size,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, id: docRef.id };
    }

    if (action === 'update') {
        if (!bannerId) throw new functions.https.HttpsError('invalid-argument', 'Missing bannerId');
        await db.collection('service_bottom_banners').doc(bannerId).update({
            ...bannerData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }

    if (action === 'delete') {
        if (!bannerId) throw new functions.https.HttpsError('invalid-argument', 'Missing bannerId');
        await db.collection('service_bottom_banners').doc(bannerId).delete();
        return { success: true };
    }

    if (action === 'reorder') {
        const { orders } = data;
        if (!Array.isArray(orders)) throw new functions.https.HttpsError('invalid-argument', 'Orders must be an array');

        const batch = db.batch();
        orders.forEach((item: any) => {
            batch.update(db.collection('service_bottom_banners').doc(item.id), {
                order: item.order,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        await batch.commit();
        return { success: true };
    }

    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
});
