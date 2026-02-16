const admin = require('firebase-admin');

// IMPORTANT: Ensure you have GOOGLE_APPLICATION_CREDENTIALS set or are logged in with firebase login
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();

const FALLBACK_MAP = {
    'ac': 'https://images.unsplash.com/photo-1631545806609-5adb40c6e3eb?w=400&q=80',
    'air': 'https://images.unsplash.com/photo-1631545806609-5adb40c6e3eb?w=400&q=80',
    'plumb': 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400&q=80',
    'electric': 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=400&q=80',
    'clean': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80',
    'house': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80',
    'appliance': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&q=80',
    'repair': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&q=80',
    'salon': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80',
    'beauty': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80',
    'pest': 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=400&q=80',
    'paint': 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80',
    'carpenter': 'https://images.unsplash.com/photo-1611486212557-88be5ff6f941?w=400&q=80',
    'wood': 'https://images.unsplash.com/photo-1611486212557-88be5ff6f941?w=400&q=80',
    'water': 'https://images.unsplash.com/photo-1538300342682-cf57afb97285?w=400&q=80',
    'ro': 'https://images.unsplash.com/photo-1538300342682-cf57afb97285?w=400&q=80',
    'default': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80'
};

function getFallbackUrl(name, category = '') {
    const searchStr = (name + ' ' + category).toLowerCase();
    for (const [key, url] of Object.entries(FALLBACK_MAP)) {
        if (key === 'default') continue;
        if (searchStr.includes(key)) return url;
    }
    return FALLBACK_MAP['default'];
}

function isValidUrl(url) {
    return typeof url === 'string' && url.startsWith('http');
}

async function backfill() {
    console.log('Starting image backfill...');

    let categoriesUpdated = 0;
    let servicesUpdated = 0;
    let subServicesUpdated = 0;

    const BATCH_SIZE = 400;
    let batch = db.batch();
    let opCount = 0;

    async function commitBatchIfNeeded() {
        if (opCount >= BATCH_SIZE) {
            await batch.commit();
            console.log(`Committed batch of ${opCount} operations.`);
            batch = db.batch();
            opCount = 0;
        }
    }

    // 1. Process Categories
    const categoriesSnapshot = await db.collection('categories').get();
    for (const catDoc of categoriesSnapshot.docs) {
        const data = catDoc.data();
        const name = data.name || data.title || '';
        let imageUrl = data.imageUrl || data.image;

        let needsUpdate = false;
        const updates = {};

        // Migrate 'image' to 'imageUrl' if 'imageUrl' is missing
        if (!data.imageUrl && data.image) {
            updates.imageUrl = data.image;
            imageUrl = data.image;
            needsUpdate = true;
        }

        // Validate or fallback
        if (!isValidUrl(imageUrl)) {
            updates.imageUrl = getFallbackUrl(name);
            needsUpdate = true;
        }

        if (needsUpdate) {
            batch.update(catDoc.ref, updates);
            opCount++;
            categoriesUpdated++;
            await commitBatchIfNeeded();
        }

        // 2. Process Services
        const servicesSnapshot = await catDoc.ref.collection('services').get();
        for (const serviceDoc of servicesSnapshot.docs) {
            const sData = serviceDoc.data();
            const sName = sData.name || sData.title || '';
            const sCategory = sData.category || name;
            let sImageUrl = sData.imageUrl || sData.image;

            let sNeedsUpdate = false;
            const sUpdates = {};

            if (!sData.imageUrl && sData.image) {
                sUpdates.imageUrl = sData.image;
                sImageUrl = sData.image;
                sNeedsUpdate = true;
            }

            if (!isValidUrl(sImageUrl)) {
                sUpdates.imageUrl = getFallbackUrl(sName, sCategory);
                sNeedsUpdate = true;
            }

            if (sNeedsUpdate) {
                batch.update(serviceDoc.ref, sUpdates);
                opCount++;
                servicesUpdated++;
                await commitBatchIfNeeded();
            }

            // 3. Process Sub-Services
            const subServicesSnapshot = await serviceDoc.ref.collection('subServices').get();
            for (const subDoc of subServicesSnapshot.docs) {
                const ssData = subDoc.data();
                const ssName = ssData.name || ssData.title || '';
                let ssImageUrl = ssData.imageUrl || ssData.image;

                let ssNeedsUpdate = false;
                const ssUpdates = {};

                if (!ssData.imageUrl && ssData.image) {
                    ssUpdates.imageUrl = ssData.image;
                    ssImageUrl = ssData.image;
                    ssNeedsUpdate = true;
                }

                if (!isValidUrl(ssImageUrl)) {
                    ssUpdates.imageUrl = getFallbackUrl(ssName, sCategory);
                    ssNeedsUpdate = true;
                }

                if (ssNeedsUpdate) {
                    batch.update(subDoc.ref, ssUpdates);
                    opCount++;
                    subServicesUpdated++;
                    await commitBatchIfNeeded();
                }
            }
        }
    }

    if (opCount > 0) {
        await batch.commit();
        console.log(`Committed final batch of ${opCount} operations.`);
    }

    console.log('\nIMAGE BACKFILL: SUCCESS');
    console.log(`categories updated: ${categoriesUpdated}`);
    console.log(`services updated: ${servicesUpdated}`);
    console.log(`subServices updated: ${subServicesUpdated}`);
}

backfill().catch(err => {
    console.error('Backfill failed:', err);
    process.exit(1);
});
