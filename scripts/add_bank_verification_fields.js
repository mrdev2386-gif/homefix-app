/**
 * Migration Script: Add Bank Verification Security Fields
 * 
 * Adds the following fields to all technician documents:
 * - verificationLock: false
 * - verificationAttempts: 0
 * - lastVerificationAttemptAt: null
 * 
 * Run: node scripts/add_bank_verification_fields.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addBankVerificationFields() {
  console.log('🔄 Starting migration: Add bank verification security fields...\n');

  try {
    const techniciansRef = db.collection('technicians');
    const snapshot = await techniciansRef.get();

    if (snapshot.empty) {
      console.log('❌ No technician documents found');
      return;
    }

    console.log(`📊 Found ${snapshot.size} technician documents\n`);

    let updatedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    // Process in batches of 500 (Firestore limit)
    const batchSize = 500;
    let batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const techId = doc.id;

      // Check if fields already exist
      if (data.verificationLock !== undefined && 
          data.verificationAttempts !== undefined) {
        console.log(`⏭️  Skipped: ${data.name || techId} (fields already exist)`);
        skippedCount++;
        continue;
      }

      try {
        // Add new fields
        batch.update(doc.ref, {
          verificationLock: false,
          verificationAttempts: 0,
          lastVerificationAttemptAt: null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`✅ Queued: ${data.name || techId}`);
        updatedCount++;
        batchCount++;

        // Commit batch when it reaches the limit
        if (batchCount >= batchSize) {
          await batch.commit();
          console.log(`\n💾 Committed batch of ${batchCount} updates\n`);
          batch = db.batch();
          batchCount = 0;
        }

      } catch (error) {
        console.error(`❌ Error processing ${techId}:`, error.message);
        errorCount++;
      }
    }

    // Commit remaining batch
    if (batchCount > 0) {
      await batch.commit();
      console.log(`\n💾 Committed final batch of ${batchCount} updates\n`);
    }

    // Summary
    console.log('\n' + '='.repeat(50));
    console.log('📈 Migration Summary:');
    console.log('='.repeat(50));
    console.log(`✅ Updated: ${updatedCount}`);
    console.log(`⏭️  Skipped: ${skippedCount}`);
    console.log(`❌ Errors: ${errorCount}`);
    console.log('='.repeat(50));
    console.log('\n✨ Migration complete!\n');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

// Run migration
addBankVerificationFields()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
