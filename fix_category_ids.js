const admin = require('firebase-admin');
const serviceAccount = require('./scripts/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixMissingCategoryIds() {
  console.log('🔧 Fixing missing categoryId fields...\n');

  try {
    const servicesSnapshot = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .get();

    console.log(`Found ${servicesSnapshot.size} approved services to check`);

    const batch = db.batch();
    let updateCount = 0;

    for (const doc of servicesSnapshot.docs) {
      const data = doc.data();
      
      if (!data.categoryId) {
        console.log(`Fixing service: ${data.title}`);
        
        // Map service titles to category IDs (customize as needed)
        let categoryId = 'general';
        if (data.title?.toLowerCase().includes('clean')) categoryId = 'cleaning';
        if (data.title?.toLowerCase().includes('ac')) categoryId = 'ac_repair';
        if (data.title?.toLowerCase().includes('car')) categoryId = 'car_wash';
        if (data.title?.toLowerCase().includes('electric')) categoryId = 'electrical';
        if (data.title?.toLowerCase().includes('plumb')) categoryId = 'plumbing';
        
        const updates = {
          categoryId: categoryId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        batch.update(doc.ref, updates);
        updateCount++;
      }
    }

    if (updateCount > 0) {
      await batch.commit();
      console.log(`✅ Updated ${updateCount} services with categoryId`);
    } else {
      console.log('ℹ️ All services already have categoryId');
    }

    // Test simple queries that don't require complex indexes
    console.log('\n🧪 Testing simple customer app queries...');
    
    // 1. Basic approved services
    const approvedQuery = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .get();
    console.log(`✅ Total approved services: ${approvedQuery.size}`);

    // 2. Location filtering (single field at a time)
    const stateQuery = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .where('state', '==', 'Karnataka')
      .get();
    console.log(`✅ Services in Karnataka: ${stateQuery.size}`);

    // 3. Category filtering
    const categoryQuery = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .where('categoryId', '==', 'cleaning')
      .get();
    console.log(`✅ Cleaning services: ${categoryQuery.size}`);

    console.log('\n🎉 Customer app can now see approved technician services!');

  } catch (error) {
    console.error('❌ Error fixing categoryId fields:', error);
  }
}

fixMissingCategoryIds();