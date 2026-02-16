import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const temp_recovery_diag = functions.https.onRequest(async (req, res) => {
    if (req.query.secret !== 'audit_2026_recovery') {
        res.status(403).send('Forbidden');
        return;
    }

    const db = admin.firestore();
    const DRY_RUN = false; // DISABLING DRY RUN FOR EXECUTION

    const result: any = {
        phase8: { dryRun: DRY_RUN, categoriesCreated: [], categoriesSkippedExisting: [] },
        phase9: { finalCategoryCount: 0 }
    };

    const targetCategories = [
        { id: 'repair', name: 'Repair', imageUrl: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&q=80' },
        { id: 'cleaning', name: 'Cleaning', imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80' },
        { id: 'personal_care', name: 'Personal Care', imageUrl: 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80' },
        { id: 'renovation', name: 'Renovation', imageUrl: 'https://images.unsplash.com/photo-1581578731117-104f2a41272c?w=400&q=80' }
    ];

    try {
        // --- PRE-INSPECTION ---
        const existingCats = await db.collection('categories').get();
        const existingNormNames = new Set();
        let maxOrder = 0;

        existingCats.forEach(doc => {
            const data = doc.data();
            const name = (data.name || data.title || '').toString().toLowerCase().trim().replace(/\s+/g, ' ');
            existingNormNames.add(name);
            if (data.order && typeof data.order === 'number') {
                maxOrder = Math.max(maxOrder, data.order);
            }
        });

        // --- PHASE 8: CATEGORY GAP FIX ---
        const batch = db.batch();
        let currentOrder = maxOrder + 1;

        for (const cat of targetCategories) {
            const normalizedTarget = cat.name.toLowerCase().trim().replace(/\s+/g, ' ');

            // Check by ID and by Name
            const idRef = db.collection('categories').doc(cat.id);
            const idDoc = await idRef.get();

            if (idDoc.exists || existingNormNames.has(normalizedTarget)) {
                result.phase8.categoriesSkippedExisting.push(cat.name);
            } else {
                if (!DRY_RUN) {
                    batch.set(idRef, {
                        name: cat.name,
                        imageUrl: cat.imageUrl,
                        order: currentOrder++,
                        isActive: true,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        createdBy: "migration_script"
                    });
                }
                result.phase8.categoriesCreated.push(cat.name);
                currentOrder++;
            }
        }

        if (!DRY_RUN && result.phase8.categoriesCreated.length > 0) {
            await batch.commit();
        }

        // --- PHASE 9: SAFETY REPORT ---
        const finalCats = await db.collection('categories').get();
        result.phase9.finalCategoryCount = finalCats.size;

        res.send(`
PHASE8:
dryRun: ${DRY_RUN}
categoriesCreated: ${result.phase8.categoriesCreated.join(', ') || 'None'}
categoriesSkippedExisting: ${result.phase8.categoriesSkippedExisting.join(', ') || 'None'}

PHASE9:
finalCategoryCount: ${result.phase9.finalCategoryCount}
        `.trim());

    } catch (error: any) {
        res.status(500).send(`ERROR: ${error.message}`);
    }
});
