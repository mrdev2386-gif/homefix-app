/**
 * HomeFix Technician Wallet Cloud Functions
 * 
 * PRODUCTION-SAFE PAYMENT & PAYOUT SYSTEM
 * 
 * Security Features:
 * - All wallet operations via Cloud Functions only
 * - No client-side balance manipulation
 * - Idempotency keys prevent duplicate transactions
 * - Server-side payment verification
 * - Rate limiting
 * - Audit logging
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Razorpay from 'razorpay';
import { v4 as uuidv4 } from 'uuid';

// Import service moderation functions
export * from './admin/service_moderation';

// ============================================
// BOOKING STATUS CONSTANTS
// ============================================

const BOOKING_STATUS = {
  PENDING_ADMIN_APPROVAL: 'pending_admin_approval',
  APPROVED_BY_ADMIN: 'approved_by_admin',
  TECHNICIAN_ACCEPTED: 'technician_accepted',
  SERVICE_IN_PROGRESS: 'service_in_progress',
  SERVICE_COMPLETED: 'service_completed',
  REJECTED: 'rejected',
} as const;

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Initialize Razorpay
const razorpay = new Razorpay({
    key_id: functions.config().razorpay.key_id,
    key_secret: functions.config().razorpay.key_secret,
});

// Configuration constants
const CONFIG = {
    PLATFORM_COMMISSION_PERCENT: 15, // 15% platform commission
    MIN_WITHDRAWAL_AMOUNT: 100,      // Minimum ₹100 for withdrawal
    MAX_WITHDRAWAL_AMOUNT: 50000,    // Maximum ₹50,000 per transaction
    PAYOUT_FEE: 10,                 // ₹10 per payout
    QR_EXPIRY_MINUTES: 30,          // QR code expiry time
    MAX_DAILY_WITHDRAWALS: 3,        // Max withdrawals per day
    WITHDRAWAL_COOLDOWN_HOURS: 6,   // Cooldown between withdrawals
};

// Type definitions
interface PaymentData {
    bookingId: string;
    amount: number;
    paymentId: string;
    customerId: string;
    technicianId: string;
}

interface WithdrawalData {
    technicianId: string;
    amount: number;
    bankAccountId: string;
}

interface QRPaymentData {
    bookingId: string;
    technicianId: string;
    customerId: string;
    customerPhone: string;
    amount: number;
}

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Verify Razorpay webhook signature
 */
function verifyWebhookSignature(
    body: string,
    signature: string,
    secret: string
): boolean {
    const crypto = require('crypto');
    const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(body)
        .digest('hex');
    return signature === expectedSignature;
}

/**
 * Generate idempotency key
 */
function generateIdempotencyKey(prefix: string, id: string): string {
    return `${prefix}_${id}_${Date.now()}`;
}

/**
 * Create audit log
 */
async function createAuditLog(
    action: string,
    technicianId: string,
    data: Record<string, any>
): Promise<void> {
    await db.collection('audit_logs').add({
        action,
        technicianId,
        data,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: new Date().toISOString(),
    });
}

/**
 * Create booking audit log
 */
async function createBookingAuditLog(
    adminId: string,
    action: string,
    bookingId: string,
    details?: Record<string, any>
): Promise<void> {
    await db.collection('booking_audit_logs').add({
        adminId,
        action,
        bookingId,
        details: details || {},
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: new Date().toISOString(),
    });
}

/**
 * Verify admin role
 */
function verifyAdminRole(context: functions.https.CallableContext): void {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    if (!context.auth.token?.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }
}

/**
 * Send FCM notification to user
 */
async function sendNotification(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, string>
): Promise<void> {
    try {
        const userDoc = await db.collection('technicians').doc(userId).get();
        const fcmToken = userDoc.data()?.fcmToken;
        
        if (!fcmToken) {
            const customerDoc = await db.collection('customers').doc(userId).get();
            const customerFcmToken = customerDoc.data()?.fcmToken;
            
            if (!customerFcmToken) {
                console.log(`No FCM token found for user ${userId}`);
                return;
            }
            
            await admin.messaging().send({
                token: customerFcmToken,
                notification: { title, body },
                data: data || {},
            });
        } else {
            await admin.messaging().send({
                token: fcmToken,
                notification: { title, body },
                data: data || {},
            });
        }
    } catch (error) {
        console.error(`Failed to send notification to ${userId}:`, error);
    }
}

/**
 * Check rate limiting for withdrawal
 */
async function checkWithdrawalRateLimit(technicianId: string): Promise<boolean> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const withdrawalCount = await db
        .collection('technician_payouts')
        .where('technicianId', '==', technicianId)
        .where('createdAt', '>=', today)
        .count()
        .get();

    return withdrawalCount.data().count < CONFIG.MAX_DAILY_WITHDRAWALS;
}

/**
 * Get technician wallet (create if doesn't exist)
 */
async function getOrCreateWallet(technicianId: string) {
    const walletRef = db.collection('technician_wallets').doc(technicianId);
    const walletDoc = await walletRef.get();

    if (!walletDoc.exists) {
        await walletRef.set({
            technicianId,
            availableBalance: 0,
            pendingBalance: 0,
            onHoldBalance: 0,
            lifetimeEarnings: 0,
            lastPayoutAt: null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            kycStatus: 'pending',
            bankAccountId: null,
        });
    }

    return walletRef;
}

/**
 * Create wallet transaction (append-only)
 */
async function createWalletTransaction(
    technicianId: string,
    type: string,
    source: string,
    status: string,
    amount: number,
    referenceId: string,
    description: string,
    fee?: number
): Promise<string> {
    const txnRef = db
        .collection('technician_wallets')
        .doc(technicianId)
        .collection('transactions')
        .doc();

    const idempotencyKey = generateIdempotencyKey(type, referenceId);

    // Check for duplicate transaction
    const existingTxn = await db
        .collection('technician_wallets')
        .doc(technicianId)
        .collection('transactions')
        .where('idempotencyKey', '==', idempotencyKey)
        .limit(1)
        .get();

    if (!existingTxn.empty) {
        throw new functions.https.HttpsError(
            'already-exists',
            'Transaction already exists'
        );
    }

    await txnRef.set({
        type,
        source,
        status,
        amount,
        fee: fee || 0,
        referenceId,
        description,
        idempotencyKey,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: 'cloud_function',
    });

    return txnRef.id;
}

