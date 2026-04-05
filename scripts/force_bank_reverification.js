/**
 * Migration Script: Force Bank Re-Verification
 * 
 * PURPOSE:
 * - Reset bank verification status for ALL existing technicians
 * - Force them to re-verify using new Fund Account Validation system
 * 
 * USAGE:
 * node scripts/force_bank_reverification.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateTechnicians() {
  console.log('🔄 Starting bank verification migration...\n');

  try {
    const techniciansSnapshot = await db.collection('technicians').get();
    
    console.log(`📊 Found ${techniciansSnapshot.size} technicians\n`);

    let updated = 0;
    let skipped = 0;
    let errors = 0;

    const batch = db.batch();
    let batchCount = 0;
    const BATCH_SIZE = 500;

    for (const doc of techniciansSnapshot.docs) {
      const techData = doc.data();
      const techId = doc.id;

      try {
        // Prepare update data
        const updateData = {
          bankVerified: false,
          bankVerificationStatus: 'pending',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Preserve existing bank details if they exist
        if (techData.accountNumber) {
          updateData.bankAccountNumber = techData.accountNumber;
        }
        if (techData.ifscCode) {
          updateData.bankIfsc = techData.ifscCode;
        }
        if (techData.accountHolderName) {
          updateData.bankHolderName = techData.accountHolderName;
        }

        // Clear old verification fields
        updateData.bankStatus = admin.firestore.FieldValue.delete();
        updateData.razorpayFundAccountId = admin.firestore.FieldValue.delete();

        batch.update(doc.ref, updateData);
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

    console.log('\n📈 Migration Summary:');
    console.log(`   ✅ Updated: ${updated}`);
    console.log(`   ⏭️  Skipped: ${skipped}`);
    console.log(`   ❌ Errors: ${errors}`);
    console.log('\n✨ Migration complete!\n');

    // Log migration event
    await db.collection('system_logs').add({
      action: 'bank_verification_migration',
      totalTechnicians: techniciansSnapshot.size,
      updated,
      skipped,
      errors,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }

  process.exit(0);
}

// Run migration
migrateTechnicians();
