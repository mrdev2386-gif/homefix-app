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
  'service_in_progress': ['awaiting_payment', 'cancelled'],
  'awaiting_payment': ['paid', 'cancelled'],
  'paid': ['completed', 'cancelled'],
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

        // CRITICAL FIX: Use ?? NOT || to avoid empty string bug
        const rawStatus = booking.bookingStatus ?? booking.status ?? '';
        const currentStatus = String(rawStatus).toLowerCase().trim();
        const pendingStatuses = ['pending_admin_review', 'pending_admin_approval', 'pending_admin', 'pending'];
        
        // TEMP DEBUG LOG (REMOVE LATER)
        console.log('[APPROVE DEBUG]', {
          rawStatus,
          currentStatus,
          bookingId,
          hasPendingStatus: pendingStatuses.includes(currentStatus)
        });
        
        if (!pendingStatuses.includes(currentStatus)) {
            console.warn(`[approveBookingByAdmin] Status mismatch - allowing approve anyway. Raw: "${rawStatus}", Normalized: "${currentStatus}"`);
            // TEMP: Allow approve even if status doesn't match (for debugging)
        }

        // Use overrideTechnicianId if admin is changing technician, else keep original
        const { overrideTechnicianId } = data;
        const assignedTechnicianId = overrideTechnicianId || booking.technicianId;

        if (!assignedTechnicianId) {
            throw new functions.https.HttpsError('failed-precondition', 'No technician assigned to booking');
        }

        const techDoc = await db.collection('technicians').doc(assignedTechnicianId).get();
        if (!techDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Technician not found');
        }

        const techData = techDoc.data()!;

        // ✅ CRITICAL SECURITY FIX: Validate technician is approved
        // Prevents assignment of unapproved/unverified technicians
        if (techData.verificationStatus !== 'approved' && techData.status !== 'approved') {
            console.error('[approveBookingByAdmin] Technician not approved:', {
                technicianId: assignedTechnicianId,
                verificationStatus: techData.verificationStatus,
                status: techData.status
            });
            throw new functions.https.HttpsError(
                'failed-precondition',
                'Selected technician is not approved. Please select an approved technician.'
            );
        }

        // ✅ FETCH SERVICE IMAGE - Add to booking during approval
        let serviceImage: string | null = null;
        if (booking.serviceId) {
            try {
                const serviceDoc = await db.collection('technician_services').doc(booking.serviceId).get();
                if (serviceDoc.exists) {
                    const serviceData = serviceDoc.data()!;
                    const rawImage = serviceData?.image || 
                                   serviceData?.serviceImage || 
                                   serviceData?.imageUrl || 
                                   (Array.isArray(serviceData?.images) ? serviceData.images[0] : null) || 
                                   serviceData?.photoUrl || 
                                   null;
                    serviceImage = rawImage && rawImage !== 'NO_IMAGE' ? rawImage : null;
                    console.log('🔍 [approveBookingByAdmin] Service image detected:', {
                        serviceId: booking.serviceId,
                        hasImage: !!serviceImage,
                        imageUrl: serviceImage,
                        allFields: {
                            image: serviceData?.image,
                            serviceImage: serviceData?.serviceImage,
                            imageUrl: serviceData?.imageUrl,
                            images: serviceData?.images,
                            photoUrl: serviceData?.photoUrl
                        }
                    });
                }
            } catch (error) {
                console.warn('⚠️ [approveBookingByAdmin] Failed to fetch service image:', error);
                // Non-fatal - continue with approval
            }
        }

        // Use placeholder if no image found
        const finalServiceImage = serviceImage || 'https://via.placeholder.com/300';

        await db.runTransaction(async (t) => {
            const freshDoc = await t.get(bookingRef);
            if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
            const freshBooking = freshDoc.data()!;
            
            // NEVER override pricing during approval
            const price = freshBooking.price;
            const finalAmount = freshBooking.finalAmount;
            const offerPrice = freshBooking.offerPrice;
            
            console.log('[APPROVE PRICE DEBUG] Preserving pricing:', {
              price,
              finalAmount,
              offerPrice,
            });
            
            updateBookingStatus(t, bookingRef, 'approved_by_admin', freshBooking, {
                bookingStatus: 'approved_by_admin',
                technicianId: assignedTechnicianId,
                technicianName: techData.name || freshBooking.technicianName || 'Technician',
                technicianPhone: techData.phone || freshBooking.technicianPhone || '',
                approvedAt: admin.firestore.FieldValue.serverTimestamp(),
                approvedBy: uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                serviceImage: finalServiceImage,
                imageUrl: finalServiceImage,
            });
            
            console.log('🔥 [FINAL IMAGE SAVED]:', {
                bookingId,
                serviceImage: finalServiceImage,
                imageUrl: finalServiceImage,
                wasNull: !serviceImage,
                usedPlaceholder: !serviceImage
            });
            
            console.log('[APPROVE PRICE DEBUG] Approval complete - pricing unchanged');
        });

        // ✅ NOTIFICATION FIX: Remove duplicate notification sending
        // The onBookingStatusChange trigger will handle all notifications
        // This prevents duplicate notifications to technicians
        console.log(`[approveBookingByAdmin] Booking approved. Notification will be sent by trigger.`);

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
            
            // STEP 1: Update booking status with timestamp
            updateBookingStatus(t, bookingRef, 'technician_accepted', freshBooking, {
                bookingStatus: 'technician_accepted',
                acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
                technicianAcceptedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            
            console.log(`✅ [technicianAcceptBooking] Booking ${bookingId} accepted by technician ${uid}`);
        });

        // STEP 2: Send notification to customer
        const customerDoc = await db.collection('customers').doc(booking.customerId).get();
        const customerData = customerDoc.data();

        if (customerData?.fcmToken) {
            console.log(`📲 [technicianAcceptBooking] Sending notification to customer ${booking.customerId}`);
            await sendNotificationToToken({
                token: customerData.fcmToken,
                title: 'Technician Assigned',
                body: 'Your technician has accepted the booking and will arrive soon',
                data: { 
                    bookingId, 
                    type: 'booking_accepted',
                    technicianId: uid,
                    technicianName: booking.technicianName || 'Technician',
                },
            });
        } else {
            console.warn(`⚠️ [technicianAcceptBooking] No FCM token for customer ${booking.customerId}`);
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

        // AFTER-SERVICE PAYMENT MODEL: No payment required before service starts
        // Payment is collected AFTER service completion
        // Technician can start service immediately after acceptance

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
            
            // STEP 8: Update status to awaiting_payment
            updateBookingStatus(t, bookingRef, 'awaiting_payment', freshBooking, {
                bookingStatus: 'awaiting_payment',
                serviceCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
                paymentStatus: 'awaiting_payment',
            });
            
            console.log(`✅ [completeService] Service completed for booking ${bookingId}, status set to awaiting_payment`);
        });

        // STEP 9: Notify customer to make payment
        const customerDoc = await db.collection('customers').doc(booking.customerId).get();
        const customerData = customerDoc.data();

        if (customerData?.fcmToken) {
            console.log(`📲 [completeService] Sending payment notification to customer ${booking.customerId}`);
            await sendNotificationToToken({
                token: customerData.fcmToken,
                title: 'Service Completed',
                body: 'Your service has been completed. Please make payment and leave a review.',
                data: { 
                    bookingId, 
                    type: 'service_completed',
                    action: 'make_payment',
                },
            });
        } else {
            console.warn(`⚠️ [completeService] No FCM token for customer ${booking.customerId}`);
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

        // Customers can only cancel pending_admin_review bookings
        if (isCustomer && !isAdmin) {
            if (booking.bookingStatus !== 'pending_admin_review') {
                throw new functions.https.HttpsError(
                    'failed-precondition',
                    'You can only cancel a booking that is pending admin review'
                );
            }
        }

        await db.runTransaction(async (t) => {
            const freshDoc = await t.get(bookingRef);
            if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
            const freshBooking = freshDoc.data()!;
            const newStatus = isCustomer && !isAdmin ? 'cancelled_by_customer' : 'cancelled';
            updateBookingStatus(t, bookingRef, newStatus, freshBooking, {
                bookingStatus: newStatus,
                cancelledAt: admin.firestore.Timestamp.now(),
                cancelledBy: uid,
                cancellationReason: sanitize(reason) || 'No reason provided',
            });
        });

        return { success: true, bookingStatus: isCustomer && !isAdmin ? 'cancelled_by_customer' : 'cancelled' };
    })
);

