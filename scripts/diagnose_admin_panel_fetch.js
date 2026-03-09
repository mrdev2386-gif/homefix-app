/**
 * Admin Panel Service Fetch Diagnostic
 * 
 * Purpose: Diagnose why admin panel is not fetching pending services
 * 
 * Checks:
 * 1. Collection exists
 * 2. Documents have status field
 * 3. Pending services exist
 * 4. Firestore index exists
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function diagnoseAdminPanelFetch() {
  console.log('🔍 ADMIN PANEL SERVICE FETCH DIAGNOSTIC\n');
  console.log('='.repeat(70));

  try {
    // Step 1: Check if collection exists
    console.log('\n📊 STEP 1: Checking technician_services collection...\n');
    
    const allServicesSnapshot = await db.collection('technician_services').limit(10).get();
    
    if (allServicesSnapshot.empty) {
      console.log('❌ Collection is EMPTY - No services exist at all');
      console.log('   Action: Create a test service from technician app');
      return;
    }
    
    console.log(`✅ Collection exists with ${allServicesSnapshot.size} documents (showing first 10)`);
    
    // Step 2: Analyze document structure
    console.log('\n📊 STEP 2: Analyzing document structure...\n');
    
    const statusCounts = {
      pending: 0,
      approved: 0,
      rejected: 0,
      missing: 0,
      other: []
    };
    
    const sampleDocs = [];
    
    allServicesSnapshot.forEach(doc => {
      const data = doc.data();
      const status = data.status;
      
      if (!status) {
        statusCounts.missing++;
      } else if (status === 'pending') {
        statusCounts.pending++;
        sampleDocs.push({ id: doc.id, ...data });
      } else if (status === 'approved') {
        statusCounts.approved++;
      } else if (status === 'rejected') {
        statusCounts.rejected++;
      } else {
        statusCounts.other.push(status);
      }
    });
    
    console.log('Status Distribution:');
    console.log(`  - Pending: ${statusCounts.pending}`);
    console.log(`  - Approved: ${statusCounts.approved}`);
    console.log(`  - Rejected: ${statusCounts.rejected}`);
    console.log(`  - Missing status field: ${statusCounts.missing}`);
    if (statusCounts.other.length > 0) {
      console.log(`  - Other statuses: ${statusCounts.other.join(', ')}`);
    }
    
    // Step 3: Test the exact query admin panel uses
    console.log('\n📊 STEP 3: Testing admin panel query...\n');
    console.log('Query: collection("technician_services").where("status", "==", "pending")');
    
    try {
      const pendingServicesSnapshot = await db.collection('technician_services')
        .where('status', '==', 'pending')
        .get();
      
      console.log(`\n✅ Query executed successfully`);
      console.log(`   Found ${pendingServicesSnapshot.size} pending services`);
      
      if (pendingServicesSnapshot.empty) {
        console.log('\n⚠️  Query returned ZERO results');
        console.log('   Possible causes:');
        console.log('   1. All services have been approved/rejected');
        console.log('   2. Services are missing status field');
        console.log('   3. Status field has different value (e.g., "pending_admin_approval")');
      } else {
        console.log('\n✅ Pending services found:');
        pendingServicesSnapshot.forEach((doc, index) => {
          const data = doc.data();
          console.log(`\n   ${index + 1}. Service ID: ${doc.id}`);
          console.log(`      Name: ${data.name || data.serviceName || 'N/A'}`);
          console.log(`      Status: ${data.status}`);
          console.log(`      isActive: ${data.isActive}`);
          console.log(`      Technician: ${data.technicianId}`);
          console.log(`      Created: ${data.createdAt?.toDate?.() || 'N/A'}`);
        });
      }
    } catch (queryError) {
      console.error('\n❌ Query FAILED:', queryError.message);
      
      if (queryError.message.includes('index')) {
        console.log('\n⚠️  FIRESTORE INDEX MISSING');
        console.log('   Create index with:');
        console.log('   - Collection: technician_services');
        console.log('   - Fields: status (Ascending), createdAt (Descending)');
        console.log('\n   Or run: firebase deploy --only firestore:indexes');
      }
    }
    
    // Step 4: Check for services with missing status
    if (statusCounts.missing > 0) {
      console.log('\n📊 STEP 4: Services with missing status field...\n');
      
      const allDocs = await db.collection('technician_services').get();
      const missingStatus = [];
      
      allDocs.forEach(doc => {
        const data = doc.data();
        if (!data.status) {
          missingStatus.push({
            id: doc.id,
            name: data.name || data.serviceName || 'N/A',
            technicianId: data.technicianId,
            isActive: data.isActive
          });
        }
      });
      
      console.log(`Found ${missingStatus.length} services without status field:`);
      missingStatus.forEach((service, index) => {
        console.log(`\n   ${index + 1}. ${service.id}`);
        console.log(`      Name: ${service.name}`);
        console.log(`      Technician: ${service.technicianId}`);
        console.log(`      isActive: ${service.isActive}`);
      });
      
      console.log('\n⚠️  ACTION REQUIRED: Run normalize_service_status.js to fix');
    }
    
    // Step 5: Sample pending service structure
    if (sampleDocs.length > 0) {
      console.log('\n📊 STEP 5: Sample pending service structure...\n');
      console.log(JSON.stringify(sampleDocs[0], null, 2));
    }
    
    // Final Summary
    console.log('\n' + '='.repeat(70));
    console.log('📊 DIAGNOSTIC SUMMARY');
    console.log('='.repeat(70));
    
    if (statusCounts.pending > 0) {
      console.log('\n✅ ADMIN PANEL SHOULD BE WORKING');
      console.log(`   ${statusCounts.pending} pending services available`);
      console.log('\n   If admin panel still shows empty:');
      console.log('   1. Check browser console for errors');
      console.log('   2. Verify Firebase config in admin panel');
      console.log('   3. Check Firestore security rules allow admin read');
      console.log('   4. Clear browser cache and reload');
    } else if (statusCounts.missing > 0) {
      console.log('\n⚠️  SERVICES MISSING STATUS FIELD');
      console.log(`   ${statusCounts.missing} services need migration`);
      console.log('\n   ACTION: Run normalize_service_status.js');
    } else {
      console.log('\n✅ NO PENDING SERVICES');
      console.log('   All services have been reviewed');
      console.log('\n   To test:');
      console.log('   1. Create new service from technician app');
      console.log('   2. Verify it appears in admin panel');
    }
    
    console.log('='.repeat(70) + '\n');

  } catch (error) {
    console.error('\n❌ Diagnostic failed:', error);
    throw error;
  }
}

// Run diagnostic
diagnoseAdminPanelFetch()
  .then(() => {
    console.log('🎉 Diagnostic completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Diagnostic failed:', error);
    process.exit(1);
  });
