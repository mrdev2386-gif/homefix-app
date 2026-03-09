// Test script to verify admin approval flow
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function testAdminApprovalFlow() {
  console.log('🧪 Testing Admin Approval Flow...\n');
  
  // Test 1: Verify profile completion calculation
  console.log('1. Testing profile completion calculation...');
  
  const testTechnician = {
    fullName: 'Test Technician',
    phone: '+919876543210',
    email: 'test@example.com',
    profilePhotoUrl: 'https://example.com/photo.jpg',
    skills: ['plumbing', 'electrical'],
    experienceYears: 5,
    bankStatus: 'approved',
    aadhaarFrontUrl: 'https://example.com/aadhaar.jpg',
    customServices: ['Custom Service']
  };
  
  const completion = calculateProfileCompletion(testTechnician);
  console.log(`   Profile completion: ${completion}%`);
  
  if (completion === 100) {
    console.log('   ✅ Profile completion calculation works correctly\n');
  } else {
    console.log('   ❌ Profile completion calculation failed\n');
    return;
  }
  
  // Test 2: Create test technician document
  console.log('2. Creating test technician document...');
  
  const testUid = 'test-technician-' + Date.now();
  
  try {
    await db.collection('technicians').doc(testUid).set({
      ...testTechnician,
      profileApprovalRequested: false,
      profileApproved: false,
      profileRejected: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('   ✅ Test technician created\n');
    
    // Test 3: Simulate profile completion reaching 100%
    console.log('3. Simulating profile update to trigger admin review...');
    
    await db.collection('technicians').doc(testUid).update({
      // Ensure all fields are complete
      fullName: 'Updated Test Technician',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Wait for Cloud Function to process
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // Test 4: Verify admin review was requested
    console.log('4. Verifying admin review was requested...');
    
    const updatedDoc = await db.collection('technicians').doc(testUid).get();
    const data = updatedDoc.data();
    
    if (data.profileApprovalRequested === true) {
      console.log('   ✅ Admin review requested successfully');
      console.log(`   ✅ Review requested at: ${data.reviewRequestedAt?.toDate()}\n`);
    } else {
      console.log('   ❌ Admin review was NOT requested');
      console.log('   ❌ Cloud Function trigger may not be working\n');
    }
    
    // Test 5: Simulate admin approval
    console.log('5. Simulating admin approval...');
    
    await db.collection('technicians').doc(testUid).update({
      profileApproved: true,
      profileApprovalRequested: false,
      profileRejected: false,
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('   ✅ Admin approval simulated\n');
    
    // Test 6: Verify service creation is now allowed
    console.log('6. Testing service creation validation...');
    
    const finalDoc = await db.collection('technicians').doc(testUid).get();
    const finalData = finalDoc.data();
    
    const canCreateServices = finalData.profileApproved === true && 
                             calculateProfileCompletion(finalData) === 100;
    
    if (canCreateServices) {
      console.log('   ✅ Service creation is now allowed');
    } else {
      console.log('   ❌ Service creation is still blocked');
    }
    
    // Cleanup
    console.log('\n7. Cleaning up test data...');
    await db.collection('technicians').doc(testUid).delete();
    console.log('   ✅ Test data cleaned up');
    
    console.log('\n🎉 Admin approval flow test completed!');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

function calculateProfileCompletion(technician) {
  let completed = 0;
  const total = 8;
  
  if (technician.fullName && technician.fullName.trim().length > 0) completed++;
  if (technician.phone && technician.phone.trim().length > 0) completed++;
  if (technician.profilePhotoUrl && technician.profilePhotoUrl.trim().length > 0) completed++;
  if (technician.skills && technician.skills.length > 0) completed++;
  if (technician.experienceYears && technician.experienceYears > 0) completed++;
  if (technician.bankStatus === 'approved') completed++;
  if ((technician.aadhaarFrontUrl && technician.aadhaarFrontUrl.trim().length > 0) || 
      (technician.panNumber && technician.panNumber.trim().length > 0)) completed++;
  if ((technician.customServices && technician.customServices.length > 0) || 
      (technician.skills && technician.skills.length > 0)) completed++;
  
  return Math.round((completed / total) * 100);
}

// Run the test
testAdminApprovalFlow().then(() => {
  process.exit(0);
}).catch((error) => {
  console.error('Test suite failed:', error);
  process.exit(1);
});