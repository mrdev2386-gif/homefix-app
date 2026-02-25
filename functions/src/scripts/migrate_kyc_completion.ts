/**
 * ONE-TIME MIGRATION SCRIPT
 * 
 * Fixes existing technicians where:
 * - stepsCompleted.kyc == true
 * - stepsCompleted.bank == true  
 * - stepsCompleted.services == true
 * BUT isKycComplete == false
 * 
 * Run this ONCE after deploying the fixed Cloud Function
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin (if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function migrateExistingTechnicians() {
  console.log('[MIGRATION] Starting technician KYC migration...');
  
  let fixedCount = 0;
  let skippedCount = 0;
  let errorCount = 0;

  try {
    // Query all technicians where isKycComplete is false or missing
    const snapshot = await db.collection('technicians')
      .where('isKycComplete', '==', false)
      .get();

    console.log(`[MIGRATION] Found ${snapshot.size} technicians with isKycComplete=false`);

    // Process in batches of 500 (Firestore limit)
    const batchSize = 500;
    let batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const stepsCompleted = data.stepsCompleted || {};

      // Check if all critical steps are complete
      const hasKyc = stepsCompleted.kyc === true;
      const hasBank = stepsCompleted.bank === true;
      const hasServices = stepsCompleted.services === true;

      if (hasKyc && hasBank && hasServices) {
        // This technician should have isKycComplete = true
        console.log(`[MIGRATION] Fixing technician ${doc.id}`);

        batch.set(doc.ref, {
          isKycComplete: true,
          onboardingCompleted: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          migratedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        fixedCount++;
        batchCount++;

        // Commit batch if we hit the limit
        if (batchCount >= batchSize) {
          await batch.commit();
          console.log(`[MIGRATION] Committed batch of ${batchCount} updates`);
          batch = db.batch();
          batchCount = 0;
        }
      } else {
        skippedCount++;
      }
    }

    // Commit remaining batch
    if (batchCount > 0) {
      await batch.commit();
      console.log(`[MIGRATION] Committed final batch of ${batchCount} updates`);
    }

    console.log('[MIGRATION] ===== MIGRATION COMPLETE =====');
    console.log(`[MIGRATION] Fixed: ${fixedCount}`);
    console.log(`[MIGRATION] Skipped: ${skippedCount}`);
    console.log(`[MIGRATION] Errors: ${errorCount}`);

  } catch (error) {
    console.error('[MIGRATION] Fatal error:', error);
    throw error;
  }
}

// Run migration
migrateExistingTechnicians()
  .then(() => {
    console.log('[MIGRATION] Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('[MIGRATION] Script failed:', error);
    process.exit(1);
  });
