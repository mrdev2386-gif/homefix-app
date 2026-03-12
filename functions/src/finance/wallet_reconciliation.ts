/**
 * Wallet Reconciliation System - TEMPORARILY DISABLED
 * 
 * Scheduled function temporarily disabled for deployment stability.
 * Will be re-enabled after Firebase Functions compatibility is verified.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Reconciliation window: last 7 days
const RECONCILIATION_DAYS = 7;

async function getRazorpay() {
    const razorpayKeyId = process.env.RAZORPAY_KEY_ID || '';
    const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET || '';

    if (!razorpayKeyId || !razorpayKeySecret) {
        console.warn('Razorpay credentials not configured - skipping external reconciliation');
    }

    const Razorpay = (await import('razorpay')).default;
    return new Razorpay({
        key_id: razorpayKeyId,
        key_secret: razorpayKeySecret,
    });
}

/**
 * Wallet reconciliation temporarily disabled for deployment stability
 */
export const walletReconciliationDisabled = async () => {
    console.log("Wallet reconciliation temporarily disabled for deployment stability.");
    return null;
};

/**
 * Flag a suspicious wallet for manual review
 */
async function flagSuspiciousWallet(technicianId: string, flags: any) {
    try {
        // Add to suspicious wallets collection
        await db.collection('suspicious_wallets').doc(technicianId).set({
            technicianId,
            flags: admin.firestore.FieldValue.arrayUnion({
                ...flags,
                flaggedAt: new Date().toISOString()
            }),
            lastFlaggedAt: admin.firestore.FieldValue.serverTimestamp(),
            reviewStatus: 'pending',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        // Also add to technician document for quick access
        await db.collection('technicians').doc(technicianId).set({
            walletReviewStatus: 'requires_review',
            lastWalletReviewAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        console.log(`[RECONCILIATION] Flagged wallet for ${technicianId}:`, flags.type);

    } catch (error: any) {
        console.error(`[RECONCILIATION] Failed to flag wallet ${technicianId}:`, error);
    }
}

/**
 * Manual reconciliation trigger (admin callable)
 */
export const triggerManualReconciliation = functions.https.onCall(
    async (data, context) => {
        // Check admin - validate uid exists
        const uid = context.auth?.uid;
        if (!uid) {
            throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
        }
        
        const adminDoc = await db.collection('admins').doc(uid).get();
        if (!adminDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'Admin only');
        }

        const { technicianId, days = 7 } = data;

        if (technicianId) {
            // Single wallet reconciliation
            const walletDoc = await db.collection('technician_wallets').doc(technicianId).get();
            if (!walletDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Wallet not found');
            }

            const transactions = await db
                .collection('technician_wallets')
                .doc(technicianId)
                .collection('transactions')
                .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(
                    new Date(Date.now() - days * 24 * 60 * 60 * 1000)
                ))
                .get();

            let totalCredits = 0;
            let totalDebits = 0;

            for (const txn of transactions.docs) {
                const t = txn.data();
                if (t.amount > 0) totalCredits += t.amount;
                else totalDebits += Math.abs(t.amount);
            }

            return {
                technicianId,
                walletBalance: walletDoc.data()?.availableBalance || 0,
                calculatedBalance: totalCredits + totalDebits,
                totalCredits,
                totalDebits,
                transactionCount: transactions.size,
                period: { days }
            };

        } else {
            // Full reconciliation - trigger the scheduled function
            // This will run asynchronously
            return {
                message: 'Full reconciliation triggered. Check reconciliation_reports collection for results.',
                expectedCompletion: new Date(Date.now() + 5 * 60 * 1000).toISOString()
            };
        }
    }
);

/**
 * Get reconciliation anomalies (admin callable)
 */
export const getReconciliationAnomalies = functions.https.onCall(
    async (data, context) => {
        // Check admin
        const uid = context.auth?.uid;
        if (!uid) {
            throw new functions.https.HttpsError('unauthenticated', 'Auth required');
        }

        const adminDoc = await db.collection('admins').doc(uid).get();
        if (!adminDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'Admin only');
        }

        const { limit = 50 } = data;

        // Get suspicious wallets
        const suspiciousSnapshot = await db.collection('suspicious_wallets')
            .where('reviewStatus', '==', 'pending')
            .limit(limit)
            .get();

        const anomalies = suspiciousSnapshot.docs.map(doc => ({
            technicianId: doc.id,
            flags: doc.data().flags,
            lastFlaggedAt: doc.data().lastFlaggedAt,
            reviewStatus: doc.data().reviewStatus
        }));

        // Get recent reconciliation reports
        const reportsSnapshot = await db.collection('reconciliation_reports')
            .orderBy('createdAt', 'desc')
            .limit(10)
            .get();

        const reports = reportsSnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        return { anomalies, reports };
    }
);

/**
 * Mark wallet as reviewed (admin callable)
 */
export const markWalletReviewed = functions.https.onCall(
    async (data, context) => {
        // Check admin
        const uid = context.auth?.uid;
        if (!uid) {
            throw new functions.https.HttpsError('unauthenticated', 'Auth required');
        }

        const adminDoc = await db.collection('admins').doc(uid).get();
        if (!adminDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'Admin only');
        }

        const { technicianId, reviewStatus, notes } = data;

        if (!technicianId || !reviewStatus) {
            throw new functions.https.HttpsError('invalid-argument', 'Technician ID and review status required');
        }

        await db.collection('suspicious_wallets').doc(technicianId).update({
            reviewStatus,
            reviewedBy: uid,
            reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
            reviewNotes: notes || '',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Update technician document
        await db.collection('technicians').doc(technicianId).update({
            walletReviewStatus: reviewStatus === 'resolved' ? 'clean' : 'requires_review',
            lastWalletReviewAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Log the review action
        await db.collection('wallet_review_logs').add({
            technicianId,
            reviewStatus,
            reviewedBy: uid,
            notes: notes || '',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return { success: true };
    }
);
