/**
 * Finance Module Constants
 * 
 * This file contains constant values used throughout the finance and settings module.
 */

import type { PayoutStatus, WithdrawalStatus, AuditActionType, AuditEntityType } from '@/types/finance';

// ============================================================================
// Pagination Constants
// ============================================================================

export const PAGINATION = {
  PAYOUTS_PER_PAGE: 20,
  WITHDRAWALS_PER_PAGE: 20,
  AUDIT_LOGS_PER_PAGE: 50
} as const;

// ============================================================================
// Status Labels
// ============================================================================

export const PAYOUT_STATUS_LABELS: Record<PayoutStatus, string> = {
  pending: 'Pending',
  processing: 'Processing',
  completed: 'Completed',
  failed: 'Failed'
};

export const WITHDRAWAL_STATUS_LABELS: Record<WithdrawalStatus, string> = {
  pending: 'Pending',
  approved: 'Approved',
  rejected: 'Rejected',
  completed: 'Completed'
};

export const AUDIT_ACTION_LABELS: Record<AuditActionType, string> = {
  payout_processed: 'Payout Processed',
  withdrawal_approved: 'Withdrawal Approved',
  withdrawal_rejected: 'Withdrawal Rejected',
  settings_updated: 'Settings Updated'
};

export const AUDIT_ENTITY_LABELS: Record<AuditEntityType, string> = {
  booking_payout: 'Booking Payout',
  wallet_withdrawal: 'Wallet Withdrawal',
  app_settings: 'App Settings'
};

// ============================================================================
// Status Colors (Tailwind classes)
// ============================================================================

export const PAYOUT_STATUS_COLORS: Record<PayoutStatus, string> = {
  pending: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
  processing: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
  completed: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
  failed: 'bg-red-500/10 text-red-400 border-red-500/20'
};

export const WITHDRAWAL_STATUS_COLORS: Record<WithdrawalStatus, string> = {
  pending: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
  approved: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
  rejected: 'bg-red-500/10 text-red-400 border-red-500/20',
  completed: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
};

// ============================================================================
// Validation Constants
// ============================================================================

export const VALIDATION = {
  MIN_REJECTION_REASON_LENGTH: 10,
  MIN_ADMIN_NOTES_LENGTH: 5,
  MIN_COMMISSION_PERCENTAGE: 0,
  MAX_COMMISSION_PERCENTAGE: 100,
  MIN_WITHDRAWAL_AMOUNT: 1,
  MIN_PHONE_DIGITS: 10
} as const;

// ============================================================================
// Timeout Constants
// ============================================================================

export const TIMEOUTS = {
  OPERATION_TIMEOUT_MS: 10000, // 10 seconds
  DEBOUNCE_SEARCH_MS: 300 // 300ms for search input debouncing
} as const;

// ============================================================================
// Error Messages
// ============================================================================

export const ERROR_MESSAGES = {
  NETWORK_ERROR: 'Network error. Please check your connection.',
  TIMEOUT_ERROR: 'Operation timed out. Please try again.',
  GENERIC_ERROR: 'An error occurred. Please try again.',
  UNAUTHORIZED: 'You are not authorized to perform this action.',
  NOT_FOUND: 'The requested resource was not found.',
  INVALID_INPUT: 'Invalid input. Please check your data.',
  LOAD_FAILED: 'Failed to load data. Please try again.'
} as const;

// ============================================================================
// Success Messages
// ============================================================================

export const SUCCESS_MESSAGES = {
  PAYOUT_PROCESSED: 'Payout processed successfully',
  WITHDRAWAL_APPROVED: 'Withdrawal approved successfully',
  WITHDRAWAL_REJECTED: 'Withdrawal rejected successfully',
  SETTINGS_UPDATED: 'Settings updated successfully'
} as const;

// ============================================================================
// Empty State Messages
// ============================================================================

export const EMPTY_STATE_MESSAGES = {
  NO_PAYOUTS: 'No payouts found',
  NO_PAYOUTS_DESC: 'There are no booking payouts to display. Payouts will appear here once bookings are completed.',
  NO_WITHDRAWALS: 'No withdrawal requests found',
  NO_WITHDRAWALS_DESC: 'There are no wallet withdrawal requests to display. Requests will appear here when technicians submit them.',
  NO_AUDIT_LOGS: 'No logs found for the selected filters',
  NO_AUDIT_LOGS_DESC: 'Try adjusting your filters to see more results.',
  NO_SEARCH_RESULTS: 'No results match your search',
  NO_SEARCH_RESULTS_DESC: 'Try different search terms or clear the search to see all items.'
} as const;

// ============================================================================
// Filter Options
// ============================================================================

export const PAYOUT_STATUS_OPTIONS: { value: PayoutStatus | ''; label: string }[] = [
  { value: '', label: 'All Statuses' },
  { value: 'pending', label: 'Pending' },
  { value: 'processing', label: 'Processing' },
  { value: 'completed', label: 'Completed' },
  { value: 'failed', label: 'Failed' }
];

export const WITHDRAWAL_STATUS_OPTIONS: { value: WithdrawalStatus | ''; label: string }[] = [
  { value: '', label: 'All Statuses' },
  { value: 'pending', label: 'Pending' },
  { value: 'approved', label: 'Approved' },
  { value: 'rejected', label: 'Rejected' },
  { value: 'completed', label: 'Completed' }
];

export const AUDIT_ACTION_OPTIONS: { value: AuditActionType | ''; label: string }[] = [
  { value: '', label: 'All Actions' },
  { value: 'payout_processed', label: 'Payout Processed' },
  { value: 'withdrawal_approved', label: 'Withdrawal Approved' },
  { value: 'withdrawal_rejected', label: 'Withdrawal Rejected' },
  { value: 'settings_updated', label: 'Settings Updated' }
];

export const AUDIT_ENTITY_OPTIONS: { value: AuditEntityType | ''; label: string }[] = [
  { value: '', label: 'All Entities' },
  { value: 'booking_payout', label: 'Booking Payout' },
  { value: 'wallet_withdrawal', label: 'Wallet Withdrawal' },
  { value: 'app_settings', label: 'App Settings' }
];

// ============================================================================
// Route Paths
// ============================================================================

export const ROUTES = {
  BOOKING_PAYOUTS: '/finance/booking-payouts',
  BOOKING_PAYOUT_DETAILS: (id: string) => `/finance/booking-payouts/${id}`,
  WALLET_WITHDRAWALS: '/finance/wallet-withdrawals',
  WALLET_WITHDRAWAL_DETAILS: (id: string) => `/finance/wallet-withdrawals/${id}`,
  AUDIT_LOGS: '/audit-logs',
  SETTINGS: '/settings'
} as const;
