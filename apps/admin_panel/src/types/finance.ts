/**
 * Finance & Settings Module Type Definitions
 * 
 * This file contains all TypeScript interfaces and types for the admin finance
 * and settings module, including data models for Firestore collections and
 * Cloud Function request/response interfaces.
 */

import { Timestamp } from 'firebase/firestore';

// ============================================================================
// Status Type Unions
// ============================================================================

/**
 * Payout status values
 */
export type PayoutStatus = 'pending' | 'processing' | 'completed' | 'failed';

/**
 * Withdrawal status values
 */
export type WithdrawalStatus = 'pending' | 'approved' | 'rejected' | 'completed';

/**
 * Payout method types
 */
export type PayoutMethod = 'bank_transfer' | 'wallet' | 'upi';

/**
 * Audit log action types
 */
export type AuditActionType = 
  | 'payout_processed' 
  | 'withdrawal_approved' 
  | 'withdrawal_rejected' 
  | 'settings_updated';

/**
 * Audit log entity types
 */
export type AuditEntityType = 
  | 'booking_payout' 
  | 'wallet_withdrawal' 
  | 'app_settings';

// ============================================================================
// Firestore Collection Interfaces
// ============================================================================

/**
 * BookingPayout document interface
 * Collection: bookingPayouts
 */
export interface BookingPayout {
  id: string;
  bookingId: string;
  technicianId: string;
  technicianName: string;
  serviceId: string;
  serviceName: string;
  bookingAmount: number;
  platformCommissionPercentage: number;
  platformCommissionAmount: number;
  technicianEarning: number;
  status: PayoutStatus;
  payoutMethod: PayoutMethod;
  createdAt: Timestamp;
  paidAt?: Timestamp;
  processedBy?: string; // Admin ID
  notes?: string;
}

/**
 * WalletWithdrawal document interface
 * Collection: walletWithdrawals
 */
export interface WalletWithdrawal {
  id: string;
  technicianId: string;
  technicianName: string;
  amount: number;
  bankAccountNumber: string;
  bankAccountName: string;
  ifscCode: string;
  bankName: string;
  status: WithdrawalStatus;
  requestedAt: Timestamp;
  processedAt?: Timestamp;
  processedBy?: string; // Admin ID
  adminNotes?: string;
  rejectionReason?: string;
}

/**
 * AuditLog document interface
 * Collection: auditLogs
 */
export interface AuditLog {
  id: string;
  adminId: string;
  adminName: string;
  adminEmail: string;
  actionType: AuditActionType;
  entityType: AuditEntityType;
  entityId: string;
  metadata: Record<string, any>;
  ipAddress: string;
  userAgent: string;
  createdAt: Timestamp;
}

/**
 * AppSettings document interface
 * Document path: appSettings/config
 */
export interface AppSettings {
  platformCommissionPercentage: number; // 0-100
  supportPhoneNumber: string;
  supportEmail: string;
  maintenanceMode: boolean;
  minWithdrawalAmount: number;
  lastUpdatedAt: Timestamp;
  lastUpdatedBy: string; // Admin ID
}

// ============================================================================
// Cloud Function Request/Response Interfaces
// ============================================================================

/**
 * Process Booking Payout Cloud Function
 */
export interface ProcessBookingPayoutRequest {
  payoutId: string;
}

export interface ProcessBookingPayoutResponse {
  success: boolean;
  message: string;
  payout?: BookingPayout;
}

/**
 * Approve Wallet Withdrawal Cloud Function
 */
export interface ApproveWalletWithdrawalRequest {
  withdrawalId: string;
  adminNotes?: string;
}

export interface ApproveWalletWithdrawalResponse {
  success: boolean;
  message: string;
  withdrawal?: WalletWithdrawal;
}

/**
 * Reject Wallet Withdrawal Cloud Function
 */
export interface RejectWalletWithdrawalRequest {
  withdrawalId: string;
  rejectionReason: string; // Required, min 10 chars
}

export interface RejectWalletWithdrawalResponse {
  success: boolean;
  message: string;
  withdrawal?: WalletWithdrawal;
}

/**
 * Update App Settings Cloud Function
 */
export interface UpdateAppSettingsRequest {
  platformCommissionPercentage?: number;
  supportPhoneNumber?: string;
  supportEmail?: string;
  maintenanceMode?: boolean;
  minWithdrawalAmount?: number;
}

export interface UpdateAppSettingsResponse {
  success: boolean;
  message: string;
  settings?: AppSettings;
}

// ============================================================================
// Filter and Pagination Interfaces
// ============================================================================

/**
 * Payout filter options
 */
export interface PayoutFilters {
  status?: PayoutStatus;
  searchTerm?: string;
  technicianId?: string;
}

/**
 * Withdrawal filter options
 */
export interface WithdrawalFilters {
  status?: WithdrawalStatus;
  searchTerm?: string;
  technicianId?: string;
}

/**
 * Audit log filter options
 */
export interface AuditLogFilters {
  actionType?: AuditActionType;
  entityType?: AuditEntityType;
  startDate?: Date;
  endDate?: Date;
  adminId?: string;
}

/**
 * Pagination state
 */
export interface PaginationState {
  currentPage: number;
  totalPages: number;
  itemsPerPage: number;
  totalItems: number;
}

// ============================================================================
// UI Component Props Interfaces
// ============================================================================

/**
 * Status badge props
 */
export interface StatusBadgeProps {
  status: PayoutStatus | WithdrawalStatus;
  size?: 'sm' | 'md' | 'lg';
}

/**
 * Confirm dialog props
 */
export interface ConfirmDialogProps {
  title: string;
  message: string;
  confirmText: string;
  cancelText: string;
  onConfirm: () => void;
  onCancel: () => void;
  requireInput?: boolean;
  inputLabel?: string;
  inputPlaceholder?: string;
  inputValidation?: (value: string) => string | null;
  minLength?: number;
}

/**
 * Error state props
 */
export interface ErrorStateProps {
  title: string;
  message: string;
  onRetry?: () => void;
  showRetry?: boolean;
}

/**
 * Empty state props
 */
export interface EmptyStateProps {
  title: string;
  description: string;
  icon?: React.ComponentType<{ className?: string }>;
  action?: {
    label: string;
    onClick: () => void;
  };
}

// ============================================================================
// Form State Interfaces
// ============================================================================

/**
 * Settings form values
 */
export interface SettingsFormValues {
  platformCommissionPercentage: number;
  supportPhoneNumber: string;
  supportEmail: string;
  maintenanceMode: boolean;
  minWithdrawalAmount: number;
}

/**
 * Form validation errors
 */
export interface FormErrors {
  [key: string]: string;
}

/**
 * Form touched fields
 */
export interface FormTouched {
  [key: string]: boolean;
}