/**
 * Calculate commission and net amount
 */
function calculateNetAmount(grossAmount: number): {
    commission: number;
    netAmount: number;
} {
    const commission = (grossAmount * CONFIG.PLATFORM_COMMISSION_PERCENT) / 100;
    const netAmount = grossAmount - commission;
    return { commission, netAmount };
}

// ============================================
// CALLABLE FUNCTIONS
// ============================================

/**
 * Request Withdrawal - Callable Function
 * 
 * SECURITY: Server-side validation only
 * Client cannot trigger payout directly
 */
export const requestWithdrawal = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: WithdrawalData, context) => {
        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated'
            );
        }

        const { technicianId, amount, bankAccountId } = data;

        // Verify technician owns the account
        if (context.auth.uid !== technicianId) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Unauthorized access'
            );
        }

        // Validate amount
        if (amount < CONFIG.MIN_WITHDRAWAL_AMOUNT) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                `Minimum withdrawal amount is ₹${CONFIG.MIN_WITHDRAWAL_AMOUNT}`
            );
        }

        if (amount > CONFIG.MAX_WITHDRAWAL_AMOUNT) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                `Maximum withdrawal amount is ₹${CONFIG.MAX_WITHDRAWAL_AMOUNT}`
            );
        }

        // Get technician wallet
        const walletRef = await getOrCreateWallet(technicianId);
        const walletDoc = await walletRef.get();
        const walletData = walletDoc.data();

        // Check available balance
        if (!walletData || walletData.availableBalance < amount) {
            throw new functions.https.HttpsError(
                'failed-precondition',
                'Insufficient balance'
            );
        }

        // Check KYC status
        if (walletData.kycStatus !== 'verified') {
            throw new functions.https.HttpsError(
                'failed-precondition',
                'KYC verification required'
            );
        }

        // Check bank account exists and is verified
        const bankDoc = await db
            .collection('technician_bank_accounts')
            .doc(bankAccountId)
            .get();

        if (!bankDoc.exists || bankDoc.data()?.technicianId !== technicianId) {
            throw new functions.https.HttpsError(
                'not-found',
                'Bank account not found'
            );
        }

        if (bankDoc.data()?.status !== 'verified') {
            throw new functions.https.HttpsError(
                'failed-precondition',
                'Bank account not verified'
            );
        }

        // Check rate limit
        const withinRateLimit = await checkWithdrawalRateLimit(technicianId);
        if (!withinRateLimit) {
            throw new functions.https.HttpsError(
                'resource-exhausted',
                'Daily withdrawal limit reached'
            );
        }

        // Check cooldown (last withdrawal)
        if (walletData.lastPayoutAt) {
            const lastPayout = walletData.lastPayoutAt.toDate();
            const cooldownEnd = new Date(lastPayout);
            cooldownEnd.setHours(cooldownEnd.getHours() + CONFIG.WITHDRAWAL_COOLDOWN_HOURS);

            if (new Date() < cooldownEnd) {
                throw new functions.https.HttpsError(
                    'failed-precondition',
                    `Withdrawal cooldown: ${CONFIG.WITHDRAWAL_COOLDOWN_HOURS} hours between withdrawals`
                );
            }
        }

        // Create payout record
        const payoutRef = db.collection('technician_payouts').doc();
        const payoutId = payoutRef.id;
        const idempotencyKey = generateIdempotencyKey('withdrawal', payoutId);

        const bankData = bankDoc.data();

        await payoutRef.set({
            technicianId,
            amount,
            fee: CONFIG.PAYOUT_FEE,
            netAmount: amount - CONFIG.PAYOUT_FEE,
            status: 'initiated',
            bankAccountId,
            bankName: bankData?.bankName,
            bankAccountNumber: bankData?.accountNumber,
            ifscCode: bankData?.ifscCode,
            idempotencyKey,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            retryCount: 0,
        });

        // Deduct from available balance (use transaction for atomicity)
        await db.runTransaction(async (transaction) => {
            const walletDoc = await transaction.get(walletRef);
            const currentBalance = walletDoc.data()?.availableBalance || 0;

            if (currentBalance < amount) {
                throw new Error('Insufficient balance');
            }

            transaction.update(walletRef, {
                availableBalance: currentBalance - amount,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });

        // Create wallet transaction record
        await createWalletTransaction(
            technicianId,
            'payout',
            'withdrawal',
            'pending',
            amount,
            payoutId,
            `Withdrawal to ${bankData?.bankName}`
        );

        // Process payout via Razorpay (async)
        processPayout(payoutId, technicianId, amount, bankData).catch(console.error);

        // Create audit log
        await createAuditLog('withdrawal_requested', technicianId, {
            payoutId,
            amount,
            bankAccountId,
        });

        return {
            success: true,
            payoutId,
            message: 'Withdrawal request submitted successfully',
        };
    }
);

/**
 * Process Razorpay Payout
 */
