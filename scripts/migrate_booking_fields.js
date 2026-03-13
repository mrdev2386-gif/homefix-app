/**
 * Migration Script: Standardize Booking Fields
 * 
 * This script migrates existing booking documents to use standardized field names:
 * - status -> bookingStatus
 * - assignedTechnicianId -> technicianId
 * - ADMIN_APPROVED -> approved_by_admin
 * - TECHNICIAN_ACCEPTED -> technician_accepted
 * - IN_PROGRESS -> service_in_progress
 * - COMPLETED -> service_completed
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Status mapping
const STATUS_MAPPING = {
  'PENDING_ADMIN_APPROVAL': 'pending_admin_approval',
  'ADMIN_APPROVED': 'approved_by_admin',
  'TECHNICIAN_ACCEPTED': 'technician_accepted',
  'IN_PROGRESS': 'service_in_progress',
  'COMPLETED': 'service_completed',
  'REJECTED': 'rejected'
};

async function migrateBookingFields() {
  console.log('🚀 Starting booking fields migration...');
  
  try {
    // Get all booking documents
    const bookingsSnapshot = await db.collection('bookings').get();
    console.log(`📊 Found ${bookingsSnapshot.docs.length} booking documents`);
    
    let migratedCount = 0;
    const batch = db.batch();
    
    for (const doc of bookingsSnapshot.docs) {
      const data = doc.data();
      const updates = {};
      let needsUpdate = false;
      
      // Migrate status field to bookingStatus
      if (data.status && !data.bookingStatus) {
        const mappedStatus = STATUS_MAPPING[data.status] || data.status.toLowerCase();
        updates.bookingStatus = mappedStatus;
        needsUpdate = true;
        console.log(`📝 ${doc.id}: status "${data.status}" -> bookingStatus "${mappedStatus}"`);
      }
      
      // Migrate assignedTechnicianId to technicianId
      if (data.assignedTechnicianId && !data.technicianId) {
        updates.technicianId = data.assignedTechnicianId;
        needsUpdate = true;
        console.log(`📝 ${doc.id}: assignedTechnicianId -> technicianId`);
      }
      
      // Migrate assignedTechnicianName to technicianName
      if (data.assignedTechnicianName && !data.technicianName) {
        updates.technicianName = data.assignedTechnicianName;
        needsUpdate = true;
        console.log(`📝 ${doc.id}: assignedTechnicianName -> technicianName`);
      }
      
      if (needsUpdate) {
        updates.migratedAt = admin.firestore.FieldValue.serverTimestamp();
        batch.update(doc.ref, updates);
        migratedCount++;
      }
    }
    
    if (migratedCount > 0) {
      await batch.commit();
      console.log(`✅ Successfully migrated ${migratedCount} booking documents`);
    } else {
      console.log('✅ No documents needed migration');
    }
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

async function createFirestoreIndex() {
  console.log('📋 Creating Firestore composite index...');
  console.log('Please create this index manually in Firebase Console:');
  console.log('Collection: bookings');
  console.log('Fields:');
  console.log('  - technicianId (Ascending)');
  console.log('  - bookingStatus (Ascending)');
  console.log('  - createdAt (Descending)');
  console.log('');
  console.log('Index URL: https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/indexes');
}

// Run migration
async function main() {
  try {
    await migrateBookingFields();
    await createFirestoreIndex();
    console.log('🎉 Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('💥 Migration failed:', error);
    process.exit(1);
  }
}

main();