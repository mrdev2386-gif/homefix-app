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
import { updateBookingStatus } from '../shared/status_history_tracker';

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
export const approveBookingByAdmin = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
        console.log('✅ [approveBookingByAdmin] Auth UID:', context.auth?.uid);
        
        const { bookingId } = data;
        const uid = context.auth?.uid;

        if (!uid) {
          console.error('❌ [approveBookingByAdmin] context.auth is NULL');
          throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        }
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

        await db.runTransaction(async (t) => {
            const freshDoc = await t.get(bookingRef);
            if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
            const freshBooking = freshDoc.data()!;
            updateBookingStatus(t, bookingRef, 'approved_by_admin', freshBooking, {
                bookingStatus: 'approved_by_admin',
                approvedAt: admin.firestore.FieldValue.serverTimestamp(),
                approvedBy: uid,
            });
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
export const technicianAcceptBooking = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
        console.log('✅ [technicianAcceptBooking] Auth UID:', context.auth?.uid);
        
        const { bookingId } = data;
        const uid = context.auth?.uid;

        if (!uid) {
          console.error('❌ [technicianAcceptBooking] context.auth is NULL');
          throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        }
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

        await db.runTransaction(async (t) => {
            const freshDoc = await t.get(bookingRef);
            if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
            const freshBooking = freshDoc.data()!;
            updateBookingStatus(t, bookingRef, 'technician_accepted', freshBooking, {
                bookingStatus: 'technician_accepted',
                acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
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
export const startService = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
        console.log('✅ [startService] Auth UID:', context.auth?.uid);
        
        const { bookingId } = data;
        const uid = context.auth?.uid;

        if (!uid) {
          console.error('❌ [startService] context.auth is NULL');
          throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        }
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

        await db.runTransaction(async (t) => {
            const freshDoc = await t.get(bookingRef);
            if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
            const freshBooking = freshDoc.data()!;
            updateBookingStatus(t, bookingRef, 'service_in_progress', freshBooking, {
                bookingStatus: 'service_in_progress',
                serviceStartedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
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
export const completeService = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
        console.log('✅ [completeService] Auth UID:', context.auth?.uid);
        
        const { bookingId } = data;
        const uid = context.auth?.uid;

        if (!uid) {
          console.error('❌ [completeService] context.auth is NULL');
          throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        }
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

        await db.runTransaction(async (t) => {
            const freshDoc = await t.get(bookingRef);
            if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
            const freshBooking = freshDoc.data()!;
            updateBookingStatus(t, bookingRef, 'service_completed', freshBooking, {
                bookingStatus: 'service_completed',
                serviceCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
                paymentStatus: 'pending',
            });
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
export const technicianRejectBooking = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
        console.log('✅ [technicianRejectBooking] Auth UID:', context.auth?.uid);
        
        const { bookingId, reason } = data;
        const uid = context.auth?.uid;

        if (!uid) {
          console.error('❌ [technicianRejectBooking] context.auth is NULL');
          throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        }
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

        await db.runTransaction(async (t) => {
            const freshDoc = await t.get(bookingRef);
            if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
            const freshBooking = freshDoc.data()!;
            updateBookingStatus(t, bookingRef, 'technician_rejected', freshBooking, {
                bookingStatus: 'technician_rejected',
                rejectedBy: uid,
                rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
                rejectionReason: sanitize(reason) || 'Technician unavailable',
            });
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
export const cancelBooking = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
        console.log('✅ [cancelBooking] Auth UID:', context.auth?.uid);
        
        const { bookingId, reason } = data;
        const uid = context.auth?.uid;

        if (!uid) {
          console.error('❌ [cancelBooking] context.auth is NULL');
          throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        }
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

        await db.runTransaction(async (t) => {
            const freshDoc = await t.get(bookingRef);
            if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
            const freshBooking = freshDoc.data()!;
            updateBookingStatus(t, bookingRef, 'cancelled', freshBooking, {
                bookingStatus: 'cancelled',
                cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
                cancelledBy: uid,
                cancellationReason: sanitize(reason) || 'No reason provided',
            });
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
export const createBookingRequest = functions
  .region('asia-south1')
  .https.onCall(
  secureCallable(async (data, context) => {
    try {
      // 1. App Check: warn but never block
      if (!context.app) {
        console.warn('⚠️ [createBookingRequest] App Check token missing - allowing request (non-enforced)');
      }

      console.log('✅ [createBookingRequest] Auth UID:', context.auth?.uid);
      console.log('📦 [createBookingRequest] INPUT DATA:', JSON.stringify(data));
      
      const uid = context.auth?.uid;
      if (!uid) {
        console.error('❌ [createBookingRequest] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
      }

    // PHASE 3: Rate Limiting (non-fatal - log and continue if it fails)
    try {
      const rateLimit = await checkBookingRateLimit(uid);
      if (!rateLimit.allowed) {
        throw new functions.https.HttpsError(
          'resource-exhausted',
          rateLimit.error || 'Too many booking requests. Please try later.'
        );
      }
    } catch (rateLimitError: any) {
      if (rateLimitError instanceof functions.https.HttpsError) throw rateLimitError;
      console.warn('⚠️ [createBookingRequest] Rate limit check failed (non-fatal):', rateLimitError.message);
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
        price,
      } = data;

      console.log('🔍 [createBookingRequest] Validating inputs...');
      
      if (!serviceId || typeof serviceId !== 'string') {
        console.error('❌ [createBookingRequest] Invalid serviceId:', serviceId);
        throw new functions.https.HttpsError('invalid-argument', 'serviceId is required and must be a string');
      }
      if (!technicianId || typeof technicianId !== 'string') {
        console.error('❌ [createBookingRequest] Invalid technicianId:', technicianId);
        throw new functions.https.HttpsError('invalid-argument', 'technicianId is required and must be a string');
      }
      if (!categoryId) {
        console.error('❌ [createBookingRequest] Missing categoryId');
        throw new functions.https.HttpsError('invalid-argument', 'categoryId is required');
      }
      if (!scheduledDate) {
        console.error('❌ [createBookingRequest] Missing scheduledDate');
        throw new functions.https.HttpsError('invalid-argument', 'scheduledDate is required');
      }
      if (!scheduledTime) {
        console.error('❌ [createBookingRequest] Missing scheduledTime');
        throw new functions.https.HttpsError('invalid-argument', 'scheduledTime is required');
      }
      if (!address || typeof address !== 'object') {
        console.warn('⚠️ [createBookingRequest] address missing or invalid - using empty object');
        // Do NOT throw - address is sanitized below, empty is acceptable
      }
      if (price !== undefined && (typeof price !== 'number' || price <= 0)) {
        console.error('❌ [createBookingRequest] Invalid price:', price);
        throw new functions.https.HttpsError('invalid-argument', 'price must be a positive number');
      }
      if (paymentMode && !['before_work', 'after_work', 'pay_before_work', 'pay_after_work'].includes(paymentMode)) {
        console.error('❌ [createBookingRequest] Invalid paymentMode:', paymentMode);
        throw new functions.https.HttpsError('invalid-argument', 'paymentMode must be either "before_work" or "after_work"');
      }
      
      console.log('✅ [createBookingRequest] Input validation passed');

      console.log('🔍 [createBookingRequest] Fetching customer profile...');
      const customerDoc = await db.collection('customers').doc(uid).get();
      if (!customerDoc.exists) {
        console.error('❌ [createBookingRequest] Customer not found:', uid);
        throw new functions.https.HttpsError('not-found', 'Customer profile not found. Please complete your profile first.');
      }
      console.log('✅ [createBookingRequest] Customer found:', customerDoc.data()?.name);

      // PHASE 1: Fix Price Manipulation
      // Fetch actual price from source of truth (technician_services)
      console.log('🔍 [createBookingRequest] Fetching service data...');
      const serviceDoc = await db.collection('technician_services').doc(serviceId).get();
      if (!serviceDoc.exists) {
        console.error('❌ [createBookingRequest] Service not found:', serviceId);
        throw new functions.https.HttpsError('not-found', `Service listing not found: ${serviceId}`);
      }

      const serviceData = serviceDoc.data()!;
      console.log('📦 [createBookingRequest] Service data:', { name: serviceData.name, price: serviceData.price, technicianId: serviceData.technicianId });
      
      if (serviceData.technicianId !== technicianId) {
        console.error('❌ [createBookingRequest] Technician mismatch. Expected:', serviceData.technicianId, 'Got:', technicianId);
        throw new functions.https.HttpsError('invalid-argument', 'Service does not belong to the selected technician');
      }

      // ENFORCE Database Price (use client price if service price is missing)
      const basePrice = serviceData.price || price || 0;
      if (typeof basePrice !== 'number' || basePrice <= 0) {
        console.error('❌ [createBookingRequest] Invalid price. Service price:', serviceData.price, 'Client price:', price);
        throw new functions.https.HttpsError('internal', 'Invalid service price configuration. Please contact support.');
      }
      console.log('✅ [createBookingRequest] Using price:', basePrice);

      console.log('🔍 [createBookingRequest] Fetching technician data...');
      const techDoc = await db.collection('technicians').doc(technicianId).get();
      if (!techDoc.exists) {
        console.error('❌ [createBookingRequest] Technician not found:', technicianId);
        throw new functions.https.HttpsError('not-found', `Technician not found: ${technicianId}`);
      }

      const techData = techDoc.data()!;
      console.log('📦 [createBookingRequest] Technician data:', { name: techData.name, status: techData.status, verificationStatus: techData.verificationStatus });
      
      if (techData.verificationStatus !== 'approved' && techData.status !== 'approved') {
        console.error('❌ [createBookingRequest] Technician not verified. Status:', techData.status, 'Verification:', techData.verificationStatus);
        throw new functions.https.HttpsError('failed-precondition', 'Technician is not verified. Please select another technician.');
      }
      console.log('✅ [createBookingRequest] Technician verified');

      const finalIdempotencyKey = idempotencyKey || `BK_${uid}_${Date.now()}`;
      const bookingId = db.collection('bookings').doc().id;
      
      console.log('🔑 [createBookingRequest] Idempotency key:', finalIdempotencyKey);
      console.log('🆔 [createBookingRequest] Generated booking ID:', bookingId);

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
          paymentMode: paymentMode || 'after_work',
          bookingStatus: 'pending',
          status: 'pending',
          // INITIALIZE STATUS HISTORY
          statusHistory: [
            {
              status: 'pending',
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            },
          ],
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
        console.log(`💾 [createBookingRequest] Writing booking to Firestore: ${bookingId}`);
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

        console.log(`✅ [BOOKING] Created booking: ${bookingId} for customer: ${uid} with price: ${basePrice}`);
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
        console.error(`❌ [BOOKING] Transaction error:`, error);
        console.error(`❌ [BOOKING] Error stack:`, error.stack);
        throw new functions.https.HttpsError('internal', error.message || 'Transaction failed');
      }
    } catch (error: any) {
      console.error('FINAL ERROR:', error);
      console.error('STACK:', error?.stack);
      console.error('INPUT:', data);
      
      // Re-throw HttpsError as-is
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      // Wrap unexpected errors with real message
      throw new functions.https.HttpsError('internal', error.message || 'Unknown error');
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
    console.warn('[sanitizeAddress] Invalid address object, returning empty');
    return {};
  }

  const sanitized: Record<string, any> = {};
  const allowedKeys = [
    'line1', 'line2', 'city', 'state', 'postalCode', 'country', 
    'latitude', 'longitude', 'text', 'fullAddress', 'landmark',
    'name', 'phone', 'label', 'district', 'pincode'
  ];

  for (const key of allowedKeys) {
    if (key in address) {
      const value = address[key];
      if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
        sanitized[key] = value;
      }
    }
  }
  
  // If no keys were sanitized, copy all primitive values
  if (Object.keys(sanitized).length === 0) {
    for (const [key, value] of Object.entries(address)) {
      if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
        sanitized[key] = value;
      }
    }
  }

  console.log('[sanitizeAddress] Sanitized address keys:', Object.keys(sanitized));
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