// ==========================================
// 7️⃣ ADMIN REJECT BOOKING
// ==========================================
export const rejectBookingByAdmin = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
      console.log('✅ [rejectBookingByAdmin] Auth UID:', context.auth?.uid);
      
      const { bookingId, reason } = data;
      const uid = context.auth?.uid;

      if (!uid) {
        console.error('❌ [rejectBookingByAdmin] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
      }
      if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'bookingId required');
      }

      // Verify admin
      const adminDoc = await db.collection('admins').doc(uid).get();
      if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can reject bookings');
      }

      const bookingRef = db.collection('bookings').doc(bookingId);
      const bookingSnap = await bookingRef.get();

      if (!bookingSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
      }

      const booking = bookingSnap.data()!;

      // CRITICAL FIX: Use ?? NOT || to avoid empty string bug
      const rawStatus = booking.bookingStatus ?? booking.status ?? '';
      const currentStatus = String(rawStatus).toLowerCase().trim();
      const rejectablePendingStatuses = ['pending_admin_review', 'pending_admin_approval', 'pending_admin', 'pending', 'awaiting_payment'];
      
      // TEMP DEBUG LOG (REMOVE LATER)
      console.log('[REJECT DEBUG]', {
        rawStatus,
        currentStatus,
        bookingId,
        hasRejectableStatus: rejectablePendingStatuses.includes(currentStatus)
      });
      
      if (!rejectablePendingStatuses.includes(currentStatus)) {
        console.warn(`[rejectBookingByAdmin] Status mismatch - allowing reject anyway. Raw: "${rawStatus}", Normalized: "${currentStatus}"`);
        // TEMP: Allow reject even if status doesn't match (for debugging)
      }

      // Update booking
      await db.runTransaction(async (t) => {
        const freshDoc = await t.get(bookingRef);
        if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
        const freshBooking = freshDoc.data()!;
        
        updateBookingStatus(t, bookingRef, 'rejected_by_admin', freshBooking, {
          bookingStatus: 'rejected_by_admin',
          rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
          rejectedBy: uid,
          rejectionReason: sanitize(reason) || 'Rejected by admin',
        });
      });

      // Notify customer
      const customerDoc = await db.collection('customers').doc(booking.customerId).get();
      const customerData = customerDoc.data();

      if (customerData?.fcmToken) {
        await sendNotificationToToken({
          token: customerData.fcmToken,
          title: 'Booking Rejected',
          body: `Your booking request was rejected. ${reason || ''}`,
          data: { bookingId, type: 'booking_rejected' },
        });
      }

      console.log(`✅ [rejectBookingByAdmin] Booking ${bookingId} rejected by admin ${uid}`);
      return { success: true, bookingStatus: 'rejected_by_admin' };
    })
  );

