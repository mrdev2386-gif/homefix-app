import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { checkRateLimit } from './shared/utils';
import { secureCallable, sanitize } from './shared/security';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// ==========================================
// HELPERS
// ==========================================

async function isAdmin(uid: string): Promise<boolean> {
  const adminDoc = await db.collection('admins').doc(uid).get();
  return adminDoc.exists;
}

async function sendNotification(
  userId: string,
  userType: 'customer' | 'technician' | 'admin',
  title: string,
  body: string,
  data: Record<string, string> = {}
) {
  try {
    if (userId === 'admin') {
      const admins = await db.collection('admins').get();
      for (const adminDoc of admins.docs) {
        await sendNotification(adminDoc.id, 'admin', title, body, data);
      }
      return;
    }

    const tokensSnapshot = await db.collection(userType === 'technician' ? 'technicians' : 'customers')
      .doc(userId)
      .collection('fcmTokens')
      .where('isActive', '==', true)
      .get();

    if (tokensSnapshot.empty) return;

    const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
    const messages = tokens.map(token => ({
      token,
      notification: { title, body },
      data,
    }));

    for (let i = 0; i < messages.length; i += 500) {
      const chunk = messages.slice(i, i + 500);
      await admin.messaging().sendEachForMulticast({ tokens: chunk.map(m => m.token), notification: chunk[0].notification, data: chunk[0].data });
    }
  } catch (error) {
    console.error(`[Notification Error] ${userId}:`, error);
  }
}

// ==========================================
// 1. CREATE CUSTOM SERVICE REQUEST
// ==========================================

interface CreateCustomRequestData {
  categoryId: string;
  subCategoryId: string;
  description: string;
  preferredDate?: string;
  addressId: string;
  images?: string[]; // Max 3
  idempotencyKey: string;
}

export const createCustomServiceRequest = functions.region('asia-south1').https.onCall(
  secureCallable(async (data: CreateCustomRequestData, context: functions.https.CallableContext) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');

  const customerId = context.auth.uid;
  const { categoryId, subCategoryId, description, preferredDate, addressId, images, idempotencyKey } = data;

  // 0. RATE LIMITING (Harden)
  await checkRateLimit(customerId, 'create_custom_request', 3, 120);

  // 1. Role verification
  const customerDoc = await db.collection('customers').doc(customerId).get();
  if (!customerDoc.exists) throw new functions.https.HttpsError('not-found', 'Customer profile not found');
  const customerData = customerDoc.data()!;

  // 2. Fetch District from profile
  const district = customerData.district;
  if (!district) throw new functions.https.HttpsError('failed-precondition', 'District not found in profile. Please update profile.');

  // 3. Validation
  if (!categoryId || !subCategoryId || !addressId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }
  if (subCategoryId === 'custom_sub_service' && (!description || description.trim().length < 10)) {
    throw new functions.https.HttpsError('invalid-argument', 'Description required for custom service (min 10 chars)');
  }

  // 4. Address Snapshot
  const addressDoc = await db.collection('customers').doc(customerId).collection('addresses').doc(addressId).get();
  if (!addressDoc.exists) throw new functions.https.HttpsError('not-found', 'Address not found');
  const addressSnapshot = addressDoc.data();

  // 5. Idempotency & Transaction
  const requestId = db.collection('service_requests').doc().id;
  const idempotencyId = `custom_${customerId}_${idempotencyKey}`;

  return await db.runTransaction(async (transaction) => {
    const idempotencyRef = db.collection('request_idempotency').doc(idempotencyId);
    const idempotencyDoc = await transaction.get(idempotencyRef);

    if (idempotencyDoc.exists) {
      return { success: true, requestId: idempotencyDoc.data()!.requestId, message: 'Existing request retrieved' };
    }

    const requestData = {
      id: requestId,
      customerId,
      customerName: customerData.name || 'Customer',
      customerPhone: customerData.phone || '',
      district: district || '',
      districtNormalized: district ? district.toString().trim().toLowerCase() : '',
      categoryId,
      subCategoryId,
      description: description || '',
      preferredDate: preferredDate || null,
      addressId,
      addressSnapshot,
      images: images || [],
      status: 'pending_admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    transaction.set(db.collection('service_requests').doc(requestId), requestData);
    transaction.set(idempotencyRef, { requestId, createdAt: admin.firestore.FieldValue.serverTimestamp() });

    return { success: true, requestId, message: 'Custom request submitted for admin review' };
  }).then(async (result) => {
    // Notify Admin
    await sendNotification('admin', 'admin', 'New Custom Request', `A new custom request from ${district} requires review.`);
    return result;
  });
})
);

