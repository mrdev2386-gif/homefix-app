/**
 * POST-MIGRATION ARCHIVE SCRIPT
 * 
 * Run after 7 days of stable operation
 * Renames legacy collections to _archived_*
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function archiveCollection(sourceName, targetName) {
  console.log(`\n📦 Archiving ${sourceName} → ${targetName}...`);
  
  const sourceSnapshot = await db.collection(sourceName).get();
  
  if (sourceSnapshot.empty) {
    console.log(`⚠️ ${sourceName} is already empty`);
    return 0;
  }
  
  const batches = [];
  let currentBatch = db.batch();
  let operationCount = 0;
  let totalCount = 0;
  
  sourceSnapshot.forEach(doc => {
    const targetRef = db.collection(targetName).doc(doc.id);
    currentBatch.set(targetRef, doc.data());
    
    const sourceRef = db.collection(sourceName).doc(doc.id);
    currentBatch.delete(sourceRef);
    
    operationCount += 2;
    totalCount++;
    
    if (operationCount >= 400) {
      batches.push(currentBatch.commit());
      currentBatch = db.batch();
      operationCount = 0;
    }
  });
  
  if (operationCount > 0) {
    batches.push(currentBatch.commit());
  }
  
  await Promise.all(batches);
  console.log(`✅ Archived ${totalCount} documents`);
  return totalCount;
}

async function main() {
  console.log('🗄️ ARCHIVING LEGACY COLLECTIONS');
  console.log('=================================\n');
  
  try {
    await archiveCollection('technician_categories', '_archived_technician_categories');
    await archiveCollection('technician_subcategories', '_archived_technician_subcategories');
    
    console.log('\n✅ ARCHIVING COMPLETE');
    console.log('Legacy collections moved to _archived_* collections');
    console.log('Monitor for 30 days before permanent deletion');
    
  } catch (error) {
    console.error('\n❌ ARCHIVING FAILED:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

main();
