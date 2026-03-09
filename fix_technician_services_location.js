const admin = require('firebase-admin');
const serviceAccount = require('./scripts/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixTechnicianServicesLocation() {
  console.log('🔧 Fixing technician services location data...\n');

  try {
    // 1. Get all approved services with missing location data
    const servicesSnapshot = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .get();

    console.log(`Found ${servicesSnapshot.size} approved services to check`);

    const batch = db.batch();
    let updateCount = 0;

    for (const doc of servicesSnapshot.docs) {
      const data = doc.data();
      const needsUpdate = !data.state || !data.district || data.state === 'no-state' || data.district === 'no-district';

      if (needsUpdate) {
        console.log(`Updating service: ${data.title}`);
        
        // Set default location for testing (you can customize this)
        const updates = {
          state: 'Karnataka',
          district: 'Bangalore Urban',
          city: 'Bangalore',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        batch.update(doc.ref, updates);
        updateCount++;
      }
    }

    if (updateCount > 0) {
      await batch.commit();
      console.log(`✅ Updated ${updateCount} services with location data`);
    } else {
      console.log('ℹ️ All services already have location data');
    }

    // 2. Verify the fix
    console.log('\n🔍 Verifying location filtering...');
    const testQuery = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .where('state', '==', 'Karnataka')
      .where('district', '==', 'Bangalore Urban')
      .get();

    console.log(`✅ Services now visible in Karnataka/Bangalore Urban: ${testQuery.size}`);

    if (!testQuery.empty) {
      console.log('Sample services:');
      testQuery.docs.slice(0, 3).forEach(doc => {
        const data = doc.data();
        console.log(`  - ${data.title} by ${data.technicianId}`);
      });
    }

  } catch (error) {
    console.error('❌ Error fixing technician services:', error);
  }
}

fixTechnicianServicesLocation();