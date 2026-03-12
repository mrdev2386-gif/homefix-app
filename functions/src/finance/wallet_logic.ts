
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Unified DB reference
const db = admin.firestore();

export const DEFAULT_COMMISSION_PERCENTAGE = 0.10; // 10% platform fee

/**
 * Atomic Wallet Deduction / Credit with Immutable Ledger Entry
 */
export async function updateWalletBalance(
    transaction: admin.firestore.Transaction,
    userId: string,
    amount: number, // Positive for credit, negative for debit
    type: string,
    bookingId: string | null,
    description: string
) {
    const walletRef = db.collection('wallets').doc(userId);
    const txnRef = db.collection('walletTransactions').doc();
    const now = admin.firestore.Timestamp.now();

    const walletDoc = await transaction.get(walletRef);
    const currentBalance = walletDoc.exists ? (walletDoc.data()?.balance || 0) : 0;
    const newBalance = currentBalance + amount;

    if (newBalance < 0) {
        throw new Error(`Insufficient wallet balance for user ${userId}`);
    }

    // 1. Update Wallet Balance
    transaction.set(walletRef, {
        balance: newBalance,
        updatedAt: now,
        userId: userId
    }, { merge: true });

    // 2. Create Immutable Ledger Entry
    transaction.set(txnRef, {
        userId,
        amount,
        type,
        bookingId,
        description,
        previousBalance: currentBalance,
        newBalance: newBalance,
        createdAt: now,
        status: 'completed'
    });

    return newBalance;
}

/**
 * Handle Technician Earning Payout (90% to technician, 10% to platform)
 */
export async function processTechnicianEarning(
    bookingId: string,
    techId: string,
    totalAmount: number,
    customerId: string
) {
    const commissionAmount = totalAmount * DEFAULT_COMMISSION_PERCENTAGE;
    const technicianAmount = totalAmount - commissionAmount;

    await db.runTransaction(async (transaction) => {
        // 1. Credit Technician (90%)
        await updateWalletBalance(
            transaction,
            techId,
            technicianAmount,
            'technician_payout',
            bookingId,
            `Payout for booking ${bookingId}`
        );

        // 2. Track Platform Commission (10%)
        const platformRef = db.collection('platform_earnings').doc(bookingId);
        transaction.set(platformRef, {
            bookingId,
            totalAmount,
            technicianPayout: technicianAmount,
            platformCommission: commissionAmount,
            techId,
            customerId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 3. Mark booking as payout processed
        const bookingRef = db.collection('bookings').doc(bookingId);
        transaction.update(bookingRef, {
            payoutProcessed: true,
            technicianPayout: technicianAmount,
            platformCommission: commissionAmount
        });
    });

    console.log(`[FINANCE] Processed payout for tech ${techId}: ${technicianAmount} for booking ${bookingId}`);
}

/**
 * Callable: Admin Wallet Adjustment
 */
export const processWalletTransaction = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const { type, amount, description, targetUid } = data;

    // Check Admin
    const adminSnap = await db.collection('admins').doc(context.auth.uid).get();
    if (!adminSnap.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can adjust wallets');
    }

    try {
        await db.runTransaction(async (t: admin.firestore.Transaction) => {
            const adjustmentAmount = type === 'credit' ? Math.abs(amount) : -Math.abs(amount);
            await updateWalletBalance(t, targetUid, adjustmentAmount, 'admin_adjustment', null, description);
        });

        return { success: true };
    } catch (e: any) {
        throw new functions.https.HttpsError('internal', e.message);
    }
});
