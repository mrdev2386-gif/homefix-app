/**
 * MIGRATION SCRIPT: Initialize Status History for Existing Bookings
 * 
 * This script safely adds statusHistory to all existing bookings that don't have it.
 * 
 * SAFETY:
 * - Only processes bookings without statusHistory
 * - Uses current status only (doesn't assume past states)
 * - Non-destructive (doesn't modify existing data)
 * - Batch processing to avoid timeouts
 * - Comprehensive logging
 * 
 * USAGE:
 * node lib/scripts/migrate_booking_status_history.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../../scripts/serviceAccountKey.json');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

/**
 * Initialize status history for a single booking
 */
async function initializeBookingStatusHistory(bookingId, bookingData) {
  try {
    // Check if history already exists
    if (bookingData.statusHistory && Array.isArray(bookingData.statusHistory) && bookingData.statusHistory.length > 0) {
      console.log(`[SKIP] Booking ${bookingId} already has history (${bookingData.statusHistory.length} entries)`);
      return { status: 'skipped', reason: 'already_has_history' };
    }

    const currentStatus = bookingData.status || bookingData.bookingStatus || 'pending';
    const createdAt = bookingData.createdAt || admin.firestore.Timestamp.now();

    console.log(`[INIT] Booking ${bookingId}: status=${currentStatus}`);

    // Create initial history entry
    const initialHistory = [
      {
        status: currentStatus,
        timestamp: createdAt,
      },
    ];

    // Update booking with history
    await db.collection('bookings').doc(bookingId).update({
      statusHistory: initialHistory,
    });

    console.log(`[SUCCESS] Booking ${bookingId}: history initialized`);
    return { status: 'success' };
  } catch (error) {
    console.error(`[ERROR] Booking ${bookingId}:`, error.message);
    return { status: 'error', error: error.message };
  }
}

/**
 * Main migration function
 */
async function migrateAllBookings() {
  console.log('='.repeat(60));
  console.log('BOOKING STATUS HISTORY MIGRATION');
  console.log('='.repeat(60));
  console.log('');

  const stats = {
    total: 0,
    success: 0,
    skipped: 0,
    error: 0,
  };

  try {
    // Fetch all bookings
    console.log('[FETCH] Loading all bookings...');
    const bookingsSnapshot = await db.collection('bookings').get();
    stats.total = bookingsSnapshot.size;

    console.log(`[FETCH] Found ${stats.total} bookings`);
    console.log('');

    // Process in batches of 500
    const batchSize = 500;
    const bookings = bookingsSnapshot.docs;

    for (let i = 0; i < bookings.length; i += batchSize) {
      const batch = bookings.slice(i, i + batchSize);
      const batchNumber = Math.floor(i / batchSize) + 1;
      const totalBatches = Math.ceil(bookings.length / batchSize);

      console.log(`[BATCH ${batchNumber}/${totalBatches}] Processing ${batch.length} bookings...`);

      // Process batch in parallel
      const promises = batch.map(async (doc) => {
        const result = await initializeBookingStatusHistory(doc.id, doc.data());
        
        if (result.status === 'success') {
          stats.success++;
        } else if (result.status === 'skipped') {
          stats.skipped++;
        } else if (result.status === 'error') {
          stats.error++;
        }
      });

      await Promise.all(promises);

      console.log(`[BATCH ${batchNumber}/${totalBatches}] Complete`);
      console.log('');
    }

    // Print final stats
    console.log('='.repeat(60));
    console.log('MIGRATION COMPLETE');
    console.log('='.repeat(60));
    console.log(`Total bookings:     ${stats.total}`);
    console.log(`Successfully migrated: ${stats.success}`);
    console.log(`Skipped (already had history): ${stats.skipped}`);
    console.log(`Errors:             ${stats.error}`);
    console.log('='.repeat(60));

    // Exit
    process.exit(0);
  } catch (error) {
    console.error('[FATAL ERROR]', error);
    process.exit(1);
  }
}

// Run migration
migrateAllBookings();
