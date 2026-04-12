"use strict";
/**
 * Admin Service Management Functions
 *
 * Platform-controlled, hack-safe service and pricing management
 * All pricing changes are logged and audited
 *
 * Security: Admin-only access, all operations logged
 */
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
exports.migrateServicesToNested = exports.manageService = exports.getSubServicePriceHistory = exports.bulkUpdatePrices = exports.getPricingConfig = exports.updatePricingConfig = exports.deleteSubService = exports.updateSubService = exports.createSubService = exports.deleteService = exports.updateService = exports.createService = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const config_1 = require("../shared/config");
const utils_1 = require("./utils");
// ============================================================================
// SERVICE MANAGEMENT
// ============================================================================
/**
 * Create a new service category
 */
exports.createService = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { name, slug, category, icon, imageUrl, description, requiresInspection, inspectionCharge, inspectionDuration, isFeatured, order } = data;
    // Validation
    if (!name || !slug || !category) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    // Check if slug already exists
    const existingService = await config_1.db.collection('services').where('slug', '==', slug).get();
    if (!existingService.empty) {
        throw new functions.https.HttpsError('already-exists', 'Service with this slug already exists');
    }
    const serviceRef = config_1.db.collection('services').doc();
    const serviceId = serviceRef.id;
    const serviceData = {
        id: serviceId,
        name,
        slug,
        category,
        icon: icon || 'default',
        imageUrl: imageUrl || '',
        description: description || '',
        isActive: true,
        isFeatured: isFeatured || false,
        order: order || 999,
        requiresInspection: requiresInspection || false,
        inspectionCharge: inspectionCharge || 0,
        inspectionDuration: inspectionDuration || 30,
        metadata: {
            totalSubServices: 0,
            activeSubServices: 0,
            activeTechnicians: 0,
            avgRating: 0,
            totalBookings: 0
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: context.auth.uid,
        updatedBy: context.auth.uid
    };
    await serviceRef.set(serviceData);
    await (0, utils_1.logAdminAction)(context.auth.uid, 'service_create', serviceId, serviceData);
    return { success: true, serviceId };
});
/**
 * Update an existing service
 */
exports.updateService = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { serviceId, updates } = data;
    if (!serviceId) {
        throw new functions.https.HttpsError('invalid-argument', 'Service ID required');
    }
    // Prevent updating critical fields
    const allowedFields = [
        'name', 'description', 'icon', 'imageUrl', 'isActive', 'isFeatured', 'order',
        'requiresInspection', 'inspectionCharge', 'inspectionDuration'
    ];
    const filteredUpdates = {};
    for (const key of Object.keys(updates)) {
        if (allowedFields.includes(key)) {
            filteredUpdates[key] = updates[key];
        }
    }
    filteredUpdates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    filteredUpdates.updatedBy = context.auth.uid;
    await config_1.db.collection('services').doc(serviceId).update(filteredUpdates);
    await (0, utils_1.logAdminAction)(context.auth.uid, 'service_update', serviceId, filteredUpdates);
    return { success: true };
});
/**
 * Delete (soft delete) a service
 */
exports.deleteService = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
    console.log("AUTH DEBUG:", context.auth);
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }
    await (0, utils_1.assertAdmin)(context);
    const { serviceId } = data;
    if (!serviceId) {
        throw new functions.https.HttpsError('invalid-argument', 'Service ID required');
    }
    // Soft delete - just mark as inactive
    await config_1.db.collection('services').doc(serviceId).update({
        isActive: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: context.auth.uid
    });
    // Also deactivate all sub-services
    const subServices = await config_1.db.collection('subServices').where('serviceId', '==', serviceId).get();
    const batch = config_1.db.batch();
    subServices.forEach(doc => {
        batch.update(doc.ref, {
            isActive: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedBy: context.auth.uid
        });
    });
    await batch.commit();
    await (0, utils_1.logAdminAction)(context.auth.uid, 'service_delete', serviceId);
    return { success: true };
});
// ============================================================================
// SUB-SERVICE MANAGEMENT
// ============================================================================
/**
 * Create a new sub-service with fixed pricing
 */
