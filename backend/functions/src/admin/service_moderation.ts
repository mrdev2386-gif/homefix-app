import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface ServiceModerationData {
  serviceId: string;
}

// Verify admin role
function verifyAdminRole(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  if (!context.auth.token?.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
}

// Create audit log
async function createAuditLog(
  adminId: string,
  action: string,
  serviceId: string
): Promise<void> {
  await db.collection('admin_audit_logs').add({
    adminId,
    action,
    serviceId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// Approve Service
export const approveService = functions.https.onCall(
  async (data: ServiceModerationData, context) => {
    verifyAdminRole(context);
    
    const { serviceId } = data;
    
    if (!serviceId) {
      throw new functions.https.HttpsError('invalid-argument', 'Service ID is required');
    }

    try {
      await db.runTransaction(async (transaction) => {
        const serviceRef = db.collection('technician_services').doc(serviceId);
        const serviceDoc = await transaction.get(serviceRef);
        
        if (!serviceDoc.exists) {
          throw new functions.https.HttpsError('not-found', 'Service not found');
        }

        transaction.update(serviceRef, {
          status: 'active',
          approvedAt: admin.firestore.FieldValue.serverTimestamp(),
          approvedBy: context.auth!.uid,
        });
      });

      await createAuditLog(context.auth!.uid, 'approve_service', serviceId);
      
      return { success: true, message: 'Service approved successfully' };
    } catch (error) {
      console.error('Error approving service:', error);
      throw new functions.https.HttpsError('internal', 'Failed to approve service');
    }
  }
);

// Reject Service
export const rejectService = functions.https.onCall(
  async (data: ServiceModerationData, context) => {
    verifyAdminRole(context);
    
    const { serviceId } = data;
    
    if (!serviceId) {
      throw new functions.https.HttpsError('invalid-argument', 'Service ID is required');
    }

    try {
      await db.runTransaction(async (transaction) => {
        const serviceRef = db.collection('technician_services').doc(serviceId);
        const serviceDoc = await transaction.get(serviceRef);
        
        if (!serviceDoc.exists) {
          throw new functions.https.HttpsError('not-found', 'Service not found');
        }

        transaction.update(serviceRef, {
          status: 'rejected',
          rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
          rejectedBy: context.auth!.uid,
        });
      });

      await createAuditLog(context.auth!.uid, 'reject_service', serviceId);
      
      return { success: true, message: 'Service rejected successfully' };
    } catch (error) {
      console.error('Error rejecting service:', error);
      throw new functions.https.HttpsError('internal', 'Failed to reject service');
    }
  }
);

// Disable Service
export const disableService = functions.https.onCall(
  async (data: ServiceModerationData, context) => {
    verifyAdminRole(context);
    
    const { serviceId } = data;
    
    if (!serviceId) {
      throw new functions.https.HttpsError('invalid-argument', 'Service ID is required');
    }

    try {
      await db.runTransaction(async (transaction) => {
        const serviceRef = db.collection('technician_services').doc(serviceId);
        const serviceDoc = await transaction.get(serviceRef);
        
        if (!serviceDoc.exists) {
          throw new functions.https.HttpsError('not-found', 'Service not found');
        }

        transaction.update(serviceRef, {
          status: 'disabled',
          disabledAt: admin.firestore.FieldValue.serverTimestamp(),
          disabledBy: context.auth!.uid,
        });
      });

      await createAuditLog(context.auth!.uid, 'disable_service', serviceId);
      
      return { success: true, message: 'Service disabled successfully' };
    } catch (error) {
      console.error('Error disabling service:', error);
      throw new functions.https.HttpsError('internal', 'Failed to disable service');
    }
  }
);