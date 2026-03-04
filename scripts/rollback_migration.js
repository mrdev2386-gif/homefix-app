/**
 * ROLLBACK SCRIPT - Use only if migration fails
 * 
 * Restores categories from _archived_old_categories
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function rollback() {
  console.log('🔄 ROLLING BACK MIGRATION...\n');
  
  try {
    // Restore old categories
    const backupSnapshot = await db.collection('_archived_old_categories').get();
    
    if (backupSnapshot.empty) {
      console.log('⚠️ No backup found to restore');
      return;
    }
    
    const batch = db.batch();
    let count = 0;
    
    backupSnapshot.forEach(doc => {
      const categoryRef = db.collection('categories').doc(doc.id);
      batch.set(categoryRef, doc.data());
      count++;
    });
    
    await batch.commit();
    console.log(`✅ Restored ${count} categories from backup`);
    
  } catch (error) {
    console.error('❌ Rollback failed:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

rollback();