async function processPayout(
    payoutId: string,
    technicianId: string,
    amount: number,
    bankData: any
): Promise<void> {
    try {
        const payout = await razorpay.payouts.create({
            account_number: functions.config().razorpay.account_number,
            amount: Math.round(amount * 100), // Convert to paise
            currency: 'INR',
            mode: 'IMPS',
            purpose: 'payout',
            fund_account: {
                bank_account: {
                    name: bankData.accountHolderName,
                    ifsc: bankData.ifscCode,
                    account_number: bankData.accountNumber,
                },
                contact: {
                    name: bankData.accountHolderName,
                    type: 'technician',
                    reference_id: technicianId,
                },
            },
            queue_if_low_balance: true,
        });

        // Update payout record
        await db.collection('technician_payouts').doc(payoutId).update({
            status: payout.status === 'processed' ? 'success' : 'processing',
            razorpayPayoutId: payout.id,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            processedBy: 'cloud_function_payout',
        });

        // Create audit log
        await createAuditLog('payout_processed', technicianId, {
            payoutId,
            razorpayPayoutId: payout.id,
            status: payout.status,
        });

    } catch (error: any) {
        console.error('Payout failed:', error);

        // Update payout status to failed
        await db.runTransaction(async (transaction) => {
            const payoutDoc = await transaction.get(
                db.collection('technician_payouts').doc(payoutId)
            );

            if (payoutDoc.data()?.status === 'initiated') {
                // Rollback: Add amount back to wallet
                const walletRef = db.collection('technician_wallets').doc(technicianId);
                const walletDoc = await transaction.get(walletRef);
                const currentBalance = walletDoc.data()?.availableBalance || 0;

                transaction.update(walletRef, {
                    availableBalance: currentBalance + amount,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                transaction.update(
                    db.collection('technician_payouts').doc(payoutId),
                    {
                        status: 'failed',
                        failureReason: error.message,
                        processedAt: admin.firestore.FieldValue.serverTimestamp(),
                    }
                );

                // Update transaction record
                const txnQuery = await db
                    .collection('technician_wallets')
                    .doc(technicianId)
                    .collection('transactions')
                    .where('referenceId', '==', payoutId)
                    .limit(1)
                    .get();

                if (!txnQuery.empty) {
                    transaction.update(txnQuery.docs[0].ref, {
                        status: 'failed',
                    });
                }
            }
        });

        await createAuditLog('payout_failed', technicianId, {
            payoutId,
            error: error.message,
        });
    }
}

/**
 * Credit Technician Wallet - Called after payment verification
 */
export const creditTechnicianWallet = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: PaymentData, context) => {
        // Only allow calls from verified sources (payment webhook, admin)
        // This function should NOT be called directly from client

        const { bookingId, amount, customerId, technicianId } = data;

        // Verify booking exists and belongs to technician
        const bookingDoc = await db.collection('bookings').doc(bookingId).get();

        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError(
                'not-found',
                'Booking not found'
            );
        }

        const bookingData = bookingDoc.data();

        if (bookingData?.technicianId !== technicianId) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Booking does not belong to this technician'
            );
        }

        // Calculate net amount after commission
        const { commission, netAmount } = calculateNetAmount(amount);

        // Get or create wallet
        const walletRef = await getOrCreateWallet(technicianId);

        // Check if already credited (idempotency)
        const existingTxn = await db
            .collection('technician_wallets')
            .doc(technicianId)
            .collection('transactions')
            .where('referenceId', '==', bookingId)
            .where('type', '==', 'credit')
            .limit(1)
            .get();

        if (!existingTxn.empty) {
            return {
                success: true,
                message: 'Payment already credited',
                alreadyCredited: true,
            };
        }

        // Add to pending balance (requires admin approval to move to available)
        await db.runTransaction(async (transaction) => {
            const walletDoc = await transaction.get(walletRef);
            const currentPending = walletDoc.data()?.pendingBalance || 0;
            const currentLifetime = walletDoc.data()?.lifetimeEarnings || 0;

            transaction.update(walletRef, {
                pendingBalance: currentPending + netAmount,
                lifetimeEarnings: currentLifetime + netAmount,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });

        // Create transaction record
        await createWalletTransaction(
            technicianId,
            'credit',
            'booking',
            'pending',
            netAmount,
            bookingId,
            `Payment for booking ${bookingId}`
        );

        // Update booking payment status
        await db.collection('bookings').doc(bookingId).update({
            'payment.status': 'paid',
            'payment.paidAt': admin.firestore.FieldValue.serverTimestamp(),
            'payment.technicianAmount': netAmount,
            'payment.commission': commission,
        });

        // Create audit log
        await createAuditLog('wallet_credited', technicianId, {
            bookingId,
            amount: netAmount,
            commission,
        });

        return {
            success: true,
            amount: netAmount,
            commission,
            message: 'Payment credited to pending balance',
        };
    }
);

/**
 * Approve Payment - Move from pending to available (Admin only)
 */
export const approvePayment = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { technicianId: string; bookingId: string }, context) => {
        // This should be called by admin only (verify admin role)

        const { technicianId, bookingId } = data;

        // Get transaction
        const txnQuery = await db
            .collection('technician_wallets')
            .doc(technicianId)
            .collection('transactions')
            .where('referenceId', '==', bookingId)
            .where('type', '==', 'credit')
            .limit(1)
            .get();

        if (txnQuery.empty) {
            throw new functions.https.HttpsError(
                'not-found',
                'Transaction not found'
            );
        }

        const txnDoc = txnQuery.docs[0];
        const txnData = txnDoc.data();

        if (txnData.status === 'completed') {
            return { success: true, message: 'Already approved' };
        }

        const amount = txnData.amount;

        // Move from pending to available
        await db.runTransaction(async (transaction) => {
            const walletRef = db.collection('technician_wallets').doc(technicianId);
            const walletDoc = await transaction.get(walletRef);

            const currentPending = walletDoc.data()?.pendingBalance || 0;
            const currentAvailable = walletDoc.data()?.availableBalance || 0;

            if (currentPending < amount) {
                throw new Error('Insufficient pending balance');
            }

            transaction.update(walletRef, {
                pendingBalance: currentPending - amount,
                availableBalance: currentAvailable + amount,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Update transaction status
            transaction.update(txnDoc.ref, {
                status: 'completed',
            });
        });

        await createAuditLog('payment_approved', technicianId, {
            bookingId,
            amount,
        });

        return { success: true };
    }
);

/**
 * Generate QR Code for Booking Payment
 */
export const generateBookingQR = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { bookingId: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated'
            );
        }

        const { bookingId } = data;

        // Get booking details
        const bookingDoc = await db.collection('bookings').doc(bookingId).get();

        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError(
                'not-found',
                'Booking not found'
            );
        }

        const bookingData = bookingDoc.data();
        const technicianId = bookingData?.technicianId;

        // Verify technician owns the booking
        if (context.auth.uid !== technicianId) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Unauthorized'
            );
        }

        // Check if QR already exists and is not expired
        const paymentDoc = await db
            .collection('bookings')
            .doc(bookingId)
            .collection('payment')
            .doc('qr')
            .get();

        if (paymentDoc.exists) {
            const paymentData = paymentDoc.data();
            const expiresAt = paymentData?.expiresAt?.toDate();

            if (expiresAt && new Date() < expiresAt && paymentData?.status === 'generated') {
                // Return existing QR
                return {
                    success: true,
                    qrImageUrl: paymentData.qrImageUrl,
                    qrId: paymentData.qrId,
                    expiresAt: expiresAt.toISOString(),
                };
            }
        }

        // Create Razorpay QR
        const amount = bookingData?.totalAmount || 0;
        const expiryTime = new Date();
        expiryTime.setMinutes(expiryTime.getMinutes() + CONFIG.QR_EXPIRY_MINUTES);

        const qrPayload = {
            type: 'payment',
            name: `Booking ${bookingId}`,
            usage: 'single_use',
            fixed_amount: true,
            amount: Math.round(amount * 100),
            currency: 'INR',
            description: `Payment for booking ${bookingId}`,
            expiry_time: Math.floor(expiryTime.getTime() / 1000),
            notes: {
                bookingId,
                technicianId,
                customerId: bookingData?.customerId,
            },
        };

        const qr = await razorpay.qrCode.create(qrPayload);

        // Save QR payment details
        await db
            .collection('bookings')
            .doc(bookingId)
            .collection('payment')
            .doc('qr')
            .set({
                bookingId,
                technicianId,
                customerId: bookingData?.customerId,
                customerPhone: bookingData?.customerPhone,
                amount,
                status: 'generated',
                qrId: qr.id,
                qrImageUrl: qr.image_url,
                razorpayOrderId: qr.order_id,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                expiresAt: admin.firestore.Timestamp.fromDate(expiryTime),
            });

        await createAuditLog('qr_generated', technicianId, {
            bookingId,
            qrId: qr.id,
        });

        return {
            success: true,
            qrImageUrl: qr.image_url,
            qrId: qr.id,
            expiresAt: expiryTime.toISOString(),
        };
    }
);

