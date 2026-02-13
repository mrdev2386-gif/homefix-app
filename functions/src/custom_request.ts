import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from './shared/config';
import { sendPushNotification, NotificationPayload } from './shared/notifications';

// ==========================================
// CUSTOM REQUEST TYPES
// ==========================================

export interface CustomRequestData {
  categoryId: string;
  title: string;
  description: string;
  imageUrls?: string[];
  preferredDate: string;
  preferredTime: string;
  addressId: string;
  budgetMin?: number;
  budgetMax?: number;
  urgency: 'normal' | 'urgent' | 'emergency';
}

export interface CustomRequest {
  id: string;
  customerId: string;
  customerName: string;
  customerPhone: string;
  categoryId: string;
  categoryName?: string;
  title: string;
  description: string;
  imageUrls: string[];
  preferredDate: string;
  preferredTime: string;
  addressId: string;
  address: {
    address: string;
    coordinates?: admin.firestore.GeoPoint;
    city?: string;
    pinCode?: string;
    label?: string;
  };
  budgetMin?: number;
  budgetMax?: number;
  urgency: 'normal' | 'urgent' | 'emergency';
  status: 'pending' | 'accepted' | 'booked' | 'cancelled' | 'expired';
  technicianAssigned?: string;
  technicianName?: string;
  technicianPhone?: string;
  bookingId?: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  acceptedAt?: admin.firestore.Timestamp;
}

// ==========================================
// HELPER FUNCTIONS
// ==========================================

/**
 * Structured logging helper
 */
function log(level: 'INFO' | 'WARN' | 'ERROR', action: string, metadata: Record<string, any> = {}): void {
  console.log(JSON.stringify({
    level,
    timestamp: new Date().toISOString(),
    action,
    ...metadata,
  }));
}

/**
 * Sanitize text input to prevent XSS and injection attacks
 */
function sanitizeInput(text: string): string {
  return text
    .trim()
    .replace(/[<>]/g, '')
    .replace(/javascript:/gi, '')
    .replace(/on\w+=/gi, '')
    .slice(0, 2000);
}

/**
 * Validate category exists and is active
 * Composite index: categories(isActive, name) - required for efficient lookup
 */
async function validateCategory(categoryId: string): Promise<{ exists: boolean; name?: string }> {
  const categoryDoc = await db.collection('categories').doc(categoryId).get();
  if (!categoryDoc.exists) {
    return { exists: false };
  }
  const categoryData = categoryDoc.data()!;
  if (!categoryData.isActive) {
    return { exists: false };
  }
  return { exists: true, name: categoryData.name };
}

/**
 * Validate address belongs to customer
 */
async function validateAddress(customerId: string, addressId: string): Promise<any> {
  const addressDoc = await db.collection('customers').doc(customerId).collection('addresses').doc(addressId).get();
  if (!addressDoc.exists) {
    return null;
  }
  return { id: addressDoc.id, ...addressDoc.data() };
}

/**
 * Validate and upload base64 image to Firebase Storage
 * Server-side enforcement of size, type, and path
 */
