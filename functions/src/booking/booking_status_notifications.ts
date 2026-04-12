/**
 * CRITICAL FIX: Booking Status Change Notifications
 * 
 * Sends notifications when booking status changes:
 * - pending_admin_review → approved_by_admin (notify technician)
 * - approved_by_admin → technician_accepted (notify customer)
 * - awaiting_payment → paid (notify technician)
 * - service_in_progress → awaiting_payment (notify customer)
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin'
import { sendNotificationToToken } from '../shared/notification_helper';

const db = admin.firestore();

/**
 * Trigger: Send notifications when booking status changes
 */
export const onBookingStatusChange = functions
  .region('asia-south1')
  .firestore.document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const bookingId = context.params.bookingId;

    const beforeStatus = before.bookingStatus || before.status;
    const afterStatus = after.bookingStatus || after.status;

    // No status change
    if (beforeStatus === afterStatus) {
      console.log(`[onBookingStatusChange] No status change for ${bookingId}`);
      return;
    }

    console.log(`[onBookingStatusChange] Status changed: ${beforeStatus} → ${afterStatus} for booking ${bookingId}`);

    try {
      // CASE 1: Admin approved booking → Notify technician
      if (afterStatus === 'approved_by_admin' && beforeStatus !== 'approved_by_admin') {
        console.log(`📲 [onBookingStatusChange] Notifying technician of approval for ${bookingId}`);
        
        const technicianId = after.technicianId;
        if (technicianId) {
          const techDoc = await db.collection('technicians').doc(technicianId).get();
          const techData = techDoc.data();

          if (techData?.fcmToken) {
            await sendNotificationToToken({
              token: techData.fcmToken,
              title: 'New Job Assignment',
              body: `You have been assigned a new job: ${after.serviceTitle}. Please review and accept.`,
              data: {
                bookingId,
                type: 'booking_approved',
                serviceTitle: after.serviceTitle,
              },
            });
          }
        }
      }

      // CASE 2: Technician accepted booking → Notify customer
      if (afterStatus === 'technician_accepted' && beforeStatus === 'approved_by_admin') {
        console.log(`📲 [onBookingStatusChange] Notifying customer of acceptance for ${bookingId}`);
        
        const customerId = after.customerId;
        if (customerId) {
          const customerDoc = await db.collection('customers').doc(customerId).get();
          const customerData = customerDoc.data();

          if (customerData?.fcmToken) {
            await sendNotificationToToken({
              token: customerData.fcmToken,
              title: 'Technician Assigned',
              body: `${after.technicianName || 'Your technician'} has accepted your booking for ${after.serviceTitle}`,
              data: {
                bookingId,
                type: 'booking_accepted',
                technicianId: after.technicianId,
                technicianName: after.technicianName,
              },
            });
          }
        }
      }

      // CASE 3: Service started → Notify customer
      if (afterStatus === 'service_in_progress' && beforeStatus === 'technician_accepted') {
        console.log(`📲 [onBookingStatusChange] Notifying customer of service start for ${bookingId}`);
        
        const customerId = after.customerId;
        if (customerId) {
          const customerDoc = await db.collection('customers').doc(customerId).get();
          const customerData = customerDoc.data();

          if (customerData?.fcmToken) {
            await sendNotificationToToken({
              token: customerData.fcmToken,
              title: 'Service Started',
              body: `${after.technicianName || 'Your technician'} has started working on your service`,
              data: {
                bookingId,
                type: 'service_started',
              },
            });
          }
        }
      }

      // CASE 4: Service completed → Notify customer to pay
      if (afterStatus === 'awaiting_payment' && beforeStatus === 'service_in_progress') {
        console.log(`📲 [onBookingStatusChange] Notifying customer to pay for ${bookingId}`);
        
        const customerId = after.customerId;
        if (customerId) {
          const customerDoc = await db.collection('customers').doc(customerId).get();
          const customerData = customerDoc.data();

          if (customerData?.fcmToken) {
            await sendNotificationToToken({
              token: customerData.fcmToken,
              title: 'Service Completed',
              body: `Your service is complete. Please confirm payment of ₹${after.finalAmount || after.price}`,
              data: {
                bookingId,
                type: 'service_completed',
                amount: (after.finalAmount || after.price).toString(),
              },
            });
          }
        }
      }

      // CASE 5: Payment received → Notify technician
      if (afterStatus === 'paid' && beforeStatus === 'awaiting_payment') {
        console.log(`📲 [onBookingStatusChange] Notifying technician of payment for ${bookingId}`);
        
        const technicianId = after.technicianId;
        if (technicianId) {
          const techDoc = await db.collection('technicians').doc(technicianId).get();
          const techData = techDoc.data();

          if (techData?.fcmToken) {
            await sendNotificationToToken({
              token: techData.fcmToken,
              title: 'Payment Received',
              body: `Payment of ₹${after.finalAmount || after.price} received for booking ${bookingId}`,
              data: {
                bookingId,
                type: 'payment_received',
                amount: (after.finalAmount || after.price).toString(),
              },
            });
          }
        }
      }

      // CASE 6: Technician rejected → Notify admin
      if (afterStatus === 'technician_rejected' && beforeStatus === 'approved_by_admin') {
        console.log(`📲 [onBookingStatusChange] Notifying admin of rejection for ${bookingId}`);
        
        const adminsSnapshot = await db.collection('admins').limit(10).get();
        for (const adminDoc of adminsSnapshot.docs) {
          const adminData = adminDoc.data();
          if (adminData?.fcmToken) {
            await sendNotificationToToken({
              token: adminData.fcmToken,
              title: 'Booking Rejected',
              body: `Technician rejected booking ${bookingId}. Please reassign to another technician.`,
              data: {
                bookingId,
                type: 'booking_rejected_by_tech',
              },
            });
          }
        }
      }

      // CASE 7: Booking cancelled → Notify both parties
      if (afterStatus === 'cancelled' || afterStatus === 'cancelled_by_customer') {
        console.log(`📲 [onBookingStatusChange] Notifying parties of cancellation for ${bookingId}`);
        
        // Notify technician
        const technicianId = after.technicianId;
        if (technicianId) {
          const techDoc = await db.collection('technicians').doc(technicianId).get();
          const techData = techDoc.data();

          if (techData?.fcmToken) {
            await sendNotificationToToken({
              token: techData.fcmToken,
              title: 'Booking Cancelled',
              body: `Booking ${bookingId} has been cancelled`,
              data: {
                bookingId,
                type: 'booking_cancelled',
              },
            });
          }
        }

        // Notify customer
        const customerId = after.customerId;
        if (customerId) {
          const customerDoc = await db.collection('customers').doc(customerId).get();
          const customerData = customerDoc.data();

          if (customerData?.fcmToken) {
            await sendNotificationToToken({
              token: customerData.fcmToken,
              title: 'Booking Cancelled',
              body: `Your booking ${bookingId} has been cancelled`,
              data: {
                bookingId,
                type: 'booking_cancelled',
              },
            });
          }
        }
      }

      console.log(`✅ [onBookingStatusChange] Notifications sent for ${bookingId}`);

    } catch (error) {
      console.error(`❌ [onBookingStatusChange] Error sending notifications for ${bookingId}:`, error);
      // Don't throw - notifications are non-critical
    }
  });
