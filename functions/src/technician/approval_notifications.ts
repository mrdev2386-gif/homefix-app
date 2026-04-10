import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendPushNotification } from '../shared/notifications';

const db = admin.firestore();

/**
 * Sends approval notification to technician when admin approves their profile
 * Triggered when technician status changes to "approved" or "active"
 * 
 * BACKWARD COMPATIBLE: Handles both status values:
 * - status: 'approved' (from Cloud Function approveTechnician)
 * - status: 'active' (from Admin Panel direct Firestore write)
 * - profileApproved: true (fallback for edge cases)
 */
export const onTechnicianApproved = functions.firestore
    .document('technicians/{techId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (!before || !after) return;

        const techId = context.params.techId;

        // STEP 1: Check if status changed to approved (handles BOTH 'approved' and 'active')
        const wasApproved = 
            before.status === 'approved' || 
            before.status === 'active' ||
            before.profileApproved === true;
        
        const isNowApproved = 
            after.status === 'approved' || 
            after.status === 'active' ||
            after.profileApproved === true;

        // STEP 2: Only send notification on transition from not-approved to approved
        if (!wasApproved && isNowApproved) {
            console.log(`[TECH_APPROVAL_NOTIFICATION] Technician ${techId} approved. Status: ${after.status}, profileApproved: ${after.profileApproved}`);

            try {
                const techName = after.fullName || 'Technician';

                // STEP 3: Send FCM notification
                await sendPushNotification(techId, 'technicians', {
                    title: '✅ Profile Approved!',
                    body: `Congratulations ${techName}! Your profile has been approved. You can now create and list services.`,
                    data: {
                        type: 'technician_approved',
                        screen: 'dashboard',
                    },
                });

                console.log(`[TECH_APPROVAL_NOTIFICATION] ✅ Notification sent to ${techId}`);
            } catch (error) {
                console.error(`[TECH_APPROVAL_NOTIFICATION] ❌ Failed to send notification to ${techId}:`, error);
                // Don't fail the function - notification is best-effort
            }
        }
    });
