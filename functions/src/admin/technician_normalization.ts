import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * TECHNICIAN DATA NORMALIZATION CLOUD FUNCTION
 * 
 * Normalizes all technician documents by:
 * 1. Converting legacy step fields to normalized fields
 * 2. Converting status "active" to "approved" 
 * 3. Recalculating profile completion from normalized fields
 * 4. Removing legacy keys completely
 */
export const normalizeTechnicianData = functions.https.onCall(async (data, context) => {
    // Admin only function
    if (!context.auth || !context.auth.token.admin) {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only admins can run data normalization'
        );
    }

    console.log('[NORMALIZATION] Starting technician data normalization...');

    let processedCount = 0;
    let normalizedCount = 0;
    let errorCount = 0;
    const errors: string[] = [];

    try {
        // Get all technician documents
        const snapshot = await db.collection('technicians').get();
        
        console.log(`[NORMALIZATION] Found ${snapshot.size} technician documents`);

        // Process in batches of 500 (Firestore limit)
        const batch = db.batch();
        let batchCount = 0;

        for (const doc of snapshot.docs) {
            try {
                const data = doc.data();
                const docId = doc.id;
                let needsUpdate = false;
                const updates: any = {};

                // 1. NORMALIZE STEP FIELDS
                const rawSteps = data.stepsCompleted || {};
                const normalizedSteps: any = {};

                // Map legacy fields to normalized fields
                normalizedSteps.personalDetails = rawSteps.basic ?? rawSteps.personalDetails ?? false;
                normalizedSteps.serviceCategories = rawSteps.professional ?? rawSteps.serviceCategories ?? false;
                normalizedSteps.portfolio = rawSteps.portfolio ?? rawSteps.bank ?? false;
                normalizedSteps.verification = rawSteps.verification ?? rawSteps.kyc ?? false;

                // Check if normalization is needed
                const hasLegacyFields = ['basic', 'professional', 'kyc', 'services', 'bank']
                    .some(key => rawSteps.hasOwnProperty(key));

                if (hasLegacyFields || JSON.stringify(rawSteps) !== JSON.stringify(normalizedSteps)) {
                    updates.stepsCompleted = normalizedSteps;
                    needsUpdate = true;
                    console.log(`[NORMALIZATION] ${docId}: Normalized step fields`);
                }

                // 2. NORMALIZE STATUS FIELD
                if (data.status === 'active') {
                    updates.status = 'approved';
                    needsUpdate = true;
                    console.log(`[NORMALIZATION] ${docId}: Status active → approved`);
                }

                // 3. RECALCULATE PROFILE COMPLETION
                let completedSteps = 0;
                if (normalizedSteps.personalDetails === true) completedSteps++;
                if (normalizedSteps.serviceCategories === true) completedSteps++;
                if (normalizedSteps.portfolio === true) completedSteps++;
                if (normalizedSteps.verification === true) completedSteps++;

                const calculatedCompletion = Math.floor((completedSteps * 100) / 4);
                const currentCompletion = data.profileCompletion;

                if (currentCompletion !== calculatedCompletion) {
                    updates.profileCompletion = calculatedCompletion;
                    needsUpdate = true;
                    console.log(`[NORMALIZATION] ${docId}: Profile completion ${currentCompletion}% → ${calculatedCompletion}%`);
                }

                // 4. ADD UPDATE TIMESTAMP
                if (needsUpdate) {
                    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
                    updates.normalizedAt = admin.firestore.FieldValue.serverTimestamp();
                    
                    batch.update(doc.ref, updates);
                    batchCount++;
                    normalizedCount++;

                    // Commit batch if it reaches 500 operations
                    if (batchCount >= 500) {
                        await batch.commit();
                        console.log(`[NORMALIZATION] Committed batch of ${batchCount} updates`);
                        batchCount = 0;
                    }
                }

                processedCount++;

            } catch (error) {
                console.error(`[NORMALIZATION] Error processing document ${doc.id}:`, error);
                errors.push(`${doc.id}: ${error}`);
                errorCount++;
            }
        }

        // Commit remaining batch
        if (batchCount > 0) {
            await batch.commit();
            console.log(`[NORMALIZATION] Committed final batch of ${batchCount} updates`);
        }

        const result = {
            success: true,
            processedCount,
            normalizedCount,
            errorCount,
            errors: errors.slice(0, 10), // Limit error list
            summary: {
                totalDocuments: snapshot.size,
                documentsNormalized: normalizedCount,
                documentsUnchanged: processedCount - normalizedCount,
                documentsWithErrors: errorCount
            }
        };

        console.log('[NORMALIZATION] Completed successfully:', result.summary);
        return result;

    } catch (error) {
        console.error('[NORMALIZATION] Fatal error:', error);
        throw new functions.https.HttpsError(
            'internal',
            `Normalization failed: ${error}`
        );
    }
});

/**
 * VERIFY NORMALIZATION RESULTS
 * 
 * Checks all technician documents to verify normalization was successful
 */
export const verifyTechnicianNormalization = functions.https.onCall(async (data, context) => {
    // Admin only function
    if (!context.auth || !context.auth.token.admin) {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only admins can run verification'
        );
    }

    console.log('[VERIFICATION] Starting normalization verification...');

    const results = {
        totalDocuments: 0,
        normalizedDocuments: 0,
        documentsWithLegacyFields: 0,
        documentsWithIncorrectCompletion: 0,
        documentsWithActiveStatus: 0,
        approvedTechnicians: 0,
        completeTechnicians: 0,
        issues: [] as string[]
    };

    try {
        const snapshot = await db.collection('technicians').get();
        results.totalDocuments = snapshot.size;

        for (const doc of snapshot.docs) {
            const data = doc.data();
            const docId = doc.id;
            const steps = data.stepsCompleted || {};

            // Check for legacy fields
            const hasLegacyFields = ['basic', 'professional', 'kyc', 'services', 'bank']
                .some(key => steps.hasOwnProperty(key));

            if (hasLegacyFields) {
                results.documentsWithLegacyFields++;
                results.issues.push(`${docId}: Still has legacy fields: ${Object.keys(steps).filter(k => ['basic', 'professional', 'kyc', 'services', 'bank'].includes(k)).join(', ')}`);
            }

            // Check status normalization
            if (data.status === 'active') {
                results.documentsWithActiveStatus++;
                results.issues.push(`${docId}: Status still "active" instead of "approved"`);
            }

            if (data.status === 'approved') {
                results.approvedTechnicians++;
            }

            // Verify profile completion calculation
            let completedSteps = 0;
            if (steps.personalDetails === true) completedSteps++;
            if (steps.serviceCategories === true) completedSteps++;
            if (steps.portfolio === true) completedSteps++;
            if (steps.verification === true) completedSteps++;

            const expectedCompletion = Math.floor((completedSteps * 100) / 4);
            const actualCompletion = data.profileCompletion;

            if (actualCompletion !== expectedCompletion) {
                results.documentsWithIncorrectCompletion++;
                results.issues.push(`${docId}: Profile completion mismatch - expected ${expectedCompletion}%, actual ${actualCompletion}%`);
            }

            if (expectedCompletion === 100) {
                results.completeTechnicians++;
            }

            // Check if document appears normalized
            if (!hasLegacyFields && data.status !== 'active' && actualCompletion === expectedCompletion) {
                results.normalizedDocuments++;
            }
        }

        console.log('[VERIFICATION] Completed:', results);
        return results;

    } catch (error) {
        console.error('[VERIFICATION] Error:', error);
        throw new functions.https.HttpsError(
            'internal',
            `Verification failed: ${error}`
        );
    }
});
