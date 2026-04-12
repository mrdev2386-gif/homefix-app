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
exports.manageDispute = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("../shared/security");
const db = admin.firestore();
async function assertAdmin(context) {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
    if (!adminDoc.exists)
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
}
exports.manageDispute = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    await assertAdmin(context);
    const { disputeId, action, notes, amount } = data;
    if (!disputeId || !action)
        throw new functions.https.HttpsError('invalid-argument', 'Missing disputeId or action');
    const disputeRef = db.collection('disputes').doc(disputeId);
    const disputeDoc = await disputeRef.get();
    if (!disputeDoc.exists)
        throw new functions.https.HttpsError('not-found', 'Dispute not found');
    const dispute = disputeDoc.data();
    const updates = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        adminNotes: (0, security_1.sanitize)(notes) || dispute.adminNotes || ''
    };
    switch (action) {
        case 'investigating':
            updates.status = 'investigating';
            break;
        case 'resolve':
            updates.status = 'resolved';
            updates.resolvedAt = admin.firestore.FieldValue.serverTimestamp();
            updates.resolvedBy = context.auth.uid;
            break;
        case 'reject':
            updates.status = 'rejected';
            updates.rejectedAt = admin.firestore.FieldValue.serverTimestamp();
            updates.rejectedBy = context.auth.uid;
            break;
        case 'refund':
            if (!amount || amount <= 0)
                throw new functions.https.HttpsError('invalid-argument', 'Invalid refund amount');
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
        actorUid: context.auth.uid,
        action: `dispute_${action}`,
        entityId: disputeId,
        metadata: { notes, amount },
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return { success: true };
}));
//# sourceMappingURL=disputes.js.map