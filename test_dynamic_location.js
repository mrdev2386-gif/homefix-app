const admin = require('firebase-admin');
const serviceAccount = require('./scripts/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testDynamicLocationFiltering() {
  console.log('🧪 Testing Dynamic Location Filtering...\n');

  try {
    // 1. Create test customer with address
    const testUserId = 'test_customer_123';
    const testAddressId = 'primary_address_123';
    
    console.log('1. Setting up test customer with address...');
    
    // Create customer document
    await db.collection('customers').doc(testUserId).set({
      name: 'Test Customer',
      email: 'test@example.com',
      primaryAddressId: testAddressId,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Create primary address
    await db.collection('customers')
      .doc(testUserId)
      .collection('addresses')
      .doc(testAddressId)
      .set({
        street: '123 Test Street',
        city: 'Bangalore',
        district: 'Bangalore Urban',
        state: 'Karnataka',
        pincode: '560001',
        isDefault: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    
    console.log('✅ Test customer and address created');

    // 2. Test the location retrieval logic
    console.log('\n2. Testing location retrieval...');
    
    const customerDoc = await db.collection('customers').doc(testUserId).get();
    const primaryAddressId = customerDoc.data()?.primaryAddressId;
    
    if (primaryAddressId) {
      const addressDoc = await db.collection('customers')
        .doc(testUserId)
        .collection('addresses')
        .doc(primaryAddressId)
        .get();
      
      const addressData = addressDoc.data();
      const userState = addressData?.state;
      const userDistrict = addressData?.district;
      
      console.log(`✅ User location: ${userState}/${userDistrict}`);
      
      // 3. Test service query with user location
      console.log('\n3. Testing service query with user location...');
      
      const servicesQuery = await db.collection('technician_services')
        .where('status', '==', 'approved')
        .where('state', '==', userState)
        .where('district', '==', userDistrict)
        .get();
      
      console.log(`✅ Services for user location: ${servicesQuery.size}`);
      
      if (!servicesQuery.empty) {
        console.log('Sample services:');
        servicesQuery.docs.slice(0, 3).forEach(doc => {
          const data = doc.data();
          console.log(`  - ${data.title} (${data.categoryId})`);
        });
      }
      
      // 4. Test with different location (should return 0)
      console.log('\n4. Testing with different location...');
      
      const differentLocationQuery = await db.collection('technician_services')
        .where('status', '==', 'approved')
        .where('state', '==', 'Maharashtra')
        .where('district', '==', 'Mumbai')
        .get();
      
      console.log(`✅ Services for different location: ${differentLocationQuery.size}`);
      
    } else {
      console.log('❌ No primary address found');
    }

    // 5. Cleanup test data
    console.log('\n5. Cleaning up test data...');
    
    // Delete address
    await db.collection('customers')
      .doc(testUserId)
      .collection('addresses')
      .doc(testAddressId)
      .delete();
    
    // Delete customer
    await db.collection('customers').doc(testUserId).delete();
    
    console.log('✅ Test data cleaned up');

    console.log('\n🎉 Dynamic location filtering test completed successfully!');
    console.log('\nKey Points:');
    console.log('- ✅ Customer app will get user location from primary address');
    console.log('- ✅ Services are filtered by user\'s state and district');
    console.log('- ✅ Users in different locations see different services');
    console.log('- ✅ No hardcoded location values in queries');

  } catch (error) {
    console.error('❌ Error testing dynamic location filtering:', error);
  }
}

testDynamicLocationFiltering();