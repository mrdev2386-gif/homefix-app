"use strict";
/**
 * STATUS HISTORY TRACKING UTILITY
 *
 * Provides robust backend-driven status history tracking for all booking operations.
 *
 * FEATURES:
 * - Automatic statusHistory append on every status update
 * - Server-side timestamps using FieldValue.serverTimestamp()
 * - Duplicate consecutive status prevention
 * - Backward compatibility (auto-creates history for old bookings)
 * - Atomic updates using arrayUnion
 * - Comprehensive logging
 * - Error-safe fallback
 *
 * USAGE:
 * import { updateBookingStatus, initializeStatusHistory } from './shared/status_history_tracker';
 *
 * // Update status with history tracking
 * await updateBookingStatus(transaction, bookingRef, 'accepted', bookingData);
 *
 * // Or use standalone
 * await updateBookingStatusStandalone(bookingId, 'in_progress');
 */
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
exports.updateBookingStatus = updateBookingStatus;
exports.updateBookingStatusStandalone = updateBookingStatusStandalone;
exports.initializeStatusHistory = initializeStatusHistory;
exports.initializeStatusHistoryStandalone = initializeStatusHistoryStandalone;
exports.updateBookingStatusSafe = updateBookingStatusSafe;
exports.batchInitializeStatusHistory = batchInitializeStatusHistory;
exports.getStatusHistory = getStatusHistory;
exports.validateStatusHistoryIntegrity = validateStatusHistoryIntegrity;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * Update booking status with automatic history tracking
 *
 * @param transaction - Firestore transaction (for atomic updates)
 * @param bookingRef - Booking document reference
 * @param newStatus - New status to set
 * @param currentBookingData - Current booking data (must include current status)
 * @param additionalUpdates - Optional additional fields to update
 * @returns void
 *
 * CRITICAL: This function MUST be called within a transaction for atomicity
 */
