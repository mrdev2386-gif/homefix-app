/**
 * BOOKING STATE MACHINE - Enforces valid transitions
 * 
 * Prevents:
 * - Invalid state jumps
 * - Completed bookings reverting to earlier states
 * - Cancelled bookings being accepted later
 * - Race conditions via transaction-based validation
 */

import * as admin from 'firebase-admin';

const db = admin.firestore();

// Valid state transitions (immutable)
const STATE_MACHINE: Record<string, Set<string>> = {
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
export function isValidTransition(currentStatus: string, newStatus: string): boolean {
  if (!STATE_MACHINE[currentStatus]) {
    return false; // Invalid current state
  }
  return STATE_MACHINE[currentStatus].has(newStatus);
}

/**
 * Check if a booking is in a terminal state
 */
export function isTerminalState(status: string): boolean {
  return TERMINAL_STATES.has(status);
}

/**
 * Validate booking state transition inside a transaction
 * Returns true if transition is valid, throws error otherwise
 */
export async function validateTransitionInTransaction(
  transaction: admin.firestore.Transaction,
  bookingRef: admin.firestore.DocumentReference,
  newStatus: string
): Promise<boolean> {
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
export function getAllowedNextStates(currentStatus: string): string[] {
  return Array.from(STATE_MACHINE[currentStatus] || new Set());
}

/**
 * Check if booking can be cancelled
 */
export function canBeCancelled(status: string): boolean {
  return isValidTransition(status, 'cancelled');
}

/**
 * Check if booking is completed
 */
export function isCompleted(status: string): boolean {
  return status === 'completed';
}

/**
 * Check if booking is awaiting admin approval
 */
export function isPendingAdminApproval(status: string): boolean {
  return status === 'pending_admin_approval';
}

/**
 * Check if booking is awaiting technician acceptance
 */
export function isPendingTechnicianAcceptance(status: string): boolean {
  return status === 'approved_by_admin';
}

/**
 * Check if booking is in progress
 */
export function isInProgress(status: string): boolean {
  return status === 'service_in_progress';
}

/**
 * Get human-readable status label
 */
export function getStatusLabel(status: string): string {
  const labels: Record<string, string> = {
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
export function getStatusColor(status: string): string {
  const colors: Record<string, string> = {
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
