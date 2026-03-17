import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { secureCallable, sanitize } from '../shared/security';

const db = admin.firestore();

async function assertAdmin(context: functions.https.CallableContext) {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
    if (!adminDoc.exists) throw new functions.https.HttpsError('permission-denied', 'Admin access required');
}

export const manageDispute = functions.https.onCall(
    secureCallable(async (data: any, context: any) => {
    await assertAdmin(context);
    const { disputeId, action, notes, amount } = data;
    if (!disputeId || !action) throw new functions.https.HttpsError('invalid-argument', 'Missing disputeId or action');

    const disputeRef = db.collection('disputes').doc(disputeId);
    const disputeDoc = await disputeRef.get();
    if (!disputeDoc.exists) throw new functions.https.HttpsError('not-found', 'Dispute not found');

    const dispute = disputeDoc.data()!;
    const updates: any = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        adminNotes: sanitize(notes) || dispute.adminNotes || ''
    };

    switch (action) {
        case 'investigating':
            updates.status = 'investigating';
            break;
        case 'resolve':
            updates.status = 'resolved';
            updates.resolvedAt = admin.firestore.FieldValue.serverTimestamp();
            updates.resolvedBy = context.auth!.uid;
            break;
        case 'reject':
            updates.status = 'rejected';
            updates.rejectedAt = admin.firestore.FieldValue.serverTimestamp();
            updates.rejectedBy = context.auth!.uid;
            break;
        case 'refund':
            if (!amount || amount <= 0) throw new functions.https.HttpsError('invalid-argument', 'Invalid refund amount');
            updates.status = 'resolved';
            updates.refundAmount = amount;
            updates.refundProcessedAt = admin.firestore.FieldValue.serverTimestamp();
            
            // Credit wallet
            if (dispute.customerId) {
                const customerRef = db.collection('customers').doc(dispute.customerId);
                await db.runTransaction(async (t) => {
                    const customerDoc = await t.get(customerRef);
                    const currentBalance = customerDoc.data()?.walletBalance || 0;
                    t.update(customerRef, { walletBalance: currentBalance + amount });
                    
                    t.set(customerRef.collection('wallet_transactions').doc(), {
                        type: 'credit',
                        amount,
                        reason: `Dispute refund: ${disputeId}`,
                        disputeId,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                });
            }
            break;
        default:
            throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
    }

    await disputeRef.update(updates);

    await db.collection('activity_logs').add({
        actorType: 'admin',
        actorUid: context.auth!.uid,
        action: `dispute_${action}`,
        entityId: disputeId,
        metadata: { notes, amount },
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { success: true };
    })
);
