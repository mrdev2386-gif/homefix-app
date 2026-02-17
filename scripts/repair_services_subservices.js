/**
 * HomeFix Firestore Repair Agent
 * 
 * GOAL: Fix all services that have fewer than 7 subServices
 * 
 * Path: services/{serviceId}/subServices/{subServiceId}
 * 
 * Rules:
 * - DO NOT modify services that already have ≥7 subServices
 * - Only add missing subServices to reach minimum 7
 * - Each subService must include:
 *   - name (string)
 *   - price (number > 0)
 *   - imageUrl (valid https image)
 *   - isActive: true
 *   - durationMins (number)
 *   - createdAt (serverTimestamp)
 * - Use batch writes (≤500 per batch)
 * - Ensure unique subServiceIds per service
 */

const admin = require('firebase-admin');
const path = require('path');

// ============================================================================
// CONFIGURATION
// ============================================================================

const TARGET_MIN_SUB_SERVICES = 7;
const BATCH_SIZE = 500;

const DEFAULT_SUB_SERVICES = {
    ac: [
        { name: 'Split AC Service', price: 599, durationMins: 60 },
        { name: 'Window AC Service', price: 499, durationMins: 45 },
        { name: 'Central AC Service', price: 1499, durationMins: 90 },
        { name: 'AC Gas Refill', price: 899, durationMins: 30 },
        { name: 'AC Installation', price: 1999, durationMins: 120 },
        { name: 'AC Uninstallation', price: 999, durationMins: 90 },
        { name: 'AC Repair & Maintenance', price: 699, durationMins: 60 },
    ],
    plumbing: [
        { name: 'Leakage Repair', price: 399, durationMins: 45 },
        { name: 'Tap & Faucet Repair', price: 299, durationMins: 30 },
        { name: 'Toilet Repair', price: 499, durationMins: 60 },
        { name: 'Pipe Fitting', price: 599, durationMins: 60 },
        { name: 'Drain Cleaning', price: 449, durationMins: 45 },
        { name: 'Water Tank Cleaning', price: 799, durationMins: 90 },
        { name: 'Bathroom Fitting', price: 1299, durationMins: 120 },
    ],
    electrician: [
        { name: 'Switch & Socket Repair', price: 249, durationMins: 30 },
        { name: 'MCB Repair', price: 399, durationMins: 30 },
        { name: 'Wiring Repair', price: 499, durationMins: 45 },
        { name: 'Fan Installation', price: 349, durationMins: 45 },
        { name: 'Light Fitting', price: 199, durationMins: 20 },
        { name: 'Wiring New Points', price: 599, durationMins: 60 },
        { name: 'Electrical Inspection', price: 399, durationMins: 45 },
    ],
    cleaning: [
        { name: 'Home Deep Cleaning', price: 2499, durationMins: 180 },
        { name: 'Kitchen Cleaning', price: 999, durationMins: 90 },
        { name: 'Bathroom Cleaning', price: 699, durationMins: 60 },
        { name: 'Sofa Cleaning', price: 799, durationMins: 60 },
        { name: 'Carpet Cleaning', price: 599, durationMins: 45 },
        { name: 'Window Cleaning', price: 449, durationMins: 45 },
        { name: 'Move-in/Move-out Cleaning', price: 2999, durationMins: 240 },
    ],
    appliances: [
        { name: 'Washing Machine Repair', price: 349, durationMins: 45 },
        { name: 'Refrigerator Repair', price: 399, durationMins: 45 },
        { name: 'Microwave Repair', price: 299, durationMins: 30 },
        { name: 'TV Repair', price: 349, durationMins: 45 },
        { name: 'Dishwasher Repair', price: 449, durationMins: 60 },
        { name: 'Geyser Repair', price: 399, durationMins: 45 },
        { name: 'Water Purifier Service', price: 349, durationMins: 45 },
    ],
    salon: [
        { name: 'Haircut', price: 299, durationMins: 30 },
        { name: 'Shaving', price: 149, durationMins: 15 },
        { name: 'Facial', price: 799, durationMins: 60 },
        { name: 'Manicure', price: 399, durationMins: 45 },
        { name: 'Pedicure', price: 449, durationMins: 45 },
        { name: 'Hair Spa', price: 999, durationMins: 60 },
        { name: 'Body Massage', price: 1499, durationMins: 90 },
    ],
    pest_control: [
        { name: 'Cockroach Treatment', price: 799, durationMins: 60 },
        { name: 'Bed Bug Treatment', price: 1499, durationMins: 90 },
        { name: 'Termite Treatment', price: 2499, durationMins: 120 },
        { name: 'Rodent Control', price: 999, durationMins: 60 },
        { name: 'Mosquito Treatment', price: 699, durationMins: 45 },
        { name: 'Fly Control', price: 599, durationMins: 45 },
        { name: 'General Pest Control', price: 899, durationMins: 60 },
    ],
    painting: [
        { name: 'Interior Painting', price: 25, durationMins: 480 },
        { name: 'Exterior Painting', price: 30, durationMins: 480 },
        { name: 'Wall Putty', price: 12, durationMins: 240 },
        { name: 'Texture Painting', price: 45, durationMins: 360 },
        { name: 'Waterproofing', price: 35, durationMins: 180 },
        { name: 'Pop Ceiling', price: 55, durationMins: 240 },
        { name: 'Paint Touch-up', price: 399, durationMins: 60 },
    ],
    carpentry: [
        { name: 'Furniture Repair', price: 499, durationMins: 60 },
        { name: 'Furniture Assembly', price: 399, durationMins: 45 },
        { name: 'Almirah Repair', price: 599, durationMins: 60 },
        { name: 'Door Repair', price: 449, durationMins: 45 },
        { name: 'Window Repair', price: 399, durationMins: 45 },
        { name: 'Modular Kitchen Install', price: 2999, durationMins: 240 },
        { name: 'Wardrobe Installation', price: 1999, durationMins: 180 },
    ],
    ro_service: [
        { name: 'RO Installation', price: 499, durationMins: 45 },
        { name: 'RO Servicing', price: 399, durationMins: 45 },
        { name: 'RO Filter Change', price: 599, durationMins: 45 },
        { name: 'RO Repair', price: 449, durationMins: 60 },
        { name: 'RO AMC', price: 1499, durationMins: 60 },
        { name: 'UV Lamp Replacement', price: 799, durationMins: 30 },
        { name: 'Tank Cleaning', price: 349, durationMins: 30 },
    ],
    generic: [
        { name: 'Basic Service', price: 399, durationMins: 30 },
        { name: 'Standard Service', price: 799, durationMins: 45 },
        { name: 'Premium Service', price: 1299, durationMins: 60 },
        { name: 'Advanced Service', price: 1899, durationMins: 90 },
        { name: 'Inspection Visit', price: 199, durationMins: 20 },
        { name: 'Emergency Repair', price: 1499, durationMins: 60 },
        { name: 'Annual Maintenance', price: 2499, durationMins: 120 },
    ]
};

