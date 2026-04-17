/**
 * useWithdrawalRequests Hook
 * 
 * Custom React hook for managing withdrawal requests with admin approval workflow.
 * Provides real-time updates, filtering, and approval/rejection actions.
 */

'use client';

import { useState, useEffect, useMemo } from 'react';
import { collection, query, where, onSnapshot, orderBy, limit, Unsubscribe } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { getFunctions, httpsCallable } from 'firebase/functions';

export interface WithdrawalRequest {
  requestId: string;
  technicianId: string;
  technicianName: string;
  technicianPhone: string;
  amount: number;
  fee: number;
  netAmount: number;
  status: 'pending' | 'approved' | 'rejected' | 'failed';
  walletBalanceAtRequest: number;
  createdAt: any;
  approvedAt?: any;
  rejectedAt?: any;
  approvedBy?: string;
  rejectedBy?: string;
  rejectionReason?: string;
  razorpayPayoutId?: string;
}

interface UseWithdrawalRequestsOptions {
  status?: string;
  itemsPerPage?: number;
}

interface UseWithdrawalRequestsReturn {
  requests: WithdrawalRequest[];
  filteredRequests: WithdrawalRequest[];
  loading: boolean;
  error: Error | null;
  currentPage: number;
  totalPages: number;
  paginatedRequests: WithdrawalRequest[];
  goToPage: (page: number) => void;
  nextPage: () => void;
  prevPage: () => void;
  hasNext: boolean;
  hasPrev: boolean;
  setSearchTerm: (term: string) => void;
  searchTerm: string;
  approveRequest: (requestId: string) => Promise<void>;
  rejectRequest: (requestId: string, reason: string) => Promise<void>;
  approving: boolean;
  rejecting: boolean;
  retry: () => void;
}

const ITEMS_PER_PAGE = 20;

export function useWithdrawalRequests(
  options: UseWithdrawalRequestsOptions = {}
): UseWithdrawalRequestsReturn {
  const { status = 'pending', itemsPerPage = ITEMS_PER_PAGE } = options;

  const [requests, setRequests] = useState<WithdrawalRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [approving, setApproving] = useState(false);
  const [rejecting, setRejecting] = useState(false);
  const [retryCount, setRetryCount] = useState(0);

  // Subscribe to Firestore real-time updates
  useEffect(() => {
    setLoading(true);
    setError(null);

    let q = query(
      collection(db, 'withdrawal_requests'),
      orderBy('createdAt', 'desc'),
      limit(100)
    );

    if (status && status !== 'all') {
      q = query(q, where('status', '==', status));
    }

    const unsubscribe: Unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const requestsData: WithdrawalRequest[] = snapshot.docs.map(doc => ({
          requestId: doc.id,
          ...doc.data()
        } as WithdrawalRequest));
        setRequests(requestsData);
        setLoading(false);
        setError(null);
      },
      (err) => {
        console.error('[useWithdrawalRequests Error]', {
          error: err,
          status,
          timestamp: new Date().toISOString()
        });
        setError(err as Error);
        setLoading(false);
      }
    );

    return () => {
      unsubscribe();
    };
  }, [status, retryCount]);

  // Apply client-side search filtering
  const filteredRequests = useMemo(() => {
    if (!searchTerm) return requests;
    
    const term = searchTerm.toLowerCase();
    return requests.filter(r => 
      r.technicianName?.toLowerCase().includes(term) ||
      r.technicianPhone?.toLowerCase().includes(term) ||
      r.technicianId.toLowerCase().includes(term) ||
      r.requestId.toLowerCase().includes(term)
    );
  }, [requests, searchTerm]);

  // Calculate pagination
  const totalPages = Math.ceil(filteredRequests.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const paginatedRequests = filteredRequests.slice(startIndex, endIndex);

  // Pagination controls
  const goToPage = (page: number) => {
    const validPage = Math.max(1, Math.min(page, totalPages));
    setCurrentPage(validPage);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const nextPage = () => {
    if (currentPage < totalPages) {
      goToPage(currentPage + 1);
    }
  };

  const prevPage = () => {
    if (currentPage > 1) {
      goToPage(currentPage - 1);
    }
  };

  const hasNext = currentPage < totalPages;
  const hasPrev = currentPage > 1;

  // Approve withdrawal request
  const approveRequest = async (requestId: string) => {
    setApproving(true);
    try {
      const functions = getFunctions();
      const approveWithdrawalRequest = httpsCallable(functions, 'approveWithdrawalRequest');
      await approveWithdrawalRequest({ requestId });
    } catch (err: any) {
      console.error('[Approve Request Error]', err);
      throw new Error(err.message || 'Failed to approve withdrawal request');
    } finally {
      setApproving(false);
    }
  };

  // Reject withdrawal request
  const rejectRequest = async (requestId: string, reason: string) => {
    setRejecting(true);
    try {
      const functions = getFunctions();
      const rejectWithdrawalRequest = httpsCallable(functions, 'rejectWithdrawalRequest');
      await rejectWithdrawalRequest({ requestId, reason });
    } catch (err: any) {
      console.error('[Reject Request Error]', err);
      throw new Error(err.message || 'Failed to reject withdrawal request');
    } finally {
      setRejecting(false);
    }
  };

  // Retry function for error recovery
  const retry = () => {
    setRetryCount(prev => prev + 1);
  };

  // Reset to page 1 when search term or status changes
  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, status]);

  return {
    requests,
    filteredRequests,
    loading,
    error,
    currentPage,
    totalPages,
    paginatedRequests,
    goToPage,
    nextPage,
    prevPage,
    hasNext,
    hasPrev,
    setSearchTerm,
    searchTerm,
    approveRequest,
    rejectRequest,
    approving,
    rejecting,
    retry
  };
}
