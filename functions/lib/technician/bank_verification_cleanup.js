"use strict";
/**
 * Bank Verification Auto-Cleanup
 *
 * CRITICAL: Scheduled function to clean up stuck "verifying" statuses
 * Runs every 10 minutes to prevent indefinite pending states
 *
 * \u2705 Prevents stuck verifications
 * \u2705 Auto-releases locks
 * \u2705 Cleans up old idempotency records
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
exports.cleanupOldIdempotencyRecords = exports.cleanupStuckBankVerifications = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const VERIFICATION_TIMEOUT_MS = 2 * 60 * 1000; // 2 minutes
/**
 * Scheduled function: Clean up stuck bank verifications
 * Runs every 10 minutes
 */
exports.cleanupStuckBankVerifications = functions
    .region('asia-south1')
    .runWith({ maxInstances: 1, timeoutSeconds: 540, memory: '256MB' })
    .pubsub.schedule('every 10 minutes')
    .onRun(async (context) => {
    console.log('Running cleanupStuckBankVerifications at', new Date().toISOString());
    const now = admin.firestore.Timestamp.now();
    const timeoutThreshold = admin.firestore.Timestamp.fromMillis(now.toMillis() - VERIFICATION_TIMEOUT_MS);
    try {
        // Find all technicians with stuck "verifying" status
        const stuckVerifications = await admin.firestore()
            .collection('technicians')
            .where('bankVerificationStatus', '==', 'verifying')
            .where('updatedAt', '<', timeoutThreshold)
            .limit(100)
            .get();
        if (stuckVerifications.empty) {
            console.log('[CLEANUP] No stuck verifications found');
            return null;
        }
        console.log(`[CLEANUP] Found ${stuckVerifications.size} stuck verifications`);
        const batch = admin.firestore().batch();
        let updateCount = 0;
        stuckVerifications.docs.forEach((doc) => {
            const techData = doc.data();
            console.log(`[CLEANUP] Fixing stuck verification - Technician: ${doc.id}`);
            batch.update(doc.ref, {
                bankVerificationStatus: 'failed',
                bankVerificationMessage: 'Verification timeout. Please retry.',
                verificationLock: false, // Release lock
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            // Log cleanup action
            batch.set(admin.firestore().collection('payment_logs').doc(), {
                technicianId: doc.id,
                action: 'bank_verification_cleanup',
                status: 'failed',
                reason: 'timeout',
                previousStatus: 'verifying',
                accountNumber: techData.bankAccountNumber ? `***${techData.bankAccountNumber.slice(-4)}` : 'unknown',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            updateCount++;
        });
        await batch.commit();
        console.log(`[CLEANUP] Successfully cleaned up ${updateCount} stuck verifications`);
        return { success: true, cleanedUp: updateCount };
    }
    catch (error) {
        console.error('[CLEANUP] Error during cleanup:', error);
        return { success: false, error: error };
    }
});
/**
 * Scheduled function: Clean up old idempotency records
 * Runs daily at 2 AM
 */
exports.cleanupOldIdempotencyRecords = functions
    .region('asia-south1')
    .runWith({ maxInstances: 1, timeoutSeconds: 540, memory: '256MB' })
    .pubsub.schedule('0 2 * * *')
    .timeZone('Asia/Kolkata')
    .onRun(async (context) => {
    console.log('Running cleanupOldIdempotencyRecords at', new Date().toISOString());
    const now = admin.firestore.Timestamp.now();
    try {
        // Find expired idempotency records
        const expiredRecords = await admin.firestore()
            .collection('verificationRequests')
            .where('expiresAt', '<', now)
            .limit(500)
            .get();
        if (expiredRecords.empty) {
            console.log('[CLEANUP] No expired idempotency records found');
            return null;
        }
        console.log(`[CLEANUP] Found ${expiredRecords.size} expired idempotency records`);
        const batch = admin.firestore().batch();
        let deleteCount = 0;
        expiredRecords.docs.forEach((doc) => {
            batch.delete(doc.ref);
            deleteCount++;
        });
        await batch.commit();
        console.log(`[CLEANUP] Successfully deleted ${deleteCount} expired idempotency records`);
        return { success: true, deleted: deleteCount };
    }
    catch (error) {
        console.error('[CLEANUP] Error during idempotency cleanup:', error);
        return { success: false, error: error };
    }
});
//# sourceMappingURL=bank_verification_cleanup.js.map