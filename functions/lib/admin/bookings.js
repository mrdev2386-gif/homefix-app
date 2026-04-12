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
exports.adminManageBooking = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const config_1 = require("../shared/config");
const utils_1 = require("./utils");
const status_history_tracker_1 = require("../shared/status_history_tracker");
const notifications_1 = require("../shared/notifications"); // Ensure this exists
exports.adminManageBooking = functions.region('asia-south1').https.onCall(async (data, context) => {
    try {
        await (0, utils_1.assertAdmin)(context);
        const { bookingId, action, payload } = data; // action: 'assign' | 'reassign' | 'cancel'
        if (!bookingId || !action) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing bookingId or action');
        }
        const bookingRef = config_1.db.collection('bookings').doc(bookingId);
        const bookingDoc = await bookingRef.get();
        if (!bookingDoc.exists)
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        const booking = bookingDoc.data();
        if (action === 'assign' || action === 'reassign') {
            const { technicianId } = payload;
            if (!technicianId)
                throw new functions.https.HttpsError('invalid-argument', 'Missing technicianId');
            const techDoc = await config_1.db.collection('technicians').doc(technicianId).get();
            if (!techDoc.exists)
                throw new functions.https.HttpsError('not-found', 'Technician not found');
            const techData = techDoc.data();
            await config_1.db.runTransaction(async (t) => {
                const bookingDoc = await t.get(bookingRef);
                if (!bookingDoc.exists)
                    throw new functions.https.HttpsError('not-found', 'Booking not found');
                const booking = bookingDoc.data();
                // If reassigning, remove from old technician
                if (booking.assignedTechnicianId && booking.assignedTechnicianId !== technicianId) {
                    t.update(config_1.db.collection('technicians').doc(booking.assignedTechnicianId), {
                        currentAssignments: admin.firestore.FieldValue.arrayRemove(bookingId)
                    });
                }
                // Use status history tracker for atomic update
                (0, status_history_tracker_1.updateBookingStatus)(t, bookingRef, 'assigned', booking, {
                    assignedTechnicianId: technicianId,
                    assignedTechnicianName: techData.name || 'Expert',
                });
                t.update(config_1.db.collection('technicians').doc(technicianId), {
                    currentAssignments: admin.firestore.FieldValue.arrayUnion(bookingId)
                });
            });
            // Notify Technician
            try {
                await (0, notifications_1.sendPushNotification)(technicianId, 'technicians', {
                    title: 'New Job Assigned',
                    body: `You have been manually assigned to ${booking.serviceTitle}.`,
                    data: { bookingId, type: 'job_assigned' }
                });
            }
            catch (e) {
                console.error(`[Booking] Failed to notify technician ${technicianId}`, e);
            }
            // Notify Customer
            try {
                await (0, notifications_1.sendPushNotification)(booking.customerId, 'customers', {
                    title: 'Professional Assigned',
                    body: `${techData.name} has been assigned to your booking.`,
                    data: { bookingId, type: 'tech_assigned' }
                });
            }
            catch (e) {
                console.error(`[Booking] Failed to notify customer ${booking.customerId}`, e);
            }
            await (0, utils_1.logAdminAction)(context.auth.uid, `booking_${action}`, bookingId, { technicianId });
        }
        else if (action === 'cancel') {
            const { reason } = payload;
            // Use unified flow for cancellation to ensure tech cleanup and potentially refund logic
            const { updateBookingStatusUnified } = require('../shared/booking_flow');
            await updateBookingStatusUnified(bookingId, 'cancelled', { uid: context.auth.uid, role: 'admin' }, { reason: reason || 'Cancelled by admin', logAction: true });
            // Notify Customer
            try {
                await (0, notifications_1.sendPushNotification)(booking.customerId, 'customers', {
                    title: 'Booking Cancelled',
                    body: `Your booking has been cancelled by the administrator.`,
                    data: { bookingId, type: 'booking_cancelled' }
                });
            }
            catch (e) {
                console.error(`[Booking] Failed to notify customer ${booking.customerId}`, e);
            }
            if (booking.assignedTechnicianId) {
                // Notify Technician
                try {
                    await (0, notifications_1.sendPushNotification)(booking.assignedTechnicianId, 'technicians', {
                        title: 'Job Cancelled',
                        body: `Job #${bookingId.slice(-6)} has been cancelled.`,
                        data: { bookingId, type: 'job_cancelled' }
                    });
                }
                catch (e) {
                    console.error(`[Booking] Failed to notify technician ${booking.assignedTechnicianId}`, e);
                }
            }
            await (0, utils_1.logAdminAction)(context.auth.uid, 'booking_cancel', bookingId, { reason });
        }
        else {
            throw new functions.https.HttpsError('invalid-argument', `Invalid action: ${action}`);
        }
        return { success: true };
    }
    catch (error) {
        console.error('[Booking] Error in adminManageBooking:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to manage booking');
    }
});
//# sourceMappingURL=bookings.js.map