/**
 * HomeFix Service Catalog Enrichment Script
 * 
 * Target: Ensure every customer-facing service has at least 4-5 sub-services.
 * Path: categories/{categoryId}/services/{serviceId}/subServices/{subServiceId}
 * 
 * Features:
 * - Idempotent creation of missing sub-services
 * - Smart templates based on service name
 * - Image fallback logic
 * - Technician coverage validation
 * - Dry-run mode for safety
 */

const admin = require('firebase-admin');
const path = require('path');

// ============================================================================
// 1. CONFIGURATION
// ============================================================================

const DRY_RUN = true; // SET TO FALSE TO APPLY CHANGES
const TARGET_SUB_SERVICE_COUNT = 5; // We aim for 5 sub-services per service
const MIN_REQUIRED_COUNT = 4; // Skip if already has this many

const DEFAULT_SUB_SERVICES = {
    ac: [
        { name: 'General Service', price: 499 },
        { name: 'Deep Service', price: 999 },
        { name: 'Gas Refill', price: 1499 },
        { name: 'Repair Visit', price: 299 },
        { name: 'Installation', price: 1999 },
        { name: 'Cleaning & Sanitization', price: 799 },
    ],
    cleaning: [
        { name: 'Basic Cleaning', price: 599 },
        { name: 'Deep Cleaning', price: 1299 },
        { name: 'Premium Cleaning', price: 1999 },
        { name: 'Move-in Cleaning', price: 2499 },
        { name: 'Sanitization', price: 799 },
        { name: 'Express Cleaning', price: 399 },
    ],
    generic: [
        { name: 'Basic Service', price: 399 },
        { name: 'Standard Service', price: 799 },
        { name: 'Premium Service', price: 1299 },
        { name: 'Advanced Service', price: 1899 },
        { name: 'Inspection Visit', price: 199 },
        { name: 'Emergency Repair', price: 1499 },
    ]
};

const FALLBACK_IMAGE_URL = 'https://images.unsplash.com/photo-1581578731117-104f2a41272c?auto=format&fit=crop&q=80&w=800';

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
// 3. UTILITY FUNCTIONS
// ============================================================================

/**
 * Selects the best sub-service templates based on service name
 */
function getTemplates(serviceName) {
    const name = serviceName.toLowerCase();
    if (name.includes('ac') || name.includes('air conditioner') || name.includes('cooling')) {
        return DEFAULT_SUB_SERVICES.ac;
    }
    if (name.includes('clean') || name.includes('wash') || name.includes('saniti')) {
        return DEFAULT_SUB_SERVICES.cleaning;
    }
    return DEFAULT_SUB_SERVICES.generic;
}

/**
 * Returns a valid imageUrl for a sub-service
 */
function getImageUrl(serviceImageUrl) {
    if (serviceImageUrl && typeof serviceImageUrl === 'string' && serviceImageUrl.startsWith('http')) {
        return serviceImageUrl;
    }
    return FALLBACK_IMAGE_URL;
}

/**
 * Generates a unique-ish ID for a sub-service
 */
function generateId(serviceId, name) {
    const slug = name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
    // Return a combination to avoid global collisions if any
    return `${serviceId}_${slug}`;
}

// ============================================================================
// 4. MIGRATION LOGIC
// ============================================================================

