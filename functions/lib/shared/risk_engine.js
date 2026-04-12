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
exports.SCORE_THRESHOLDS = exports.RISK_INCREMENTS = void 0;
exports.updateRiskProfile = updateRiskProfile;
const admin = __importStar(require("firebase-admin"));
const notifications_1 = require("./notifications");
const SCORE_THRESHOLDS = {
    MONITORED: 21,
    RESTRICTED: 41,
    SUSPENDED: 71,
};
exports.SCORE_THRESHOLDS = SCORE_THRESHOLDS;
const RISK_INCREMENTS = {
    MINOR: 5,
    MEDIUM: 10,
    SEVERE: 20,
};
exports.RISK_INCREMENTS = RISK_INCREMENTS;
/**
 * Updates or creates a risk profile for a user or technician.
 * Also handles status transitions and notification triggers.
 */
async function updateRiskProfile(entityId, entityType, increment, flag, metadata) {
    const db = admin.firestore();
    const riskRef = db.collection('risk_profiles').doc(entityId);
    await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(riskRef);
        let currentScore = 0;
        let currentFlags = [];
        let currentStatus = 'normal';
        if (doc.exists) {
            const data = doc.data();
            currentScore = data.riskScore || 0;
            currentFlags = data.flags || [];
            currentStatus = data.status || 'normal';
        }
        const newScore = Math.min(Math.max(currentScore + increment, 0), 100);
        if (flag && !currentFlags.includes(flag)) {
            currentFlags.push(flag);
        }
        // Determine New Status
        let newStatus = 'normal';
        if (newScore >= SCORE_THRESHOLDS.SUSPENDED)
            newStatus = 'suspended';
        else if (newScore >= SCORE_THRESHOLDS.RESTRICTED)
            newStatus = 'restricted';
        else if (newScore >= SCORE_THRESHOLDS.MONITORED)
            newStatus = 'monitored';
        const profileUpdate = {
            entityId,
            entityType,
            riskScore: newScore,
            flags: currentFlags,
            status: newStatus,
            lastEvaluatedAt: admin.firestore.FieldValue.serverTimestamp(),
            ...(metadata ? { [`metadata.${flag}`]: metadata } : {})
        };
        transaction.set(riskRef, profileUpdate, { merge: true });
        // Activity Log for Audit
        const logRef = db.collection('activity_logs').doc();
        transaction.set(logRef, {
            actorType: 'system',
            actorUid: 'risk_engine',
            action: 'risk_evaluation',
            entityId,
            entityType,
            prevScore: currentScore,
            newScore,
            addedFlag: flag,
            statusChanged: currentStatus !== newStatus,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Notifications on Status Change
        if (currentStatus !== newStatus) {
            await handleStatusChangeNotification(entityId, entityType, newStatus);
        }
    });
}
async function handleStatusChangeNotification(uid, type, status) {
    const userType = type === 'customer' ? 'customers' : 'technicians';
    let title = '';
    let body = '';
    switch (status) {
        case 'monitored':
            title = 'Account Security Notice';
            body = 'We noticed some unusual activity. Your account is under routine monitoring to ensure platform safety.';
            break;
        case 'restricted':
            title = 'Account Restricted';
            body = 'Some features have been temporarily restricted due to policy violations. Please contact support if you believe this is an error.';
            break;
        case 'suspended':
            title = 'Account Suspended';
            body = 'Your account has been suspended for violating platform trust standards. Access to bookings is currently disabled.';
            break;
        default:
            return;
    }
    try {
        await (0, notifications_1.sendPushNotification)(uid, userType, {
            title,
            body,
            data: { type: 'risk_update', status }
        });
    }
    catch (e) {
        console.error('Failed to send risk notification:', e);
    }
}
//# sourceMappingURL=risk_engine.js.map