async function uploadBase64Image(
  base64Data: string,
  customerId: string,
  requestId: string,
  index: number
): Promise<string> {
  // Validate base64 header
  if (!base64Data || typeof base64Data !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid image data');
  }

  if (!base64Data.startsWith('data:image/')) {
    throw new functions.https.HttpsError('invalid-argument', 'Only image files are allowed');
  }

  // Extract and validate base64 content
  const parts = base64Data.split(',');
  if (parts.length !== 2) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid image format');
  }

  const mimeType = parts[0].split(':')[1]?.split(';')[0] || '';
  const allowedMimeTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  
  if (!allowedMimeTypes.includes(mimeType.toLowerCase())) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid image type. Allowed: JPEG, PNG, WebP');
  }

  let imageBuffer: Buffer;
  try {
    imageBuffer = Buffer.from(parts[1], 'base64');
  } catch {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid base64 data');
  }

  // Size validation (5MB max)
  const maxSize = 5 * 1024 * 1024;
  if (imageBuffer.length > maxSize) {
    throw new functions.https.HttpsError('invalid-argument', 'Image size exceeds 5MB limit');
  }

  // Validate size is reasonable (at least 1 byte)
  if (imageBuffer.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Empty image file');
  }

  // Sanitize filename and create path
  const sanitizedCustomerId = customerId.replace(/[^a-zA-Z0-9]/g, '_');
  const sanitizedRequestId = requestId.replace(/[^a-zA-Z0-9]/g, '_');
  const imageId = `img_${Date.now()}_${index}`;
  const filePath = `custom_requests/${sanitizedCustomerId}/${sanitizedRequestId}/${imageId}.jpg`;
  const file = admin.storage().bucket().file(filePath);

  try {
    await file.save(imageBuffer, {
      contentType: 'image/jpeg',
      metadata: {
        cacheControl: 'public,max-age=31536000',
        metadata: {
          customerId: sanitizedCustomerId,
          requestId: sanitizedRequestId,
          uploadedAt: new Date().toISOString(),
        },
      },
    });

    const [url] = await file.getSignedUrl({
      action: 'read',
      expires: Date.now() + 365 * 24 * 60 * 60 * 1000,
    });

    return url;
  } catch (error: any) {
    log('ERROR', 'image_upload_failed', { customerId, requestId, error: error.message });
    throw new functions.https.HttpsError('internal', 'Failed to upload image');
  }
}

/**
 * Find matching technicians for a custom request
 * Composite index required: technicians(isActive, status, serviceCategories, city)
 * Limited to 50 results for scalability
 */
async function findMatchingTechnicians(categoryId: string, city?: string): Promise<string[]> {
  try {
    let query: admin.firestore.Query = db.collection('technicians')
      .where('isActive', '==', true)
      .where('status', '==', 'active')
      .where('serviceCategories', 'array-contains', categoryId)
      .limit(50); // Scalability guard - max 50 technicians notified

    if (city) {
      query = query.where('city', '==', city);
    }

    const technicianSnap = await query.get();
    return technicianSnap.docs.map(doc => doc.id);
  } catch (error: any) {
    log('ERROR', 'technician_matching_failed', { categoryId, error: error.message });
    return [];
  }
}

/**
 * Create notifications for technicians - failure-safe fan-out
 * Uses Promise.allSettled to ensure one failure doesn't block others
 */
async function createTechnicianNotifications(
  technicianIds: string[],
  requestId: string,
  categoryName: string,
  urgencyLabel: string
): Promise<void> {
  if (technicianIds.length === 0) {
    log('INFO', 'no_technicians_to_notify', { requestId });
    return;
  }

  log('INFO', 'creating_technician_notifications', { 
    requestId, 
    count: technicianIds.length 
  });

  const notificationPromises: Promise<void>[] = technicianIds.map(async (technicianId) => {
    try {
      const notificationRef = db.collection('technician_notifications').doc();
      
      await notificationRef.set({
        id: notificationRef.id,
        technicianId,
        requestId,
        type: 'custom_request',
        title: 'New Service Request',
        body: `A customer needs help with ${categoryName}`,
        urgency: urgencyLabel,
        status: 'unread',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // Send FCM - wrapped in try/catch, doesn't block notification creation
      await sendPushNotification(technicianId, 'technicians', {
        title: '🔔 New Service Request',
        body: 'A customer nearby needs help! Tap to view.',
        data: { type: 'custom_request', requestId },
      }).catch((err) => {
        log('WARN', 'fcm_send_failed', { technicianId, requestId, error: err.message });
      });
    } catch (error: any) {
      // Log but don't throw - notification fan-out must not fail the main request
      log('WARN', 'notification_creation_failed', { 
        technicianId, 
        requestId, 
        error: error.message 
      });
    }
  });

  // Use allSettled to ensure all notifications are attempted
  await Promise.allSettled(notificationPromises);
  
  log('INFO', 'notifications_completed', { requestId, count: technicianIds.length });
}

/**
 * Check rate limit for custom requests
 * Uses rolling window with indexed query on createdAt
 */
async function checkRateLimit(customerId: string, urgency: string): Promise<void> {
  // Emergency requests bypass rate limiting
  if (urgency === 'emergency') {
    log('INFO', 'rate_limit_bypassed', { customerId, reason: 'emergency' });
    return;
  }

  // Rolling window: last 60 minutes
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

  try {
    const recentRequests = await db.collection('custom_requests')
      .where('customerId', '==', customerId)
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneHourAgo))
      .where('status', '!=', 'cancelled')
      .count()
      .get();

    const count = recentRequests.data().count;

    if (count >= 3) {
      log('WARN', 'rate_limit_exceeded', { customerId, count, limit: 3 });
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Rate limit exceeded. You can only create 3 requests per hour.'
      );
    }

    log('INFO', 'rate_limit_passed', { customerId, count, limit: 3 });
  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    log('ERROR', 'rate_limit_check_failed', { customerId, error: error.message });
    // Don't fail on rate limit check errors - allow the request
  }
}

