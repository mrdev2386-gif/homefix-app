import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { db } from '../shared/config';
const { razorpay } = require('../config/razorpay');

const LOG_PREFIX = "[WITHDRAWAL]";

const MIN_WITHDRAWAL = 100;
const MAX_WITHDRAWAL = 50000;
const PAYOUT_FEE = 10;
const DAILY_WITHDRAWAL_LIMIT = 3;
const COOLDOWN_HOURS = 6;

// Generate idempotency key for withdrawal
function generateWithdrawalIdempotencyKey(technicianId: string, amount: number, timestamp: number): string {
    return crypto.createHash('sha256')
        .update(`${technicianId}:${amount}:${timestamp}`)
        .digest('hex');
}

// Get Razorpay config
function getRazorpayConfig() {
    const config = functions.config();
    return {
        payout_account: config.razorpay?.payout_account || '',
    };
}

/**
 * Request withdrawal with AUTOMATIC Razorpay payout
 * NO ADMIN APPROVAL REQUIRED
 * 
 * Flow:
 * 1. Validate technician and bank details
 * 2. Check balance and limits
 * 3. Create Razorpay payout immediately
 * 4. Deduct balance atomically
 * 5. Log transaction
 */
export const requestWithdrawal = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        console.error(`${LOG_PREFIX} Auth required`);
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }

    const technicianId = context.auth.uid;
    const { amount: requestedAmount } = data;
    const amount = Math.max(0, requestedAmount);

    console.log(`${LOG_PREFIX} Withdrawal request - Technician: ${technicianId}, Amount: ${amount}`);

    // Validation: Amount
    if (!amount || amount < MIN_WITHDRAWAL) {
        console.warn(`${LOG_PREFIX} Invalid amount - Min: ${MIN_WITHDRAWAL}, Requested: ${amount}`);
        throw new functions.https.HttpsError('invalid-argument', `Minimum withdrawal is ₹${MIN_WITHDRAWAL}`);
    }

    if (amount > MAX_WITHDRAWAL) {
        console.warn(`${LOG_PREFIX} Exceeds max - Max: ${MAX_WITHDRAWAL}, Requested: ${amount}`);
        throw new functions.https.HttpsError('invalid-argument', `Maximum withdrawal is ₹${MAX_WITHDRAWAL}`);
    }

    const walletRef = db.collection('technician_wallets').doc(technicianId);
    const techRef = db.collection('technicians').doc(technicianId);

    const [walletDoc, techDoc] = await Promise.all([walletRef.get(), techRef.get()]);

    if (!walletDoc.exists || !techDoc.exists) {
        console.error(`${LOG_PREFIX} Not found - Technician: ${technicianId}`);
        throw new functions.https.HttpsError('not-found', 'Wallet or profile not found');
    }

    const wallet = walletDoc.data()!;
    const tech = techDoc.data()!;

    // Validation: Bank verification
    if (tech.bankVerified !== true || tech.bankVerificationStatus !== 'verified') {
        console.warn(`${LOG_PREFIX} Bank not verified - Status: ${tech.bankVerificationStatus}`);
        throw new functions.https.HttpsError(
            'failed-precondition', 
            'Please verify your bank account before requesting withdrawal. Go to Profile > Bank Details to verify.'
        );
    }

    if (!tech.fundAccountId) {
        console.warn(`${LOG_PREFIX} Fund account missing`);
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Bank account verification incomplete. Please re-verify your bank details.'
        );
    }

    // Validation: Balance
    if (wallet.availableBalance < amount) {
        console.warn(`${LOG_PREFIX} Insufficient balance - Available: ${wallet.availableBalance}, Requested: ${amount}`);
        throw new functions.https.HttpsError('failed-precondition', `Insufficient balance. Available: ₹${wallet.availableBalance}`);
    }

    // Validation: Account status
    if (tech.status === 'suspended' || tech.status === 'deactivated') {
        console.warn(`${LOG_PREFIX} Account suspended - Status: ${tech.status}`);
        throw new functions.https.HttpsError('failed-precondition', 'Technician account is suspended');
    }

    // Rate limiting: Daily withdrawal limit
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayWithdrawals = await db.collection('technician_wallets')
        .doc(technicianId)
        .collection('transactions')
        .where('type', '==', 'debit')
        .where('source', '==', 'withdrawal')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(todayStart))
        .get();

    if (todayWithdrawals.size >= DAILY_WITHDRAWAL_LIMIT) {
        console.warn(`${LOG_PREFIX} Daily limit exceeded - Count: ${todayWithdrawals.size}`);
        throw new functions.https.HttpsError('resource-exhausted', `Maximum ${DAILY_WITHDRAWAL_LIMIT} withdrawals per day allowed.`);
    }

    // Rate limiting: Cooldown period
    if (wallet.lastPayoutAt) {
        const lastPayout = wallet.lastPayoutAt.toDate();
        const cooldownEnd = new Date(lastPayout.getTime() + COOLDOWN_HOURS * 60 * 60 * 1000);
        if (new Date() < cooldownEnd) {
            const remainingMinutes = Math.ceil((cooldownEnd.getTime() - Date.now()) / (60 * 1000));
            console.warn(`${LOG_PREFIX} Cooldown active - Remaining: ${remainingMinutes} minutes`);
            throw new functions.https.HttpsError('failed-precondition', `Please wait ${remainingMinutes} minutes before next withdrawal.`);
        }
    }

    // Idempotency: Check for duplicate requests
    const timestamp = Date.now();
    const idempotencyKey = generateWithdrawalIdempotencyKey(technicianId, amount, Math.floor(timestamp / 60000));
    
    const existingPayout = await db.collection('payouts')
        .where('idempotencyKey', '==', idempotencyKey)
        .where('status', 'in', ['processing', 'processed'])
        .limit(1)
        .get();

    if (!existingPayout.empty) {
        const existing = existingPayout.docs[0].data();
        console.log(`${LOG_PREFIX} Duplicate detected - Payout ID: ${existing.razorpayPayoutId}`);
        return {
            success: true,
            payoutId: existingPayout.docs[0].id,
            razorpayPayoutId: existing.razorpayPayoutId,
            message: 'Withdrawal already in progress',
            isDuplicate: true
        };
    }

    // Create payout record
    const payoutId = `payout_${timestamp}_${Math.random().toString(36).substr(2, 9)}`;
    const payoutRef = db.collection('payouts').doc(payoutId);

    try {
        // Store payout record with processing status
        await payoutRef.set({
            id: payoutId,
            technicianId,
            amount,
            fee: PAYOUT_FEE,
            netAmount: amount - PAYOUT_FEE,
            status: 'processing',
            idempotencyKey,
            fundAccountId: tech.fundAccountId,
            technicianName: tech.name,
            technicianPhone: tech.phone,
            walletBalanceAtRequest: wallet.availableBalance,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`${LOG_PREFIX} Payout record created - ID: ${payoutId}`);

        // Use direct Razorpay instance
        const rzp = razorpay;
        const { payout_account } = getRazorpayConfig();

        if (!payout_account) {
            throw new Error('Razorpay payout account not configured');
        }

        // Create Razorpay payout
        console.log(`${LOG_PREFIX} Creating Razorpay payout - Fund Account: ${tech.fundAccountId}`);
        
        const razorpayPayout = await (rzp as any).payouts.create({
            account_number: payout_account,
            fund_account_id: tech.fundAccountId,
            amount: Math.round((amount - PAYOUT_FEE) * 100), // Net amount in paise
            currency: 'INR',
            mode: 'IMPS',
            purpose: 'payout',
            queue_if_low_balance: false,
            reference_id: payoutId,
            narration: `Withdrawal ${payoutId}`,
            notes: {
                technicianId,
                technicianName: tech.name,
                payoutId
            }
        });

        console.log(`${LOG_PREFIX} Razorpay payout created - ID: ${razorpayPayout.id}, Status: ${razorpayPayout.status}`);

        // Atomic wallet update
        await db.runTransaction(async (t) => {
            const currentWallet = await t.get(walletRef);
            const currentBalance = currentWallet.data()?.availableBalance || 0;

            // Double-check balance
            if (currentBalance < amount) {
                throw new Error('Insufficient balance during transaction');
            }

            // Deduct balance
            t.update(walletRef, {
                availableBalance: admin.firestore.FieldValue.increment(-amount),
                lastPayoutAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Create transaction record
            const txnRef = walletRef.collection('transactions').doc();
            t.set(txnRef, {
                type: 'debit',
                source: 'withdrawal',
                status: 'completed',
                amount: -amount,
                fee: PAYOUT_FEE,
                netAmount: -(amount - PAYOUT_FEE),
                referenceId: payoutId,
                razorpayPayoutId: razorpayPayout.id,
                description: `Withdrawal to bank account`,
                balanceBefore: currentBalance,
                balanceAfter: currentBalance - amount,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Update payout record
            t.update(payoutRef, {
                razorpayPayoutId: razorpayPayout.id,
                razorpayStatus: razorpayPayout.status,
                status: 'processed',
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        console.log(`${LOG_PREFIX} Withdrawal successful - Payout ID: ${payoutId}, Razorpay ID: ${razorpayPayout.id}`);

        return {
            success: true,
            payoutId,
            razorpayPayoutId: razorpayPayout.id,
            amount,
            netAmount: amount - PAYOUT_FEE,
            fee: PAYOUT_FEE,
            message: `Withdrawal of ₹${amount - PAYOUT_FEE} initiated successfully. Funds will be credited to your bank account within 30 minutes.`
        };

    } catch (error: any) {
        console.error(`${LOG_PREFIX} Withdrawal failed:`, error);

        // Update payout record with failure
        await payoutRef.update({
            status: 'failed',
            error: error.message,
            razorpayError: error.response?.data || null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }).catch(() => {});

        // Return user-friendly error
        const errorMessage = error.response?.data?.error?.description || error.message || 'Withdrawal failed';
        throw new functions.https.HttpsError('internal', errorMessage);
    }
});


/**
 * Get withdrawal/payout history for technician
 */
export const getPayoutHistory = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }

    const technicianId = context.auth.uid;
    const { limit = 20 } = data;

    const snapshot = await db.collection('payouts')
        .where('technicianId', '==', technicianId)
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();

    const payouts = snapshot.docs.map(doc => {
        const d = doc.data();
        return {
            payoutId: doc.id,
            amount: d.amount,
            fee: d.fee,
            netAmount: d.netAmount,
            status: d.status,
            razorpayPayoutId: d.razorpayPayoutId,
            razorpayStatus: d.razorpayStatus,
            error: d.error,
            createdAt: d.createdAt?.toDate()?.toISOString(),
            processedAt: d.processedAt?.toDate()?.toISOString()
        };
    });

    return { payouts };
});


export const getTransactionHistory = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }

    const technicianId = context.auth.uid;
    const { limit = 20, startAfter } = data;

    let query = db.collection('technician_wallets')
        .doc(technicianId)
        .collection('transactions')
        .orderBy('createdAt', 'desc')
        .limit(limit);

    if (startAfter) {
        const startDoc = await db.collection('technician_wallets')
            .doc(technicianId)
            .collection('transactions')
            .doc(startAfter)
            .get();
        query = query.startAfter(startDoc);
    }

    const snapshot = await query.get();

    const transactions = snapshot.docs.map(doc => {
        const d = doc.data();
        return {
            txnId: doc.id,
            type: d.type,
            source: d.source,
            status: d.status,
            amount: d.amount,
            fee: d.fee,
            referenceId: d.referenceId,
            description: d.description,
            createdAt: d.createdAt?.toDate()?.toISOString()
        };
    });

    return { transactions };
});


export const generateBookingQR = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }

    const technicianId = context.auth.uid;
    const { bookingId } = data;

    if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'Booking ID required');
    }

    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking = bookingDoc.data()!;

    if (booking.technicianId !== technicianId) {
        throw new functions.https.HttpsError('permission-denied', 'Not assigned to this booking');
    }

    if (booking.payment?.status === 'paid') {
        throw new functions.https.HttpsError('already-exists', 'Booking already paid');
    }

    const existingQR = await db.collection('bookings')
        .doc(bookingId)
        .collection('payment')
        .doc('qr')
        .get();

    if (existingQR.exists) {
        const qrData = existingQR.data()!;
        const expiresAt = qrData.expiresAt?.toDate();

        if (expiresAt && new Date() < expiresAt) {
            return {
                success: true,
                qrImageUrl: qrData.qrImageUrl,
                qrId: qrData.qrId,
                expiresAt: expiresAt.toISOString(),
                amount: booking.pricing?.total || booking.pricing?.subtotal || 0
            };
        }
    }

    const rzp = razorpay;
    const totalAmount = booking.pricing?.total || booking.pricing?.subtotal || 0;

    const qrCode = await (rzp as any).qrCodes.create({
        type: 'upi_qr',
        name: `Booking_${booking.bookingNumber}`,
        usage: 'single_use',
        fixed_amount: true,
        payment_amount: Math.round(totalAmount * 100),
        currency: 'INR',
        notes: {
            bookingId,
            technicianId
        }
    });

    const expiresAt = new Date(Date.now() + 30 * 60 * 1000);

    await db.collection('bookings').doc(bookingId)
        .collection('payment').doc('qr').set({
            qrId: qrCode.id,
            qrImageUrl: qrCode.image_url,
            status: 'generated',
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
            amount: totalAmount,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

    return {
        success: true,
        qrImageUrl: qrCode.image_url,
        qrId: qrCode.id,
        expiresAt: expiresAt.toISOString(),
        amount: totalAmount
    };
});

