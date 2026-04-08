'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { PageHeader, StatusBadge, Column, ConfirmDialog, StatCard } from '@/components/ui';
import { Search, X, CheckCircle, XCircle, Clock, TrendingUp, Package, Eye, UserCog, Star } from 'lucide-react';
import { Timestamp } from 'firebase/firestore';
import { subscribeToBookings, AdminBooking, approveBookingAction, rejectBookingAction, approveBookingWithTechnician, fetchAllTechnicians, TechnicianOption } from '@/lib/services/adminBookingService';
import { normalizeBookingStatus, canApproveBooking } from '@/lib/bookingStatus';

export default function BookingsPage() {
  const router = useRouter();
  const [bookings, setBookings] = useState<AdminBooking[]>([]);
  const [filteredBookings, setFilteredBookings] = useState<AdminBooking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedBooking, setSelectedBooking] = useState<AdminBooking | null>(null);
  const [processing, setProcessing] = useState(false);
  const [showChangeTechModal, setShowChangeTechModal] = useState(false);
  const [technicians, setTechnicians] = useState<TechnicianOption[]>([]);
  const [selectedTechId, setSelectedTechId] = useState<string>('');
  const [techLoading, setTechLoading] = useState(false);
  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    onConfirm: () => void;
    variant?: 'default' | 'danger';
  }>({ isOpen: false, title: '', message: '', onConfirm: () => {} });

  useEffect(() => {
    console.log('[BookingsPage] Mounting, starting subscription...');
    let unsubscribe: (() => void) | undefined;

    try {
      unsubscribe = subscribeToBookings((bookingsData) => {
        console.log('[BookingsPage] Received bookings:', bookingsData.length);
        setBookings(bookingsData);
        setLoading(false);
        setError(null);
      });
    } catch (err: any) {
      console.error('[BookingsPage] Failed to start subscription:', err);
      setError('Failed to load bookings. Please refresh.');
      setLoading(false);
    }

    return () => unsubscribe?.();
  }, []);

  useEffect(() => {
    let filtered = [...bookings];
    if (statusFilter !== 'all') {
      filtered = filtered.filter(b => normalizeBookingStatus(b.status) === statusFilter);
    }
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(b =>
        b.id.toLowerCase().includes(term) ||
        b.customerName?.toLowerCase().includes(term) ||
        b.technicianName?.toLowerCase().includes(term) ||
        b.serviceName?.toLowerCase().includes(term)
      );
    }
    setFilteredBookings(filtered);
  }, [bookings, searchTerm, statusFilter]);

  const stats = {
    total: bookings.length,
    pending: bookings.filter(b => canApproveBooking(b.status)).length,
    active: bookings.filter(b => ['approved_by_admin', 'technician_accepted', 'service_in_progress'].includes(normalizeBookingStatus(b.status))).length,
    completed: bookings.filter(b => normalizeBookingStatus(b.status) === 'service_completed').length,
  };

  const openChangeTechModal = async (booking: AdminBooking) => {
    setSelectedBooking(booking);
    setSelectedTechId(booking.technicianId || '');
    setShowChangeTechModal(true);
    setTechLoading(true);
    try {
      const techs = await fetchAllTechnicians();
      setTechnicians(techs);
    } catch (e) {
      console.error('Failed to load technicians', e);
    } finally {
      setTechLoading(false);
    }
  };

  const handleChangeTechAndApprove = () => {
    if (!selectedBooking || !selectedTechId) return;
    setConfirmDialog({
      isOpen: true,
      title: 'Approve with Technician',
      message: 'Approve booking and assign selected technician?',
      onConfirm: async () => {
        setProcessing(true);
        try {
          await approveBookingWithTechnician(selectedBooking.id, selectedTechId);
          setShowChangeTechModal(false);
          setConfirmDialog(prev => ({ ...prev, isOpen: false }));
        } catch (error: any) {
          alert(`Failed: ${error.message}`);
        } finally {
          setProcessing(false);
        }
      },
    });
  };

  const handleApprove = (bookingId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Approve Booking',
      message: 'This will notify the technician. Are you sure?',
      onConfirm: async () => {
        setProcessing(true);
        try {
          await approveBookingAction(bookingId);
          setConfirmDialog(prev => ({ ...prev, isOpen: false }));
        } catch (error: any) {
          alert(`Failed: ${error.message}`);
        } finally {
          setProcessing(false);
        }
      },
    });
  };

  const handleReject = (bookingId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Reject Booking',
      message: 'This will cancel the booking and notify the customer. Are you sure?',
      variant: 'danger',
      onConfirm: async () => {
        setProcessing(true);
        try {
          await rejectBookingAction(bookingId, 'Rejected by admin');
          setConfirmDialog(prev => ({ ...prev, isOpen: false }));
        } catch (error: any) {
          alert(`Failed: ${error.message}`);
        } finally {
          setProcessing(false);
        }
      },
    });
  };

  const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'info' | 'default' => {
    const n = normalizeBookingStatus(status);
    const map: Record<string, 'success' | 'warning' | 'error' | 'info' | 'default'> = {
      'pending_admin_approval': 'warning',
      'approved_by_admin': 'info',
      'technician_accepted': 'info',
      'service_in_progress': 'info',
      'service_completed': 'success',
      'rejected': 'error',
    };
    return map[n] || 'default';
  };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return '-';
    if (timestamp instanceof Timestamp) return timestamp.toDate().toLocaleDateString();
    if (timestamp?.toDate) return timestamp.toDate().toLocaleDateString();
    return '-';
  };

  const columns: Column[] = [
    {
      key: 'id',
      label: 'Booking ID',
      render: (item) => <span className="text-sm font-mono text-[#6366F1]">{item.id.substring(0, 8)}</span>
    },
    {
      key: 'customerName',
      label: 'Customer',
      render: (item) => (
        <div>
          <p className="text-sm text-[#E5E7EB]">{item.customerName}</p>
          <p className="text-xs text-[#6B7280]">{item.customerPhone}</p>
        </div>
      )
    },
    {
      key: 'technicianName',
      label: 'Technician',
      render: (item) => (
        <div>
          <p className="text-sm text-[#E5E7EB]">{item.technicianName || 'Not assigned'}</p>
          <p className="text-xs text-[#6B7280]">{item.technicianPhone || ''}</p>
        </div>
      )
    },
    {
      key: 'serviceName',
      label: 'Service',
      render: (item) => (
        <div>
          <p className="text-sm text-[#E5E7EB]">{item.serviceName}</p>
          <p className="text-xs text-[#6B7280]">{item.categoryName}</p>
        </div>
      )
    },
    {
      key: 'servicePrice',
      label: 'Price',
      render: (item) => <span className="text-sm font-medium text-[#E5E7EB]">₹{item.servicePrice}</span>
    },
    {
      key: 'bookingDate',
      label: 'Date',
      render: (item) => <span className="text-sm text-[#E5E7EB]">{formatDate(item.bookingDate)}</span>
    },
    {
      key: 'status',
      label: 'Status',
      render: (item) => <StatusBadge status={normalizeBookingStatus(item.status).replace(/_/g, ' ')} variant={getStatusVariant(item.status)} />
    },
    {
      key: 'actions',
      label: 'Actions',
      align: 'right',
      render: (item) => (
        <div className="flex items-center gap-2 justify-end">
          <button
            onClick={() => router.push(`/bookings/${item.id}`)}
            className="px-3 py-1 text-xs bg-[#1F2937] text-[#E5E7EB] rounded-lg hover:bg-[#374151]"
          >
            <Eye size={12} className="inline mr-1" />View
          </button>
          {canApproveBooking(item.status) && (
            <>
              <button
                onClick={() => openChangeTechModal(item)}
                disabled={processing}
                className="px-3 py-1 text-xs bg-[#6366F1] text-white rounded-lg hover:bg-[#4F46E5]"
              >
                <UserCog size={12} className="inline mr-1" />Change Tech
              </button>
              <button
                onClick={() => handleApprove(item.id)}
                disabled={processing}
                className="px-3 py-1 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700"
              >
                <CheckCircle size={12} className="inline mr-1" />Approve
              </button>
              <button
                onClick={() => handleReject(item.id)}
                disabled={processing}
                className="px-3 py-1 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700"
              >
                <XCircle size={12} className="inline mr-1" />Reject
              </button>
            </>
          )}
        </div>
      )
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader title="Bookings Management" description="Moderate and manage all service bookings" />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
        <StatCard title="Total Bookings" value={stats.total} icon={Package} color="purple" />
        <StatCard title="Pending Approval" value={stats.pending} icon={Clock} color="orange" />
        <StatCard title="Active Bookings" value={stats.active} icon={TrendingUp} color="blue" />
        <StatCard title="Completed" value={stats.completed} icon={CheckCircle} color="green" />
      </div>

      <div className="admin-card p-3 sm:p-4">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-[#6B7280]" size={18} />
            <input
              type="text"
              placeholder="Search..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input-field w-full pl-10 pr-4"
            />
            {searchTerm && <button onClick={() => setSearchTerm('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-[#6B7280]"><X size={18} /></button>}
          </div>
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="input-field">
            <option value="all">All Status</option>
            <option value="pending_admin_approval">Pending Approval</option>
            <option value="approved_by_admin">Admin Approved</option>
            <option value="technician_accepted">Technician Accepted</option>
            <option value="service_in_progress">In Progress</option>
            <option value="service_completed">Completed</option>
            <option value="rejected">Rejected / Cancelled</option>
          </select>
          <div className="flex items-center justify-end">
            <span className="text-sm text-[#9CA3AF]">Showing {filteredBookings.length} of {bookings.length}</span>
          </div>
        </div>
      </div>

      <div className="admin-card p-4 sm:p-6">
        {loading ? (
          <div className="space-y-4">{[1,2,3].map(i => <div key={i} className="h-16 bg-[#1F2937] rounded animate-pulse" />)}</div>
        ) : error ? (
          <div className="text-center py-12">
            <p className="text-red-400 text-sm mb-3">{error}</p>
            <button
              onClick={() => { setError(null); setLoading(true); }}
              className="px-4 py-2 text-xs bg-[#6366F1] text-white rounded-lg hover:bg-[#4F46E5]"
            >
              Retry
            </button>
          </div>
        ) : filteredBookings.length === 0 ? (
          <div className="text-center py-12 text-[#6B7280]">No bookings found</div>
        ) : (
          <div className="overflow-x-auto -mx-4 sm:mx-0">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#1F2937]">
                  {columns.map(col => (
                    <th key={col.key} className={`text-left text-xs font-semibold text-[#9CA3AF] uppercase tracking-wider py-3 px-3 sm:px-4 ${col.align === 'right' ? 'text-right' : ''}`}>
                      {col.label}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filteredBookings.map((item, index) => (
                  <tr key={item.id} className="border-b border-[#1F2937] hover:bg-[#1F2937]/50">
                    {columns.map(col => (
                      <td key={col.key} className={`py-3 sm:py-4 px-3 sm:px-4 ${col.align === 'right' ? 'text-right' : ''}`}>
                        {col.render ? col.render(item, index) : (item as any)[col.key]}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Change Technician Modal */}
      {showChangeTechModal && selectedBooking && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-[#111827] rounded-2xl max-w-lg w-full max-h-[80vh] flex flex-col border border-[#1F2937]">
            <div className="sticky top-0 bg-[#111827] border-b border-[#1F2937] p-5 flex items-center justify-between">
              <div>
                <h2 className="text-lg font-bold text-[#E5E7EB]">Change Technician</h2>
                <p className="text-xs text-[#6B7280] mt-0.5">Booking: {selectedBooking.id.substring(0, 10)}</p>
              </div>
              <button onClick={() => setShowChangeTechModal(false)} className="text-[#6B7280] hover:text-[#E5E7EB]"><X size={20} /></button>
            </div>

            <div className="p-5 overflow-y-auto flex-1">
              <div className="bg-[#1F2937] rounded-lg p-4 mb-4 space-y-1">
                <p className="text-xs text-[#6B7280]">Customer</p>
                <p className="text-sm font-medium text-[#E5E7EB]">{selectedBooking.customerName} · {selectedBooking.customerPhone}</p>
                <p className="text-xs text-[#6B7280] mt-2">Service</p>
                <p className="text-sm font-medium text-[#E5E7EB]">{selectedBooking.serviceName} · ₹{selectedBooking.servicePrice}</p>
                <p className="text-xs text-[#6B7280] mt-2">Current Technician</p>
                <p className="text-sm font-medium text-[#E5E7EB]">{selectedBooking.technicianName || 'None'} · {selectedBooking.technicianPhone || '-'}</p>
              </div>

              <p className="text-sm font-semibold text-[#E5E7EB] mb-3">Select Technician</p>

              {techLoading ? (
                <div className="space-y-2">{[1,2,3].map(i => <div key={i} className="h-14 bg-[#1F2937] rounded animate-pulse" />)}</div>
              ) : (
                <div className="space-y-2">
                  {technicians.map(tech => (
                    <button
                      key={tech.id}
                      onClick={() => setSelectedTechId(tech.id)}
                      className={`w-full text-left p-3 rounded-lg border transition-colors ${
                        selectedTechId === tech.id
                          ? 'border-[#6366F1] bg-[#6366F1]/10'
                          : 'border-[#374151] bg-[#1F2937] hover:border-[#6366F1]/50'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-sm font-medium text-[#E5E7EB]">{tech.name}</p>
                          <p className="text-xs text-[#6B7280]">{tech.phone}</p>
                        </div>
                        <div className="text-right">
                          <p className="text-xs text-[#9CA3AF] flex items-center gap-1 justify-end">
                            <Star size={10} className="fill-yellow-400 text-yellow-400" />{tech.rating.toFixed(1)}
                          </p>
                          <p className="text-xs text-[#6B7280]">{tech.completedJobs} jobs</p>
                        </div>
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>

            <div className="border-t border-[#1F2937] p-5 flex gap-3">
              <button
                onClick={() => setShowChangeTechModal(false)}
                className="flex-1 px-4 py-2.5 bg-[#1F2937] text-[#E5E7EB] rounded-lg hover:bg-[#374151] text-sm"
              >
                Cancel
              </button>
              <button
                onClick={handleChangeTechAndApprove}
                disabled={!selectedTechId || processing}
                className="flex-1 px-4 py-2.5 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 text-sm font-medium"
              >
                <CheckCircle size={14} className="inline mr-1" />Approve with this Tech
              </button>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        isOpen={confirmDialog.isOpen}
        title={confirmDialog.title}
        message={confirmDialog.message}
        onConfirm={confirmDialog.onConfirm}
        onCancel={() => setConfirmDialog(prev => ({ ...prev, isOpen: false }))}
        variant={confirmDialog.variant}
      />
    </div>
  );
}