// ==========================================
// CREATE CUSTOM REQUEST FUNCTION
// ==========================================

export const createCustomRequest = functions.https.onCall(async (data: CustomRequestData, context: functions.https.CallableContext) => {
  // 1. Authentication Check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const customerId = context.auth.uid;
  const customerName = context.auth.token.name || 'Customer';

  log('INFO', 'create_custom_request_started', { customerId });

  // 2. Input Validation
  const errors: string[] = [];

  if (!data.categoryId) errors.push('Service category is required');
  if (!data.title || data.title.trim().length < 5) errors.push('Title must be at least 5 characters');
  if (!data.description || data.description.trim().length < 20) errors.push('Description must be at least 20 characters');
  if (!data.preferredDate) errors.push('Preferred date is required');
  if (!data.preferredTime) errors.push('Preferred time slot is required');
  if (!data.addressId) errors.push('Address is required');
  if (!data.urgency) errors.push('Urgency level is required');

  if (errors.length > 0) {
    throw new functions.https.HttpsError('invalid-argument', errors.join('; '));
  }

  // Validate date is not in the past
  const preferredDate = new Date(data.preferredDate);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  if (preferredDate < today) {
    throw new functions.https.HttpsError('invalid-argument', 'Preferred date cannot be in the past');
  }

  // Validate budget range
  if (data.budgetMin !== undefined && data.budgetMin < 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Minimum budget cannot be negative');
  }
  if (data.budgetMax !== undefined && data.budgetMax < 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Maximum budget cannot be negative');
  }
  if (data.budgetMin !== undefined && data.budgetMax !== undefined && data.budgetMin > data.budgetMax) {
    throw new functions.https.HttpsError('invalid-argument', 'Minimum budget cannot exceed maximum budget');
  }

  // Server-side image validation - critical for security
  if (data.imageUrls && data.imageUrls.length > 5) {
    throw new functions.https.HttpsError('invalid-argument', 'Maximum 5 images allowed');
  }

  // 3. Validate Category
  const categoryResult = await validateCategory(data.categoryId);
  if (!categoryResult.exists) {
    throw new functions.https.HttpsError('not-found', 'Invalid or inactive service category');
  }

  // 4. Validate Address
  const addressData = await validateAddress(customerId, data.addressId);
  if (!addressData) {
    throw new functions.https.HttpsError('not-found', 'Address not found');
  }

  // 5. Rate Limiting Check
  await checkRateLimit(customerId, data.urgency);

  try {
    const requestId = db.collection('custom_requests').doc().id;

    // 6. Upload Images (if any) - with server-side validation
    const imageUrls: string[] = [];
    if (data.imageUrls && data.imageUrls.length > 0) {
      for (let i = 0; i < data.imageUrls.length; i++) {
        const uploadedUrl = await uploadBase64Image(data.imageUrls[i], customerId, requestId, i);
        imageUrls.push(uploadedUrl);
      }
    }

    // 7. Prepare Request Data
    const requestData: CustomRequest = {
      id: requestId,
      customerId,
      customerName,
      customerPhone: '',
      categoryId: data.categoryId,
      categoryName: categoryResult.name,
      title: sanitizeInput(data.title),
      description: sanitizeInput(data.description),
      imageUrls,
      preferredDate: data.preferredDate,
      preferredTime: data.preferredTime,
      addressId: data.addressId,
      address: {
        address: addressData.address,
        coordinates: addressData.coordinates,
        city: addressData.city,
        pinCode: addressData.pinCode,
        label: addressData.label,
      },
      budgetMin: data.budgetMin,
      budgetMax: data.budgetMax,
      urgency: data.urgency,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
      updatedAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
    };

    // 8. Get Customer Phone
    const customerDoc = await db.collection('customers').doc(customerId).get();
    if (customerDoc.exists) {
      const customerData = customerDoc.data()!;
      requestData.customerPhone = customerData.phone || '';
    }

    // 9. Create Firestore Document
    await db.collection('custom_requests').doc(requestId).set(requestData);

    log('INFO', 'custom_request_created', { requestId, customerId, urgency: data.urgency });

    // 10. Async Technician Alert - fire and forget, failure-safe
    const urgencyLabel = data.urgency === 'emergency' ? 'URGENT' : data.urgency === 'urgent' ? 'Soon' : 'Flexible';
    
    findMatchingTechnicians(data.categoryId, addressData.city)
      .then(async (technicianIds) => {
        await createTechnicianNotifications(technicianIds, requestId, categoryResult.name || '', urgencyLabel);
      })
      .catch(err => log('ERROR', 'technician_alert_failed', { requestId, error: err.message }));

    // 11. Return Success
    return {
      success: true,
      requestId,
      message: 'Custom request created successfully',
    };

  } catch (error: any) {
    log('ERROR', 'create_custom_request_failed', { customerId, error: error.message });
    throw new functions.https.HttpsError('internal', error.message || 'Failed to create custom request');
  }
});

