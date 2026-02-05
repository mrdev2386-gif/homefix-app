import * as admin from 'firebase-admin';
import { sendPushNotification } from './notifications';

export type EntityType = 'customer' | 'technician';
export type RiskStatus = 'normal' | 'monitored' | 'restricted' | 'suspended';

export interface RiskProfile {
    entityId: string;
    entityType: EntityType;
    riskScore: number;
    flags: string[];
    status: RiskStatus;
    lastEvaluatedAt: admin.firestore.FieldValue;
    metadata?: any;
}

const SCORE_THRESHOLDS = {
    MONITORED: 21,
    RESTRICTED: 41,
    SUSPENDED: 71,
};

const RISK_INCREMENTS = {
    MINOR: 5,
    MEDIUM: 10,
    SEVERE: 20,
};

/**
 * Updates or creates a risk profile for a user or technician.
 * Also handles status transitions and notification triggers.
 */
export async function updateRiskProfile(
    entityId: string,
    entityType: EntityType,
    increment: number,
    flag: string,
    metadata?: any
) {
    const db = admin.firestore();
    const riskRef = db.collection('risk_profiles').doc(entityId);

    await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(riskRef);
        let currentScore = 0;
        let currentFlags: string[] = [];
        let currentStatus: RiskStatus = 'normal';

        if (doc.exists) {
            const data = doc.data() as RiskProfile;
            currentScore = data.riskScore || 0;
            currentFlags = data.flags || [];
            currentStatus = data.status || 'normal';
        }

        const newScore = Math.min(Math.max(currentScore + increment, 0), 100);
        if (flag && !currentFlags.includes(flag)) {
            currentFlags.push(flag);
        }

        // Determine New Status
        let newStatus: RiskStatus = 'normal';
        if (newScore >= SCORE_THRESHOLDS.SUSPENDED) newStatus = 'suspended';
        else if (newScore >= SCORE_THRESHOLDS.RESTRICTED) newStatus = 'restricted';
        else if (newScore >= SCORE_THRESHOLDS.MONITORED) newStatus = 'monitored';

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

async function handleStatusChangeNotification(uid: string, type: EntityType, status: RiskStatus) {
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
        await sendPushNotification(uid, userType, {
            title,
            body,
            data: { type: 'risk_update', status }
        });
    } catch (e) {
        console.error('Failed to send risk notification:', e);
    }
}

export { RISK_INCREMENTS, SCORE_THRESHOLDS };
