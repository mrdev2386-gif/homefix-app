import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendUserNotification } from '../shared/notification_helper';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * BOOKING STATUS CHANGE TRIGGER
 * Detects status updates and sends appropriate notifications
 */
export const onBookingStatusChange = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const bookingId = context.params.bookingId;
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return;

    const previousStatus = before.bookingStatus || before.status;
    const newStatus = after.bookingStatus || after.status;
    const customerId = after.customerId;
    const technicianId = after.technicianId;

    // Only trigger if status actually changed
    if (previousStatus === newStatus) return;

    try {
      console.log(`[BOOKING NOTIFICATION] Status change: ${previousStatus} → ${newStatus}`);

      // ================================================
      // STATUS: approved_by_admin (SINGLE SOURCE OF TRUTH)
      // ================================================
      // Set by: Admin (when admin approves booking)
      // Transitions from: pending_admin_review → approved_by_admin
      // 
      // ✅ CONSOLIDATED: Only check for 'approved_by_admin' (the actual status used)
      // Removed legacy status checks: 'ASSIGNED', 'admin_approved'
      if (newStatus === 'approved_by_admin') {
        await handleAdminApproved(customerId, technicianId, bookingId, after);
      }

      // ================================================
      // STATUS: technicianAccepted
      // ================================================
      // Set by: Technician (when they accept the job)
      if (newStatus === 'technician_accepted' || newStatus === 'technicianAccepted') {
        await handleTechnicianAccepted(customerId, technicianId, bookingId, after);
      }

      // ================================================
      // STATUS: technicianArrived
      // ================================================
      // Set by: Technician (when they arrive at location)
      if (newStatus === 'technician_arrived' || newStatus === 'technicianArrived') {
        await handleTechnicianArrived(customerId, bookingId, after);
      }

      // ================================================
      // STATUS: workStarted
      // ================================================
      // Set by: Technician (when work begins)
      if (newStatus === 'service_in_progress' || newStatus === 'work_started' || newStatus === 'workStarted') {
        await handleWorkStarted(customerId, bookingId, after);
      }

      if (newStatus === 'service_completed' || newStatus === 'completed') {
        await handleCompleted(customerId, technicianId, bookingId, after);
      }

      // ================================================
      // STATUS: cancelled
      // ================================================
      // Set by: Customer, Technician, or System
      if (newStatus === 'cancelled' && previousStatus !== 'cancelled') {
        await handleCancelled(customerId, technicianId, bookingId, after);
      }

      // ================================================
      // STATUS: paid_escrow (Pay Before Work)
      // ================================================
      if (newStatus === 'paid_escrow' || after.paymentStatus === 'paid_escrow') {
        // Notify customer about payment confirmation
        await sendUserNotification({
          userId: customerId,
          userType: 'customer',
          title: '💳 Payment Confirmed!',
          body: 'Your payment has been received. Technician will arrive soon.',
          type: 'payment_success',
          data: { bookingId, screen: 'booking_details' },
          priority: 'high',
        }).catch(err => console.error('[BOOKING] Payment confirmation notification failed:', err));

        // Notify technician about payment received
        if (technicianId) {
          await sendUserNotification({
            userId: technicianId,
            userType: 'technician',
            title: '💰 Payment Received!',
            body: `Payment confirmed for booking #${bookingId.substring(0, 6)}. You can now proceed.`,
            type: 'payment_received',
            data: { bookingId, screen: 'booking_details' },
            priority: 'high',
          }).catch(err => console.error('[BOOKING] Technician payment notification failed:', err));
        }
      }

      // ================================================
      // STATUS: awaiting_customer_payment (Pay After Work)
      // ================================================
      if (newStatus === 'awaiting_customer_payment') {
        await sendUserNotification({
          userId: customerId,
          userType: 'customer',
          title: '🛠️ Service Finished!',
          body: 'Technician has finished work. Please show your QR code to complete payment.',
          type: 'job_completed',
          data: { bookingId, screen: 'payment_qr' },
          priority: 'high'
        }).catch(err => console.error('[BOOKING] Payment notification failed:', err));
      }

      console.log(`[BOOKING NOTIFICATION] ✅ All notifications sent for booking: ${bookingId}`);
    } catch (error) {
      console.error(`[BOOKING NOTIFICATION] ❌ Error for booking ${bookingId}:`, error);
      // Track notification failure
      await db.collection('notification_failures').add({
        bookingId,
        error: error instanceof Error ? error.message : String(error),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      }).catch(err => console.error('[BOOKING] Failed to log notification error:', err));
      // Don't fail the function - notifications are best-effort
    }
  });

