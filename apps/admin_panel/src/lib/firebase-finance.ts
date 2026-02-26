/**
 * Firebase Finance Module Service Utilities
 * 
 * This file provides utility functions for interacting with Firebase services
 * for the finance and settings module, including Firestore queries and
 * Cloud Function invocations.
 */

'use client';

import { 
  collection, 
  doc, 
  query, 
  where, 
  orderBy, 
  limit,
  getDocs,
  getDoc,
  onSnapshot,
  Timestamp,
  QueryConstraint,
  Unsubscribe
} from 'firebase/firestore';
import { httpsCallable, HttpsCallableResult } from 'firebase/functions';
import { db, functions } from './firebase';
import type {
  BookingPayout,
  WalletWithdrawal,
  AuditLog,
  AppSettings,
  PayoutFilters,
  WithdrawalFilters,
  AuditLogFilters,
  ProcessBookingPayoutRequest,
  ProcessBookingPayoutResponse,
  ApproveWalletWithdrawalRequest,
  ApproveWalletWithdrawalResponse,
  RejectWalletWithdrawalRequest,
  RejectWalletWithdrawalResponse,
  UpdateAppSettingsRequest,
  UpdateAppSettingsResponse
} from '@/types/finance';

// ============================================================================
// Collection References
// ============================================================================

export const COLLECTIONS = {
  BOOKING_PAYOUTS: 'bookingPayouts',
  WALLET_WITHDRAWALS: 'walletWithdrawals',
  AUDIT_LOGS: 'auditLogs',
  APP_SETTINGS: 'appSettings'
} as const;

export const SETTINGS_DOC_ID = 'config';

// ============================================================================
// Booking Payouts
// ============================================================================

/**
 * Get booking payouts collection reference
 */
export function getBookingPayoutsRef() {
  return collection(db, COLLECTIONS.BOOKING_PAYOUTS);
}

/**
 * Build query for booking payouts with filters
 */
export function buildPayoutsQuery(filters: PayoutFilters, itemsPerPage: number = 20) {
  const constraints: QueryConstraint[] = [
    orderBy('createdAt', 'desc'),
    limit(itemsPerPage)
  ];

  if (filters.status) {
    constraints.unshift(where('status', '==', filters.status));
  }

  if (filters.technicianId) {
    constraints.unshift(where('technicianId', '==', filters.technicianId));
  }

  return query(getBookingPayoutsRef(), ...constraints);
}

/**
 * Subscribe to booking payouts with real-time updates
 */
export function subscribeToPayouts(
  filters: PayoutFilters,
  onUpdate: (payouts: BookingPayout[]) => void,
  onError: (error: Error) => void,
  itemsPerPage: number = 20
): Unsubscribe {
  const q = buildPayoutsQuery(filters, itemsPerPage);

  return onSnapshot(
    q,
    (snapshot) => {
      const payouts = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as BookingPayout[];
      onUpdate(payouts);
    },
    (error) => {
      console.error('[Payouts Subscription Error]', error);
      onError(error as Error);
    }
  );
}

/**
 * Get a single booking payout by ID
 */
export async function getPayoutById(payoutId: string): Promise<BookingPayout | null> {
  const docRef = doc(db, COLLECTIONS.BOOKING_PAYOUTS, payoutId);
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) {
    return null;
  }

  return {
    id: docSnap.id,
    ...docSnap.data()
  } as BookingPayout;
}

/**
 * Subscribe to a single booking payout with real-time updates
 */
export function subscribeToPayoutById(
  payoutId: string,
  onUpdate: (payout: BookingPayout | null) => void,
  onError: (error: Error) => void
): Unsubscribe {
  const docRef = doc(db, COLLECTIONS.BOOKING_PAYOUTS, payoutId);

  return onSnapshot(
    docRef,
    (snapshot) => {
      if (!snapshot.exists()) {
        onUpdate(null);
        return;
      }
      
      const payout = {
        id: snapshot.id,
        ...snapshot.data()
      } as BookingPayout;
      onUpdate(payout);
    },
    (error) => {
      console.error('[Payout Subscription Error]', error);
      onError(error as Error);
    }
  );
}

// ============================================================================
// Wallet Withdrawals
// ============================================================================

/**
 * Get wallet withdrawals collection reference
 */
export function getWalletWithdrawalsRef() {
  return collection(db, COLLECTIONS.WALLET_WITHDRAWALS);
}

