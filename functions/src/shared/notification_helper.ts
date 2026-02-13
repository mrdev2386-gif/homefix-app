/**
 * Unified Notification Helper for HomeFix
 * 
 * Production-grade notification system that:
 * - Creates unified notification documents
 * - Sends FCM push notifications to all user devices
 * - Uses Promise.allSettled for failure-safe fan-out
 * - Supports priority handling
 * - Logs failures but never throws
 */

import * as admin from 'firebase-admin';

const db = admin.firestore();

// ==========================================
// TYPES & INTERFACES
// ==========================================

export type UserType = 'customer' | 'technician' | 'admin';
export type NotificationType =
  | 'booking_confirmed'
  | 'booking_cancelled'
  | 'technician_en_route'
  | 'technician_arrived'
  | 'job_completed'
  | 'payment_success'
  | 'payment_failed'
  | 'new_request_nearby'
  | 'new_instant_booking'
  | 'payout_processed'
  | 'new_review'
  | 'custom_request_accepted'
  | 'general';

export type NotificationPriority = 'high' | 'normal';

interface FcmPayload {
  title: string;
  body: string;
  data?: { [key: string]: string };
  notificationId?: string;
  type?: string;
  priority?: NotificationPriority;
  imageUrl?: string;
}

export interface SendNotificationInput {
  userId: string;
  userType: UserType;
  title: string;
  body: string;
  type: NotificationType;
  eventId?: string; // Optional event ID for deduplication
  data?: {
    bookingId?: string;
    requestId?: string;
    screen?: string;
    [key: string]: string | undefined;
  };
  imageUrl?: string;
  priority?: NotificationPriority;
}

// ==========================================
// DUPLICATE PROTECTION
// ==========================================

/**
 * Generates a deterministic deduplication key
 */
function generateDedupeKey(
  userId: string,
  type: NotificationType,
  data?: { bookingId?: string; requestId?: string }
): string {
  const targetId = data?.bookingId ?? data?.requestId ?? '';
  return `${userId}:${type}:${targetId}`;
}

/**
 * Checks for duplicate notification within the time window
 * Returns true if duplicate found (should skip)
 */
async function checkDuplicate(
  dedupeKey: string,
  timeWindowSeconds: number = 60
): Promise<boolean> {
  const cutoff = Date.now() - (timeWindowSeconds * 1000);
  
  const snapshot = await db.collection('notifications')
    .where('dedupeKey', '==', dedupeKey)
    .where('createdAt', '>', admin.firestore.Timestamp.fromMillis(cutoff))
    .limit(1)
    .get();
  
  return !snapshot.empty;
}

// ==========================================
// MAIN HELPER FUNCTION
// ==========================================

/**
 * Sends a notification to a user - creates document AND sends push
 * Uses Promise.allSettled for failure-safe operation
 * Includes duplicate protection
 */
