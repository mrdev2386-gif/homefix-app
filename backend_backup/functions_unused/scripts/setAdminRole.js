#!/usr/bin/env node

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function setAdminRole() {
  const email = process.argv[2];

  if (!email) {
    console.error('Error: Please provide an email argument');
    console.error('\nUsage:');
    console.error('  node setAdminRole.js <email>');
    console.error('\nExample:');
    console.error('  node setAdminRole.js cryptosourav23@gmail.com');
    process.exit(1);
  }

  try {
    console.log(`\nSetting admin role for: ${email}`);
    
    const user = await admin.auth().getUserByEmail(email);
    console.log(`Found user: ${user.uid}`);

    await admin.auth().setCustomUserClaims(user.uid, {
      admin: true
    });

    console.log(`\nAdmin role assigned successfully: ${email}`);
    console.log(`\nUser Details:`);
    console.log(`  Email: ${email}`);
    console.log(`  UID: ${user.uid}`);
    console.log(`  Custom Claim: admin = true`);
    
    console.log(`\nNext Steps:`);
    console.log(`  1. Log out from admin panel`);
    console.log(`  2. Log back in`);
    console.log(`  3. Token will refresh with admin claim`);
    console.log(`  4. Try approving a booking\n`);
    
    process.exit(0);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.error(`\nError: User not found with email: ${email}`);
    } else {
      console.error(`\nError: ${error.message}`);
    }
    process.exit(1);
  }
}

setAdminRole();
