
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin } from '../shared/security';
import { sendPushNotification } from '../shared/notifications';

const db = admin.firestore();

export const approveKYC = functions.region('asia-south1').https.onCall(async (data, context) => {
    // DEPRECATED: This function is no longer used
    // Use approveTechnician() instead for all approval operations
    console.error('[DEPRECATED] approveKYC() called - use approveTechnician() instead');
    throw new functions.https.HttpsError(
        'failed-precondition',
        'DEPRECATED: Use approveTechnician() instead'
    );
});

export const approveTechnician = functions.region('asia-south1').https.onCall(async (data, context) => {
    try {
        console.log('[ADMIN APPROVAL] Raw incoming data:', JSON.stringify(data));
        console.log('[ADMIN APPROVAL] Context auth:', context.auth?.uid);
        
        await assertAdmin(context);
        
        // Handle both techId and technicianId parameter names
        const technicianId = data?.techId || data?.technicianId;
        const approve = data?.approve !== undefined ? data.approve : true;
        const reason = data?.reason;
        
        console.log('[ADMIN APPROVAL] Extracted values:', {
            technicianId,
            approve,
            reason,
            originalData: data
        });
        
        if (!technicianId || technicianId.trim() === '') {
            console.error('[ADMIN APPROVAL] Invalid technicianId:', technicianId);
            throw new functions.https.HttpsError('invalid-argument', 'Missing or empty technician ID (techId or technicianId)');
        }

        console.log('[ADMIN APPROVAL] Processing for technicianId:', technicianId, 'approve:', approve);

        const techRef = db.collection('technicians').doc(technicianId);
        const techDoc = await techRef.get();
        
        if (!techDoc.exists) {
            console.error('[ADMIN APPROVAL] Technician not found:', technicianId);
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        }

        if (approve) {
            // APPROVE: Set ALL required fields for technician activation
            await techRef.update({
                // Primary approval flags
                isApproved: true,              // Required by technician app
                adminApproved: true,           // Required by technician app
                isVerified: true,              // Legacy compatibility
                
                // Status fields
                status: 'approved',            // Main status
                kycStatus: 'approved',         // KYC-specific status
                
                // Activation
                isActive: true,                // Allow going online
                
                // Metadata
                approvedAt: admin.firestore.FieldValue.serverTimestamp(),
                approvedBy: context.auth!.uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                
                // Clear rejection fields
                rejectionReason: admin.firestore.FieldValue.delete(),
                suspensionReason: admin.firestore.FieldValue.delete()
            });

            console.log('[ADMIN APPROVAL] ✅ Technician approved and activated:', technicianId);

            await sendPushNotification(technicianId, 'technicians', {
                title: 'Welcome to HomeFix!',
                body: 'Your profile has been approved. You can now go online and accept bookings.',
                data: { type: 'profile_status', status: 'approved' }
            });
        } else {
            // REJECT/SUSPEND: Clear approval flags
            await techRef.update({
                status: 'suspended',
                isApproved: false,
                adminApproved: false,
                isVerified: false,
                isActive: false,
                isOnline: false,               // Force offline
                kycStatus: 'rejected',
                rejectionReason: reason || 'Not specified',
                rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
                rejectedBy: context.auth!.uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            console.log('[ADMIN APPROVAL] ❌ Technician suspended:', technicianId);

            await sendPushNotification(technicianId, 'technicians', {
                title: 'Profile Status Update',
                body: reason || 'Your profile has been suspended. Contact support for details.',
                data: { type: 'profile_status', status: 'suspended' }
            });
        }

        return { success: true };
    } catch (error: any) {
        console.error('[ADMIN APPROVAL ❌] Full error details:', {
            message: error?.message,
            stack: error?.stack,
            data: error?.data,
            code: error?.code
        });
        
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        
        throw new functions.https.HttpsError(
            'internal',
            error?.message || 'Approval failed'
        );
    }
});

export const suspendTechnician = functions.region('asia-south1').https.onCall(async (data, context) => {
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
