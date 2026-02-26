/**
 * useWalletWithdrawals Hook
 * 
 * Custom React hook for managing wallet withdrawals with Firestore real-time listeners.
 * Provides pagination, filtering, and search capabilities.
 */

'use client';

import { useState, useEffect, useMemo } from 'react';
import type { WalletWithdrawal, WithdrawalFilters } from '@/types/finance';
import { 
  subscribeToWithdrawals, 
  filterWithdrawalsBySearch 
} from '@/lib/firebase-finance';
import { PAGINATION } from '@/constants/finance';

interface UseWalletWithdrawalsOptions {
  filters?: WithdrawalFilters;
  itemsPerPage?: number;
}

interface UseWalletWithdrawalsReturn {
  withdrawals: WalletWithdrawal[];
  filteredWithdrawals: WalletWithdrawal[];
  loading: boolean;
  error: Error | null;
  currentPage: number;
  totalPages: number;
  paginatedWithdrawals: WalletWithdrawal[];
  goToPage: (page: number) => void;
  nextPage: () => void;
  prevPage: () => void;
  hasNext: boolean;
  hasPrev: boolean;
  setSearchTerm: (term: string) => void;
  searchTerm: string;
  retry: () => void;
}

/**
 * Hook for managing wallet withdrawals with real-time updates
 */
export function useWalletWithdrawals(
  options: UseWalletWithdrawalsOptions = {}
): UseWalletWithdrawalsReturn {
  const { 
    filters = {}, 
    itemsPerPage = PAGINATION.WITHDRAWALS_PER_PAGE 
  } = options;

  const [withdrawals, setWithdrawals] = useState<WalletWithdrawal[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [retryCount, setRetryCount] = useState(0);

  // Subscribe to Firestore real-time updates
  useEffect(() => {
    setLoading(true);
    setError(null);

    const unsubscribe = subscribeToWithdrawals(
      filters,
      (updatedWithdrawals) => {
        setWithdrawals(updatedWithdrawals);
        setLoading(false);
        setError(null);
      },
      (err) => {
        console.error('[useWalletWithdrawals Error]', {
          error: err,
          filters,
          timestamp: new Date().toISOString()
        });
        setError(err);
        setLoading(false);
      },
      itemsPerPage * 10 // Fetch more items for client-side pagination
    );

    // Cleanup listener on unmount
    return () => {
      unsubscribe();
    };
  }, [filters.status, filters.technicianId, itemsPerPage, retryCount]);

  // Apply client-side search filtering
  const filteredWithdrawals = useMemo(() => {
    return filterWithdrawalsBySearch(withdrawals, searchTerm);
  }, [withdrawals, searchTerm]);

  // Calculate pagination
  const totalPages = Math.ceil(filteredWithdrawals.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const paginatedWithdrawals = filteredWithdrawals.slice(startIndex, endIndex);

  // Pagination controls
  const goToPage = (page: number) => {
    const validPage = Math.max(1, Math.min(page, totalPages));
    setCurrentPage(validPage);
    
    // Scroll to top of content area
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

  // Retry function for error recovery
  const retry = () => {
    setRetryCount(prev => prev + 1);
  };

  // Reset to page 1 when search term or filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, filters.status, filters.technicianId]);

  return {
    withdrawals,
    filteredWithdrawals,
    loading,
    error,
    currentPage,
    totalPages,
    paginatedWithdrawals,
    goToPage,
    nextPage,
    prevPage,
    hasNext,
    hasPrev,
    setSearchTerm,
    searchTerm,
    retry
  };
}
