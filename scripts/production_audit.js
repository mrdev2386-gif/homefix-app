/**
 * HomeFix Production Health Auditor
 * 
 * Performs a comprehensive, read-only audit of the service catalog,
 * technician coverage, and booking readiness.
 */

const admin = require('firebase-admin');

// ============================================================================
// CONFIGURATION
// ============================================================================

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';

if (!admin.apps.length) {
    try {
        const serviceAccount = require(SERVICE_ACCOUNT_PATH);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    } catch (error) {
        console.error('❌ Error initializing Firebase Admin. Ensure serviceAccountKey.json is valid.');
        process.exit(1);
    }
}

const db = admin.firestore();

// ============================================================================
// AUDIT LOGIC
// ============================================================================

async function runAudit() {
    console.log('🔍 Starting HomeFix Production Audit...\n');

    const health = {
        categories: { total: 0, active: 0, missingImage: 0 },
        services: { totalNested: 0, totalRoot: 0, missingImage: 0, inactive: 0, withoutSub: 0 },
        subServices: { total: 0, missingImage: 0, inactive: 0, belowMin: 0, healthy: 0 },
        technicians: { total: 0, approved: 0, withoutServiceIds: 0, orphanRefs: 0 },
        bookings: { total: 0, invalidServiceId: 0 }
    };

    const alerts = [];
    const warnings = [];

    try {
        // --- 1. Category & Nested Services Scan ---
        const allNestedServiceIds = new Set();
        const catSnap = await db.collection('categories').get();
        health.categories.total = catSnap.size;

        for (const catDoc of catSnap.docs) {
            const cData = catDoc.data();
            if (cData.isActive !== false) health.categories.active++;
            if (!cData.imageUrl && !cData.image) health.categories.missingImage++;

            const servSnap = await catDoc.ref.collection('services').get();
            health.services.totalNested += servSnap.size;

            for (const servDoc of servSnap.docs) {
                const sData = servDoc.data();
                const serviceId = servDoc.id;
                allNestedServiceIds.add(serviceId);

                if (sData.isActive === false) health.services.inactive++;
                if (!sData.imageUrl && !sData.image) health.services.missingImage++;

                const subSnap = await servDoc.ref.collection('subServices').get();
                const subCount = subSnap.size;
                health.subServices.total += subCount;

                if (subCount === 0) health.services.withoutSub++;
                else if (subCount < 4) health.subServices.belowMin++;
                else health.subServices.healthy++;

                subSnap.forEach(subDoc => {
                    const ssData = subDoc.data();
                    if (!ssData.imageUrl && !ssData.image) health.subServices.missingImage++;
                    if (ssData.isActive === false) health.subServices.inactive++;
                });
            }
        }

        // --- 2. Root Services Drift ---
        const rootSnap = await db.collection('services').get();
        health.services.totalRoot = rootSnap.size;
        const drift = health.services.totalRoot - health.services.totalNested;
        if (drift > 0) {
            alerts.push(`DRIFT DETECTED: ${drift} services exist in root but are missing from nested structure.`);
        }

        // --- 3. Technicians ---
        const techSnap = await db.collection('technicians').get();
        health.technicians.total = techSnap.size;
        for (const techDoc of techSnap.docs) {
            const tData = techDoc.data();
            if (tData.status === 'approved' || tData.isApproved === true) health.technicians.approved++;

            const sIds = tData.serviceIds || [];
            if (sIds.length === 0) health.technicians.withoutServiceIds++;
            else {
                const orphans = sIds.filter(id => !allNestedServiceIds.has(id));
                health.technicians.orphanRefs += orphans.length;
            }
        }

        // --- 4. Bookings ---
        const bookingSnap = await db.collection('bookings').get();
        health.bookings.total = bookingSnap.size;
        for (const bDoc of bookingSnap.docs) {
            const bData = bDoc.data();
            if (bData.serviceId && !allNestedServiceIds.has(bData.serviceId)) {
                health.bookings.invalidServiceId++;
            }
        }

        // --- CRITICAL ALERTS ---
        if (health.services.totalNested === 0 && health.services.totalRoot > 0) alerts.push('CRITICAL: Nested service catalog is EMPTY despite data in root services.');
        if (health.bookings.invalidServiceId > 0) alerts.push(`CRITICAL: ${health.bookings.invalidServiceId} bookings are pointing to non-existent nested services.`);
        if (health.technicians.approved > 0 && health.technicians.withoutServiceIds === health.technicians.approved) {
            alerts.push('CRITICAL: ZERO approved technicians have service assignments.');
        }

        // --- WARNINGS ---
        if (health.categories.missingImage > 0) warnings.push(`${health.categories.missingImage} categories are missing images.`);
        if (health.subServices.belowMin > 0) warnings.push(`${health.subServices.belowMin} services have fewer than 4 sub-services (Enrichment needed).`);

        // --- FINAL OUTPUT ---
        console.log('HEALTH_SUMMARY:');
        console.log(`categories: ${health.categories.total} (${health.categories.active} active, ${health.categories.missingImage} missing image)`);
        console.log(`services: ${health.services.totalNested} nested, ${health.services.totalRoot} root, ${health.services.withoutSub} without sub-services`);
        console.log(`subServices: ${health.subServices.total} total, ${health.subServices.healthy} healthy, ${health.subServices.belowMin} below minimum`);
        console.log(`technicians: ${health.technicians.total} total, ${health.technicians.approved} approved, ${health.technicians.orphanRefs} orphan service refs`);
        console.log(`bookings: ${health.bookings.total} total, ${health.bookings.invalidServiceId} invalid service references`);

        console.log('\nCRITICAL_ALERTS:');
        if (alerts.length > 0) alerts.forEach(a => console.log(`[!] ${a}`));
        else console.log('None');

        console.log('\nWARNINGS:');
        if (warnings.length > 0) warnings.forEach(w => console.log(`[-] ${w}`));
        else console.log('None');

        console.log('\nREADY_FOR_PRODUCTION:');
        console.log(alerts.length === 0 ? 'YES' : 'NO');

    } catch (error) {
        console.error('Audit failed:', error);
    }
}

runAudit();
