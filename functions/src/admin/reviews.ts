import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

async function assertAdmin(context: functions.https.CallableContext) {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
    if (!adminDoc.exists) throw new functions.https.HttpsError('permission-denied', 'Admin access required');
}

export const manageReview = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { reviewId, action, reason } = data;
    if (!reviewId || !action) throw new functions.https.HttpsError('invalid-argument', 'Missing reviewId or action');

    const reviewRef = db.collection('reviews').doc(reviewId);
    const reviewDoc = await reviewRef.get();
    if (!reviewDoc.exists) throw new functions.https.HttpsError('not-found', 'Review not found');

    const updates: any = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

    switch (action) {
        case 'hide':
            updates.isHidden = true;
            break;
        case 'unhide':
            updates.isHidden = false;
            break;
        case 'flag':
            updates.isFlagged = true;
            break;
        case 'unflag':
            updates.isFlagged = false;
            break;
        default:
            throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
    }

    await reviewRef.update(updates);

    await db.collection('activity_logs').add({
        actorType: 'admin',
        actorUid: context.auth!.uid,
        action: `review_${action}`,
        entityId: reviewId,
        metadata: { reason },
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { success: true };
});
