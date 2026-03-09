/**
 * Migration Script: Fix Old Technician Services
 * 
 * Problem: Old services created before moderation system have:
 * - isActive: true
 * - NO status field
 * 
 * Solution: Add status field based on isActive value
 * - If isActive = true → status = 'approved'
 * - If isActive = false → status = 'pending'
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function migrateOldServices() {
  console.log('🔍 Starting migration of old technician services...\n');

  try {
    // Fetch all services
    const snapshot = await db.collection('technician_services').get();
    
    console.log(`📊 Total services found: ${snapshot.size}\n`);

    const batch = db.batch();
    let fixedCount = 0;
    let alreadyCorrectCount = 0;

    snapshot.forEach(doc => {
      const data = doc.data();
      
      // Check if status field is missing
      if (!data.status) {
        console.log(`❌ Service ${doc.id} missing status field`);
        console.log(`   - isActive: ${data.isActive}`);
        console.log(`   - name: ${data.name}`);
        
        // Determine status based on isActive
        const status = data.isActive === true ? 'approved' : 'pending';
        
        batch.update(doc.ref, {
          status: status,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        console.log(`   ✅ Will set status to: ${status}\n`);
        fixedCount++;
      } else {
        alreadyCorrectCount++;
      }
    });

    if (fixedCount > 0) {
      console.log(`\n💾 Committing batch update for ${fixedCount} services...`);
      await batch.commit();
      console.log(`✅ Successfully fixed ${fixedCount} services`);
    } else {
      console.log(`✅ All services already have status field`);
    }

    console.log(`\n📈 Summary:`);
    console.log(`   - Total services: ${snapshot.size}`);
    console.log(`   - Fixed: ${fixedCount}`);
    console.log(`   - Already correct: ${alreadyCorrectCount}`);
    console.log(`\n✅ Migration completed successfully!`);

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

// Run migration
migrateOldServices()
  .then(() => {
    console.log('\n🎉 Done!');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Fatal error:', error);
    process.exit(1);
  });
