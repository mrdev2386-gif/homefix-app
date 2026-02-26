/**
 * Wallet Withdrawals List Page
 * 
 * Displays a paginated list of wallet withdrawal requests with real-time updates,
 * filtering, search, and navigation to details page.
 * 
 * Requirements: 5.1, 5.2, 5.5, 5.6, 5.7, 18.2, 18.4, 18.5, 18.6
 */

'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Wallet, Clock, CheckCircle2, XCircle, FileText } from 'lucide-react';
import { Card, CardHeader, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import Table from '@/components/ui/Table';
import StatusBadge from '@/components/ui/StatusBadge';
import LoadingState, { TableSkeleton } from '@/components/ui/LoadingState';
import ErrorState from '@/components/ui/ErrorState';
import EmptyState from '@/components/ui/EmptyState';
import FilterBar from '@/components/ui/FilterBar';
import { useWalletWithdrawals } from '@/hooks/useWalletWithdrawals';
import { formatCurrency, formatTimestamp } from '@/lib/firebase-finance';
import { WITHDRAWAL_STATUS_OPTIONS, EMPTY_STATE_MESSAGES, ROUTES } from '@/constants/finance';
import type { WalletWithdrawal, WithdrawalStatus } from '@/types/finance';

export default function WalletWithdrawalsPage() {
  const router = useRouter();
  const [statusFilter, setStatusFilter] = useState<WithdrawalStatus | ''>('');

  const {
    paginatedWithdrawals,
    filteredWithdrawals,
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
  } = useWalletWithdrawals({
    filters: {
      status: statusFilter || undefined
    }
  });

  // Handle row click to navigate to details
  const handleRowClick = (withdrawal: WalletWithdrawal) => {
    router.push(ROUTES.WALLET_WITHDRAWAL_DETAILS(withdrawal.id));
  };

  // Clear all filters
  const handleClearFilters = () => {
    setStatusFilter('');
    setSearchTerm('');
  };

  // Table columns configuration
  const columns = [
    {
      key: 'technician',
      label: 'Technician',
      render: (withdrawal: WalletWithdrawal) => (
        <div className="flex flex-col">
          <span className="text-sm font-medium text-slate-200">{withdrawal.technicianName}</span>
          <span className="text-xs text-slate-500 font-mono">{withdrawal.id.substring(0, 12)}...</span>
        </div>
      )
    },
    {
      key: 'amount',
      label: 'Amount',
      render: (withdrawal: WalletWithdrawal) => (
        <span className="text-sm font-semibold text-emerald-400">{formatCurrency(withdrawal.amount)}</span>
      )
    },
    {
      key: 'bankDetails',
      label: 'Bank Details',
      render: (withdrawal: WalletWithdrawal) => (
        <div className="flex flex-col gap-1">
          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-500">Account:</span>
            <span className="text-sm font-medium text-white font-mono">
              ****{withdrawal.bankAccountNumber.slice(-4)}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-500">Name:</span>
            <span className="text-sm text-slate-400">{withdrawal.bankAccountName}</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-500">Bank:</span>
            <span className="text-sm text-slate-400">{withdrawal.bankName}</span>
          </div>
        </div>
      )
    },
    {
      key: 'ifscCode',
      label: 'IFSC Code',
      render: (withdrawal: WalletWithdrawal) => (
        <span className="text-sm font-mono text-slate-300">{withdrawal.ifscCode}</span>
      )
    },
    {
      key: 'status',
      label: 'Status',
      render: (withdrawal: WalletWithdrawal) => (
        <StatusBadge status={withdrawal.status} />
      )
    },
    {
      key: 'requestedAt',
      label: 'Requested',
      render: (withdrawal: WalletWithdrawal) => (
        <span className="text-sm text-slate-400">{formatTimestamp(withdrawal.requestedAt)}</span>
      )
    }
  ];

  return (
    <div className="space-y-6 max-w-[1400px] mx-auto pb-20">
      {/* Page Header */}
      <header className="flex flex-col gap-2">
        <h1 className="text-3xl font-black text-white tracking-tight uppercase">
          Wallet Withdrawals
        </h1>
        <p className="text-slate-400 text-sm">
          Manage and process technician wallet withdrawal requests
        </p>
      </header>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="bg-slate-900/40 border-slate-800/50">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-2">
              <div className="p-2 bg-indigo-500/10 text-indigo-400 rounded-lg">
                <Wallet size={20} />
              </div>
              <span className="text-xs font-bold text-slate-500 uppercase">Total</span>
            </div>
            <h3 className="text-2xl font-black text-white">
              {filteredWithdrawals.length}
            </h3>
            <p className="text-xs text-slate-500 mt-1">Requests</p>
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
              {filteredWithdrawals.filter(w => w.status === 'pending').length}
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
              <span className="text-xs font-bold text-slate-500 uppercase">Approved</span>
            </div>
            <h3 className="text-2xl font-black text-white">
              {filteredWithdrawals.filter(w => w.status === 'approved' || w.status === 'completed').length}
            </h3>
            <p className="text-xs text-slate-500 mt-1">Processed</p>
          </CardContent>
        </Card>

        <Card className="bg-slate-900/40 border-slate-800/50">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-2">
              <div className="p-2 bg-red-500/10 text-red-400 rounded-lg">
                <XCircle size={20} />
              </div>
              <span className="text-xs font-bold text-slate-500 uppercase">Rejected</span>
            </div>
            <h3 className="text-2xl font-black text-white">
              {filteredWithdrawals.filter(w => w.status === 'rejected').length}
            </h3>
            <p className="text-xs text-slate-500 mt-1">Declined</p>
          </CardContent>
        </Card>
      </div>

      {/* Filter Bar */}
      <FilterBar
        searchPlaceholder="Search by technician name..."
        searchValue={searchTerm}
        onSearchChange={setSearchTerm}
        filters={[
          {
            key: 'status',
            label: 'Status',
            options: WITHDRAWAL_STATUS_OPTIONS.slice(1).map(opt => ({
              value: opt.value as string,
              label: opt.label
            }))
          }
        ]}
        filterValues={{ status: statusFilter }}
        onFilterChange={(key, value) => {
          if (key === 'status') {
            setStatusFilter(value as WithdrawalStatus | '');
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
              <TableSkeleton rows={5} columns={6} />
            </div>
          )}

          {/* Error State */}
          {error && !loading && (
            <ErrorState
              title="Failed to Load Withdrawals"
              message={error.message || 'Unable to fetch withdrawal data. Please try again.'}
              onRetry={retry}
              showRetry={true}
            />
          )}

          {/* Empty State */}
          {!loading && !error && paginatedWithdrawals.length === 0 && (
            <EmptyState
              icon={FileText}
              title={searchTerm || statusFilter ? EMPTY_STATE_MESSAGES.NO_SEARCH_RESULTS : EMPTY_STATE_MESSAGES.NO_WITHDRAWALS}
              description={searchTerm || statusFilter ? EMPTY_STATE_MESSAGES.NO_SEARCH_RESULTS_DESC : EMPTY_STATE_MESSAGES.NO_WITHDRAWALS_DESC}
              action={searchTerm || statusFilter ? {
                label: 'Clear Filters',
                onClick: handleClearFilters
              } : undefined}
            />
          )}

          {/* Data Table */}
          {!loading && !error && paginatedWithdrawals.length > 0 && (
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
                  {paginatedWithdrawals.map((withdrawal) => (
                    <tr
                      key={withdrawal.id}
                      onClick={() => handleRowClick(withdrawal)}
                      className="hover:bg-indigo-500/5 cursor-pointer transition-colors"
                    >
                      {columns.map((col) => (
                        <td key={col.key} className="px-6 py-4">
                          {col.render(withdrawal)}
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
        {!loading && !error && paginatedWithdrawals.length > 0 && totalPages > 1 && (
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
