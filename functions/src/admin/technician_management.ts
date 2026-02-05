
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin } from '../shared/security';
import { sendPushNotification } from '../shared/notifications';

const db = admin.firestore();

export const approveKYC = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { technicianId, approved, reason } = data;

    if (!technicianId) {
        throw new functions.https.HttpsError('invalid-argument', 'Technician ID required');
    }

    const appRef = db.collection('technicianApplications').doc(technicianId);

    if (approved) {
        await appRef.update({
            'kyc.status': 'approved',
            'kyc.approvedBy': context.auth!.uid,
            'kyc.approvedAt': admin.firestore.FieldValue.serverTimestamp(),
            status: 'kyc_verified',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await sendPushNotification(technicianId, 'technicians', {
            title: 'KYC Approved',
            body: 'Your KYC documents have been verified. You can proceed to the next step.',
            data: { type: 'kyc_status', status: 'approved' }
        });
    } else {
        await appRef.update({
            'kyc.status': 'rejected',
            'kyc.rejectedBy': context.auth!.uid,
            'kyc.rejectedAt': admin.firestore.FieldValue.serverTimestamp(),
            'kyc.rejectionReason': reason || 'Documentation unclear',
            status: 'rejected', // Or back to draft? Design implies lifecycle.
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await sendPushNotification(technicianId, 'technicians', {
            title: 'KYC Rejected',
            body: `Your KYC was rejected: ${reason || 'Please re-upload documents.'}`,
            data: { type: 'kyc_status', status: 'rejected' }
        });
    }

    return { success: true };
});

export const approveTechnician = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { technicianId } = data;

    const appDoc = await db.collection('technicianApplications').doc(technicianId).get();
    if (!appDoc.exists || appDoc.data()!.status !== 'submitted') {
        throw new functions.https.HttpsError('failed-precondition', 'Application not in submitted state');
    }

    const batch = db.batch();
    const techRef = db.collection('technicians').doc(technicianId);
    const appRef = db.collection('technicianApplications').doc(technicianId);

    // Update Technician Status
    batch.update(techRef, {
        status: 'approved',
        isActive: true, // Auto-activate or let tech do it? Design: "approved + active".
        approvedBy: context.auth!.uid,
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update Application Status
    batch.update(appRef, {
        status: 'approved',
        approvedBy: context.auth!.uid,
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await batch.commit();

    await sendPushNotification(technicianId, 'technicians', {
        title: 'Welcome to HomeFix!',
        body: 'Your profile has been approved. You can now go online and accept bookings.',
        data: { type: 'profile_status', status: 'approved' }
    });

    return { success: true };
});

export const suspendTechnician = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { technicianId, reason } = data;

    await db.collection('technicians').doc(technicianId).update({
        status: 'suspended',
        isActive: false,
        isOnline: false, // Force offline
        suspensionReason: reason,
        suspendedBy: context.auth!.uid,
        suspendedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Kill any active sessions? Firebase Auth revocation is separate.

    return { success: true };
});