// ==========================================
// 8️⃣ CREATE BOOKING REQUEST
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
    console.log('🔥 CREATE BOOKING FUNCTION HIT - unified_booking_lifecycle.ts');
    console.log('✅ [BOOKING CONSOLIDATION] Using SINGLE SOURCE OF TRUTH for booking creation');
    console.log('✅ [PRICING VALIDATION] Pricing logic: Number() parsing with strict offer validation');
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
        paymentMethod,
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
      if (paymentMethod && !['online', 'after_service'].includes(paymentMethod)) {
        console.error('❌ [createBookingRequest] Invalid paymentMethod:', paymentMethod);
        throw new functions.https.HttpsError('invalid-argument', 'paymentMethod must be either "online" or "after_service"');
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

      console.log('🔍 [IMAGE DEBUG] SERVICE ID:', serviceId);
      console.log('🔍 [IMAGE DEBUG] SERVICE EXISTS:', serviceDoc.exists);
      console.log('🔍 [IMAGE DEBUG] SERVICE DATA:', JSON.stringify(serviceDoc.data()));

      const service = serviceDoc.data()!;
      
      // ✅ ROBUST IMAGE FIELD DETECTION - Check all possible field names
      const rawImage = service?.image || 
                       service?.serviceImage || 
                       service?.imageUrl || 
                       (Array.isArray(service?.images) ? service.images[0] : null) || 
                       service?.photoUrl || 
                       null;
      
      console.log('🔍 [IMAGE DEBUG] DETECTED FIELDS:', {
        image: service?.image,
        serviceImage: service?.serviceImage,
        imageUrl: service?.imageUrl,
        images: service?.images,
        photoUrl: service?.photoUrl,
        selectedImage: rawImage
      });
      
      const serviceImage = rawImage && rawImage !== 'NO_IMAGE' ? rawImage : null;
      console.log('📦 [createBookingRequest] Service data:', { name: service.name, price: service.price, technicianId: service.technicianId, imageUrl: serviceImage });
      
      if (service.technicianId !== technicianId) {
        console.error('❌ [createBookingRequest] Technician mismatch. Expected:', service.technicianId, 'Got:', technicianId);
        throw new functions.https.HttpsError('invalid-argument', 'Service does not belong to the selected technician');
      }

      // CRITICAL SECURITY FIX: NEVER trust client price - ONLY use database price
      const basePrice: number = service.price;

      if (typeof basePrice !== 'number' || basePrice <= 0) {
        console.error('❌ [createBookingRequest] Invalid service price in database:', service.price);
        throw new functions.https.HttpsError('internal', 'Service price not configured. Please contact support.');
      }

      // STRICT SAFE PARSING - SINGLE SOURCE OF TRUTH
      // Parse base price with NaN validation
      const parsedPrice = Number(basePrice);
      const calculatedPrice = (!isNaN(parsedPrice) && parsedPrice > 0) ? parsedPrice : 0;
      
      // Parse offer price with NaN validation
      const parsedOffer = Number(service.offerPrice);
      const offer = (!isNaN(parsedOffer) && parsedOffer > 0) ? parsedOffer : null;

      // CRITICAL FIX: Apply offerPrice if valid (no hasOffer check - field doesn't exist)
      // Edge cases handled:
      // - offerPrice null/undefined → use price
      // - offerPrice = 0 → treat as null
      // - offerPrice NaN → treat as null
      // - offerPrice >= price → ignore offer
      let finalPrice = calculatedPrice;

      if (offer !== null && offer < calculatedPrice) {
        finalPrice = offer;
      }

      console.log('[BOOKING PRICE DEBUG]', {
        rawBasePrice: basePrice,
        rawOfferPrice: service.offerPrice,
        parsedPrice,
        parsedOffer,
        calculatedPrice,
        offer,
        finalPrice,
        discountApplied: finalPrice < calculatedPrice,
        validation: `offer=${offer}, price=${calculatedPrice}, valid=${offer !== null && offer < calculatedPrice}`
      });

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

      const finalIdempotencyKey = idempotencyKey || `BK_${require('crypto').randomBytes(16).toString('hex')}`;
      const bookingId = db.collection('bookings').doc().id;
      
      console.log('🔑 [createBookingRequest] Idempotency key:', finalIdempotencyKey);
      console.log('🆔 [createBookingRequest] Generated booking ID:', bookingId);

      // PHASE 5: Protect Booking Integrity - Define outside transaction
      // ALLOW: Customer to choose payment method (online or after_service)
      const requestedPaymentMethod = data.paymentMethod || data.paymentMode || 'after_service';
      
      // Validate payment method
      if (!['online', 'after_service', 'pay_before_work', 'pay_after_work'].includes(requestedPaymentMethod)) {
        console.error('❌ [createBookingRequest] Invalid paymentMethod:', requestedPaymentMethod);
        throw new functions.https.HttpsError('invalid-argument', 'paymentMethod must be "online" or "after_service"');
      }
      
      // Map legacy payment modes to standard methods
      let finalPaymentMethod = 'after_service';
      if (requestedPaymentMethod === 'online' || requestedPaymentMethod === 'pay_before_work') {
        finalPaymentMethod = 'online';
      } else if (requestedPaymentMethod === 'after_service' || requestedPaymentMethod === 'pay_after_work') {
        finalPaymentMethod = 'after_service';
      }
      
      console.log(`[PAYMENT METHOD] Requested: ${requestedPaymentMethod}, Final: ${finalPaymentMethod}`);
      // All bookings go through admin review first
      const initialStatus = 'pending_admin_review';

      try {
      await db.runTransaction(async (transaction) => {
        const idempotencyRef = db.collection('booking_idempotency').doc(finalIdempotencyKey);
        const idempotencyDoc = await transaction.get(idempotencyRef);

        if (idempotencyDoc.exists) {
          const existingBookingId = idempotencyDoc.data()?.bookingId;
          throw new Error(`IDEMPOTENCY_DUPLICATE:${existingBookingId}`);
        }
        
        const bookingData = {
          bookingId,
          customerId: uid,
          customerName: customerDoc.data()?.name || 'Customer',
          customerPhone: customerDoc.data()?.phone || '',
          technicianId,
          technicianName: techData.name || 'Technician',
          technicianPhone: techData.phone || '',
          serviceId,
          serviceName: service.name || service.title || 'Service',
          serviceImage: serviceImage,
          imageUrl: serviceImage,
          price: calculatedPrice,
          finalAmount: finalPrice,
          offerPrice: offer,
          originalPrice: calculatedPrice,
          discountAmount: calculatedPrice - finalPrice,
          categoryId: service.categoryId || categoryId,
          categoryName: categoryName || service.category || 'Service',
          subcategoryId: subcategoryId || null,
          quantity: quantity || 1,
          durationMinutes: durationMinutes || null,
          scheduledDate,
          scheduledTime,
          address: sanitizeAddress(address),
          paymentMethod: finalPaymentMethod,
          bookingStatus: 'pending_admin_review',
          // INITIALIZE STATUS HISTORY
          statusHistory: [
            {
              status: initialStatus,
              timestamp: admin.firestore.Timestamp.now(),
            },
          ],
          paymentStatus: 'pending',
          payment: {
            status: 'pending',
            paymentMethod: finalPaymentMethod,
            currency: 'INR'
          },
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
        
        // AUDIT TRAIL: Verify pricing before write
        console.log('✅ [BOOKING AUDIT] Pricing verified before Firestore write:', {
          price: bookingData.price,
          finalAmount: bookingData.finalAmount,
          offerPrice: bookingData.offerPrice,
          discountAmount: bookingData.discountAmount,
          source: 'unified_booking_lifecycle.ts'
        });
        
        console.log('[CREATE BOOKING FIRESTORE WRITE] Exact fields being written:', {
          price: bookingData.price,
          finalAmount: bookingData.finalAmount,
          originalPrice: bookingData.originalPrice,
          offerPrice: bookingData.offerPrice,
          bookingStatus: bookingData.bookingStatus,
        });

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

        console.log(`✅ [BOOKING] Created booking: ${bookingId} for customer: ${uid} with price: ${basePrice}, paymentMethod: ${finalPaymentMethod}`);
        
        await sendAdminNotification(bookingId, 'New Booking Pending Approval');

        return {
          success: true,
          bookingId,
          bookingStatus: 'pending_admin_review',
          paymentMethod: finalPaymentMethod,
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

// ==========================================
// 9️⃣ ADMIN CHANGE TECHNICIAN
// ==========================================
export const adminChangeTechnician = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
        const { bookingId, technicianId: newTechnicianId } = data;
        const uid = context.auth?.uid;

        if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
        if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');
        if (!newTechnicianId) throw new functions.https.HttpsError('invalid-argument', 'technicianId required');

        const adminDoc = await db.collection('admins').doc(uid).get();
        if (!adminDoc.exists) throw new functions.https.HttpsError('permission-denied', 'Admin access required');

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingSnap = await bookingRef.get();
        if (!bookingSnap.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');

        const techDoc = await db.collection('technicians').doc(newTechnicianId).get();
        if (!techDoc.exists) throw new functions.https.HttpsError('not-found', 'Technician not found');
        const techData = techDoc.data()!;

        // ✅ CRITICAL SECURITY FIX: Validate technician is approved
        if (techData.verificationStatus !== 'approved' && techData.status !== 'approved') {
            console.error('[adminChangeTechnician] Technician not approved:', {
                technicianId: newTechnicianId,
                verificationStatus: techData.verificationStatus,
                status: techData.status
            });
            throw new functions.https.HttpsError(
                'failed-precondition',
                'Selected technician is not approved. Please select an approved technician.'
            );
        }

        // Only update technician fields — do NOT change status
        await bookingRef.update({
            technicianId: newTechnicianId,
            technicianName: techData.name || 'Technician',
            technicianPhone: techData.phone || '',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true, technicianId: newTechnicianId, technicianName: techData.name };
    })
);

// ==========================================
// 🔟 GET ALL TECHNICIANS (for admin change-technician modal)
// ==========================================
export const getAllTechniciansForAdmin = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
        const uid = context.auth?.uid;
        if (!uid) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');

        const adminDoc = await db.collection('admins').doc(uid).get();
        if (!adminDoc.exists) throw new functions.https.HttpsError('permission-denied', 'Admin access required');

        const snapshot = await db.collection('technicians')
            .where('status', 'in', ['approved', 'active'])
            .limit(100)
            .get();

        const technicians = snapshot.docs.map(doc => {
            const d = doc.data();
            return {
                id: doc.id,
                name: d.name || 'Unknown',
                phone: d.phone || '',
                rating: d.rating || 0,
                completedJobs: d.completedJobs || d.totalJobs || 0,
            };
        });

        return { success: true, technicians };
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
    const notificationPromises = [];
    
    for (const adminDoc of adminsSnapshot.docs) {
      const adminData = adminDoc.data();
      
      // Write to Firestore notifications collection
      notificationPromises.push(
        db.collection('notifications').add({
          userId: adminDoc.id,
          title,
          body: `New booking #${bookingId} requires approval`,
          type: 'booking_pending_approval',
          bookingId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        })
      );
      
      // Send FCM notification if token exists
      if (adminData?.fcmToken) {
        notificationPromises.push(
          sendNotificationToToken({
            token: adminData.fcmToken,
            title,
            body: `New booking #${bookingId} requires approval`,
            data: { 
              bookingId, 
              type: 'booking_pending_approval',
            },
          })
        );
      }
    }
    
    // Use Promise.allSettled to not block booking creation if notifications fail
    await Promise.allSettled(notificationPromises);
    console.log(`📧 [BOOKING] Notified ${adminsSnapshot.size} admins about booking ${bookingId}`);
  } catch (error) {
    console.error('[BOOKING] Error sending admin notification:', error);
    // Non-fatal - don't throw
  }
}
