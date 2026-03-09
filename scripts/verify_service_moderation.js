/**
 * Service Moderation Verification Script
 * 
 * Purpose: Verify that the service moderation workflow is correctly configured
 * 
 * Checks:
 * 1. All services have status field
 * 2. All services have isActive field
 * 3. Pending services have isActive = false
 * 4. Approved services have isActive = true
 * 5. No services are missing critical fields
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifyServiceModeration() {
  console.log('🔍 Verifying Service Moderation Workflow...\n');

  try {
    const servicesSnapshot = await db.collection('technician_services').get();
    
    if (servicesSnapshot.empty) {
      console.log('✅ No services found.');
      return;
    }

    console.log(`📊 Checking ${servicesSnapshot.size} services...\n`);

    const stats = {
      total: servicesSnapshot.size,
      pending: 0,
      approved: 0,
      rejected: 0,
      missingStatus: 0,
      missingIsActive: 0,
      missingIsDeleted: 0,
      incorrectPending: 0, // pending but isActive=true
      incorrectApproved: 0, // approved but isActive=false
    };

    const issues = [];

    servicesSnapshot.forEach(doc => {
      const data = doc.data();
      const serviceId = doc.id;

      // Check status field
      if (!data.status) {
        stats.missingStatus++;
        issues.push(`❌ ${serviceId}: Missing 'status' field`);
      } else {
        if (data.status === 'pending') stats.pending++;
        if (data.status === 'approved') stats.approved++;
        if (data.status === 'rejected') stats.rejected++;
      }

      // Check isActive field
      if (data.isActive === undefined || data.isActive === null) {
        stats.missingIsActive++;
        issues.push(`❌ ${serviceId}: Missing 'isActive' field`);
      }

      // Check isDeleted field
      if (data.isDeleted === undefined || data.isDeleted === null) {
        stats.missingIsDeleted++;
        issues.push(`⚠️  ${serviceId}: Missing 'isDeleted' field`);
      }

      // Check consistency: pending services should be inactive
      if (data.status === 'pending' && data.isActive === true) {
        stats.incorrectPending++;
        issues.push(`❌ ${serviceId}: Status is 'pending' but isActive is true`);
      }

      // Check consistency: approved services should be active
      if (data.status === 'approved' && data.isActive === false) {
        stats.incorrectApproved++;
        issues.push(`❌ ${serviceId}: Status is 'approved' but isActive is false`);
      }
    });

    // Print results
    console.log('='.repeat(70));
    console.log('📊 VERIFICATION RESULTS');
    console.log('='.repeat(70));
    console.log(`Total Services: ${stats.total}`);
    console.log(`\nStatus Distribution:`);
    console.log(`  - Pending: ${stats.pending}`);
    console.log(`  - Approved: ${stats.approved}`);
    console.log(`  - Rejected: ${stats.rejected}`);
    console.log(`\nIssues Found:`);
    console.log(`  - Missing 'status': ${stats.missingStatus}`);
    console.log(`  - Missing 'isActive': ${stats.missingIsActive}`);
    console.log(`  - Missing 'isDeleted': ${stats.missingIsDeleted}`);
    console.log(`  - Pending but active: ${stats.incorrectPending}`);
    console.log(`  - Approved but inactive: ${stats.incorrectApproved}`);
    console.log('='.repeat(70));

    if (issues.length > 0) {
      console.log(`\n⚠️  Found ${issues.length} issues:\n`);
      issues.forEach(issue => console.log(issue));
      console.log('\n❌ VERIFICATION FAILED - Run normalize_service_status.js to fix issues\n');
    } else {
      console.log('\n✅ VERIFICATION PASSED - All services are correctly configured!\n');
    }

    // Additional checks
    console.log('='.repeat(70));
    console.log('🔍 WORKFLOW VERIFICATION');
    console.log('='.repeat(70));
    
    const pendingActive = servicesSnapshot.docs.filter(doc => {
      const data = doc.data();
      return data.status === 'pending' && data.isActive === true;
    }).length;

    const approvedInactive = servicesSnapshot.docs.filter(doc => {
      const data = doc.data();
      return data.status === 'approved' && data.isActive === false;
    }).length;

    console.log(`Pending services that are active (WRONG): ${pendingActive}`);
    console.log(`Approved services that are inactive (WRONG): ${approvedInactive}`);
    
    if (pendingActive === 0 && approvedInactive === 0) {
      console.log('\n✅ Service moderation workflow is correctly configured!');
    } else {
      console.log('\n❌ Service moderation workflow has issues!');
    }
    console.log('='.repeat(70) + '\n');

  } catch (error) {
    console.error('\n❌ Verification failed:', error);
    throw error;
  }
}

// Run verification
verifyServiceModeration()
  .then(() => {
    console.log('🎉 Verification completed. Exiting...');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Verification failed:', error);
    process.exit(1);
  });
