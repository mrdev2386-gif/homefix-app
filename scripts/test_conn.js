const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});
admin.firestore().collection('categories').limit(1).get()
    .then(s => {
        console.log('SUCCESS: Docs found:', s.size);
        process.exit(0);
    })
    .catch(e => {
        console.error('FAIL:', e.message);
        process.exit(1);
    });
