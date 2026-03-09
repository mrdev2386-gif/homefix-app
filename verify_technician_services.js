const admin = require('firebase-admin');
const serviceAccount = require('./scripts/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifyTechnicianServices() {
  console.log('🔍 Verifying technician services visibility...\n');

  try {
    // 1. Check if technician_services collection exists and has documents
    console.log('1. Checking technician_services collection...');
    const techServicesSnapshot = await db.collection('technician_services').limit(10).get();
    
    if (techServicesSnapshot.empty) {
      console.log('❌ No documents found in technician_services collection');
      return;
    }

    console.log(`✅ Found ${techServicesSnapshot.size} technician services`);
    
    // 2. Check status distribution
    console.log('\n2. Checking status distribution...');
    const allServicesSnapshot = await db.collection('technician_services').get();
    const statusCounts = {};
    const locationCounts = {};
    
    allServicesSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const status = data.status || 'undefined';
      const state = data.state || 'no-state';
      const district = data.district || 'no-district';
      
      statusCounts[status] = (statusCounts[status] || 0) + 1;
      locationCounts[`${state}/${district}`] = (locationCounts[`${state}/${district}`] || 0) + 1;
    });
    
    console.log('Status distribution:');
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`  - ${status}: ${count}`);
    });
    
    console.log('\nLocation distribution:');
    Object.entries(locationCounts).slice(0, 10).forEach(([location, count]) => {
      console.log(`  - ${location}: ${count}`);
    });

    // 3. Check approved services specifically
    console.log('\n3. Checking approved services...');
    const approvedSnapshot = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .limit(5)
      .get();
    
    if (approvedSnapshot.empty) {
      console.log('❌ No approved services found');
      
      // Check for other status values that might be used
      const pendingSnapshot = await db.collection('technician_services')
        .where('status', '==', 'pending')
        .limit(3)
        .get();
      
      if (!pendingSnapshot.empty) {
        console.log('ℹ️ Found pending services that need approval:');
        pendingSnapshot.docs.forEach(doc => {
          const data = doc.data();
          console.log(`  - ${data.title} (${data.state}/${data.district})`);
        });
      }
    } else {
      console.log(`✅ Found ${approvedSnapshot.size} approved services:`);
      approvedSnapshot.docs.forEach(doc => {
        const data = doc.data();
        console.log(`  - ${data.title} (${data.state || 'no-state'}/${data.district || 'no-district'})`);
      });
    }

    // 4. Test customer app query
    console.log('\n4. Testing customer app query (approved services)...');
    const customerQuery = db.collection('technician_services')
      .where('status', '==', 'approved')
      .limit(10);
    
    const customerSnapshot = await customerQuery.get();
    console.log(`Customer app would see: ${customerSnapshot.size} services`);
    
    if (!customerSnapshot.empty) {
      console.log('Sample services visible to customers:');
      customerSnapshot.docs.slice(0, 3).forEach(doc => {
        const data = doc.data();
        console.log(`  - ${data.title} in ${data.state}/${data.district}`);
      });
    }

    // 5. Test location filtering
    console.log('\n5. Testing location filtering...');
    const testState = 'Karnataka';
    const testDistrict = 'Bangalore Urban';
    
    const locationFilteredSnapshot = await db.collection('technician_services')
      .where('status', '==', 'approved')
      .where('state', '==', testState)
      .where('district', '==', testDistrict)
      .limit(5)
      .get();
    
    console.log(`Services in ${testState}/${testDistrict}: ${locationFilteredSnapshot.size}`);

  } catch (error) {
    console.error('❌ Error verifying technician services:', error);
  }
}

verifyTechnicianServices();