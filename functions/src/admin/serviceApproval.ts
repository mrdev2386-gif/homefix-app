/**
 * Admin Service Management Cloud Functions
 * 
 * Handles approval, rejection, and status management of technician services
 */

import * as functions from "firebase-functions";

import * as admin from "firebase-admin";


const db = admin.firestore();

/**
 * Approve a technician service
 * Changes status from 'pending' to 'active'
 */
export const approveService = functions.region('asia-south1').https.onCall(
    async (request, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError("unauthenticated", "Admin authentication required");
        }

        const { serviceId } = request.data;
        if (!serviceId) {
            throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
        }

        try {
            const serviceRef = db.collection('technician_services').doc(serviceId);
            const serviceDoc = await serviceRef.get();

            if (!serviceDoc.exists) {
                throw new functions.https.HttpsError("not-found", "Service not found");
            }

            const serviceData = serviceDoc.data()!;
            
            if (serviceData.status !== 'pending') {
                throw new functions.https.HttpsError("failed-precondition", 
                    `Service is not pending approval. Current status: ${serviceData.status}`);
            }

            await serviceRef.update({
                status: 'active',
                isPublished: true,
                technicianApproved: true,
                approvedAt: admin.firestore.Timestamp.now(),
                approvedBy: context.auth.uid,
                updatedAt: admin.firestore.Timestamp.now()
            });

            console.log(`Service ${serviceId} approved by admin ${context.auth.uid}`);

            return {
                success: true,
                message: 'Service approved successfully',
                serviceId,
                newStatus: 'active'
            };

        } catch (error: any) {
            console.error('Error approving service:', error);
            throw new functions.https.HttpsError("internal", error.message || "Failed to approve service");
        }
    }
);

/**
 * Reject a technician service
 * Changes status from 'pending' to 'rejected'
 */
export const rejectService = functions.region('asia-south1').https.onCall(
    async (request, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError("unauthenticated", "Admin authentication required");
        }

        const { serviceId, reason } = request.data;
        if (!serviceId) {
            throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
        }

        try {
            const serviceRef = db.collection('technician_services').doc(serviceId);
            const serviceDoc = await serviceRef.get();

            if (!serviceDoc.exists) {
                throw new functions.https.HttpsError("not-found", "Service not found");
            }

            const serviceData = serviceDoc.data()!;
            
            if (serviceData.status !== 'pending') {
                throw new functions.https.HttpsError("failed-precondition", 
                    `Service is not pending approval. Current status: ${serviceData.status}`);
            }

            await serviceRef.update({
                status: 'rejected',
                isPublished: false,
                technicianApproved: false,
                rejectedAt: admin.firestore.Timestamp.now(),
                rejectedBy: context.auth.uid,
                rejectionReason: reason || 'No reason provided',
                updatedAt: admin.firestore.Timestamp.now()
            });

            console.log(`Service ${serviceId} rejected by admin ${context.auth.uid}`);

            return {
                success: true,
                message: 'Service rejected',
                serviceId,
                newStatus: 'rejected'
            };

        } catch (error: any) {
            console.error('Error rejecting service:', error);
            throw new functions.https.HttpsError("internal", error.message || "Failed to reject service");
        }
    }
);

/**
 * Disable an active service
 * Changes status from 'active' to 'disabled'
 */
export const disableService = functions.region('asia-south1').https.onCall(
    async (request, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError("unauthenticated", "Admin authentication required");
        }

        const { serviceId, reason } = request.data;
        if (!serviceId) {
            throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
        }

        try {
            const serviceRef = db.collection('technician_services').doc(serviceId);
            const serviceDoc = await serviceRef.get();

            if (!serviceDoc.exists) {
                throw new functions.https.HttpsError("not-found", "Service not found");
            }

            await serviceRef.update({
                status: 'disabled',
                isPublished: false,
                disabledAt: admin.firestore.Timestamp.now(),
                disabledBy: context.auth.uid,
                disableReason: reason || 'Disabled by admin',
                updatedAt: admin.firestore.Timestamp.now()
            });

            console.log(`Service ${serviceId} disabled by admin ${context.auth.uid}`);

            return {
                success: true,
                message: 'Service disabled',
                serviceId,
                newStatus: 'disabled'
            };

        } catch (error: any) {
            console.error('Error disabling service:', error);
            throw new functions.https.HttpsError("internal", error.message || "Failed to disable service");
        }
    }
);
