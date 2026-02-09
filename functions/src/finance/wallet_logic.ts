
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