/**
 * Build query for wallet withdrawals with filters
 */
export function buildWithdrawalsQuery(filters: WithdrawalFilters, itemsPerPage: number = 20) {
  const constraints: QueryConstraint[] = [
    orderBy('requestedAt', 'desc'),
    limit(itemsPerPage)
  ];

  if (filters.status) {
    constraints.unshift(where('status', '==', filters.status));
  }

  if (filters.technicianId) {
    constraints.unshift(where('technicianId', '==', filters.technicianId));
  }

  return query(getWalletWithdrawalsRef(), ...constraints);
}

/**
 * Subscribe to wallet withdrawals with real-time updates
 */
export function subscribeToWithdrawals(
  filters: WithdrawalFilters,
  onUpdate: (withdrawals: WalletWithdrawal[]) => void,
  onError: (error: Error) => void,
  itemsPerPage: number = 20
): Unsubscribe {
  const q = buildWithdrawalsQuery(filters, itemsPerPage);

  return onSnapshot(
    q,
    (snapshot) => {
      const withdrawals = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as WalletWithdrawal[];
      onUpdate(withdrawals);
    },
    (error) => {
      console.error('[Withdrawals Subscription Error]', error);
      onError(error as Error);
    }
  );
}

/**
 * Get a single wallet withdrawal by ID
 */
export async function getWithdrawalById(withdrawalId: string): Promise<WalletWithdrawal | null> {
  const docRef = doc(db, COLLECTIONS.WALLET_WITHDRAWALS, withdrawalId);
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) {
    return null;
  }

  return {
    id: docSnap.id,
    ...docSnap.data()
  } as WalletWithdrawal;
}

/**
 * Subscribe to a single wallet withdrawal with real-time updates
 */
export function subscribeToWithdrawalById(
  withdrawalId: string,
  onUpdate: (withdrawal: WalletWithdrawal | null) => void,
  onError: (error: Error) => void
): Unsubscribe {
  const docRef = doc(db, COLLECTIONS.WALLET_WITHDRAWALS, withdrawalId);

  return onSnapshot(
    docRef,
    (snapshot) => {
      if (!snapshot.exists()) {
        onUpdate(null);
        return;
      }
      
      const withdrawal = {
        id: snapshot.id,
        ...snapshot.data()
      } as WalletWithdrawal;
      onUpdate(withdrawal);
    },
    (error) => {
      console.error('[Withdrawal Subscription Error]', error);
      onError(error as Error);
    }
  );
}

// ============================================================================
// Audit Logs
// ============================================================================

/**
 * Get audit logs collection reference
 */
export function getAuditLogsRef() {
  return collection(db, COLLECTIONS.AUDIT_LOGS);
}

/**
 * Build query for audit logs with filters
 */
export function buildAuditLogsQuery(filters: AuditLogFilters, itemsPerPage: number = 50) {
  const constraints: QueryConstraint[] = [
    orderBy('createdAt', 'desc'),
    limit(itemsPerPage)
  ];

  if (filters.actionType) {
    constraints.unshift(where('actionType', '==', filters.actionType));
  }

  if (filters.entityType) {
    constraints.unshift(where('entityType', '==', filters.entityType));
  }

  if (filters.adminId) {
    constraints.unshift(where('adminId', '==', filters.adminId));
  }

  return query(getAuditLogsRef(), ...constraints);
}

/**
 * Subscribe to audit logs with real-time updates
 */
export function subscribeToAuditLogs(
  filters: AuditLogFilters,
  onUpdate: (logs: AuditLog[]) => void,
  onError: (error: Error) => void,
  itemsPerPage: number = 50
): Unsubscribe {
  const q = buildAuditLogsQuery(filters, itemsPerPage);

  return onSnapshot(
    q,
    (snapshot) => {
      const logs = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as AuditLog[];
      onUpdate(logs);
    },
    (error) => {
      console.error('[Audit Logs Subscription Error]', error);
      onError(error as Error);
    }
  );
}

// ============================================================================
// App Settings
// ============================================================================

/**
 * Get app settings document reference
 */
export function getAppSettingsRef() {
  return doc(db, COLLECTIONS.APP_SETTINGS, SETTINGS_DOC_ID);
}

/**
 * Get app settings
 */
export async function getAppSettings(): Promise<AppSettings | null> {
  const docRef = getAppSettingsRef();
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) {
    return null;
  }

  return docSnap.data() as AppSettings;
}

