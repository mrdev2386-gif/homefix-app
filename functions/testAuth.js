const admin = require('firebase-admin');
const serviceAccount = require('../scripts/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'homefix-aa42d'
});

const auth = admin.auth();
const functions = require('firebase-functions-test')({
  projectId: 'homefix-aa42d'
}, '../scripts/serviceAccountKey.json');

// Test user credentials
const TEST_EMAIL = 'test@homefix.com';
const TEST_PASSWORD = 'Test@123456';

async function createTestUser() {
  try {
    const userRecord = await auth.createUser({
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
      emailVerified: true
    });
    console.log('✅ Test user created:', userRecord.uid);
    return userRecord.uid;
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      const user = await auth.getUserByEmail(TEST_EMAIL);
      console.log('✅ Test user exists:', user.uid);
      return user.uid;
    }
    throw error;
  }
}

async function getIdToken(uid) {
  const customToken = await auth.createCustomToken(uid);
  console.log('✅ Custom token created');
  return customToken;
}

async function testCallableFunction(functionName, region, data = {}) {
  const https = require('https');
  const url = `https://${region}-homefix-aa42d.cloudfunctions.net/${functionName}`;
  
  try {
    const uid = await createTestUser();
    const token = await getIdToken(uid);
    
    console.log(`\n🔥 Testing: ${functionName} (${region})`);
    console.log(`   URL: ${url}`);
    console.log(`   UID: ${uid}`);
    
    const response = await new Promise((resolve, reject) => {
      const postData = JSON.stringify({ data });
      
      const options = {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': postData.length,
          'Authorization': `Bearer ${token}`
        }
      };
      
      const req = https.request(url, options, (res) => {
        let body = '';
        res.on('data', (chunk) => body += chunk);
        res.on('end', () => {
          try {
            resolve({
              status: res.statusCode,
              body: JSON.parse(body)
            });
          } catch (e) {
            resolve({
              status: res.statusCode,
              body: body
            });
          }
        });
      });
      
      req.on('error', reject);
      req.write(postData);
      req.end();
    });
    
    if (response.status === 200) {
      console.log(`   ✅ SUCCESS: ${response.status}`);
      console.log(`   Response:`, JSON.stringify(response.body, null, 2));
      return true;
    } else {
      console.log(`   ❌ FAILED: ${response.status}`);
      console.log(`   Error:`, JSON.stringify(response.body, null, 2));
      return false;
    }
  } catch (error) {
    console.log(`   ❌ ERROR: ${error.message}`);
    return false;
  }
}

async function runTests() {
  console.log('='.repeat(60));
  console.log('CLOUD FUNCTIONS AUTHENTICATION TEST');
  console.log('='.repeat(60));
  
  const tests = [
    { name: 'saveFcmToken', region: 'asia-south1', data: { token: 'test_token_123', platform: 'android' } },
    { name: 'createTechnicianProfile', region: 'asia-south1', data: { phone: '+919876543210', email: 'tech@test.com' } },
    { name: 'admin_getDashboardStats', region: 'asia-south1', data: {} }
  ];
  
  let passed = 0;
  let failed = 0;
  
  for (const test of tests) {
    const result = await testCallableFunction(test.name, test.region, test.data);
    if (result) {
      passed++;
    } else {
      failed++;
    }
    
    // Wait 1 second between tests
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  console.log('\n' + '='.repeat(60));
  console.log('TEST RESULTS');
  console.log('='.repeat(60));
  console.log(`✅ Passed: ${passed}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`📊 Total: ${tests.length}`);
  
  if (failed === 0) {
    console.log('\n🎉 ALL TESTS PASSED! No unauthenticated errors.');
  } else {
    console.log('\n⚠️  Some tests failed. Check logs above.');
  }
  
  process.exit(failed === 0 ? 0 : 1);
}

runTests().catch(error => {
  console.error('❌ Test suite failed:', error);
  process.exit(1);
});
