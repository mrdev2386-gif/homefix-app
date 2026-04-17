'use client';

import { useState } from 'react';
import { Wallet, CheckCircle, XCircle, Clock, AlertCircle, Search, Filter, X, RefreshCw } from 'lucide-react';
import { useWithdrawalRequests } from '@/hooks/useWithdrawalRequests';
import ConfirmDialog from '@/components/ui/ConfirmDialog';
import LoadingState, { TableSkeleton } from '@/components/ui/LoadingState';
import { Timestamp } from 'firebase/firestore';

export default function WithdrawalsPage() {
  const [statusFilter, setStatusFilter] = useState('pending');
  const {
    paginatedRequests,
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
    approveRequest,
    rejectRequest,
    approving,
    rejecting,
    retry,
    filteredRequests
  } = useWithdrawalRequests({ status: statusFilter });

  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    onConfirm: (inputValue?: string) => void;
    variant?: 'default' | 'danger';
    requireInput?: boolean;
    inputLabel?: string;
    inputPlaceholder?: string;
  }>({ isOpen: false, title: '', message: '', onConfirm: () => {} });

  const handleApprove = (requestId: string, technicianName: string, amount: number) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Approve Withdrawal',
      message: `Are you sure you want to approve withdrawal of ₹${amount} for ${technicianName}? This will deduct the balance and process the payout immediately.`,
      variant: 'default',
      onConfirm: async () => {
        try {
          await approveRequest(requestId);
          setConfirmDialog({ ...confirmDialog, isOpen: false });
          
          // Show success message
          const successDiv = document.createElement('div');
          successDiv.className = 'fixed top-4 right-4 bg-green-600 text-white px-6 py-3 rounded-lg shadow-lg z-50';
          successDiv.textContent = 'Withdrawal approved successfully';
          document.body.appendChild(successDiv);
          setTimeout(() => successDiv.remove(), 3000);
        } catch (err: any) {
          setConfirmDialog({ ...confirmDialog, isOpen: false });
          
          // Show error message
          const errorDiv = document.createElement('div');
          errorDiv.className = 'fixed top-4 right-4 bg-red-600 text-white px-6 py-3 rounded-lg shadow-lg z-50';
          errorDiv.textContent = err.message || 'Failed to approve withdrawal';
          document.body.appendChild(errorDiv);
          setTimeout(() => errorDiv.remove(), 5000);
        }
      }
    });
  };

  const handleReject = (requestId: string, technicianName: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Reject Withdrawal',
      message: `Are you sure you want to reject the withdrawal request from ${technicianName}?`,
      variant: 'danger',
      requireInput: true,
      inputLabel: 'Rejection Reason',
      inputPlaceholder: 'Please provide the reason for rejection...',
      onConfirm: async (inputValue?: string) => {
        try {
          const reason = inputValue || 'Rejected by admin';
          await rejectRequest(requestId, reason);
          setConfirmDialog({ ...confirmDialog, isOpen: false });
          
          // Show success message
          const successDiv = document.createElement('div');
          successDiv.className = 'fixed top-4 right-4 bg-green-600 text-white px-6 py-3 rounded-lg shadow-lg z-50';
          successDiv.textContent = 'Withdrawal rejected successfully';
          document.body.appendChild(successDiv);
          setTimeout(() => successDiv.remove(), 3000);
        } catch (err: any) {
          setConfirmDialog({ ...confirmDialog, isOpen: false });
          
          // Show error message
          const errorDiv = document.createElement('div');
          errorDiv.className = 'fixed top-4 right-4 bg-red-600 text-white px-6 py-3 rounded-lg shadow-lg z-50';
          errorDiv.textContent = err.message || 'Failed to reject withdrawal';
          document.body.appendChild(errorDiv);
          setTimeout(() => errorDiv.remove(), 5000);
        }
      }
    });
  };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    try {
      if (timestamp instanceof Timestamp) {
        return timestamp.toDate().toLocaleString('en-IN', {
          day: '2-digit',
          month: 'short',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
        });
      }
      if (typeof timestamp === 'string') {
        return new Date(timestamp).toLocaleString('en-IN', {
          day: '2-digit',
          month: 'short',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
        });
      }
      return 'N/A';
    } catch {
      return 'N/A';
    }
  };

  const getStatusBadge = (status: string) => {
    const variants = {
      pending: { bg: 'bg-yellow-500/20', text: 'text-yellow-400', icon: Clock },
      approved: { bg: 'bg-green-500/20', text: 'text-green-400', icon: CheckCircle },
      rejected: { bg: 'bg-red-500/20', text: 'text-red-400', icon: XCircle },
      failed: { bg: 'bg-red-500/20', text: 'text-red-400', icon: AlertCircle }
    };
    const variant = variants[status as keyof typeof variants] || variants.pending;
    const Icon = variant.icon;
    
    return (
      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${variant.bg} ${variant.text}`}>
        <Icon size={12} />
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    );
  };

  if (error) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-[#E5E7EB] flex items-center gap-3">
              <Wallet className="text-[#6366F1]" size={28} />
              Withdrawal Requests
            </h1>
            <p className="text-[#9CA3AF] mt-1">Manage technician withdrawal requests</p>
          </div>
        </div>

        <div className="bg-[#111827] border border-[#1F2937] rounded-xl p-12 text-center">
          <AlertCircle className="w-12 h-12 text-red-400 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-[#E5E7EB] mb-2">Failed to Load Requests</h3>
          <p className="text-[#9CA3AF] mb-6">{error.message}</p>
          <button
            onClick={retry}
            className="px-6 py-2 bg-[#6366F1] hover:bg-[#4F46E5] text-white rounded-lg transition-colors inline-flex items-center gap-2"
          >
            <RefreshCw size={16} />
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#E5E7EB] flex items-center gap-3">
            <Wallet className="text-[#6366F1]" size={28} />
            Withdrawal Requests
          </h1>
          <p className="text-[#9CA3AF] mt-1">Manage technician withdrawal requests</p>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-[#111827] rounded-xl p-4 border border-[#1F2937]">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-[#6B7280]" size={16} />
            <input
              type="text"
              placeholder="Search by name, phone, or ID..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-9 pr-4 py-2 bg-[#1F2937] border border-[#374151] text-[#E5E7EB] placeholder-[#6B7280] rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#6366F1] focus:border-transparent"
            />
            {searchTerm && (
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-[#6B7280] hover:text-[#9CA3AF]"
              >
                <X size={14} />
              </button>
            )}
          </div>

          <div className="relative">
            <Filter className="absolute left-3 top-1/2 -translate-y-1/2 text-[#6B7280]" size={16} />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full pl-9 pr-4 py-2 bg-[#1F2937] border border-[#374151] text-[#E5E7EB] rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#6366F1] focus:border-transparent appearance-none"
            >
              <option value="all">All Status</option>
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
              <option value="failed">Failed</option>
            </select>
          </div>

          <div className="flex items-center justify-end">
            <span className="text-sm text-[#6B7280]">
              {filteredRequests.length} request{filteredRequests.length !== 1 ? 's' : ''}
            </span>
          </div>
        </div>
      </div>

      {/* Requests Table */}
      <div className="bg-[#111827] border border-[#1F2937] rounded-xl overflow-hidden">
        {loading ? (
          <TableSkeleton rows={5} columns={7} />
        ) : paginatedRequests.length === 0 ? (
          <div className="p-12 text-center">
            <Wallet className="w-12 h-12 text-[#374151] mx-auto mb-4" />
            <h3 className="text-lg font-semibold text-[#E5E7EB] mb-2">No Requests Found</h3>
            <p className="text-[#9CA3AF]">
              {searchTerm ? 'Try adjusting your search' : 'No withdrawal requests to display'}
            </p>
          </div>
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-[#0F172A] border-b border-[#1F2937]">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">
                      Technician
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">
                      Amount
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">
                      Net Amount
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">
                      Wallet Balance
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">
                      Requested
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#1F2937]">
                  {paginatedRequests.map((request) => (
                    <tr key={request.requestId} className="hover:bg-[#0F172A] transition-colors">
                      <td className="px-6 py-4">
                        <div>
                          <p className="text-sm font-medium text-[#E5E7EB]">{request.technicianName}</p>
                          <p className="text-xs text-[#6B7280] mt-0.5">{request.technicianPhone}</p>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-sm font-semibold text-[#E5E7EB]">₹{request.amount.toLocaleString()}</p>
                        <p className="text-xs text-[#6B7280]">Fee: ₹{request.fee}</p>
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-sm font-semibold text-green-400">₹{request.netAmount.toLocaleString()}</p>
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-sm text-[#9CA3AF]">₹{request.walletBalanceAtRequest.toLocaleString()}</p>
                      </td>
                      <td className="px-6 py-4">
                        {getStatusBadge(request.status)}
                        {request.rejectionReason && (
                          <p className="text-xs text-red-400 mt-1">{request.rejectionReason}</p>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-sm text-[#9CA3AF]">{formatDate(request.createdAt)}</p>
                      </td>
                      <td className="px-6 py-4 text-right">
                        {request.status === 'pending' && (
                          <div className="flex items-center gap-2 justify-end">
                            <button
                              onClick={() => handleApprove(request.requestId, request.technicianName, request.amount)}
                              disabled={approving || rejecting}
                              className="px-3 py-1.5 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                              {approving ? 'Approving...' : 'Approve'}
                            </button>
                            <button
                              onClick={() => handleReject(request.requestId, request.technicianName)}
                              disabled={approving || rejecting}
                              className="px-3 py-1.5 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                              {rejecting ? 'Rejecting...' : 'Reject'}
                            </button>
                          </div>
                        )}
                        {request.status === 'approved' && request.approvedAt && (
                          <p className="text-xs text-[#6B7280]">
                            Approved: {formatDate(request.approvedAt)}
                          </p>
                        )}
                        {request.status === 'rejected' && request.rejectedAt && (
                          <p className="text-xs text-[#6B7280]">
                            Rejected: {formatDate(request.rejectedAt)}
                          </p>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="px-6 py-4 border-t border-[#1F2937] flex items-center justify-between">
                <p className="text-sm text-[#6B7280]">
                  Page {currentPage} of {totalPages}
                </p>
                <div className="flex items-center gap-2">
                  <button
                    onClick={prevPage}
                    disabled={!hasPrev}
                    className="px-4 py-2 bg-[#1F2937] text-[#E5E7EB] rounded-lg hover:bg-[#374151] transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                  >
                    Previous
                  </button>
                  <button
                    onClick={nextPage}
                    disabled={!hasNext}
                    className="px-4 py-2 bg-[#1F2937] text-[#E5E7EB] rounded-lg hover:bg-[#374151] transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                  >
                    Next
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      <ConfirmDialog
        isOpen={confirmDialog.isOpen}
        title={confirmDialog.title}
        message={confirmDialog.message}
        onConfirm={confirmDialog.onConfirm}
        onCancel={() => setConfirmDialog({ ...confirmDialog, isOpen: false })}
        variant={confirmDialog.variant}
        requireInput={confirmDialog.requireInput}
        inputLabel={confirmDialog.inputLabel}
        inputPlaceholder={confirmDialog.inputPlaceholder}
      />
    </div>
  );
}
