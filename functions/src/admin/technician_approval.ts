/**
 * Admin Technician Approval Function
 * Properly sets technician status and ensures profile completion is 100%
 */

import { onCall } from "firebase-functions/v2/https";
import { CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as https from "firebase-functions/v2/https";

const db = admin.firestore();

interface ApprovalRequest {
  technicianId: string;
  action: "approve" | "reject";
  rejectionReason?: string;
}

/**
 * Approve or Reject Technician
 * Sets proper status and profile completion
 */
export const approveTechnician = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 30 },
  async (request: CallableRequest<ApprovalRequest>) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    // TODO: Add admin role check here
    // const adminDoc = await db.collection('admins').doc(request.auth.uid).get();
    // if (!adminDoc.exists) {
    //   throw new https.HttpsError("permission-denied", "Admin access required");
    // }

    const { technicianId, action, rejectionReason } = request.data;

    if (!technicianId || !action) {
      throw new https.HttpsError("invalid-argument", "Technician ID and action are required");
    }

    const techRef = db.collection('technicians').doc(technicianId);
    const techDoc = await techRef.get();

    if (!techDoc.exists) {
      throw new https.HttpsError("not-found", "Technician not found");
    }

    const updateData: any = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (action === "approve") {
      // COMPLETE APPROVAL: Set all required fields for approved technician
      updateData.status = "approved";
      updateData.onboardingCompleted = true;
      updateData.profileCompletion = 100;
      updateData.profileApprovalRequested = true;
      updateData.profileRejected = false;
      updateData.stepsCompleted = {
        personalDetails: true,
        serviceCategories: true,
        portfolio: true,
        verification: true,
      };

      console.log(`[ADMIN APPROVAL] Fully approving technician ${technicianId} with all required fields`);
    } else if (action === "reject") {
      updateData.status = "rejected";
      updateData.profileRejected = true;
      if (rejectionReason) {
        updateData.rejectionReason = rejectionReason;
      }

      console.log(`[ADMIN APPROVAL] Rejecting technician ${technicianId}: ${rejectionReason || 'No reason provided'}`);
    }

    await techRef.update(updateData);

    return {
      success: true,
      technicianId,
      action,
      message: `Technician ${action}d successfully`,
    };
  }
);