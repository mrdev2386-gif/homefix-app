'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { PageHeader, StatusBadge, Column, ConfirmDialog, StatCard } from '@/components/ui';
import { Search, Filter, X, CheckCircle, XCircle, Calendar, Clock, TrendingUp, Package, Eye, Phone, MapPin, IndianRupee } from 'lucide-react';
import { Timestamp } from 'firebase/firestore';
import { subscribeToBookings, AdminBooking, approveBookingAction, rejectBookingAction } from '@/lib/services/adminBookingService';

export default function BookingsPage() {
  const router = useRouter();
  const [bookings, setBookings] = useState<AdminBooking[]>([]);
  const [filteredBookings, setFilteredBookings] = useState<AdminBooking[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [paymentFilter, setPaymentFilter] = useState('all');
  const [selectedBooking, setSelectedBooking] = useState<AdminBooking | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    onConfirm: () => void;
    variant?: 'default' | 'danger';
  }>({ isOpen: false, title: '', message: '', onConfirm: () => {} });

  useEffect(() => {
    const unsubscribe = subscribeToBookings((bookingsData) => {
      console.log('Fetched bookings:', bookingsData.length);
      setBookings(bookingsData);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  useEffect(() => {
    filterBookings();
  }, [bookings, searchTerm, statusFilter, paymentFilter]);

  const filterBookings = () => {
    let filtered = [...bookings];

    if (statusFilter !== 'all') {
      filtered = filtered.filter(b => b.status === statusFilter);
    }

    if (paymentFilter !== 'all') {
      filtered = filtered.filter(b => b.paymentStatus === paymentFilter);
    }

    if (searchTerm) {
      filtered = filtered.filter(b => 
        b.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        b.customerName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        b.technicianName?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredBookings(filtered);
  };

  const stats = {
    total: bookings.length,
    pending: bookings.filter(b => b.status === 'PENDING_ADMIN_APPROVAL').length,
    active: bookings.filter(b => ['ADMIN_APPROVED', 'TECHNICIAN_ACCEPTED', 'IN_PROGRESS'].includes(b.status)).length,
    completed: bookings.filter(b => b.status === 'COMPLETED').length,
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
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error: any) {
          console.error('Error approving booking:', error);
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
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error: any) {
          console.error('Error rejecting booking:', error);
          alert(`Failed: ${error.message}`);
        } finally {
          setProcessing(false);
        }
      },
    });
  };

  const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'info' | 'default' => {
    const map: Record<string, 'success' | 'warning' | 'error' | 'info' | 'default'> = {
      'PENDING_ADMIN_APPROVAL': 'warning',
      'ADMIN_APPROVED': 'info',
      'TECHNICIAN_ACCEPTED': 'info',
      'IN_PROGRESS': 'info',
      'COMPLETED': 'success',
      'CANCELLED': 'error',
    };
    return map[status] || 'default';
  };

  const formatStatus = (status: string) => status.replace(/_/g, ' ');

  const formatDate = (timestamp: any) => {
    if (!timestamp) return '-';
    if (timestamp instanceof Timestamp) return timestamp.toDate().toLocaleDateString();
    if (timestamp.toDate) return timestamp.toDate().toLocaleDateString();
    if (timestamp instanceof Date) return timestamp.toLocaleDateString();
    return '-';
  };

  const getTimeline = (booking: any) => {
    const timeline = [
      { label: 'Booking Created', date: booking.createdAt, completed: true },
      { label: 'Admin Approved', date: booking.adminApprovedAt, completed: ['ADMIN_APPROVED', 'TECHNICIAN_ACCEPTED', 'IN_PROGRESS', 'COMPLETED'].includes(booking.status) },
      { label: 'Technician Accepted', date: booking.technicianAcceptedAt, completed: ['TECHNICIAN_ACCEPTED', 'IN_PROGRESS', 'COMPLETED'].includes(booking.status) },
      { label: 'Service Started', date: booking.serviceStartedAt, completed: ['IN_PROGRESS', 'COMPLETED'].includes(booking.status) },
      { label: 'Service Completed', date: booking.completedAt, completed: booking.status === 'COMPLETED' },
    ];
    return timeline;
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
          <p className="text-sm text-[#E5E7EB]">{item.technicianName || 'Not assigned yet'}</p>
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
      key: 'location', 
      label: 'City / Address',
      render: (item) => <span className="text-sm text-[#9CA3AF]">{item.city || '-'}</span>
    },
    { 
      key: 'bookingDate', 
      label: 'Booking Date',
      render: (item) => (
        <div>
          <p className="text-sm text-[#E5E7EB]">{formatDate(item.bookingDate)}</p>
          <p className="text-xs text-[#6B7280]">{item.timeSlot || ''}</p>
        </div>
      )
    },
    { 
      key: 'servicePrice', 
      label: 'Price',
      render: (item) => <span className="text-sm font-medium text-[#E5E7EB]">₹{item.servicePrice}</span>
    },
    {
      key: 'paymentStatus',
      label: 'Payment',
      render: (item) => (
        <StatusBadge 
          status={item.paymentStatus || 'PENDING'} 
          variant={item.paymentStatus === 'PAID' ? 'success' : item.paymentStatus === 'FAILED' ? 'error' : 'warning'}
        />
      )
    },
    {
      key: 'status',
      label: 'Status',
      render: (item) => <StatusBadge status={formatStatus(item.status)} variant={getStatusVariant(item.status)} />
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
            <Eye size={12} className="inline mr-1" />
            View
          </button>
          {item.status === 'PENDING_ADMIN_APPROVAL' && (
            <>
              <button
                onClick={() => handleApprove(item.id)}
                disabled={processing}
                className="px-3 py-1 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700"
              >
                <CheckCircle size={12} className="inline mr-1" />
                Approve
              </button>
              <button
                onClick={() => handleReject(item.id)}
                disabled={processing}
                className="px-3 py-1 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700"
              >
                <XCircle size={12} className="inline mr-1" />
                Reject
              </button>
            </>
          )}
          {item.status === 'ADMIN_APPROVED' && (
            <span className="text-xs text-[#6B7280] italic">Waiting for technician</span>
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
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
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
            <option value="PENDING_ADMIN_APPROVAL">Pending Approval</option>
            <option value="ADMIN_APPROVED">Admin Approved</option>
            <option value="TECHNICIAN_ACCEPTED">Technician Accepted</option>
            <option value="IN_PROGRESS">In Progress</option>
            <option value="COMPLETED">Completed</option>
            <option value="CANCELLED">Cancelled</option>
          </select>
          <select value={paymentFilter} onChange={(e) => setPaymentFilter(e.target.value)} className="input-field">
            <option value="all">All Payments</option>
            <option value="PENDING">Pending</option>
            <option value="PAID">Paid</option>
            <option value="FAILED">Failed</option>
          </select>
          <div className="flex items-center justify-end">
            <span className="text-sm text-[#9CA3AF]">Showing {filteredBookings.length} of {bookings.length}</span>
          </div>
        </div>
      </div>

      <div className="admin-card p-4 sm:p-6">
        {loading ? (
          <div className="space-y-4">{[1,2,3].map(i => <div key={i} className="h-16 bg-[#1F2937] rounded animate-pulse" />)}</div>
        ) : filteredBookings.length === 0 ? (
          <div className="text-center py-12 text-[#6B7280]">No bookings found</div>
        ) : (
          <div className="overflow-x-auto -mx-4 sm:mx-0">
            <div className="inline-block min-w-full align-middle">
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
                          {col.render ? col.render(item, index) : item[col.key]}
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {showDetailsModal && selectedBooking && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-2 sm:p-4">
          <div className="bg-[#111827] rounded-xl sm:rounded-2xl max-w-4xl w-full max-h-[95vh] sm:max-h-[90vh] overflow-y-auto border border-[#1F2937]">
            <div className="sticky top-0 bg-[#111827] border-b border-[#1F2937] p-4 sm:p-6 flex items-center justify-between z-10">
              <h2 className="text-lg sm:text-xl font-bold text-[#E5E7EB]">Booking Details</h2>
              <button onClick={() => setShowDetailsModal(false)} className="text-[#6B7280] hover:text-[#E5E7EB]"><X size={24} /></button>
            </div>
            <div className="p-4 sm:p-6 space-y-6">
              {/* Customer, Technician, Service Grid */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6">
                {/* Customer */}
                <div className="space-y-3 bg-[#1F2937] p-4 rounded-lg">
                  <h3 className="text-xs sm:text-sm font-bold text-[#E5E7EB] uppercase tracking-wider">Customer</h3>
                  <div className="space-y-2">
                    <p className="text-sm font-medium text-[#E5E7EB]">{selectedBooking.customerName}</p>
                    <div className="flex items-center gap-2 text-[#9CA3AF]"><Phone size={14} /><span className="text-xs sm:text-sm">{selectedBooking.customerPhone}</span></div>
                    {selectedBooking.customerAddress && <div className="flex items-start gap-2 text-[#9CA3AF]"><MapPin size={14} className="mt-1" /><span className="text-xs sm:text-sm">{selectedBooking.customerAddress}</span></div>}
                    {selectedBooking.city && <p className="text-xs text-[#6B7280]">{selectedBooking.city}</p>}
                  </div>
                </div>
                {/* Technician */}
                <div className="space-y-3 bg-[#1F2937] p-4 rounded-lg">
                  <h3 className="text-xs sm:text-sm font-bold text-[#E5E7EB] uppercase tracking-wider">Technician</h3>
                  <div className="space-y-2">
                    <p className="text-sm font-medium text-[#E5E7EB]">{selectedBooking.technicianName || 'Not assigned yet'}</p>
                    {selectedBooking.technicianPhone && <div className="flex items-center gap-2 text-[#9CA3AF]"><Phone size={14} /><span className="text-xs sm:text-sm">{selectedBooking.technicianPhone}</span></div>}
                    {selectedBooking.technicianRating && <p className="text-xs text-[#6B7280]">⭐ {selectedBooking.technicianRating.toFixed(1)}</p>}
                    {selectedBooking.technicianExperience && <p className="text-xs text-[#6B7280]">{selectedBooking.technicianExperience}</p>}
                  </div>
                </div>
                {/* Service */}
                <div className="space-y-3 bg-[#1F2937] p-4 rounded-lg">
                  <h3 className="text-xs sm:text-sm font-bold text-[#E5E7EB] uppercase tracking-wider">Service</h3>
                  <div className="space-y-2">
                    {selectedBooking.serviceImage && <img src={selectedBooking.serviceImage} alt={selectedBooking.serviceName} className="w-full h-24 object-cover rounded" />}
                    <p className="text-sm font-medium text-[#E5E7EB]">{selectedBooking.serviceName}</p>
                    <p className="text-xs text-[#6B7280]">{selectedBooking.categoryName}</p>
                    <div className="flex items-center gap-2 text-[#10B981]"><IndianRupee size={14} /><span className="text-sm font-bold">₹{selectedBooking.servicePrice}</span></div>
                  </div>
                </div>
              </div>

              {/* Booking & Payment Grid */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-6">
                {/* Booking */}
                <div className="space-y-3 bg-[#1F2937] p-4 rounded-lg">
                  <h3 className="text-xs sm:text-sm font-bold text-[#E5E7EB] uppercase tracking-wider">Booking</h3>
                  <div className="space-y-2">
                    <div className="flex items-center gap-2"><Calendar size={14} className="text-[#6B7280]" /><span className="text-xs sm:text-sm text-[#E5E7EB]">{formatDate(selectedBooking.bookingDate)}</span></div>
                    <div className="flex items-center gap-2"><Clock size={14} className="text-[#6B7280]" /><span className="text-xs sm:text-sm text-[#E5E7EB]">{selectedBooking.timeSlot}</span></div>
                    <StatusBadge status={formatStatus(selectedBooking.status)} variant={getStatusVariant(selectedBooking.status)} />
                  </div>
                </div>
                {/* Payment */}
                <div className="space-y-3 bg-[#1F2937] p-4 rounded-lg">
                  <h3 className="text-xs sm:text-sm font-bold text-[#E5E7EB] uppercase tracking-wider">Payment</h3>
                  <div className="space-y-2">
                    <p className="text-xs sm:text-sm text-[#9CA3AF]">Method: {selectedBooking.paymentMethod || 'Not specified'}</p>
                    <StatusBadge status={selectedBooking.paymentStatus || 'PENDING'} variant={selectedBooking.paymentStatus === 'PAID' ? 'success' : 'warning'} />
                    {selectedBooking.transactionId && <p className="text-xs text-[#6B7280] font-mono break-all">TXN: {selectedBooking.transactionId}</p>}
                  </div>
                </div>
              </div>

              {/* Booking Timeline */}
              <div className="space-y-3 bg-[#1F2937] p-4 rounded-lg">
                <h3 className="text-xs sm:text-sm font-bold text-[#E5E7EB] uppercase tracking-wider">Booking Timeline</h3>
                <div className="space-y-3">
                  {getTimeline(selectedBooking).map((step, idx) => (
                    <div key={idx} className="flex items-center gap-3 sm:gap-4">
                      <div className={`w-6 h-6 sm:w-8 sm:h-8 rounded-full flex items-center justify-center flex-shrink-0 ${step.completed ? 'bg-green-600' : 'bg-[#374151]'}`}>
                        {step.completed ? <CheckCircle size={14} className="text-white" /> : <div className="w-2 h-2 rounded-full bg-[#6B7280]" />}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className={`text-xs sm:text-sm ${step.completed ? 'text-[#E5E7EB] font-medium' : 'text-[#6B7280]'}`}>{step.label}</p>
                        {step.date && <p className="text-xs text-[#6B7280]">{formatDate(step.date)}</p>}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Action Buttons */}
              {selectedBooking.status === 'PENDING_ADMIN_APPROVAL' && (
                <div className="flex flex-col sm:flex-row gap-3 pt-4 border-t border-[#1F2937]">
                  <button onClick={() => { setShowDetailsModal(false); handleApprove(selectedBooking.id); }} className="flex-1 px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium text-sm sm:text-base">
                    <CheckCircle size={16} className="inline mr-2" />Approve Booking
                  </button>
                  <button onClick={() => { setShowDetailsModal(false); handleReject(selectedBooking.id); }} className="flex-1 px-4 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium text-sm sm:text-base">
                    <XCircle size={16} className="inline mr-2" />Reject Booking
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        isOpen={confirmDialog.isOpen}
        title={confirmDialog.title}
        message={confirmDialog.message}
        onConfirm={confirmDialog.onConfirm}
        onCancel={() => setConfirmDialog({ ...confirmDialog, isOpen: false })}
        variant={confirmDialog.variant}
      />
    </div>
  );
}
