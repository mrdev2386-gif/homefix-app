"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyBookingStatuses = exports.migrateBookingStatus = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * MIGRATION FUNCTION: Update ADMIN_APPROVED bookings to ASSIGNED
 *
 * This function migrates existing bookings with status "ADMIN_APPROVED"
 * to the new unified status "ASSIGNED" to ensure technician app visibility.
 *
 * Usage: Call this function once to migrate existing data
 */
exports.migrateBookingStatus = functions.region('asia-south1').https.onCall(async (data, context) => {
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
                migratedBy: context.auth.uid,
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
    }
    catch (error) {
        console.error('Error migrating booking status:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * VERIFICATION FUNCTION: Check booking status distribution
 *
 * This function provides a summary of booking statuses to verify migration
 */
exports.verifyBookingStatuses = functions.region('asia-south1').https.onCall(async (data, context) => {
    // Admin authentication required
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }
    const userRecord = await admin.auth().getUser(context.auth.uid);
    if (!userRecord.customClaims?.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }
    try {
        const statusCounts = {};
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
    }
    catch (error) {
        console.error('Error verifying booking statuses:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
//# sourceMappingURL=migrate_booking_status.js.map