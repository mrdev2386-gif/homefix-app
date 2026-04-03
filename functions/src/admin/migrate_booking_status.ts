import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * MIGRATION FUNCTION: Update ADMIN_APPROVED bookings to ASSIGNED
 * 
 * This function migrates existing bookings with status "ADMIN_APPROVED" 
 * to the new unified status "ASSIGNED" to ensure technician app visibility.
 * 
 * Usage: Call this function once to migrate existing data
 */
export const migrateBookingStatus = functions.region('asia-south1').https.onCall(
    async (data, context) => {
        // Admin authentication required
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }

        const userRecord = await admin.auth().getUser(context.auth.uid);
        if (!userRecord.customClaims?.admin) {
            throw new functions.https.HttpsError('permission-denied', 'Admin access required');
        }

        try {
            // Query for bookings with ADMIN_APPROVED status
            const adminApprovedBookings = await db.collection('bookings')
                .where('status', '==', 'ADMIN_APPROVED')
                .get();

            console.log(`Found ${adminApprovedBookings.size} bookings with ADMIN_APPROVED status`);

            if (adminApprovedBookings.empty) {
                return {
                    success: true,
                    message: 'No bookings found with ADMIN_APPROVED status',
                    migratedCount: 0
                };
            }

            // Batch update bookings
            const batch = db.batch();
            let migratedCount = 0;

            adminApprovedBookings.docs.forEach((doc) => {
                const booking = doc.data();
                
                // Update to new unified status
                batch.update(doc.ref, {
                    status: 'ASSIGNED',
                    bookingStatus: 'approved_by_admin', // For backward compatibility
                    migratedAt: admin.firestore.FieldValue.serverTimestamp(),
                    migratedBy: context.auth!.uid,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                migratedCount++;
                console.log(`Migrating booking ${doc.id}: ${booking.status} -> ASSIGNED`);
            });

            // Execute batch update
            await batch.commit();

            console.log(`Successfully migrated ${migratedCount} bookings`);

            return {
                success: true,
                message: `Successfully migrated ${migratedCount} bookings from ADMIN_APPROVED to ASSIGNED`,
                migratedCount
            };

        } catch (error: any) {
            console.error('Error migrating booking status:', error);
            throw new functions.https.HttpsError('internal', error.message);
        }
    }
);

/**
 * VERIFICATION FUNCTION: Check booking status distribution
 * 
 * This function provides a summary of booking statuses to verify migration
 */
export const verifyBookingStatuses = functions.region('asia-south1').https.onCall(
    async (data, context) => {
        // Admin authentication required
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }

        const userRecord = await admin.auth().getUser(context.auth.uid);
        if (!userRecord.customClaims?.admin) {
            throw new functions.https.HttpsError('permission-denied', 'Admin access required');
        }

        try {
            const statusCounts: Record<string, number> = {};

            // Get all bookings and count by status
            const allBookings = await db.collection('bookings').get();

            allBookings.docs.forEach((doc) => {
                const booking = doc.data();
                const status = booking.status || 'undefined';
                statusCounts[status] = (statusCounts[status] || 0) + 1;
            });

            return {
                success: true,
                totalBookings: allBookings.size,
                statusDistribution: statusCounts
            };

        } catch (error: any) {
            console.error('Error verifying booking statuses:', error);
            throw new functions.https.HttpsError('internal', error.message);
        }
    }
);