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

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin } from './utils';

interface AuditResult {
    totalCategories: number;
    totalServices: number;
    totalSubServices: number;
    averageSubServicesPerService: number;
    servicesWithZeroSubServices: string[];
    servicesBelowMinimum: Array<{ name: string; count: number }>;
    servicesHealthy: Array<{ name: string; count: number }>;
}

/**
 * Audits the complete service catalog
 * Admin-only, read-only operation
 */
export const admin_auditServiceCatalog = functions.https.onCall(
    async (data, context): Promise<AuditResult> => {
        // 1. Enforce admin-only access
        await assertAdmin(context);

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
            const servicesPerCategory: { [key: string]: number } = {};

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
            const subServicesPerService: { [key: string]: number } = {};
            const servicesWithZeroSubServices: string[] = [];

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
        } catch (error) {
            console.error('❌ Service catalog audit failed:', error);
            throw new functions.https.HttpsError(
                'internal',
                'Failed to audit service catalog',
                error
            );
        }
    }
);
