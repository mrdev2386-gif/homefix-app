"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onTechnicianApplicationStatusTrigger = exports.onTechnicianLikeNotification = exports.onBookingCancelledNotification = exports.onNewReviewNotification = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const notify = __importStar(require("./shared/notification_helper"));
const db = admin.firestore();
/**
 * Triggered when a new review is added
 */
exports.onNewReviewNotification = functions.firestore
    .document('reviews/{reviewId}')
    .onCreate(async (snap, context) => {
    const review = snap.data();
    if (!review)
        return;
    const { technicianId, rating, customerName, bookingId } = review;
    if (technicianId) {
        await notify.notifyTechnicianNewReview(technicianId, bookingId || '', rating, customerName || 'A customer');
    }
});
/**
 * Triggered when a booking is cancelled (backup trigger)
 * Most cancellations are handled in the flow, but this ensures coverage.
 */
exports.onBookingCancelledNotification = functions.firestore
    .document('bookings/{bookingId}')
    .onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();
    if (!after || !before)
        return;
    // Check for cancellation
    if (after.status === 'cancelled' && before.status !== 'cancelled') {
        const bookingId = context.params.bookingId;
        const cancelledBy = after.cancelledBy;
        if (cancelledBy === 'customer') {
            // Notify Technician
            if (after.technicianId) {
                await notify.notifyTechnicianBookingCancelled(after.technicianId, bookingId, after.cancellationReason);
            }
        }
        else if (cancelledBy === 'technician' || cancelledBy === 'admin') {
            // Notify Customer
            if (after.customerId) {
                await notify.notifyCustomerBookingCancelled(after.customerId, bookingId, after.cancellationReason);
            }
        }
    }
});
/**
 * Triggered when a user heart/likes a technician
 */
exports.onTechnicianLikeNotification = functions.firestore
    .document('technician_likes/{likeId}')
    .onCreate(async (snap, context) => {
    const like = snap.data();
    if (!like)
        return;
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
exports.onTechnicianApplicationStatusTrigger = functions.firestore
    .document('technicians/{techId}')
    .onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();
    if (!after || !before)
        return;
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
        }
        else if (after.status === 'rejected') {
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
//# sourceMappingURL=notification_triggers.js.map