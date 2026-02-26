/**
 * Booking Payouts List Page
 * 
 * Displays a paginated list of booking payouts with real-time updates,
 * filtering, search, and navigation to details page.
 * 
 * Requirements: 2.1, 2.2, 2.5, 2.6, 2.7, 18.1, 18.4, 18.5, 18.6
 */

'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { IndianRupee, Clock, CheckCircle2, AlertCircle, FileText } from 'lucide-react';
import { Card, CardHeader, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import Table from '@/components/ui/Table';
import StatusBadge from '@/components/ui/StatusBadge';
import LoadingState, { TableSkeleton } from '@/components/ui/LoadingState';
import ErrorState from '@/components/ui/ErrorState';
import EmptyState from '@/components/ui/EmptyState';
import FilterBar from '@/components/ui/FilterBar';
import { useBookingPayouts } from '@/hooks/useBookingPayouts';
import { formatCurrency, formatTimestamp } from '@/lib/firebase-finance';
import { PAYOUT_STATUS_OPTIONS, EMPTY_STATE_MESSAGES, ROUTES } from '@/constants/finance';
import type { BookingPayout, PayoutStatus } from '@/types/finance';

export default function BookingPayoutsPage() {
  const router = useRouter();
  const [statusFilter, setStatusFilter] = useState<PayoutStatus | ''>('');

  const {
    paginatedPayouts,
    filteredPayouts,
    loading,
    error,
    currentPage,
    totalPages,
    goToPage,
    nextPage,
    prevPage,
    hasNext,
    hasPrev,
    setSearchTerm,
    searchTerm,
    retry
  } = useBookingPayouts({
    filters: {
      status: statusFilter || undefined
    }
  });

  // Handle row click to navigate to details
  const handleRowClick = (payout: BookingPayout) => {
    router.push(ROUTES.BOOKING_PAYOUT_DETAILS(payout.id));
  };

  // Clear all filters
  const handleClearFilters = () => {
    setStatusFilter('');
    setSearchTerm('');
  };

  // Table columns configuration
  const columns = [
    {
      key: 'bookingId',
      label: 'Booking ID',
      render: (payout: BookingPayout) => (
        <div className="flex flex-col">
          <span className="font-semibold text-white text-sm">{payout.bookingId}</span>
          <span className="text-xs text-slate-500 font-mono">{payout.id.substring(0, 12)}...</span>
        </div>
      )
    },
    {
      key: 'technician',
      label: 'Technician',
      render: (payout: BookingPayout) => (
        <div className="flex flex-col">
          <span className="text-sm font-medium text-slate-200">{payout.technicianName}</span>
          <span className="text-xs text-slate-500">{payout.serviceName}</span>
        </div>
      )
    },
    {
      key: 'amounts',
      label: 'Amounts',
      render: (payout: BookingPayout) => (
        <div className="flex flex-col gap-1">
          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-500">Booking:</span>
            <span className="text-sm font-medium text-white">{formatCurrency(payout.bookingAmount)}</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-500">Commission:</span>
            <span className="text-sm text-slate-400">{formatCurrency(payout.platformCommissionAmount)}</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-500">Earning:</span>
            <span className="text-sm font-semibold text-emerald-400">{formatCurrency(payout.technicianEarning)}</span>
          </div>
        </div>
      )
    },
    {
      key: 'status',
      label: 'Status',
      render: (payout: BookingPayout) => (
        <StatusBadge status={payout.status} />
      )
    },
    {
      key: 'createdAt',
      label: 'Created',
      render: (payout: BookingPayout) => (
        <span className="text-sm text-slate-400">{formatTimestamp(payout.createdAt)}</span>
      )
    }
  ];

  return (
    <div className="space-y-6 max-w-[1400px] mx-auto pb-20">
      {/* Page Header */}
      <header className="flex flex-col gap-2">
        <h1 className="text-3xl font-black text-white tracking-tight uppercase">
          Booking Payouts
        </h1>
        <p className="text-slate-400 text-sm">
          Manage and monitor technician booking payouts
        </p>
      </header>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="bg-slate-900/40 border-slate-800/50">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-2">
              <div className="p-2 bg-indigo-500/10 text-indigo-400 rounded-lg">
                <IndianRupee size={20} />
              </div>
              <span className="text-xs font-bold text-slate-500 uppercase">Total</span>
            </div>
            <h3 className="text-2xl font-black text-white">
              {filteredPayouts.length}
            </h3>
            <p className="text-xs text-slate-500 mt-1">Payouts</p>
          </CardContent>
        </Card>

        <Card className="bg-slate-900/40 border-slate-800/50">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-2">
              <div className="p-2 bg-amber-500/10 text-amber-400 rounded-lg">
                <Clock size={20} />
              </div>
              <span className="text-xs font-bold text-slate-500 uppercase">Pending</span>
            </div>
            <h3 className="text-2xl font-black text-white">
              {filteredPayouts.filter(p => p.status === 'pending').length}
            </h3>
            <p className="text-xs text-slate-500 mt-1">Awaiting</p>
          </CardContent>
        </Card>

        <Card className="bg-slate-900/40 border-slate-800/50">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-2">
              <div className="p-2 bg-emerald-500/10 text-emerald-400 rounded-lg">
                <CheckCircle2 size={20} />
              </div>
              <span className="text-xs font-bold text-slate-500 uppercase">Completed</span>
            </div>
            <h3 className="text-2xl font-black text-white">
              {filteredPayouts.filter(p => p.status === 'completed').length}
            </h3>
            <p className="text-xs text-slate-500 mt-1">Paid</p>
          </CardContent>
        </Card>

        <Card className="bg-slate-900/40 border-slate-800/50">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-2">
              <div className="p-2 bg-red-500/10 text-red-400 rounded-lg">
                <AlertCircle size={20} />
              </div>
              <span className="text-xs font-bold text-slate-500 uppercase">Failed</span>
            </div>
            <h3 className="text-2xl font-black text-white">
              {filteredPayouts.filter(p => p.status === 'failed').length}
            </h3>
            <p className="text-xs text-slate-500 mt-1">Errors</p>
          </CardContent>
        </Card>
      </div>

      {/* Filter Bar */}
      <FilterBar
        searchPlaceholder="Search by technician name or booking ID..."
        searchValue={searchTerm}
        onSearchChange={setSearchTerm}
        filters={[
          {
            key: 'status',
            label: 'Status',
            options: PAYOUT_STATUS_OPTIONS.slice(1).map(opt => ({
              value: opt.value as string,
              label: opt.label
            }))
          }
        ]}
        filterValues={{ status: statusFilter }}
        onFilterChange={(key, value) => {
          if (key === 'status') {
            setStatusFilter(value as PayoutStatus | '');
          }
        }}
        onClearFilters={handleClearFilters}
      />

      {/* Main Content Card */}
      <Card className="border-slate-800/50 bg-slate-900/40 overflow-hidden">
        <CardContent className="p-0">
          {/* Loading State */}
          {loading && (
            <div className="p-6">
              <TableSkeleton rows={5} columns={5} />
            </div>
          )}

          {/* Error State */}
          {error && !loading && (
            <ErrorState
              title="Failed to Load Payouts"
              message={error.message || 'Unable to fetch payout data. Please try again.'}
              onRetry={retry}
              showRetry={true}
            />
          )}

          {/* Empty State */}
          {!loading && !error && paginatedPayouts.length === 0 && (
            <EmptyState
              icon={FileText}
              title={searchTerm || statusFilter ? EMPTY_STATE_MESSAGES.NO_SEARCH_RESULTS : EMPTY_STATE_MESSAGES.NO_PAYOUTS}
              description={searchTerm || statusFilter ? EMPTY_STATE_MESSAGES.NO_SEARCH_RESULTS_DESC : EMPTY_STATE_MESSAGES.NO_PAYOUTS_DESC}
              action={searchTerm || statusFilter ? {
                label: 'Clear Filters',
                onClick: handleClearFilters
              } : undefined}
            />
          )}

          {/* Data Table */}
          {!loading && !error && paginatedPayouts.length > 0 && (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-slate-950/20 border-b border-slate-800/50">
                  <tr>
                    {columns.map((col) => (
                      <th
                        key={col.key}
                        className="px-6 py-4 text-left text-xs font-bold text-slate-500 uppercase tracking-wider"
                      >
                        {col.label}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/50">
                  {paginatedPayouts.map((payout) => (
                    <tr
                      key={payout.id}
                      onClick={() => handleRowClick(payout)}
                      className="hover:bg-indigo-500/5 cursor-pointer transition-colors"
                    >
                      {columns.map((col) => (
                        <td key={col.key} className="px-6 py-4">
                          {col.render ? col.render(payout) : payout[col.key as keyof BookingPayout]}
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>

        {/* Pagination */}
        {!loading && !error && paginatedPayouts.length > 0 && totalPages > 1 && (
          <div className="p-6 border-t border-slate-800/50 flex items-center justify-between">
            <div className="text-sm text-slate-400">
              Page {currentPage} of {totalPages}
            </div>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={prevPage}
                disabled={!hasPrev}
                className="bg-slate-950/50 border-slate-800"
              >
                Previous
              </Button>
              
              {/* Page Numbers */}
              <div className="flex items-center gap-1">
                {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                  let pageNum: number;
                  if (totalPages <= 5) {
                    pageNum = i + 1;
                  } else if (currentPage <= 3) {
                    pageNum = i + 1;
                  } else if (currentPage >= totalPages - 2) {
                    pageNum = totalPages - 4 + i;
                  } else {
                    pageNum = currentPage - 2 + i;
                  }

                  return (
                    <Button
                      key={pageNum}
                      variant={currentPage === pageNum ? 'default' : 'outline'}
                      size="sm"
                      onClick={() => goToPage(pageNum)}
                      className={currentPage === pageNum ? 'bg-indigo-600' : 'bg-slate-950/50 border-slate-800'}
                    >
                      {pageNum}
                    </Button>
                  );
                })}
              </div>

              <Button
                variant="outline"
                size="sm"
                onClick={nextPage}
                disabled={!hasNext}
                className="bg-slate-950/50 border-slate-800"
              >
                Next
              </Button>
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}
