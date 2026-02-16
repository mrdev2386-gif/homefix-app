/**
 * Technician Subcategory to Service Migration Script
 * 
 * This script links every `technician_subcategories` document to the real customer service
 * using `serviceId`. It supports dry-run mode, batch updates, and idempotency.
 */

const admin = require('firebase-admin');
const path = require('path');

// ============================================================================
// CONFIGURATION
// ============================================================================

// Toggle DRY_RUN to false to apply changes to Firestore
const DRY_RUN = true;

// Mapping: technicianSubcategoryId -> serviceId
const SUBCATEGORY_SERVICE_MAP = {
    // Example mappings (Replace with actual IDs from your project)
    'ac_repair_ac_repair': 'ac_service_id_placeholder',
    'cleaning_deep_cleaning': 'cleaning_service_id_placeholder',
    'electrician_wiring': 'electrical_service_id_placeholder',
    'plumber_leakage_repair': 'plumbing_service_id_placeholder',
    // Format: [technician_subcategory_id]: [customer_service_id]
};

// ============================================================================
// INITIALIZATION
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
// MIGRATION LOGIC
// ============================================================================

async function migrate() {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  Technician Subcategory Service-Link Migration');
    console.log(`  DRY RUN: ${DRY_RUN}`);
    console.log('═══════════════════════════════════════════════════════════\n');

    let totalScanned = 0;
    let totalUpdated = 0;
    let totalSkipped = 0;
    let totalMissingMapping = 0;
    let currentBatch = db.batch();
    let opCount = 0;

    try {
        const subSnap = await db.collection('technician_subcategories').get();
        totalScanned = subSnap.size;

        for (const doc of subSnap.docs) {
            const data = doc.data();
            const subId = doc.id;
            const subName = data.name || 'Unknown';

            // 1. Check if serviceId already exists (Idempotency)
            if (data.serviceId) {
                console.log(`⏭️  SKIPPING [${subId}] - serviceId already exists.`);
                totalSkipped++;
                continue;
            }

            // 2. Lookup mapping
            const serviceId = SUBCATEGORY_SERVICE_MAP[subId];

            if (serviceId) {
                console.log(`✅ MAPPED [${subId}] (${subName}) -> ${serviceId}`);

                if (!DRY_RUN) {
                    currentBatch.update(doc.ref, {
                        serviceId: serviceId,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    opCount++;

                    if (opCount >= 400) {
                        await currentBatch.commit();
                        console.log('📦 Batch committed (400 records)');
                        currentBatch = db.batch();
                        opCount = 0;
                    }
                }
                totalUpdated++;
            } else {
                console.warn(`⚠️  WARNING: Missing mapping for subcategory: ${subId} (${subName})`);
                totalMissingMapping++;
            }

            if (totalScanned % 50 === 0) {
                console.log(`Progress: Scanned ${totalScanned} records...`);
            }
        }

        // Final commit if any
        if (!DRY_RUN && opCount > 0) {
            await currentBatch.commit();
            console.log(`📦 Final batch committed (${opCount} records)`);
        }

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('  MIGRATION SUMMARY');
        console.log('═══════════════════════════════════════════════════════════');
        console.log(`  Total Scanned:         ${totalScanned}`);
        console.log(`  Total Updated:         ${totalUpdated}`);
        console.log(`  Total Skipped:         ${totalSkipped}`);
        console.log(`  Total Missing Mapping: ${totalMissingMapping}`);
        console.log('═══════════════════════════════════════════════════════════\n');

        if (DRY_RUN) {
            console.log('⚠️  NO CHANGES WERE APPLIED. Set DRY_RUN = false to execute.');
        } else {
            console.log('🎉 Migration completed successfully.');
        }

    } catch (error) {
        console.error('❌ Migration failed:', error);
    }
}

// ============================================================================
// RUN
// ============================================================================

migrate().then(() => {
    // Keep process alive for a moment to ensure logs are flushed
    setTimeout(() => process.exit(0), 1000);
});
