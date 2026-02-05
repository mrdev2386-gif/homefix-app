/**
 * Script to set admin custom claim for a Firebase user
 * Usage: node set_admin_claim.js <uid>
 *
 * This script sets { admin: true } custom claim for the provided UID
 * using Firebase Admin SDK. This allows the user to access admin features
 * via getIdTokenResult().claims.admin check.
 *
 * Note: Requires a valid serviceAccountKey.json file in the same directory
 */

const admin = require('firebase-admin');
let serviceAccount;

try {
  // Try to load the service account key
  serviceAccount = require('./serviceAccountKey.json');
} catch (error) {
  console.error('Error loading serviceAccountKey.json:', error.message);
  console.log('\nPlease ensure serviceAccountKey.json exists in the same directory.');
  console.log('You can generate this file from Firebase Console > Project Settings > Service Accounts.');
  process.exit(1);
}

// Check for required UID argument
if (process.argv.length < 3) {
  console.log('Usage: node set_admin_claim.js <uid>');
  console.log('Example: node set_admin_claim.js 4IxIlemh7ig4vUbg4qpgiMKeEeE3');
  process.exit(1);
}

const uid = process.argv[2];

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

/**
 * Sets admin claim for the specified user
 * @param {string} uid - Firebase user UID
 */
async function setAdminClaim(uid) {
  try {
    // First check if the user exists
    const userRecord = await admin.auth().getUser(uid);
    console.log(`Found user: ${userRecord.email}`);

    // Set the custom claim
    await admin.auth().setCustomUserClaims(uid, { admin: true });

    console.log(`✅ Successfully set admin: true custom claim for user:`);
    console.log(`   - UID: ${uid}`);
    console.log(`   - Email: ${userRecord.email}`);
    console.log('\nThis user can now access admin features by checking:');
    console.log('   token.claims.admin === true');
    console.log('\nNote: The user may need to sign out and sign back in to get the updated token.');
  } catch (error) {
    console.error('❌ Error setting admin claim:', error);
    if (error.code === 'auth/user-not-found') {
      console.log(`\nUser with UID ${uid} does not exist. Please check the UID and try again.`);
    }
  } finally {
    process.exit(0);
  }
}

// Execute the function with the provided UID
setAdminClaim(uid);