export async function sendUserNotification(input: SendNotificationInput): Promise<{
  success: boolean;
  notificationId?: string;
  skipped?: boolean;
  error?: string;
}> {
  const {
    userId,
    userType,
    title,
    body,
    type,
    data = {},
    imageUrl,
    priority = 'normal',
  } = input;

  try {
    // Step 0: Duplicate check
    const dedupeKey = generateDedupeKey(userId, type, data);
    const isDuplicate = await checkDuplicate(dedupeKey);
    
    if (isDuplicate) {
      console.log(`[NOTIFICATION] SKIPPED duplicate: ${dedupeKey}`);
      return { success: true, skipped: true };
    }

    // Step 1: Create notification document with dedupeKey
    const notificationRef = db.collection('notifications').doc();
    const notificationData = {
      id: notificationRef.id,
      dedupeKey, // For fast duplicate detection
      userId,
      userType,
      title,
      body,
      type,
      data: {
        ...data,
        screen: data.screen ?? getDefaultScreen(type),
      },
      isRead: false,
      imageUrl: imageUrl ?? null,
      priority,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await notificationRef.set(notificationData);

    // Step 2: Fetch all FCM tokens
    const tokensCollection = userType === 'customer' 
      ? db.collection('customers').doc(userId).collection('fcmTokens')
      : db.collection('technicians').doc(userId).collection('fcmTokens');

    const tokensSnapshot = await tokensCollection.get();

    if (tokensSnapshot.empty) {
      console.log(`[NOTIFICATION] No FCM tokens found for ${userType}:${userId}`);
      return { success: true, notificationId: notificationRef.id };
    }

    // Step 3: Send push to all tokens using Promise.allSettled
    const tokenPromises = tokensSnapshot.docs.map(async (doc) => {
      const token = doc.data().token;
      if (!token) return;

      try {
        await sendPushToToken(token, {
          title,
          body,
          data: {
            ...data,
            notificationId: notificationRef.id,
            type,
            screen: data.screen ?? getDefaultScreen(type),
          },
          priority,
          imageUrl,
        }, userType);

        // Clean up invalid token if needed
        const tokenData = doc.data();
        if (tokenData.invalidCount > 3) {
          await doc.ref.delete();
        }
      } catch (error: any) {
        console.error(`[NOTIFICATION] Failed to send to token ${doc.id}:`, error.code);
        
        // Remove invalid tokens
        if (error.code === 'messaging/registration-token-not-registered' ||
            error.code === 'messaging/invalid-registration-token') {
          await doc.ref.delete().catch(() => {});
        }
        
        // Increment invalid count
        await doc.ref.update({
          invalidCount: admin.firestore.FieldValue.increment(1),
        }).catch(() => {});
      }
    });

    // Use allSettled to never fail due to individual token failures
    const results = await Promise.allSettled(tokenPromises);
    const failedCount = results.filter(r => r.status === 'rejected').length;

    if (failedCount > 0) {
      console.warn(`[NOTIFICATION] ${failedCount}/${tokenPromises.length} tokens failed for ${userType}:${userId}`);
    }

    return { success: true, notificationId: notificationRef.id };

  } catch (error: any) {
    console.error(`[NOTIFICATION] Critical failure for ${userType}:${userId}:`, error.message);
    // Never throw - notifications are best-effort
    return { success: false, error: error.message };
  }
}

// ==========================================
// SEND TO SINGLE TOKEN
// ==========================================

async function sendPushToToken(
  token: string,
  payload: FcmPayload,
  userType: UserType
): Promise<void> {
  const message: admin.messaging.Message = {
    notification: {
      title: payload.title,
      body: payload.body,
    },
    token,
    android: {
      priority: payload.priority === 'high' ? 'high' : 'normal',
      notification: {
        channelId: userType === 'customer' ? 'high_importance_channel' : 'job_alerts_channel',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        imageUrl: payload.imageUrl,
      },
      collapseKey: payload.type,
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: payload.title,
            body: payload.body,
          },
          badge: 1,
          sound: 'default',
          'mutable-content': 1,
        },
      },
    },
    data: {
      notificationId: payload.notificationId || '',
      type: payload.type || 'general',
      screen: payload.data?.screen || '',
      bookingId: payload.data?.bookingId || '',
      deepLink: buildDeepLink(payload.type, payload.data),
    },
  };

  // Add image for APNs if provided
  if (payload.imageUrl) {
    message.apns = {
      ...message.apns as object,
      fcmOptions: {
        imageUrl: payload.imageUrl,
      },
    } as any;
  }

  await admin.messaging().send(message);
}

// ==========================================
// HELPER FUNCTIONS
// ==========================================

function getDefaultScreen(type: NotificationType): string {
  const screenMap: Record<NotificationType, string> = {
    booking_confirmed: 'booking_details',
    booking_cancelled: 'booking_details',
    technician_en_route: 'booking_tracking',
    technician_arrived: 'booking_tracking',
    job_completed: 'booking_details',
    payment_success: 'payment_history',
    payment_failed: 'payment_history',
    new_request_nearby: 'new_requests',
    new_instant_booking: 'new_requests',
    payout_processed: 'wallet',
    new_review: 'reviews',
    custom_request_accepted: 'custom_request_details',
    general: 'notifications',
  };
  return screenMap[type] || 'notifications';
}

function buildDeepLink(type: string | undefined, data: any): string {
  const base = 'homefix://app';
  
  if (!type) return base;
  
  switch (type) {
    case 'booking_confirmed':
    case 'booking_cancelled':
    case 'job_completed':
      return `${base}/booking/${data.bookingId}`;
    case 'technician_en_route':
    case 'technician_arrived':
      return `${base}/booking/${data.bookingId}/tracking`;
    case 'payment_success':
    case 'payment_failed':
      return `${base}/payment/${data.bookingId}`;
    case 'new_request_nearby':
    case 'new_instant_booking':
      return `${base}/requests/new`;
    case 'payout_processed':
      return `${base}/technician/wallet`;
    case 'new_review':
      return `${base}/reviews`;
    case 'custom_request_accepted':
      return `${base}/requests/${data.requestId}`;
    default:
      return base;
  }
}

// ==========================================
// BULK NOTIFICATIONS
// ==========================================

