/**
 * Script to get UID by email address
 * Usage: node get_uid_by_email.js <email>
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
    console.log('Usage: node get_uid_by_email.js <email>');
    console.log('Example: node get_uid_by_email.js cryptosourav23@gmail.com');
    process.exit(1);
}

const email = process.argv[2];

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

async function getUidByEmail(email) {
    try {
        const userRecord = await admin.auth().getUserByEmail(email);
        console.log(`✅ Found user:`);
        console.log(`   - Email: ${userRecord.email}`);
        console.log(`   - UID: ${userRecord.uid}`);
        console.log(`   - Email Verified: ${userRecord.emailVerified}`);
        console.log(`\nCurrent Custom Claims:`, userRecord.customClaims || 'None');

        return userRecord.uid;
    } catch (error) {
        console.error('❌ Error finding user:', error.message);
        if (error.code === 'auth/user-not-found') {
            console.log(`\nUser with email ${email} does not exist.`);
        }
    } finally {
        process.exit(0);
    }
}

getUidByEmail(email);
