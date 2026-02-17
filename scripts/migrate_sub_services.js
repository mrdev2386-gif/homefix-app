/**
 * HomeFix Sub-Services Migration Script
 * 
 * Copies subServices from root services to nested services structure.
 * 
 * SOURCE: services/{serviceId}/subServices/{subServiceId}
 * TARGET: categories/{categoryId}/services/{serviceId}/subServices/{subServiceId}
 * 
 * Features:
 * - DRY_RUN support (default: true)
 * - Batch writes for efficiency
 * - Idempotent (skips existing nested subServices)
 * - Preserves all fields
 * - Adds migration metadata
 */

const admin = require('firebase-admin');
const path = require('path');

// ============================================================================
// 1. CONFIGURATION
// ============================================================================

// Set to false to actually perform the migration
const DRY_RUN = process.argv.includes('--execute') ? false : true;
const BATCH_SIZE = 400;

// Category name to ID mapping (normalized for matching)
const CATEGORY_NAME_TO_ID_MAP = {
    'cleaning': 'cleaning',
    'repair': 'repair',
    'renovation': 'renovation',
    'personal care': 'personal_care',
    'appliance': 'repair',  // Map Appliance to Repair (fallback)
    'appliances': 'repair'
};

// ============================================================================
// 2. INITIALIZATION
// ============================================================================

const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');

if (!admin.apps.length) {
    try {
        const serviceAccount = require(SERVICE_ACCOUNT_PATH);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    } catch (e) {
        console.error('❌ Error: Missing serviceAccountKey.json in scripts folder.');
        process.exit(1);
    }
}

const db = admin.firestore();

// ============================================================================
// 3. MIGRATION LOGIC
// ============================================================================

/**
 * Get all categories from Firestore
 */
async function getCategories() {
    const snapshot = await db.collection('categories').get();
    return snapshot.docs.map(doc => ({ id: doc.id, data: doc.data() }));
}

/**
 * Get all root-level services
 */
async function getRootServices() {
    const snapshot = await db.collection('services').get();
    return snapshot.docs.map(doc => ({ id: doc.id, data: doc.data() }));
}

/**
 * Get subServices from a service path
 */
async function getSubServices(servicePath) {
    const snapshot = await db.doc(servicePath).collection('subServices').get();
    return snapshot.docs.map(doc => ({ id: doc.id, data: doc.data() }));
}

/**
 * Resolve category from root service data
 * Returns category ID that exists in Firestore
 */
function resolveCategoryId(serviceData) {
    const categoryField = serviceData.category || serviceData.categoryId || '';
    const normalizedCategory = categoryField.toLowerCase().trim();
    
    // Direct mapping lookup
    if (CATEGORY_NAME_TO_ID_MAP[normalizedCategory]) {
        return CATEGORY_NAME_TO_ID_MAP[normalizedCategory];
    }
    
    // Partial matching
    for (const [key, value] of Object.entries(CATEGORY_NAME_TO_ID_MAP)) {
        if (normalizedCategory.includes(key) || key.includes(normalizedCategory)) {
            return value;
        }
    }
    
    return null;
}

/**
 * Copy a subService to the nested path with migration metadata
 */
