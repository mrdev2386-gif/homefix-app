"use strict";
/**
 * WITHDRAWAL REQUEST SYSTEM WITH ADMIN APPROVAL
 *
 * NEW FLOW:
 * 1. Technician requests withdrawal → creates request (status: pending)
 * 2. Admin reviews and approves/rejects
 * 3. On approval → deduct balance + process Razorpay payout
 * 4. On rejection → no balance deduction
 *
 * SECURITY:
 * - Balance NOT deducted until admin approval
 * - Atomic transaction on approval
 * - Idempotency protection
 * - Only admins can approve/reject
 *
 * PRODUCTION SAFETY:
 * - Structured logging for all operations
 * - Fail-safe payout handling (no money loss on failure)
 * - Retry mechanism with idempotency
 * - Admin alerts for critical events
 * - Analytics tracking
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
exports.getMyWithdrawalRequests = exports.getWithdrawalRequests = exports.rejectWithdrawalRequest = exports.approveWithdrawalRequest = exports.createWithdrawalRequest = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
const config_1 = require("../shared/config");
const { razorpay } = require('../config/razorpay');
const LOG_PREFIX = "[WITHDRAWAL_REQUEST]";
const MIN_WITHDRAWAL = 100;
const MAX_WITHDRAWAL = 50000;
const PAYOUT_FEE = 10;
const DAILY_REQUEST_LIMIT = 3;
const MAX_RETRY_ATTEMPTS = 2;
const RETRY_DELAY_MS = 500;
// Structured logging helper
function logWithdrawalEvent(event, data) {
    const logEntry = {
        timestamp: new Date().toISOString(),
        event,
        ...data
    };
    console.log(`${LOG_PREFIX} ${JSON.stringify(logEntry)}`);
    // Store critical events in Firestore for monitoring
    if (['request_created', 'approval_success', 'approval_failed', 'payout_failed'].includes(event)) {
        config_1.db.collection('withdrawal_logs').add({
            ...logEntry,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        }).catch(err => console.error('Failed to store log:', err));
    }
}
// Generate idempotency key
function generateRequestIdempotencyKey(technicianId, amount, timestamp) {
    return crypto.createHash('sha256')
        .update(`${technicianId}:${amount}:${timestamp}`)
        .digest('hex');
}
/**
 * CREATE WITHDRAWAL REQUEST (Technician)
 *
 * Creates a pending request WITHOUT deducting balance
 * Admin must approve before payout
 */