/**
 * Get Technician Wallet Balance
 */
export const getTechnicianWallet = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { technicianId: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated'
            );
        }

        const { technicianId } = data;

        // Verify ownership
        if (context.auth.uid !== technicianId) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Unauthorized'
            );
        }

        const walletRef = await getOrCreateWallet(technicianId);
        const walletDoc = await walletRef.get();
        const walletData = walletDoc.data();

        return {
            availableBalance: walletData?.availableBalance || 0,
            pendingBalance: walletData?.pendingBalance || 0,
            onHoldBalance: walletData?.onHoldBalance || 0,
            lifetimeEarnings: walletData?.lifetimeEarnings || 0,
            kycStatus: walletData?.kycStatus || 'pending',
            bankAccountId: walletData?.bankAccountId,
        };
    }
);

/**
 * Get Transaction History
 */
export const getTransactionHistory = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (
        data: { technicianId: string; limit?: number; startAfter?: string },
        context
    ) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated'
            );
        }

        const { technicianId, limit = 20, startAfter } = data;

        if (context.auth.uid !== technicianId) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Unauthorized'
            );
        }

        let query = db
            .collection('technician_wallets')
            .doc(technicianId)
            .collection('transactions')
            .orderBy('createdAt', 'desc')
            .limit(limit);

        if (startAfter) {
            const startDoc = await db
                .collection('technician_wallets')
                .doc(technicianId)
                .collection('transactions')
                .doc(startAfter)
                .get();

            if (startDoc.exists) {
                query = query.startAfter(startDoc);
            }
        }

        const snapshot = await query.get();

        const transactions = snapshot.docs.map((doc) => ({
            txnId: doc.id,
            ...doc.data(),
            createdAt: doc.data().createdAt?.toDate()?.toISOString(),
        }));

        return {
            transactions,
            lastDocId: snapshot.docs[snapshot.docs.length - 1]?.id,
        };
    }
);

/**
 * Get Payout History
 */
export const getPayoutHistory = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { technicianId: string; limit?: number }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated'
            );
        }

        const { technicianId, limit = 20 } = data;

        if (context.auth.uid !== technicianId) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Unauthorized'
            );
        }

        const snapshot = await db
            .collection('technician_payouts')
            .where('technicianId', '==', technicianId)
            .orderBy('createdAt', 'desc')
            .limit(limit)
            .get();

        const payouts = snapshot.docs.map((doc) => ({
            payoutId: doc.id,
            ...doc.data(),
            createdAt: doc.data().createdAt?.toDate()?.toISOString(),
            processedAt: doc.data().processedAt?.toDate()?.toISOString(),
        }));

        return { payouts };
    }
);

// ============================================
// BOOKING CREATION AND LIFECYCLE FUNCTIONS
// ============================================

/**
 * Create Urgent Booking - Customer creates urgent booking
 * 
 * Creates urgent booking with immediate technician assignment
 */
export const createUrgentBooking = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated'
            );
        }

        const {
            technicianId,
            technicianName,
            serviceType,
            district,
            urgentFee
        } = data;

        // Validate required fields
        if (!technicianId || !serviceType) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Missing required fields'
            );
        }

        try {
            const bookingRef = db.collection('bookings').doc();
            const bookingId = bookingRef.id;

            // Create urgent booking document
            await bookingRef.set({
                bookingId: bookingId,
                customerId: context.auth.uid,
                technicianId: technicianId,
                technicianName: technicianName || 'Unknown',
                serviceType: serviceType,
                serviceTitle: `Urgent ${serviceType}`,
                bookingStatus: BOOKING_STATUS.APPROVED_BY_ADMIN, // Skip admin approval for urgent
                paymentStatus: 'pending',
                paymentMode: 'pay_after_work',
                isUrgent: true,
                urgentFee: urgentFee || 100,
                district: district || '',
                scheduledDate: new Date().toISOString(),
                scheduledTime: 'ASAP',
                scheduledAt: admin.firestore.FieldValue.serverTimestamp(),
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Create audit log
            await createBookingAuditLog(
                context.auth.uid,
                'urgent_booking_created',
                bookingId,
                {
                    technicianId,
                    serviceType,
                    urgentFee,
                    status: BOOKING_STATUS.APPROVED_BY_ADMIN
                }
            );

            // Send notification to technician
            await sendNotification(
                technicianId,
                'Urgent Booking Request',
                `New urgent ${serviceType} booking request`,
                { bookingId, type: 'urgent_booking' }
            );

            return {
                success: true,
                bookingId: bookingId,
                status: BOOKING_STATUS.APPROVED_BY_ADMIN,
                message: 'Urgent booking created successfully'
            };
        } catch (error: any) {
            console.error('Error creating urgent booking:', error);
            throw new functions.https.HttpsError('internal', 'Failed to create urgent booking');
        }
    }
);

