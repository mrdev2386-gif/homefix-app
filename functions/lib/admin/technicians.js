"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateTechnician = exports.getTechnicianById = exports.getTechnicians = exports.updateTechServices = exports.toggleTechAvailability = exports.approveTechnician = exports.adminApproveTechnician = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const config_1 = require("../shared/config");
const utils_1 = require("./utils");
const security_1 = require("../shared/security");
exports.adminApproveTechnician = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    try {
        await (0, utils_1.assertAdmin)(context);
        const { techId, approve, reason } = data;
        if (!techId)
            throw new functions.https.HttpsError('invalid-argument', 'Missing techId');
        const appRef = config_1.db.collection('technician_applications').doc(techId);
        const appDoc = await appRef.get();
        if (!appDoc.exists)
            throw new functions.https.HttpsError('not-found', 'Application not found');
        const appData = appDoc.data();
        if (approve) {
            await config_1.db.collection('technicians').doc(techId).set({
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
        }
        else {
            await appRef.update({
                status: 'rejected',
                isApproved: false,
                rejectionReason: (0, security_1.sanitize)(reason) || 'Not specified',
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            await config_1.db.collection('technicians').doc(techId).update({
                status: 'rejected',
                isApproved: false,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        await (0, utils_1.logAdminAction)(context.auth.uid, approve ? 'tech_app_approve' : 'tech_app_reject', techId, { reason: (0, security_1.sanitize)(reason) });
        return { success: true };
    }
    catch (error) {
        console.error('[Technician] Error in adminApproveTechnician:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to process application');
    }
}));
exports.approveTechnician = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    try {
        await (0, utils_1.assertAdmin)(context);
        const { techId, approve, reason } = data;
        if (!techId)
            throw new functions.https.HttpsError('invalid-argument', 'Missing techId');
        const techRef = config_1.db.collection('technicians').doc(techId);
        const techDoc = await techRef.get();
        if (!techDoc.exists)
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        console.log('[ADMIN APPROVAL] Processing approval for:', techId, 'approve:', approve);
        if (approve) {
            // APPROVE: Set ALL required fields for technician activation
            await techRef.update({
                // Primary approval flags
                isApproved: true, // Required by technician app
                adminApproved: true, // Required by technician app
                isVerified: true, // Legacy compatibility
                // Status fields
                status: 'approved', // Main status
                kycStatus: 'approved', // KYC-specific status
                // Activation
                isActive: true, // Allow going online
                // Metadata
                approvedAt: admin.firestore.FieldValue.serverTimestamp(),
                approvedBy: context.auth.uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                // Clear rejection fields
                rejectionReason: admin.firestore.FieldValue.delete()
            });
            console.log('[ADMIN APPROVAL] ✅ Technician approved and activated:', techId);
        }
        else {
            // REJECT/SUSPEND: Clear approval flags
            await techRef.update({
                status: 'suspended',
                isApproved: false,
                adminApproved: false,
                isVerified: false,
                isActive: false,
                isOnline: false, // Force offline
                kycStatus: 'rejected',
                rejectionReason: (0, security_1.sanitize)(reason) || 'Not specified',
                rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
                rejectedBy: context.auth.uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log('[ADMIN APPROVAL] ❌ Technician suspended:', techId);
        }
        await (0, utils_1.logAdminAction)(context.auth.uid, approve ? 'tech_approve' : 'tech_suspend', techId, { reason: (0, security_1.sanitize)(reason) });
        return { success: true };
    }
    catch (error) {
        console.error('[Technician] Error in approveTechnician:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to update technician status');
    }
}));
exports.toggleTechAvailability = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    try {
        await (0, utils_1.assertAdmin)(context);
        const { techId, isAvailable } = data;
        if (!techId)
            throw new functions.https.HttpsError('invalid-argument', 'Missing techId');
        const techRef = config_1.db.collection('technicians').doc(techId);
        const techDoc = await techRef.get();
        if (!techDoc.exists)
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        await techRef.update({
            isAvailable: Boolean(isAvailable),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        await (0, utils_1.logAdminAction)(context.auth.uid, 'tech_toggle_availability', techId, { isAvailable });
        return { success: true };
    }
    catch (error) {
        console.error('[Technician] Error in toggleTechAvailability:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to toggle availability');
    }
}));
/**
 * Update technician services
 */
exports.updateTechServices = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    try {
        await (0, utils_1.assertAdmin)(context);
        const { techId, skills } = data;
        if (!techId || !skills)
            throw new functions.https.HttpsError('invalid-argument', 'Missing techId or skills');
        const techRef = config_1.db.collection('technicians').doc(techId);
        const techDoc = await techRef.get();
        if (!techDoc.exists)
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        await techRef.update({
            skills,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        await (0, utils_1.logAdminAction)(context.auth.uid, 'tech_update_services', techId, { skills });
        return { success: true };
    }
    catch (error) {
        console.error('[Technician] Error in updateTechServices:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to update services');
    }
}));
/**
 * Get paginated and filtered list of technicians
 */
exports.getTechnicians = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    try {
        await (0, utils_1.assertAdmin)(context);
        const { limit = 10, offset = 0, status, search, city, kycPending } = data;
        let query = config_1.db.collection('technicians');
        // Filter for pending KYC submissions
        if (kycPending === true) {
            query = query
                .where('isKycComplete', '==', true)
                .where('kycStatus', '==', 'pending');
        }
        else if (status) {
            query = query.where('status', '==', status);
        }
        if (city) {
            query = query.where('city', '==', city);
        }
        const snapshot = await query.orderBy('createdAt', 'desc').get();
        let techs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        if (search) {
            const lowerSearch = (0, security_1.sanitize)(search).toLowerCase();
            techs = techs.filter((t) => t.name?.toLowerCase().includes(lowerSearch) ||
                t.fullName?.toLowerCase().includes(lowerSearch) ||
                t.email?.toLowerCase().includes(lowerSearch) ||
                t.phone?.includes(lowerSearch) ||
                t.id.includes(lowerSearch));
        }
        const total = techs.length;
        const paginatedTechs = techs.slice(offset, offset + limit);
        console.log('[ADMIN PIPELINE] Loaded', paginatedTechs.length, 'technicians (total:', total, ')');
        return {
            techs: paginatedTechs,
            total,
            limit,
            offset
        };
    }
    catch (error) {
        console.error('[Admin Techs] Error in getTechnicians:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to fetch technicians');
    }
}));
/**
 * Get full details of a technician
 */
