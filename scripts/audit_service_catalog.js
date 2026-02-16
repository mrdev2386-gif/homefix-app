const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}.firebaseio.com`
});

const db = admin.firestore();

/**
 * FIRESTORE SERVICE CATALOG AUDIT
 * 
 * READ-ONLY SCRIPT
 * Does NOT modify any data
 * Only counts and reports
 */

async function auditServiceCatalog() {
    console.log('========================================');
    console.log('FIRESTORE SERVICE CATALOG AUDIT');
    console.log('========================================\n');
    console.log('⚠️  READ-ONLY MODE - No data will be modified\n');

    try {
        // =============================================
        // 1️⃣ COUNT TOTAL CATEGORIES
        // =============================================
        console.log('1️⃣  Counting categories...');
        const categoriesSnapshot = await db.collection('categories').get();
        const totalCategories = categoriesSnapshot.size;
        console.log(`   ✓ Found ${totalCategories} categories\n`);

        // =============================================
        // 2️⃣ COUNT TOTAL SERVICES
        // =============================================
        console.log('2️⃣  Counting services across all categories...');
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

            console.log(`   ✓ ${categoryName}: ${serviceCount} services`);
        }
        console.log(`   ✓ TOTAL: ${totalServices} services\n`);

        // =============================================
        // 3️⃣ COUNT TOTAL SUB-SERVICES
        // =============================================
        console.log('3️⃣  Counting sub-services across all services...');
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

                if (subServiceCount > 0) {
                    console.log(`   ✓ ${serviceKey}: ${subServiceCount} sub-services`);
                }
            }
        }
        console.log(`   ✓ TOTAL: ${totalSubServices} sub-services\n`);

        // =============================================
        // 4️⃣ COVERAGE SUMMARY
        // =============================================
        console.log('4️⃣  Computing coverage metrics...');

        const averageSubServicesPerService = totalServices > 0
            ? (totalSubServices / totalServices).toFixed(2)
            : 0;

        const servicesBelowMinimum = Object.entries(subServicesPerService)
            .filter(([_, count]) => count > 0 && count < 4)
            .map(([name, count]) => ({ name, count }));

        const servicesHealthy = Object.entries(subServicesPerService)
            .filter(([_, count]) => count >= 4)
            .map(([name, count]) => ({ name, count }));

        console.log(`   ✓ Average: ${averageSubServicesPerService} sub-services per service`);
        console.log(`   ✓ Services with 0 sub-services: ${servicesWithZeroSubServices.length}`);
        console.log(`   ✓ Services below minimum (<4): ${servicesBelowMinimum.length}`);
        console.log(`   ✓ Healthy services (≥4): ${servicesHealthy.length}\n`);

        // =============================================
        // OUTPUT FINAL RESULTS
        // =============================================
        console.log('\n========================================');
        console.log('FINAL AUDIT RESULTS');
        console.log('========================================\n');

        console.log('SUMMARY:');
        console.log(`totalCategories: ${totalCategories}`);
        console.log(`totalServices: ${totalServices}`);
        console.log(`totalSubServices: ${totalSubServices}`);
        console.log(`averageSubServicesPerService: ${averageSubServicesPerService}\n`);

        console.log('BREAKDOWN:');
        console.log(`servicesWithZeroSubServices: ${servicesWithZeroSubServices.length}`);
        console.log(`servicesBelowMinimum: ${servicesBelowMinimum.length}`);
        console.log(`servicesHealthy: ${servicesHealthy.length}\n`);

        // =============================================
        // DETAILED BREAKDOWN
        // =============================================
        if (servicesWithZeroSubServices.length > 0) {
            console.log('========================================');
            console.log('SERVICES WITH ZERO SUB-SERVICES');
            console.log('========================================');
            servicesWithZeroSubServices.forEach((service, idx) => {
                console.log(`${idx + 1}. ${service}`);
            });
            console.log('');
        }

        if (servicesBelowMinimum.length > 0) {
            console.log('========================================');
            console.log('SERVICES BELOW MINIMUM (<4 SUB-SERVICES)');
            console.log('========================================');
            servicesBelowMinimum.forEach((service, idx) => {
                console.log(`${idx + 1}. ${service.name} (${service.count} sub-services)`);
            });
            console.log('');
        }

        if (servicesHealthy.length > 0) {
            console.log('========================================');
            console.log('HEALTHY SERVICES (≥4 SUB-SERVICES)');
            console.log('========================================');
            servicesHealthy.forEach((service, idx) => {
                console.log(`${idx + 1}. ${service.name} (${service.count} sub-services)`);
            });
            console.log('');
        }

        console.log('========================================');
        console.log('SERVICES PER CATEGORY');
        console.log('========================================');
        Object.entries(servicesPerCategory).forEach(([category, count]) => {
            console.log(`${category}: ${count} services`);
        });
        console.log('');

        console.log('========================================');
        console.log('✅ AUDIT COMPLETE');
        console.log('========================================');

        process.exit(0);

    } catch (error) {
        console.error('\n❌ ERROR during audit:', error.message);
        console.error(error);
        process.exit(1);
    }
}

// Run the audit
auditServiceCatalog();
