/**
 * Check existing categories and services in Firestore
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

async function checkData() {
    console.log('=== CATEGORIES ===\n');
    const categoriesSnap = await db.collection('categories').get();
    categoriesSnap.forEach(doc => {
        const data = doc.data();
        console.log(`ID: ${doc.id}`);
        console.log(`  Name: ${data.name}`);
        console.log(`  Order: ${data.order}`);
        console.log(`  isActive: ${data.isActive}`);
        console.log('');
    });

    console.log('=== EXISTING SERVICES ===\n');
    const servicesSnap = await db.collection('services').get();
    console.log(`Total services: ${servicesSnap.size}\n`);
    
    servicesSnap.forEach(doc => {
        const data = doc.data();
        console.log(`Service ID: ${doc.id}`);
        console.log(`  Name: ${data.name || data.title || 'N/A'}`);
        console.log(`  Category: ${data.categoryId || data.category || 'N/A'}`);
        console.log(`  isActive: ${data.isActive}`);
        console.log('');
    });

    // Check for existing subServices count per service
    console.log('=== SUBSERVICES COUNT PER SERVICE ===\n');
    for (const doc of servicesSnap.docs) {
        const subServicesSnap = await db.collection(`services/${doc.id}/subServices`).get();
        console.log(`${doc.id}: ${subServicesSnap.size} subServices`);
    }
}

checkData()
    .then(() => setTimeout(() => process.exit(0), 1000))
    .catch(e => {
        console.error('Error:', e);
        process.exit(1);
    });