function updateBookingStatus(transaction, bookingRef, newStatus, currentBookingData, additionalUpdates = {}) {
    const bookingId = bookingRef.id;
    const oldStatus = currentBookingData.bookingStatus || currentBookingData.status || 'unknown';
    const existingHistory = currentBookingData.statusHistory || [];
    console.log(`[STATUS TRACKING] Booking: ${bookingId}`);
    console.log(`[STATUS TRACKING] Old: ${oldStatus} → New: ${newStatus}`);
    console.log(`[STATUS TRACKING] History count before: ${existingHistory.length}`);
    // Validate status
    if (!newStatus || typeof newStatus !== 'string') {
        console.error(`[STATUS TRACKING] Invalid newStatus: ${newStatus}`);
        throw new Error('Invalid status value');
    }
    // Check if status actually changed
    if (oldStatus === newStatus) {
        console.log(`[STATUS TRACKING] Status unchanged (${newStatus}), skipping history append`);
        // Still update other fields if provided
        if (Object.keys(additionalUpdates).length > 0) {
            transaction.update(bookingRef, {
                status: newStatus,
                bookingStatus: newStatus,
                ...additionalUpdates,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        return;
    }
    // Check for duplicate consecutive status
    const lastHistoryEntry = existingHistory.length > 0
        ? existingHistory[existingHistory.length - 1]
        : null;
    if (lastHistoryEntry && lastHistoryEntry.status === newStatus) {
        console.log(`[STATUS TRACKING] Duplicate consecutive status detected (${newStatus}), skipping history append`);
        // Update status and other fields without adding to history
        transaction.update(bookingRef, {
            status: newStatus,
            bookingStatus: newStatus,
            ...additionalUpdates,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
    }
    // Create new history entry
    // NOTE: FieldValue.serverTimestamp() cannot be used inside arrayUnion — use Timestamp.now() instead
    const newHistoryEntry = {
        status: newStatus,
        timestamp: admin.firestore.Timestamp.now(),
    };
    // Update booking with new status and append to history
    transaction.update(bookingRef, {
        status: newStatus,
        bookingStatus: newStatus,
        statusHistory: admin.firestore.FieldValue.arrayUnion(newHistoryEntry),
        ...additionalUpdates,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`[STATUS TRACKING] History count after: ${existingHistory.length + 1}`);
    console.log(`[STATUS TRACKING] ✅ Status updated successfully`);
}
/**
 * Standalone version (creates its own transaction)
 *
 * Use this when you're not already in a transaction context
 *
 * @param bookingId - Booking document ID
 * @param newStatus - New status to set
 * @param additionalUpdates - Optional additional fields to update
 * @returns Promise<void>
 */
async function updateBookingStatusStandalone(bookingId, newStatus, additionalUpdates = {}) {
    const bookingRef = db.collection('bookings').doc(bookingId);
    try {
        await db.runTransaction(async (transaction) => {
            const bookingDoc = await transaction.get(bookingRef);
            if (!bookingDoc.exists) {
                throw new Error(`Booking not found: ${bookingId}`);
            }
            const bookingData = bookingDoc.data();
            updateBookingStatus(transaction, bookingRef, newStatus, bookingData, additionalUpdates);
        });
    }
    catch (error) {
        console.error(`[STATUS TRACKING] Error updating booking ${bookingId}:`, error.message);
        throw error;
    }
}
/**
 * Initialize status history for existing bookings without history
 *
 * This function is SAFE for backward compatibility:
 * - Only creates history if it doesn't exist
 * - Uses current status only (doesn't assume past states)
 * - Non-destructive
 *
 * @param transaction - Firestore transaction
 * @param bookingRef - Booking document reference
 * @param currentBookingData - Current booking data
 * @returns void
 */
function initializeStatusHistory(transaction, bookingRef, currentBookingData) {
    const bookingId = bookingRef.id;
    const existingHistory = currentBookingData.statusHistory;
    // Only initialize if history doesn't exist
    if (existingHistory && Array.isArray(existingHistory) && existingHistory.length > 0) {
        console.log(`[STATUS TRACKING] Booking ${bookingId} already has history (${existingHistory.length} entries), skipping initialization`);
        return;
    }
    const currentStatus = currentBookingData.status || 'pending';
    const createdAt = currentBookingData.createdAt || admin.firestore.FieldValue.serverTimestamp();
    console.log(`[STATUS TRACKING] Initializing history for booking ${bookingId} with status: ${currentStatus}`);
    // Create initial history entry with current status
    const initialHistory = [
        {
            status: currentStatus,
            timestamp: createdAt,
        },
    ];
    transaction.update(bookingRef, {
        statusHistory: initialHistory,
    });
    console.log(`[STATUS TRACKING] ✅ History initialized for booking ${bookingId}`);
}
/**
 * Standalone version of initializeStatusHistory
 *
 * @param bookingId - Booking document ID
 * @returns Promise<void>
 */
async function initializeStatusHistoryStandalone(bookingId) {
    const bookingRef = db.collection('bookings').doc(bookingId);
    try {
        await db.runTransaction(async (transaction) => {
            const bookingDoc = await transaction.get(bookingRef);
            if (!bookingDoc.exists) {
                throw new Error(`Booking not found: ${bookingId}`);
            }
            const bookingData = bookingDoc.data();
            initializeStatusHistory(transaction, bookingRef, bookingData);
        });
    }
    catch (error) {
        console.error(`[STATUS TRACKING] Error initializing history for booking ${bookingId}:`, error.message);
        throw error;
    }
}
/**
 * Safe wrapper for status updates with error fallback
 *
 * If history update fails, it will still update the status
 * to prevent blocking the main operation
 *
 * @param transaction - Firestore transaction
 * @param bookingRef - Booking document reference
 * @param newStatus - New status to set
 * @param currentBookingData - Current booking data
 * @param additionalUpdates - Optional additional fields to update
 * @returns void
 */
function updateBookingStatusSafe(transaction, bookingRef, newStatus, currentBookingData, additionalUpdates = {}) {
    try {
        updateBookingStatus(transaction, bookingRef, newStatus, currentBookingData, additionalUpdates);
    }
    catch (error) {
        console.error(`[STATUS TRACKING] Error updating status with history, falling back to status-only update:`, error.message);
        // Fallback: Update status without history
        transaction.update(bookingRef, {
            status: newStatus,
            ...additionalUpdates,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
}
/**
 * Batch initialize status history for multiple bookings
 *
 * Useful for migration scripts
 *
 * @param bookingIds - Array of booking IDs
 * @param batchSize - Number of bookings to process per batch (default: 500)
 * @returns Promise<{ success: number; failed: number; skipped: number }>
 */
async function batchInitializeStatusHistory(bookingIds, batchSize = 500) {
    let success = 0;
    let failed = 0;
    let skipped = 0;
    console.log(`[STATUS TRACKING] Starting batch initialization for ${bookingIds.length} bookings`);
    // Process in batches
    for (let i = 0; i < bookingIds.length; i += batchSize) {
        const batch = bookingIds.slice(i, i + batchSize);
        console.log(`[STATUS TRACKING] Processing batch ${Math.floor(i / batchSize) + 1} (${batch.length} bookings)`);
        const promises = batch.map(async (bookingId) => {
            try {
                await initializeStatusHistoryStandalone(bookingId);
                success++;
            }
            catch (error) {
                if (error.message.includes('already has history')) {
                    skipped++;
                }
                else {
                    console.error(`[STATUS TRACKING] Failed to initialize history for ${bookingId}:`, error.message);
                    failed++;
                }
            }
        });
        await Promise.all(promises);
    }
    console.log(`[STATUS TRACKING] Batch initialization complete: ${success} success, ${failed} failed, ${skipped} skipped`);
    return { success, failed, skipped };
}
/**
 * Get status history for a booking
 *
 * @param bookingId - Booking document ID
 * @returns Promise<StatusHistoryEntry[]>
 */
async function getStatusHistory(bookingId) {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
        throw new Error(`Booking not found: ${bookingId}`);
    }
    const bookingData = bookingDoc.data();
    return bookingData.statusHistory || [];
}
/**
 * Validate status history integrity
 *
 * Checks if the last history entry matches the current status
 *
 * @param bookingId - Booking document ID
 * @returns Promise<{ valid: boolean; message: string }>
 */
async function validateStatusHistoryIntegrity(bookingId) {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
        return { valid: false, message: 'Booking not found' };
    }
    const bookingData = bookingDoc.data();
    const currentStatus = bookingData.status;
    const statusHistory = bookingData.statusHistory || [];
    if (statusHistory.length === 0) {
        return { valid: false, message: 'No status history found' };
    }
    const lastHistoryEntry = statusHistory[statusHistory.length - 1];
    if (lastHistoryEntry.status !== currentStatus) {
        return {
            valid: false,
            message: `Status mismatch: current=${currentStatus}, last history=${lastHistoryEntry.status}`,
        };
    }
    return { valid: true, message: 'Status history is valid' };
}
//# sourceMappingURL=status_history_tracker.js.map