const FALLBACK_IMAGE_URLS = {
    ac: 'https://images.unsplash.com/photo-1631545806609-5adb40c6e3eb?w=400&q=80',
    plumbing: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400&q=80',
    electrician: 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=400&q=80',
    cleaning: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80',
    appliances: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&q=80',
    salon: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80',
    pest_control: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=400&q=80',
    painting: 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80',
    carpentry: 'https://images.unsplash.com/photo-1611486212557-88be5ff6f941?w=400&q=80',
    ro_service: 'https://images.unsplash.com/photo-1538300342682-cf57afb97285?w=400&q=80',
    generic: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80'
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
// UTILITY FUNCTIONS
// ============================================================================

function getCategoryFromService(serviceName) {
    const name = serviceName.toLowerCase();
    if (name.includes('ac') || name.includes('air conditioner') || name.includes('cooling')) return 'ac';
    if (name.includes('plumb') || name.includes('pipe') || name.includes('drain') || name.includes('leak')) return 'plumbing';
    if (name.includes('electric') || name.includes('wiring') || name.includes('fan') || name.includes('light')) return 'electrician';
    if (name.includes('clean') || name.includes('wash')) return 'cleaning';
    if (name.includes('appliance') || name.includes('washing') || name.includes('fridge') || name.includes('microwave') || name.includes('tv')) return 'appliances';
    if (name.includes('salon') || name.includes('spa') || name.includes('haircut') || name.includes('facial')) return 'salon';
    if (name.includes('pest') || name.includes('cockroach') || name.includes('termite')) return 'pest_control';
    if (name.includes('paint') || name.includes('wall')) return 'painting';
    if (name.includes('carpenter') || name.includes('wood') || name.includes('furniture')) return 'carpentry';
    if (name.includes('ro') || name.includes('water purifier') || name.includes('purifier')) return 'ro_service';
    return 'generic';
}

function getTemplates(serviceName) {
    const category = getCategoryFromService(serviceName);
    return DEFAULT_SUB_SERVICES[category] || DEFAULT_SUB_SERVICES.generic;
}

function getImageUrl(serviceName, serviceImageUrl) {
    if (serviceImageUrl && typeof serviceImageUrl === 'string' && serviceImageUrl.startsWith('http')) {
        return serviceImageUrl;
    }
    const category = getCategoryFromService(serviceName);
    return FALLBACK_IMAGE_URLS[category] || FALLBACK_IMAGE_URLS.generic;
}

function generateSubServiceId(serviceId, name) {
    const slug = name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
    const uniqueSuffix = Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
    return `${serviceId}_${slug}_${uniqueSuffix}`;
}

// ============================================================================
// MAIN REPAIR LOGIC
// ============================================================================

async function runRepair() {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  HomeFix Firestore Repair Agent');
    console.log('  Ensuring all services have ≥7 subServices');
    console.log('═══════════════════════════════════════════════════════════\n');

    let servicesScanned = 0;
    let servicesFixed = 0;
    let subServicesAdded = 0;
    let servicesStillBelowMinimum = 0;
    let servicesAlreadyOK = 0;

    const batch = db.batch();
    let opCount = 0;

    // Scan services collection at path: services/{serviceId}
    console.log('=== Scanning services collection ===\n');
    const servicesSnap = await db.collection('services').get();
    console.log(`Found ${servicesSnap.size} services\n`);

    for (const serviceDoc of servicesSnap.docs) {
        servicesScanned++;
        
        const serviceData = serviceDoc.data();
        const serviceId = serviceDoc.id;
        const serviceName = serviceData.name || serviceData.title || serviceId;
        
        // Count existing sub-services at path: services/{serviceId}/subServices
        const subServicesSnap = await serviceDoc.ref.collection('subServices').get();
        const existingCount = subServicesSnap.size;
        
        // Get existing subService names to avoid duplicates
        const existingNames = new Set(subServicesSnap.docs.map(d => d.data().name?.toLowerCase()));
        const existingIds = new Set(subServicesSnap.docs.map(d => d.id));

        console.log(`[${serviceName}] - Current subServices: ${existingCount}`);

        if (existingCount >= TARGET_MIN_SUB_SERVICES) {
            console.log(`  ⏭️  SKIP - Already has ${existingCount} subServices (≥${TARGET_MIN_SUB_SERVICES})\n`);
            servicesAlreadyOK++;
            continue;
        }

        // Need to add more subServices
        const templates = getTemplates(serviceName);
        let addedInThisService = 0;
        const needed = TARGET_MIN_SUB_SERVICES - existingCount;

        console.log(`  🛠️  FIXING - Need to add ${needed} more subServices...`);

        for (const template of templates) {
            if (addedInThisService >= needed) break;

            // Skip if a subService with same name already exists
            if (existingNames.has(template.name.toLowerCase())) {
                console.log(`    ⏭️  Skipping "${template.name}" - already exists`);
                continue;
            }

            // Generate unique ID
            let subServiceId = generateSubServiceId(serviceId, template.name);
            let counter = 0;
            while (existingIds.has(subServiceId)) {
                subServiceId = generateSubServiceId(serviceId, template.name + '_' + counter);
                counter++;
            }
            existingIds.add(subServiceId);

            const subRef = serviceDoc.ref.collection('subServices').doc(subServiceId);

            const newSubData = {
                id: subServiceId,
                name: template.name,
                price: template.price,
                imageUrl: getImageUrl(serviceName, serviceData.imageUrl || serviceData.image),
                isActive: true,
                durationMins: template.durationMins,
                order: (existingCount + addedInThisService + 1) * 10,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            };

            batch.set(subRef, newSubData);
            opCount++;
            addedInThisService++;
            subServicesAdded++;

            console.log(`    + Added: "${template.name}" (₹${template.price}, ${template.durationMins} mins)`);
        }

        servicesFixed++;
        console.log(`  ✅ Added ${addedInThisService} subServices to [${serviceName}]\n`);

        // Commit batch when reaching limit
        if (opCount >= BATCH_SIZE) {
            await batch.commit();
            console.log(`📦 Batch committed (${opCount} records)\n`);
            
            // Start new batch
            const newBatch = db.batch();
            opCount = 0;
        }
    }

    // Final batch commit
    if (opCount > 0) {
        await batch.commit();
        console.log(`📦 Final batch committed (${opCount} records)\n`);
    }

    // ============================================================================
    // REPAIR RESULT
    // ============================================================================
    
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  REPAIR RESULT');
    console.log('═══════════════════════════════════════════════════════════');
    console.log(`  servicesFixed:              ${servicesFixed}`);
    console.log(`  subServicesAdded:           ${subServicesAdded}`);
    console.log(`  servicesStillBelowMinimum:  ${servicesStillBelowMinimum}`);
    console.log('═══════════════════════════════════════════════════════════\n');

    // Validation check
    if (servicesStillBelowMinimum > 0) {
        console.log(`⚠️  WARNING: ${servicesStillBelowMinimum} services still below minimum!`);
    } else {
        console.log('✅ SUCCESS: All services now have ≥7 subServices!');
    }

    return { servicesFixed, subServicesAdded, servicesStillBelowMinimum };
}

// ============================================================================
// RUN
// ============================================================================

runRepair()
    .then(result => {
        console.log('\n📊 Final Result:', JSON.stringify(result, null, 2));
        setTimeout(() => process.exit(0), 2000);
    })
    .catch(error => {
        console.error('❌ Error during repair:', error);
        process.exit(1);
    });
