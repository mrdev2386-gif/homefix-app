/**
 * IDEMPOTENCY CLEANUP - Scheduled Function
 * 
 * Prevents booking_idempotency collection from growing infinitely
 * Runs daily to delete expired idempotency records (older than 24 hours)
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Scheduled function to clean up expired idempotency records
 * Runs daily at 2 AM UTC
 */
export const cleanupExpiredIdempotencyRecords = functions
  .region('asia-south1')
  .pubsub.schedule('0 2 * * *') // Daily at 2 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('[IDEMPOTENCY_CLEANUP] Starting cleanup job...');
    
    try {
      // Calculate cutoff time (24 hours ago)
      const cutoffTime = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 24 * 60 * 60 * 1000)
      );
      
      console.log(`[IDEMPOTENCY_CLEANUP] Deleting records older than: ${cutoffTime.toDate().toISOString()}`);
      
      // Query expired records (batch delete for performance)
      const expiredRecords = await db
        .collection('booking_idempotency')
        .where('createdAt', '<', cutoffTime)
        .limit(500) // Process in batches to avoid timeout
        .get();
      
      if (expiredRecords.empty) {
        console.log('[IDEMPOTENCY_CLEANUP] No expired records found');
        return null;
      }
      
      console.log(`[IDEMPOTENCY_CLEANUP] Found ${expiredRecords.size} expired records`);
      
      // Batch delete for performance
      const batch = db.batch();
      let deleteCount = 0;
      
      expiredRecords.docs.forEach((doc) => {
        batch.delete(doc.ref);
        deleteCount++;
      });
      
      await batch.commit();
      
      console.log(`[IDEMPOTENCY_CLEANUP] ✅ Successfully deleted ${deleteCount} expired records`);
      
      // If we hit the limit, schedule another run immediately
      if (expiredRecords.size === 500) {
        console.log('[IDEMPOTENCY_CLEANUP] More records to clean, will run again on next schedule');
      }
      
      return null;
    } catch (error: any) {
      console.error('[IDEMPOTENCY_CLEANUP] ❌ Error during cleanup:', error.message);
      throw error;
    }
  });

/**
 * Manual cleanup function (callable by admin)
 * Useful for immediate cleanup or testing
 */
export const manualCleanupIdempotency = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    // Verify admin
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
    }
    
    const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
    if (!adminDoc.exists) {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can run manual cleanup');
    }
    
    console.log(`[IDEMPOTENCY_CLEANUP] Manual cleanup triggered by admin: ${context.auth.uid}`);
    
    try {
      const cutoffTime = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 24 * 60 * 60 * 1000)
      );
      
      const expiredRecords = await db
        .collection('booking_idempotency')
        .where('createdAt', '<', cutoffTime)
        .get();
      
      if (expiredRecords.empty) {
        return { success: true, deletedCount: 0, message: 'No expired records found' };
      }
      
      const batch = db.batch();
      expiredRecords.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      
      console.log(`[IDEMPOTENCY_CLEANUP] ✅ Manual cleanup deleted ${expiredRecords.size} records`);
      
      return {
        success: true,
        deletedCount: expiredRecords.size,
        message: `Successfully deleted ${expiredRecords.size} expired idempotency records`,
      };
    } catch (error: any) {
      console.error('[IDEMPOTENCY_CLEANUP] ❌ Manual cleanup error:', error.message);
      throw new functions.https.HttpsError('internal', `Cleanup failed: ${error.message}`);
    }
  });