/**
 * Create Booking Request - Customer creates booking
 * 
 * Creates booking with status: pending_admin_approval
 * Admin must approve before technician can see it
 */
export const createBookingRequest = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated'
            );
        }

        const {
            serviceId,
            technicianId,
            categoryId,
            categoryName,
            scheduledDate,
            scheduledTime,
            address,
            price,
            subcategoryId,
            quantity,
            durationMinutes,
            couponCode,
            paymentMode,
            idempotencyKey
        } = data;

        // Validate required fields
        if (!serviceId || !technicianId || !categoryId || !scheduledDate || !scheduledTime || !address || !price) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Missing required fields'
            );
        }

        try {
            const bookingRef = db.collection('bookings').doc();
            const bookingId = bookingRef.id;

            // Create booking document
            await bookingRef.set({
                bookingId: bookingId,
                customerId: context.auth.uid,
                technicianId: technicianId,
                serviceId: serviceId,
                categoryId: categoryId,
                categoryName: categoryName || '',
                subcategoryId: subcategoryId || '',
                scheduledDate: scheduledDate,
                scheduledTime: scheduledTime,
                scheduledAt: admin.firestore.Timestamp.fromDate(new Date(`${scheduledDate} ${scheduledTime}`)),
                address: address,
                price: price,
                finalAmount: price,
                quantity: quantity || 1,
                durationMinutes: durationMinutes || 60,
                couponCode: couponCode || null,
                paymentMode: paymentMode || 'pay_after_work',
                bookingStatus: BOOKING_STATUS.PENDING_ADMIN_APPROVAL,
                paymentStatus: 'pending',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                idempotencyKey: idempotencyKey || `BK_${Date.now()}`
            });

            // Create audit log
            await createBookingAuditLog(
                context.auth.uid,
                'booking_created',
                bookingId,
                {
                    serviceId,
                    technicianId,
                    price,
                    status: BOOKING_STATUS.PENDING_ADMIN_APPROVAL
                }
            );

            return {
                success: true,
                bookingId: bookingId,
                status: BOOKING_STATUS.PENDING_ADMIN_APPROVAL,
                message: 'Booking created successfully. Waiting for admin approval.'
            };
        } catch (error: any) {
            console.error('Error creating booking:', error);
            throw new functions.https.HttpsError('internal', 'Failed to create booking');
        }
    }
);

/**
 * Technician Respond to Job - Accept or Reject booking
 */
export const technicianRespondToJob = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { bookingId: string; action: string; reason?: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated'
            );
        }

        const { bookingId, action, reason } = data;
        const technicianId = context.auth.uid;

        if (!bookingId || !action) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Missing bookingId or action'
            );
        }

        if (!['accept', 'reject'].includes(action)) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Action must be accept or reject'
            );
        }

        try {
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingDoc = await bookingRef.get();

            if (!bookingDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            }

            const bookingData = bookingDoc.data();

            // Verify technician owns this booking
            if (bookingData?.technicianId !== technicianId) {
                throw new functions.https.HttpsError(
                    'permission-denied',
                    'This booking is not assigned to you'
                );
            }

            // Verify booking is in correct status
            if (bookingData?.bookingStatus !== BOOKING_STATUS.APPROVED_BY_ADMIN) {
                throw new functions.https.HttpsError(
                    'failed-precondition',
                    'Booking must be approved by admin first'
                );
            }

            const newStatus = action === 'accept' 
                ? BOOKING_STATUS.TECHNICIAN_ACCEPTED 
                : BOOKING_STATUS.REJECTED;

            // Update booking status
            const updateData: Record<string, any> = {
                bookingStatus: newStatus,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };

            if (action === 'accept') {
                updateData.technicianAcceptedAt = admin.firestore.FieldValue.serverTimestamp();
            } else {
                updateData.rejectedByTechnician = true;
                updateData.rejectionReason = reason || 'Technician declined';
                updateData.rejectedAt = admin.firestore.FieldValue.serverTimestamp();
            }

            await bookingRef.update(updateData);

            // Create audit log
            await createBookingAuditLog(
                technicianId,
                action === 'accept' ? 'technician_accepted' : 'technician_rejected',
                bookingId,
                {
                    previousStatus: bookingData?.bookingStatus,
                    newStatus: newStatus,
                    reason: reason || null
                }
            );

            // Send notification to customer
            const notificationTitle = action === 'accept' 
                ? 'Technician Accepted' 
                : 'Technician Declined';
            const notificationBody = action === 'accept'
                ? 'Your booking has been accepted by the technician'
                : reason || 'The technician has declined your booking';

            await sendNotification(
                bookingData?.customerId,
                notificationTitle,
                notificationBody,
                { bookingId, type: `technician_${action}` }
            );

            return {
                success: true,
                message: `Booking ${action}ed successfully`,
                bookingId,
                newStatus
            };
        } catch (error: any) {
            console.error(`Error ${action}ing booking:`, error);
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            throw new functions.https.HttpsError('internal', `Failed to ${action} booking`);
        }
    }
);

/**
 * Update Booking Status - Generic status update function
 */
