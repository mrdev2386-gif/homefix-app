/**
 * Booking Status Constants
 * Standardized across entire HomeFix platform
 */

export const BOOKING_STATUS = {
  PENDING_ADMIN_APPROVAL: 'PENDING_ADMIN_APPROVAL',
  ADMIN_APPROVED: 'ADMIN_APPROVED',
  TECHNICIAN_ACCEPTED: 'TECHNICIAN_ACCEPTED',
  IN_PROGRESS: 'IN_PROGRESS',
  COMPLETED: 'COMPLETED',
  REJECTED: 'REJECTED',
} as const;

export type BookingStatus = typeof BOOKING_STATUS[keyof typeof BOOKING_STATUS];

export const BOOKING_STATUS_LABELS: Record<BookingStatus, string> = {
  [BOOKING_STATUS.PENDING_ADMIN_APPROVAL]: 'Pending Admin Approval',
  [BOOKING_STATUS.ADMIN_APPROVED]: 'Admin Approved',
  [BOOKING_STATUS.TECHNICIAN_ACCEPTED]: 'Technician Accepted',
  [BOOKING_STATUS.IN_PROGRESS]: 'In Progress',
  [BOOKING_STATUS.COMPLETED]: 'Completed',
  [BOOKING_STATUS.REJECTED]: 'Rejected',
};

export const BOOKING_STATUS_VARIANTS: Record<BookingStatus, 'success' | 'warning' | 'error' | 'info' | 'default'> = {
  [BOOKING_STATUS.PENDING_ADMIN_APPROVAL]: 'warning',
  [BOOKING_STATUS.ADMIN_APPROVED]: 'info',
  [BOOKING_STATUS.TECHNICIAN_ACCEPTED]: 'info',
  [BOOKING_STATUS.IN_PROGRESS]: 'info',
  [BOOKING_STATUS.COMPLETED]: 'success',
  [BOOKING_STATUS.REJECTED]: 'error',
};

/**
 * Normalize booking status to standard format
 * Handles variants like: pending_admin_review, pending_admin, etc.
 */
export function normalizeBookingStatus(status: string): BookingStatus {
  if (!status) return BOOKING_STATUS.PENDING_ADMIN_APPROVAL;
  
  const normalized = status.toUpperCase().replace(/-/g, '_');
  
  // Map common variants to standard status
  const variantMap: Record<string, BookingStatus> = {
    'PENDING_ADMIN_APPROVAL': BOOKING_STATUS.PENDING_ADMIN_APPROVAL,
    'PENDING_ADMIN_REVIEW': BOOKING_STATUS.PENDING_ADMIN_APPROVAL,
    'PENDING_ADMIN': BOOKING_STATUS.PENDING_ADMIN_APPROVAL,
    'ADMIN_APPROVED': BOOKING_STATUS.ADMIN_APPROVED,
    'TECHNICIAN_ACCEPTED': BOOKING_STATUS.TECHNICIAN_ACCEPTED,
    'IN_PROGRESS': BOOKING_STATUS.IN_PROGRESS,
    'COMPLETED': BOOKING_STATUS.COMPLETED,
    'REJECTED': BOOKING_STATUS.REJECTED,
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
  return normalized === BOOKING_STATUS.IN_PROGRESS;
}
