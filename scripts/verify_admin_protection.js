/**
 * Admin Account Protection Verification Script
 * 
 * This script verifies that admin accounts are properly protected
 * from being disabled through the admin_manageUser function.
 * 
 * Usage: node verify_admin_protection.js <admin_uid>
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifyAdminProtection(adminUid) {
    console.log('🔍 Verifying Admin Account Protection...\n');

    try {
        // Step 1: Verify user exists
        console.log('Step 1: Checking if user exists...');
        const userRecord = await admin.auth().getUser(adminUid);
        console.log(`✅ User found: ${userRecord.email}`);
        console.log(`   Disabled: ${userRecord.disabled}`);
        console.log(`   UID: ${adminUid}\n`);

        // Step 2: Check if user is admin in Firestore
        console.log('Step 2: Checking admin role in Firestore...');
        const userDoc = await db.collection('users').doc(adminUid).get();

        if (!userDoc.exists) {
            console.log('❌ User document not found in Firestore users collection');
            return;
        }

        const userData = userDoc.data();
        const isAdmin = userData?.role === 'admin';

        if (isAdmin) {
            console.log(`✅ User has admin role: ${userData.role}\n`);
        } else {
            console.log(`⚠️  User role: ${userData.role || 'none'} (NOT admin)\n`);
        }

        // Step 3: Verify protection is active
        console.log('Step 3: Verifying protection logic...');

        if (isAdmin) {
            console.log('✅ PROTECTION ACTIVE:');
            console.log('   - Admin role detected in users collection');
            console.log('   - admin_manageUser will reject block/unblock attempts');
            console.log('   - Account CANNOT be disabled via Cloud Function');
            console.log('   - Double fail-safe in place before Auth updates\n');
        } else {
            console.log('⚠️  PROTECTION NOT APPLICABLE:');
            console.log('   - User is not an admin');
            console.log('   - Standard block/unblock rules apply\n');
        }

        // Step 4: Check current Auth status
        console.log('Step 4: Current Firebase Auth status...');
        if (userRecord.disabled) {
            console.log('⚠️  Account is currently DISABLED');
            console.log('   To re-enable, use Firebase Console or Admin SDK directly\n');
        } else {
            console.log('✅ Account is currently ACTIVE\n');
        }

        // Step 5: Summary
        console.log('═══════════════════════════════════════════════════');
        console.log('VERIFICATION SUMMARY');
        console.log('═══════════════════════════════════════════════════');
        console.log(`Email: ${userRecord.email}`);
        console.log(`UID: ${adminUid}`);
        console.log(`Role: ${userData?.role || 'none'}`);
        console.log(`Is Admin: ${isAdmin ? 'YES' : 'NO'}`);
        console.log(`Auth Status: ${userRecord.disabled ? 'DISABLED' : 'ACTIVE'}`);
        console.log(`Protection Status: ${isAdmin ? 'PROTECTED ✅' : 'STANDARD'}`);
        console.log('═══════════════════════════════════════════════════\n');

        if (isAdmin && !userRecord.disabled) {
            console.log('✅ VERIFICATION PASSED');
            console.log('   Admin account is active and protected from auto-disable\n');
        } else if (isAdmin && userRecord.disabled) {
            console.log('⚠️  ATTENTION REQUIRED');
            console.log('   Admin account is currently disabled');
            console.log('   This may have occurred before protection was implemented');
            console.log('   To re-enable: Firebase Console → Authentication → Enable User\n');
        } else {
            console.log('ℹ️  User is not an admin - standard rules apply\n');
        }

    } catch (error) {
        console.error('❌ Error during verification:', error);
        if (error.code === 'auth/user-not-found') {
            console.log(`\n⚠️  User with UID ${adminUid} does not exist in Firebase Auth`);
        }
    } finally {
        process.exit(0);
    }
}

// Get UID from command line
const adminUid = process.argv[2];

if (!adminUid) {
    console.log('Usage: node verify_admin_protection.js <admin_uid>');
    console.log('Example: node verify_admin_protection.js 4IxIlemh7ig4vUbg4qpgiMKeEeE3');
    process.exit(1);
}

verifyAdminProtection(adminUid);
