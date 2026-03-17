/**
 * UNIFIED BOOKING LIFECYCLE - Single Source of Truth
 * 
 * STANDARDIZED FLOW:
 * 1. Customer creates booking → bookingStatus: "pending"
 * 2. Admin approves → bookingStatus: "approved_by_admin" 
 * 3. Technician accepts → bookingStatus: "technician_accepted"
 * 4. Service starts → bookingStatus: "service_in_progress"
 * 5. Service completes → bookingStatus: "service_completed"
 * 6. Payment processed → bookingStatus: "completed"
 * 
 * REJECTED STATES:
 * - "rejected_by_admin"
 * - "technician_rejected"
 * - "cancelled"
 * 
 * SECURITY:
 * - Idempotency protection via idempotencyKey
 * - Input validation & sanitization
 * - Firestore transaction for atomic writes
 * - No client-side Firestore writes
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendNotificationToToken } from '../shared/notification_helper';
import { isValidTransition, isTerminalState, validateTransitionInTransaction } from '../shared/booking_state_machine';
import { checkBookingRateLimit } from './production_hardening';
import { secureCallable, sanitize } from '../shared/security';
import { logger } from '../shared/utils';

const db = admin.firestore();

// Valid booking status transitions
const VALID_STATUS_TRANSITIONS: Record<string, string[]> = {
  'pending': ['approved_by_admin', 'rejected_by_admin', 'cancelled'],
  'pending_admin_approval': ['approved_by_admin', 'rejected_by_admin', 'cancelled'],
  'approved_by_admin': ['technician_accepted', 'technician_rejected', 'cancelled'],
  'technician_accepted': ['service_in_progress', 'cancelled'],
  'service_in_progress': ['service_completed', 'cancelled'],
  'service_completed': ['completed', 'cancelled'],
  'completed': [],
  'cancelled': [],
  'rejected_by_admin': [],
  'technician_rejected': [],
};

// ==========================================
// 1️⃣ ADMIN APPROVE BOOKING
// ==========================================
export const approveBookingByAdmin = functions.https.onCall(
    secureCallable(async (data, context) => {
        const { bookingId } = data;
        const uid = context.auth?.uid;

        if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

        const adminDoc = await db.collection('admins').doc(uid).get();
        if (!adminDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can approve bookings');
        }

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingSnap = await bookingRef.get();

        if (!bookingSnap.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingSnap.data()!;

        if (booking.bookingStatus !== 'pending_admin_approval' && booking.bookingStatus !== 'pending') {
            throw new functions.https.HttpsError(
                'failed-precondition',
                `Cannot approve booking with status: ${booking.bookingStatus}`
            );
        }

        if (!booking.technicianId) {
            throw new functions.https.HttpsError('failed-precondition', 'No technician assigned to booking');
        }

        const techDoc = await db.collection('technicians').doc(booking.technicianId).get();
        if (!techDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        }

        const techData = techDoc.data()!;

        if (techData.verificationStatus !== 'approved') {
            throw new functions.https.HttpsError(
                'failed-precondition',
                'Technician is not verified. Please select another technician.'
            );
        }

        await bookingRef.update({
            bookingStatus: 'approved_by_admin',
            approvedAt: admin.firestore.FieldValue.serverTimestamp(),
            approvedBy: uid,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        if (booking.technicianId) {
            const techDoc = await db.collection('technicians').doc(booking.technicianId).get();
            const techData = techDoc.data();

            if (techData?.fcmToken) {
                await sendNotificationToToken({
                    token: techData.fcmToken,
                    title: 'New Job Available',
                    body: `Admin approved a booking for ${booking.serviceName || 'service'}. Please accept or reject.`,
                    data: { bookingId, type: 'booking_approved' },
                });
            }
        }

        return { success: true, bookingStatus: 'approved_by_admin' };
    })
);

// ==========================================
// 2️⃣ TECHNICIAN ACCEPT BOOKING
// ==========================================
export const technicianAcceptBooking = functions.https.onCall(
    secureCallable(async (data, context) => {
        const { bookingId } = data;
        const uid = context.auth?.uid;

        if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingSnap = await bookingRef.get();

        if (!bookingSnap.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingSnap.data()!;

        if (booking.technicianId !== uid) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Only the assigned technician can accept this booking'
            );
        }

        if (booking.bookingStatus !== 'approved_by_admin') {
            throw new functions.https.HttpsError(
                'failed-precondition',
                `Cannot accept booking with status: ${booking.bookingStatus}`
            );
        }

        await bookingRef.update({
            bookingStatus: 'technician_accepted',
            acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        const customerDoc = await db.collection('customers').doc(booking.customerId).get();
        const customerData = customerDoc.data();

        if (customerData?.fcmToken) {
            await sendNotificationToToken({
                token: customerData.fcmToken,
                title: 'Booking Accepted',
                body: 'Your booking has been accepted by the technician',
                data: { bookingId, type: 'booking_accepted' },
            });
        }

        return { success: true, bookingStatus: 'technician_accepted' };
    })
);

// ==========================================
// 3️⃣ START SERVICE
// ==========================================
export const startService = functions.https.onCall(
    secureCallable(async (data, context) => {
        const { bookingId } = data;
        const uid = context.auth?.uid;

        if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingSnap = await bookingRef.get();

        if (!bookingSnap.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingSnap.data()!;

        if (booking.technicianId !== uid) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Only the assigned technician can start this service'
            );
        }

        if (booking.bookingStatus !== 'technician_accepted') {
            throw new functions.https.HttpsError(
                'failed-precondition',
                `Cannot start service with status: ${booking.bookingStatus}`
            );
        }

        await bookingRef.update({
            bookingStatus: 'service_in_progress',
            serviceStartedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        const customerDoc = await db.collection('customers').doc(booking.customerId).get();
        const customerData = customerDoc.data();

        if (customerData?.fcmToken) {
            await sendNotificationToToken({
                token: customerData.fcmToken,
                title: 'Service Started',
                body: 'Your technician has started working on your service',
                data: { bookingId, type: 'service_started' },
            });
        }

        return { success: true, bookingStatus: 'service_in_progress' };
    })
);

// ==========================================
// 4️⃣ COMPLETE SERVICE
// ==========================================
export const completeService = functions.https.onCall(
    secureCallable(async (data, context) => {
        const { bookingId } = data;
        const uid = context.auth?.uid;

        if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingSnap = await bookingRef.get();

        if (!bookingSnap.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingSnap.data()!;

        if (booking.technicianId !== uid) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Only the assigned technician can complete this service'
            );
        }

        if (booking.bookingStatus !== 'service_in_progress') {
            throw new functions.https.HttpsError(
                'failed-precondition',
                `Cannot complete service with status: ${booking.bookingStatus}`
            );
        }

        await bookingRef.update({
            bookingStatus: 'service_completed',
            serviceCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
            paymentStatus: 'pending',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        const customerDoc = await db.collection('customers').doc(booking.customerId).get();
        const customerData = customerDoc.data();

        if (customerData?.fcmToken) {
            await sendNotificationToToken({
                token: customerData.fcmToken,
                title: 'Service Completed',
                body: 'Your service has been completed. Please make payment and leave a review.',
                data: { bookingId, type: 'service_completed' },
            });
        }

        return { success: true, bookingStatus: 'service_completed' };
    })
);

// ==========================================
// 5️⃣ TECHNICIAN REJECT BOOKING
// ==========================================
export const technicianRejectBooking = functions.https.onCall(
    secureCallable(async (data, context) => {
        const { bookingId, reason } = data;
        const uid = context.auth?.uid;

        if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingSnap = await bookingRef.get();

        if (!bookingSnap.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingSnap.data()!;

        if (booking.technicianId !== uid) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'Only the assigned technician can reject this booking'
            );
        }

        if (booking.bookingStatus !== 'approved_by_admin') {
            throw new functions.https.HttpsError(
                'failed-precondition',
                `Cannot reject booking with status: ${booking.bookingStatus}`
            );
        }

        await bookingRef.update({
            bookingStatus: 'technician_rejected',
            rejectedBy: uid,
            rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
            rejectionReason: sanitize(reason) || 'Technician unavailable',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Notify admin to reassign
        const adminsSnapshot = await db.collection('admins').get();
        for (const adminDoc of adminsSnapshot.docs) {
            const adminData = adminDoc.data();
            if (adminData?.fcmToken) {
                await sendNotificationToToken({
                    token: adminData.fcmToken,
                    title: 'Booking Rejected',
                    body: `Technician rejected booking. Please reassign to another technician.`,
                    data: { bookingId, type: 'booking_rejected_by_tech' },
                });
            }
        }

        return { success: true, bookingStatus: 'technician_rejected' };
    })
);

// ==========================================
// 6️⃣ CANCEL BOOKING
// ==========================================
export const cancelBooking = functions.https.onCall(
    secureCallable(async (data, context) => {
        const { bookingId, reason } = data;
        const uid = context.auth?.uid;

        if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingSnap = await bookingRef.get();

        if (!bookingSnap.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }

        const booking = bookingSnap.data()!;

        if (booking.bookingStatus === 'completed') {
            throw new functions.https.HttpsError(
                'failed-precondition',
                'Cannot cancel completed booking'
            );
        }

        const isCustomer = booking.customerId === uid;
        const isTechnician = booking.technicianId === uid;
        const adminDoc = await db.collection('admins').doc(uid).get();
        const isAdmin = adminDoc.exists;

        if (!isCustomer && !isTechnician && !isAdmin) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'You do not have permission to cancel this booking'
            );
        }

        await bookingRef.update({
            bookingStatus: 'cancelled',
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
            cancelledBy: uid,
            cancellationReason: sanitize(reason) || 'No reason provided',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return { success: true, bookingStatus: 'cancelled' };
    })
);

// ==========================================
// 7️⃣ CREATE BOOKING REQUEST
// ==========================================
/**
 * Create a new booking request
 * 
 * IDEMPOTENCY: Uses idempotencyKey to prevent duplicate bookings
 * TRANSACTION: Atomic write with idempotency check
 * VALIDATION: Input sanitization and business logic validation
 */
