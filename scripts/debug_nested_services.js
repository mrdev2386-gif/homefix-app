/**
 * Debug Script: Diagnose Nested Services Visibility Issue
 * 
 * READ-ONLY - No writes to Firestore
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

async function runDebug() {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  DEBUG: Nested Services Visibility');
    console.log('═══════════════════════════════════════════════════════════\n');

    // ========================================================================
    // STEP 1: VERIFY NESTED SERVICES EXIST
    // ========================================================================
    console.log('📋 STEP 1: Scanning nested services...\n');
    
    const categoriesSnap = await db.collection('categories').get();
    const categories = categoriesSnap.docs.map(d => ({ id: d.id, data: d.data() }));
    
    console.log(`Total categories: ${categories.length}`);
    console.log('Category IDs:', categories.map(c => c.id));
    console.log('');

    let totalNestedServices = 0;
    const servicesPerCategory = [];
    const allNestedServices = []; // Store for matching

    for (const category of categories) {
        const servicesSnap = await db.collection(`categories/${category.id}/services`).get();
        const count = servicesSnap.size;
        totalNestedServices += count;
        servicesPerCategory.push({ categoryId: category.id, count });
        
        console.log(`  Category [${category.id}]: ${count} services`);
        
        // Store service IDs for matching
        for (const serviceDoc of servicesSnap.docs) {
            allNestedServices.push({
                categoryId: category.id,
                serviceId: serviceDoc.id,
                data: serviceDoc.data()
            });
        }
    }

    const sampleNestedServicePaths = allNestedServices.slice(0, 5).map(s => 
        `categories/${s.categoryId}/services/${s.serviceId}`
    );

    console.log('');
    console.log('Sample nested service paths:');
    sampleNestedServicePaths.forEach(p => console.log(`  - ${p}`));
    console.log('');

    // ========================================================================
    // STEP 2: ROOT SERVICE CROSSCHECK
    // ========================================================================
    console.log('📋 STEP 2: Root service crosscheck...\n');
    
    const rootServicesSnap = await db.collection('services').get();
    const rootServices = rootServicesSnap.docs.map(d => ({ 
        id: d.id, 
        data: d.data() 
    }));

    console.log(`Total root services: ${rootServices.length}`);
    console.log('');

    // Show first 5 root services with their category fields
    console.log('First 5 root services:');
    const firstFiveRoots = rootServices.slice(0, 5);
    
    for (const service of firstFiveRoots) {
        const categoryField = service.data.category || service.data.categoryId || 'NONE';
        console.log(`  - Service ID: ${service.id}`);
        console.log(`    category field: ${categoryField}`);
        console.log(`    expected nested path: categories/${categoryField}/services/${service.id}`);
        console.log('');
    }

    // ========================================================================
    // STEP 3: MATCH TEST
    // ========================================================================
    console.log('📋 STEP 3: Matching test...\n');

    let matchedServices = 0;
    let missingServices = 0;
    const matchResults = [];

    // Build a lookup for nested services
    const nestedLookup = new Map();
    for (const nested of allNestedServices) {
        nestedLookup.set(nested.serviceId, nested.categoryId);
    }

    for (const rootService of rootServices) {
        const serviceId = rootService.id;
        
        // Try direct ID match first
        let matched = false;
        let matchedCategory = null;
        
        if (nestedLookup.has(serviceId)) {
            matched = true;
            matchedCategory = nestedLookup.get(serviceId);
        } else {
            // Try matching by category field
            const categoryField = rootService.data.category || rootService.data.categoryId;
            if (categoryField && nestedLookup.has(categoryField)) {
                matched = true;
                matchedCategory = nestedLookup.get(categoryField);
            }
        }

        if (matched) {
            matchedServices++;
            matchResults.push({
                serviceId,
                status: 'MATCHED',
                category: matchedCategory,
                path: `categories/${matchedCategory}/services/${serviceId}`
            });
        } else {
            missingServices++;
            matchResults.push({
                serviceId,
                status: 'MISSING',
                categoryField: rootService.data.category || rootService.data.categoryId || 'NONE'
            });
        }
    }

    console.log('Match results (first 10):');
    matchResults.slice(0, 10).forEach(r => {
        if (r.status === 'MATCHED') {
            console.log(`  ✅ ${r.serviceId} -> ${r.path}`);
        } else {
            console.log(`  ❌ ${r.serviceId} (category field: ${r.categoryField})`);
        }
    });

    // ========================================================================
    // OUTPUT FORMAT
    // ========================================================================
    console.log('');
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  DEBUG RESULT');
    console.log('═══════════════════════════════════════════════════════════\n');
    
    console.log('DEBUG_RESULT:');
    console.log(`  totalNestedServices: ${totalNestedServices}`);
    console.log(`  matchedServices: ${matchedServices}`);
    console.log(`  missingServices: ${missingServices}`);
    console.log(`  sampleNestedPaths: ${sampleNestedServicePaths.length > 0 ? '' : '(none - 0 nested services exist)'}`);
    sampleNestedServicePaths.forEach(p => console.log(`    - ${p}`));
    
    console.log('');
    console.log('Services per category:');
    servicesPerCategory.forEach(s => console.log(`  - ${s.categoryId}: ${s.count}`));
    
    console.log('');
    console.log('═══════════════════════════════════════════════════════════\n');
}

runDebug()
    .then(() => setTimeout(() => process.exit(0), 1000))
    .catch(e => {
        console.error('Error:', e);
        process.exit(1);
    });
