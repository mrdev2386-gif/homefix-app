import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendPushNotification } from '../shared/notifications';

const db = admin.firestore();

/**
 * Triggered when a new custom service request is created.
 * Sends alerts to all active and approved technicians in the customer's district
 * who are interested in the request's category.
 */
export const onCustomRequestCreatedAlertTechnicians = functions.firestore
    .document('service_requests/{requestId}')
    .onCreate(async (snapshot, context) => {
        const requestData = snapshot.data();
        if (!requestData) return;

        const districtNormalized = requestData.districtNormalized || (requestData.district ? requestData.district.toString().trim().toLowerCase() : '');
        const categoryId = requestData.categoryId;
        const categoryName = requestData.categoryName || '';
        const description = requestData.description || '';

        if (!districtNormalized || !categoryId) {
            console.log(`[TECH_ALERT] Missing district (${districtNormalized}) or categoryId (${categoryId}) for request ${context.params.requestId}`);
            return;
        }

        console.log(`[TECH_ALERT] Processing alerts for request ${context.params.requestId} in district: ${districtNormalized}, category: ${categoryId}`);

        // 1. Find eligible technicians
        // - Active status
        // - Approved
        // - Same district (using normalized field)
        // - Handles the category
        const techniciansSnapshot = await db.collection('technicians')
            .where('districtNormalized', '==', districtNormalized)
            .where('status', '==', 'active')
            .where('isApproved', '==', true)
            .where('serviceCategories', 'array-contains', categoryId)
            .get();

        if (techniciansSnapshot.empty) {
            console.log(`[TECH_ALERT] No eligible technicians found in ${districtNormalized} for category ${categoryId}`);
            // Optional: alert admins that no tech is available
            return;
        }

        console.log(`[TECH_ALERT] Found ${techniciansSnapshot.size} eligible technicians. Sending notifications...`);

        const notificationPromises = techniciansSnapshot.docs.map(async (techDoc) => {
            const techId = techDoc.id;
            const techData = techDoc.data();

            // Create notification document in technician's notifications subcollection
            const notificationId = db.collection('technicians').doc(techId).collection('notifications').doc().id;
            const notificationRef = db.collection('technicians').doc(techId).collection('notifications').doc(notificationId);

            const notificationDoc = {
                id: notificationId,
                title: 'New Service Request Nearby!',
                body: `A new ${categoryName || 'service'} request is available in ${districtNormalized.toUpperCase()}.`,
                type: 'custom_request_alert',
                requestId: context.params.requestId,
                categoryId,
                description: description || '',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                priority: 'high'
            };

            await notificationRef.set(notificationDoc);

            // Send FCM push notification
            await sendPushNotification(techId, 'technicians', {
                title: notificationDoc.title,
                body: notificationDoc.body,
                data: {
                    type: 'custom_request_alert',
                    requestId: context.params.requestId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK'
                }
            });
        });

        await Promise.all(notificationPromises);
        console.log(`[TECH_ALERT] Alerts sent successfully for request ${context.params.requestId}`);
    });
