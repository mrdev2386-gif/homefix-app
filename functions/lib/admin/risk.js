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
exports.manageRiskProfile = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("../shared/security");
const db = admin.firestore();
exports.manageRiskProfile = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    // Verify Admin via Claims
    await Promise.resolve().then(() => __importStar(require('./utils'))).then(m => m.assertAdmin(context));
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
                    metadata: { lastResetBy: context.auth.uid, reason: (0, security_1.sanitize)(reason) }
                }, { merge: true });
            }
            else if (action === 'update_status') {
                if (!newStatus)
                    throw new functions.https.HttpsError('invalid-argument', 'Missing newStatus');
                t.update(riskRef, {
                    status: newStatus,
                    lastEvaluatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    ['metadata.lastStatusChangeBy']: context.auth.uid
                });
            }
            // Log Activity
            const logRef = db.collection('activity_logs').doc();
            t.set(logRef, {
                actorType: 'admin',
                actorUid: context.auth.uid,
                action: `risk_${action}`,
                entityId,
                metadata: { reason: (0, security_1.sanitize)(reason), newStatus },
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        return { success: true };
    }
    catch (e) {
        console.error('Manage Risk Profile Error:', e);
        throw new functions.https.HttpsError('internal', e.message);
    }
}));
//# sourceMappingURL=risk.js.map