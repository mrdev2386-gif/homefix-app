
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // User must provide this

if (process.argv.length < 3) {
    console.log('Usage: node make_admin.js <uid>');
    process.exit(1);
}

const uid = process.argv[2];

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

async function makeAdmin(uid) {
    try {
        await admin.auth().setCustomUserClaims(uid, { admin: true });
        console.log(`Successfully set admin claim for user: ${uid}`);

        // Also ensure they exist in /admins collection for firestore rules
        const db = admin.firestore();
        await db.collection('admins').doc(uid).set({
            role: 'super_admin',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        console.log(`Created admin document in Firestore for UID: ${uid}`);
    } catch (error) {
        console.error('Error setting admin claim:', error);
    } finally {
        process.exit(0);
    }
}

makeAdmin(uid);
