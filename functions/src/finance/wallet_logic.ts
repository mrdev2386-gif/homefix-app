import * as admin from 'firebase-admin';

/**
 * Wallet logic functions
 */

/**
 * Process technician earning after booking completion
 * FIX 3A: Uses technician_wallets (single source of truth)
 */
export async function processTechnicianEarning(
    bookingId: string,
    technicianId: string,
    amount: number,
    customerId?: string
): Promise<void> {
    const db = admin.firestore();
    
    try {
        await db.runTransaction(async (transaction) => {
            // FIX 3A: Use technician_wallets instead of technicians.walletBalance
            const walletRef = db.collection('technician_wallets').doc(technicianId);
            const walletDoc = await transaction.get(walletRef);
            
            if (!walletDoc.exists) {
                // Auto-create wallet if doesn't exist
                transaction.set(walletRef, {
                    availableBalance: amount,
                    pendingBalance: 0,
                    lifetimeEarnings: amount,
                    lastPayoutAt: null,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            } else {
                // Increment existing balance
                transaction.update(walletRef, {
                    availableBalance: admin.firestore.FieldValue.increment(amount),
                    lifetimeEarnings: admin.firestore.FieldValue.increment(amount),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            
            // Log transaction in technician_wallets subcollection
            const transactionRef = walletRef.collection('transactions').doc();
            transaction.set(transactionRef, {
                type: 'credit',
                source: 'booking',
                status: 'completed',
                amount,
                fee: 0,
                referenceId: bookingId,
                description: `Payment for booking`,
                customerId: customerId || null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        
        console.log(`[WALLET_LOGIC] Processed earning for technician ${technicianId}: ${amount}`);
    } catch (error) {
        console.error('[WALLET_LOGIC] Error processing technician earning:', error);
        throw error;
    }
}

/**
 * Update wallet balance
 * FIX 3A: Uses technician_wallets (single source of truth)
 */
export async function updateWalletBalance(
    transaction: admin.firestore.Transaction,
    userId: string,
    amount: number,
    type: string,
    referenceId: string,
    description?: string
): Promise<void> {
    const db = admin.firestore();
    
    // FIX 3A: Use technician_wallets instead of technicians.walletBalance
    const walletRef = db.collection('technician_wallets').doc(userId);
    const walletDoc = await transaction.get(walletRef);
    
    if (!walletDoc.exists) {
        // Auto-create wallet if doesn't exist
        if (amount < 0) {
            throw new Error('Insufficient balance - wallet does not exist');
        }
        transaction.set(walletRef, {
            availableBalance: amount,
            pendingBalance: 0,
            lifetimeEarnings: amount > 0 ? amount : 0,
            lastPayoutAt: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    } else {
        const currentBalance = walletDoc.data()?.availableBalance || 0;
        const newBalance = currentBalance + amount;
        
        if (newBalance < 0) {
            throw new Error('Insufficient balance');
        }
        
        transaction.update(walletRef, {
            availableBalance: newBalance,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    
    // Log transaction in technician_wallets subcollection
    const txnRef = walletRef.collection('transactions').doc();
    transaction.set(txnRef, {
        type: amount >= 0 ? 'credit' : 'debit',
        source: type,
        status: 'completed',
        amount: Math.abs(amount),
        fee: 0,
        referenceId,
        description: description || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}
