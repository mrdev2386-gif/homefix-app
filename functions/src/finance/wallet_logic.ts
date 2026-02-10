
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db, getAppConfig } from '../shared/config';

export const DEFAULT_COMMISSION_PERCENTAGE = 0.15; // 15% to match pricing logic

export interface WalletData {
    availableBalance: number;
    pendingBalance: number;
    lifetimeEarnings: number;
    lastPayoutAt: admin.firestore.Timestamp | null;
    updatedAt: admin.firestore.FieldValue;
}

export interface EarningData {
    bookingId: string;
    serviceIds: string[];
    totalAmount: number;
    commissionAmount: number;
    technicianAmount: number;
    status: 'pending' | 'paid';
    createdAt: admin.firestore.FieldValue;
}

export async function processTechnicianEarning(bookingId: string, techId: string, totalAmount: number, serviceIds: string[]) {
    const config = await getAppConfig();
    const commissionRate = (config as any).technicianCommissionRate ?? DEFAULT_COMMISSION_PERCENTAGE;
    const commissionAmount = totalAmount * commissionRate;
    const technicianAmount = totalAmount - commissionAmount;

    const walletRef = db.collection('technicians').doc(techId).collection('wallet').doc('main');
    const earningsRef = db.collection('technicians').doc(techId).collection('earnings').doc(bookingId);

    await db.runTransaction(async (transaction) => {
        // 1. Create Earning Record
        transaction.set(earningsRef, {
            bookingId,
            serviceIds,
            totalAmount,
            commissionAmount,
            technicianAmount,
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 2. Update Wallet
        const walletDoc = await transaction.get(walletRef);
        if (!walletDoc.exists) {
            transaction.set(walletRef, {
                availableBalance: 0,
                pendingBalance: technicianAmount,
                lifetimeEarnings: technicianAmount,
                lastPayoutAt: null,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        } else {
            transaction.update(walletRef, {
                pendingBalance: admin.firestore.FieldValue.increment(technicianAmount),
                lifetimeEarnings: admin.firestore.FieldValue.increment(technicianAmount),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    });

    console.log(`Processed earning for tech ${techId}: ${technicianAmount} for booking ${bookingId}`);
}

export const processWalletTransaction = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    const { type, amount, description, targetUid } = data;

    // Only Admin can credit/debit for others. Customers can only see their own.
    // Assuming isAdmin check is available or using simple logic
    const userSnap = await db.collection('admins').doc(context.auth.uid).get();
    const adminUser = userSnap.exists;

    if (!adminUser && context.auth.uid !== targetUid) {
        throw new functions.https.HttpsError('permission-denied', 'Unauthorized wallet operation');
    }

    if (!adminUser && type === 'credit') {
        throw new functions.https.HttpsError('permission-denied', 'Users cannot manually credit their own wallet');
    }

    try {
        await db.runTransaction(async (t: admin.firestore.Transaction) => {
            const userRef = db.collection('customers').doc(targetUid);
            const userDoc = await t.get(userRef);
            if (!userDoc.exists) throw new Error("User not found");

            const currentBalance = userDoc.data()?.walletBalance || 0;
            const newBalance = type === 'credit' ? currentBalance + amount : currentBalance - amount;

            if (newBalance < 0) throw new Error("Insufficient wallet balance");

            t.update(userRef, {
                walletBalance: newBalance,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            t.set(userRef.collection('wallet_transactions').doc(), {
                type,
                amount,
                description,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'completed'
            });
        });

        return { success: true };
    } catch (e: any) {
        throw new functions.https.HttpsError('internal', e.message);
    }
});