// ==========================================
// ACCEPT CUSTOM REQUEST FUNCTION
// ==========================================

export const acceptCustomRequest = functions.https.onCall(async (data, context: functions.https.CallableContext) => {
  // 1. Authentication Check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { requestId } = data;

  if (!requestId) {
    throw new functions.https.HttpsError('invalid-argument', 'Request ID is required');
  }

  const technicianId = context.auth.uid;

  log('INFO', 'accept_custom_request_started', { technicianId, requestId });

  // 2. Verify Technician Status
  const technicianDoc = await db.collection('technicians').doc(technicianId).get();
  if (!technicianDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Only verified technicians can accept requests');
  }

  const technicianData = technicianDoc.data()!;
  if (!technicianData.isActive || technicianData.status !== 'active') {
    throw new functions.https.HttpsError('permission-denied', 'Technician account is not active');
  }

  // 3. Use Transaction for Race Condition Safety
  const result = await db.runTransaction(async (transaction) => {
    const requestRef = db.collection('custom_requests').doc(requestId);
    const requestDoc = await transaction.get(requestRef);

    if (!requestDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Custom request not found');
    }

    const request = requestDoc.data() as CustomRequest;

    // 4. Double-check Status (race protection)
    if (request.status !== 'pending') {
      log('WARN', 'accept_failed_already_processed', { 
        requestId, 
        technicianId, 
        status: request.status 
      });
      throw new functions.https.HttpsError('failed-precondition', `Request has already been ${request.status}`);
    }

    // 5. Check for conflicting active requests (within transaction for consistency)
    const conflictingSnapshot = await db.collection('custom_requests')
      .where('technicianAssigned', '==', technicianId)
      .where('status', 'in', ['pending', 'accepted'])
      .limit(2)
      .get();

    if (!conflictingSnapshot.empty) {
      throw new functions.https.HttpsError('failed-precondition', 'You already have an active request');
    }

    // 6. Create Booking from Custom Request
    const bookingId = db.collection('bookings').doc().id;
    const bookingNumber = `BK-${new Date().getFullYear()}-${String(Math.floor(1000 + Math.random() * 9000)).padStart(4, '0')}`;
    const estimatedAmount = request.budgetMax || request.budgetMin || 500;

    const bookingData = {
      id: bookingId,
      bookingNumber,
      customerId: request.customerId,
      customerName: request.customerName,
      customerPhone: request.customerPhone,
      technicianId,
      technicianName: technicianData.name || 'Technician',
      technicianPhone: technicianData.phone || '',
      serviceId: request.categoryId,
      serviceName: request.categoryName || 'Custom Service',
      location: request.address,
      status: 'accepted',
      paymentStatus: 'pending',
      price: estimatedAmount,
      finalAmount: estimatedAmount,
      customRequestId: requestId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      scheduledDate: request.preferredDate,
      scheduledTime: request.preferredTime,
    };

    // 7. Atomic Writes within Transaction
    transaction.set(db.collection('bookings').doc(bookingId), bookingData);
    transaction.update(requestRef, {
      status: 'accepted',
      technicianAssigned: technicianId,
      technicianName: technicianData.name || 'Technician',
      technicianPhone: technicianData.phone || '',
      bookingId,
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 8. Create customer notification
    const customerNotificationRef = db.collection('customers').doc(request.customerId).collection('notifications').doc();
    transaction.set(customerNotificationRef, {
      id: customerNotificationRef.id,
      type: 'request_accepted',
      title: 'Request Accepted!',
      body: 'A technician has accepted your request and a booking has been created.',
      data: { bookingId, requestId, type: 'booking_status' },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    log('INFO', 'custom_request_accepted', { requestId, bookingId, technicianId });

    return {
      bookingId,
      bookingNumber,
      customerId: request.customerId,
      customerName: request.customerName,
      technicianName: technicianData.name || 'Technician',
    };
  });

  // 9. Send Push Notification to Customer (async, failure-safe)
  try {
    await sendPushNotification(result.customerId, 'customers', {
      title: '✅ Request Accepted!',
      body: `${result.technicianName} has accepted your request. Booking #${result.bookingNumber}`,
      data: { 
        type: 'booking_status', 
        bookingId: result.bookingId,
        requestId,
      },
    });
  } catch (err: any) {
    log('WARN', 'customer_notification_failed', { 
      bookingId: result.bookingId, 
      error: err.message 
    });
    // Don't fail - notification is non-critical
  }

  return {
    success: true,
    bookingId: result.bookingId,
    bookingNumber: result.bookingNumber,
    message: 'Custom request accepted successfully',
  };
});

// ==========================================
// GET CUSTOM REQUEST (Customer View)
// ==========================================

export const getMyCustomRequests = functions.https.onCall(async (data, context: functions.https.CallableContext) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const customerId = context.auth.uid;
  const { status, limit = 20, startAfter } = data;

  try {
    let query: admin.firestore.Query = db.collection('custom_requests')
      .where('customerId', '==', customerId)
      .orderBy('createdAt', 'desc')
      .limit(limit);

    if (startAfter) {
      const startAfterDoc = await db.collection('custom_requests').doc(startAfter).get();
      if (startAfterDoc.exists) {
        query = query.startAfter(startAfterDoc);
      }
    }

    if (status) {
      query = query.where('status', '==', status);
    }

    const snapshot = await query.get();
    
    return {
      success: true,
      requests: snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate?.()?.toISOString(),
          updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
          acceptedAt: data.acceptedAt?.toDate?.()?.toISOString(),
        };
      }),
    };
  } catch (error: any) {
    log('ERROR', 'get_my_requests_failed', { customerId, error: error.message });
    throw new functions.https.HttpsError('internal', 'Failed to fetch requests');
  }
});

