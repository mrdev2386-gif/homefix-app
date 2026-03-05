/**
 * Admin Service Approval Functions
 * 
 * Callable functions for admin to approve/reject technician services
 * Only admins can call these functions
 */

import { onCall } from "firebase-functions/v2/https";
import { CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as https from "firebase-functions/v2/https";

const db = admin.firestore();

/**
 * Check if user is admin
 */
async function isAdmin(uid: string): Promise<boolean> {
  try {
    const adminDoc = await db.collection('admins').doc(uid).get();
    return adminDoc.exists;
  } catch (error) {
    console.error('[ADMIN_SERVICE] Error checking admin status:', error);
    return false;
  }
}

/**
 * Approve Technician Service
 * Sets service to active and visible to customers
 */
export const approveTechnicianService = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 30 },
  async (request: CallableRequest<{ serviceId: string; technicianId: string }>) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    // Check if user is admin
    const adminStatus = await isAdmin(request.auth.uid);
    if (!adminStatus) {
      throw new https.HttpsError("permission-denied", "Admin access required");
    }

    const { serviceId, technicianId } = request.data;

    if (!serviceId || !technicianId) {
      throw new https.HttpsError("invalid-argument", "Service ID and Technician ID required");
    }

    try {
      const serviceRef = db.doc(`technicians/${technicianId}/technician_services/${serviceId}`);
      const serviceDoc = await serviceRef.get();

      if (!serviceDoc.exists) {
        throw new https.HttpsError("not-found", "Service not found");
      }

      // Update service to approved state
      await serviceRef.update({
        isPublished: true,
        technicianApproved: true,
        status: 'active',
        updatedAt: admin.firestore.Timestamp.now(),
        approvedAt: admin.firestore.Timestamp.now(),
        approvedBy: request.auth.uid,
      });

      console.log(`[ADMIN_SERVICE] Service ${serviceId} approved by ${request.auth.uid}`);

      return {
        success: true,
        message: 'Service approved successfully',
      };
    } catch (error) {
      console.error('[ADMIN_SERVICE] Error approving service:', error);
      throw new https.HttpsError("internal", "Failed to approve service");
    }
  }
);

/**
 * Reject Technician Service
 * Marks service as rejected
 */
export const rejectTechnicianService = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 30 },
  async (request: CallableRequest<{ serviceId: string; technicianId: string; reason?: string }>) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    // Check if user is admin
    const adminStatus = await isAdmin(request.auth.uid);
    if (!adminStatus) {
      throw new https.HttpsError("permission-denied", "Admin access required");
    }

    const { serviceId, technicianId, reason } = request.data;

    if (!serviceId || !technicianId) {
      throw new https.HttpsError("invalid-argument", "Service ID and Technician ID required");
    }

    try {
      const serviceRef = db.doc(`technicians/${technicianId}/technician_services/${serviceId}`);
      const serviceDoc = await serviceRef.get();

      if (!serviceDoc.exists) {
        throw new https.HttpsError("not-found", "Service not found");
      }

      // Update service to rejected state
      await serviceRef.update({
        isPublished: false,
        status: 'rejected',
        updatedAt: admin.firestore.Timestamp.now(),
        rejectedAt: admin.firestore.Timestamp.now(),
        rejectedBy: request.auth.uid,
        rejectionReason: reason || null,
      });

      console.log(`[ADMIN_SERVICE] Service ${serviceId} rejected by ${request.auth.uid}`);

      return {
        success: true,
        message: 'Service rejected successfully',
      };
    } catch (error) {
      console.error('[ADMIN_SERVICE] Error rejecting service:', error);
      throw new https.HttpsError("internal", "Failed to reject service");
    }
  }
);

/**
 * Get Pending Services for Admin Review
 * Returns all services pending admin approval
 */
export const getPendingServices = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 30 },
  async (request: CallableRequest) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    // Check if user is admin
    const adminStatus = await isAdmin(request.auth.uid);
    if (!adminStatus) {
      throw new https.HttpsError("permission-denied", "Admin access required");
    }

    try {
      const snapshot = await db
        .collectionGroup('technician_services')
        .where('status', '==', 'pending_admin_approval')
        .orderBy('createdAt', 'desc')
        .get();

      const services = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate?.()?.toISOString(),
          updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
        };
      });

      console.log(`[ADMIN_SERVICE] Retrieved ${services.length} pending services`);

      return {
        success: true,
        services: services,
        count: services.length,
      };
    } catch (error) {
      console.error('[ADMIN_SERVICE] Error fetching pending services:', error);
      throw new https.HttpsError("internal", "Failed to fetch pending services");
    }
  }
);