async function copySubService(rootSubService, targetPath, batch) {
    const subServiceData = rootSubService.data;
    
    // Add migration metadata
    const newData = {
        ...subServiceData,
        migratedFromRoot: true,
        migratedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    const targetRef = db.doc(targetPath).collection('subServices').doc(rootSubService.id);
    batch.set(targetRef, newData);
    
    return targetRef;
}

/**
 * Main migration function
 */
async function runMigration() {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  HomeFix Sub-Services Migration');
    console.log(`  MODE: ${DRY_RUN ? 'DRY RUN (no changes)' : 'EXECUTE (will write)'}`);
    console.log('═══════════════════════════════════════════════════════════\n');

    // Statistics
    let totalRootSubServices = 0;
    let totalCopied = 0;
    let totalSkippedExisting = 0;
    let totalErrors = 0;
    const errors = [];

    // Step 1: Get all categories
    console.log('📋 Step 1: Loading categories...');
    const categories = await getCategories();
    console.log(`   Found ${categories.length} categories\n`);

    // Step 2: Get all root services
    console.log('📋 Step 2: Loading root services...');
    const rootServices = await getRootServices();
    console.log(`   Found ${rootServices.length} root services\n`);

    // Step 3: Build category->service mapping for matching
    console.log('📋 Step 3: Building nested service index...');
    const nestedServiceIndex = new Map(); // categoryId -> Map<serviceId, serviceRef>
    
    for (const category of categories) {
        const servicesSnapshot = await db.collection(`categories/${category.id}/services`).get();
        for (const serviceDoc of servicesSnapshot.docs) {
            if (!nestedServiceIndex.has(category.id)) {
                nestedServiceIndex.set(category.id, new Map());
            }
            nestedServiceIndex.get(category.id).set(serviceDoc.id, {
                id: serviceDoc.id,
                data: serviceDoc.data(),
                ref: serviceDoc.ref
            });
        }
    }
    console.log(`   Indexed ${nestedServiceIndex.size} categories with services\n`);

    // Step 4: Process each root service
    console.log('📋 Step 4: Processing root services...\n');
    
    const batch = db.batch();
    let batchOpCount = 0;

    for (const rootService of rootServices) {
        const serviceId = rootService.id;
        const serviceName = rootService.data.name || rootService.data.title || serviceId;
        
        console.log(`🔍 Processing root service: [${serviceName}] (${serviceId})`);
        
        // Get root subServices
        const rootSubServices = await getSubServices(`services/${serviceId}`);
        const rootSubServiceCount = rootSubServices.length;
        totalRootSubServices += rootSubServiceCount;
        
        console.log(`   Root subServices count: ${rootSubServiceCount}`);
        
        if (rootSubServiceCount === 0) {
            console.log(`   ⏭️  No root subServices to migrate\n`);
            continue;
        }

        // Find this service in nested structure
        let foundInCategory = null;
        let nestedService = null;
        let categoryField = rootService.data.category || rootService.data.categoryId || null;
        
        for (const [categoryId, servicesMap] of nestedServiceIndex.entries()) {
            if (servicesMap.has(serviceId)) {
                foundInCategory = categoryId;
                nestedService = servicesMap.get(serviceId);
                break;
            }
        }

        if (!foundInCategory || !nestedService) {
            // Try using category field mapping
            if (categoryField) {
                const mappedCategoryId = resolveCategoryId(rootService.data);
                if (mappedCategoryId && nestedServiceIndex.has(mappedCategoryId)) {
                    const servicesMap = nestedServiceIndex.get(mappedCategoryId);
                    if (servicesMap.has(serviceId)) {
                        foundInCategory = mappedCategoryId;
                        nestedService = servicesMap.get(serviceId);
                    }
                }
            }
        }

        if (!foundInCategory || !nestedService) {
            console.log(`   ⚠️  No matching nested service found - skipping`);
            if (categoryField) {
                console.log(`      (tried category field: "${categoryField}")`);
            }
            console.log('');
            continue;
        }

        console.log(`   ✅ Found in category: [${foundInCategory}]`);

        // Check existing nested subServices
        const nestedSubServices = await getSubServices(`categories/${foundInCategory}/services/${serviceId}`);
        const existingNestedIds = new Set(nestedSubServices.map(s => s.id));
        
        console.log(`   Existing nested subServices: ${existingNestedIds.size}`);

        // Copy missing subServices
        let copiedForThisService = 0;
        let skippedForThisService = 0;

        for (const rootSubService of rootSubServices) {
            const subServiceId = rootSubService.id;
            
            if (existingNestedIds.has(subServiceId)) {
                // Already exists - skip
                skippedForThisService++;
                totalSkippedExisting++;
            } else {
                // Need to copy
                const targetPath = `categories/${foundInCategory}/services/${serviceId}`;
                
                if (!DRY_RUN) {
                    await copySubService(rootSubService, targetPath, batch);
                    batchOpCount++;
                    
                    // Commit batch if full
                    if (batchOpCount >= BATCH_SIZE) {
                        await batch.commit();
                        console.log(`   📦 Batch committed (${batchOpCount} operations)`);
                        batchOpCount = 0;
                    }
                }
                
                copiedForThisService++;
                totalCopied++;
            }
        }

        console.log(`   📝 Copy plan: ${copiedForThisService} to copy, ${skippedForThisService} existing`);
        
        if (DRY_RUN && copiedForThisService > 0) {
            console.log(`   [DRY RUN] Would copy ${copiedForThisService} subServices to [${foundInCategory}]/services/${serviceId}:`);
            for (const rootSubService of rootSubServices) {
                if (!existingNestedIds.has(rootSubService.id)) {
                    const name = rootSubService.data?.name || rootSubService.id;
                    console.log(`      + ${name}`);
                }
            }
        }
        
        console.log('');
    }

    // Commit remaining batch operations
    if (!DRY_RUN && batchOpCount > 0) {
        await batch.commit();
        console.log(`📦 Final batch committed (${batchOpCount} operations)\n`);
    }

    // Step 5: Verify nested structure
    console.log('📋 Step 5: Verifying nested structure...\n');
    
    let totalNestedSubServices = 0;
    let servicesWithHealthySubServices = 0;

    for (const category of categories) {
        const servicesSnapshot = await db.collection(`categories/${category.id}/services`).get();
        
        for (const serviceDoc of servicesSnapshot.docs) {
            const subServicesSnapshot = await serviceDoc.ref.collection('subServices').get();
            const count = subServicesSnapshot.size;
            totalNestedSubServices += count;
            
            if (count > 0) {
                servicesWithHealthySubServices++;
            }
        }
    }

    // ============================================================================
    // OUTPUT SUMMARY
    // ============================================================================
    
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  MIGRATION SUMMARY');
    console.log('═══════════════════════════════════════════════════════════\n');
    
    console.log('SUBSERVICE_MIGRATION:');
    console.log(`  totalRootSubServices: ${totalRootSubServices}`);
    console.log(`  totalCopied: ${DRY_RUN ? '(see dry run output)' : totalCopied}`);
    console.log(`  totalSkippedExisting: ${totalSkippedExisting}`);
    console.log(`  totalErrors: ${totalErrors}`);
    console.log('');
    
    console.log('NESTED_VERIFICATION:');
    console.log(`  totalNestedSubServices: ${totalNestedSubServices}`);
    console.log(`  servicesWithHealthySubServices: ${servicesWithHealthySubServices}`);
    console.log('');
    
    if (errors.length > 0) {
        console.log('ERRORS:');
        errors.forEach(e => console.log(`  - ${e}`));
        console.log('');
    }

    console.log('═══════════════════════════════════════════════════════════');
    console.log(`  Mode: ${DRY_RUN ? 'DRY RUN COMPLETE' : 'MIGRATION COMPLETE'}`);
    console.log('═══════════════════════════════════════════════════════════\n');

    if (DRY_RUN) {
        console.log('💡 To execute the migration, run:');
        console.log('   node scripts/migrate_sub_services.js --execute\n');
    }

    return {
        totalRootSubServices,
        totalCopied,
        totalSkippedExisting,
        totalErrors,
        totalNestedSubServices,
        servicesWithHealthySubServices
    };
}

// ============================================================================
// 4. RUN
// ============================================================================

runMigration()
    .then(() => {
        setTimeout(() => process.exit(0), 1000);
    })
    .catch(error => {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    });
