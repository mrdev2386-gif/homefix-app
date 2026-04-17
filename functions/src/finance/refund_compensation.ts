/**
 * Refund Compensation System
 * FIX 3: REFUND + WALLET CONSISTENCY
 * 
 * Handles cases where refund succeeds but wallet adjustment fails
 * Provides retry mechanism and manual review process
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin } from '../shared/utils';

const LOG_PREFIX = '[REFUND_COMPENSATION]';

/**
 * Retry wallet adjustment for a failed refund compensation
 * FIX 3: Retry-safe wallet adjustment
 */
async function retryWalletAdjustment(compensationId: string): Promise<{
    success: boolean;
    error?: string;
}> {
    try {
        const compensationRef = db.collection('refund_compensations').doc(compensationId);
        const compensationDoc = await compensationRef.get();

        if (!compensationDoc.exists) {
            return { success: false, error: 'Compensation record not found' };
        }

        const compensation = compensationDoc.data()!;

        // Check if already processed
        if (compensation.status === 'completed') {
            console.log(`${LOG_PREFIX} Compensation already completed: ${compensationId}`);
            return { success: true };
        }

        const { technicianId, refundAmount, bookingId, refundId } = compensation;

        // Get current wallet balance
        const walletRef = db.collection('technician_wallets').doc(technicianId);
        const walletDoc = await walletRef.get();

        if (!walletDoc.exists) {
            return { success: false, error: 'Wallet not found' };
        }

        const walletData = walletDoc.data()!;
        const currentBalance = walletData.availableBalance || 0;

        // Check if sufficient balance now
        if (currentBalance < refundAmount) {
            console.warn(`${LOG_PREFIX} Still insufficient balance - Technician: ${technicianId}, Balance: ₹${currentBalance}, Required: ₹${refundAmount}`);
            
            // Update compensation status
            await compensationRef.update({
                status: 'pending_manual_review',
                lastRetryAt: admin.firestore.FieldValue.serverTimestamp(),
                retryCount: admin.firestore.FieldValue.increment(1),
                currentBalance: currentBalance
            });

            return { success: false, error: 'Insufficient balance' };
        }

        // Perform wallet adjustment atomically
        await db.runTransaction(async (transaction) => {
            // Re-check balance inside transaction
            const currentWalletDoc = await transaction.get(walletRef);
            const currentWalletData = currentWalletDoc.data()!;
            const txBalance = currentWalletData.availableBalance || 0;

            if (txBalance < refundAmount) {
                throw new Error('Insufficient balance in transaction');
            }

            // Deduct from wallet
            transaction.update(walletRef, {
                availableBalance: admin.firestore.FieldValue.increment(-refundAmount),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Log wallet transaction
            const txnRef = walletRef.collection('transactions').doc();
            transaction.set(txnRef, {
                type: 'debit',
                source: 'refund_compensation',
                status: 'completed',
                amount: refundAmount,
                fee: 0,
                referenceId: bookingId,
                refundId: refundId,
                compensationId: compensationId,
                description: `Refund compensation for booking`,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Mark compensation as completed
            transaction.update(compensationRef, {
                status: 'completed',
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
                finalBalance: txBalance - refundAmount
            });
        });

        // Update booking to reflect wallet adjustment
        await db.collection('bookings').doc(bookingId).update({
            'refund.walletAdjusted': true,
            'refund.walletAdjustedAt': admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`${LOG_PREFIX} Wallet adjustment completed - Compensation: ${compensationId}, Technician: ${technicianId}, Amount: -₹${refundAmount}`);

        return { success: true };

    } catch (error: any) {
        console.error(`${LOG_PREFIX} Retry error for ${compensationId}:`, error);
        
        // Update compensation with error
        await db.collection('refund_compensations').doc(compensationId).update({
            lastRetryAt: admin.firestore.FieldValue.serverTimestamp(),
            lastError: error.message,
            retryCount: admin.firestore.FieldValue.increment(1)
        }).catch(() => {});

        return { success: false, error: error.message };
    }
}

/**
 * Admin function to retry a single compensation
 * FIX 3: Manual retry trigger
 */
export const retryRefundCompensation = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
        console.log('FUNCTION START: retryRefundCompensation');
        await assertAdmin(context);

        const { compensationId } = data;

        if (!compensationId) {
            throw new functions.https.HttpsError('invalid-argument', 'compensationId required');
        }

        const result = await retryWalletAdjustment(compensationId);

        if (result.success) {
            return {
                success: true,
                message: 'Wallet adjustment completed successfully'
            };
        } else {
            throw new functions.https.HttpsError('failed-precondition', result.error || 'Retry failed');
        }
    });

/**
 * Admin function to retry all pending compensations
 * FIX 3: Batch retry mechanism
 */
export const retryAllPendingCompensations = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
        await assertAdmin(context);

        const { limit = 50 } = data;

        console.log(`${LOG_PREFIX} Starting batch retry for pending compensations`);

        const results = {
            total: 0,
            succeeded: 0,
            failed: 0,
            details: [] as any[]
        };

        try {
            // Get all pending compensations
            const compensationsSnapshot = await db.collection('refund_compensations')
                .where('status', '==', 'pending_retry')
                .limit(limit)
                .get();

            results.total = compensationsSnapshot.size;

            for (const compensationDoc of compensationsSnapshot.docs) {
                const compensationId = compensationDoc.id;
                const compensation = compensationDoc.data();

                const result = await retryWalletAdjustment(compensationId);

                if (result.success) {
                    results.succeeded++;
                    results.details.push({
                        compensationId,
                        bookingId: compensation.bookingId,
                        technicianId: compensation.technicianId,
                        amount: compensation.refundAmount,
                        status: 'completed'
                    });
                } else {
                    results.failed++;
                    results.details.push({
                        compensationId,
                        bookingId: compensation.bookingId,
                        technicianId: compensation.technicianId,
                        amount: compensation.refundAmount,
                        status: 'failed',
                        error: result.error
                    });
                }
            }

            console.log(`${LOG_PREFIX} Batch retry complete:`, results);

            return {
                success: true,
                ...results
            };

        } catch (error: any) {
            console.error(`${LOG_PREFIX} Batch retry error:`, error);
            throw new functions.https.HttpsError('internal', error.message);
        }
    });

/**
 * Get all pending compensations for admin review
 * FIX 3: Admin monitoring
 */
export const getPendingCompensations = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
        await assertAdmin(context);

        const { status = 'pending_retry', limit = 100 } = data;

        try {
            const compensationsSnapshot = await db.collection('refund_compensations')
                .where('status', '==', status)
                .orderBy('createdAt', 'desc')
                .limit(limit)
                .get();

            const compensations = compensationsSnapshot.docs.map(doc => {
                const data = doc.data();
                return {
                    compensationId: doc.id,
                    bookingId: data.bookingId,
                    refundId: data.refundId,
                    technicianId: data.technicianId,
                    refundAmount: data.refundAmount,
                    currentBalance: data.currentBalance,
                    status: data.status,
                    reason: data.reason,
                    error: data.error,
                    retryCount: data.retryCount || 0,
                    createdAt: data.createdAt?.toDate()?.toISOString(),
                    lastRetryAt: data.lastRetryAt?.toDate()?.toISOString()
                };
            });

            return {
                success: true,
                compensations,
                total: compensations.length
            };

        } catch (error: any) {
            console.error(`${LOG_PREFIX} Get compensations error:`, error);
            throw new functions.https.HttpsError('internal', error.message);
        }
    });

/**
 * Scheduled function to auto-retry pending compensations
 * FIX 3: Automatic retry mechanism (runs every hour)
 */
export const autoRetryCompensations = functions
    .region('asia-south1')
    .runWith({ maxInstances: 1, timeoutSeconds: 540, memory: '256MB' })
    .pubsub.schedule('0 */1 * * *') // Every hour at minute 0
    .timeZone('Asia/Kolkata')
    .onRun(async (context) => {
        console.log('FUNCTION START: autoRetryCompensations', new Date().toISOString());

        try {
            // Get pending compensations (max 50 per run)
            const compensationsSnapshot = await db.collection('refund_compensations')
                .where('status', '==', 'pending_retry')
                .limit(50)
                .get();

            let succeeded = 0;
            let failed = 0;

            for (const compensationDoc of compensationsSnapshot.docs) {
                const result = await retryWalletAdjustment(compensationDoc.id);
                
                if (result.success) {
                    succeeded++;
                } else {
                    failed++;
                }
            }

            console.log(`${LOG_PREFIX} Auto-retry complete - Succeeded: ${succeeded}, Failed: ${failed}`);

        } catch (error) {
            console.error(`${LOG_PREFIX} Auto-retry job error:`, error);
        }
    });
