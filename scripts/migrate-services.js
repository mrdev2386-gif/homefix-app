/**
 * Migration Script: Move Services from Subcollections to Top-Level Collection
 * 
 * FROM: technicians/{technicianId}/services/{serviceId}
 * TO: technician_services/{serviceId}
 */

const admin = require('firebase-admin');

// Load service account key
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin with service account
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function migrateServices() {
  console.log('🚀 Starting service migration...');
  
  let totalMigrated = 0;
  let totalSkipped = 0;
  
  try {
    // Step 1: Get all technicians
    const techniciansSnapshot = await db.collection('technicians').get();
    console.log(`📋 Found ${techniciansSnapshot.size} technicians`);
    
    // Step 2: Process each technician
    for (const techDoc of techniciansSnapshot.docs) {
      const technicianId = techDoc.id;
      console.log(`\n👨‍🔧 Processing technician: ${technicianId}`);
      
      // Step 3: Get services subcollection
      const servicesSnapshot = await db
        .collection('technicians')
        .doc(technicianId)
        .collection('services')
        .get();
      
      if (servicesSnapshot.empty) {
        console.log(`   ⚪ No services found`);
        continue;
      }
      
      console.log(`   📦 Found ${servicesSnapshot.size} services`);
      
      // Step 4: Migrate each service
      for (const serviceDoc of servicesSnapshot.docs) {
        const serviceId = serviceDoc.id;
        const serviceData = serviceDoc.data();
        
        // Check if service already exists in top-level collection
        const existingService = await db
          .collection('technician_services')
          .doc(serviceId)
          .get();
        
        if (existingService.exists) {
          console.log(`   ⏭️  Service ${serviceId} already exists, skipping`);
          totalSkipped++;
          continue;
        }
        
        // Prepare migrated service data
        const migratedService = {
          ...serviceData,
          technicianId: technicianId,
          status: serviceData.status || 'approved', // Default to approved for existing services
          title: serviceData.name || serviceData.title || 'Untitled Service',
          createdAt: serviceData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          migratedAt: admin.firestore.FieldValue.serverTimestamp(),
          _migrated: true
        };
        
        // Step 5: Copy to top-level collection
        await db
          .collection('technician_services')
          .doc(serviceId)
          .set(migratedService);
        
        console.log(`   ✅ Migrated service: ${serviceId} - ${migratedService.title}`);
        totalMigrated++;
      }
    }
    
    console.log('\n🎉 Migration completed successfully!');
    console.log(`📊 Total services migrated: ${totalMigrated}`);
    console.log(`⏭️  Total services skipped: ${totalSkipped}`);
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

// Run migration
if (require.main === module) {
  migrateServices()
    .then(() => {
      console.log('✅ Migration script completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Migration script failed:', error);
      process.exit(1);
    });
}

module.exports = { migrateServices };