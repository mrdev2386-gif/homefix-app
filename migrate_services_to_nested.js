/**
 * HomeFix Service Migration Script
 * 
 * Migrates services and subServices from root collections into Firebase-first nested structure.
 * 
 * FROM: services/{serviceId} and services/{serviceId}/subServices/{subId}
 * TO:   categories/{categoryId}/services/{serviceId} and categories/{categoryId}/services/{serviceId}/subServices/{subId}
 * 
 * ⚠️ RULES:
 * - DO NOT delete any existing data
 * - DO NOT overwrite existing nested docs
 * - Script is idempotent (safe to run multiple times)
 * - Uses batch writes where possible
 * - Logs everything clearly
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const fs = require('fs');
const path = require('path');

// Firebase project configuration
const PROJECT_ID = 'homefix-aa42d';

// Initialize Firebase Admin
let db;

function initializeFirebase() {
  try {
    // Try to use application default credentials
    initializeApp({
      projectId: PROJECT_ID
    });
  } catch (error) {
    if (error.code === 'app/duplicate-app') {
      console.log('Firebase app already initialized');
    } else {
      throw error;
    }
  }
  
  db = getFirestore();
  db.settings({ ignoreUndefinedProperties: true });
  console.log('Firebase Admin initialized successfully');
}

// Logging utilities
function log(level, category, message, details = {}) {
  const timestamp = new Date().toISOString();
  const logEntry = `[${timestamp}] [${level}] [${category}] ${message} ${JSON.stringify(details)}`;
  console.log(logEntry);
  
  // Also write to log file
  const logFile = path.join(__dirname, 'migration.log');
  fs.appendFileSync(logFile, logEntry + '\n');
}

function logService(category, serviceId, message = '') {
  log('MIGRATE', category, message, { serviceId });
}

function logSubService(serviceId, subId, category, message = '') {
  log('MIGRATE', category, message, { serviceId, subId });
}

function logVerify(categoryId, nestedServiceCount) {
  log('VERIFY', 'CATEGORY', '', { categoryId, nestedServiceCount });
}

// Migration statistics
const stats = {
  totalRootServices: 0,
  totalMigrated: 0,
  totalSkippedNoCategory: 0,
  totalSkippedAlreadyExists: 0,
  totalErrors: 0,
  totalSubServicesMigrated: 0,
  totalSubServicesSkipped: 0,
  totalSubServicesErrors: 0
};

// STEP 1: Migrate services from root to nested structure
async function migrateServices() {
  console.log('\n========== STEP 1: MIGRATING SERVICES ==========');
  
  const servicesRef = db.collection('services');
  const snapshot = await servicesRef.get();
  
  stats.totalRootServices = snapshot.size;
  log('INFO', 'COUNT', `Total root services found: ${snapshot.size}`);
  
  if (snapshot.empty) {
    log('INFO', 'NO_SERVICES', 'No services found in root collection');
    return;
  }
  
  // Process in batches of 500 (Firestore limit)
  const batch = db.batch();
  let batchCount = 0;
  
  for (const doc of snapshot.docs) {
    const serviceId = doc.id;
    const data = doc.data();
    
    try {
      // Check if categoryId exists
      const categoryId = data.categoryId;
      
      if (!categoryId) {
        // Skip and log
        stats.totalSkippedNoCategory++;
        logService('SKIP', serviceId, 'NO_CATEGORY - Service has no categoryId');
        continue;
      }
      
      // Build target path
      const targetPath = `categories/${categoryId}/services/${serviceId}`;
      const targetRef = db.doc(targetPath);
      
      // Check if target already exists
      const targetDoc = await targetRef.get();
      
      if (targetDoc.exists) {
        // Already exists - skip
        stats.totalSkippedAlreadyExists++;
        logService('SERVICE', serviceId, 'ALREADY_EXISTS');
        continue;
      }
      
      // Create the nested document with full data copy
      // Preserve original document ID
      const nestedData = {
        ...data,
        // Add migration metadata
        migratedAt: FieldValue.serverTimestamp(),
        originalPath: `services/${serviceId}`
      };
      
      // Add to batch
      batch.set(targetRef, nestedData);
      batchCount++;
      
      stats.totalMigrated++;
      logService('SERVICE', serviceId, `CREATED in category ${categoryId}`);
      
      // Commit batch when reaching limit
      if (batchCount >= 450) {
        await batch.commit();
        console.log(`  Committed batch of ${batchCount} services`);
        batchCount = 0;
      }
      
    } catch (error) {
      stats.totalErrors++;
      log('ERROR', 'SERVICE', `serviceId: ${serviceId}`, { message: error.message });
      console.error(`[MIGRATE][ERROR] serviceId: ${serviceId} message: ${error.message}`);
    }
  }
  
  // Commit remaining batch
  if (batchCount > 0) {
    await batch.commit();
    console.log(`  Committed final batch of ${batchCount} services`);
  }
  
  console.log('\n--- Service Migration Summary ---');
  console.log(`  Total root services: ${stats.totalRootServices}`);
  console.log(`  Migrated: ${stats.totalMigrated}`);
  console.log(`  Skipped (no category): ${stats.totalSkippedNoCategory}`);
  console.log(`  Skipped (already exists): ${stats.totalSkippedAlreadyExists}`);
  console.log(`  Errors: ${stats.totalErrors}`);
}

// STEP 2: Migrate subServices from root to nested structure
async function migrateSubServices() {
  console.log('\n========== STEP 2: MIGRATING SUBSERVICES ==========');
  
  // Get all services from root collection
  const servicesRef = db.collection('services');
  const servicesSnapshot = await servicesRef.get();
  
  if (servicesSnapshot.empty) {
    log('INFO', 'NO_SERVICES', 'No services found in root collection');
    return;
  }
  
  for (const serviceDoc of servicesSnapshot.docs) {
    const serviceId = serviceDoc.id;
    const serviceData = serviceDoc.data();
    const categoryId = serviceData.categoryId;
    
    if (!categoryId) {
      logSubService(serviceId, null, 'SKIP', 'NO_CATEGORY - Cannot migrate subServices without categoryId');
      continue;
    }
    
    try {
      // Get subServices from root path
      const subServicesRef = db.collection(`services/${serviceId}/subServices`);
      const subServicesSnapshot = await subServicesRef.get();
      
      if (subServicesSnapshot.empty) {
        logSubService(serviceId, null, 'SUBSERVICE', 'NONE_FOUND');
        continue;
      }
      
      console.log(`  Found ${subServicesSnapshot.size} subServices for service ${serviceId}`);
      
      // Process subServices
      const batch = db.batch();
      let batchCount = 0;
      
      for (const subDoc of subServicesSnapshot.docs) {
        const subId = subDoc.id;
        const subData = subDoc.data();
        
        try {
          // Build target path
          const targetPath = `categories/${categoryId}/services/${serviceId}/subServices/${subId}`;
          const targetRef = db.doc(targetPath);
          
          // Check if target already exists
          const targetDoc = await targetRef.get();
          
          if (targetDoc.exists) {
            // Already exists - skip
            stats.totalSubServicesSkipped++;
            logSubService(serviceId, subId, 'SUBSERVICE', 'ALREADY_EXISTS');
            continue;
          }
          
          // Create the nested subService document with full data copy
          const nestedData = {
            ...subData,
            // Add migration metadata
            migratedAt: FieldValue.serverTimestamp(),
            originalPath: `services/${serviceId}/subServices/${subId}`
          };
          
          // Add to batch
          batch.set(targetRef, nestedData);
          batchCount++;
          
          stats.totalSubServicesMigrated++;
          logSubService(serviceId, subId, 'SUBSERVICE', 'CREATED');
          
          // Commit batch when reaching limit
          if (batchCount >= 450) {
            await batch.commit();
            console.log(`    Committed batch of ${batchCount} subServices`);
            batchCount = 0;
          }
          
        } catch (error) {
          stats.totalSubServicesErrors++;
          log('ERROR', 'SUBSERVICE', `serviceId: ${serviceId} subId: ${subId}`, { message: error.message });
          console.error(`[MIGRATE][ERROR] serviceId: ${serviceId} subId: ${subId} message: ${error.message}`);
        }
      }
      
      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
        console.log(`    Committed final batch of ${batchCount} subServices`);
      }
      
    } catch (error) {
      log('ERROR', 'SERVICE', `serviceId: ${serviceId}`, { message: error.message });
      console.error(`[MIGRATE][ERROR] serviceId: ${serviceId} message: ${error.message}`);
    }
  }
  
  console.log('\n--- SubService Migration Summary ---');
  console.log(`  Migrated: ${stats.totalSubServicesMigrated}`);
  console.log(`  Skipped (already exists): ${stats.totalSubServicesSkipped}`);
  console.log(`  Errors: ${stats.totalSubServicesErrors}`);
}

// STEP 3: Verification
async function verifyMigration() {
  console.log('\n========== STEP 3: VERIFICATION ==========');
  
  // 1. Count root services
  const rootServicesSnapshot = await db.collection('services').get();
  const rootServicesCount = rootServicesSnapshot.size;
  
  // 2. Get all categories
  const categoriesSnapshot = await db.collection('categories').get();
  
  // 3. Count nested services per category
  let totalNestedServices = 0;
  const categoryCounts = [];
  
  console.log('\n[VERIFY][CATEGORIES]');
  
  for (const categoryDoc of categoriesSnapshot.docs) {
    const categoryId = categoryDoc.id;
    
    // Count services in this category
    const nestedServicesSnapshot = await db.collection(`categories/${categoryId}/services`).get();
    const nestedServiceCount = nestedServicesSnapshot.size;
    
    totalNestedServices += nestedServiceCount;
    categoryCounts.push({ categoryId, count: nestedServiceCount });
    
    logVerify(categoryId, nestedServiceCount);
    console.log(`  categoryId: ${categoryId}, nestedServiceCount: ${nestedServiceCount}`);
  }
  
  // 4. Sample one migrated service and count its subServices
  console.log('\n[VERIFY][SAMPLE_SERVICE]');
  
  if (categoryCounts.length > 0 && categoryCounts[0].count > 0) {
    const firstCategory = categoryCounts[0];
    const servicesSnapshot = await db.collection(`categories/${firstCategory.categoryId}/services`).limit(1).get();
    
    if (!servicesSnapshot.empty) {
      const sampleService = servicesSnapshot.docs[0];
      const sampleServiceId = sampleService.id;
      
      const subServicesSnapshot = await db.collection(`categories/${firstCategory.categoryId}/services/${sampleServiceId}/subServices`).get();
      const subServiceCount = subServicesSnapshot.size;
      
      console.log(`  Sample service: ${sampleServiceId}`);
      console.log(`  SubServices count: ${subServiceCount}`);
    }
  }
  
  // Print final verification summary
  console.log('\n--- Verification Summary ---');
  console.log(`  Total root services: ${rootServicesCount}`);
  console.log(`  Total nested services: ${totalNestedServices}`);
  console.log(`  Categories with services: ${categoryCounts.length}`);
  
  // Check success criteria
  const success = totalNestedServices > 0;
  console.log(`\n✅ Nested services populated: ${totalNestedServices > 0 ? 'YES' : 'NO'}`);
  console.log(`✅ SERVICE_COUNT > 0: ${totalNestedServices > 0 ? 'YES' : 'NO'}`);
  
  return {
    totalRootServices: rootServicesCount,
    totalNestedServices,
    categoryCounts,
    success
  };
}

// Main migration function
async function runMigration() {
  console.log('============================================');
  console.log('HomeFix Service Migration Script');
  console.log('============================================');
  console.log(`Started at: ${new Date().toISOString()}`);
  
  // Clear/initialize log file
  const logFile = path.join(__dirname, 'migration.log');
  fs.writeFileSync(logFile, `=== Migration started at ${new Date().toISOString()} ===\n`);
  
  try {
    // Initialize Firebase
    initializeFirebase();
    
    // Run migration steps
    await migrateServices();
    await migrateSubServices();
    
    // Run verification
    const verification = await verifyMigration();
    
    console.log('\n============================================');
    console.log('Migration Complete!');
    console.log('============================================');
    console.log(`Finished at: ${new Date().toISOString()}`);
    console.log(`\n=== FINAL STATISTICS ===`);
    console.log(`Total root services: ${stats.totalRootServices}`);
    console.log(`Total migrated: ${stats.totalMigrated}`);
    console.log(`Total skipped (no category): ${stats.totalSkippedNoCategory}`);
    console.log(`Total skipped (already exists): ${stats.totalSkippedAlreadyExists}`);
    console.log(`Total errors: ${stats.totalErrors}`);
    console.log(`Total subServices migrated: ${stats.totalSubServicesMigrated}`);
    console.log(`Total subServices skipped: ${stats.totalSubServicesSkipped}`);
    console.log(`Total subServices errors: ${stats.totalSubServicesErrors}`);
    console.log(`\n✅ Migration ${verification.success ? 'SUCCESSFUL' : 'FAILED'}`);
    
    // Return results for calling function
    return {
      totalRootServices: stats.totalRootServices,
      totalMigrated: stats.totalMigrated,
      totalSkippedNoCategory: stats.totalSkippedNoCategory,
      totalSkippedAlreadyExists: stats.totalSkippedAlreadyExists,
      totalErrors: stats.totalErrors,
      totalSubServicesMigrated: stats.totalSubServicesMigrated,
      totalSubServicesSkipped: stats.totalSubServicesSkipped,
      totalSubServicesErrors: stats.totalSubServicesErrors,
      verification
    };
    
  } catch (error) {
    console.error('\n❌ Migration Failed!');
    console.error('Error:', error.message);
    console.error(error.stack);
    throw error;
  }
}

// Export for use as module
module.exports = { runMigration };

// Run if executed directly
if (require.main === module) {
  runMigration()
    .then((result) => {
      console.log('\n=== EXECUTION RESULT ===');
      console.log(JSON.stringify(result, null, 2));
      process.exit(0);
    })
    .catch((error) => {
      console.error('\nExecution failed:', error.message);
      process.exit(1);
    });
}
