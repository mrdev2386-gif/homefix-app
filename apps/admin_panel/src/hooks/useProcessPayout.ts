/**
 * useProcessPayout Hook
 * 
 * Custom React hook for processing booking payouts (marking as paid).
 * Invokes the processBookingPayout Cloud Function with authentication token.
 * Manages loading, success, and error states.
 */

'use client';

import { useState } from 'react';
import { processBookingPayout } from '@/lib/firebase-finance';
import type { ProcessBookingPayoutRequest } from '@/types/finance';

interface UseProcessPayoutReturn {
  processPayout: (payoutId: string) => Promise<{ success: boolean; error?: string }>;
  processing: boolean;
  error: string | null;
}

/**
 * Hook for processing booking payouts through Cloud Function
 * 
 * @returns Object containing processPayout function, processing state, and error state
 * 
 * @example
 * ```tsx
 * const { processPayout, processing, error } = useProcessPayout();
 * 
 * const handleMarkAsPaid = async () => {
 *   const result = await processPayout(payoutId);
 *   if (result.success) {
 *     // Show success message
 *   }
 * };
 * ```
 */
export function useProcessPayout(): UseProcessPayoutReturn {
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  /**
   * Process a booking payout by marking it as paid
   * 
   * @param payoutId - The ID of the payout to process
   * @returns Promise with success status and optional error message
   */
  const processPayout = async (payoutId: string): Promise<{ success: boolean; error?: string }> => {
    // Reset error state
    setError(null);
    setProcessing(true);

    try {
      // Validate input
      if (!payoutId || typeof payoutId !== 'string') {
        throw new Error('Invalid payout ID');
      }

      // Prepare request
      const request: ProcessBookingPayoutRequest = {
        payoutId
      };

      // Invoke Cloud Function with auth token
      const response = await processBookingPayout(request);

      // Check response
      if (response.success) {
        setProcessing(false);
        return { success: true };
      } else {
        throw new Error(response.message || 'Failed to process payout');
      }
    } catch (err: any) {
      const errorMessage = err.message || 'An unexpected error occurred while processing the payout';
      
      // Log error for debugging
      console.error('[useProcessPayout Error]', {
        payoutId,
        error: err,
        timestamp: new Date().toISOString()
      });

      setError(errorMessage);
      setProcessing(false);
      
      return { 
        success: false, 
        error: errorMessage 
      };
    }
  };

  return {
    processPayout,
    processing,
    error
  };
}