/**
 * Sends the same notification to multiple users
 */
export async function sendBulkNotification(
  recipients: Array<{ userId: string; userType: UserType }>,
  input: Omit<SendNotificationInput, 'userId' | 'userType'>
): Promise<{ success: number; failed: number }> {
  const promises = recipients.map(({ userId, userType }) =>
    sendUserNotification({
      ...input,
      userId,
      userType,
    })
  );

  const results = await Promise.allSettled(promises);
  
  let success = 0;
  let failed = 0;

  for (const result of results) {
    if (result.status === 'fulfilled' && result.value.success) {
      success++;
    } else {
      failed++;
    }
  }

  return { success, failed };
}

// ==========================================
// CONVENIENCE FUNCTIONS FOR COMMON SCENARIOS
// ==========================================

export async function notifyCustomerBookingConfirmed(
  customerId: string,
  bookingId: string,
  technicianName: string
): Promise<void> {
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: 'Booking Confirmed! 🎉',
    body: `$technicianName has accepted your booking and will arrive soon.`,
    type: 'booking_confirmed',
    data: { bookingId },
    priority: 'high',
  });
}

export async function notifyCustomerTechnicianEnRoute(
  customerId: string,
  bookingId: string,
  technicianName: string
): Promise<void> {
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: 'Technician On The Way! 🚗',
    body: `$technicianName is heading to your location.`,
    type: 'technician_en_route',
    data: { bookingId },
    priority: 'high',
  });
}

export async function notifyCustomerTechnicianArrived(
  customerId: string,
  bookingId: string,
  technicianName: string
): Promise<void> {
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: 'Technician Has Arrived! 👷',
    body: `$technicianName is at your location and ready to start.`,
    type: 'technician_arrived',
    data: { bookingId },
    priority: 'high',
  });
}

export async function notifyCustomerJobCompleted(
  customerId: string,
  bookingId: string,
  technicianName: string
): Promise<void> {
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: 'Job Completed! ✅',
    body: `$technicianName has completed the service. Please rate your experience.`,
    type: 'job_completed',
    data: { bookingId },
    priority: 'normal',
  });
}

export async function notifyCustomerBookingCancelled(
  customerId: string,
  bookingId: string,
  reason: string
): Promise<void> {
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: 'Booking Cancelled',
    body: reason || 'Your booking has been cancelled.',
    type: 'booking_cancelled',
    data: { bookingId },
    priority: 'high',
  });
}

export async function notifyCustomerPaymentSuccess(
  customerId: string,
  bookingId: string,
  amount: number
): Promise<void> {
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: 'Payment Successful! 💳',
    body: `₹$amount has been received. Thank you for choosing HomeFix!`,
    type: 'payment_success',
    data: { bookingId },
    priority: 'normal',
  });
}

export async function notifyTechnicianNewRequest(
  technicianId: string,
  requestId: string,
  serviceName: string,
  address: string
): Promise<void> {
  await sendUserNotification({
    userId: technicianId,
    userType: 'technician',
    title: 'New Service Request! 🔔',
    body: `$serviceName job at ${address.substring(0, 40)}...`,
    type: 'new_request_nearby',
    data: { requestId, screen: 'request_details' },
    priority: 'high',
  });
}

export async function notifyTechnicianNewInstantBooking(
  technicianId: string,
  bookingId: string,
  serviceName: string,
  address: string
): Promise<void> {
  await sendUserNotification({
    userId: technicianId,
    userType: 'technician',
    title: 'New Instant Booking! ⚡',
    body: `$serviceName job at ${address.substring(0, 40)}...`,
    type: 'new_instant_booking',
    data: { bookingId, screen: 'booking_details' },
    priority: 'high',
  });
}

export async function notifyTechnicianPayoutProcessed(
  technicianId: string,
  amount: number
): Promise<void> {
  await sendUserNotification({
    userId: technicianId,
    userType: 'technician',
    title: 'Payout Processed! 💰',
    body: `₹$amount has been credited to your wallet.`,
    type: 'payout_processed',
    data: { screen: 'wallet' },
    priority: 'normal',
  });
}

export async function notifyTechnicianNewReview(
  technicianId: string,
  bookingId: string,
  rating: number,
  customerName: string
): Promise<void> {
  await sendUserNotification({
    userId: technicianId,
    userType: 'technician',
    title: 'New Review Received! ⭐',
    body: `$customerName gave you $rating stars. Keep up the great work!`,
    type: 'new_review',
    data: { bookingId, screen: 'reviews' },
    priority: 'normal',
  });
}
