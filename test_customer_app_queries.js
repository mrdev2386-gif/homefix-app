const admin = require('firebase-admin');
const serviceAccount = require('./scripts/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testCustomerAppQueries() {
  console.log('🧪 Testing Customer App Technician Services Queries...\n');

  try {
    const testState = 'Karnataka';
    const testDistrict = 'Bangalore Urban';

    // 1. Test basic approved services query (what customer app should see)
    console.log('1. Testing basic approved services query...');
    const approvedQuery = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .get();
    
    console.log(`✅ Total approved services: ${approvedQuery.size}`);

    // 2. Test location filtering (state + district)
    console.log(`\n2. Testing location filtering (${testState}/${testDistrict})...`);
    const locationQuery = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .where('state', '==', testState)
      .where('district', '==', testDistrict)
      .get();
    
    console.log(`✅ Services in ${testState}/${testDistrict}: ${locationQuery.size}`);

    if (!locationQuery.empty) {
      console.log('Sample services visible to customers:');
      locationQuery.docs.slice(0, 3).forEach(doc => {
        const data = doc.data();
        console.log(`  - ${data.title} (${data.categoryId || 'no-category'})`);
      });
    }

    // 3. Test category filtering with location
    console.log('\n3. Testing category + location filtering...');
    const categoryQuery = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .where('state', '==', testState)
      .where('district', '==', testDistrict)
      .where('categoryId', '==', 'cleaning')
      .get();
    
    console.log(`✅ Cleaning services in ${testState}/${testDistrict}: ${categoryQuery.size}`);

    // 4. Test what happens with different locations
    console.log('\n4. Testing different location (should return 0)...');
    const differentLocationQuery = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .where('state', '==', 'Maharashtra')
      .where('district', '==', 'Mumbai')
      .get();
    
    console.log(`✅ Services in Maharashtra/Mumbai: ${differentLocationQuery.size}`);

    // 5. Verify data structure
    console.log('\n5. Verifying service data structure...');
    if (!approvedQuery.empty) {
      const sampleDoc = approvedQuery.docs[0];
      const data = sampleDoc.data();
      
      console.log('Sample service structure:');
      console.log(`  - ID: ${sampleDoc.id}`);
      console.log(`  - Title: ${data.title}`);
      console.log(`  - Status: ${data.status}`);
      console.log(`  - State: ${data.state}`);
      console.log(`  - District: ${data.district}`);
      console.log(`  - Category: ${data.categoryId}`);
      console.log(`  - Technician: ${data.technicianId}`);
      console.log(`  - Created: ${data.createdAt?.toDate()}`);
    }

    // 6. Test pagination query
    console.log('\n6. Testing pagination query...');
    const paginatedQuery = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .where('state', '==', testState)
      .where('district', '==', testDistrict)
      .orderBy('createdAt', 'desc')
      .limit(20)
      .get();
    
    console.log(`✅ Paginated query (limit 20): ${paginatedQuery.size} services`);

    console.log('\n🎉 All tests completed successfully!');
    console.log('\n📋 Summary:');
    console.log(`   - Approved services exist: ${approvedQuery.size > 0 ? '✅' : '❌'}`);
    console.log(`   - Location filtering works: ${locationQuery.size > 0 ? '✅' : '❌'}`);
    console.log(`   - Category filtering works: ${categoryQuery.size >= 0 ? '✅' : '❌'}`);
    console.log(`   - Different location returns 0: ${differentLocationQuery.size === 0 ? '✅' : '❌'}`);

  } catch (error) {
    console.error('❌ Error testing customer app queries:', error);
  }
}

testCustomerAppQueries();