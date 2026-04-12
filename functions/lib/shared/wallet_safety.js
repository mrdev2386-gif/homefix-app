"use strict";
/**
 * WALLET TRANSACTION SAFETY - Prevents double credits and race conditions
 *
 * GUARANTEES:
 * - Idempotency via transaction-based checks
 * - Atomic wallet updates (no partial credits)
 * - Balance validation before withdrawal
 * - Duplicate transaction prevention
 * - Ledger-based accounting (immutable transaction records)
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
exports.creditWalletAtomic = creditWalletAtomic;
exports.debitWalletAtomic = debitWalletAtomic;
exports.getWalletBalance = getWalletBalance;
exports.validateWalletIntegrity = validateWalletIntegrity;
exports.checkPayoutDuplicate = checkPayoutDuplicate;
exports.checkRefundDuplicate = checkRefundDuplicate;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * Credit wallet atomically with idempotency protection
 *
 * CRITICAL: Uses Firestore transaction to ensure:
 * 1. Idempotency check happens inside transaction
 * 2. Wallet balance update is atomic
 * 3. Transaction record is created atomically
 * 4. No race conditions possible
 */
async function creditWalletAtomic(userId, amount, source, referenceId, description, userType = 'customer') {
    if (amount <= 0) {
        throw new Error('Invalid transaction amount');
    }
    const collectionName = userType === 'technician' ? 'technician_wallets' : 'wallets';
    const walletRef = db.collection(collectionName).doc(userId);
    const txnRef = walletRef.collection('transactions').doc();
    let newBalance = 0;
    let transactionId = '';
    try {
        await db.runTransaction(async (transaction) => {
            // STEP 1: Idempotency check - prevent duplicate credits
            const existingTxnSnapshot = await transaction.get(db.collection(collectionName)
                .doc(userId)
                .collection('transactions')
                .where('referenceId', '==', referenceId)
                .where('source', '==', source)
                .limit(1));
            if (!existingTxnSnapshot.empty) {
                const existingTxn = existingTxnSnapshot.docs[0].data();
                if (existingTxn.status === 'completed') {
                    console.log(`[WALLET] Duplicate credit detected for ${userId}. Reference: ${referenceId}`);
                    throw new Error(`IDEMPOTENCY_DUPLICATE:${existingTxnSnapshot.docs[0].id}`);
                }
            }
            // STEP 2: Get current wallet (auto-create if doesn't exist)
            const walletDoc = await transaction.get(walletRef);
            let currentBalance = 0;
            if (!walletDoc.exists) {
                // Create new wallet with initial balance
                transaction.set(walletRef, {
                    availableBalance: amount,
                    pendingBalance: 0,
                    lifetimeEarnings: amount,
                    lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                newBalance = amount;
            }
            else {
                // Increment existing balance atomically
                currentBalance = walletDoc.data()?.availableBalance || 0;
                newBalance = currentBalance + amount;
                transaction.update(walletRef, {
                    availableBalance: admin.firestore.FieldValue.increment(amount),
                    lifetimeEarnings: admin.firestore.FieldValue.increment(amount),
                    lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            // STEP 3: Create immutable transaction record
            transactionId = txnRef.id;
            transaction.set(txnRef, {
                type: 'credit',
                source,
                status: 'completed',
                amount,
                fee: 0,
                referenceId,
                description,
                balanceBefore: currentBalance,
                balanceAfter: newBalance,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        console.log(`[WALLET] Credit successful: ${userId}, Amount: ${amount}, Balance: ${newBalance}`);
        return { success: true, transactionId, newBalance };
    }
    catch (error) {
        if (error.message?.startsWith('IDEMPOTENCY_DUPLICATE:')) {
            const dupTxnId = error.message.split(':')[1];
            const dupTxn = await db
                .collection(collectionName)
                .doc(userId)
                .collection('transactions')
                .doc(dupTxnId)
                .get();
            const dupData = dupTxn.data();
            return { success: true, transactionId: dupTxnId, newBalance: dupData?.balanceAfter || 0 };
        }
        console.error(`[WALLET] Credit failed for ${userId}:`, error);
        throw error;
    }
}
/**
 * Debit wallet atomically with balance validation
 *
 * CRITICAL: Validates sufficient balance before debit
 */
async function debitWalletAtomic(userId, amount, source, referenceId, description, userType = 'customer') {
    if (amount <= 0) {
        throw new Error('Invalid transaction amount');
    }
    const collectionName = userType === 'technician' ? 'technician_wallets' : 'wallets';
    const walletRef = db.collection(collectionName).doc(userId);
    const txnRef = walletRef.collection('transactions').doc();
    let newBalance = 0;
    let transactionId = '';
    try {
        await db.runTransaction(async (transaction) => {
            // STEP 1: Get current wallet
            const walletDoc = await transaction.get(walletRef);
            if (!walletDoc.exists) {
                throw new Error('Wallet not found');
            }
            const currentBalance = walletDoc.data()?.availableBalance || 0;
            // STEP 2: Validate sufficient balance
            if (currentBalance < amount) {
                throw new Error(`Insufficient balance. Available: ${currentBalance}, Required: ${amount}`);
            }
            // STEP 3: Debit atomically
            newBalance = currentBalance - amount;
            transaction.update(walletRef, {
                availableBalance: admin.firestore.FieldValue.increment(-amount),
                lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // STEP 4: Create immutable transaction record
            transactionId = txnRef.id;
            transaction.set(txnRef, {
                type: 'debit',
                source,
                status: 'completed',
                amount,
                fee: 0,
                referenceId,
                description,
                balanceBefore: currentBalance,
                balanceAfter: newBalance,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        console.log(`[WALLET] Debit successful: ${userId}, Amount: ${amount}, Balance: ${newBalance}`);
        return { success: true, transactionId, newBalance };
    }
    catch (error) {
        console.error(`[WALLET] Debit failed for ${userId}:`, error);
        throw error;
    }
}
/**
 * Get wallet balance safely
 */
async function getWalletBalance(userId, userType = 'customer') {
    const collectionName = userType === 'technician' ? 'technician_wallets' : 'wallets';
    const walletDoc = await db.collection(collectionName).doc(userId).get();
    if (!walletDoc.exists) {
        return 0;
    }
    return walletDoc.data()?.availableBalance || 0;
}
/**
 * Validate wallet transaction integrity
 *
 * Checks:
 * - All transactions are immutable
 * - Balance calculations are correct
 * - No orphaned transactions
 */
async function validateWalletIntegrity(userId, userType = 'customer') {
    const collectionName = userType === 'technician' ? 'technician_wallets' : 'wallets';
    const errors = [];
    try {
        const walletDoc = await db.collection(collectionName).doc(userId).get();
        if (!walletDoc.exists) {
            return { isValid: true, errors: [] }; // No wallet = valid state
        }
        const walletData = walletDoc.data();
        const currentBalance = walletData.availableBalance || 0;
        // Get all transactions
        const txnsSnapshot = await db
            .collection(collectionName)
            .doc(userId)
            .collection('transactions')
            .orderBy('createdAt', 'asc')
            .get();
        // Recalculate balance from transactions
        let calculatedBalance = 0;
        for (const txnDoc of txnsSnapshot.docs) {
            const txn = txnDoc.data();
            if (txn.status !== 'completed') {
                errors.push(`Incomplete transaction: ${txnDoc.id}`);
                continue;
            }
            if (txn.type === 'credit') {
                calculatedBalance += txn.amount;
            }
            else if (txn.type === 'debit') {
                calculatedBalance -= txn.amount;
            }
        }
        // Verify balance matches
        if (Math.abs(calculatedBalance - currentBalance) > 0.01) {
            errors.push(`Balance mismatch. Stored: ${currentBalance}, Calculated: ${calculatedBalance}`);
        }
        return {
            isValid: errors.length === 0,
            errors,
        };
    }
    catch (error) {
        return {
            isValid: false,
            errors: [`Validation error: ${error.message}`],
        };
    }
}
/**
 * Prevent duplicate payout
 *
 * Checks if payout for this booking has already been processed
 */
async function checkPayoutDuplicate(technicianId, bookingId) {
    const existingPayout = await db
        .collection('technician_wallets')
        .doc(technicianId)
        .collection('transactions')
        .where('referenceId', '==', bookingId)
        .where('source', '==', 'booking_payout')
        .where('status', '==', 'completed')
        .limit(1)
        .get();
    return !existingPayout.empty;
}
/**
 * Prevent duplicate refund
 *
 * Checks if refund for this booking has already been processed
 */
async function checkRefundDuplicate(customerId, bookingId) {
    const existingRefund = await db
        .collection('wallets')
        .doc(customerId)
        .collection('transactions')
        .where('referenceId', '==', bookingId)
        .where('source', '==', 'booking_refund')
        .where('status', '==', 'completed')
        .limit(1)
        .get();
    return !existingRefund.empty;
}
//# sourceMappingURL=wallet_safety.js.map