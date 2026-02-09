
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { Booking } from './models';

/**
 * Valid Status Transitions
 */
export const VALID_TRANSITIONS: Record<string, string[]> = {
    'pending': ['pending_assignment', 'cancelled'],
    'pending_assignment': ['assigned', 'pending', 'cancelled'],
    'assigned': ['accepted', 'pending', 'cancelled', 'rejected'],
    'accepted': ['inspection_scheduled', 'inspection_in_progress', 'in_progress', 'cancelled'],
    'inspection_scheduled': ['inspection_in_progress', 'cancelled'],
    'inspection_in_progress': ['awaiting_approval', 'cancelled'],
    'awaiting_approval': ['approved', 'rejected', 'cancelled'],
    'approved': ['in_progress', 'cancelled'],
    'in_progress': ['completed', 'cancelled'],
    // Terminal states
    'completed': [],
    'cancelled': [],
    'rejected': [],
    'pending_admin_review': ['assigned', 'cancelled']
};

/**
 * Validates if a status transition is allowed and checks business rules
 */
export function validateStatusTransition(booking: Booking, nextStatus: string, actorRole: string): { allowed: boolean; reason?: string } {
    const currentStatus = booking.status;
    if (currentStatus === nextStatus) return { allowed: true };

    const allowed = VALID_TRANSITIONS[currentStatus] || [];
    if (!allowed.includes(nextStatus)) {
        return { allowed: false, reason: `Invalid transition from ${currentStatus} to ${nextStatus}` };
    }

    // Business Rules
    if (nextStatus === 'cancelled') {
        if (actorRole === 'customer') {
            // Rule: Customer cannot cancel after job has started ('in_progress')
            if (currentStatus === 'in_progress') {
                return { allowed: false, reason: 'Job already in progress. Contact support to cancel.' };
            }
            // Rule: Customer cancellation after approval might need admin review in some models,
            // but for now we allow it if not in_progress.
        }
        if (actorRole === 'technician') {
            // Tech should generally use 'rejection' or 'no-show' rather than absolute cancellation 
            // unless it's a specific "cannot do it" before starting.
        }
    }

    return { allowed: true };
}

/**
 * Ensures pricing is locked and technician cannot edit after approval
 */
export function canEditPricing(booking: Booking): boolean {
    // If status is 'awaiting_approval' or earlier, technician can submit/edit report.
    // Once status is 'approved' or later, NO ONE can edit pricing.
    const forbiddenStates = ['approved', 'in_progress', 'completed', 'cancelled', 'rejected'];
    return !forbiddenStates.includes(booking.status);
}

/**
 * Core function to handle booking status updates with security and validation
 */