export const createBookingRequest = functions.https.onCall(
  secureCallable(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
    }

    // PHASE 3: Rate Limiting
    const rateLimit = await checkBookingRateLimit(uid);
    if (!rateLimit.allowed) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        rateLimit.error || 'Too many booking requests. Please try later.'
      );
    }

    // PHASE 4: Input Validation (Strict)
    const {
      serviceId,
      technicianId,
      categoryId,
      categoryName,
      scheduledDate,
      scheduledTime,
      address,
      subcategoryId,
      quantity,
      durationMinutes,
      couponCode,
      idempotencyKey,
      paymentMode,
    } = data;

    if (!serviceId || typeof serviceId !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid serviceId');
    }
    if (!technicianId || typeof technicianId !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid technicianId');
    }
    if (!categoryId || !scheduledDate || !scheduledTime || !address) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required booking fields');
    }

    const customerDoc = await db.collection('users').doc(uid).get();
    if (!customerDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Customer profile not found');
    }

    // PHASE 1: Fix Price Manipulation
    // Fetch actual price from source of truth (technician_services)
    const serviceDoc = await db.collection('technician_services').doc(serviceId).get();
    if (!serviceDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Service listing not found');
    }

    const serviceData = serviceDoc.data()!;
    if (serviceData.technicianId !== technicianId) {
      throw new functions.https.HttpsError('invalid-argument', 'Service does not belong to the selected technician');
    }

    // ENFORCE Database Price
    const basePrice = serviceData.price;
    if (typeof basePrice !== 'number' || basePrice <= 0) {
      throw new functions.https.HttpsError('internal', 'Invalid service price configuration');
    }

    const techDoc = await db.collection('technicians').doc(technicianId).get();
    if (!techDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Technician not found');
    }

    const techData = techDoc.data()!;
    if (techData.verificationStatus !== 'approved' && techData.status !== 'approved') {
      throw new functions.https.HttpsError('failed-precondition', 'Technician is not verified');
    }

    const finalIdempotencyKey = idempotencyKey || `BK_${uid}_${Date.now()}`;
    const bookingId = db.collection('bookings').doc().id;

    try {
      await db.runTransaction(async (transaction) => {
        const idempotencyRef = db.collection('booking_idempotency').doc(finalIdempotencyKey);
        const idempotencyDoc = await transaction.get(idempotencyRef);

        if (idempotencyDoc.exists) {
          const existingBookingId = idempotencyDoc.data()?.bookingId;
          throw new Error(`IDEMPOTENCY_DUPLICATE:${existingBookingId}`);
        }

        // PHASE 5: Protect Booking Integrity
        const bookingData = {
          bookingId,
          customerId: uid,
          customerName: customerDoc.data()?.name || 'Customer',
          technicianId,
          technicianName: techData.name || 'Technician',
          serviceId,
          serviceName: serviceData.name || 'Service',
          categoryId: serviceData.categoryId || categoryId,
          categoryName: categoryName || serviceData.category || 'Service',
          subcategoryId: subcategoryId || null,
          quantity: quantity || 1,
          durationMinutes: durationMinutes || null,
          scheduledDate,
          scheduledTime,
          address: sanitizeAddress(address),
          // ENFORCE PRICE AND INITIAL STATUS
          price: basePrice,
          discountAmount: 0,
          finalAmount: basePrice,
          paymentMode: paymentMode || 'pay_after_work',
          bookingStatus: 'pending',
          paymentStatus: 'pending',
          adminApproval: null,
          approvedAt: null,
          approvedBy: null,
          acceptedAt: null,
          serviceStartedAt: null,
          serviceCompletedAt: null,
          cancelledAt: null,
          cancelledBy: null,
          cancellationReason: null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        transaction.set(db.collection('bookings').doc(bookingId), bookingData);
        transaction.set(idempotencyRef, {
          bookingId,
          customerId: uid,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.set(db.collection('activity_logs').doc(), {
          actorType: 'customer',
          actorUid: uid,
          action: 'booking_created',
          bookingId,
          metadata: { serviceId, technicianId, price: basePrice },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      console.log(`[BOOKING] Created booking: ${bookingId} for customer: ${uid} with price: ${basePrice}`);
      await sendAdminNotification(bookingId, 'New Booking Pending Approval');

      return {
        success: true,
        bookingId,
        bookingStatus: 'pending',
        message: 'Booking created successfully. Awaiting admin approval.',
      };
    } catch (error: any) {
      if (error.message?.startsWith('IDEMPOTENCY_DUPLICATE:')) {
        const existingBookingId = error.message.split(':')[1];
        console.log(`[BOOKING] Duplicate booking request detected. Returning existing booking: ${existingBookingId}`);
        return {
          success: true,
          bookingId: existingBookingId,
          bookingStatus: 'pending',
          isDuplicate: true,
          message: 'Booking already exists with this request.',
        };
      }
      console.error(`[BOOKING] Error creating booking:`, error);
      throw new functions.https.HttpsError('internal', 'Failed to create booking');
    }
  })
);

/**
 * Validate booking status transition
 */
export function validateStatusTransition(currentStatus: string, newStatus: string): boolean {
  const allowedTransitions = VALID_STATUS_TRANSITIONS[currentStatus] || [];
  return allowedTransitions.includes(newStatus);
}

/**
 * Sanitize address object
 */
function sanitizeAddress(address: any): Record<string, any> {
  if (!address || typeof address !== 'object') {
    return {};
  }

  const sanitized: Record<string, any> = {};
  const allowedKeys = ['line1', 'line2', 'city', 'state', 'postalCode', 'country', 'latitude', 'longitude', 'text'];

  for (const key of allowedKeys) {
    if (key in address) {
      const value = address[key];
      if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
        sanitized[key] = value;
      }
    }
  }

  return sanitized;
}

/**
 * Send notification to admins about new booking
 */
async function sendAdminNotification(bookingId: string, title: string) {
  try {
    const adminsSnapshot = await db.collection('admins').limit(10).get();
    for (const adminDoc of adminsSnapshot.docs) {
      const adminData = adminDoc.data();
      if (adminData?.fcmToken) {
        await db.collection('notifications').add({
          userId: adminDoc.id,
          title,
          body: `New booking #${bookingId} requires approval`,
          type: 'booking_pending_approval',
          bookingId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
  } catch (error) {
    console.error('[BOOKING] Error sending admin notification:', error);
  }
}
