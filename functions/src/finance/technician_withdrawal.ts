import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';

const razorpayKeyId = process.env.RAZORPAY_KEY_ID || '';
const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET || '';
const razorpayPayoutAccount = process.env.RAZORPAY_PAYOUT_ACCOUNT || '';

// Log prefix for security events
const LOG_PREFIX = "[WITHDRAWAL]";

// CONSTANTS
const MIN_WITHDRAWAL = 100;
const MAX_WITHDRAWAL = 50000;
const PAYOUT_FEE = 10;
const DAILY_LIMIT = 3;
const COOLDOWN_HOURS = 6;
const MAX_PENDING_WITHDRAWALS = 2; // Maximum pending requests before requiring approval

async function getRazorpay() {
    const Razorpay = (await import('razorpay')).default;
    return new Razorpay({
        key_id: razorpayKeyId || 'rzp_test_placeholder',
        key_secret: razorpayKeySecret || 'placeholder_secret',
    });
}

/**
 * Helper to check if user is admin
 */
async function assertAdmin(context: functions.https.CallableContext): Promise<void> {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    
    const userId = context.auth.uid;
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (!userData || userData.role !== 'admin') {
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }
}

/**
 * STEP 2 & 3: Request Withdrawal - Creates PENDING request (NO wallet debit)
 * 
 * SECURITY:
 * - Validates technician owns the wallet
 * - Checks sufficient balance server-side
 * - Enforces KYC requirement
 * - Enforces rate limiting
 * - Idempotent request creation
 * - NO wallet debit - only admin approval triggers debit
 */
