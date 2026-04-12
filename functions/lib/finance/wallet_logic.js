"use strict";
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
exports.processTechnicianEarning = processTechnicianEarning;
exports.updateWalletBalance = updateWalletBalance;
const admin = __importStar(require("firebase-admin"));
/**
 * Wallet logic functions
 */
/**
 * Process technician earning after booking completion
 * FIX 3A: Uses technician_wallets (single source of truth)
 */
async function processTechnicianEarning(bookingId, technicianId, amount, customerId) {
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
            }
            else {
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
    }
    catch (error) {
        console.error('[WALLET_LOGIC] Error processing technician earning:', error);
        throw error;
    }
}
/**
 * Update wallet balance
 * FIX 3A: Uses technician_wallets (single source of truth)
 */
async function updateWalletBalance(transaction, userId, amount, type, referenceId, description) {
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
    }
    else {
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
//# sourceMappingURL=wallet_logic.js.map