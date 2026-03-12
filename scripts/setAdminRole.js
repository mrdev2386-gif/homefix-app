#!/usr/bin/env node

/**
 * HomeFix Admin Role Setup Script
 * 
 * Sets the admin custom claim on a Firebase user account
 * This claim is required for accessing the admin panel and approving bookings
 * 
 * Usage:
 *   node scripts/setAdminRole.js <admin-email>
 * 
 * Example:
 *   node scripts/setAdminRole.js admin@homefix.com
 * 
 * Prerequisites:
 *   1. Firebase service account key (serviceAccountKey.json)
 *   2. Node.js installed
 *   3. firebase-admin package installed
 * 
 * Steps:
 *   1. Download service account key from Firebase Console
 *   2. Place it in scripts/serviceAccountKey.json
 *   3. Run this script with admin email
 *   4. Admin user will have admin claim set
 *   5. Admin must log out and back in to refresh token
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Configuration
const PROJECT_ID = 'homefix-aa42d';
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');

/**
 * Initialize Firebase Admin SDK
 */
function initializeFirebase() {
  try {
    // Check if service account key exists
    if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
      console.error('❌ Error: serviceAccountKey.json not found');
      console.error(`Expected location: ${SERVICE_ACCOUNT_PATH}`);
      console.error('\nTo get the service account key:');
      console.error('1. Go to Firebase Console: https://console.firebase.google.com');
      console.error('2. Select project: homefix-aa42d');
      console.error('3. Go to Project Settings → Service Accounts');
      console.error('4. Click "Generate New Private Key"');
      console.error('5. Save as scripts/serviceAccountKey.json');
      process.exit(1);
    }

    const serviceAccount = require(SERVICE_ACCOUNT_PATH);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: PROJECT_ID
    });

    console.log('✅ Firebase Admin SDK initialized');
    return admin.auth();
  } catch (error) {
    console.error('❌ Error initializing Firebase:', error.message);
    process.exit(1);
  }
}

/**
 * Set admin custom claim on user
 */
async function setAdminRole(auth, email) {
  try {
    console.log(`\n📧 Looking up user: ${email}`);

    // Find user by email
    const user = await auth.getUserByEmail(email);
    console.log(`✅ Found user: ${user.uid}`);
    console.log(`   Email: ${user.email}`);
    console.log(`   Display Name: ${user.displayName || 'Not set'}`);

    // Check if already admin
    const existingClaims = user.customClaims || {};
    if (existingClaims.admin === true) {
      console.log('\n⚠️  User already has admin claim');
      console.log('   No changes made');
      return user.uid;
    }

    // Set custom claim
    console.log('\n🔧 Setting admin custom claim...');
    await auth.setCustomUserClaims(user.uid, { admin: true });
    console.log('✅ Admin claim set successfully');

    return user.uid;
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.error(`❌ Error: User not found with email: ${email}`);
      console.error('\nTo find the correct email:');
      console.error('1. Go to Firebase Console → Authentication');
      console.error('2. Find the admin user');
      console.error('3. Copy the exact email address');
      console.error('4. Run this script again with the correct email');
    } else {
      console.error(`❌ Error setting admin claim: ${error.message}`);
    }
    process.exit(1);
  }
}

/**
 * Display next steps
 */
function displayNextSteps(uid, email) {
  console.log('\n' + '='.repeat(60));
  console.log('✅ ADMIN ROLE SETUP COMPLETE');
  console.log('='.repeat(60));

  console.log('\n📋 User Details:');
  console.log(`   Email: ${email}`);
  console.log(`   UID: ${uid}`);
  console.log(`   Custom Claim: admin = true`);

  console.log('\n📝 Next Steps:');
  console.log('   1. Log out from admin panel');
  console.log('   2. Close the browser completely');
  console.log('   3. Clear browser cache (optional but recommended)');
  console.log('   4. Log back in with the admin email');
  console.log('   5. Token will refresh with admin claim');
  console.log('   6. Try approving a booking');

  console.log('\n🔍 To Verify Admin Claim:');
  console.log('   1. Open admin panel');
  console.log('   2. Open browser DevTools (F12)');
  console.log('   3. Go to Console tab');
  console.log('   4. Run this command:');
  console.log('      firebase.auth().currentUser.getIdTokenResult().then(r => console.log(r.claims))');
  console.log('   5. Should show: { admin: true, ... }');

  console.log('\n❓ Troubleshooting:');
  console.log('   • If still getting 403: Log out and back in again');
  console.log('   • If token doesn\'t show admin claim: Clear browser cache');
  console.log('   • If user not found: Check email spelling in Firebase Console');

  console.log('\n' + '='.repeat(60) + '\n');
}

/**
 * Main function
 */
async function main() {
  // Get email from command line
  const email = process.argv[2];

  if (!email) {
    console.error('❌ Error: Email address required');
    console.error('\nUsage:');
    console.error('   node scripts/setAdminRole.js <admin-email>');
    console.error('\nExample:');
    console.error('   node scripts/setAdminRole.js admin@homefix.com');
    console.error('   node scripts/setAdminRole.js yash@example.com');
    process.exit(1);
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    console.error(`❌ Error: Invalid email format: ${email}`);
    process.exit(1);
  }

  console.log('\n' + '='.repeat(60));
  console.log('🔐 HomeFix Admin Role Setup');
  console.log('='.repeat(60));

  // Initialize Firebase
  const auth = initializeFirebase();

  // Set admin role
  const uid = await setAdminRole(auth, email);

  // Display next steps
  displayNextSteps(uid, email);

  // Exit successfully
  process.exit(0);
}

// Run main function
main().catch((error) => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
