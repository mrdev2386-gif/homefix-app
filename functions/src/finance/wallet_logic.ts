import * as admin from 'firebase-admin';

/**
 * Wallet logic functions
 */

/**
 * Process technician earning after booking completion
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
            const techRef = db.collection('technicians').doc(technicianId);
            const techDoc = await transaction.get(techRef);
            
            if (!techDoc.exists) {
                throw new Error('Technician not found');
            }
            
            const currentBalance = techDoc.data()?.walletBalance || 0;
            const newBalance = currentBalance + amount;
            
            transaction.update(techRef, {
                walletBalance: newBalance,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            
            // Log transaction
            const transactionRef = db.collection('wallet_transactions').doc();
            transaction.set(transactionRef, {
                userId: technicianId,
                userType: 'technician',
                type: 'credit',
                amount,
                bookingId,
                customerId: customerId || null,
                balanceBefore: currentBalance,
                balanceAfter: newBalance,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        
        console.log(`Processed earning for technician ${technicianId}: ${amount}`);
    } catch (error) {
        console.error('Error processing technician earning:', error);
        throw error;
    }
}

/**
 * Update wallet balance
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
    
    const userRef = db.collection('technicians').doc(userId);
    const userDoc = await transaction.get(userRef);
    
    if (!userDoc.exists) {
        throw new Error('User not found');
    }
    
    const currentBalance = userDoc.data()?.walletBalance || 0;
    const newBalance = currentBalance + amount;
    
    if (newBalance < 0) {
        throw new Error('Insufficient balance');
    }
    
    transaction.update(userRef, {
        walletBalance: newBalance,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Log transaction
    const transactionRef = db.collection('wallet_transactions').doc();
    transaction.set(transactionRef, {
        userId,
        userType: 'technician',
        type: amount >= 0 ? 'credit' : 'debit',
        amount: Math.abs(amount),
        referenceId,
        description: description || '',
        balanceBefore: currentBalance,
        balanceAfter: newBalance,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}
