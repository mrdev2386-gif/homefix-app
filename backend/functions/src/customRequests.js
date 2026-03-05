const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

// Create custom request with image URLs
exports.createCustomRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { title, description, category, preferredDate, preferredTime, budget, address, district, pincode, images } = data;

  if (!title?.trim() || !description?.trim() || !category || !preferredDate || !preferredTime || !address?.trim()) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  try {
    const requestRef = db.collection('custom_requests').doc();
    
    await requestRef.set({
      type: 'custom_request',
      customerId: userId,
      title: title.trim(),
      description: description.trim(),
      category,
      preferredDate,
      preferredTime,
      budget: budget ? parseFloat(budget) : null,
      address: address.trim(),
      state: '',
      district: district || '',
      pincode: pincode || '',
      images: images || [],
      technicianId: null,
      status: 'pending_admin_review',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, requestId: requestRef.id };
  } catch (error) {
    console.error('Error creating custom request:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create request');
  }
});

// Assign technician to request
exports.assignTechnicianToRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { requestId, technicianId } = data;

  if (!requestId || !technicianId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing requestId or technicianId');
  }

  try {
    await db.collection('custom_requests').doc(requestId).update({
      technicianId,
      status: 'technician_assigned',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification to technician
    const techDoc = await db.collection('technicians').doc(technicianId).get();
    const fcmToken = techDoc.data()?.fcmToken;
    
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: 'New Custom Service Request',
          body: 'You have been assigned a new custom service request',
        },
        data: { requestId, type: 'custom_request' },
      });
    }

    return { success: true };
  } catch (error) {
    console.error('Error assigning technician:', error);
    throw new functions.https.HttpsError('internal', 'Failed to assign technician');
  }
});

// Accept custom request and create booking
exports.acceptCustomRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const technicianId = context.auth.uid;
  const { requestId } = data;

  if (!requestId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing requestId');
  }

  try {
    const requestDoc = await db.collection('custom_requests').doc(requestId).get();
    
    if (!requestDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Request not found');
    }

    const requestData = requestDoc.data();
    
    if (requestData.technicianId !== technicianId) {
      throw new functions.https.HttpsError('permission-denied', 'Not assigned to this request');
    }

    // Update request status
    await db.collection('custom_requests').doc(requestId).update({
      status: 'accepted',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create booking
    const bookingRef = db.collection('bookings').doc();
    await bookingRef.set({
      type: 'custom_request',
      customRequestId: requestId,
      customerId: requestData.customerId,
      technicianId,
      status: 'approved',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Notify customer
    const customerDoc = await db.collection('customers').doc(requestData.customerId).get();
    const customerFcm = customerDoc.data()?.fcmToken;
    
    if (customerFcm) {
      await admin.messaging().send({
        token: customerFcm,
        notification: {
          title: 'Technician Assigned',
          body: 'A technician has accepted your custom service request',
        },
        data: { bookingId: bookingRef.id, type: 'booking' },
      });
    }

    return { success: true, bookingId: bookingRef.id };
  } catch (error) {
    console.error('Error accepting request:', error);
    throw new functions.https.HttpsError('internal', 'Failed to accept request');
  }
});

// Reject custom request
exports.rejectCustomRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { requestId } = data;

  if (!requestId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing requestId');
  }

  try {
    const requestDoc = await db.collection('custom_requests').doc(requestId).get();
    const requestData = requestDoc.data();

    await db.collection('custom_requests').doc(requestId).update({
      status: 'rejected',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Notify customer
    const customerDoc = await db.collection('customers').doc(requestData.customerId).get();
    const customerFcm = customerDoc.data()?.fcmToken;
    
    if (customerFcm) {
      await admin.messaging().send({
        token: customerFcm,
        notification: {
          title: 'Request Rejected',
          body: 'Your custom service request has been rejected',
        },
        data: { requestId, type: 'custom_request' },
      });
    }

    return { success: true };
  } catch (error) {
    console.error('Error rejecting request:', error);
    throw new functions.https.HttpsError('internal', 'Failed to reject request');
  }
});