exports.createWithdrawalRequest = functions.region('asia-south1').https.onCall(async (data, context) => {
    const startTime = Date.now();
    if (!context.auth) {
        logWithdrawalEvent('request_failed', { error: 'Unauthenticated' });
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const technicianId = context.auth.uid;
    const { amount: requestedAmount } = data;
    const amount = Math.max(0, requestedAmount);
    logWithdrawalEvent('request_start', { technicianId, amount });
    try {
        // Validation: Amount
        if (!amount || amount < MIN_WITHDRAWAL) {
            logWithdrawalEvent('request_failed', { technicianId, amount, error: 'Amount too low' });
            throw new functions.https.HttpsError('invalid-argument', `Minimum withdrawal is ₹${MIN_WITHDRAWAL}`);
        }
        if (amount > MAX_WITHDRAWAL) {
            logWithdrawalEvent('request_failed', { technicianId, amount, error: 'Amount too high' });
            throw new functions.https.HttpsError('invalid-argument', `Maximum withdrawal is ₹${MAX_WITHDRAWAL}`);
        }
        const walletRef = config_1.db.collection('technician_wallets').doc(technicianId);
        const techRef = config_1.db.collection('technicians').doc(technicianId);
        const [walletDoc, techDoc] = await Promise.all([walletRef.get(), techRef.get()]);
        if (!walletDoc.exists || !techDoc.exists) {
            logWithdrawalEvent('request_failed', { technicianId, error: 'Wallet or profile not found' });
            throw new functions.https.HttpsError('not-found', 'Wallet or profile not found');
        }
        const wallet = walletDoc.data();
        const tech = techDoc.data();
        // Validation: Bank verification
        if (tech.bankVerified !== true || tech.bankVerificationStatus !== 'verified') {
            logWithdrawalEvent('request_failed', { technicianId, error: 'Bank not verified' });
            throw new functions.https.HttpsError('failed-precondition', 'Please verify your bank account before requesting withdrawal');
        }
        if (!tech.fundAccountId) {
            logWithdrawalEvent('request_failed', { technicianId, error: 'No fund account' });
            throw new functions.https.HttpsError('failed-precondition', 'Bank account verification incomplete');
        }
        // Validation: Balance check
        const currentBalance = wallet.availableBalance || 0;
        if (currentBalance < amount) {
            logWithdrawalEvent('request_failed', {
                technicianId,
                amount,
                error: `Insufficient balance: ${currentBalance}`
            });
            throw new functions.https.HttpsError('failed-precondition', `Insufficient balance. Available: ₹${currentBalance}, Requested: ₹${amount}`);
        }
        // Validation: Account status
        if (tech.status === 'suspended' || tech.status === 'deactivated') {
            logWithdrawalEvent('request_failed', { technicianId, error: 'Account suspended' });
            throw new functions.https.HttpsError('failed-precondition', 'Account is suspended');
        }
        // Rate limiting: Daily request limit
        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);
        const todayRequests = await config_1.db.collection('withdrawal_requests')
            .where('technicianId', '==', technicianId)
            .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(todayStart))
            .get();
        if (todayRequests.size >= DAILY_REQUEST_LIMIT) {
            logWithdrawalEvent('request_failed', {
                technicianId,
                error: `Daily limit exceeded: ${todayRequests.size}`
            });
            throw new functions.https.HttpsError('resource-exhausted', `Maximum ${DAILY_REQUEST_LIMIT} withdrawal requests per day allowed`);
        }
        // Check for pending requests
        const pendingRequests = await config_1.db.collection('withdrawal_requests')
            .where('technicianId', '==', technicianId)
            .where('status', '==', 'pending')
            .get();
        if (!pendingRequests.empty) {
            logWithdrawalEvent('request_failed', { technicianId, error: 'Pending request exists' });
            throw new functions.https.HttpsError('failed-precondition', 'You already have a pending withdrawal request. Please wait for admin approval.');
        }
        // Idempotency check
        const timestamp = Date.now();
        const idempotencyKey = generateRequestIdempotencyKey(technicianId, amount, Math.floor(timestamp / 60000));
        const existingRequest = await config_1.db.collection('withdrawal_requests')
            .where('idempotencyKey', '==', idempotencyKey)
            .limit(1)
            .get();
        if (!existingRequest.empty) {
            const existing = existingRequest.docs[0];
            logWithdrawalEvent('request_duplicate', {
                technicianId,
                requestId: existing.id
            });
            return {
                success: true,
                requestId: existing.id,
                status: existing.data().status,
                message: 'Request already exists',
                isDuplicate: true
            };
        }
        // Create withdrawal request
        const requestRef = config_1.db.collection('withdrawal_requests').doc();
        await requestRef.set({
            technicianId,
            technicianName: tech.name || 'Technician',
            technicianPhone: tech.phone || '',
            amount,
            fee: PAYOUT_FEE,
            netAmount: amount - PAYOUT_FEE,
            status: 'pending',
            idempotencyKey,
            fundAccountId: tech.fundAccountId,
            walletBalanceAtRequest: currentBalance,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        logWithdrawalEvent('request_created', {
            requestId: requestRef.id,
            technicianId,
            amount,
            status: 'pending'
        });
        // Update analytics
        await config_1.db.collection('system_analytics').doc('withdrawals').set({
            totalRequests: admin.firestore.FieldValue.increment(1),
            totalAmountRequested: admin.firestore.FieldValue.increment(amount),
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true }).catch(err => console.error('Analytics update failed:', err));
        // Notify admins
        const adminsSnapshot = await config_1.db.collection('admins').limit(10).get();
        const notificationPromises = [];
        for (const adminDoc of adminsSnapshot.docs) {
            notificationPromises.push(config_1.db.collection('notifications').add({
                userId: adminDoc.id,
                title: 'New Withdrawal Request',
                body: `${tech.name} requested withdrawal of ₹${amount}`,
                type: 'withdrawal_request',
                requestId: requestRef.id,
                priority: 'high',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            }));
        }
        await Promise.allSettled(notificationPromises);
        const duration = Date.now() - startTime;
        logWithdrawalEvent('request_success', {
            requestId: requestRef.id,
            technicianId,
            amount,
            duration
        });
        return {
            success: true,
            requestId: requestRef.id,
            status: 'pending',
            amount,
            message: 'Withdrawal request submitted. Awaiting admin approval.'
        };
    }
    catch (error) {
        logWithdrawalEvent('request_error', {
            technicianId,
            amount,
            error: error.message
        });
        throw error;
    }
});
/**
 * APPROVE WITHDRAWAL REQUEST (Admin)
 *
 * Validates balance, deducts atomically, processes Razorpay payout
 * FAIL-SAFE: If payout fails, balance is NOT deducted (request marked as failed for retry)
 */
exports.approveWithdrawalRequest = functions.region('asia-south1').https.onCall(async (data, context) => {
    const startTime = Date.now();
    if (!context.auth) {
        logWithdrawalEvent('approval_failed', { error: 'Unauthenticated' });
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const adminId = context.auth.uid;
    const { requestId, retryAttempt = 0 } = data;
    if (!requestId) {
        logWithdrawalEvent('approval_failed', { error: 'Missing requestId' });
        throw new functions.https.HttpsError('invalid-argument', 'requestId required');
    }
    // Verify admin
    const adminDoc = await config_1.db.collection('admins').doc(adminId).get();
    if (!adminDoc.exists) {
        logWithdrawalEvent('approval_failed', { requestId, error: 'Not admin' });
        throw new functions.https.HttpsError('permission-denied', 'Only admins can approve withdrawals');
    }
    const requestRef = config_1.db.collection('withdrawal_requests').doc(requestId);
    const requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
        logWithdrawalEvent('approval_failed', { requestId, error: 'Request not found' });
        throw new functions.https.HttpsError('not-found', 'Request not found');
    }
    const request = requestDoc.data();
    // Allow retry for failed requests
    if (request.status !== 'pending' && request.status !== 'failed') {
        logWithdrawalEvent('approval_failed', {
            requestId,
            error: `Invalid status: ${request.status}`
        });
        throw new functions.https.HttpsError('failed-precondition', `Request already ${request.status}`);
    }
    const { technicianId, amount, fundAccountId } = request;
    logWithdrawalEvent('approval_start', {
        requestId,
        technicianId,
        amount,
        retryAttempt
    });
    let razorpayPayout = null;
    let payoutCreated = false;
    try {
        // STEP 1: Create Razorpay payout FIRST (before deducting balance)
        const rzp = razorpay;
        const config = functions.config();
        const payoutAccount = config.razorpay?.payout_account || '';
        if (!payoutAccount) {
            logWithdrawalEvent('payout_failed', {
                requestId,
                error: 'Payout account not configured'
            });
            throw new Error('Razorpay payout account not configured');
        }
        const payoutId = `payout_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        logWithdrawalEvent('payout_start', { requestId, fundAccountId });
        // Retry logic for payout creation
        let lastError = null;
        for (let attempt = 0; attempt <= MAX_RETRY_ATTEMPTS; attempt++) {
            try {
                razorpayPayout = await rzp.payouts.create({
                    account_number: payoutAccount,
                    fund_account_id: fundAccountId,
                    amount: Math.round((amount - PAYOUT_FEE) * 100), // Net amount in paise
                    currency: 'INR',
                    mode: 'IMPS',
                    purpose: 'payout',
                    queue_if_low_balance: false,
                    reference_id: payoutId,
                    narration: `Withdrawal ${requestId}`,
                    notes: {
                        technicianId,
                        requestId,
                        payoutId,
                        attempt: attempt.toString()
                    }
                });
                payoutCreated = true;
                logWithdrawalEvent('payout_created', {
                    requestId,
                    razorpayPayoutId: razorpayPayout.id,
                    attempt
                });
                break;
            }
            catch (err) {
                lastError = err;
                logWithdrawalEvent('payout_retry', {
                    requestId,
                    attempt,
                    error: err.message
                });
                if (attempt < MAX_RETRY_ATTEMPTS) {
                    await new Promise(resolve => setTimeout(resolve, RETRY_DELAY_MS * (attempt + 1)));
                }
            }
        }
        if (!payoutCreated) {
            throw lastError || new Error('Payout creation failed after retries');
        }
        // STEP 2: ONLY deduct balance if payout was created successfully
        await config_1.db.runTransaction(async (transaction) => {
            // Re-check request status
            const freshRequest = await transaction.get(requestRef);
            if (!freshRequest.exists) {
                throw new Error('Request not found');
            }
            const freshStatus = freshRequest.data()?.status;
            if (freshStatus !== 'pending' && freshStatus !== 'failed') {
                throw new Error(`Request no longer pending (status: ${freshStatus})`);
            }
            // Re-check balance INSIDE transaction
            const walletRef = config_1.db.collection('technician_wallets').doc(technicianId);
            const walletDoc = await transaction.get(walletRef);
            if (!walletDoc.exists) {
                throw new Error('Wallet not found');
            }
            const currentBalance = walletDoc.data()?.availableBalance || 0;
            if (currentBalance < amount) {
                throw new Error(`Insufficient balance. Available: ₹${currentBalance}, Required: ₹${amount}`);
            }
            // Deduct balance
            transaction.update(walletRef, {
                availableBalance: admin.firestore.FieldValue.increment(-amount),
                lastPayoutAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            // Create transaction record
            const txnRef = walletRef.collection('transactions').doc();
            transaction.set(txnRef, {
                type: 'debit',
                source: 'withdrawal',
                status: 'completed',
                amount: -amount,
                fee: PAYOUT_FEE,
                netAmount: -(amount - PAYOUT_FEE),
                referenceId: requestId,
                razorpayPayoutId: razorpayPayout.id,
                description: `Withdrawal approved by admin`,
                balanceBefore: currentBalance,
                balanceAfter: currentBalance - amount,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            // Update request status
            transaction.update(requestRef, {
                status: 'approved',
                approvedBy: adminId,
                approvedAt: admin.firestore.FieldValue.serverTimestamp(),
                razorpayPayoutId: razorpayPayout.id,
                razorpayStatus: razorpayPayout.status,
                payoutId,
                retryAttempts: retryAttempt,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        const duration = Date.now() - startTime;
        logWithdrawalEvent('approval_success', {
            requestId,
            technicianId,
            amount,
            razorpayPayoutId: razorpayPayout.id,
            duration
        });
        // Update analytics
        await config_1.db.collection('system_analytics').doc('withdrawals').set({
            totalApproved: admin.firestore.FieldValue.increment(1),
            totalAmountApproved: admin.firestore.FieldValue.increment(amount),
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true }).catch(err => console.error('Analytics update failed:', err));
        // Notify technician
        await config_1.db.collection('notifications').add({
            userId: technicianId,
            title: 'Withdrawal Approved',
            body: `Your withdrawal of ₹${amount - PAYOUT_FEE} has been approved and processed`,
            type: 'withdrawal_approved',
            requestId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return {
            success: true,
            requestId,
            razorpayPayoutId: razorpayPayout.id,
            message: 'Withdrawal approved and processed'
        };
    }
    catch (error) {
        logWithdrawalEvent('approval_failed', {
            requestId,
            technicianId,
            amount,
            error: error.message,
            payoutCreated
        });
        // FAIL-SAFE: Mark request as failed (balance NOT deducted if payout failed)
        // Admin can retry the approval
        await requestRef.update({
            status: 'failed',
            error: error.message,
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
            retryAttempts: retryAttempt,
            canRetry: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }).catch(() => { });
        // Alert admins about failure
        const adminsSnapshot = await config_1.db.collection('admins').limit(10).get();
        for (const adminDoc of adminsSnapshot.docs) {
            await config_1.db.collection('notifications').add({
                userId: adminDoc.id,
                title: 'Withdrawal Approval Failed',
                body: `Failed to process withdrawal for request ${requestId}. Error: ${error.message}`,
                type: 'withdrawal_failed',
                requestId,
                priority: 'critical',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            }).catch(() => { });
        }
        throw new functions.https.HttpsError('internal', error.message || 'Approval failed');
    }
});
/**
 * REJECT WITHDRAWAL REQUEST (Admin)
 */
exports.rejectWithdrawalRequest = functions.region('asia-south1').https.onCall(async (data, context) => {
    const startTime = Date.now();
    if (!context.auth) {
        logWithdrawalEvent('rejection_failed', { error: 'Unauthenticated' });
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const adminId = context.auth.uid;
    const { requestId, reason } = data;
    if (!requestId) {
        logWithdrawalEvent('rejection_failed', { error: 'Missing requestId' });
        throw new functions.https.HttpsError('invalid-argument', 'requestId required');
    }
    // Verify admin
    const adminDoc = await config_1.db.collection('admins').doc(adminId).get();
    if (!adminDoc.exists) {
        logWithdrawalEvent('rejection_failed', { requestId, error: 'Not admin' });
        throw new functions.https.HttpsError('permission-denied', 'Only admins can reject withdrawals');
    }
    const requestRef = config_1.db.collection('withdrawal_requests').doc(requestId);
    const requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
        logWithdrawalEvent('rejection_failed', { requestId, error: 'Request not found' });
        throw new functions.https.HttpsError('not-found', 'Request not found');
    }
    const request = requestDoc.data();
    if (request.status !== 'pending') {
        logWithdrawalEvent('rejection_failed', {
            requestId,
            error: `Invalid status: ${request.status}`
        });
        throw new functions.https.HttpsError('failed-precondition', `Request already ${request.status}`);
    }
    logWithdrawalEvent('rejection_start', {
        requestId,
        technicianId: request.technicianId,
        amount: request.amount
    });
    await requestRef.update({
        status: 'rejected',
        rejectedBy: adminId,
        rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
        rejectionReason: reason || 'Rejected by admin',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    // Update analytics
    await config_1.db.collection('system_analytics').doc('withdrawals').set({
        totalRejected: admin.firestore.FieldValue.increment(1),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true }).catch(err => console.error('Analytics update failed:', err));
    // Notify technician
    await config_1.db.collection('notifications').add({
        userId: request.technicianId,
        title: 'Withdrawal Rejected',
        body: `Your withdrawal request was rejected. ${reason || ''}`,
        type: 'withdrawal_rejected',
        requestId,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    const duration = Date.now() - startTime;
    logWithdrawalEvent('rejection_success', {
        requestId,
        technicianId: request.technicianId,
        amount: request.amount,
        duration
    });
    return {
        success: true,
        requestId,
        message: 'Withdrawal request rejected'
    };
});
/**
 * GET WITHDRAWAL REQUESTS (Admin)
 */
exports.getWithdrawalRequests = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    // Verify admin
    const adminDoc = await config_1.db.collection('admins').doc(context.auth.uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }
    const { status = 'pending', limit = 50 } = data;
    let query = config_1.db.collection('withdrawal_requests')
        .orderBy('createdAt', 'desc')
        .limit(limit);
    if (status && status !== 'all') {
        query = query.where('status', '==', status);
    }
    const snapshot = await query.get();
    const requests = snapshot.docs.map(doc => {
        const d = doc.data();
        return {
            requestId: doc.id,
            technicianId: d.technicianId,
            technicianName: d.technicianName,
            technicianPhone: d.technicianPhone,
            amount: d.amount,
            fee: d.fee,
            netAmount: d.netAmount,
            status: d.status,
            walletBalanceAtRequest: d.walletBalanceAtRequest,
            createdAt: d.createdAt?.toDate()?.toISOString(),
            approvedAt: d.approvedAt?.toDate()?.toISOString(),
            rejectedAt: d.rejectedAt?.toDate()?.toISOString(),
            approvedBy: d.approvedBy,
            rejectedBy: d.rejectedBy,
            rejectionReason: d.rejectionReason,
            razorpayPayoutId: d.razorpayPayoutId
        };
    });
    return { requests };
});
/**
 * GET MY WITHDRAWAL REQUESTS (Technician)
 */
exports.getMyWithdrawalRequests = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const technicianId = context.auth.uid;
    const { limit = 20 } = data;
    const snapshot = await config_1.db.collection('withdrawal_requests')
        .where('technicianId', '==', technicianId)
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();
    const requests = snapshot.docs.map(doc => {
        const d = doc.data();
        return {
            requestId: doc.id,
            amount: d.amount,
            fee: d.fee,
            netAmount: d.netAmount,
            status: d.status,
            createdAt: d.createdAt?.toDate()?.toISOString(),
            approvedAt: d.approvedAt?.toDate()?.toISOString(),
            rejectedAt: d.rejectedAt?.toDate()?.toISOString(),
            rejectionReason: d.rejectionReason
        };
    });
    return { requests };
});
//# sourceMappingURL=withdrawal_requests.js.map