/**
 * Generate QR code for technician wallet payments
 * Customers can scan this QR to pay directly to technician wallet
 * Platform takes 10% fee automatically via webhook
 */
export const generateTechnicianWalletQR = functions.region('asia-south1').https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }

    const technicianId = context.auth.uid;
    
    console.log(`${LOG_PREFIX} Generating wallet QR - Technician: ${technicianId}`);

    // Verify technician exists
    const techDoc = await db.collection('technicians').doc(technicianId).get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician not found');
    }

    const techData = techDoc.data()!;
    
    // Check for existing active QR (not expired)
    const existingQRSnapshot = await db.collection('technician_qr_codes')
        .where('technicianId', '==', technicianId)
        .where('status', '==', 'active')
        .where('expiresAt', '>', admin.firestore.Timestamp.now())
        .limit(1)
        .get();

    if (!existingQRSnapshot.empty) {
        const qrData = existingQRSnapshot.docs[0].data();
        console.log(`${LOG_PREFIX} Returning existing QR - ID: ${qrData.qrId}`);
        return {
            success: true,
            qrImageUrl: qrData.qrImageUrl,
            qrId: qrData.qrId,
            expiresAt: qrData.expiresAt.toDate().toISOString()
        };
    }

    // Create new Razorpay QR code
    const rzp = razorpay;
    
    try {
        const qrCode = await (rzp as any).qrCodes.create({
            type: 'upi_qr',
            name: `${techData.name || 'Technician'}_Wallet`,
            usage: 'multiple_use', // Can be used multiple times
            fixed_amount: false, // Customer enters amount
            description: 'Payment to technician wallet',
            notes: {
                technicianId,
                technicianName: techData.name,
                paymentType: 'wallet_credit',
                platformFee: '10%'
            }
        });

        const expiresAt = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes

        // Store QR metadata
        await db.collection('technician_qr_codes').add({
            qrId: qrCode.id,
            technicianId,
            technicianName: techData.name,
            qrImageUrl: qrCode.image_url,
            status: 'active',
            paymentType: 'wallet_credit',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt)
        });

        console.log(`${LOG_PREFIX} QR created successfully - ID: ${qrCode.id}`);

        return {
            success: true,
            qrImageUrl: qrCode.image_url,
            qrId: qrCode.id,
            expiresAt: expiresAt.toISOString()
        };
    } catch (error: any) {
        console.error(`${LOG_PREFIX} QR generation failed:`, error);
        throw new functions.https.HttpsError('internal', `Failed to generate QR: ${error.message}`);
    }
});
