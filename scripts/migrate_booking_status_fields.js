/**
 * Migration Script: Update Booking Status Fields
 * 
 * This script migrates existing booking documents to use standardized status fields:
 * - status → bookingStatus
 * - ADMIN_APPROVED → approved_by_admin
 * - PENDING_ADMIN → pending_admin_approval
 * - TECHNICIAN_ACCEPTED → technician_accepted
 * - IN_PROGRESS → service_in_progress
 * - COMPLETED → service_completed
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Status mapping
const STATUS_MAPPING = {
  'PENDING_ADMIN': 'pending_admin_approval',
  'ADMIN_APPROVED': 'approved_by_admin',
  'TECHNICIAN_ACCEPTED': 'technician_accepted',
  'IN_PROGRESS': 'service_in_progress',
  'COMPLETED': 'service_completed',
  'REJECTED': 'rejected',
  'CANCELLED': 'cancelled',
  
  // Handle lowercase variants
  'pending_admin': 'pending_admin_approval',
  'admin_approved': 'approved_by_admin',
  'technician_accepted': 'technician_accepted',
  'in_progress': 'service_in_progress',
  'completed': 'service_completed',
  'rejected': 'rejected',
  'cancelled': 'cancelled',
  
  // Handle mixed case
  'pending': 'pending_admin_approval',
  'approved': 'approved_by_admin',
  'accepted': 'technician_accepted',
  'progress': 'service_in_progress',
  'done': 'service_completed'
};

async function migrateBookingStatuses() {
  console.log('🚀 Starting booking status migration...');
  
  try {
    // Get all booking documents
    const bookingsSnapshot = await db.collection('bookings').get();
    console.log(`📊 Found ${bookingsSnapshot.docs.length} booking documents`);
    
    let migratedCount = 0;
    let skippedCount = 0;
    const batch = db.batch();
    let batchCount = 0;
    
    for (const doc of bookingsSnapshot.docs) {
      const data = doc.data();
      const updates = {};
      let needsUpdate = false;
      
      // Migrate status field to bookingStatus
      if (data.status && !data.bookingStatus) {
        const oldStatus = data.status;
        const newStatus = STATUS_MAPPING[oldStatus] || oldStatus.toLowerCase();
        
        updates.bookingStatus = newStatus;
        updates.status = admin.firestore.FieldValue.delete(); // Remove old field
        needsUpdate = true;
        
        console.log(`📝 ${doc.id}: ${oldStatus} → ${newStatus}`);
      }
      
      // Ensure bookingStatus exists (set default if missing)
      if (!data.bookingStatus && !updates.bookingStatus) {
        updates.bookingStatus = 'pending_admin_approval';
        needsUpdate = true;
        console.log(`📝 ${doc.id}: Added default status → pending_admin_approval`);
      }
      
      // Standardize existing bookingStatus values
      if (data.bookingStatus && STATUS_MAPPING[data.bookingStatus]) {
        const standardized = STATUS_MAPPING[data.bookingStatus];
        if (standardized !== data.bookingStatus) {
          updates.bookingStatus = standardized;
          needsUpdate = true;
          console.log(`📝 ${doc.id}: Standardized ${data.bookingStatus} → ${standardized}`);
        }
      }
      
      // Add updatedAt timestamp if missing
      if (!data.updatedAt) {
        updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
        needsUpdate = true;
      }
      
      if (needsUpdate) {
        batch.update(doc.ref, updates);
        migratedCount++;
        batchCount++;
        
        // Commit batch every 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          console.log(`✅ Committed batch of ${batchCount} updates`);
          batchCount = 0;
        }
      } else {
        skippedCount++;
      }
    }
    
    // Commit remaining updates
    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Committed final batch of ${batchCount} updates`);
    }
    
    console.log('\n🎉 Migration completed successfully!');
    console.log(`📊 Statistics:`);
    console.log(`   - Total documents: ${bookingsSnapshot.docs.length}`);
    console.log(`   - Migrated: ${migratedCount}`);
    console.log(`   - Skipped: ${skippedCount}`);
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

async function verifyMigration() {
  console.log('\n🔍 Verifying migration...');
  
  try {
    const bookingsSnapshot = await db.collection('bookings').get();
    let validCount = 0;
    let invalidCount = 0;
    
    const validStatuses = [
      'pending_admin_approval',
      'approved_by_admin', 
      'technician_accepted',
      'service_in_progress',
      'service_completed',
      'rejected',
      'cancelled'
    ];
    
    for (const doc of bookingsSnapshot.docs) {
      const data = doc.data();
      
      if (data.bookingStatus && validStatuses.includes(data.bookingStatus)) {
        validCount++;
      } else {
        invalidCount++;
        console.log(`⚠️  Invalid status in ${doc.id}: ${data.bookingStatus || 'MISSING'}`);
      }
      
      // Check for old status field
      if (data.status) {
        console.log(`⚠️  Old 'status' field still exists in ${doc.id}: ${data.status}`);
      }
    }
    
    console.log(`✅ Verification complete:`);
    console.log(`   - Valid bookingStatus: ${validCount}`);
    console.log(`   - Invalid/Missing: ${invalidCount}`);
    
    if (invalidCount === 0) {
      console.log('🎉 All booking documents have valid bookingStatus fields!');
    }
    
  } catch (error) {
    console.error('❌ Verification failed:', error);
  }
}

// Run migration
async function main() {
  await migrateBookingStatuses();
  await verifyMigration();
  
  console.log('\n✨ Migration script completed');
  process.exit(0);
}

main().catch(console.error);