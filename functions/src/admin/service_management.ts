/**
 * Admin Service Management - Production Ready
 * 
 * ARCHITECTURE:
 * - Single Source of Truth: technician_services/{serviceId}
 * - ALL writes via Cloud Functions (no direct Firestore writes)
 * - Status-based moderation: pending -> approved/rejected/disabled
 * - Admin Panel queries top-level collection
 * - Customer App shows only approved services
 */

import { onCall } from "firebase-functions/v2/https";
import { CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as https from "firebase-functions/v2/https";

const db = admin.firestore();

/**
 * SECURITY: Verify admin role from Firestore
 */
async function verifyAdmin(uid: string): Promise<void> {
  const adminDoc = await db.collection('admins').doc(uid).get();
  if (!adminDoc.exists) {
    throw new https.HttpsError("permission-denied", "Admin access required");
  }
}

/**
 * Log admin action for audit trail
 * STEP 5: ADMIN AUDIT LOGS
 */
async function logAdminAction(
  adminId: string,
  action: string,
  serviceId: string,
  additionalData?: any
) {
  try {
    await db.collection('admin_logs').add({
      adminId,
      action,
      serviceId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      ...additionalData
    });
    console.log(`[ADMIN_AUDIT] Logged action: ${action} by ${adminId} on service ${serviceId}`);
  } catch (error) {
    console.error('[ADMIN_AUDIT] Failed to log action:', error);
    // Don't throw - audit logging failure shouldn't block the main action
  }
}

/**
 * Approve Technician Service
 * Changes status from pending to approved
 */
export const admin_approveService = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 30 },
  async (request: CallableRequest<{ serviceId: string; status?: string }>) => {
    // Authentication check
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    // CRITICAL FIX: Verify admin role from Firestore
    await verifyAdmin(request.auth.uid);

    const { serviceId } = request.data;
    if (!serviceId) {
      throw new https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
    }

    await serviceRef.update({
      status: 'approved',
      isActive: true, // CRITICAL: Activate service on approval
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      approvedBy: request.auth.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // STEP 5: Log admin action
    await logAdminAction(request.auth.uid, 'approve_service', serviceId, {
      previousStatus: serviceDoc.data()?.status,
      newStatus: 'approved'
    });

    console.log(`[ADMIN] Service ${serviceId} approved by ${request.auth.uid}`);

    return {
      success: true,
      serviceId,
      status: 'approved',
      message: 'Service approved successfully'
    };
  }
);

/**
 * Reject Technician Service
 * Changes status from pending to rejected
 */
export const admin_rejectService = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 30 },
  async (request: CallableRequest<{ serviceId: string; status?: string; reason?: string }>) => {
    // Authentication check
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    // CRITICAL FIX: Verify admin role from Firestore
    await verifyAdmin(request.auth.uid);

    const { serviceId, reason } = request.data;
    if (!serviceId) {
      throw new https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
    }

    await serviceRef.update({
      status: 'rejected',
      isActive: false, // CRITICAL: Keep inactive on rejection
      rejectionReason: reason || 'Not specified',
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      rejectedBy: request.auth.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // STEP 5: Log admin action
    await logAdminAction(request.auth.uid, 'reject_service', serviceId, {
      previousStatus: serviceDoc.data()?.status,
      newStatus: 'rejected',
      reason: reason || 'Not specified'
    });

    console.log(`[ADMIN] Service ${serviceId} rejected by ${request.auth.uid}`);

    return {
      success: true,
      serviceId,
      status: 'rejected',
      message: 'Service rejected'
    };
  }
);

/**
 * Disable Technician Service
 * Changes status to disabled (SOFT DELETE - never removes document)
 */
export const admin_disableService = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 30 },
  async (request: CallableRequest<{ serviceId: string; status?: string }>) => {
    // Authentication check
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    // CRITICAL FIX: Verify admin role from Firestore
    await verifyAdmin(request.auth.uid);

    const { serviceId } = request.data;
    if (!serviceId) {
      throw new https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
    }

    // SOFT DELETE: Set status to disabled, never delete document
    await serviceRef.update({
      status: 'disabled',
      disabledAt: admin.firestore.FieldValue.serverTimestamp(),
      disabledBy: request.auth.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // STEP 5: Log admin action
    await logAdminAction(request.auth.uid, 'disable_service', serviceId, {
      previousStatus: serviceDoc.data()?.status,
      newStatus: 'disabled'
    });

    console.log(`[ADMIN] Service ${serviceId} disabled by ${request.auth.uid}`);

    return {
      success: true,
      serviceId,
      status: 'disabled',
      message: 'Service disabled'
    };
  }
);