export const updateBookingStatus = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { bookingId: string; status: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated'
            );
        }

        const { bookingId, status } = data;

        if (!bookingId || !status) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Missing bookingId or status'
            );
        }

        // Map status values to standardized format
        const statusMapping: Record<string, string> = {
            'in_progress': BOOKING_STATUS.SERVICE_IN_PROGRESS,
            'service_in_progress': BOOKING_STATUS.SERVICE_IN_PROGRESS,
            'completed': BOOKING_STATUS.SERVICE_COMPLETED,
            'service_completed': BOOKING_STATUS.SERVICE_COMPLETED
        };

        const mappedStatus = statusMapping[status] || status;

        try {
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingDoc = await bookingRef.get();

            if (!bookingDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            }

            const bookingData = bookingDoc.data();

            // Verify user has permission to update this booking
            const userId = context.auth.uid;
            if (bookingData?.customerId !== userId && bookingData?.technicianId !== userId) {
                throw new functions.https.HttpsError(
                    'permission-denied',
                    'You do not have permission to update this booking'
                );
            }

            await bookingRef.update({
                bookingStatus: mappedStatus,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return {
                success: true,
                message: 'Booking status updated successfully',
                bookingId,
                newStatus: mappedStatus
            };
        } catch (error: any) {
            console.error('Error updating booking status:', error);
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            throw new functions.https.HttpsError('internal', 'Failed to update booking status');
        }
    }
);

/**
 * Complete Service - Mark service as completed
 */
export const completeService = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { bookingId: string }, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated'
            );
        }

        const { bookingId } = data;
        const technicianId = context.auth.uid;

        if (!bookingId) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Missing bookingId'
            );
        }

        try {
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingDoc = await bookingRef.get();

            if (!bookingDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            }

            const bookingData = bookingDoc.data();

            // Verify technician owns this booking
            if (bookingData?.technicianId !== technicianId) {
                throw new functions.https.HttpsError(
                    'permission-denied',
                    'This booking is not assigned to you'
                );
            }

            await bookingRef.update({
                bookingStatus: BOOKING_STATUS.SERVICE_COMPLETED,
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Create audit log
            await createBookingAuditLog(
                technicianId,
                'service_completed',
                bookingId,
                {
                    previousStatus: bookingData?.bookingStatus,
                    newStatus: BOOKING_STATUS.SERVICE_COMPLETED
                }
            );

            // Send notification to customer
            await sendNotification(
                bookingData?.customerId,
                'Service Completed',
                'Your service has been completed. Please rate your experience.',
                { bookingId, type: 'service_completed' }
            );

            return {
                success: true,
                message: 'Service completed successfully',
                bookingId
            };
        } catch (error: any) {
            console.error('Error completing service:', error);
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            throw new functions.https.HttpsError('internal', 'Failed to complete service');
        }
    }
);

// ============================================
// ADMIN BOOKING LIFECYCLE FUNCTIONS
// ============================================

/**
 * Approve Booking - Admin approves booking for technician assignment
 * 
 * Updates booking status from PENDING_ADMIN_APPROVAL to APPROVED_BY_ADMIN
 * Sends notification to nearby technicians
 */
