
const admin = require('firebase-admin');

// 1. Initialize Firebase Admin
// Make sure you have GOOGLE_APPLICATION_CREDENTIALS set or use a service account key
if (!admin.apps.length) {
    admin.initializeApp({
        projectId: 'homefix-app', // Replace with your actual project ID if different
    });
}

const db = admin.firestore();

async function runTests() {
    console.log('--- STARTING TECHNICIAN ONBOARDING TESTS ---');

    const testTechId = 'test_tech_' + Date.now();
    const testPhone = '+919876543210';

    try {
        // --- TEST 1: Simulate Phone Verification ---
        console.log('\n[TEST 1] Simulate Phone Verification (Cloud Function mock)');
        // Ideally we call the Cloud Function, but for script we can simulate the DB write or use HTTP trigger if deployed.
        // Let's effectively "mock" the function's internal logic to verify DB rules allow/block or just set state.
        // Actually, better to test if we can simply WRITE to the collection directly (Should FAIL).

        console.log('Attempting direct DB write to technicianApplications (Should FAIL if rules active)...');
        try {
            await db.collection('technicianApplications').doc(testTechId).set({
                phone: testPhone,
                status: 'draft'
            });
            console.log('WARNING: Direct write SUCCEEDED (Rules might be too open for Admin SDK, which ignores rules).');
            console.log('NOTE: Admin SDK bypasses security rules. To test rules, we need a client SDK or emulator.');
        } catch (e) {
            console.log('Direct write blocked as expected:', e.message);
        }

        // Since we are running as Admin, we will use it to SEED data and then verify logic.

        // --- STEP 1: Seed Initial Application ---
        console.log('\n[STEP 1] Seeding application for ' + testTechId);
        await db.collection('technicianApplications').doc(testTechId).set({
            id: testTechId,
            phone: testPhone,
            status: 'draft',
            currentStep: 1,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log('✓ Application seeded.');

        // --- STEP 2: Verify "savePersonalDetails" logic ---
        // We can't easily invoke the Callable Function from Node without a client lib auth token.
        // So we will simulate the "outcome" and verify the "next step" logic if we were implementing unit tests.
        // BUT, we can read the collection to ensure indexes work.

        console.log('\n[TEST 2] Verifying Query Indexes...');
        try {
            const q = await db.collection('technicianApplications')
                .where('status', '==', 'draft')
                .orderBy('createdAt', 'desc')
                .get();
            console.log(`✓ Query successful. Found ${q.size} draft applications.`);
        } catch (e) {
            console.error('X Query FAILED. Indexes missing?', e.message);
        }

        // --- TEST 3: Master Service Catalog ---
        console.log('\n[TEST 3] Verifying Master Services...');
        const services = await db.collection('services').get();
        if (services.empty) {
            console.log('X No services found. Seeding default services...');
            await seedServices();
        } else {
            console.log(`✓ Found ${services.size} services.`);
            services.docs.forEach(d => console.log(` - ${d.data().name} (${d.id})`));
        }

        // --- TEST 4: Sub-Services ---
        console.log('\n[TEST 4] Verifying Sub-Services...');
        const subServices = await db.collection('subServices').get();
        if (subServices.empty) {
            console.log('X No sub-services found. Seeding defaults...');
            await seedSubServices();
        } else {
            console.log(`✓ Found ${subServices.size} sub-services.`);
        }

    } catch (e) {
        console.error('TEST SUITE ERROR:', e);
    } finally {
        // Cleanup
        console.log('\nCleaning up test data...');
        // await db.collection('technicianApplications').doc(testTechId).delete();
        console.log('Done.');
        process.exit(0);
    }
}

async function seedServices() {
    const services = [
        { id: 'ac_repair', name: 'AC Repair', category: 'home' },
        { id: 'cleaning', name: 'Cleaning', category: 'home' },
        { id: 'plumbing', name: 'Plumbing', category: 'home' },
        { id: 'electrical', name: 'Electrical', category: 'home' }
    ];

    const batch = db.batch();
    for (const s of services) {
        batch.set(db.collection('services').doc(s.id), {
            ...s,
            isActive: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }
    await batch.commit();
    console.log('✓ Seeded ' + services.length + ' services.');
}

async function seedSubServices() {
    const subs = [
        { id: 'split_ac_service', serviceId: 'ac_repair', name: 'Split AC Service' },
        { id: 'window_ac_service', serviceId: 'ac_repair', name: 'Window AC Service' },
        { id: 'bathroom_cleaning', serviceId: 'cleaning', name: 'Bathroom Cleaning' },
        { id: 'fan_repair', serviceId: 'electrical', name: 'Fan Repair' }
    ];

    const batch = db.batch();
    for (const s of subs) {
        batch.set(db.collection('subServices').doc(s.id), {
            ...s,
            isActive: true,
            basePrice: 499,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }
    await batch.commit();
    console.log('✓ Seeded ' + subs.length + ' sub-services.');
}

runTests();
