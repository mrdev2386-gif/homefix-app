import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as notify from './shared/notification_helper';

const db = admin.firestore();

/**
 * Triggered when a new review is added
 */
export const onNewReviewNotification = functions.firestore
    .document('reviews/{reviewId}')
    .onCreate(async (snap, context) => {
        const review = snap.data();
        if (!review) return;

        const { technicianId, rating, customerName, bookingId } = review;

        if (technicianId) {
            await notify.notifyTechnicianNewReview(
                technicianId,
                bookingId || '',
                rating,
                customerName || 'A customer'
            );
        }
    });

/**
 * Triggered when a booking is cancelled (backup trigger)
 * Most cancellations are handled in the flow, but this ensures coverage.
 */
export const onBookingCancelledNotification = functions.firestore
    .document('bookings/{bookingId}')
    .onUpdate(async (change, context) => {
        const after = change.after.data();
        const before = change.before.data();
        if (!after || !before) return;

        // Check for cancellation
        if (after.status === 'cancelled' && before.status !== 'cancelled') {
            const bookingId = context.params.bookingId;
            const cancelledBy = after.cancelledBy;

            if (cancelledBy === 'customer') {
                // Notify Technician
                if (after.technicianId) {
                    await notify.notifyTechnicianBookingCancelled(
                        after.technicianId,
                        bookingId,
                        after.cancellationReason
                    );
                }
            } else if (cancelledBy === 'technician' || cancelledBy === 'admin') {
                // Notify Customer
                if (after.customerId) {
                    await notify.notifyCustomerBookingCancelled(
                        after.customerId,
                        bookingId,
                        after.cancellationReason
                    );
                }
            }
        }
    });

/**
 * Triggered when a user heart/likes a technician
 */
export const onTechnicianLikeNotification = functions.firestore
    .document('technician_likes/{likeId}')
    .onCreate(async (snap, context) => {
        const like = snap.data();
        if (!like) return;

        const { technicianId, customerName } = like;

        if (technicianId) {
            await notify.sendUserNotification({
                userId: technicianId,
                userType: 'technician',
                title: 'New Like! ❤️',
                body: `${customerName || 'A customer'} liked your profile.`,
                type: 'general',
                priority: 'normal',
            });
        }
    });

/**
 * Triggered when a technician application status changes
 */
export const onTechnicianApplicationStatusTrigger = functions.firestore
    .document('technicians/{techId}')
    .onUpdate(async (change, context) => {
        const after = change.after.data();
        const before = change.before.data();
        if (!after || !before) return;

        if (after.status !== before.status) {
            const techId = context.params.techId;

            if (after.status === 'active' || after.status === 'approved') {
                await notify.sendUserNotification({
                    userId: techId,
                    userType: 'technician',
                    title: 'Account Approved! 🎉',
                    body: 'Your technician account has been approved. You can now start accepting jobs.',
                    type: 'application_approved',
                    priority: 'high',
                });
            } else if (after.status === 'rejected') {
                await notify.sendUserNotification({
                    userId: techId,
                    userType: 'technician',
                    title: 'Account Update',
                    body: `Your account application was not approved. Reason: ${after.rejectionReason || 'Please contact support.'}`,
                    type: 'application_rejected',
                    priority: 'high',
                });
            }
        }
    });
