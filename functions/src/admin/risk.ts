
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const manageRiskProfile = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    // Verify Admin via Claims
    await import('./utils').then(m => m.assertAdmin(context));

    const { entityId, action, reason, newStatus } = data;

    if (!entityId || !action) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing entityId or action');
    }

    const riskRef = db.collection('risk_profiles').doc(entityId);

    try {
        await db.runTransaction(async (t) => {
            const doc = await t.get(riskRef);
            if (!doc.exists && action !== 'reset') {
                throw new functions.https.HttpsError('not-found', 'Risk profile not found');
            }

            if (action === 'reset') {
                t.set(riskRef, {
                    riskScore: 0,
                    status: 'normal',
                    flags: [],
                    lastEvaluatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    metadata: { lastResetBy: context.auth!.uid, reason }
                }, { merge: true });
            } else if (action === 'update_status') {
                if (!newStatus) throw new functions.https.HttpsError('invalid-argument', 'Missing newStatus');
                t.update(riskRef, {
                    status: newStatus,
                    lastEvaluatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    ['metadata.lastStatusChangeBy']: context.auth!.uid
                });
            }

            // Log Activity
            const logRef = db.collection('activity_logs').doc();
            t.set(logRef, {
                actorType: 'admin',
                actorUid: context.auth!.uid,
                action: `risk_${action}`,
                entityId,
                metadata: { reason, newStatus },
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        return { success: true };
    } catch (e: any) {
        console.error('Manage Risk Profile Error:', e);
        throw new functions.https.HttpsError('internal', e.message);
    }
});
