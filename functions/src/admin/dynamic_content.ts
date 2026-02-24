import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin, logAdminAction } from './utils';
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
        const docRef = db.collection('cleaning_essentials').doc();
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
        await db.collection('cleaning_essentials').doc(categoryId).update({
            ...categoryData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }

    if (action === 'delete') {
        if (!categoryId) throw new functions.https.HttpsError('invalid-argument', 'Missing categoryId');
        await db.collection('cleaning_essentials').doc(categoryId).delete();
        return { success: true };
    }

    if (action === 'reorder') {
        const { orders } = data;
        if (!Array.isArray(orders)) throw new functions.https.HttpsError('invalid-argument', 'Orders must be an array');

        const batch = db.batch();
        orders.forEach((item: any) => {
            batch.update(db.collection('cleaning_essentials').doc(item.id), {
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
        // Updated to use 'categories' and 'subCategories' arrays per Task 3
        const categories = tech.categories || [];
        // const subCategories = tech.subCategories || []; // Unused for now, but could be specific

        // Check if the requested categoryKey (passed as categoryId data) is in the tech's categories
        // We assume categoryId passed from client corresponds to an ID in 'technician_categories' 
        // OR a key that is stored in the technician's categories list.

        // If tech has the category
        const hasSkill = Array.isArray(categories) && categories.includes(categoryId);

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

export const admin_initializeHomeContent = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);

    const collections = [
        'celebrating_professionals',
        'cleaning_essentials',
        'service_bottom_banners',
        'home_banners',
        'services',
        'technician_categories',
        'technician_subcategories'
    ];

    const results: any = {};

    for (const collName of collections) {
        const snap = await db.collection(collName).get();
        if (snap.empty) {
            console.log(`Seeding empty collection: ${collName}`);
            const seedData = getSeedData(collName);
            const batch = db.batch();

            seedData.forEach((item: any) => {
                const docRef = item.id ? db.collection(collName).doc(item.id) : db.collection(collName).doc();
                batch.set(docRef, {
                    ...item,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            });

            await batch.commit();
            results[collName] = `Seeded ${seedData.length} items`;
        } else {
            results[collName] = 'Already exists';
        }
    }

    return { success: true, results };
});

function getSeedData(collName: string): any[] {
    switch (collName) {
        case 'celebrating_professionals':
            return [
                {
                    videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-man-cleaning-the-floor-with-a-mop-41610-large.mp4',
                    thumbnailUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6954',
                    title: 'Dusting Specialist',
                    isActive: true,
                    order: 1,
                },
                {
                    videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-repairman-fixing-a-kitchen-faucet-41618-large.mp4',
                    thumbnailUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a',
                    title: 'Master Plumber',
                    isActive: true,
                    order: 2,
                },
                {
                    videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-woman-cleaning-a-glass-window-41619-large.mp4',
                    thumbnailUrl: 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac',
                    title: 'Glass Cleaning Pro',
                    isActive: true,
                    order: 3,
                },
                {
                    videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-electrician-working-on-a-fuse-box-41621-large.mp4',
                    thumbnailUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e',
                    title: 'Elite Electrician',
                    isActive: true,
                    order: 4,
                },
                {
                    videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-man-ironing-a-white-shirt-41623-large.mp4',
                    thumbnailUrl: 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60',
                    title: 'Ironing Expert',
                    isActive: true,
                    order: 5,
                },
            ];
        case 'cleaning_essentials':
            return [
                {
                    imageUrl: 'https://images.unsplash.com/photo-1584622781564-1d9876a13d00',
                    title: 'Full Home Deep Cleaning',
                    categoryId: 'cleaning',
                    isActive: true,
                    order: 1,
                },
                {
                    imageUrl: 'https://images.unsplash.com/photo-1528740561666-dc2479dc08ab',
                    title: 'Kitchen Degreasing',
                    categoryId: 'cleaning',
                    isActive: true,
                    order: 2,
                },
                {
                    imageUrl: 'https://images.unsplash.com/photo-1563453392212-326f5e854473',
                    title: 'Bathroom Sanitization',
                    categoryId: 'cleaning',
                    isActive: true,
                    order: 3,
                },
                {
                    imageUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a',
                    title: 'Sofa & Carpet Shampooing',
                    categoryId: 'cleaning',
                    isActive: true,
                    order: 4,
                },
            ];
        case 'service_bottom_banners':
            return [
                {
                    imageUrl: 'https://images.unsplash.com/photo-1595841696662-50d34b2cf331',
                    title: 'Refer & Earn',
                    description: 'Get ₹50 for every friend you refer!',
                    isActive: true,
                    order: 1,
                },
                {
                    imageUrl: 'https://images.unsplash.com/photo-1556742044-3c52d6e88c62',
                    title: 'HomeFix Plus',
                    description: 'Enjoy unlimited free delivery & extra 10% off',
                    isActive: true,
                    order: 2,
                },
            ];
        case 'home_banners':
            return [
                {
                    imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e',
                    title: '20% OFF Electrical Services',
                    subtitle: 'Safe & Certified Experts',
                    active: true,
                    order: 1,
                },
                {
                    imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6954',
                    title: 'Deep Cleaning Sale',
                    subtitle: 'Starts at just ₹499',
                    active: true,
                    order: 2,
                },
            ];
        case 'services':
            return [
                {
                    id: 'ac_service',
                    title: 'AC Repair & Service',
                    basePrice: 499.0,
                    durationMins: 45,
                    image: 'https://images.unsplash.com/photo-1581094288338-2314dddb7ecb',
                    isActive: true,
                    category: 'Appliance',
                },
                {
                    id: 'cleaning',
                    title: 'Home Cleaning',
                    basePrice: 599.0,
                    durationMins: 120,
                    image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64',
                    isActive: true,
                    category: 'Cleaning',
                },
            ];
        case 'technician_categories':
            return [
                { id: 'cleaning', name: 'Cleaning', icon: 'cleaning_services', order: 1, isActive: true },
                { id: 'plumbing', name: 'Plumbing', icon: 'plumbing', order: 2, isActive: true },
                { id: 'electrical', name: 'Electrical', icon: 'electrical_services', order: 3, isActive: true },
                { id: 'painting', name: 'Painting', icon: 'format_paint', order: 4, isActive: true },
                { id: 'ac_repair', name: 'AC Repair', icon: 'ac_unit', order: 5, isActive: true },
                { id: 'appliance', name: 'Appliance Repair', icon: 'home_repair_service', order: 6, isActive: true },
                { id: 'carpentry', name: 'Carpentry', icon: 'carpenter', order: 7, isActive: true },
                { id: 'pest_control', name: 'Pest Control', icon: 'pest_control', order: 8, isActive: true },
            ];
        case 'technician_subcategories':
            // We need parent IDs which we don't have easily here without fetching.
            // For seeding, we might skip subcategories or assume some relationship if we could control IDs.
            // Since we use auto-ID, seeding subcategories with relations is hard.
            // I'll leave subcategories empty for now or add a comment.
            return [];
        default:
            return [];
    }
}
// ... (existing content)

export const admin_manageTechnicianCategories = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { action, categoryId, categoryData } = data;

    if (action === 'add') {
        const docRef = db.collection('technician_categories').doc();
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
        await db.collection('technician_categories').doc(categoryId).update({
            ...categoryData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }

    if (action === 'delete') {
        if (!categoryId) throw new functions.https.HttpsError('invalid-argument', 'Missing categoryId');
        await db.collection('technician_categories').doc(categoryId).delete();
        return { success: true };
    }

    if (action === 'reorder') {
        const { orders } = data;
        if (!Array.isArray(orders)) throw new functions.https.HttpsError('invalid-argument', 'Orders must be an array');
        const batch = db.batch();
        orders.forEach((item: any) => {
            batch.update(db.collection('technician_categories').doc(item.id), {
                order: item.order,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        await batch.commit();
        return { success: true };
    }

    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
});

export const admin_manageTechnicianSubcategories = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { action, subCategoryId, subCategoryData } = data;

    if (action === 'add') {
        const docRef = db.collection('technician_subcategories').doc();
        await docRef.set({
            ...subCategoryData,
            isActive: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, id: docRef.id };
    }

    if (action === 'update') {
        if (!subCategoryId) throw new functions.https.HttpsError('invalid-argument', 'Missing subCategoryId');
        await db.collection('technician_subcategories').doc(subCategoryId).update({
            ...subCategoryData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }

    if (action === 'delete') {
        if (!subCategoryId) throw new functions.https.HttpsError('invalid-argument', 'Missing subCategoryId');
        await db.collection('technician_subcategories').doc(subCategoryId).delete();
        return { success: true };
    }

    if (action === 'reorder') {
        const { orders } = data;
        if (!Array.isArray(orders)) throw new functions.https.HttpsError('invalid-argument', 'Orders must be an array');
        const batch = db.batch();
        orders.forEach((item: any) => {
            batch.update(db.collection('technician_subcategories').doc(item.id), {
                order: item.order,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        await batch.commit();
        return { success: true };
    }

    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
});

// ============================================================================
// HOME SECTIONS MANAGEMENT (Dynamic Home Screen Control)
// ============================================================================

export const admin_manageHomeSections = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { action, sectionId, sectionData, orders } = data;
    // action: 'add' | 'update' | 'delete' | 'reorder'

    // Validate imageUrl if provided
    if (sectionData?.imageUrl && !sectionData.imageUrl.startsWith('https://')) {
        throw new functions.https.HttpsError('invalid-argument', 'imageUrl must start with https://');
    }

    if (action === 'add') {
        const { title, type, linkedCategoryId, customServices, imageUrl, isActive, order } = sectionData;

        if (!title || !type) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: title, type');
        }

        // Validate type
        const validTypes = ['horizontal', 'grid', 'banner'];
        if (!validTypes.includes(type)) {
            throw new functions.https.HttpsError('invalid-argument', `type must be one of: ${validTypes.join(', ')}`);
        }

        const docRef = db.collection('homeSections').doc();
        const newSection = {
            title,
            type,
            linkedCategoryId: linkedCategoryId || null,
            customServices: customServices || [],
            imageUrl: imageUrl || '',
            isActive: isActive !== undefined ? isActive : true,
            order: order || 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: context.auth!.uid
        };

        await docRef.set(newSection);
        await logAdminAction(context.auth!.uid, 'homesection_create', docRef.id, newSection);

        return { success: true, id: docRef.id };
    }

    if (action === 'update') {
        if (!sectionId) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing sectionId');
        }

        const updateData: any = {
            ...sectionData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Remove undefined values
        Object.keys(updateData).forEach(key => {
            if (updateData[key] === undefined) {
                delete updateData[key];
            }
        });

        await db.collection('homeSections').doc(sectionId).update(updateData);
        await logAdminAction(context.auth!.uid, 'homesection_update', sectionId, updateData);

        return { success: true };
    }

    if (action === 'delete') {
        if (!sectionId) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing sectionId');
        }

        await db.collection('homeSections').doc(sectionId).delete();
        await logAdminAction(context.auth!.uid, 'homesection_delete', sectionId);

        return { success: true };
    }

    if (action === 'reorder') {
        if (!Array.isArray(orders)) {
            throw new functions.https.HttpsError('invalid-argument', 'orders must be an array');
        }

        const batch = db.batch();
        orders.forEach((item: any) => {
            batch.update(db.collection('homeSections').doc(item.id), {
                order: item.order,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        await batch.commit();
        await logAdminAction(context.auth!.uid, 'homesection_reorder', 'bulk', { orders });

        return { success: true };
    }

    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
});

// ============================================================================
// CATEGORY MANAGEMENT (Under categories collection)
// ============================================================================

export const admin_manageCategory = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { action, categoryId, categoryData, orders } = data;
    // action: 'add' | 'update' | 'delete' | 'reorder'

    // Validate imageUrl if provided
    if (categoryData?.imageUrl && !categoryData.imageUrl.startsWith('https://')) {
        throw new functions.https.HttpsError('invalid-argument', 'imageUrl must start with https://');
    }

    if (action === 'add') {
        const { name, imageUrl, isActive, order } = categoryData;

        if (!name) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required field: name');
        }

        const docRef = db.collection('categories').doc();
        const newCategory = {
            name,
            imageUrl: imageUrl || '',
            isActive: isActive !== undefined ? isActive : true,
            order: order || 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: context.auth!.uid
        };

        await docRef.set(newCategory);
        await logAdminAction(context.auth!.uid, 'category_create', docRef.id, newCategory);

        return { success: true, id: docRef.id };
    }

    if (action === 'update') {
        if (!categoryId) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing categoryId');
        }

        const updateData: any = {
            ...categoryData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Remove undefined values
        Object.keys(updateData).forEach(key => {
            if (updateData[key] === undefined) {
                delete updateData[key];
            }
        });

        await db.collection('categories').doc(categoryId).update(updateData);
        await logAdminAction(context.auth!.uid, 'category_update', categoryId, updateData);

        return { success: true };
    }

    if (action === 'delete') {
        if (!categoryId) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing categoryId');
        }

        // Check if category has services before deleting
        const servicesSnapshot = await db.collection('categories').doc(categoryId)
            .collection('services').get();

        if (!servicesSnapshot.empty) {
            // Check for force flag
            if (!data.force) {
                throw new functions.https.HttpsError('failed-precondition',
                    'Cannot delete category with existing services. Use force: true to override.');
            }
        }

        // Soft delete - just mark as inactive
        await db.collection('categories').doc(categoryId).update({
            isActive: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await logAdminAction(context.auth!.uid, 'category_delete', categoryId);

        return { success: true };
    }

    if (action === 'reorder') {
        if (!Array.isArray(orders)) {
            throw new functions.https.HttpsError('invalid-argument', 'orders must be an array');
        }

        const batch = db.batch();
        orders.forEach((item: any) => {
            batch.update(db.collection('categories').doc(item.id), {
                order: item.order,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        await batch.commit();
        await logAdminAction(context.auth!.uid, 'category_reorder', 'bulk', { orders });

        return { success: true };
    }

    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
});

// ============================================================================
// SERVICE MANAGEMENT (Under categories/{categoryId}/services)
// ============================================================================

export const admin_manageNestedService = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { action, categoryId, serviceId, serviceData, orders } = data;
    // action: 'add' | 'update' | 'delete' | 'reorder'

    // Validate imageUrl if provided
    if (serviceData?.imageUrl && !serviceData.imageUrl.startsWith('https://')) {
        throw new functions.https.HttpsError('invalid-argument', 'imageUrl must start with https://');
    }

    if (action === 'add') {
        if (!categoryId) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing categoryId');
        }

        const { name, imageUrl, isActive, order } = serviceData;

        if (!name) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required field: name');
        }

        const docRef = db.collection('categories').doc(categoryId).collection('services').doc();
        const newService = {
            id: docRef.id,
            name,
            imageUrl: imageUrl || '',
            isActive: isActive !== undefined ? isActive : true,
            order: order || 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: context.auth!.uid
        };

        await docRef.set(newService);
        await logAdminAction(context.auth!.uid, 'nested_service_create', docRef.id, { ...newService, categoryId });

        return { success: true, id: docRef.id };
    }

    if (action === 'update') {
        if (!serviceId || !categoryId) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing serviceId or categoryId');
        }

        const updateData: any = {
            ...serviceData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Remove undefined values
        Object.keys(updateData).forEach(key => {
            if (updateData[key] === undefined) {
                delete updateData[key];
            }
        });

        await db.collection('categories').doc(categoryId).collection('services').doc(serviceId).update(updateData);
        await logAdminAction(context.auth!.uid, 'nested_service_update', serviceId, { ...updateData, categoryId });

        return { success: true };
    }

    if (action === 'delete') {
        if (!serviceId || !categoryId) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing serviceId or categoryId');
        }

        // Check for subServices before deleting
        const subServicesSnapshot = await db.collection('categories').doc(categoryId)
            .collection('services').doc(serviceId).collection('subServices').get();

        if (!subServicesSnapshot.empty) {
            if (!data.force) {
                throw new functions.https.HttpsError('failed-precondition',
                    'Cannot delete service with existing subServices. Use force: true to override.');
            }
        }

        // Soft delete
        await db.collection('categories').doc(categoryId).collection('services').doc(serviceId).update({
            isActive: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await logAdminAction(context.auth!.uid, 'nested_service_delete', serviceId, { categoryId });

        return { success: true };
    }

    if (action === 'reorder') {
        if (!categoryId || !Array.isArray(orders)) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing categoryId or invalid orders array');
        }

        const batch = db.batch();
        orders.forEach((item: any) => {
            batch.update(db.collection('categories').doc(categoryId).collection('services').doc(item.id), {
                order: item.order,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        await batch.commit();
        await logAdminAction(context.auth!.uid, 'nested_service_reorder', 'bulk', { categoryId, orders });

        return { success: true };
    }

    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
});

// ============================================================================
// SUBSERVICE MANAGEMENT (Under categories/{categoryId}/services/{serviceId}/subServices)
// ============================================================================

export const admin_manageNestedSubService = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);

    const { action, categoryId, serviceId, subServiceId, subServiceData, orders } = data;
    // action: 'add' | 'update' | 'delete' | 'reorder'

    // Validate price if provided
    if (subServiceData?.price !== undefined && subServiceData.price < 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Price cannot be negative');
    }

    // Validate imageUrl if provided
    if (subServiceData?.imageUrl && !subServiceData.imageUrl.startsWith('https://')) {
        throw new functions.https.HttpsError('invalid-argument', 'imageUrl must start with https://');
    }

    if (action === 'add') {
        if (!categoryId || !serviceId) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing categoryId or serviceId');
        }

        const { name, price, imageUrl, isActive, order } = subServiceData;

        if (!name || price === undefined) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: name, price');
        }

        const docRef = db.collection('categories').doc(categoryId)
            .collection('services').doc(serviceId).collection('subServices').doc();

        const newSubService = {
            id: docRef.id,
            name,
            price,
            imageUrl: imageUrl || '',
            isActive: isActive !== undefined ? isActive : true,
            order: order || 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: context.auth!.uid
        };

        await docRef.set(newSubService);
        await logAdminAction(context.auth!.uid, 'nested_subservice_create', docRef.id,
            { ...newSubService, categoryId, serviceId });

        return { success: true, id: docRef.id };
    }

    if (action === 'update') {
        if (!subServiceId || !categoryId || !serviceId) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required IDs');
        }

        const updateData: any = {
            ...subServiceData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Remove undefined values
        Object.keys(updateData).forEach(key => {
            if (updateData[key] === undefined) {
                delete updateData[key];
            }
        });

        await db.collection('categories').doc(categoryId)
            .collection('services').doc(serviceId)
            .collection('subServices').doc(subServiceId).update(updateData);

        await logAdminAction(context.auth!.uid, 'nested_subservice_update', subServiceId,
            { ...updateData, categoryId, serviceId });

        return { success: true };
    }

    if (action === 'delete') {
        if (!subServiceId || !categoryId || !serviceId) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required IDs');
        }

        // Soft delete
        await db.collection('categories').doc(categoryId)
            .collection('services').doc(serviceId)
            .collection('subServices').doc(subServiceId).update({
                isActive: false,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

        await logAdminAction(context.auth!.uid, 'nested_subservice_delete', subServiceId, { categoryId, serviceId });

        return { success: true };
    }

    if (action === 'reorder') {
        if (!categoryId || !serviceId || !Array.isArray(orders)) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required IDs or invalid orders array');
        }

        const batch = db.batch();
        orders.forEach((item: any) => {
            batch.update(db.collection('categories').doc(categoryId)
                .collection('services').doc(serviceId)
                .collection('subServices').doc(item.id), {
                order: item.order,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        await batch.commit();
        await logAdminAction(context.auth!.uid, 'nested_subservice_reorder', 'bulk', { categoryId, serviceId, orders });

        return { success: true };
    }

    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
});
