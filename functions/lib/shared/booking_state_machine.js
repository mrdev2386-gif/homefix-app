"use strict";
/**
 * BOOKING STATE MACHINE - Enforces valid transitions
 *
 * Prevents:
 * - Invalid state jumps
 * - Completed bookings reverting to earlier states
 * - Cancelled bookings being accepted later
 * - Race conditions via transaction-based validation
 */
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
exports.isValidTransition = isValidTransition;
exports.isTerminalState = isTerminalState;
exports.validateTransitionInTransaction = validateTransitionInTransaction;
exports.getAllowedNextStates = getAllowedNextStates;
exports.canBeCancelled = canBeCancelled;
exports.isCompleted = isCompleted;
exports.isPendingAdminApproval = isPendingAdminApproval;
exports.isPendingTechnicianAcceptance = isPendingTechnicianAcceptance;
exports.isInProgress = isInProgress;
exports.getStatusLabel = getStatusLabel;
exports.getStatusColor = getStatusColor;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
// Valid state transitions (immutable)
const STATE_MACHINE = {
    'pending': new Set(['approved_by_admin', 'rejected_by_admin', 'cancelled']),
    'pending_admin_approval': new Set(['approved_by_admin', 'rejected_by_admin', 'cancelled']),
    'approved_by_admin': new Set(['technician_accepted', 'technician_rejected', 'cancelled']),
    'technician_accepted': new Set(['service_in_progress', 'cancelled']),
    'service_in_progress': new Set(['service_completed', 'cancelled']),
    'service_completed': new Set(['completed', 'cancelled']),
    'completed': new Set(), // Terminal state
    'cancelled': new Set(), // Terminal state
    'rejected_by_admin': new Set(), // Terminal state
    'technician_rejected': new Set(), // Terminal state
};
// Terminal states (cannot transition out)
const TERMINAL_STATES = new Set(['completed', 'cancelled', 'rejected_by_admin', 'technician_rejected']);
/**
 * Validate if a status transition is allowed
 */
function isValidTransition(currentStatus, newStatus) {
    if (!STATE_MACHINE[currentStatus]) {
        return false; // Invalid current state
    }
    return STATE_MACHINE[currentStatus].has(newStatus);
}
/**
 * Check if a booking is in a terminal state
 */
function isTerminalState(status) {
    return TERMINAL_STATES.has(status);
}
/**
 * Validate booking state transition inside a transaction
 * Returns true if transition is valid, throws error otherwise
 */
async function validateTransitionInTransaction(transaction, bookingRef, newStatus) {
    const bookingDoc = await transaction.get(bookingRef);
    if (!bookingDoc.exists) {
        throw new Error('Booking not found');
    }
    const currentStatus = bookingDoc.data()?.bookingStatus;
    if (!currentStatus) {
        throw new Error('Booking has no status');
    }
    if (isTerminalState(currentStatus)) {
        throw new Error(`Cannot transition from terminal state: ${currentStatus}`);
    }
    if (!isValidTransition(currentStatus, newStatus)) {
        throw new Error(`Invalid transition: ${currentStatus} → ${newStatus}`);
    }
    return true;
}
/**
 * Get allowed next states for a booking
 */
function getAllowedNextStates(currentStatus) {
    return Array.from(STATE_MACHINE[currentStatus] || new Set());
}
/**
 * Check if booking can be cancelled
 */
function canBeCancelled(status) {
    return isValidTransition(status, 'cancelled');
}
/**
 * Check if booking is completed
 */
function isCompleted(status) {
    return status === 'completed';
}
/**
 * Check if booking is awaiting admin approval
 */
function isPendingAdminApproval(status) {
    return status === 'pending_admin_approval';
}
/**
 * Check if booking is awaiting technician acceptance
 */
function isPendingTechnicianAcceptance(status) {
    return status === 'approved_by_admin';
}
/**
 * Check if booking is in progress
 */
function isInProgress(status) {
    return status === 'service_in_progress';
}
/**
 * Get human-readable status label
 */
function getStatusLabel(status) {
    const labels = {
        'pending_admin_approval': 'Pending Admin Approval',
        'approved_by_admin': 'Approved - Awaiting Technician',
        'technician_accepted': 'Technician Accepted',
        'service_in_progress': 'Service In Progress',
        'service_completed': 'Service Completed - Awaiting Payment',
        'completed': 'Completed',
        'cancelled': 'Cancelled',
        'rejected_by_admin': 'Rejected by Admin',
        'technician_rejected': 'Rejected by Technician',
    };
    return labels[status] || status;
}
/**
 * Get status color for UI
 */
function getStatusColor(status) {
    const colors = {
        'pending_admin_approval': 'yellow',
        'approved_by_admin': 'blue',
        'technician_accepted': 'blue',
        'service_in_progress': 'cyan',
        'service_completed': 'orange',
        'completed': 'green',
        'cancelled': 'red',
        'rejected_by_admin': 'red',
        'technician_rejected': 'red',
    };
    return colors[status] || 'gray';
}
//# sourceMappingURL=booking_state_machine.js.map