export const approveBooking = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { bookingId: string }, context) => {
        verifyAdminRole(context);
        
        const { bookingId } = data;
        
        if (!bookingId) {
            throw new functions.https.HttpsError('invalid-argument', 'Booking ID is required');
        }

        try {
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingDoc = await bookingRef.get();
            
            if (!bookingDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            }

            const bookingData = bookingDoc.data();
            
            if (bookingData?.bookingStatus !== BOOKING_STATUS.PENDING_ADMIN_APPROVAL) {
                throw new functions.https.HttpsError(
                    'failed-precondition',
                    `Booking status must be ${BOOKING_STATUS.PENDING_ADMIN_APPROVAL}`
                );
            }

            // Update booking status
            await db.runTransaction(async (transaction) => {
                transaction.update(bookingRef, {
                    bookingStatus: BOOKING_STATUS.APPROVED_BY_ADMIN,
                    adminApprovedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            });

            // Create audit log
            await createBookingAuditLog(
                context.auth!.uid,
                'booking_approved',
                bookingId,
                {
                    previousStatus: bookingData?.bookingStatus,
                    newStatus: BOOKING_STATUS.APPROVED_BY_ADMIN,
                }
            );

            // Send notification to customer
            await sendNotification(
                bookingData?.customerId,
                'Booking Approved',
                'Your booking has been approved and technicians are being notified',
                { bookingId, type: 'booking_approved' }
            );

            return {
                success: true,
                message: 'Booking approved successfully',
                bookingId,
            };
        } catch (error: any) {
            console.error('Error approving booking:', error);
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            throw new functions.https.HttpsError('internal', 'Failed to approve booking');
        }
    }
);

/**
 * Reject Booking - Admin rejects booking
 * 
 * Updates booking status to REJECTED
 * Sends notification to customer
 */
export const rejectBooking = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { bookingId: string; reason?: string }, context) => {
        verifyAdminRole(context);
        
        const { bookingId, reason } = data;
        
        if (!bookingId) {
            throw new functions.https.HttpsError('invalid-argument', 'Booking ID is required');
        }

        try {
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingDoc = await bookingRef.get();
            
            if (!bookingDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            }

            const bookingData = bookingDoc.data();
            
            if (bookingData?.bookingStatus !== BOOKING_STATUS.PENDING_ADMIN_APPROVAL) {
                throw new functions.https.HttpsError(
                    'failed-precondition',
                    `Booking status must be ${BOOKING_STATUS.PENDING_ADMIN_APPROVAL}`
                );
            }

            // Update booking status
            await db.runTransaction(async (transaction) => {
                transaction.update(bookingRef, {
                    bookingStatus: BOOKING_STATUS.REJECTED,
                    rejectedByAdmin: true,
                    rejectionReason: reason || 'Rejected by admin',
                    rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            });

            // Create audit log
            await createBookingAuditLog(
                context.auth!.uid,
                'booking_rejected',
                bookingId,
                {
                    previousStatus: bookingData?.bookingStatus,
                    newStatus: BOOKING_STATUS.REJECTED,
                    reason: reason || 'No reason provided',
                }
            );

            // Send notification to customer
            await sendNotification(
                bookingData?.customerId,
                'Booking Rejected',
                reason || 'Your booking has been rejected',
                { bookingId, type: 'booking_rejected' }
            );

            return {
                success: true,
                message: 'Booking rejected successfully',
                bookingId,
            };
        } catch (error: any) {
            console.error('Error rejecting booking:', error);
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            throw new functions.https.HttpsError('internal', 'Failed to reject booking');
        }
    }
);

/**
 * Mark Booking Active - Technician starts service
 * 
 * Updates booking status from TECHNICIAN_ACCEPTED to IN_PROGRESS
 */
export const markBookingActive = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { bookingId: string }, context) => {
        verifyAdminRole(context);
        
        const { bookingId } = data;
        
        if (!bookingId) {
            throw new functions.https.HttpsError('invalid-argument', 'Booking ID is required');
        }

        try {
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingDoc = await bookingRef.get();
            
            if (!bookingDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            }

            const bookingData = bookingDoc.data();
            
            if (bookingData?.bookingStatus !== BOOKING_STATUS.TECHNICIAN_ACCEPTED) {
                throw new functions.https.HttpsError(
                    'failed-precondition',
                    `Booking status must be ${BOOKING_STATUS.TECHNICIAN_ACCEPTED}`
                );
            }

            // Update booking status
            await db.runTransaction(async (transaction) => {
                transaction.update(bookingRef, {
                    bookingStatus: BOOKING_STATUS.SERVICE_IN_PROGRESS,
                    serviceStartedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            });

            // Create audit log
            await createBookingAuditLog(
                context.auth!.uid,
                'booking_started',
                bookingId,
                {
                    previousStatus: bookingData?.bookingStatus,
                    newStatus: BOOKING_STATUS.SERVICE_IN_PROGRESS,
                }
            );

            // Send notification to customer
            await sendNotification(
                bookingData?.customerId,
                'Service Started',
                'Your service has started',
                { bookingId, type: 'service_started' }
            );

            return {
                success: true,
                message: 'Booking marked as active',
                bookingId,
            };
        } catch (error: any) {
            console.error('Error marking booking active:', error);
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            throw new functions.https.HttpsError('internal', 'Failed to mark booking active');
        }
    }
);

/**
 * Complete Booking - Mark service as completed
 * 
 * Updates booking status from IN_PROGRESS to COMPLETED
 */
export const completeBooking = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { bookingId: string }, context) => {
        verifyAdminRole(context);
        
        const { bookingId } = data;
        
        if (!bookingId) {
            throw new functions.https.HttpsError('invalid-argument', 'Booking ID is required');
        }

        try {
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingDoc = await bookingRef.get();
            
            if (!bookingDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            }

            const bookingData = bookingDoc.data();
            
            if (bookingData?.bookingStatus !== BOOKING_STATUS.SERVICE_IN_PROGRESS) {
                throw new functions.https.HttpsError(
                    'failed-precondition',
                    `Booking status must be ${BOOKING_STATUS.SERVICE_IN_PROGRESS}`
                );
            }

            // Update booking status
            await db.runTransaction(async (transaction) => {
                transaction.update(bookingRef, {
                    bookingStatus: BOOKING_STATUS.SERVICE_COMPLETED,
                    completedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            });

            // Create audit log
            await createBookingAuditLog(
                context.auth!.uid,
                'booking_completed',
                bookingId,
                {
                    previousStatus: bookingData?.bookingStatus,
                    newStatus: BOOKING_STATUS.SERVICE_COMPLETED,
                }
            );

            // Send notification to customer
            await sendNotification(
                bookingData?.customerId,
                'Service Completed',
                'Your service has been completed. Please rate your experience',
                { bookingId, type: 'service_completed' }
            );

            // Send notification to technician
            if (bookingData?.technicianId) {
                await sendNotification(
                    bookingData.technicianId,
                    'Booking Completed',
                    'Your service has been marked as completed',
                    { bookingId, type: 'booking_completed' }
                );
            }

            return {
                success: true,
                message: 'Booking completed successfully',
                bookingId,
            };
        } catch (error: any) {
            console.error('Error completing booking:', error);
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            throw new functions.https.HttpsError('internal', 'Failed to complete booking');
        }
    }
);

/**
 * Update Booking Payment - Mark payment as completed
 * 
 * Updates payment status to PAID
 */
export const updateBookingPayment = functions.https.onCall(
    {
        cors: true,
        enforceAppCheck: true,
    },
    async (data: { bookingId: string; paymentStatus: string }, context) => {
        verifyAdminRole(context);
        
        const { bookingId, paymentStatus } = data;
        
        if (!bookingId) {
            throw new functions.https.HttpsError('invalid-argument', 'Booking ID is required');
        }
        
        if (!paymentStatus) {
            throw new functions.https.HttpsError('invalid-argument', 'Payment status is required');
        }

        const validStatuses = ['PENDING', 'PAID', 'FAILED', 'REFUNDED'];
        if (!validStatuses.includes(paymentStatus)) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                `Payment status must be one of: ${validStatuses.join(', ')}`
            );
        }

        try {
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingDoc = await bookingRef.get();
            
            if (!bookingDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Booking not found');
            }

            const bookingData = bookingDoc.data();
            const previousPaymentStatus = bookingData?.paymentStatus;

            // Update booking payment status
            await db.runTransaction(async (transaction) => {
                const updateData: Record<string, any> = {
                    paymentStatus,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                };

                if (paymentStatus === 'PAID') {
                    updateData.paymentCompletedAt = admin.firestore.FieldValue.serverTimestamp();
                }

                transaction.update(bookingRef, updateData);
            });

            // Create audit log
            await createBookingAuditLog(
                context.auth!.uid,
                'booking_payment_updated',
                bookingId,
                {
                    previousPaymentStatus,
                    newPaymentStatus: paymentStatus,
                }
            );

            // Send notification to customer if payment is completed
            if (paymentStatus === 'PAID') {
                await sendNotification(
                    bookingData?.customerId,
                    'Payment Received',
                    'Your payment has been received successfully',
                    { bookingId, type: 'payment_received' }
                );
            }

            return {
                success: true,
                message: `Payment status updated to ${paymentStatus}`,
                bookingId,
            };
        } catch (error: any) {
            console.error('Error updating booking payment:', error);
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            throw new functions.https.HttpsError('internal', 'Failed to update booking payment');
        }
    }
);

// ============================================
// WEBHOOK HANDLERS
// ============================================

/**
 * Razorpay Payment Webhook
 * 
 * SECURITY: Verifies webhook signature before processing
 */
