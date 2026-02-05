/**
 * One-time script to promote a specific user to admin role via Firebase Custom Claims
 *
 * This script:
 * 1. Promotes user with UID 4IxIlemh7ig4vUbg4qpgiMKeEeE3 (cryptosourav23@gmail.com) to admin
 * 2. Uses Firebase Admin SDK to set custom claim {admin: true}
 * 3. Does NOT modify any Firestore collections
 *
 * The admin role will be readable on client side via getIdTokenResult().claims.admin
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

// The specific user we want to promote to admin
const SPECIFIC_UID = '4IxIlemh7ig4vUbg4qpgiMKeEeE3'; // Email: cryptosourav23@gmail.com

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

/**
 * Promotes the specific user to admin role
 */
async function promoteSpecificAdmin() {
  try {
    // First check if the user exists
    const userRecord = await admin.auth().getUser(SPECIFIC_UID);
    console.log(`Found user: ${userRecord.email} (${SPECIFIC_UID})`);

    // Set the admin custom claim
    await admin.auth().setCustomUserClaims(SPECIFIC_UID, { admin: true });

    // Verify the claim was set
    const updatedUser = await admin.auth().getUser(SPECIFIC_UID);

    console.log(`\n✅ SUCCESS: User ${userRecord.email} is now an admin!`);
    console.log(`Current custom claims:`, updatedUser.customClaims);
    console.log('\nThis user can now access admin features by checking:');
    console.log('   token.claims.admin === true');
    console.log('\nNote: The user may need to sign out and sign back in to get the updated token.');
  } catch (error) {
    console.error('❌ Error setting admin claim:', error);
    if (error.code === 'auth/user-not-found') {
      console.log(`\nUser with UID ${SPECIFIC_UID} does not exist. Please check the UID.`);
    }
  } finally {
    process.exit(0);
  }
}

// Execute the function
promoteSpecificAdmin();
