const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();

async function inspect() {
    try {
        console.log('--- Categories ---');
        const catSnap = await db.collection('categories').get();
        catSnap.forEach(doc => {
            console.log(`ID: ${doc.id}, Name: ${doc.data().name || doc.data().title}`);
        });

        console.log('\n--- Sample Root Service ---');
        const servSnap = await db.collection('services').limit(1).get();
        if (!servSnap.empty) {
            console.log(JSON.stringify({ id: servSnap.docs[0].id, ...servSnap.docs[0].data() }, null, 2));
        } else {
            console.log('No services found in root collection.');
        }
    } catch (e) {
        console.error(e);
    }
}

inspect();
