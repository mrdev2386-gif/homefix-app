/**
 * Migration Script: Fix Stuck Pending Bank Verifications
 * 
 * PURPOSE:
 * - Find all technicians with bankVerificationStatus = "pending"
 * - Change status to "failed" to allow resubmission
 * 
 * USAGE:
 * node scripts/fix_pending_bank_verifications.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixPendingVerifications() {
  console.log('🔄 Starting pending verification fix...\n');

  try {
    // Find all technicians with pending status
    const pendingSnapshot = await db.collection('technicians')
      .where('bankVerificationStatus', '==', 'pending')
      .get();
    
    console.log(`📊 Found ${pendingSnapshot.size} technicians with pending status\n`);

    if (pendingSnapshot.empty) {
      console.log('✅ No pending verifications found. All good!\n');
      process.exit(0);
    }

    let updated = 0;
    let errors = 0;

    const batch = db.batch();
    let batchCount = 0;
    const BATCH_SIZE = 500;

    for (const doc of pendingSnapshot.docs) {
      const techData = doc.data();
      const techId = doc.id;

      try {
        console.log(`   Processing: ${techData.name || techId} - Status: pending → failed`);

        // Change pending to failed to allow resubmission
        batch.update(doc.ref, {
          bankVerificationStatus: 'failed',
          bankVerificationMessage: 'Verification incomplete. Please resubmit your bank details.',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        batchCount++;
        updated++;

        // Commit batch if it reaches the limit
        if (batchCount >= BATCH_SIZE) {
          await batch.commit();
          console.log(`✅ Committed batch of ${batchCount} updates`);
          batchCount = 0;
        }

      } catch (error) {
        console.error(`❌ Error updating technician ${techId}:`, error.message);
        errors++;
      }
    }

    // Commit remaining updates
    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Committed final batch of ${batchCount} updates`);
    }

    console.log('\n📈 Fix Summary:');
    console.log(`   ✅ Updated: ${updated}`);
    console.log(`   ❌ Errors: ${errors}`);
    console.log('\n✨ Fix complete!\n');

    // Log fix event
    await db.collection('system_logs').add({
      action: 'fix_pending_bank_verifications',
      totalPending: pendingSnapshot.size,
      updated,
      errors,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

  } catch (error) {
    console.error('❌ Fix failed:', error);
    process.exit(1);
  }

  process.exit(0);
}

// Run fix
fixPendingVerifications();
