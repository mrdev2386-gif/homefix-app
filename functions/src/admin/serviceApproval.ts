/**
 * Admin Service Management Cloud Functions
 * 
 * Handles approval, rejection, and status management of technician services
 */

import { onCall } from "firebase-functions/v2/https";
import { CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as https from "firebase-functions/v2/https";

const db = admin.firestore();

/**
 * Approve a technician service
 * Changes status from 'pending' to 'active'
 */
export const approveService = onCall(
    {
        region: "us-central1",
        cpu: 1,
        memory: "256MiB",
        timeoutSeconds: 30,
        maxInstances: 5
    },
    async (request: CallableRequest<{ serviceId: string }>) => {
        if (!request.auth) {
            throw new https.HttpsError("unauthenticated", "Admin authentication required");
        }

        const { serviceId } = request.data;
        if (!serviceId) {
            throw new https.HttpsError("invalid-argument", "Service ID is required");
        }

        try {
            const serviceRef = db.collection('technician_services').doc(serviceId);
            const serviceDoc = await serviceRef.get();

            if (!serviceDoc.exists) {
                throw new https.HttpsError("not-found", "Service not found");
            }

            const serviceData = serviceDoc.data()!;
            
            if (serviceData.status !== 'pending') {
                throw new https.HttpsError("failed-precondition", 
                    `Service is not pending approval. Current status: ${serviceData.status}`);
            }

            await serviceRef.update({
                status: 'active',
                isPublished: true,
                technicianApproved: true,
                approvedAt: admin.firestore.Timestamp.now(),
                approvedBy: request.auth.uid,
                updatedAt: admin.firestore.Timestamp.now()
            });

            console.log(`Service ${serviceId} approved by admin ${request.auth.uid}`);

            return {
                success: true,
                message: 'Service approved successfully',
                serviceId,
                newStatus: 'active'
            };

        } catch (error: any) {
            console.error('Error approving service:', error);
            throw new https.HttpsError("internal", error.message || "Failed to approve service");
        }
    }
);

/**
 * Reject a technician service
 * Changes status from 'pending' to 'rejected'
 */
export const rejectService = onCall(
    {
        region: "us-central1",
        cpu: 1,
        memory: "256MiB",
        timeoutSeconds: 30,
        maxInstances: 5
    },
    async (request: CallableRequest<{ serviceId: string; reason?: string }>) => {
        if (!request.auth) {
            throw new https.HttpsError("unauthenticated", "Admin authentication required");
        }

        const { serviceId, reason } = request.data;
        if (!serviceId) {
            throw new https.HttpsError("invalid-argument", "Service ID is required");
        }

        try {
            const serviceRef = db.collection('technician_services').doc(serviceId);
            const serviceDoc = await serviceRef.get();

            if (!serviceDoc.exists) {
                throw new https.HttpsError("not-found", "Service not found");
            }

            const serviceData = serviceDoc.data()!;
            
            if (serviceData.status !== 'pending') {
                throw new https.HttpsError("failed-precondition", 
                    `Service is not pending approval. Current status: ${serviceData.status}`);
            }

            await serviceRef.update({
                status: 'rejected',
                isPublished: false,
                technicianApproved: false,
                rejectedAt: admin.firestore.Timestamp.now(),
                rejectedBy: request.auth.uid,
                rejectionReason: reason || 'No reason provided',
                updatedAt: admin.firestore.Timestamp.now()
            });

            console.log(`Service ${serviceId} rejected by admin ${request.auth.uid}`);

            return {
                success: true,
                message: 'Service rejected',
                serviceId,
                newStatus: 'rejected'
            };

        } catch (error: any) {
            console.error('Error rejecting service:', error);
            throw new https.HttpsError("internal", error.message || "Failed to reject service");
        }
    }
);

/**
 * Disable an active service
 * Changes status from 'active' to 'disabled'
 */
export const disableService = onCall(
    {
        region: "us-central1",
        cpu: 1,
        memory: "256MiB",
        timeoutSeconds: 30,
        maxInstances: 5
    },
    async (request: CallableRequest<{ serviceId: string; reason?: string }>) => {
        if (!request.auth) {
            throw new https.HttpsError("unauthenticated", "Admin authentication required");
        }

        const { serviceId, reason } = request.data;
        if (!serviceId) {
            throw new https.HttpsError("invalid-argument", "Service ID is required");
        }

        try {
            const serviceRef = db.collection('technician_services').doc(serviceId);
            const serviceDoc = await serviceRef.get();

            if (!serviceDoc.exists) {
                throw new https.HttpsError("not-found", "Service not found");
            }

            await serviceRef.update({
                status: 'disabled',
                isPublished: false,
                disabledAt: admin.firestore.Timestamp.now(),
                disabledBy: request.auth.uid,
                disableReason: reason || 'Disabled by admin',
                updatedAt: admin.firestore.Timestamp.now()
            });

            console.log(`Service ${serviceId} disabled by admin ${request.auth.uid}`);

            return {
                success: true,
                message: 'Service disabled',
                serviceId,
                newStatus: 'disabled'
            };

        } catch (error: any) {
            console.error('Error disabling service:', error);
            throw new https.HttpsError("internal", error.message || "Failed to disable service");
        }
    }
);