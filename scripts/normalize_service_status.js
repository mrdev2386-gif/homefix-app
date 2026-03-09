/**
 * Data Migration Script: Normalize Service Status
 * 
 * Purpose: Fix existing technician_services documents that are missing
 * status or isActive fields due to previous implementation.
 * 
 * Run this ONCE after deploying the fixed Cloud Functions.
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function normalizeServiceStatus() {
  console.log('🔍 Starting service status normalization...\n');

  try {
    // Fetch all technician services
    const servicesSnapshot = await db.collection('technician_services').get();
    
    if (servicesSnapshot.empty) {
      console.log('✅ No services found. Nothing to migrate.');
      return;
    }

    console.log(`📊 Found ${servicesSnapshot.size} services to check\n`);

    let updatedCount = 0;
    let alreadyCorrectCount = 0;
    const batch = db.batch();
    let batchCount = 0;

    for (const doc of servicesSnapshot.docs) {
      const data = doc.data();
      const updates = {};

      // Check if status field is missing or incorrect
      if (!data.status) {
        updates.status = 'pending';
        console.log(`⚠️  Service ${doc.id}: Missing status → Setting to 'pending'`);
      }

      // Check if isActive field is missing
      if (data.isActive === undefined || data.isActive === null) {
        // If status is approved, set isActive to true, otherwise false
        updates.isActive = data.status === 'approved' ? true : false;
        console.log(`⚠️  Service ${doc.id}: Missing isActive → Setting to ${updates.isActive}`);
      }

      // Check if isDeleted field is missing
      if (data.isDeleted === undefined || data.isDeleted === null) {
        updates.isDeleted = false;
        console.log(`⚠️  Service ${doc.id}: Missing isDeleted → Setting to false`);
      }

      // If there are updates to apply
      if (Object.keys(updates).length > 0) {
        updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
        batch.update(doc.ref, updates);
        updatedCount++;
        batchCount++;

        // Firestore batch limit is 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          console.log(`\n✅ Committed batch of ${batchCount} updates\n`);
          batchCount = 0;
        }
      } else {
        alreadyCorrectCount++;
      }
    }

    // Commit remaining updates
    if (batchCount > 0) {
      await batch.commit();
      console.log(`\n✅ Committed final batch of ${batchCount} updates\n`);
    }

    console.log('\n' + '='.repeat(60));
    console.log('📊 MIGRATION SUMMARY');
    console.log('='.repeat(60));
    console.log(`Total services checked: ${servicesSnapshot.size}`);
    console.log(`Services updated: ${updatedCount}`);
    console.log(`Services already correct: ${alreadyCorrectCount}`);
    console.log('='.repeat(60));
    console.log('\n✅ Migration completed successfully!\n');

  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    throw error;
  }
}

// Run the migration
normalizeServiceStatus()
  .then(() => {
    console.log('🎉 Script completed. Exiting...');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Script failed:', error);
    process.exit(1);
  });
