
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { verifyAdmin } from '../shared/security_audit';
import { assertAuthenticated } from '../shared/security';

const db = admin.firestore();

export const bindDevice = functions.region('asia-south1').https.onCall(async (data, context) => {
    assertAuthenticated(context);
    const uid = context.auth!.uid;
    const { deviceId, deviceInfo } = data;

    if (!deviceId) {
        throw new functions.https.HttpsError('invalid-argument', 'Device ID required');
    }

    const techRef = db.collection('technicians').doc(uid);
    const techDoc = await techRef.get();

    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }

    const techData = techDoc.data()!;

    // If deviceId already set and different, require admin approval (or re-login flow)
    if (techData.deviceId && techData.deviceId !== deviceId) {
        console.warn(`Device change attempt for ${uid}. Old: ${techData.deviceId}, New: ${deviceId}`);

        // Logic: Allow change if > 30 days? Or require admin?
        // For high security: Block and ask to contact support.
        // For UX: Maybe allow with OTP? (Not implemented here)

        // We will log a change request
        await db.collection('device_change_requests').add({
            technicianId: uid,
            oldDeviceId: techData.deviceId,
            newDeviceId: deviceId,
            newDeviceInfo: deviceInfo,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'pending'
        });

        throw new functions.https.HttpsError('permission-denied', 'New device detected. Please contact support to authorize this device.');
    }

    // Bind ID
    await techRef.update({
        deviceId,
        deviceInfo,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { success: true };
});