exports.getTechnicianById = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    try {
        await (0, utils_1.assertAdmin)(context);
        const { techId } = data;
        if (!techId)
            throw new functions.https.HttpsError('invalid-argument', 'Missing techId');
        const techDoc = await config_1.db.collection('technicians').doc(techId).get();
        if (!techDoc.exists)
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        const techData = techDoc.data();
        // STEP 3: Use canonical wallet path - technician_wallets/{techId}
        const walletDoc = await config_1.db.collection('technician_wallets').doc(techId).get();
        const wallet = walletDoc.exists ? walletDoc.data() : { availableBalance: 0, pendingBalance: 0 };
        // Fetch job history (last 5)
        const jobsSnap = await config_1.db.collection('bookings')
            .where('assignedTechnicianId', '==', techId)
            .orderBy('createdAt', 'desc')
            .limit(5)
            .get();
        const jobHistory = jobsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        // Extract KYC documents from technician document itself
        const documents = {};
        if (techData.aadhaarFrontUrl) {
            documents['Aadhaar Front'] = techData.aadhaarFrontUrl;
        }
        if (techData.aadhaarBackUrl) {
            documents['Aadhaar Back'] = techData.aadhaarBackUrl;
        }
        if (techData.profilePhotoUrl) {
            documents['Profile Photo'] = techData.profilePhotoUrl;
        }
        // Fetch ratings & reviews (last 5)
        const reviewsSnap = await config_1.db.collection('reviews')
            .where('technicianId', '==', techId)
            .orderBy('createdAt', 'desc')
            .limit(5)
            .get();
        const reviews = reviewsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        console.log('[ADMIN PIPELINE] Loaded technician details with', Object.keys(documents).length, 'documents');
        return {
            ...techData,
            wallet,
            jobHistory,
            documents,
            reviews
        };
    }
    catch (error) {
        console.error('[Admin Techs] Error in getTechnicianById:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to fetch technician details');
    }
}));
/**
 * Update technician profile
 */
exports.updateTechnician = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    try {
        await (0, utils_1.assertAdmin)(context);
        const { techId, updates } = data;
        if (!techId || !updates)
            throw new functions.https.HttpsError('invalid-argument', 'Missing techId or updates');
        const techRef = config_1.db.collection('technicians').doc(techId);
        const techDoc = await techRef.get();
        if (!techDoc.exists)
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        const allowedFields = ['name', 'phone', 'email', 'skills', 'city', 'status', 'isVerified', 'isAvailable'];
        const cleanUpdates = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
        for (const field of allowedFields) {
            if (updates[field] !== undefined) {
                cleanUpdates[field] = (typeof updates[field] === 'string') ? (0, security_1.sanitize)(updates[field]) : updates[field];
            }
        }
        await techRef.update(cleanUpdates);
        // If status changed to suspended, maybe block in Auth too?
        if (updates.status === 'suspended' || updates.status === 'blocked') {
            await admin.auth().updateUser(techId, { disabled: true });
            await config_1.db.collection('users').doc(techId).update({ isBlocked: true });
        }
        else if (updates.status === 'approved') {
            await admin.auth().updateUser(techId, { disabled: false });
            await config_1.db.collection('users').doc(techId).update({ isBlocked: false });
        }
        await (0, utils_1.logAdminAction)(context.auth.uid, 'update_technician', techId, { updates: cleanUpdates });
        return { success: true };
    }
    catch (error) {
        console.error('[Admin Techs] Error in updateTechnician:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to update technician');
    }
}));
//# sourceMappingURL=technicians.js.map