/**
 * Migration Script: Standardize Booking Status Fields
 * 
 * This script migrates existing booking documents to use standardized field names and values:
 * 
 * FIELD MIGRATIONS:
 * - status → bookingStatus
 * - assignedTechnicianId → technicianId
 * 
 * STATUS VALUE MIGRATIONS:
 * - ADMIN_APPROVED → approved_by_admin
 * - PENDING_ADMIN_APPROVAL → pending_admin_approval
 * - TECHNICIAN_ACCEPTED → technician_accepted
 * - IN_PROGRESS → service_in_progress
 * - COMPLETED → service_completed
 * - pending_admin_review → pending_admin_approval
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Status value mapping
const STATUS_MAPPING = {
  // Old uppercase constants to new lowercase
  'PENDING_ADMIN_APPROVAL': 'pending_admin_approval',
  'ADMIN_APPROVED': 'approved_by_admin',
  'TECHNICIAN_ACCEPTED': 'technician_accepted',
  'IN_PROGRESS': 'service_in_progress',
  'COMPLETED': 'service_completed',
  'REJECTED': 'rejected',
  
  // Legacy status values
  'pending_admin_review': 'pending_admin_approval',
  'admin_approved': 'approved_by_admin',
  'in_progress': 'service_in_progress',
  'completed': 'service_completed',
  
  // Already correct values (no change needed)
  'pending_admin_approval': 'pending_admin_approval',
  'approved_by_admin': 'approved_by_admin',
  'technician_accepted': 'technician_accepted',
  'service_in_progress': 'service_in_progress',
  'service_completed': 'service_completed',
  'rejected': 'rejected'
};

async function migrateBookingFields() {
  console.log('🚀 Starting booking fields migration...');
  
  try {
    // Get all booking documents
    const bookingsSnapshot = await db.collection('bookings').get();
    console.log(`📊 Found ${bookingsSnapshot.docs.length} booking documents`);
    
    let migratedCount = 0;
    let batchCount = 0;
    let batch = db.batch();
    
    for (const doc of bookingsSnapshot.docs) {
      const data = doc.data();
      const updates = {};
      let needsUpdate = false;
      
      // STEP 1: Migrate status field to bookingStatus
      if (data.status && !data.bookingStatus) {\n        const mappedStatus = STATUS_MAPPING[data.status] || data.status.toLowerCase();\n        updates.bookingStatus = mappedStatus;\n        needsUpdate = true;\n        console.log(`📝 ${doc.id}: status \"${data.status}\" → bookingStatus \"${mappedStatus}\"`);\n      }\n      \n      // STEP 2: Standardize existing bookingStatus values\n      if (data.bookingStatus && STATUS_MAPPING[data.bookingStatus] && STATUS_MAPPING[data.bookingStatus] !== data.bookingStatus) {\n        const mappedStatus = STATUS_MAPPING[data.bookingStatus];\n        updates.bookingStatus = mappedStatus;\n        needsUpdate = true;\n        console.log(`📝 ${doc.id}: bookingStatus \"${data.bookingStatus}\" → \"${mappedStatus}\"`);\n      }\n      \n      // STEP 3: Migrate assignedTechnicianId to technicianId\n      if (data.assignedTechnicianId && !data.technicianId) {\n        updates.technicianId = data.assignedTechnicianId;\n        needsUpdate = true;\n        console.log(`📝 ${doc.id}: assignedTechnicianId → technicianId`);\n      }\n      \n      // STEP 4: Migrate assignedTechnicianName to technicianName\n      if (data.assignedTechnicianName && !data.technicianName) {\n        updates.technicianName = data.assignedTechnicianName;\n        needsUpdate = true;\n        console.log(`📝 ${doc.id}: assignedTechnicianName → technicianName`);\n      }\n      \n      if (needsUpdate) {\n        updates.migratedAt = admin.firestore.FieldValue.serverTimestamp();\n        updates.migrationVersion = '1.0';\n        batch.update(doc.ref, updates);\n        migratedCount++;\n        batchCount++;\n        \n        // Commit batch every 500 operations (Firestore limit)\n        if (batchCount >= 500) {\n          await batch.commit();\n          console.log(`✅ Committed batch of ${batchCount} updates`);\n          batch = db.batch();\n          batchCount = 0;\n        }\n      }\n    }\n    \n    // Commit remaining updates\n    if (batchCount > 0) {\n      await batch.commit();\n      console.log(`✅ Committed final batch of ${batchCount} updates`);\n    }\n    \n    if (migratedCount > 0) {\n      console.log(`✅ Successfully migrated ${migratedCount} booking documents`);\n    } else {\n      console.log('✅ No documents needed migration');\n    }\n    \n  } catch (error) {\n    console.error('❌ Migration failed:', error);\n    throw error;\n  }\n}\n\nasync function verifyMigration() {\n  console.log('🔍 Verifying migration results...');\n  \n  try {\n    const bookingsSnapshot = await db.collection('bookings').get();\n    let statusFieldCount = 0;\n    let bookingStatusFieldCount = 0;\n    let assignedTechnicianIdCount = 0;\n    let technicianIdCount = 0;\n    \n    for (const doc of bookingsSnapshot.docs) {\n      const data = doc.data();\n      \n      if (data.status) statusFieldCount++;\n      if (data.bookingStatus) bookingStatusFieldCount++;\n      if (data.assignedTechnicianId) assignedTechnicianIdCount++;\n      if (data.technicianId) technicianIdCount++;\n    }\n    \n    console.log('📊 Migration Results:');\n    console.log(`   Documents with 'status' field: ${statusFieldCount}`);\n    console.log(`   Documents with 'bookingStatus' field: ${bookingStatusFieldCount}`);\n    console.log(`   Documents with 'assignedTechnicianId' field: ${assignedTechnicianIdCount}`);\n    console.log(`   Documents with 'technicianId' field: ${technicianIdCount}`);\n    \n    if (statusFieldCount > 0) {\n      console.log('⚠️  Warning: Some documents still have old \"status\" field');\n    }\n    \n    if (assignedTechnicianIdCount > 0) {\n      console.log('⚠️  Warning: Some documents still have old \"assignedTechnicianId\" field');\n    }\n    \n  } catch (error) {\n    console.error('❌ Verification failed:', error);\n  }\n}\n\nasync function createFirestoreIndex() {\n  console.log('📋 Required Firestore Composite Index:');\n  console.log('');\n  console.log('Collection: bookings');\n  console.log('Fields:');\n  console.log('  1. technicianId (Ascending)');\n  console.log('  2. bookingStatus (Ascending)');\n  console.log('  3. createdAt (Descending)');\n  console.log('');\n  console.log('🔗 Create index at: https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/indexes');\n  console.log('');\n  console.log('📝 Index creation command (if using Firebase CLI):');\n  console.log('firebase firestore:indexes');\n}\n\n// Run migration\nasync function main() {\n  try {\n    console.log('🏁 Starting HomeFix Booking Migration');\n    console.log('=====================================');\n    \n    await migrateBookingFields();\n    await verifyMigration();\n    await createFirestoreIndex();\n    \n    console.log('');\n    console.log('🎉 Migration completed successfully!');\n    console.log('');\n    console.log('📋 Next Steps:');\n    console.log('1. Create the Firestore composite index (see above)');\n    console.log('2. Deploy the updated Cloud Functions');\n    console.log('3. Test the booking flow:');\n    console.log('   - Customer creates booking → pending_admin_approval');\n    console.log('   - Admin approves booking → approved_by_admin');\n    console.log('   - Technician sees job in job screen immediately');\n    \n    process.exit(0);\n  } catch (error) {\n    console.error('💥 Migration failed:', error);\n    process.exit(1);\n  }\n}\n\nmain();