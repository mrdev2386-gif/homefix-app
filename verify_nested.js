const admin = require('firebase-admin');
const key = require('./scripts/serviceAccountKey.json');
admin.initializeApp({credential: admin.credential.cert(key)});
const db = admin.firestore();

async function verifyNestedServices() {
  console.log('Fetching categories...');
  const categoriesSnap = await db.collection('categories').get();
  const categories = categoriesSnap.docs.map(d => d.id);
  console.log('Total categories:', categories.length);
  
  let totalNestedServices = 0;
  let categoriesWithServices = 0;
  
  for (const catId of categories) {
    const servicesSnap = await db.collection('categories/' + catId + '/services').get();
    const count = servicesSnap.size;
    if (count > 0) {
      console.log('Category ' + catId + ' has ' + count + ' nested services');
      categoriesWithServices++;
      totalNestedServices += count;
    }
  }
  
  console.log('\n=== NESTED VERIFICATION ===');
  console.log('totalNestedServicesFound:', totalNestedServices);
  console.log('categoriesWithServices:', categoriesWithServices);
  
  process.exit(0);
}

verifyNestedServices().catch(e => {
  console.error(e);
  process.exit(1);
});