// ==========================================
// 2. ADMIN APPROVE SERVICE REQUEST
// ==========================================

interface AdminApproveData {
  requestId: string;
  action: 'approve' | 'reject';
  technicianId?: string; // Required for approve
  rejectionReason?: string;
}

export const adminApproveServiceRequest = functions.region('asia-south1').https.onCall(
  secureCallable(async (data: AdminApproveData, context: functions.https.CallableContext) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Unauthenticated');
  if (!(await isAdmin(context.auth.uid))) throw new functions.https.HttpsError('permission-denied', 'Admin access required');

  const { requestId, action, technicianId, rejectionReason } = data;

  const requestRef = db.collection('service_requests').doc(requestId);
  const requestDoc = await requestRef.get();
  if (!requestDoc.exists) throw new functions.https.HttpsError('not-found', 'Request not found');
  const request = requestDoc.data()!;

  if (request.status !== 'pending_admin' && request.status !== 'technician_rejected') {
    throw new functions.https.HttpsError('failed-precondition', 'Request is not in a status that allows approval');
  }

  if (action === 'approve') {
    if (!technicianId) throw new functions.https.HttpsError('invalid-argument', 'Technician ID required for approval');

    const techDoc = await db.collection('technicians').doc(technicianId).get();
    if (!techDoc.exists) throw new functions.https.HttpsError('not-found', 'Technician not found');
    const techData = techDoc.data()!;

    // STRICT FILTER: Match district, approved status, and category
    if (techData.district !== request.district) {
      throw new functions.https.HttpsError('failed-precondition', 'Technician must be in the same district');
    }
    if (techData.status !== 'approved' && techData.status !== 'active') {
      throw new functions.https.HttpsError('failed-precondition', 'Technician is not approved');
    }

    // serviceCategories is usually an array of category IDs
    const categories = techData.serviceCategories || [];
    if (!categories.includes(request.categoryId)) {
      throw new functions.https.HttpsError('failed-precondition', 'Technician does not handle this category');
    }

    await requestRef.update({
      status: 'technician_pending',
      technicianId,
      technicianName: techData.name || 'Technician',
      technicianPhone: techData.phone || '',
      adminApprovedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await sendNotification(technicianId, 'technician', 'New Job Assigned', 'You have a new custom request to review.');
    return { success: true, message: 'Request approved and assigned to technician' };
  } else {
    await requestRef.update({
      status: 'admin_rejected',
      rejectionReason: sanitize(rejectionReason) || 'Rejected by admin',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await sendNotification(request.customerId, 'customer', 'Request Update', 'Your custom request was not approved by admin.');
    return { success: true, message: 'Request rejected' };
  }
  })
);

// ==========================================
// 3. TECHNICIAN RESPOND SERVICE REQUEST
// ==========================================

interface TechnicianRespondData {
  requestId: string;
  action: 'accept' | 'reject';
  rejectionReason?: string;
}

export const technicianRespondServiceRequest = functions.region('asia-south1').https.onCall(
  secureCallable(async (data: TechnicianRespondData, context: functions.https.CallableContext) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Unauthenticated');
  const technicianId = context.auth.uid;
  const { requestId, action, rejectionReason } = data;

  const requestRef = db.collection('service_requests').doc(requestId);
  const requestDoc = await requestRef.get();
  if (!requestDoc.exists) throw new functions.https.HttpsError('not-found', 'Request not found');
  const request = requestDoc.data()!;

  if (request.technicianId !== technicianId) throw new functions.https.HttpsError('permission-denied', 'Unauthorized');
  if (request.status !== 'technician_pending') throw new functions.https.HttpsError('failed-precondition', 'Request not in technician_pending status');

  if (action === 'accept') {
    await requestRef.update({
      status: 'awaiting_payment',
      technicianAcceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await sendNotification(request.customerId, 'customer', 'Technician Accepted!', 'Your custom request was accepted. Please proceed to payment.');
    return { success: true, message: 'Request accepted' };
  } else {
    await requestRef.update({
      status: 'technician_rejected',
      rejectionReason: sanitize(rejectionReason) || 'Technician declined',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await sendNotification('admin', 'admin', 'Technician Rejected Request', `Technician rejected the request for ${request.district}.`);
    return { success: true, message: 'Request rejected' };
  }
  })
);

// ==========================================
// 4. CUSTOMER CONFIRM SERVICE PAYMENT
// ==========================================

interface CustomerPaymentData {
  requestId: string;
  paymentMethod: 'now' | 'after_service';
}

export const customerConfirmServicePayment = functions.region('asia-south1').https.onCall(
  secureCallable(async (data: CustomerPaymentData, context: functions.https.CallableContext) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Unauthenticated');
  const customerId = context.auth.uid;
  const { requestId, paymentMethod } = data;

  const requestRef = db.collection('service_requests').doc(requestId);
  const requestDoc = await requestRef.get();
  if (!requestDoc.exists) throw new functions.https.HttpsError('not-found', 'Request not found');
  const request = requestDoc.data()!;

  if (request.customerId !== customerId) throw new functions.https.HttpsError('permission-denied', 'Unauthorized');

  if (request.status === 'confirmed') {
    return { success: true, message: 'Booking already confirmed' };
  }

  if (request.status !== 'awaiting_payment') {
    throw new functions.https.HttpsError('failed-precondition', 'Request is not in awaiting_payment status');
  }

  if (request.paymentStatus === 'paid' && paymentMethod === 'now') {
    return { success: true, message: 'Payment already processed' };
  }

  await requestRef.update({
    status: 'confirmed',
    paymentMethod,
    paymentStatus: paymentMethod === 'now' ? 'paid' : 'pending',
    confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await sendNotification(request.technicianId, 'technician', 'Booking Confirmed!', 'The customer has confirmed the booking. You can start the job.');
  return { success: true, message: 'Booking confirmed' };
})
);

/**
 * Technician: Get inbox of assigned custom requests
 */
export const getTechnicianInbox = functions.region('asia-south1').https.onCall(
  secureCallable(async (data: { limit?: number; startAfter?: string }, context: functions.https.CallableContext) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Unauthenticated');
  const technicianId = context.auth.uid;
  const limit = data.limit || 20;

  let query = db.collection('service_requests')
    .where('technicianId', '==', technicianId)
    .where('status', '==', 'technician_pending')
    .orderBy('createdAt', 'desc')
    .limit(limit);

  if (data.startAfter) {
    const startDoc = await db.collection('service_requests').doc(data.startAfter).get();
    if (startDoc.exists) {
      query = query.startAfter(startDoc);
    }
  }

  const snapshot = await query.get();
  const requests = snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));

  return { success: true, requests };
})
);

/**
 * Get details of a single custom request
 */
export const getCustomRequestDetail = functions.region('asia-south1').https.onCall(
  secureCallable(async (data: { requestId: string }, context: functions.https.CallableContext) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Unauthenticated');
  const uid = context.auth.uid;
  const { requestId } = data;

  if (!requestId) throw new functions.https.HttpsError('invalid-argument', 'Request ID required');

  const requestDoc = await db.collection('service_requests').doc(requestId).get();
  if (!requestDoc.exists) throw new functions.https.HttpsError('not-found', 'Request not found');
  const request = requestDoc.data()!;

  // Security check: Customer, Technician, or Admin
  const isOwner = request.customerId === uid;
  const isAssignedTech = request.technicianId === uid;
  const isAdm = await isAdmin(uid);

  if (!isOwner && !isAssignedTech && !isAdm) {
    throw new functions.https.HttpsError('permission-denied', 'Privacy violation');
  }

  return { success: true, request };
})
);