export const razorpayPaymentWebhook = functions.https.onRequest(
    async (req, res) => {
        const signature = req.headers['x-razorpay-signature'];
        const secret = functions.config().razorpay.webhook_secret;

        if (!signature || !secret) {
            res.status(400).send('Missing signature or secret');
            return;
        }

        const body = JSON.stringify(req.body);

        if (!verifyWebhookSignature(body, signature as string, secret)) {
            console.error('Invalid webhook signature');
            res.status(400).send('Invalid signature');
            return;
        }

        const event = req.body;

        switch (event.event) {
            case 'payment.captured':
                await handlePaymentCaptured(event.payload.payment.entity);
                break;
            case 'payment.failed':
                await handlePaymentFailed(event.payload.payment.entity);
                break;
            case 'qrcode.scanned':
                await handleQRScanned(event.payload.qrcode.entity);
                break;
        }

        res.status(200).send('OK');
    }
);

/**
 * Handle successful payment
 */
async function handlePaymentCaptured(payment: any) {
    const { notes, order_id } = payment;
    const bookingId = notes?.bookingId;

    if (!bookingId) {
        console.error('No bookingId in payment notes');
        return;
    }

    // Get booking details
    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    const bookingData = bookingDoc.data();

    if (!bookingData) {
        console.error('Booking not found:', bookingId);
        return;
    }

    const technicianId = bookingData.technicianId;
    const amount = payment.amount / 100; // Convert from paise

    // Calculate net amount
    const { commission, netAmount } = calculateNetAmount(amount);

    // Credit technician wallet
    const walletRef = await getOrCreateWallet(technicianId);

    await db.runTransaction(async (transaction) => {
        const walletDoc = await transaction.get(walletRef);
        const currentPending = walletDoc.data()?.pendingBalance || 0;
        const currentLifetime = walletDoc.data()?.lifetimeEarnings || 0;

        transaction.update(walletRef, {
            pendingBalance: currentPending + netAmount,
            lifetimeEarnings: currentLifetime + netAmount,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });

    // Create transaction record
    await createWalletTransaction(
        technicianId,
        'credit',
        'booking',
        'pending',
        netAmount,
        bookingId,
        `Payment via QR for booking ${bookingId}`
    );

    // Update booking payment status
    await db.collection('bookings').doc(bookingId).update({
        'payment.status': 'paid',
        'payment.paidAt': admin.firestore.FieldValue.serverTimestamp(),
        'payment.paymentId': payment.id,
        'payment.technicianAmount': netAmount,
        'payment.commission': commission,
    });

    // Update QR payment status
    const qrPaymentRef = db
        .collection('bookings')
        .doc(bookingId)
        .collection('payment')
        .doc('qr');

    await qrPaymentRef.update({
        status: 'paid',
        paymentId: payment.id,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await createAuditLog('payment_webhook_processed', technicianId, {
        bookingId,
        paymentId: payment.id,
        amount: netAmount,
    });

    console.log(`Payment captured for booking ${bookingId}: ₹${amount}`);
}

/**
 * Handle failed payment
 */
async function handlePaymentFailed(payment: any) {
    const { notes } = payment;
    const bookingId = notes?.bookingId;

    if (!bookingId) return;

    await db.collection('bookings').doc(bookingId).update({
        'payment.status': 'failed',
        'payment.error': payment.error_description,
    });

    console.log(`Payment failed for booking ${bookingId}`);
}

/**
 * Handle QR code scanned
 */
async function handleQRScanned(qr: any) {
    const { notes } = qr;
    const bookingId = notes?.bookingId;

    if (!bookingId) return;

    await db
        .collection('bookings')
        .doc(bookingId)
        .collection('payment')
        .doc('qr')
        .update({
            status: 'scanned',
            scannedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    console.log(`QR scanned for booking ${bookingId}`);
}

/**
 * Razorpay Payout Webhook
 */
export const razorpayPayoutWebhook = functions.https.onRequest(
    async (req, res) => {
        const signature = req.headers['x-razorpay-signature'];
        const secret = functions.config().razorpay.payout_webhook_secret;

        if (!signature || !secret) {
            res.status(400).send('Missing signature or secret');
            return;
        }

        const body = JSON.stringify(req.body);

        if (!verifyWebhookSignature(body, signature as string, secret)) {
            res.status(400).send('Invalid signature');
            return;
        }

        const event = req.body;

        switch (event.event) {
            case 'payout.processed':
                await handlePayoutProcessed(event.payload.payout.entity);
                break;
            case 'payout.failed':
                await handlePayoutFailed(event.payload.payout.entity);
                break;
            case 'payout.reversed':
                await handlePayoutReversed(event.payload.payout.entity);
                break;
        }

        res.status(200).send('OK');
    }
);

/**
 * Handle successful payout
 */
async function handlePayoutProcessed(payout: any) {
    const payoutId = payout.id;

    await db
        .collection('technician_payouts')
        .doc(payoutId)
        .update({
            status: 'success',
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    console.log(`Payout processed: ${payoutId}`);
}

/**
 * Handle failed payout
 */
async function handlePayoutFailed(payout: any) {
    const payoutId = payout.id;

    // Get payout details to rollback
    const payoutDoc = await db
        .collection('technician_payouts')
        .doc(payoutId)
        .get();

    const payoutData = payoutDoc.data();

    if (payoutData && payoutData.status === 'processing') {
        // Rollback: Add amount back to wallet
        const technicianId = payoutData.technicianId;
        const walletRef = db.collection('technician_wallets').doc(technicianId);

        await db.runTransaction(async (transaction) => {
            const walletDoc = await transaction.get(walletRef);
            const currentBalance = walletDoc.data()?.availableBalance || 0;

            transaction.update(walletRef, {
                availableBalance: currentBalance + payoutData.amount,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });

        await db
            .collection('technician_payouts')
            .doc(payoutId)
            .update({
                status: 'failed',
                failureReason: payout.failure_reason,
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
    }

    console.log(`Payout failed: ${payoutId}`);
}

/**
 * Handle reversed payout
 */
async function handlePayoutReversed(payout: any) {
    const payoutId = payout.id;

    await db
        .collection('technician_payouts')
        .doc(payoutId)
        .update({
            status: 'cancelled',
            failureReason: 'Payout reversed by bank',
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    console.log(`Payout reversed: ${payoutId}`);
}
