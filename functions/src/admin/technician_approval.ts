/**
 * Admin Technician Approval Function
 * Properly sets technician status and ensures profile completion is 100%
 */

import * as functions from "firebase-functions";

import * as admin from "firebase-admin";
import { secureCallable, sanitize } from "../shared/security";


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
export const approveTechnician = functions.https.onCall(
  secureCallable(async (request: any, context: any) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }

    // Verify admin access
    if (!context.auth.token?.admin) {
      throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }

    const { technicianId, action, rejectionReason } = request.data;

    if (!technicianId || !action) {
      throw new functions.https.HttpsError("invalid-argument", "Technician ID and action are required");
    }

    const techRef = db.collection('technicians').doc(technicianId);
    const techDoc = await techRef.get();

    if (!techDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Technician not found");
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
        updateData.rejectionReason = sanitize(rejectionReason);
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
  })
);
