'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { PageHeader, StatusBadge, Column, ConfirmDialog, StatCard } from '@/components/ui';
import { Search, Filter, X, CheckCircle, XCircle, Calendar, Clock, TrendingUp, Package, Eye, Phone, MapPin, IndianRupee } from 'lucide-react';
import { Timestamp, collection, query, orderBy, limit, getDocs, where, startAfter, DocumentSnapshot } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { subscribeToBookings, AdminBooking, approveBookingAction, rejectBookingAction } from '@/lib/services/adminBookingService';

const PAGE_SIZE = 20;

export default function BookingsPage() {
  const router = useRouter();
  const [bookings, setBookings] = useState<AdminBooking[]>([]);
  const [filteredBookings, setFilteredBookings] = useState<AdminBooking[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [paymentFilter, setPaymentFilter] = useState('all');
  const [selectedBooking, setSelectedBooking] = useState<AdminBooking | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [lastVisible, setLastVisible] = useState<DocumentSnapshot | null>(null);
  const [hasMore, setHasMore] = useState(true);
  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    onConfirm: () => void;
    variant?: 'default' | 'danger';
  }>({ isOpen: false, title: '', message: '', onConfirm: () => {} });

  // OPTIMIZATION: Load initial data asynchronously without blocking render
  useEffect(() => {
    setLoading(true);
    const timer = setTimeout(() => {
      fetchInitialBookings();
    }, 0);
    return () => clearTimeout(timer);
  }, []);

  const fetchInitialBookings = async () => {
    try {
      const q = query(
        collection(db, 'bookings'),
        orderBy('createdAt', 'desc'),
        limit(PAGE_SIZE + 1)
      );
      const snapshot = await getDocs(q);
      const docs = snapshot.docs.slice(0, PAGE_SIZE);
      
      const bookingsData = docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as AdminBooking[];

      setBookings(bookingsData);
      setLastVisible(docs.length > 0 ? docs[docs.length - 1] : null);
      setHasMore(snapshot.docs.length > PAGE_SIZE);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching bookings:', error);
      setLoading(false);
    }
  };

  const loadMoreBookings = async () => {
    if (!lastVisible || !hasMore || loadingMore) return;
    
    try {
      setLoadingMore(true);
      const q = query(
        collection(db, 'bookings'),
        orderBy('createdAt', 'desc'),
        startAfter(lastVisible),
        limit(PAGE_SIZE + 1)
      );
      const snapshot = await getDocs(q);
      const docs = snapshot.docs.slice(0, PAGE_SIZE);
      
      const newBookings = docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as AdminBooking[];

      setBookings(prev => [...prev, ...newBookings]);
      setLastVisible(docs.length > 0 ? docs[docs.length - 1] : null);
      setHasMore(snapshot.docs.length > PAGE_SIZE);
    } catch (error) {
      console.error('Error loading more bookings:', error);
    } finally {
      setLoadingMore(false);
    }
  };

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
          await fetchInitialBookings();
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
          await fetchInitialBookings();
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
        </div>
      )
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader title="Bookings Management" description="Moderate and manage all service bookings" />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
        <StatCard title="Total Bookings" value={stats.total} icon={Package} color="purple" loading={loading} />
        <StatCard title="Pending Approval" value={stats.pending} icon={Clock} color="orange" loading={loading} />
        <StatCard title="Active Bookings" value={stats.active} icon={TrendingUp} color="blue" loading={loading} />
        <StatCard title="Completed" value={stats.completed} icon={CheckCircle} color="green" loading={loading} />
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
            <option value="COMPLETED">Completed</option>
          </select>
          <select value={paymentFilter} onChange={(e) => setPaymentFilter(e.target.value)} className="input-field">
            <option value="all">All Payments</option>
            <option value="PENDING">Pending</option>
            <option value="PAID">Paid</option>
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

        {/* Load More Button */}
        {hasMore && bookings.length > 0 && (
          <div className="flex justify-center mt-6">
            <button
              onClick={loadMoreBookings}
              disabled={loadingMore}
              className="px-6 py-3 bg-[#1F2937] text-[#E5E7EB] rounded-lg hover:bg-[#374151] transition-colors disabled:opacity-50"
            >
              {loadingMore ? 'Loading...' : 'Load More Bookings'}
            </button>
          </div>
        )}
      </div>

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
