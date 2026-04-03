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

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { secureCallable, sanitize } from "../shared/security";

const db = admin.firestore();

/**
 * SECURITY: Verify admin role from Firestore
 */
async function verifyAdmin(uid: string): Promise<void> {
  const adminDoc = await db.collection('admins').doc(uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError("permission-denied", "Admin access required");
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
export const admin_approveService = functions.region('asia-south1').https.onCall(
  secureCallable(async (request: any, context: any) => {
    // Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }

    // CRITICAL FIX: Verify admin role from Firestore
    await verifyAdmin(context.auth.uid);

    const { serviceId } = request;
    if (!serviceId) {
      throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Service not found");
    }

    await serviceRef.update({
      status: 'approved',
      isActive: true, // CRITICAL: Activate service on approval
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      approvedBy: context.auth.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // STEP 5: Log admin action
    await logAdminAction(context.auth.uid, 'approve_service', serviceId, {
      previousStatus: serviceDoc.data()?.status,
      newStatus: 'approved'
    });

    console.log(`[ADMIN] Service ${serviceId} approved by ${context.auth.uid}`);

    return {
      success: true,
      serviceId,
      status: 'approved',
      message: 'Service approved successfully'
    };
  })
);

/**
 * Reject Technician Service
 * Changes status from pending to rejected
 */
export const admin_rejectService = functions.region('asia-south1').https.onCall(
  secureCallable(async (request: any, context: any) => {
    // Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }

    // CRITICAL FIX: Verify admin role from Firestore
    await verifyAdmin(context.auth.uid);

    const { serviceId, reason } = request;
    if (!serviceId) {
      throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Service not found");
    }

    await serviceRef.update({
      status: 'rejected',
      isActive: false, // CRITICAL: Keep inactive on rejection
      rejectionReason: sanitize(reason) || 'Not specified',
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      rejectedBy: context.auth.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // STEP 5: Log admin action
    await logAdminAction(context.auth.uid, 'reject_service', serviceId, {
      previousStatus: serviceDoc.data()?.status,
      newStatus: 'rejected',
      reason: sanitize(reason) || 'Not specified'
    });

    console.log(`[ADMIN] Service ${serviceId} rejected by ${context.auth.uid}`);

    return {
      success: true,
      serviceId,
      status: 'rejected',
      message: 'Service rejected'
    };
  })
);

/**
 * Disable Technician Service
 * Changes status to disabled (SOFT DELETE - never removes document)
 */
export const admin_disableService = functions.region('asia-south1').https.onCall(
  secureCallable(async (request: any, context: any) => {
    // Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }

    // CRITICAL FIX: Verify admin role from Firestore
    await verifyAdmin(context.auth.uid);

    const { serviceId } = request;
    if (!serviceId) {
      throw new functions.https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Service not found");
    }

    // SOFT DELETE: Set status to disabled, never delete document
    await serviceRef.update({
      status: 'disabled',
      disabledAt: admin.firestore.FieldValue.serverTimestamp(),
      disabledBy: context.auth.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // STEP 5: Log admin action
    await logAdminAction(context.auth.uid, 'disable_service', serviceId, {
      previousStatus: serviceDoc.data()?.status,
      newStatus: 'disabled'
    });

    console.log(`[ADMIN] Service ${serviceId} disabled by ${context.auth.uid}`);

    return {
      success: true,
      serviceId,
      status: 'disabled',
      message: 'Service disabled'
    };
  })
);
