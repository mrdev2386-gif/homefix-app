/**
 * HomeFix Service Migration Script
 * 
 * Safely migrates services from the root 'services' collection to 
 * categories/{categoryId}/services/{serviceId}
 * 
 * RULES:
 * - Low-impact, idempotent, and production-safe.
 * - Does not delete or modify original root services.
 * - Maps root 'category' field to a document in 'categories' collection.
 */

const admin = require('firebase-admin');

// ============================================================================
// CONFIGURATION
// ============================================================================

// ❌ SET TO false TO EXECUTE MIGRATION
const DRY_RUN = true;

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json'; // Ensure this key is valid for homefix-aa42d
const BATCH_SIZE = 400; // Firebase limit is 500, using 400 for safety

// ============================================================================
// INITIALIZATION
// ============================================================================

if (!admin.apps.length) {
    try {
        const serviceAccount = require(SERVICE_ACCOUNT_PATH);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    } catch (error) {
        console.error('❌ Error loading service account key. Ensure serviceAccountKey.json is present and valid.');
        process.exit(1);
    }
}

const db = admin.firestore();

// ============================================================================
// HELPERS
// ============================================================================

/**
 * Normalizes a category name for mapping
 * Rules: lowercase, trim, remove extra spaces
 */
function normalizeName(name) {
    if (!name) return '';
    return name.toString().toLowerCase().trim().replace(/\s+/g, ' ');
}

// ============================================================================
// MIGRATION LOGIC
// ============================================================================

async function migrateServices() {
    console.log('🚀 Starting Service Migration...');
    console.log(`Mode: ${DRY_RUN ? '🔍 DRY RUN (Manual validation required)' : '⚡ PRODUCTION (Write enabled)'}\n`);

    const stats = {
        totalRootServices: 0,
        totalMigrated: 0,
        totalSkippedAlreadyExists: 0,
        totalMissingCategoryMapping: 0,
        totalErrors: 0
    };

    try {
        // --- PHASE 1: BUILD CATEGORY LOOKUP ---
        console.log('📂 Phase 1: Building Category Lookup Map...');
        const categoriesSnapshot = await db.collection('categories').get();
        const categoryLookup = new Map();
        const duplicateNames = new Set();

        categoriesSnapshot.forEach(doc => {
            const data = doc.data();
            const rawName = data.name || data.title;
            const normalized = normalizeName(rawName);

            if (categoryLookup.has(normalized)) {
                console.error(`❌ Duplicate category name found: "${rawName}" (ID: ${doc.id}). Normalization: "${normalized}"`);
                duplicateNames.add(normalized);
            } else {
                categoryLookup.set(normalized, doc.id);
            }
        });

        // Clean up duplicates to prevent ambiguous mapping
        duplicateNames.forEach(name => categoryLookup.delete(name));
        console.log(`✅ Built map for ${categoryLookup.size} unique categories.\n`);

        // --- PHASE 2 & 3: SCAN AND MIGRATE ---
        console.log('🔎 Phase 2: Scanning Root Services...');
        const rootServicesSnapshot = await db.collection('services').get();
        stats.totalRootServices = rootServicesSnapshot.size;

        let batch = db.batch();
        let opsInBatch = 0;

        for (let i = 0; i < rootServicesSnapshot.docs.length; i++) {
            const doc = rootServicesSnapshot.docs[i];
            const data = doc.data();
            const serviceId = doc.id;
            const rawCategory = data.category;
            const normalizedCategory = normalizeName(rawCategory);

            // Progress log
            if (i > 0 && i % 25 === 0) {
                console.log(`... processed ${i}/${stats.totalRootServices} services`);
            }

            // 1. Check Mapping
            const categoryId = categoryLookup.get(normalizedCategory);
            if (!categoryId) {
                console.warn(`⚠️  Skipping [${serviceId}]: No category mapping for "${rawCategory}"`);
                stats.totalMissingCategoryMapping++;
                continue;
            }

            // 2. Check Existence (Idempotency)
            const targetRef = db.collection('categories').doc(categoryId).collection('services').doc(serviceId);
            const existsSnapshot = await targetRef.get();

            if (existsSnapshot.exists) {
                stats.totalSkippedAlreadyExists++;
                continue;
            }

            // 3. Prepare Migration
            const migratedData = {
                ...data,
                migratedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            if (DRY_RUN) {
                console.log(`[DRY RUN] Would migrate service: "${data.name || serviceId}" -> categories/${categoryId}/services/${serviceId}`);
            } else {
                batch.set(targetRef, migratedData);
                opsInBatch++;

                if (opsInBatch >= BATCH_SIZE) {
                    await commitBatch(batch);
                    batch = db.batch();
                    opsInBatch = 0;
                }
            }
            stats.totalMigrated++;
        }

        // Commit final batch
        if (!DRY_RUN && opsInBatch > 0) {
            await commitBatch(batch);
        }

        console.log('\n==================================================');
        console.log('SUMMARY:');
        console.log(`totalRootServices: ${stats.totalRootServices}`);
        console.log(`totalMigrated: ${stats.totalMigrated}`);
        console.log(`totalSkippedAlreadyExists: ${stats.totalSkippedAlreadyExists}`);
        console.log(`totalMissingCategoryMapping: ${stats.totalMissingCategoryMapping}`);
        console.log(`totalErrors: ${stats.totalErrors}`);
        console.log('==================================================\n');

    } catch (error) {
        console.error('🔥 Fatal error during migration:', error);
        stats.totalErrors++;
    }
}

async function commitBatch(batch) {
    try {
        await batch.commit();
        console.log('📦 Batch write successful.');
    } catch (error) {
        console.error('❌ Batch write failed:', error);
        throw error;
    }
}

// ============================================================================
// VERIFICATION HELPER
// ============================================================================

/**
 * Counts nested services and compares with root.
 * List services that are still pending.
 */
async function verifyNestedServices() {
    console.log('🔍 Running Verification Helper...');
    const rootSnapshot = await db.collection('services').get();
    const rootIds = rootSnapshot.docs.map(d => d.id);

    let totalNested = 0;
    const foundNestedIds = new Set();

    const categoriesSnapshot = await db.collection('categories').get();
    for (const catDoc of categoriesSnapshot.docs) {
        const nestedSnapshot = await catDoc.ref.collection('services').get();
        totalNested += nestedSnapshot.size;
        nestedSnapshot.forEach(d => foundNestedIds.add(d.id));
    }

    const unmigrated = rootIds.filter(id => !foundNestedIds.has(id));

    console.log('\n--- VERIFICATION REPORT ---');
    console.log(`Root Services: ${rootSnapshot.size}`);
    console.log(`Total Nested Services found: ${totalNested}`);
    console.log(`Coverage: ${((foundNestedIds.size / rootSnapshot.size) * 100).toFixed(2)}%`);

    if (unmigrated.length > 0) {
        console.log(`\nPending Migration (${unmigrated.length}):`);
        unmigrated.forEach(id => console.log(` - ${id}`));
    } else {
        console.log('\n✅ All root services successfully mapped to nested structure.');
    }
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================

async function main() {
    await migrateServices();

    // To run verification, uncomment below:
    // await verifyNestedServices();
}

main();