/**
 * Subscribe to app settings with real-time updates
 */
export function subscribeToAppSettings(
  onUpdate: (settings: AppSettings | null) => void,
  onError: (error: Error) => void
): Unsubscribe {
  const docRef = getAppSettingsRef();

  return onSnapshot(
    docRef,
    (snapshot) => {
      if (!snapshot.exists()) {
        onUpdate(null);
        return;
      }
      
      const settings = snapshot.data() as AppSettings;
      onUpdate(settings);
    },
    (error) => {
      console.error('[Settings Subscription Error]', error);
      onError(error as Error);
    }
  );
}

// ============================================================================
// Cloud Functions
// ============================================================================

/**
 * Process booking payout (mark as paid)
 */
export async function processBookingPayout(
  request: ProcessBookingPayoutRequest
): Promise<ProcessBookingPayoutResponse> {
  try {
    const processPayoutFn = httpsCallable<
      ProcessBookingPayoutRequest,
      ProcessBookingPayoutResponse
    >(functions, 'processBookingPayout');

    const result = await processPayoutFn(request);
    return result.data;
  } catch (error: any) {
    console.error('[Process Payout Error]', error);
    throw new Error(error.message || 'Failed to process payout');
  }
}

/**
 * Approve wallet withdrawal
 */
export async function approveWalletWithdrawal(
  request: ApproveWalletWithdrawalRequest
): Promise<ApproveWalletWithdrawalResponse> {
  try {
    const approveWithdrawalFn = httpsCallable<
      ApproveWalletWithdrawalRequest,
      ApproveWalletWithdrawalResponse
    >(functions, 'approveWalletWithdrawal');

    const result = await approveWithdrawalFn(request);
    return result.data;
  } catch (error: any) {
    console.error('[Approve Withdrawal Error]', error);
    throw new Error(error.message || 'Failed to approve withdrawal');
  }
}

/**
 * Reject wallet withdrawal
 */
export async function rejectWalletWithdrawal(
  request: RejectWalletWithdrawalRequest
): Promise<RejectWalletWithdrawalResponse> {
  try {
    const rejectWithdrawalFn = httpsCallable<
      RejectWalletWithdrawalRequest,
      RejectWalletWithdrawalResponse
    >(functions, 'rejectWalletWithdrawal');

    const result = await rejectWithdrawalFn(request);
    return result.data;
  } catch (error: any) {
    console.error('[Reject Withdrawal Error]', error);
    throw new Error(error.message || 'Failed to reject withdrawal');
  }
}

/**
 * Update app settings
 */
export async function updateAppSettings(
  request: UpdateAppSettingsRequest
): Promise<UpdateAppSettingsResponse> {
  try {
    const updateSettingsFn = httpsCallable<
      UpdateAppSettingsRequest,
      UpdateAppSettingsResponse
    >(functions, 'updateAppSettings');

    const result = await updateSettingsFn(request);
    return result.data;
  } catch (error: any) {
    console.error('[Update Settings Error]', error);
    throw new Error(error.message || 'Failed to update settings');
  }
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Filter payouts by search term (client-side filtering)
 */
export function filterPayoutsBySearch(
  payouts: BookingPayout[],
  searchTerm: string
): BookingPayout[] {
  if (!searchTerm.trim()) {
    return payouts;
  }

  const term = searchTerm.toLowerCase();
  return payouts.filter(payout => 
    payout.technicianName.toLowerCase().includes(term) ||
    payout.bookingId.toLowerCase().includes(term)
  );
}

/**
 * Filter withdrawals by search term (client-side filtering)
 */
export function filterWithdrawalsBySearch(
  withdrawals: WalletWithdrawal[],
  searchTerm: string
): WalletWithdrawal[] {
  if (!searchTerm.trim()) {
    return withdrawals;
  }

  const term = searchTerm.toLowerCase();
  return withdrawals.filter(withdrawal => 
    withdrawal.technicianName.toLowerCase().includes(term)
  );
}

/**
 * Format currency for display
 */
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(amount);
}

/**
 * Format timestamp for display
 */
export function formatTimestamp(timestamp: Timestamp): string {
  return timestamp.toDate().toLocaleString('en-IN', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}

/**
 * Format date for display
 */
export function formatDate(timestamp: Timestamp): string {
  return timestamp.toDate().toLocaleDateString('en-IN', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
}
