'use client';

import { useState, useEffect } from 'react';
import { PageHeader, DataTable, StatusBadge, Column, ConfirmDialog } from '@/components/ui';
import { Search, Filter, X, Star, User, Wallet, Calendar } from 'lucide-react';
import { db } from '@/lib/firebase';
import { collection, query, where, orderBy, limit as firestoreLimit, getDocs, Timestamp } from 'firebase/firestore';
import { adminApi } from '@/lib/admin-api';

export default function TechniciansPage() {
  const [technicians, setTechnicians] = useState<any[]>([]);
  const [filteredTechnicians, setFilteredTechnicians] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedTechnician, setSelectedTechnician] = useState<any>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [recentBookings, setRecentBookings] = useState<any[]>([]);
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

  useEffect(() => {
    fetchTechnicians();
  }, []);

  useEffect(() => {
    filterTechnicians();
  }, [technicians, searchTerm, statusFilter]);

  const fetchTechnicians = async () => {
    try {
      setLoading(true);
      const techQuery = query(
        collection(db, 'technicians'),
        where('status', '==', 'approved'),
        orderBy('createdAt', 'desc'),
        firestoreLimit(100)
      );
      const snapshot = await getDocs(techQuery);
      const techsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));
      setTechnicians(techsData);
    } catch (error) {
      console.error('Error fetching technicians:', error);
    } finally {
      setLoading(false);
    }
  };

  const filterTechnicians = () => {
    let filtered = [...technicians];
    if (statusFilter !== 'all') {
      if (statusFilter === 'active') {
        filtered = filtered.filter(t => t.isOnline === true && !t.suspended);
      } else if (statusFilter === 'offline') {
        filtered = filtered.filter(t => t.isOnline === false && !t.suspended);
      } else if (statusFilter === 'suspended') {
        filtered = filtered.filter(t => t.suspended === true);
      }
    }
    if (searchTerm) {
      filtered = filtered.filter(t =>
        t.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.phone?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }
    setFilteredTechnicians(filtered);
  };

  const handleViewDetails = async (technician: any) => {
    setSelectedTechnician(technician);
    try {
      const bookingsQuery = query(
        collection(db, 'bookings'),
        where('technicianId', '==', technician.id),
        orderBy('createdAt', 'desc'),
        firestoreLimit(5)
      );
      const bookingsSnapshot = await getDocs(bookingsQuery);
      const bookingsData = bookingsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setRecentBookings(bookingsData);
    } catch (error) {
      console.error('Error fetching bookings:', error);
      setRecentBookings([]);
    }
    setShowDetailsModal(true);
  };

  const handleSuspend = (techId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Suspend Technician',
      message: 'Are you sure you want to suspend this technician? They will not be able to receive new bookings.',
      variant: 'danger',
      requireInput: true,
      inputLabel: 'Suspension Reason',
      inputPlaceholder: 'Please provide the reason for suspension...',
      onConfirm: async (inputValue?: string) => {
        try {
          const reason = inputValue || 'Suspended by admin';
          await adminApi.suspendTechnician(techId, reason);
          await fetchTechnicians();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error suspending technician:', error);
        }
      },
    });
  };

  const handleActivate = (techId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Activate Technician',
      message: 'Are you sure you want to reactivate this technician? They will be able to receive bookings again.',
      onConfirm: async () => {
        try {
          await adminApi.reactivateTechnician(techId);
          await fetchTechnicians();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error activating technician:', error);
        }
      },
    });
  };

  const getTechnicianStatus = (tech: any): { status: string; variant: 'success' | 'warning' | 'error' | 'info' | 'default' } => {
    if (tech.suspended) return { status: 'Suspended', variant: 'error' };
    if (tech.isOnline) return { status: 'Active', variant: 'success' };
    return { status: 'Offline', variant: 'default' };
  };

  const columns: Column[] = [
    {
      key: 'name',
      label: 'Technician Name',
      sortable: true,
      render: (item) => (
        <div className="flex items-center gap-2.5">
          {item.profileImageUrl ? (
            <img src={item.profileImageUrl} alt="" className="w-8 h-8 rounded-full object-cover" />
          ) : (
            <div className="w-8 h-8 rounded-full bg-[#6366F1]/20 flex items-center justify-center flex-shrink-0">
              <User size={14} className="text-[#6366F1]" />
            </div>
          )}
          <span className="text-sm font-medium text-[#E5E7EB]">{item.name || 'N/A'}</span>
        </div>
      )
    },
    {
      key: 'phone',
      label: 'Phone Number',
      render: (item) => (
        <span className="text-sm text-[#E5E7EB]">{item.phone || 'N/A'}</span>
      )
    },
    {
      key: 'skills',
      label: 'Service Categories',
      render: (item) => (
        <span className="text-sm text-[#9CA3AF]">
          {Array.isArray(item.skills) ? item.skills.slice(0, 2).join(', ') : item.skills || 'N/A'}
          {Array.isArray(item.skills) && item.skills.length > 2 && ` +${item.skills.length - 2}`}
        </span>
      )
    },
    {
      key: 'city',
      label: 'City',
      render: (item) => (
        <span className="text-sm text-[#9CA3AF]">{item.city || item.district || 'N/A'}</span>
      )
    },
    {
      key: 'rating',
      label: 'Rating',
      render: (item) => (
        <div className="flex items-center gap-1">
          <Star size={13} className="text-yellow-500 fill-yellow-500" />
          <span className="text-sm font-medium text-[#E5E7EB]">{item.rating?.toFixed(1) || '0.0'}</span>
        </div>
      )
    },
    {
      key: 'completedJobs',
      label: 'Completed Jobs',
      render: (item) => (
        <span className="text-sm text-[#E5E7EB]">{item.completedJobs || 0}</span>
      )
    },
    {
      key: 'walletBalance',
      label: 'Wallet Balance',
      render: (item) => (
        <span className="text-sm font-medium text-[#E5E7EB]">₹{item.walletBalance || 0}</span>
      )
    },
    {
      key: 'status',
      label: 'Status',
      render: (item) => {
        const { status, variant } = getTechnicianStatus(item);
        return <StatusBadge status={status} variant={variant} />;
      }
    },
    {
      key: 'actions',
      label: 'Actions',
      align: 'right',
      render: (item) => (
        <div className="flex items-center gap-2 justify-end">
          <button
            onClick={() => handleViewDetails(item)}
            className="px-3 py-1 text-xs bg-[#1F2937] text-[#9CA3AF] rounded-lg hover:bg-[#374151] hover:text-[#E5E7EB] transition-colors"
          >
            View
          </button>
          {item.suspended ? (
            <button
              onClick={() => handleActivate(item.id)}
              className="px-3 py-1 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
            >
              Activate
            </button>
          ) : (
            <button
              onClick={() => handleSuspend(item.id)}
              className="px-3 py-1 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
            >
              Suspend
            </button>
          )}
        </div>
      )
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Technicians"
        description="Manage and monitor all technicians on the platform"
      />

      {/* Filters */}
      <div className="bg-[#111827] rounded-xl p-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-[#6B7280]" size={16} />
            <input
              type="text"
              placeholder="Search by name or phone..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-9 pr-4 py-2 bg-[#1F2937] border border-[#374151] text-[#E5E7EB] placeholder-[#6B7280] rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#6366F1] focus:border-transparent"
            />
            {searchTerm && (
              <button onClick={() => setSearchTerm('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-[#6B7280] hover:text-[#9CA3AF]">
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
              <option value="active">Active</option>
              <option value="offline">Offline</option>
              <option value="suspended">Suspended</option>
            </select>
          </div>

          <div className="flex items-center justify-end">
            <span className="text-sm text-[#6B7280]">
              {filteredTechnicians.length} of {technicians.length} technicians
            </span>
          </div>
        </div>
      </div>

      {/* Technicians Table */}
      <div className="admin-card p-6">
        <DataTable columns={columns} data={filteredTechnicians} loading={loading} emptyMessage="No technicians found" />
      </div>

      {/* Technician Details Modal */}
      {showDetailsModal && selectedTechnician && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="bg-[#111827] border border-[#1F2937] rounded-xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-[#111827] border-b border-[#1F2937] px-6 py-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-[#E5E7EB]">Technician Details</h2>
              <button onClick={() => setShowDetailsModal(false)} className="p-1.5 text-[#6B7280] hover:text-[#E5E7EB] hover:bg-[#1F2937] rounded-lg transition-colors">
                <X size={18} />
              </button>
            </div>
            <div className="p-6 space-y-6">
              {/* Profile Section */}
              <div className="flex items-start gap-5">
                {selectedTechnician.profileImageUrl ? (
                  <img src={selectedTechnician.profileImageUrl} alt="" className="w-20 h-20 rounded-full object-cover flex-shrink-0" />
                ) : (
                  <div className="w-20 h-20 rounded-full bg-[#6366F1]/20 flex items-center justify-center flex-shrink-0">
                    <User size={36} className="text-[#6366F1]" />
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <h3 className="text-xl font-bold text-[#E5E7EB]">{selectedTechnician.name}</h3>
                  <p className="text-sm text-[#9CA3AF] mt-0.5">{selectedTechnician.phone}</p>
                  <p className="text-sm text-[#9CA3AF]">{selectedTechnician.email || 'N/A'}</p>
                  <div className="mt-2">
                    {(() => {
                      const { status, variant } = getTechnicianStatus(selectedTechnician);
                      return <StatusBadge status={status} variant={variant} />;
                    })()}
                  </div>
                </div>
              </div>

              {/* Service Info */}
              <div>
                <p className="text-xs font-semibold text-[#6B7280] uppercase tracking-wider mb-3">Service Information</p>
                <div className="grid grid-cols-2 gap-3">
                  {[
                    { label: 'Service Categories', value: Array.isArray(selectedTechnician.skills) ? selectedTechnician.skills.join(', ') : selectedTechnician.skills },
                    { label: 'Experience', value: selectedTechnician.experience },
                    { label: 'City', value: selectedTechnician.city },
                    { label: 'District', value: selectedTechnician.district },
                  ].map(({ label, value }) => (
                    <div key={label} className="bg-[#0F172A] rounded-lg p-3">
                      <p className="text-xs text-[#6B7280] mb-1">{label}</p>
                      <p className="text-sm font-medium text-[#E5E7EB]">{value || 'N/A'}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Performance Metrics */}
              <div>
                <p className="text-xs font-semibold text-[#6B7280] uppercase tracking-wider mb-3">Performance Metrics</p>
                <div className="grid grid-cols-3 gap-3">
                  <div className="bg-[#0F172A] rounded-lg p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <Star size={16} className="text-yellow-500" />
                      <p className="text-xs text-[#6B7280]">Avg Rating</p>
                    </div>
                    <p className="text-2xl font-bold text-[#E5E7EB]">{selectedTechnician.rating?.toFixed(1) || '0.0'}</p>
                  </div>
                  <div className="bg-[#0F172A] rounded-lg p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <Calendar size={16} className="text-[#6366F1]" />
                      <p className="text-xs text-[#6B7280]">Completed Jobs</p>
                    </div>
                    <p className="text-2xl font-bold text-[#E5E7EB]">{selectedTechnician.completedJobs || 0}</p>
                  </div>
                  <div className="bg-[#0F172A] rounded-lg p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <Wallet size={16} className="text-green-500" />
                      <p className="text-xs text-[#6B7280]">Wallet Balance</p>
                    </div>
                    <p className="text-2xl font-bold text-[#E5E7EB]">₹{selectedTechnician.walletBalance || 0}</p>
                  </div>
                </div>
              </div>

              {/* Recent Bookings */}
              <div>
                <p className="text-xs font-semibold text-[#6B7280] uppercase tracking-wider mb-3">Recent Bookings</p>
                {recentBookings.length > 0 ? (
                  <div className="space-y-2">
                    {recentBookings.map((booking) => (
                      <div key={booking.id} className="bg-[#0F172A] rounded-lg px-4 py-3 flex items-center justify-between">
                        <div>
                          <p className="text-sm font-medium text-[#E5E7EB]">{booking.serviceType || 'N/A'}</p>
                          <p className="text-xs text-[#6B7280]">{booking.customerName || 'N/A'}</p>
                        </div>
                        <StatusBadge status={booking.status} variant="info" />
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-[#6B7280] text-center py-6 bg-[#0F172A] rounded-lg">No recent bookings</p>
                )}
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-3 pt-2">
                {selectedTechnician.suspended ? (
                  <button
                    onClick={() => { setShowDetailsModal(false); handleActivate(selectedTechnician.id); }}
                    className="flex-1 px-4 py-2.5 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors text-sm font-medium"
                  >
                    Activate Technician
                  </button>
                ) : (
                  <button
                    onClick={() => { setShowDetailsModal(false); handleSuspend(selectedTechnician.id); }}
                    className="flex-1 px-4 py-2.5 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors text-sm font-medium"
                  >
                    Suspend Technician
                  </button>
                )}
              </div>
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
        requireInput={confirmDialog.requireInput}
        inputLabel="Suspension Reason"
        inputPlaceholder="Enter reason for suspension..."
      />
    </div>
  );
}
