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
exports.manageReview = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
async function assertAdmin(context) {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
    if (!adminDoc.exists)
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
}
exports.manageReview = functions.region('asia-south1').https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { reviewId, action, reason } = data;
    if (!reviewId || !action)
        throw new functions.https.HttpsError('invalid-argument', 'Missing reviewId or action');
    const reviewRef = db.collection('reviews').doc(reviewId);
    const reviewDoc = await reviewRef.get();
    if (!reviewDoc.exists)
        throw new functions.https.HttpsError('not-found', 'Review not found');
    const updates = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
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
        actorUid: context.auth.uid,
        action: `review_${action}`,
        entityId: reviewId,
        metadata: { reason },
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return { success: true };
});
//# sourceMappingURL=reviews.js.map