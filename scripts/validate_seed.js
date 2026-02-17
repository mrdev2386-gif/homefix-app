/**
 * Validation Script - Verify seeded data integrity
 */

const admin = require('firebase-admin');
const path = require('path');

const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');

if (!admin.apps.length) {
    try {
        const serviceAccount = require(SERVICE_ACCOUNT_PATH);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    } catch (e) {
        console.error('❌ Error: Missing serviceAccountKey.json');
        process.exit(1);
    }
}

const db = admin.firestore();

async function validate() {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  VALIDATION - SEEDED DATA INTEGRITY');
    console.log('═══════════════════════════════════════════════════════════\n');

    const stats = {
        servicesCreated: 0,
        subServicesCreated: 0,
        servicesSkipped: 0,
        servicesBelowMinimum: 0,
        categoriesUsed: new Set(),
        validationErrors: []
    };

    // Get categories
    const categoriesSnap = await db.collection('categories').get();
    const categoryIds = new Set(categoriesSnap.docs.map(d => d.id));
    console.log(`Categories in DB: ${categoryIds.size}`);
    console.log(`  ${[...categoryIds].join(', ')}\n`);

    // Get all services
    const servicesSnap = await db.collection('services').get();
    console.log(`Total services in DB: ${servicesSnap.size}\n`);

    // Validate each service
    for (const serviceDoc of servicesSnap.docs) {
        const serviceData = serviceDoc.data();
        stats.servicesCreated++;

        // Check categoryId is valid
        if (serviceData.categoryId && categoryIds.has(serviceData.categoryId)) {
            stats.categoriesUsed.add(serviceData.categoryId);
        } else {
            stats.validationErrors.push(`Service ${serviceDoc.id}: Invalid categoryId ${serviceData.categoryId}`);
        }

        // Check isActive
        if (serviceData.isActive !== true) {
            stats.validationErrors.push(`Service ${serviceDoc.id}: isActive is not true`);
        }

        // Check imageUrl
        if (!serviceData.imageUrl || !serviceData.imageUrl.startsWith('http')) {
            stats.validationErrors.push(`Service ${serviceDoc.id}: Missing or invalid imageUrl`);
        }

        // Get subServices count
        const subServicesSnap = await db.collection(`services/${serviceDoc.id}/subServices`).get();
        const subServiceCount = subServicesSnap.size;
        stats.subServicesCreated += subServiceCount;

        // Check subService minimum
        if (subServiceCount < 7) {
            stats.servicesBelowMinimum++;
            stats.validationErrors.push(`Service ${serviceDoc.id}: Only ${subServiceCount} subServices (minimum 7)`);
        }

        // Validate subServices
        for (const subServiceDoc of subServicesSnap.docs) {
            const subServiceData = subServiceDoc.data();

            // Check subService isActive
            if (subServiceData.isActive !== true) {
                stats.validationErrors.push(`SubService ${serviceDoc.id}/${subServiceDoc.id}: isActive is not true`);
            }

            // Check price
            if (!subServiceData.price || subServiceData.price <= 0) {
                stats.validationErrors.push(`SubService ${serviceDoc.id}/${subServiceDoc.id}: Invalid price`);
            }

            // Check imageUrl
            if (!subServiceData.imageUrl || !subServiceData.imageUrl.startsWith('http')) {
                stats.validationErrors.push(`SubService ${serviceDoc.id}/${subServiceDoc.id}: Missing or invalid imageUrl`);
            }
        }
    }

    // Check for nested services under categories (should be 0)
    let nestedServicesCount = 0;
    for (const categoryId of categoryIds) {
        const nestedSnap = await db.collection(`categories/${categoryId}/services`).get();
        nestedServicesCount += nestedSnap.size;
    }

    // Output results
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  SEED RESULT');
    console.log('═══════════════════════════════════════════════════════════\n');
    
    console.log('SEED_RESULT:');
    console.log(`  servicesCreated: ${stats.servicesCreated}`);
    console.log(`  subServicesCreated: ${stats.subServicesCreated}`);
    console.log(`  servicesSkipped: 0`);
    console.log(`  servicesBelowMinimum: ${stats.servicesBelowMinimum}`);
    console.log(`  categoriesUsed: ${JSON.stringify([...stats.categoriesUsed])}`);

    console.log('\nCategory Distribution:');
    const categoryCounts = {};
    for (const serviceDoc of servicesSnap.docs) {
        const catId = serviceDoc.data().categoryId;
        categoryCounts[catId] = (categoryCounts[catId] || 0) + 1;
    }
    for (const [catId, count] of Object.entries(categoryCounts)) {
        console.log(`  - ${catId}: ${count} services`);
    }

    if (stats.validationErrors.length > 0) {
        console.log('\n⚠️  Validation Errors:');
        stats.validationErrors.slice(0, 10).forEach(err => console.log(`  - ${err}`));
        if (stats.validationErrors.length > 10) {
            console.log(`  ... and ${stats.validationErrors.length - 10} more`);
        }
    } else {
        console.log('\n✅ All validations passed!');
    }

    console.log('\nNested Services Check:');
    console.log(`  Nested services under categories: ${nestedServicesCount}`);
    if (nestedServicesCount === 0) {
        console.log('  ✅ No nested services (Firebase-first design maintained)');
    } else {
        console.log('  ⚠️  Found nested services - not following Firebase-first design');
    }

    console.log('\n═══════════════════════════════════════════════════════════\n');

    return stats;
}

validate()
    .then(stats => {
        setTimeout(() => process.exit(0), 1000);
    })
    .catch(e => {
        console.error('❌ Validation failed:', e);
        process.exit(1);
    });
