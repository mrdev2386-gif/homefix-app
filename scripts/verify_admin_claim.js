/**
 * Script to verify admin custom claim for a Firebase user
 * Usage: node verify_admin_claim.js <uid>
 */

const admin = require('firebase-admin');
let serviceAccount;

try {
  serviceAccount = require('./serviceAccountKey.json');
} catch (error) {
  console.error('Error loading serviceAccountKey.json:', error.message);
  process.exit(1);
}

if (process.argv.length < 3) {
  console.log('Usage: node verify_admin_claim.js <uid>');
  console.log('Example: node verify_admin_claim.js 4IxIlemh7ig4vUbg4qpgiMKeEeE3');
  process.exit(1);
}

const uid = process.argv[2];

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function verifyAdminClaim(uid) {
  try {
    const userRecord = await admin.auth().getUser(uid);
    console.log(`User: ${userRecord.email}`);
    console.log(`UID: ${uid}`);
    console.log('\nCustom Claims:');
    console.log(JSON.stringify(userRecord.customClaims, null, 2));
    
    if (userRecord.customClaims && userRecord.customClaims.admin === true) {
      console.log('\n✅ Admin claim verified successfully!');
      console.log('User has admin privileges.');
    } else {
      console.log('\n❌ Admin claim not found or invalid.');
      console.log('User does not have admin privileges.');
    }
  } catch (error) {
    console.error('❌ Error verifying admin claim:', error);
  } finally {
    process.exit(0);
  }
}

verifyAdminClaim(uid);