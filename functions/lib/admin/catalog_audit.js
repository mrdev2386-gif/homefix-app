"use strict";
/**
 * HomeFix Service Catalog Audit Function
 *
 * READ-ONLY function that counts and reports statistics about the service catalog.
 * Does NOT modify any data.
 *
 * Returns:
 * - totalCategories
 * - totalServices
 * - totalSubServices
 * - averageSubServicesPerService
 * - servicesWithZeroSubServices
 * - servicesBelowMinimum
 * - servicesHealthy
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
exports.admin_auditServiceCatalog = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("./utils");
/**
 * Audits the complete service catalog
 * Admin-only, read-only operation
 */
exports.admin_auditServiceCatalog = functions.region('asia-south1').https.onCall(async (data, context) => {
    // 1. Enforce admin-only access
    await (0, utils_1.assertAdmin)(context);
    const db = admin.firestore();
    try {
        console.log('🔍 Starting service catalog audit...');
        // =============================================
        // 1️⃣ COUNT TOTAL CATEGORIES
        // =============================================
        const categoriesSnapshot = await db.collection('categories').get();
        const totalCategories = categoriesSnapshot.size;
        console.log(`✓ Found ${totalCategories} categories`);
        // =============================================
        // 2️⃣ COUNT TOTAL SERVICES
        // =============================================
        let totalServices = 0;
        const servicesPerCategory = {};
        for (const categoryDoc of categoriesSnapshot.docs) {
            const categoryId = categoryDoc.id;
            const categoryData = categoryDoc.data();
            const categoryName = categoryData.name || categoryId;
            const servicesSnapshot = await db
                .collection('categories')
                .doc(categoryId)
                .collection('services')
                .get();
            const serviceCount = servicesSnapshot.size;
            totalServices += serviceCount;
            servicesPerCategory[categoryName] = serviceCount;
        }
        console.log(`✓ Found ${totalServices} total services`);
        // =============================================
        // 3️⃣ COUNT TOTAL SUB-SERVICES
        // =============================================
        let totalSubServices = 0;
        const subServicesPerService = {};
        const servicesWithZeroSubServices = [];
        for (const categoryDoc of categoriesSnapshot.docs) {
            const categoryId = categoryDoc.id;
            const categoryData = categoryDoc.data();
            const categoryName = categoryData.name || categoryId;
            const servicesSnapshot = await db
                .collection('categories')
                .doc(categoryId)
                .collection('services')
                .get();
            for (const serviceDoc of servicesSnapshot.docs) {
                const serviceId = serviceDoc.id;
                const serviceData = serviceDoc.data();
                const serviceName = serviceData.name || serviceId;
                const subServicesSnapshot = await db
                    .collection('categories')
                    .doc(categoryId)
                    .collection('services')
                    .doc(serviceId)
                    .collection('subServices')
                    .get();
                const subServiceCount = subServicesSnapshot.size;
                totalSubServices += subServiceCount;
                const serviceKey = `${categoryName} → ${serviceName}`;
                subServicesPerService[serviceKey] = subServiceCount;
                if (subServiceCount === 0) {
                    servicesWithZeroSubServices.push(serviceKey);
                }
            }
        }
        console.log(`✓ Found ${totalSubServices} total sub-services`);
        // =============================================
        // 4️⃣ COVERAGE SUMMARY
        // =============================================
        const averageSubServicesPerService = totalServices > 0 ? parseFloat((totalSubServices / totalServices).toFixed(2)) : 0;
        const servicesBelowMinimum = Object.entries(subServicesPerService)
            .filter(([_, count]) => count > 0 && count < 4)
            .map(([name, count]) => ({ name, count }));
        const servicesHealthy = Object.entries(subServicesPerService)
            .filter(([_, count]) => count >= 4)
            .map(([name, count]) => ({ name, count }));
        console.log('✅ Audit completed successfully');
        console.log(`   - Services with zero sub-services: ${servicesWithZeroSubServices.length}`);
        console.log(`   - Services below minimum: ${servicesBelowMinimum.length}`);
        console.log(`   - Healthy services: ${servicesHealthy.length}`);
        return {
            totalCategories,
            totalServices,
            totalSubServices,
            averageSubServicesPerService,
            servicesWithZeroSubServices,
            servicesBelowMinimum,
            servicesHealthy,
        };
    }
    catch (error) {
        console.error('❌ Service catalog audit failed:', error);
        throw new functions.https.HttpsError('internal', 'Failed to audit service catalog', error);
    }
});
//# sourceMappingURL=catalog_audit.js.map