exports.createSubService = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { serviceId, name, slug, description, detailedDescription, fixedPrice, estimatedDuration, warrantyDays, requiredTools, requiredCertifications, skillLevel, requiresInspection, canBeAddedAfterInspection, order, tags } = data;
    // Validation
    if (!serviceId || !name || !slug || fixedPrice === undefined) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    if (fixedPrice < 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Price cannot be negative');
    }
    // Get parent service
    const serviceDoc = await config_1.db.collection('services').doc(serviceId).get();
    if (!serviceDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Parent service not found');
    }
    const service = serviceDoc.data();
    // Check if slug already exists for this service
    const existingSubService = await config_1.db.collection('subServices')
        .where('serviceId', '==', serviceId)
        .where('slug', '==', slug)
        .get();
    if (!existingSubService.empty) {
        throw new functions.https.HttpsError('already-exists', 'Sub-service with this slug already exists for this service');
    }
    const subServiceRef = config_1.db.collection('subServices').doc();
    const subServiceId = subServiceRef.id;
    const subServiceData = {
        id: subServiceId,
        serviceId,
        serviceName: service.name,
        name,
        slug,
        description: description || '',
        detailedDescription: detailedDescription || '',
        isActive: true,
        fixedPrice,
        currency: 'INR',
        estimatedDuration: estimatedDuration || 60,
        warrantyDays: warrantyDays || 0,
        requiredTools: requiredTools || [],
        requiredCertifications: requiredCertifications || [],
        skillLevel: skillLevel || 'basic',
        requiresInspection: requiresInspection !== undefined ? requiresInspection : service.requiresInspection,
        canBeAddedAfterInspection: canBeAddedAfterInspection || false,
        order: order || 999,
        tags: tags || [],
        metadata: {
            totalBookings: 0,
            avgRating: 0,
            completionRate: 0
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: context.auth.uid,
        updatedBy: context.auth.uid,
        priceHistory: []
    };
    await subServiceRef.set(subServiceData);
    // Update parent service metadata
    await config_1.db.collection('services').doc(serviceId).update({
        'metadata.totalSubServices': admin.firestore.FieldValue.increment(1),
        'metadata.activeSubServices': admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await (0, utils_1.logAdminAction)(context.auth.uid, 'subservice_create', subServiceId, subServiceData);
    return { success: true, subServiceId };
});
/**
 * Update sub-service (including price changes with audit trail)
 */
exports.updateSubService = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { subServiceId, updates } = data;
    if (!subServiceId) {
        throw new functions.https.HttpsError('invalid-argument', 'Sub-service ID required');
    }
    // Get current sub-service
    const subServiceDoc = await config_1.db.collection('subServices').doc(subServiceId).get();
    if (!subServiceDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Sub-service not found');
    }
    const currentSubService = subServiceDoc.data();
    // Allowed fields for update
    const allowedFields = [
        'name', 'description', 'detailedDescription', 'isActive', 'fixedPrice',
        'estimatedDuration', 'warrantyDays', 'requiredTools', 'requiredCertifications',
        'skillLevel', 'requiresInspection', 'canBeAddedAfterInspection', 'order',
        'imageUrl', 'tags'
    ];
    const filteredUpdates = {};
    for (const key of Object.keys(updates)) {
        if (allowedFields.includes(key)) {
            filteredUpdates[key] = updates[key];
        }
    }
    // Handle price change with audit trail
    if (updates.fixedPrice !== undefined && updates.fixedPrice !== currentSubService.fixedPrice) {
        const priceHistoryEntry = {
            oldPrice: currentSubService.fixedPrice,
            newPrice: updates.fixedPrice,
            changedAt: admin.firestore.FieldValue.serverTimestamp(),
            changedBy: context.auth.uid,
            reason: updates.priceChangeReason || 'Admin update'
        };
        filteredUpdates.priceHistory = admin.firestore.FieldValue.arrayUnion(priceHistoryEntry);
    }
    filteredUpdates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    filteredUpdates.updatedBy = context.auth.uid;
    await config_1.db.collection('subServices').doc(subServiceId).update(filteredUpdates);
    await (0, utils_1.logAdminAction)(context.auth.uid, 'subservice_update', subServiceId, filteredUpdates);
    return { success: true };
});
/**
 * Delete (soft delete) a sub-service
 */
