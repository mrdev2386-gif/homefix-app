/**
 * Booking Status Constants
 * Standardized across entire HomeFix platform
 */

export const BOOKING_STATUS = {
  PENDING_ADMIN_APPROVAL: 'pending_admin_approval',
  APPROVED_BY_ADMIN: 'approved_by_admin',
  TECHNICIAN_ACCEPTED: 'technician_accepted',
  SERVICE_IN_PROGRESS: 'service_in_progress',
  SERVICE_COMPLETED: 'service_completed',
  REJECTED: 'rejected',
} as const;

export type BookingStatus = typeof BOOKING_STATUS[keyof typeof BOOKING_STATUS];

export const BOOKING_STATUS_LABELS: Record<BookingStatus, string> = {
  [BOOKING_STATUS.PENDING_ADMIN_APPROVAL]: 'Pending Admin Approval',
  [BOOKING_STATUS.APPROVED_BY_ADMIN]: 'Approved by Admin',
  [BOOKING_STATUS.TECHNICIAN_ACCEPTED]: 'Technician Accepted',
  [BOOKING_STATUS.SERVICE_IN_PROGRESS]: 'Service in Progress',
  [BOOKING_STATUS.SERVICE_COMPLETED]: 'Service Completed',
  [BOOKING_STATUS.REJECTED]: 'Rejected',
};

export const BOOKING_STATUS_VARIANTS: Record<BookingStatus, 'success' | 'warning' | 'error' | 'info' | 'default'> = {
  [BOOKING_STATUS.PENDING_ADMIN_APPROVAL]: 'warning',
  [BOOKING_STATUS.APPROVED_BY_ADMIN]: 'info',
  [BOOKING_STATUS.TECHNICIAN_ACCEPTED]: 'info',
  [BOOKING_STATUS.SERVICE_IN_PROGRESS]: 'info',
  [BOOKING_STATUS.SERVICE_COMPLETED]: 'success',
  [BOOKING_STATUS.REJECTED]: 'error',
};

/**
 * Normalize booking status to standard format
 * Handles variants like: pending_admin_review, pending_admin, etc.
 */
export function normalizeBookingStatus(status: string): BookingStatus {
  if (!status) return BOOKING_STATUS.PENDING_ADMIN_APPROVAL;
  
  const normalized = status.toLowerCase().trim().replace(/-/g, '_');
  
  // Map all pending variants to standard pending status
  const pendingVariants = ['pending_admin_review', 'pending_admin_approval', 'pending_admin', 'pending'];
  if (pendingVariants.includes(normalized)) {
    return BOOKING_STATUS.PENDING_ADMIN_APPROVAL;
  }
  
  // Map common variants to standard status
  const variantMap: Record<string, BookingStatus> = {
    'approved_by_admin': BOOKING_STATUS.APPROVED_BY_ADMIN,
    'admin_approved': BOOKING_STATUS.APPROVED_BY_ADMIN,
    'assigned': BOOKING_STATUS.APPROVED_BY_ADMIN,
    'technician_accepted': BOOKING_STATUS.TECHNICIAN_ACCEPTED,
    'confirmed': BOOKING_STATUS.TECHNICIAN_ACCEPTED,
    'service_in_progress': BOOKING_STATUS.SERVICE_IN_PROGRESS,
    'in_progress': BOOKING_STATUS.SERVICE_IN_PROGRESS,
    'service_completed': BOOKING_STATUS.SERVICE_COMPLETED,
    'completed': BOOKING_STATUS.SERVICE_COMPLETED,
    'rejected': BOOKING_STATUS.REJECTED,
    'rejected_by_admin': BOOKING_STATUS.REJECTED,
    'admin_rejected': BOOKING_STATUS.REJECTED,
    'technician_rejected': BOOKING_STATUS.REJECTED,
    'cancelled': BOOKING_STATUS.REJECTED,
  };
  
  return variantMap[normalized] || (status as BookingStatus);
}

/**
 * Check if booking can be approved
 * Handles multiple status variants
 */
export function canApproveBooking(status: string): boolean {
  const normalized = normalizeBookingStatus(status);
  return normalized === BOOKING_STATUS.PENDING_ADMIN_APPROVAL;
}

/**
 * Check if booking can be rejected
 * Handles multiple status variants
 */
export function canRejectBooking(status: string): boolean {
  const normalized = normalizeBookingStatus(status);
  return normalized === BOOKING_STATUS.PENDING_ADMIN_APPROVAL;
}

/**
 * Check if booking can be marked active
 */
export function canMarkActive(status: string): boolean {
  const normalized = normalizeBookingStatus(status);
  return normalized === BOOKING_STATUS.TECHNICIAN_ACCEPTED;
}

/**
 * Check if booking can be completed
 */
export function canMarkCompleted(status: string): boolean {
  const normalized = normalizeBookingStatus(status);
  return normalized === BOOKING_STATUS.SERVICE_IN_PROGRESS;
}
