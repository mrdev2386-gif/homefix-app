/**
 * HOMEFIX CATEGORY SYSTEM MIGRATION SCRIPT
 * 
 * PHASE 1: technician_categories → categories
 * PHASE 2: technician_subcategories → services
 * PHASE 3: Verification
 * 
 * SAFETY: Creates backups before any migration
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ============================================
// PHASE 1: BACKUP EXISTING CATEGORIES
// ============================================
async function backupExistingCategories() {
  console.log('\n📦 PHASE 1A: Backing up existing categories collection...');
  
  const categoriesSnapshot = await db.collection('categories').get();
  
  if (categoriesSnapshot.empty) {
    console.log('✅ No existing categories to backup');
    return 0;
  }

  const batch = db.batch();
  let count = 0;

  categoriesSnapshot.forEach(doc => {
    const backupRef = db.collection('_archived_old_categories').doc(doc.id);
    batch.set(backupRef, doc.data());
    count++;
  });

  await batch.commit();
  console.log(`✅ Backed up ${count} documents to _archived_old_categories`);
  return count;
}

// ============================================
// PHASE 1B: MIGRATE technician_categories → categories
// ============================================
async function migrateTechnicianCategories() {
  console.log('\n📦 PHASE 1B: Migrating technician_categories → categories...');
  
  const techCategoriesSnapshot = await db.collection('technician_categories').get();
  
  if (techCategoriesSnapshot.empty) {
    console.log('⚠️ No technician_categories found to migrate');
    return 0;
  }

  const batch = db.batch();
  let count = 0;

  techCategoriesSnapshot.forEach(doc => {
    const data = doc.data();
    const categoryRef = db.collection('categories').doc(doc.id);
    
    batch.set(categoryRef, {
      id: doc.id,
      name: data.name,
      isActive: data.isActive !== undefined ? data.isActive : true,
      order: data.order || 0,
      createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    count++;
  });

  await batch.commit();
  console.log(`✅ Migrated ${count} categories`);
  return count;
}

// ============================================
// PHASE 2: MIGRATE technician_subcategories → services
// ============================================
async function migrateTechnicianSubcategories() {
  console.log('\n📦 PHASE 2: Migrating technician_subcategories → services...');
  
  const techSubcategoriesSnapshot = await db.collection('technician_subcategories').get();
  
  if (techSubcategoriesSnapshot.empty) {
    console.log('⚠️ No technician_subcategories found to migrate');
    return 0;
  }

  const batches = [];
  let currentBatch = db.batch();
  let operationCount = 0;
  let totalCount = 0;

  for (const doc of techSubcategoriesSnapshot.docs) {
    const data = doc.data();
    const serviceRef = db.collection('services').doc(doc.id);
    
    currentBatch.set(serviceRef, {
      id: doc.id,
      name: data.name,
      categoryId: data.categoryId,
      isActive: data.isActive !== undefined ? data.isActive : true,
      order: data.order || 0,
      basePrice: data.basePrice || 0,
      description: data.description || '',
      createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    
    operationCount++;
    totalCount++;

    // Firestore batch limit is 500
    if (operationCount === 500) {
      batches.push(currentBatch.commit());
      currentBatch = db.batch();
      operationCount = 0;
    }
  }

  if (operationCount > 0) {
    batches.push(currentBatch.commit());
  }

  await Promise.all(batches);
  console.log(`✅ Migrated ${totalCount} services`);
  return totalCount;
}

// ============================================
// PHASE 3: VERIFICATION
// ============================================
async function verifyMigration() {
  console.log('\n🔍 PHASE 3: Verifying migration...');
  
  // Count categories
  const categoriesSnapshot = await db.collection('categories').get();
  const categoriesCount = categoriesSnapshot.size;
  console.log(`📊 Categories count: ${categoriesCount}`);
  
  // Count services
  const servicesSnapshot = await db.collection('services').get();
  const servicesCount = servicesSnapshot.size;
  console.log(`📊 Services count: ${servicesCount}`);
  
  // Check for orphan services
  const categoryIds = new Set(categoriesSnapshot.docs.map(doc => doc.id));
  let orphanCount = 0;
  
  servicesSnapshot.forEach(doc => {
    const categoryId = doc.data().categoryId;
    if (categoryId && !categoryIds.has(categoryId)) {
      console.log(`⚠️ Orphan service found: ${doc.id} (categoryId: ${categoryId})`);
      orphanCount++;
    }
  });
  
  if (orphanCount === 0) {
    console.log('✅ No orphan services found');
  } else {
    console.log(`⚠️ Found ${orphanCount} orphan services`);
  }
  
  // Sample data check
  console.log('\n📋 Sample Categories:');
  categoriesSnapshot.docs.slice(0, 3).forEach(doc => {
    console.log(`  - ${doc.id}: ${doc.data().name}`);
  });
  
  console.log('\n📋 Sample Services:');
  servicesSnapshot.docs.slice(0, 3).forEach(doc => {
    const data = doc.data();
    console.log(`  - ${doc.id}: ${data.name} (categoryId: ${data.categoryId})`);
  });
  
  return {
    categoriesCount,
    servicesCount,
    orphanCount
  };
}

// ============================================
// MAIN EXECUTION
// ============================================
async function main() {
  console.log('🚀 HOMEFIX CATEGORY SYSTEM MIGRATION');
  console.log('=====================================\n');
  
  try {
    // Phase 1A: Backup existing categories
    await backupExistingCategories();
    
    // Phase 1B: Migrate technician_categories
    const categoriesMigrated = await migrateTechnicianCategories();
    
    // Phase 2: Migrate technician_subcategories
    const servicesMigrated = await migrateTechnicianSubcategories();
    
    // Phase 3: Verify
    const verification = await verifyMigration();
    
    console.log('\n✅ MIGRATION COMPLETE');
    console.log('=====================');
    console.log(`Categories migrated: ${categoriesMigrated}`);
    console.log(`Services migrated: ${servicesMigrated}`);
    console.log(`Final categories count: ${verification.categoriesCount}`);
    console.log(`Final services count: ${verification.servicesCount}`);
    console.log(`Orphan services: ${verification.orphanCount}`);
    
    if (verification.categoriesCount >= 40 && verification.servicesCount >= 200) {
      console.log('\n🎉 SUCCESS: Migration meets expected thresholds (40+ categories, 200+ services)');
    } else {
      console.log('\n⚠️ WARNING: Migration counts below expected thresholds');
    }
    
  } catch (error) {
    console.error('\n❌ MIGRATION FAILED:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

main();