exports.deleteSubService = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { subServiceId } = data;
    if (!subServiceId) {
        throw new functions.https.HttpsError('invalid-argument', 'Sub-service ID required');
    }
    const subServiceDoc = await config_1.db.collection('subServices').doc(subServiceId).get();
    if (!subServiceDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Sub-service not found');
    }
    const subService = subServiceDoc.data();
    // Soft delete
    await config_1.db.collection('subServices').doc(subServiceId).update({
        isActive: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: context.auth.uid
    });
    // Update parent service metadata
    await config_1.db.collection('services').doc(subService.serviceId).update({
        'metadata.activeSubServices': admin.firestore.FieldValue.increment(-1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await (0, utils_1.logAdminAction)(context.auth.uid, 'subservice_delete', subServiceId);
    return { success: true };
});
// ============================================================================
// PRICING CONFIGURATION
// ============================================================================
/**
 * Update global pricing configuration
 */
exports.updatePricingConfig = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { updates } = data;
    const allowedFields = [
        'defaultInspectionCharge',
        'inspectionChargeRefundable',
        'platformFeePercentage',
        'gstPercentage',
        'minBookingAmount',
        'maxBookingAmount',
        'allowDynamicPricing',
        'allowDiscounts'
    ];
    const filteredUpdates = {};
    for (const key of Object.keys(updates)) {
        if (allowedFields.includes(key)) {
            filteredUpdates[key] = updates[key];
        }
    }
    filteredUpdates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    filteredUpdates.updatedBy = context.auth.uid;
    await config_1.db.collection('app_config').doc('pricing').update(filteredUpdates);
    await (0, utils_1.logAdminAction)(context.auth.uid, 'pricing_config_update', 'pricing', filteredUpdates);
    return { success: true };
});
/**
 * Get pricing configuration
 */
exports.getPricingConfig = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const configDoc = await config_1.db.collection('app_config').doc('pricing').get();
    if (!configDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Pricing configuration not found');
    }
    return { config: configDoc.data() };
});
// ============================================================================
// BULK OPERATIONS
// ============================================================================
/**
 * Bulk update prices (e.g., apply percentage increase/decrease)
 */
exports.bulkUpdatePrices = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { serviceId, adjustmentType, adjustmentValue, reason } = data;
    // adjustmentType: 'percentage' | 'fixed'
    // adjustmentValue: number (e.g., 10 for 10% increase, or 100 for ₹100 increase)
    if (!serviceId || !adjustmentType || adjustmentValue === undefined) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    // Get all sub-services for this service
    const subServicesSnapshot = await config_1.db.collection('subServices')
        .where('serviceId', '==', serviceId)
        .where('isActive', '==', true)
        .get();
    if (subServicesSnapshot.empty) {
        throw new functions.https.HttpsError('not-found', 'No active sub-services found');
    }
    const batch = config_1.db.batch();
    const updates = [];
    for (const doc of subServicesSnapshot.docs) {
        const subService = doc.data();
        let newPrice;
        if (adjustmentType === 'percentage') {
            newPrice = Math.round(subService.fixedPrice * (1 + adjustmentValue / 100));
        }
        else {
            newPrice = subService.fixedPrice + adjustmentValue;
        }
        // Ensure price is not negative
        if (newPrice < 0)
            newPrice = 0;
        const priceHistoryEntry = {
            oldPrice: subService.fixedPrice,
            newPrice,
            changedAt: admin.firestore.FieldValue.serverTimestamp(),
            changedBy: context.auth.uid,
            reason: reason || `Bulk ${adjustmentType} adjustment: ${adjustmentValue}`
        };
        batch.update(doc.ref, {
            fixedPrice: newPrice,
            priceHistory: admin.firestore.FieldValue.arrayUnion(priceHistoryEntry),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedBy: context.auth.uid
        });
        updates.push({
            subServiceId: doc.id,
            name: subService.name,
            oldPrice: subService.fixedPrice,
            newPrice
        });
    }
    await batch.commit();
    await (0, utils_1.logAdminAction)(context.auth.uid, 'bulk_price_update', serviceId, { adjustmentType, adjustmentValue, updates });
    return { success: true, updatedCount: updates.length, updates };
});
/**
 * Get price history for a sub-service
 */
exports.getSubServicePriceHistory = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { subServiceId } = data;
    if (!subServiceId) {
        throw new functions.https.HttpsError('invalid-argument', 'Sub-service ID required');
    }
    const subServiceDoc = await config_1.db.collection('subServices').doc(subServiceId).get();
    if (!subServiceDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Sub-service not found');
    }
    const subService = subServiceDoc.data();
    return {
        subServiceId,
        name: subService.name,
        currentPrice: subService.fixedPrice,
        priceHistory: subService.priceHistory || []
    };
});
/**
 * Dispatcher for service management (backward compatibility with frontend)
 */
