
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { db } from '../shared/config';
import { assertAdmin, logAdminAction } from '../shared/utils';
import * as notify from '../shared/notification_helper';

const LOG_PREFIX = '[PAYOUT_LOGIC]';

// Use functions.config() — consistent with all other payment functions
function getRazorpayConfig() {
    const config = functions.config();
    return {
        key_id: config.razorpay?.key_id || '',
        key_secret: config.razorpay?.key_secret || '',
        payout_account: config.razorpay?.payout_account || '',
    };
}

async function getRazorpay() {
    const { key_id, key_secret } = getRazorpayConfig();
    const Razorpay = (await import('razorpay')).default;
    return new Razorpay({ key_id, key_secret });
}

/**
 * Admin triggers manual payout for a technician
 */
export const triggerTechnicianPayout = functions.region('asia-south1').https.onCall(async (data: any, context: functions.https.CallableContext) => {
    await assertAdmin(context);
    const { technicianId, amount } = data;

    if (!technicianId || !amount || amount <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid technician ID or amount');
    }

    const techRef = db.collection('technicians').doc(technicianId);
    // FIX 3A: Use technician_wallets (single source of truth)
    const walletRef = db.collection('technician_wallets').doc(technicianId);

    const [techDoc, walletDoc] = await Promise.all([techRef.get(), walletRef.get()]);

    if (!techDoc.exists || !walletDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician or Wallet not found');
    }

    const wallet = walletDoc.data()!;
    if (wallet.availableBalance < amount) {
        throw new functions.https.HttpsError('failed-precondition', 'Insufficient available balance');
    }

    const payoutId = db.collection('payouts').doc().id;

    try {
        await db.collection('payouts').doc(payoutId).set({
            id: payoutId,
            technicianId,
            amount,
            status: 'initiated',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        const techData = techDoc.data()!;

        if (techData.bankVerified !== true || techData.bankVerificationStatus !== 'verified') {
            throw new Error('Technician bank account not verified');
        }
        if (!techData.fundAccountId) {
            throw new Error('Fund account ID missing. Bank verification incomplete.');
        }
        if (!techData.bankDetails) {
            throw new Error('Technician bank details missing');
        }

        const rzp = await getRazorpay();
        const { payout_account } = getRazorpayConfig();

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
            await techRef.update({ rzpContactId: contactId });
        }

        let fundAccountId = techData.fundAccountId || techData.rzpFundAccountId;
        if (!fundAccountId) {
            const fundAccount = await (rzp as any).fundAccounts.create({
                contact_id: contactId,
                account_type: 'bank_account',
                bank_account: {
                    name: techData.bankDetails.holderName || techData.name,
                    ifsc: techData.bankDetails.ifsc,
                    account_number: techData.bankDetails.accountNumber
                }
            });
            fundAccountId = fundAccount.id;
            await techRef.update({ rzpFundAccountId: fundAccountId });
        }

        const payout = await (rzp as any).payouts.create({
            account_number: payout_account,
            fund_account_id: fundAccountId,
            amount: Math.round(amount * 100),
            currency: 'INR',
            mode: 'IMPS',
            purpose: 'payout',
            queue_if_low_balance: true,
            reference_id: payoutId,
            notes: { technicianId, payoutId }
        });

        // FIX 3A: Deduct from technician_wallets (single source of truth)
        await db.runTransaction(async (t) => {
            t.update(db.collection('payouts').doc(payoutId), {
                razorpayPayoutId: payout.id,
                status: payout.status,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            t.update(walletRef, {
                availableBalance: admin.firestore.FieldValue.increment(-amount),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        await logAdminAction(context.auth!.uid, 'payout_initiated', technicianId, { amount, payoutId });

        return { success: true, payoutId, rzpPayoutId: payout.id };

    } catch (error: any) {
        console.error(`${LOG_PREFIX} Payout Error:`, error);
        await db.collection('payouts').doc(payoutId).update({
            status: 'failed',
            error: error.message,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        throw new functions.https.HttpsError('internal', error.message);
    }
});

/**
 * FIX 1: Razorpay Payout Webhook — SECURED with HMAC SHA256 signature verification
 * Previously had NO verification — now production-safe
 */
export const razorpayPayoutWebhook = functions.https.onRequest(async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }

    try {
        // STEP 1: Load webhook secret from functions.config()
        const config = functions.config();
        const webhookSecret = config.razorpay?.webhook_secret || '';

        if (!webhookSecret) {
            console.error(`${LOG_PREFIX} Webhook secret not configured`);
            res.status(500).send('Webhook secret not configured');
            return;
        }

        // STEP 2: Verify x-razorpay-signature header
        const signature = req.headers['x-razorpay-signature'] as string;
        if (!signature) {
            console.error(`${LOG_PREFIX} No signature in payout webhook request`);
            res.status(400).send('No signature provided');
            return;
        }

        // STEP 3: HMAC SHA256 — use raw body (same pattern as razorpayWebhookV2)
        const body = req.rawBody || JSON.stringify(req.body);
        const expectedSignature = crypto
            .createHmac('sha256', webhookSecret)
            .update(body)
            .digest('hex');

        if (signature !== expectedSignature) {
            console.error(`${LOG_PREFIX} Invalid payout webhook signature — REJECTED`);
            await db.collection('payment_logs').add({
                action: 'payout_webhook_invalid_signature',
                receivedSignature: signature.substring(0, 10) + '...',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            }).catch(() => {});
            res.status(400).send('Invalid signature');
            return;
        }

        console.log(`${LOG_PREFIX} Payout webhook signature verified`);

        // STEP 4: Defensive null safety
        const event = req.body?.event;
        const payoutEntity = req.body?.payload?.payout?.entity;

        if (!payoutEntity || !payoutEntity.reference_id) {
            console.warn(`${LOG_PREFIX} Missing payout entity or reference_id`);
            res.status(200).send('OK');
            return;
        }

        const payoutId = payoutEntity.reference_id;

        const payoutRef = db.collection('payouts').doc(payoutId);
        const payoutDoc = await payoutRef.get();

        if (!payoutDoc.exists) {
            console.warn(`${LOG_PREFIX} Payout not found: ${payoutId}`);
            // Return 200 to prevent Razorpay retry storms
            res.status(200).send('OK');
            return;
        }

        const pData = payoutDoc.data()!;
        const techId = pData.technicianId;

        // FIX 3A: Use technician_wallets (single source of truth)
        const walletRef = db.collection('technician_wallets').doc(techId);

        if (event === 'payout.processed') {
            // Idempotency: only update if not already success
            if (pData.status === 'success') {
                console.log(`${LOG_PREFIX} Duplicate payout.processed ignored: ${payoutId}`);
                res.status(200).send('OK');
                return;
            }

            await db.runTransaction(async (t) => {
                t.update(payoutRef, {
                    status: 'success',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                t.update(walletRef, {
                    lastPayoutAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            });

            await notify.notifyTechnicianPayoutProcessed(techId, pData.amount);

        } else if (event === 'payout.reversed' || event === 'payout.failed') {
            // Idempotency: only restore balance if not already failed
            if (pData.status === 'failed') {
                console.log(`${LOG_PREFIX} Duplicate payout failure ignored: ${payoutId}`);
                res.status(200).send('OK');
                return;
            }

            await db.runTransaction(async (t) => {
                t.update(payoutRef, {
                    status: 'failed',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                // FIX 3A: Restore balance in technician_wallets
                t.update(walletRef, {
                    availableBalance: admin.firestore.FieldValue.increment(pData.amount),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            });

            await notify.sendUserNotification({
                userId: techId,
                userType: 'technician',
                title: 'Payout Failed 🔴',
                body: `Your payout of ₹${pData.amount} failed. Balance has been restored.`,
                type: 'payout_processed',
                data: { screen: 'wallet' },
                priority: 'high'
            });
        } else {
            console.log(`${LOG_PREFIX} Unhandled payout event: ${event}`);
        }

        res.status(200).send('OK');

    } catch (error: any) {
        console.error(`${LOG_PREFIX} Payout webhook error:`, error);
        res.status(500).send('Internal Server Error');
    }
});

/**
 * Admin settles pending balance into available balance
 * FIX 3A: Uses technician_wallets (single source of truth)
 */
export const settleTechnicianBalance = functions.region('asia-south1').https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { technicianId } = data;

    // FIX 3A: Use technician_wallets
    const walletRef = db.collection('technician_wallets').doc(technicianId);
    const walletDoc = await walletRef.get();
    if (!walletDoc.exists) throw new functions.https.HttpsError('not-found', 'Wallet not found');

    const wallet = walletDoc.data()!;
    const pending = wallet.pendingBalance || 0;

    if (pending <= 0) return { success: true, message: 'No pending balance' };

    await db.runTransaction(async (t) => {
        t.update(walletRef, {
            availableBalance: admin.firestore.FieldValue.increment(pending),
            pendingBalance: 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    });

    await notify.sendUserNotification({
        userId: technicianId,
        userType: 'technician',
        title: 'Earnings Settled 💰',
        body: `₹${pending} from pending earnings have been moved to your available balance.`,
        type: 'payout_processed',
        data: { screen: 'wallet' }
    });

    return { success: true, settledAmount: pending };
});

/**
 * Internal helper: initiate Razorpay refund for a cancelled booking
 * Uses functions.config() for keys — consistent with all other payment functions
 * 
 * FIX 5: This is a legacy helper function. For new refund requests, use initiateRefund 
 * from razorpay.ts instead, which has better admin controls and idempotency.
 */
export async function initiateRefund(bookingId: string) {
    console.log(`${LOG_PREFIX} Initiating refund for booking: ${bookingId}`);
    const payments = await db.collection('payments')
        .where('bookingId', '==', bookingId)
        .where('status', '==', 'success')
        .get();

    if (payments.empty) {
        console.log(`${LOG_PREFIX} No successful payment found for booking ${bookingId}. Skipping refund.`);
        return;
    }

    const paymentDoc = payments.docs[0];
    const paymentData = paymentDoc.data();

    try {
        const rzp = await getRazorpay();
        const refund = await rzp.payments.refund(paymentData.razorpayPaymentId, {
            amount: Math.round(paymentData.amount * 100),
            notes: { bookingId, reason: 'Cancellation Refund' }
        });

        await paymentDoc.ref.update({
            status: 'refunded',
            razorpayRefundId: refund.id,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await db.collection('bookings').doc(bookingId).update({
            paymentStatus: 'refunded',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await notify.notifyCustomerBookingCancelled(
            paymentData.userId,
            bookingId,
            `A refund of ₹${paymentData.amount} has been initiated for your booking.`
        );
    } catch (e) {
        console.error(`${LOG_PREFIX} Razorpay Refund Error:`, e);
    }
}