// ================================================
// HANDLER: Admin Approved
// ================================================
async function handleAdminApproved(
  customerId: string,
  technicianId: string,
  bookingId: string,
  booking: any
) {
  // Fetch booking details for better messaging
  const serviceName = booking.serviceName || 'Service';
  const technicianName = booking.technicianName || 'A technician';
  const customerName = booking.customerName || 'A customer';

  // Notify customer
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: '✅ Booking Approved!',
    body: `Your ${serviceName} booking has been approved and assigned to ${technicianName}.`,
    type: 'booking_confirmed',
    data: {
      bookingId,
      screen: 'booking_details',
    },
    priority: 'high',
  }).catch(err => console.error('[BOOKING] Customer notification failed:', err));

  // Notify technician (if assigned)
  if (technicianId) {
    await sendUserNotification({
      userId: technicianId,
      userType: 'technician',
      title: '🔔 New Job Assigned!',
      body: `${serviceName} job assigned from ${customerName}. Review and accept/reject.`,
      type: 'new_instant_booking',
      data: {
        bookingId,
        screen: 'booking_details',
      },
      priority: 'high',
    }).catch(err => console.error('[BOOKING] Technician notification failed:', err));
  }

  console.log(`[BOOKING NOTIFICATION] Admin approved booking ${bookingId} - notifications sent to customer and technician`);
}

// ================================================
// HANDLER: Technician Accepted
// ================================================
async function handleTechnicianAccepted(
  customerId: string,
  technicianId: string,
  bookingId: string,
  booking: any
) {
  const technicianName = booking.technicianName || 'Your technician';
  const serviceName = booking.serviceName || 'Service';

  // Notify customer
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: '🎉 Technician Accepted!',
    body: `${technicianName} has accepted your ${serviceName} booking and will arrive soon.`,
    type: 'booking_confirmed',
    data: {
      bookingId,
      screen: 'booking_details',
    },
    priority: 'high',
  }).catch(err => console.error('[BOOKING] Customer notification failed:', err));
}

// ================================================
// HANDLER: Technician Arrived
// ================================================
async function handleTechnicianArrived(
  customerId: string,
  bookingId: string,
  booking: any
) {
  const technicianName = booking.technicianName || 'Your technician';

  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: '👷 Technician Has Arrived!',
    body: `${technicianName} has arrived at your location and is ready to start.`,
    type: 'technician_arrived',
    data: {
      bookingId,
      screen: 'booking_tracking',
    },
    priority: 'high',
  }).catch(err => console.error('[BOOKING] Notification failed:', err));
}

// ================================================
// HANDLER: Work Started
// ================================================
async function handleWorkStarted(
  customerId: string,
  bookingId: string,
  booking: any
) {
  const serviceName = booking.serviceName || 'Service';

  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: '⚙️ Service Started',
    body: `The ${serviceName} service has started. You can track progress in real-time.`,
    type: 'job_completed',
    data: {
      bookingId,
      screen: 'booking_tracking',
    },
    priority: 'normal',
  }).catch(err => console.error('[BOOKING] Notification failed:', err));
}

// ================================================
// HANDLER: Completed
// ================================================
async function handleCompleted(
  customerId: string,
  technicianId: string,
  bookingId: string,
  booking: any
) {
  const technicianName = booking.technicianName || 'Your technician';
  const serviceName = booking.serviceName || 'Service';

  // Notify customer to rate
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: '✅ Service Completed!',
    body: `${technicianName} has completed the ${serviceName}. Please rate your experience.`,
    type: 'job_completed',
    data: {
      bookingId,
      screen: 'booking_details',
    },
    priority: 'normal',
  }).catch(err => console.error('[BOOKING] Customer notification failed:', err));

  // Notify technician
  if (technicianId) {
    await sendUserNotification({
      userId: technicianId,
      userType: 'technician',
      title: '✅ Job Completed',
      body: `You have successfully completed the ${serviceName} booking.`,
      type: 'job_completed',
      data: {
        bookingId,
        screen: 'booking_details',
      },
      priority: 'normal',
    }).catch(err => console.error('[BOOKING] Technician notification failed:', err));
  }
}

// ================================================
// HANDLER: Cancelled
// ================================================
async function handleCancelled(
  customerId: string,
  technicianId: string,
  bookingId: string,
  booking: any
) {
  const reason = booking.cancellationReason || 'Booking was cancelled';
  const cancelledBy = booking.cancelledBy || 'System';

  // Notify customer
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: '❌ Booking Cancelled',
    body: reason,
    type: 'booking_cancelled',
    data: {
      bookingId,
      screen: 'booking_details',
    },
    priority: 'high',
  }).catch(err => console.error('[BOOKING] Customer notification failed:', err));

  // Notify technician (if assigned)
  if (technicianId) {
    await sendUserNotification({
      userId: technicianId,
      userType: 'technician',
      title: '❌ Job Cancelled',
      body: `Booking was cancelled. ${reason}`,
      type: 'booking_cancelled',
      data: {
        bookingId,
        screen: 'booking_details',
      },
      priority: 'high',
    }).catch(err => console.error('[BOOKING] Technician notification failed:', err));
  }
}
