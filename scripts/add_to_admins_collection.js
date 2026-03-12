/**
 * Script to add user to admins collection for Firestore rules compatibility
 * Usage: node add_to_admins_collection.js <uid>
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
  console.log('Usage: node add_to_admins_collection.js <uid>');
  console.log('Example: node add_to_admins_collection.js 4IxIlemh7ig4vUbg4qpgiMKeEeE3');
  process.exit(1);
}

const uid = process.argv[2];

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function addToAdminsCollection(uid) {
  try {
    const userRecord = await admin.auth().getUser(uid);
    
    // Add to admins collection
    await admin.firestore().collection('admins').doc(uid).set({
      email: userRecord.email,
      uid: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      role: 'admin',
      permissions: ['all']
    });
    
    console.log(`✅ Successfully added user to admins collection:`);
    console.log(`   - UID: ${uid}`);
    console.log(`   - Email: ${userRecord.email}`);
    console.log('\nUser now has both custom claim and Firestore document for admin access.');
  } catch (error) {
    console.error('❌ Error adding to admins collection:', error);
  } finally {
    process.exit(0);
  }
}

addToAdminsCollection(uid);