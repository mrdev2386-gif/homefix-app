/**
 * Booking Payout Details Page
 * 
 * Displays detailed information about a specific booking payout with real-time updates.
 * Allows admins to mark pending payouts as paid through a secure Cloud Function.
 * 
 * Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 19.1, 19.5, 25
 */

'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { ArrowLeft, IndianRupee, User, Calendar, CheckCircle2 } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import StatusBadge from '@/components/ui/StatusBadge';
import LoadingState from '@/components/ui/LoadingState';
import ErrorState from '@/components/ui/ErrorState';
import ConfirmDialog from '@/components/ui/ConfirmDialog';
import { subscribeToPayoutById } from '@/lib/firebase-finance';
import { useProcessPayout } from '@/hooks/useProcessPayout';
import { formatCurrency, formatTimestamp } from '@/lib/firebase-finance';
import { ROUTES, SUCCESS_MESSAGES } from '@/constants/finance';
import type { BookingPayout } from '@/types/finance';

interface BookingPayoutDetailsPageProps {
  params: {
    id: string;
  };
}

export default function BookingPayoutDetailsPage({ params }: BookingPayoutDetailsPageProps) {
  const router = useRouter();
  const { id } = params;

  // State
  const [payout, setPayout] = useState<BookingPayout | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [showConfirmDialog, setShowConfirmDialog] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Hooks
  const { processPayout, processing, error: processError } = useProcessPayout();

  // Subscribe to real-time updates
  useEffect(() => {
    setLoading(true);
    setError(null);

    const unsubscribe = subscribeToPayoutById(
      id,
      (updatedPayout) => {
        setPayout(updatedPayout);
        setLoading(false);
      },
      (err) => {
        console.error('[Payout Details Error]', err);
        setError(err);
        setLoading(false);
      }
    );

    // Cleanup listener on unmount
    return () => unsubscribe();
  }, [id]);

  // Handle mark as paid
  const handleMarkAsPaid = async () => {
    setShowConfirmDialog(false);
    setSuccessMessage(null);

    const result = await processPayout(id);
    
    if (result.success) {
      setSuccessMessage(SUCCESS_MESSAGES.PAYOUT_PROCESSED);
      // Success message will auto-hide after 3 seconds
      setTimeout(() => setSuccessMessage(null), 3000);
    }
  };

  // Handle back navigation
  const handleBack = () => {
    router.push(ROUTES.BOOKING_PAYOUTS);
  };

  // Handle retry
  const handleRetry = () => {
    setLoading(true);
    setError(null);
    // Re-trigger subscription by forcing component re-mount logic
    window.location.reload();
  };

  // Loading state
  if (loading) {
    return (
      <div className="space-y-6 max-w-[1200px] mx-auto pb-20">
        <LoadingState message="Loading payout details..." />
      </div>
    );
  }

  // Error state
  if (error || !payout) {
    return (
      <div className="space-y-6 max-w-[1200px] mx-auto pb-20">
        <Button
          variant="ghost"
          onClick={handleBack}
          className="mb-4"
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back to Payouts
        </Button>
        <ErrorState
          title="Failed to Load Payout"
          message={error?.message || 'Payout not found or unable to fetch payout data.'}
          onRetry={handleRetry}
          showRetry={true}
        />
      </div>
    );
  }

  // Determine if "Mark as Paid" button should be shown
  const canMarkAsPaid = payout.status === 'pending';

  return (
    <div className="space-y-6 max-w-[1200px] mx-auto pb-20">
      {/* Back Button */}
      <Button
        variant="ghost"
        onClick={handleBack}
        className="mb-4"
      >
        <ArrowLeft className="w-4 h-4 mr-2" />
        Back to Payouts
      </Button>

      {/* Success Message */}
      {successMessage && (
        <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-lg p-4 flex items-center gap-3">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <p className="text-emerald-400 font-semibold">{successMessage}</p>
        </div>
      )}

      {/* Error Message */}
      {processError && (
        <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
          <p className="text-red-400 font-semibold">{processError}</p>
        </div>
      )}

      {/* Page Header */}
      <header className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black text-white tracking-tight uppercase mb-2">
            Payout Details
          </h1>
          <p className="text-slate-400 text-sm">
            Booking ID: <span className="font-mono text-slate-300">{payout.bookingId}</span>
          </p>
        </div>
        <div className="flex items-center gap-3">
          <StatusBadge status={payout.status} />
          {canMarkAsPaid && (
            <Button
              onClick={() => setShowConfirmDialog(true)}
              disabled={processing}
              isLoading={processing}
              className="bg-emerald-600 hover:bg-emerald-700"
            >
              {processing ? 'Processing...' : 'Mark as Paid'}
            </Button>
          )}
        </div>
      </header>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Technician Information */}
        <Card className="border-slate-800/50 bg-slate-900/40">
          <CardContent className="p-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="p-2 bg-indigo-500/10 text-indigo-400 rounded-lg">
                <User size={20} />
              </div>
              <h2 className="text-lg font-black text-white uppercase tracking-wide">
                Technician Info
              </h2>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">
                  Name
                </label>
                <p className="text-white font-semibold">{payout.technicianName}</p>
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">
                  Technician ID
                </label>
                <p className="text-slate-300 font-mono text-sm">{payout.technicianId}</p>
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">
                  Service
                </label>
                <p className="text-white font-semibold">{payout.serviceName}</p>
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">
                  Service ID
                </label>
                <p className="text-slate-300 font-mono text-sm">{payout.serviceId}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Payment Amounts */}
        <Card className="border-slate-800/50 bg-slate-900/40">
          <CardContent className="p-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="p-2 bg-emerald-500/10 text-emerald-400 rounded-lg">
                <IndianRupee size={20} />
              </div>
              <h2 className="text-lg font-black text-white uppercase tracking-wide">
                Payment Details
              </h2>
            </div>
            <div className="space-y-4">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                <label className="text-sm font-bold text-slate-400 uppercase tracking-wide">
                  Booking Amount
                </label>
                <p className="text-white font-semibold text-lg">{formatCurrency(payout.bookingAmount)}</p>
              </div>
              <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                <label className="text-sm font-bold text-slate-400 uppercase tracking-wide">
                  Platform Commission ({payout.platformCommissionPercentage}%)
                </label>
                <p className="text-slate-400 font-semibold">-{formatCurrency(payout.platformCommissionAmount)}</p>
              </div>
              <div className="flex items-center justify-between pt-2">
                <label className="text-sm font-bold text-emerald-400 uppercase tracking-wide">
                  Technician Earning
                </label>
                <p className="text-emerald-400 font-black text-2xl">{formatCurrency(payout.technicianEarning)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Payout Information */}
        <Card className="border-slate-800/50 bg-slate-900/40">
          <CardContent className="p-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="p-2 bg-blue-500/10 text-blue-400 rounded-lg">
                <Calendar size={20} />
              </div>
              <h2 className="text-lg font-black text-white uppercase tracking-wide">
                Payout Info
              </h2>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">
                  Payout ID
                </label>
                <p className="text-slate-300 font-mono text-sm">{payout.id}</p>
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">
                  Payout Method
                </label>
                <p className="text-white font-semibold capitalize">{payout.payoutMethod.replace('_', ' ')}</p>
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">
                  Status
                </label>
                <div className="mt-1">
                  <StatusBadge status={payout.status} />
                </div>
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">
                  Created At
                </label>
                <p className="text-slate-300">{formatTimestamp(payout.createdAt)}</p>
              </div>
              {payout.status === 'completed' && payout.paidAt && (
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">
                    Paid At
                  </label>
                  <p className="text-emerald-400 font-semibold">{formatTimestamp(payout.paidAt)}</p>
                </div>
              )}
              {payout.processedBy && (
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">
                    Processed By
                  </label>
                  <p className="text-slate-300 font-mono text-sm">{payout.processedBy}</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Additional Notes (if any) */}
        {payout.notes && (
          <Card className="border-slate-800/50 bg-slate-900/40">
            <CardContent className="p-6">
              <h2 className="text-lg font-black text-white uppercase tracking-wide mb-4">
                Notes
              </h2>
              <p className="text-slate-300">{payout.notes}</p>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Confirm Dialog */}
      <ConfirmDialog
        isOpen={showConfirmDialog}
        title="Confirm Payment"
        message={`Are you sure you want to mark this payout as paid? This will process a payment of ${formatCurrency(payout.technicianEarning)} to ${payout.technicianName}.`}
        confirmText="Mark as Paid"
        cancelText="Cancel"
        onConfirm={handleMarkAsPaid}
        onCancel={() => setShowConfirmDialog(false)}
        variant="default"
      />
    </div>
  );
}