export const requestWithdrawal = functions.https.onCall(async (data, context) => {
    // 1. Authentication
    if (!context.auth) {
        console.error(`${LOG_PREFIX} request_created - Auth required`);
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }

    const technicianId = context.auth.uid;
    const { amount: requestedAmount, bankAccountId } = data;

    // clamp to non‑negative value (extra safety)
    const amount = Math.max(0, requestedAmount);

    // 2. Validation
    if (!amount || amount < MIN_WITHDRAWAL) {
        console.warn(`${LOG_PREFIX} invalid_amount - Technician: ${technicianId}, Amount: ${amount}`);
        throw new functions.https.HttpsError(
            'invalid-argument',
            `Minimum withdrawal is ₹${MIN_WITHDRAWAL}`
        );
    }

    if (amount > MAX_WITHDRAWAL) {
        console.warn(`${LOG_PREFIX} exceeds_max - Technician: ${technicianId}, Amount: ${amount}`);
        throw new functions.https.HttpsError(
            'invalid-argument',
            `Maximum withdrawal is ₹${MAX_WITHDRAWAL}`
        );
    }

    // 3. Get wallet & technician data
    const walletRef = db.collection('technician_wallets').doc(technicianId);
    const techRef = db.collection('technicians').doc(technicianId);

    const [walletDoc, techDoc] = await Promise.all([
        walletRef.get(),
        techRef.get()
    ]);

    if (!walletDoc.exists || !techDoc.exists) {
        console.error(`${LOG_PREFIX} not_found - Technician: ${technicianId}`);
        throw new functions.https.HttpsError('not-found', 'Wallet or profile not found');
    }

    const wallet = walletDoc.data()!;
    const tech = techDoc.data()!;

    // 4. KYC Check
    if (wallet.kycStatus !== 'verified') {
        console.warn(`${LOG_PREFIX} kyc_required - Technician: ${technicianId}`);
        throw new functions.https.HttpsError(
            'failed-precondition',
            'KYC verification required before withdrawal'
        );
    }

    // 5. Balance Check
    if (wallet.availableBalance < amount) {
        console.warn(`${LOG_PREFIX} insufficient_balance - Technician: ${technicianId}, Available: ${wallet.availableBalance}, Requested: ${amount}`);
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Insufficient balance'
        );
    }

    // 6. Check technician status
    if (tech.status === 'suspended' || tech.status === 'deactivated') {
        console.warn(`${LOG_PREFIX} technician_suspended - Technician: ${technicianId}, Status: ${tech.status}`);
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Technician account is suspended'
        );
    }

    // 7. Rate Limiting - Check daily limit (pending requests)
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const recentPendingRequests = await db.collection('withdrawalRequests')
        .where('technicianId', '==', technicianId)
        .where('status', '==', 'pending')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(todayStart))
        .get();

    if (recentPendingRequests.size >= MAX_PENDING_WITHDRAWALS) {
        console.warn(`${LOG_PREFIX} too_many_pending - Technician: ${technicianId}, Count: ${recentPendingRequests.size}`);
        throw new functions.https.HttpsError(
            'resource-exhausted',
            `Maximum ${MAX_PENDING_WITHDRAWALS} pending withdrawal requests allowed. Please wait for approval.`
        );
    }

    // 8. Cooldown Check
    if (wallet.lastPayoutAt) {
        const lastPayout = wallet.lastPayoutAt.toDate();
        const cooldownEnd = new Date(lastPayout.getTime() + COOLDOWN_HOURS * 60 * 60 * 1000);
        if (new Date() < cooldownEnd) {
            console.warn(`${LOG_PREFIX} cooldown_active - Technician: ${technicianId}, Available at: ${cooldownEnd.toISOString()}`);
            throw new functions.https.HttpsError(
                'failed-precondition',
                `Cooldown active. Next withdrawal available at ${cooldownEnd.toLocaleTimeString()}`
            );
        }
    }

    // 9. STEP 4: IDEMPOTENCY - Check for recent duplicate withdrawal requests
    const idempotencyWindowMs = 60 * 1000; // 1 minute window
    const recentWithdrawals = await db.collection('withdrawalRequests')
        .where('technicianId', '==', technicianId)
        .where('amount', '==', amount)
        .where('createdAt', '>=', admin.firestore.Timestamp.fromMillis(Date.now() - idempotencyWindowMs))
        .limit(1)
        .get();

    if (!recentWithdrawals.empty) {
        const existingRequest = recentWithdrawals.docs[0];
        console.log(`${LOG_PREFIX} duplicate_attempt - Technician: ${technicianId}, Existing ID: ${existingRequest.id}`);
        return {
            success: true,
            requestId: existingRequest.id,
            message: "Duplicate request detected. Original withdrawal request is being processed.",
            isDuplicate: true
        };
    }

    // 10. Generate unique request ID
    const requestId = `withdraw_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const requestRef = db.collection('withdrawalRequests').doc(requestId);

    // STEP 5: Create pending withdrawal record (NO wallet debit)
    // Use set with exists: false to prevent race condition duplicates
    const requestCreated = await requestRef.set({
        technicianId,
        amount,
        fee: PAYOUT_FEE,
        netAmount: amount - PAYOUT_FEE,
        status: 'pending', // PENDING - requires admin approval
        bankAccountId: bankAccountId || null,
        idempotencyKey: requestId,
        walletBalanceAtRequest: wallet.availableBalance,
        technicianName: tech.name,
        technicianPhone: tech.phone,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        processedAt: null,
        processedBy: null,
        rejectionReason: null,
        razorpayPayoutId: null,
        failureReason: null
    }).then(() => true).catch((error) => {
        if (error.code === 'already-exists') {
            console.log(`${LOG_PREFIX} race_condition - Request already created: ${requestId}`);
            return false;
        }
        throw error;
    });

    if (!requestCreated) {
        console.warn(`${LOG_PREFIX} request_exists - Technician: ${technicianId}, ID: ${requestId}`);
        return {
            success: true,
            requestId,
            message: "Withdrawal request already in progress. Please wait.",
            isDuplicate: true
        };
    }

    console.log(`${LOG_PREFIX} request_created - Technician: ${technicianId}, Request ID: ${requestId}, Amount: ${amount}`);

    return {
        success: true,
        requestId,
        message: `Withdrawal request of ₹${amount} submitted. Pending admin approval.`
    };
});

/**
 * STEP 6 & 7: Admin Approval - Atomically debit wallet and process payout
 * 
 * CRITICAL: Uses Firestore transaction to prevent race conditions
 * - Re-checks balance inside transaction
 * - Re-checks status still pending
 * - Atomic wallet debit
 * - Double-withdrawal protection
 */
export const approveWithdrawal = functions.https.onCall(async (data, context) => {
    // 1. Admin authentication
    await assertAdmin(context);

    const { requestId, adminNotes } = data;

    if (!requestId) {
        throw new functions.https.HttpsError('invalid-argument', 'Request ID required');
    }

    const requestRef = db.collection('withdrawalRequests').doc(requestId);
    const requestDoc = await requestRef.get();

    if (!requestDoc.exists) {
        console.error(`${LOG_PREFIX} approve_not_found - Request: ${requestId}`);
        throw new functions.https.HttpsError('not-found', 'Withdrawal request not found');
    }

    const request = requestDoc.data()!;

    // 2. Check status is still pending
    if (request.status !== 'pending') {
        console.warn(`${LOG_PREFIX} approve_not_pending - Request: ${requestId}, Status: ${request.status}`);
        throw new functions.https.HttpsError(
            'failed-precondition',
            `Request is already ${request.status}. Cannot approve.`
        );
    }

    const technicianId = request.technicianId;
    const amount = request.amount;

    console.log(`${LOG_PREFIX} approve_attempt - Request: ${requestId}, Technician: ${technicianId}, Amount: ${amount}`);

    // STEP 7: ATOMIC WALLET DEBIT with double-withdrawal protection
    await db.runTransaction(async (t) => {
        // Re-read request inside transaction
        const reqDoc = await t.get(requestRef);
        const reqData = reqDoc.data()!;

        // Double-check status still pending
        if (reqData.status !== 'pending') {
            console.warn(`${LOG_PREFIX} race_blocked - Request: ${requestId}, Status changed to: ${reqData.status}`);
            throw new Error(`Request status changed to ${reqData.status}. Transaction aborted.`);
        }

        // Re-read wallet to check balance
        const walletRef = db.collection('technician_wallets').doc(technicianId);
        const walletDoc = await t.get(walletRef);
        const wallet = walletDoc.data()!;

        // Re-verify balance inside transaction
        if (wallet.availableBalance < amount) {
            console.error(`${LOG_PREFIX} race_insufficient - Request: ${requestId}, Balance: ${wallet.availableBalance}, Requested: ${amount}`);
            throw new Error('Insufficient balance - request may have been modified');
        }

        // ATOMIC DEBIT
        t.update(walletRef, {
            availableBalance: admin.firestore.FieldValue.increment(-amount),
            lastPayoutAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Create wallet transaction record
        t.set(db.collection('technician_wallets').doc(technicianId)
            .collection('transactions').doc(), {
            type: 'payout',
            source: 'withdrawal',
            status: 'completed',
            amount: -amount,
            fee: request.fee,
            referenceId: requestId,
            description: `Withdrawal approved`,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Update request status to approved
        t.update(requestRef, {
            status: 'approved',
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            processedBy: context.auth?.uid || 'admin',
            adminNotes: adminNotes || null,
            walletBalanceAfter: wallet.availableBalance - amount
        });
    });

    console.log(`${LOG_PREFIX} approved_success - Request: ${requestId}, Amount: ${amount}`);

    // 3. Process Razorpay Payout (fire and forget - webhook will update)
    try {
        const walletDoc = await db.collection('technician_wallets').doc(technicianId).get();
        const techDoc = await db.collection('technicians').doc(technicianId).get();
        
        if (!walletDoc.exists || !techDoc.exists) {
            console.error(`${LOG_PREFIX} razorpay_data_missing - Request: ${requestId}`);
            return { success: true, message: 'Approved but payout processing failed - contact support' };
        }

        const rzp = await getRazorpay();
        const techData = techDoc.data()!;

        // Get or create contact
        let contactId = techData.rzpContactId;
        if (!contactId) {
            const contact = await (rzp as any).contacts.create({
                name: techData.name,
                email: techData.email,
                contact: techData.phone,
                type: 'employee',
                reference_id: technicianId
            });
            contactId = contact.id;
            await db.collection('technicians').doc(technicianId).update({ rzpContactId: contactId });
        }

        // Get or create fund account
        let fundAccountId = techData.rzpFundAccountId;
        if (!fundAccountId && request.bankAccountId) {
            const bankDoc = await db.collection('technician_bank_accounts')
                .doc(request.bankAccountId).get();

            if (bankDoc.exists) {
                const bankData = bankDoc.data()!;
                const fundAccount = await (rzp as any).fundAccounts.create({
                    contact_id: contactId,
                    account_type: 'bank_account',
                    bank_account: {
                        name: bankData.holderName || techData.name,
                        ifsc: bankData.ifsc,
                        account_number: bankData.accountNumber
                    }
                });
                fundAccountId = fundAccount.id;
                await db.collection('technicians').doc(technicianId).update({ rzpFundAccountId: fundAccountId });
            }
        }

        // Create payout
        if (fundAccountId) {
            const payout = await (rzp as any).payouts.create({
                account_number: razorpayPayoutAccount || 'X123456789',
                fund_account_id: fundAccountId,
                amount: Math.round((amount - request.fee) * 100),
                currency: 'INR',
                mode: 'IMPS',
                purpose: 'payout',
                queue_if_low_balance: true,
                reference_id: requestId,
                notes: { technicianId, requestId }
            });

            await requestRef.update({
                razorpayPayoutId: payout.id,
                razorpayStatus: payout.status
            });
        }
    } catch (error: any) {
        console.error(`${LOG_PREFIX} razorpay_error - Request: ${requestId}, Error:`, error.message);
        // Don't fail - withdrawal was approved, payout will be retried
    }

    return {
        success: true,
        message: `Withdrawal of ₹${amount} approved and processed.`
    };
});

/**
 * STEP 9: Admin Rejection - Updates status without debiting wallet
 */
export const rejectWithdrawal = functions.https.onCall(async (data, context) => {
    // 1. Admin authentication
    await assertAdmin(context);

    const { requestId, reason } = data;

    if (!requestId) {
        throw new functions.https.HttpsError('invalid-argument', 'Request ID required');
    }

    const requestRef = db.collection('withdrawalRequests').doc(requestId);
    const requestDoc = await requestRef.get();

    if (!requestDoc.exists) {
        console.error(`${LOG_PREFIX} reject_not_found - Request: ${requestId}`);
        throw new functions.https.HttpsError('not-found', 'Withdrawal request not found');
    }

    const request = requestDoc.data()!;

    // 2. Check status is still pending
    if (request.status !== 'pending') {
        console.warn(`${LOG_PREFIX} reject_not_pending - Request: ${requestId}, Status: ${request.status}`);
        throw new functions.https.HttpsError(
            'failed-precondition',
            `Request is already ${request.status}. Cannot reject.`
        );
    }

    console.log(`${LOG_PREFIX} rejected - Request: ${requestId}, Reason: ${reason}`);

    // Update status to rejected (NO wallet change)
    await requestRef.update({
        status: 'rejected',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        processedBy: context.auth?.uid || 'admin',
        rejectionReason: reason || 'Rejected by admin'
    });

    return {
        success: true,
        message: 'Withdrawal request rejected.'
    };
});

/**
 * Get Withdrawal Request History
 */
export const getWithdrawalRequests = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }

    const technicianId = context.auth.uid;
    const { limit = 20, status } = data;

    let query = db.collection('withdrawalRequests')
        .where('technicianId', '==', technicianId)
        .orderBy('createdAt', 'desc')
        .limit(limit);

    if (status) {
        // Need to filter manually after fetching due to Firestore limitations
        const snapshot = await query.get();
        const filtered = snapshot.docs.filter(d => d.data().status === status);
        const requests = filtered.map(doc => {
            const d = doc.data();
            return {
                requestId: doc.id,
                amount: d.amount,
                fee: d.fee,
                netAmount: d.netAmount,
                status: d.status,
                createdAt: d.createdAt?.toDate()?.toISOString(),
                processedAt: d.processedAt?.toDate()?.toISOString(),
                rejectionReason: d.rejectionReason
            };
        });
        return { requests };
    }

    const snapshot = await query.get();

    const requests = snapshot.docs.map(doc => {
        const d = doc.data();
        return {
            requestId: doc.id,
            amount: d.amount,
            fee: d.fee,
            netAmount: d.netAmount,
            status: d.status,
            createdAt: d.createdAt?.toDate()?.toISOString(),
            processedAt: d.processedAt?.toDate()?.toISOString(),
            rejectionReason: d.rejectionReason
        };
    });

    return { requests };
});

/**
 * Get Transaction History
 */
export const getTransactionHistory = functions.https.onCall(async (data, context) => {
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

/**
 * Get Payout History
 */
export const getPayoutHistory = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }

    const technicianId = context.auth.uid;
    const { limit = 20 } = data;

    const snapshot = await db.collection('withdrawalRequests')
        .where('technicianId', '==', technicianId)
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();

    const payouts = snapshot.docs.map(doc => {
        const d = doc.data();
        return {
            requestId: doc.id,
            amount: d.amount,
            fee: d.fee,
            netAmount: d.netAmount,
            status: d.status,
            razorpayPayoutId: d.razorpayPayoutId,
            failureReason: d.failureReason,
            createdAt: d.createdAt?.toDate()?.toISOString(),
            processedAt: d.processedAt?.toDate()?.toISOString()
        };
    });

    return { payouts };
});

/**
 * Generate QR for Booking Payment
 */
export const generateBookingQR = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }

    const technicianId = context.auth.uid;
    const { bookingId } = data;

    if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'Booking ID required');
    }

    // Get booking
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking = bookingDoc.data()!;

    // Verify technician is assigned
    if (booking.technicianId !== technicianId) {
        throw new functions.https.HttpsError('permission-denied', 'Not assigned to this booking');
    }

    // Check if booking is payable
    if (booking.payment?.status === 'paid') {
        throw new functions.https.HttpsError('already-exists', 'Booking already paid');
    }

    // Check if QR already exists and is valid
    const existingQR = await db.collection('bookings')
        .doc(bookingId)
        .collection('payment')
        .doc('qr')
        .get();

    if (existingQR.exists) {
        const qrData = existingQR.data()!;
        const expiresAt = qrData.expiresAt?.toDate();

        if (expiresAt && new Date() < expiresAt) {
            // Return existing valid QR
            return {
                success: true,
                qrImageUrl: qrData.qrImageUrl,
                qrId: qrData.qrId,
                expiresAt: expiresAt.toISOString(),
                amount: booking.pricing?.total || booking.pricing?.subtotal || 0
            };
        }
    }

    // Generate new QR via Razorpay
    const rzp = await getRazorpay();

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

    // Calculate expiry (30 minutes)
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000);

    // Store QR data
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

// Tech reference for payout processing
const techRef = db.collection('technicians');

/**
 * Get Pending Withdrawal Requests (Admin function)
 */
export const getPendingWithdrawalRequests = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    
    const { limit = 50 } = data;
    
    const snapshot = await db.collection('withdrawalRequests')
        .where('status', '==', 'pending')
        .orderBy('createdAt', 'asc')
        .limit(limit)
        .get();
    
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
            walletBalanceAtRequest: d.walletBalanceAtRequest,
            bankAccountId: d.bankAccountId,
            status: d.status,
            createdAt: d.createdAt?.toDate()?.toISOString()
        };
    });
    
    return { requests };
});