exports.manageService = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { action, serviceId, payload } = data;
    if (action === 'create') {
        const createData = {
            ...payload,
            slug: payload.slug || payload.name?.toLowerCase().replace(/\s+/g, '-') || `service-${Date.now()}`,
            category: payload.category || payload.categoryId || 'general'
        };
        // @ts-ignore - access the internal handler if needed, or just redirect
        // In this case, we can't easily call onCall from another onCall without .run in some environments
        // So we'll just implement a simple dispatch logic or re-link
        // For simplicity and safety, we'll re-implement the dispatch logic here
        // but actually, we can just call the logic since it's in the same file.
        // However, onCall functions are wrapped. We'll use a helper or just re-route.
        return await exports.createService.run(createData, context);
    }
    else if (action === 'update') {
        return await exports.updateService.run({ serviceId, updates: payload }, context);
    }
    else if (action === 'delete') {
        return await exports.deleteService.run({ serviceId }, context);
    }
    else {
        throw new functions.https.HttpsError('invalid-argument', `Invalid action: ${action}`);
    }
});
// ============================================================================
// SERVICE NESTING MIGRATION (PHASE 12)
// ============================================================================
/**
 * Migrate root services to nested categories/{categoryId}/services structure
 *
 * RULES:
 * - DO NOT delete root services
 * - DO NOT overwrite existing nested services
 * - Preserve ALL original fields
 * - Add migratedAt timestamp
 * - Idempotent (safe to run multiple times)
 */
exports.migrateServicesToNested = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const DRY_RUN = data.dryRun ?? false;
    const BATCH_SIZE = 400;
    console.log(`[SERVICE_MIGRATION] Starting migration...`);
    console.log(`[SERVICE_MIGRATION] DRY_RUN: ${DRY_RUN}`);
    // Get all root services
    const servicesSnapshot = await config_1.db.collection('services').get();
    const totalRootServices = servicesSnapshot.size;
    console.log(`[SERVICE_MIGRATION] Found ${totalRootServices} root services`);
    let totalMigrated = 0;
    let totalSkippedAlreadyExists = 0;
    let totalErrors = 0;
    const errors = [];
    // Process in batches
    const batch = config_1.db.batch();
    let batchOpCount = 0;
    for (const serviceDoc of servicesSnapshot.docs) {
        const serviceData = serviceDoc.data();
        const serviceId = serviceDoc.id;
        // Get category from service - this is the categoryId for nesting
        const categoryId = serviceData.category || serviceData.categoryId;
        if (!categoryId) {
            console.log(`[SERVICE_MIGRATION] Skipping service ${serviceId} - no category`);
            totalErrors++;
            errors.push(`Service ${serviceId}: no category field`);
            continue;
        }
        // Check if nested service already exists
        const nestedPath = `categories/${categoryId}/services/${serviceId}`;
        const nestedDocRef = config_1.db.doc(nestedPath);
        const nestedDoc = await nestedDocRef.get();
        if (nestedDoc.exists) {
            console.log(`[SERVICE_MIGRATION] Skipping ${serviceId} - already exists at ${nestedPath}`);
            totalSkippedAlreadyExists++;
            continue;
        }
        if (DRY_RUN) {
            console.log(`[DRY_RUN] Would migrate: ${serviceId} -> ${nestedPath}`);
            totalMigrated++;
            continue;
        }
        // Create nested service with ALL original fields + migratedAt
        const nestedData = {
            ...serviceData,
            migratedAt: admin.firestore.FieldValue.serverTimestamp(),
            originalServiceId: serviceId
        };
        batch.set(nestedDocRef, nestedData);
        batchOpCount++;
        console.log(`[SERVICE_MIGRATION] Queueing migration: ${serviceId} -> ${nestedPath}`);
        totalMigrated++;
        // Commit batch if reaching limit
        if (batchOpCount >= BATCH_SIZE) {
            await batch.commit();
            console.log(`[SERVICE_MIGRATION] Committed batch of ${batchOpCount}`);
            batchOpCount = 0;
        }
    }
    // Commit remaining batch
    if (batchOpCount > 0) {
        await batch.commit();
        console.log(`[SERVICE_MIGRATION] Committed final batch of ${batchOpCount}`);
    }
    const summary = {
        success: true,
        dryRun: DRY_RUN,
        totalRootServices,
        totalMigrated,
        totalSkippedAlreadyExists,
        totalErrors,
        errors: errors.slice(0, 10) // Limit errors in response
    };
    console.log(`[SERVICE_MIGRATION] Migration complete:`, summary);
    return summary;
});
//# sourceMappingURL=services.js.map