
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';

// Environment variables for Razorpay configuration
const razorpayKeyId = process.env.RAZORPAY_KEY_ID || '';
const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET || '';
const razorpayPayoutAccount = process.env.RAZORPAY_PAYOUT_ACCOUNT || '';

// Helper for lazy loading Razorpay
async function getRazorpay() {
    const Razorpay = (await import('razorpay')).default;
    return new Razorpay({
        key_id: razorpayKeyId || 'rzp_test_placeholder',
        key_secret: razorpayKeySecret || 'placeholder_secret',
    });
}
import { assertAdmin, logAdminAction } from '../admin/utils';
import { sendPushNotification } from '../shared/notifications';

/**
 * Admin triggers manual payout for a technician
 */
export const triggerTechnicianPayout = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    await assertAdmin(context);
    const { technicianId, amount } = data;

    if (!technicianId || !amount || amount <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid technician ID or amount');
    }

    const techRef = db.collection('technicians').doc(technicianId);
    const walletRef = techRef.collection('wallet').doc('main');
    const techDoc = await techRef.get();
    const walletDoc = await walletRef.get();

    if (!techDoc.exists || !walletDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician or Wallet not found');
    }

    const wallet = walletDoc.data()!;
    if (wallet.availableBalance < amount) {
        throw new functions.https.HttpsError('failed-precondition', 'Insufficient available balance');
    }

    const payoutId = db.collection('payouts').doc().id;

    try {
        // 1. Create Payout record in 'initiated' status
        await db.collection('payouts').doc(payoutId).set({
            id: payoutId,
            technicianId,
            amount,
            status: 'initiated',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 2. Razorpay Payout Integration
        const techData = techDoc.data()!;
        if (!techData.bankDetails) {
            throw new Error('Technician bank details missing');
        }

        const rzp = await getRazorpay();

        // Create Contact (if not exists)
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

        // Create Fund Account (if not exists)
        let fundAccountId = techData.rzpFundAccountId;
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

        // Trigger Payout
        const payout = await (rzp as any).payouts.create({
            account_number: razorpayPayoutAccount || 'X123456789',
            fund_account_id: fundAccountId,
            amount: Math.round(amount * 100),
            currency: 'INR',
            mode: 'IMPS',
            purpose: 'payout',
            queue_if_low_balance: true,
            reference_id: payoutId,
            notes: { technicianId, payoutId }
        });

        // 3. Update Firestore with Razorpay Payout ID
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
        console.error('Payout Error:', error);
        await db.collection('payouts').doc(payoutId).update({
            status: 'failed',
            error: error.message,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        throw new functions.https.HttpsError('internal', error.message);
    }
});

/**
 * Handle Razorpay Webhooks for Payout status updates
 */
export const razorpayPayoutWebhook = functions.https.onRequest(async (req, res) => {
    // Note: Secret verification should be done here in production
    const event = req.body.event;
    const payout = req.body.payload.payout.entity;
    const payoutId = payout.reference_id;

    console.log(`Received Razorpay Payout Webhook: ${event} for payout ${payoutId}`);

    const payoutRef = db.collection('payouts').doc(payoutId);
    const payoutDoc = await payoutRef.get();
    if (!payoutDoc.exists) {
        res.status(404).send('Payout not found');
        return;
    }

    const pData = payoutDoc.data()!;
    const techId = pData.technicianId;
    const techRef = db.collection('technicians').doc(techId);
    const walletRef = techRef.collection('wallet').doc('main');

    if (event === 'payout.processed') {
        await db.runTransaction(async (t) => {
            t.update(payoutRef, {
                status: 'success',
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            t.update(walletRef, {
                lastPayoutAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        await sendPushNotification(techId, 'technicians', {
            title: 'Payout Successful',
            body: `Your payout of ₹${pData.amount} was successful.`,
            data: { type: 'payout', status: 'success' }
        });

    } else if (event === 'payout.reversed' || event === 'payout.failed') {
        await db.runTransaction(async (t) => {
            t.update(payoutRef, {
                status: 'failed',
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            t.update(walletRef, {
                availableBalance: admin.firestore.FieldValue.increment(pData.amount),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        await sendPushNotification(techId, 'technicians', {
            title: 'Payout Failed',
            body: `Your payout of ₹${pData.amount} failed and balance has been rolled back.`,
            data: { type: 'payout', status: 'failed' }
        });
    }

    res.json({ status: 'ok' });
});

/**
 * Admin settles pending balance into available balance
 */
export const settleTechnicianBalance = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { technicianId } = data;

    const walletRef = db.collection('technicians').doc(technicianId).collection('wallet').doc('main');
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

    await sendPushNotification(technicianId, 'technicians', {
        title: 'Earnings Settled',
        body: `₹${pending} from pending earnings have been moved to your available balance.`,
        data: { type: 'wallet', status: 'settled' }
    });

    return { success: true, settledAmount: pending };
});

export async function initiateRefund(bookingId: string) {
    console.log(`Initiating refund for booking: ${bookingId}`);
    const payments = await db.collection('payments')
        .where('bookingId', '==', bookingId)
        .where('status', '==', 'success')
        .get();

    if (payments.empty) {
        console.log(`No successful payment found for booking ${bookingId}. Skipping refund.`);
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

        // Notify Customer
        await sendPushNotification(paymentData.userId, 'customers', {
            title: 'Refund Initiated',
            body: `A refund of ₹${paymentData.amount} has been initiated for your booking.`,
            data: { type: 'payment', referenceId: bookingId }
        });
    } catch (e) {
        console.error('Razorpay Refund Error:', e);
    }
}