export async function updateBookingStatusUnified(
    bookingId: string,
    nextStatus: string,
    actor: { uid: string; role: 'customer' | 'technician' | 'admin' | 'system' },
    options: {
        reason?: string;
        pricingData?: any;
        inspectionReport?: any;
        logAction?: boolean;
    } = {}
) {
    const db = admin.firestore();
    const bookingRef = db.collection('bookings').doc(bookingId);

    return db.runTransaction(async (t) => {
        const bDoc = await t.get(bookingRef);
        if (!bDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
        const booking = bDoc.data() as Booking;

        // 1. Role Authorization
        if (actor.role === 'customer' && booking.customerId !== actor.uid) {
            throw new functions.https.HttpsError('permission-denied', 'Unauthorized');
        }
        if (actor.role === 'technician' && booking.assignedTechnicianId !== actor.uid && booking.status !== 'pending' && booking.status !== 'pending_assignment') {
            // Special case: taking a job handled by matching, or being assigned.
            // If already assigned, must be that tech.
            if (booking.assignedTechnicianId && booking.assignedTechnicianId !== actor.uid) {
                throw new functions.https.HttpsError('permission-denied', 'Unauthorized: Another professional is assigned');
            }
        }

        // 2. State Validation
        const validation = validateStatusTransition(booking, nextStatus, actor.role);
        if (!validation.allowed) {
            throw new functions.https.HttpsError('failed-precondition', validation.reason || 'Transition blocked');
        }

        // 3. Status Specific Logic
        const update: any = {
            status: nextStatus,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Pricing Security: Prevent modification after approval
        if (options.pricingData) {
            if (!canEditPricing(booking)) {
                throw new functions.https.HttpsError('failed-precondition', 'Pricing is locked and cannot be modified');
            }
            if (actor.role === 'technician') {
                // Ensure tech only modifies items, not platform fees or totals (backend recalculates)
                // In UC flow, tech submits report, system calculates totals.
                // For this MVP, we assume tech sends { subServices: [...] }
            }
            update.pricing = {
                ...booking.pricing,
                ...options.pricingData,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            };
        }

        if (nextStatus === 'cancelled') {
            update.cancelledBy = actor.role;
            update.cancellationReason = options.reason || 'Cancelled';
            update.cancelledAt = admin.firestore.FieldValue.serverTimestamp();

            // 1. Cleanup tech assignment
            if (booking.assignedTechnicianId) {
                t.update(db.collection('technicians').doc(booking.assignedTechnicianId), {
                    currentAssignments: admin.firestore.FieldValue.arrayRemove(bookingId)
                });
            }

            // 2. Handle Refunds (Razorpay or Wallet)
            if (booking.paymentStatus === 'paid') {
                if (booking.razorpayOrderId) {
                    // Razorpay Refund - We mark as refund_pending for the trigger/admin to handle
                    // since we can't do external calls inside a firestore transaction.
                    update.paymentStatus = 'refund_pending';
                    update.refundRequestedAt = admin.firestore.FieldValue.serverTimestamp();
                } else {
                    // Wallet Refund
                    const customerRef = db.collection('customers').doc(booking.customerId);
                    t.update(customerRef, {
                        walletBalance: admin.firestore.FieldValue.increment(booking.pricing.total),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    t.set(customerRef.collection('wallet_transactions').doc(), {
                        type: 'credit',
                        amount: booking.pricing.total,
                        description: `Refund for cancelled booking #${bookingId.slice(-6)}`,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        status: 'completed'
                    });
                    update.paymentStatus = 'refunded';
                }
            }
        }

        if (nextStatus === 'awaiting_approval') {
            update.inspectionCompleted = true;
            update.inspectionCompletedAt = admin.firestore.FieldValue.serverTimestamp();
            if (options.inspectionReport) {
                update.inspectionNotes = options.inspectionReport.notes;
                update.inspectionImages = options.inspectionReport.images;
            }
            // Lock pricing snapshot
            update.pricing.pricingLockedAt = admin.firestore.FieldValue.serverTimestamp();
        }

        if (nextStatus === 'approved') {
            update.approvedAt = admin.firestore.FieldValue.serverTimestamp();
            update.pricing.pricingApprovedBy = actor.uid;
        }

        if (nextStatus === 'in_progress') {
            update.startedAt = admin.firestore.FieldValue.serverTimestamp();
        }

        if (nextStatus === 'completed') {
            update.completedAt = admin.firestore.FieldValue.serverTimestamp();
            // Free up technician
            if (booking.assignedTechnicianId) {
                t.update(db.collection('technicians').doc(booking.assignedTechnicianId), {
                    currentAssignments: admin.firestore.FieldValue.arrayRemove(bookingId),
                    lastJobEndedAt: admin.firestore.FieldValue.serverTimestamp(),
                    totalJobs: admin.firestore.FieldValue.increment(1)
                });
            }
        }

        t.update(bookingRef, update);

        // 4. Audit Logging (optional inside transaction for atomicity)
        if (options.logAction) {
            const logRef = db.collection('booking_history').doc();
            t.set(logRef, {
                bookingId,
                fromStatus: booking.status,
                toStatus: nextStatus,
                actorUid: actor.uid,
                actorRole: actor.role,
                reason: options.reason || null,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    });
}