async function runEnrichment() {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  HomeFix Service Sub-Service Enrichment');
    console.log(`  DRY RUN: ${DRY_RUN}`);
    console.log('═══════════════════════════════════════════════════════════\n');

    let servicesScanned = 0;
    let servicesUpdated = 0;
    let subServicesCreated = 0;
    let servicesSkipped = 0;

    const batch = db.batch();
    let opCount = 0;

    try {
        const categoriesSnap = await db.collection('categories').get();

        for (const catDoc of categoriesSnap.docs) {
            const servicesSnap = await catDoc.ref.collection('services').get();

            for (const serviceDoc of servicesSnap.docs) {
                servicesScanned++;
                const serviceData = serviceDoc.data();
                const serviceId = serviceDoc.id;
                const serviceName = serviceData.name || serviceData.title || 'Unnamed Service';

                // Count existing sub-services
                const existingSubSnap = await serviceDoc.ref.collection('subServices').get();
                const existingCount = existingSubSnap.size;
                const existingNames = new Set(existingSubSnap.docs.map(d => d.data().name?.toLowerCase()));

                if (existingCount >= MIN_REQUIRED_COUNT) {
                    console.log(`⏭️  SKIPPING [${serviceName}] - Already has ${existingCount} sub-services.`);
                    servicesSkipped++;
                    continue;
                }

                console.log(`🛠️  ENRICHING [${serviceName}] - Current count: ${existingCount}`);

                const templates = getTemplates(serviceName);
                let addedInThisService = 0;

                for (const template of templates) {
                    if (existingCount + addedInThisService >= TARGET_SUB_SERVICE_COUNT) break;

                    // Avoid duplicate names
                    if (existingNames.has(template.name.toLowerCase())) continue;

                    const subId = generateId(serviceId, template.name);
                    const subRef = serviceDoc.ref.collection('subServices').doc(subId);

                    const newSubData = {
                        id: subId,
                        name: template.name,
                        imageUrl: getImageUrl(serviceData.imageUrl || serviceData.image),
                        price: template.price,
                        order: (existingCount + addedInThisService + 1) * 10,
                        isActive: true,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    };

                    if (!DRY_RUN) {
                        batch.set(subRef, newSubData);
                        opCount++;

                        if (opCount >= BATCH_SIZE) {
                            await batch.commit();
                            console.log('📦 Batch committed (400 records)');
                            batch = db.batch();
                            opCount = 0;
                        }
                    }

                    addedInThisService++;
                    subServicesCreated++;
                }

                if (addedInThisService > 0) {
                    servicesUpdated++;
                    console.log(`   + Added ${addedInThisService} sub-services.`);
                }

                if (servicesScanned % 25 === 0) {
                    console.log(`Progress: Scanned ${servicesScanned} services...`);
                }
            }
        }

        if (!DRY_RUN && opCount > 0) {
            await batch.commit();
            console.log(`📦 Final batch committed (${opCount} records)`);
        }

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('  ENRICHMENT SUMMARY');
        console.log('═══════════════════════════════════════════════════════════');
        console.log(`  Services Scanned:      ${servicesScanned}`);
        console.log(`  Services Updated:      ${servicesUpdated}`);
        console.log(`  Sub-Services Created:  ${subServicesCreated}`);
        console.log(`  Services Skipped:      ${servicesSkipped}`);
        console.log('═══════════════════════════════════════════════════════════\n');

        // Run technician alignment check
        await verifyTechnicianCoverage();

    } catch (error) {
        console.error('❌ Enrichment failed:', error);
    }
}

// ============================================================================
// 5. TECHNICIAN ALIGNMENT CHECK
// ============================================================================

async function verifyTechnicianCoverage() {
    console.log('🔍 Running Technician Alignment Check...');

    try {
        // 1. Collect all serviceIds from technicians
        const techSnap = await db.collection('technicians').get();
        const uniqueServiceIds = new Set();

        techSnap.forEach(doc => {
            const data = doc.data();
            if (Array.isArray(data.serviceIds)) {
                data.serviceIds.forEach(id => uniqueServiceIds.add(id));
            }
        });

        console.log(`   Uncovered ${uniqueServiceIds.size} unique service IDs across all technicians.`);

        // 2. Map all services to their subService counts
        const serviceCoverage = new Map();
        const categoriesSnap = await db.collection('categories').get();

        for (const catDoc of categoriesSnap.docs) {
            const servicesSnap = await catDoc.ref.collection('services').get();
            for (const serviceDoc of servicesSnap.docs) {
                const subSnap = await serviceDoc.ref.collection('subServices').get();
                serviceCoverage.set(serviceDoc.id, {
                    name: serviceDoc.data().name || serviceDoc.data().title || serviceDoc.id,
                    subCount: subSnap.size
                });
            }
        }

        // 3. Compare and warn
        let gapsFound = 0;
        uniqueServiceIds.forEach(serviceId => {
            const info = serviceCoverage.get(serviceId);
            if (!info) {
                console.warn(`🚨 WARNING: Technician is linked to service [${serviceId}] but this service DOES NOT exist in categories tree!`);
                gapsFound++;
            } else if (info.subCount < MIN_REQUIRED_COUNT) {
                console.warn(`🚨 WARNING: Service [${info.name}] (${serviceId}) has only ${info.subCount} sub-services. Technicians may have suboptimal matching.`);
                gapsFound++;
            }
        });

        if (gapsFound === 0) {
            console.log('✅ All technician-linked services meet the sub-service quota.');
        } else {
            console.log(`⚠️ Finished check with ${gapsFound} warnings found.`);
        }

    } catch (error) {
        console.error('❌ Technician alignment check failed:', error);
    }
}

// ============================================================================
// 6. RUN
// ============================================================================

runEnrichment().then(() => {
    setTimeout(() => process.exit(0), 1000);
});