// ==========================================
// CANCEL CUSTOM REQUEST (Customer View)
// ==========================================

export const cancelCustomRequest = functions.https.onCall(async (data, context: functions.https.CallableContext) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { requestId, reason } = data;

  if (!requestId) {
    throw new functions.https.HttpsError('invalid-argument', 'Request ID is required');
  }

  const customerId = context.auth.uid;

  await db.runTransaction(async (transaction) => {
    const requestRef = db.collection('custom_requests').doc(requestId);
    const requestDoc = await transaction.get(requestRef);

    if (!requestDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Request not found');
    }

    const request = requestDoc.data() as CustomRequest;

    if (request.customerId !== customerId) {
      throw new functions.https.HttpsError('permission-denied', 'You can only cancel your own requests');
    }

    if (request.status !== 'pending') {
      throw new functions.https.HttpsError('failed-precondition', 'Only pending requests can be cancelled');
    }

    transaction.update(requestRef, {
      status: 'cancelled',
      cancellationReason: reason || 'Cancelled by customer',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  log('INFO', 'custom_request_cancelled', { requestId, customerId });

  return { success: true, message: 'Request cancelled successfully' };
});

// ==========================================
// GET CUSTOM REQUEST (Technician Inbox)
// ==========================================

export const getTechnicianInbox = functions.https.onCall(async (data, context: functions.https.CallableContext) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const technicianId = context.auth.uid;

  const technicianDoc = await db.collection('technicians').doc(technicianId).get();
  if (!technicianDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Technician not found');
  }

  const technicianData = technicianDoc.data()!;
  if (!technicianData.isActive || technicianData.status !== 'active') {
    throw new functions.https.HttpsError('permission-denied', 'Technician account is not active');
  }

  const { limit = 20, startAfter } = data;

  try {
    const serviceCategories = technicianData.serviceCategories || [];
    
    let query: admin.firestore.Query = db.collection('custom_requests')
      .where('status', '==', 'pending')
      .where('categoryId', 'in', serviceCategories)
      .orderBy('createdAt', 'desc')
      .limit(limit);

    if (startAfter) {
      const startAfterDoc = await db.collection('custom_requests').doc(startAfter).get();
      if (startAfterDoc.exists) {
        query = query.startAfter(startAfterDoc);
      }
    }

    const snapshot = await query.get();
    
    return {
      success: true,
      requests: snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate?.()?.toISOString(),
          updatedAt: data.updatedAt?.toDate?.()?.toISOString(),
        };
      }),
    };
  } catch (error: any) {
    log('ERROR', 'get_technician_inbox_failed', { technicianId, error: error.message });
    throw new functions.https.HttpsError('internal', 'Failed to fetch inbox');
  }
});

// ==========================================
// GET CUSTOM REQUEST DETAIL
// ==========================================

export const getCustomRequestDetail = functions.https.onCall(async (data, context: functions.https.CallableContext) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { requestId } = data;
  const userId = context.auth.uid;

  if (!requestId) {
    throw new functions.https.HttpsError('invalid-argument', 'Request ID is required');
  }

  const requestDoc = await db.collection('custom_requests').doc(requestId).get();

  if (!requestDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Request not found');
  }

  const request = requestDoc.data() as CustomRequest;

  const isOwner = request.customerId === userId;
  const isAssignedTech = request.technicianAssigned === userId;
  const adminDoc = await db.collection('admins').doc(userId).get();
  const isAdmin = adminDoc.exists;

  if (!isOwner && !isAssignedTech && !isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Access denied');
  }

  return {
    success: true,
    request: {
      ...request,
      createdAt: request.createdAt?.toDate?.()?.toISOString(),
      updatedAt: request.updatedAt?.toDate?.()?.toISOString(),
      acceptedAt: request.acceptedAt?.toDate?.()?.toISOString(),
    },
  };
});
