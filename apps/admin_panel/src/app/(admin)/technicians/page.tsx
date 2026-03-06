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
    onConfirm: () => void;
    variant?: 'default' | 'danger';
    requireInput?: boolean;
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
    
    // Fetch recent bookings for this technician
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
      onConfirm: async () => {
        try {
          await adminApi.suspendTechnician(techId, 'Suspended by admin');
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
    if (tech.suspended) {
      return { status: 'Suspended', variant: 'error' };
    }
    if (tech.isOnline) {
      return { status: 'Active', variant: 'success' };
    }
    return { status: 'Offline', variant: 'default' };
  };

  const columns: Column[] = [
    { 
      key: 'name', 
      label: 'Technician Name',
      sortable: true,
      render: (item) => (
        <div className="flex items-center gap-2">
          {item.profileImageUrl ? (
            <img src={item.profileImageUrl} alt="" className="w-8 h-8 rounded-full object-cover" />
          ) : (
            <div className="w-8 h-8 rounded-full bg-indigo-100 flex items-center justify-center">
              <User size={16} className="text-indigo-600" />
            </div>
          )}
          <span className="text-sm font-medium text-gray-900">{item.name || 'N/A'}</span>
        </div>
      )
    },
    { 
      key: 'phone', 
      label: 'Phone Number',
      render: (item) => (
        <span className="text-sm text-gray-900">{item.phone || 'N/A'}</span>
      )
    },
    { 
      key: 'skills', 
      label: 'Service Categories',
      render: (item) => (
        <span className="text-sm text-gray-600">
          {Array.isArray(item.skills) ? item.skills.slice(0, 2).join(', ') : item.skills || 'N/A'}
          {Array.isArray(item.skills) && item.skills.length > 2 && ` +${item.skills.length - 2}`}
        </span>
      )
    },
    { 
      key: 'city', 
      label: 'City',
      render: (item) => (
        <span className="text-sm text-gray-600">{item.city || item.district || 'N/A'}</span>
      )
    },
    { 
      key: 'rating', 
      label: 'Rating',
      render: (item) => (
        <div className="flex items-center gap-1">
          <Star size={14} className="text-yellow-500 fill-yellow-500" />
          <span className="text-sm font-medium text-gray-900">{item.rating?.toFixed(1) || '0.0'}</span>
        </div>
      )
    },
    { 
      key: 'completedJobs', 
      label: 'Completed Jobs',
      render: (item) => (
        <span className="text-sm text-gray-900">{item.completedJobs || 0}</span>
      )
    },
    { 
      key: 'walletBalance', 
      label: 'Wallet Balance',
      render: (item) => (
        <span className="text-sm font-medium text-gray-900">₹{item.walletBalance || 0}</span>
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
            className="px-3 py-1 text-xs bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
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
      <div className="bg-white rounded-xl border border-gray-200 p-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={18} />
            <input
              type="text"
              placeholder="Search by name or phone..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            />
            {searchTerm && (
              <button onClick={() => setSearchTerm('')} className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <X size={18} />
              </button>
            )}
          </div>

          <div className="relative">
            <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={18} />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent appearance-none bg-white"
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="offline">Offline</option>
              <option value="suspended">Suspended</option>
            </select>
          </div>

          <div className="flex items-center justify-end">
            <span className="text-sm text-gray-600">
              Showing {filteredTechnicians.length} of {technicians.length} technicians
            </span>
          </div>
        </div>
      </div>

      {/* Technicians Table */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <DataTable columns={columns} data={filteredTechnicians} loading={loading} emptyMessage="No technicians found" />
      </div>

      {/* Technician Details Modal */}
      {showDetailsModal && selectedTechnician && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 p-6 flex items-center justify-between">
              <h2 className="text-xl font-bold text-gray-900">Technician Details</h2>
              <button onClick={() => setShowDetailsModal(false)} className="text-gray-400 hover:text-gray-600">
                <X size={24} />
              </button>
            </div>
            <div className="p-6 space-y-6">
              {/* Profile Section */}
              <div className="flex items-start gap-6">
                {selectedTechnician.profileImageUrl ? (
                  <img src={selectedTechnician.profileImageUrl} alt="" className="w-24 h-24 rounded-full object-cover" />
                ) : (
                  <div className="w-24 h-24 rounded-full bg-indigo-100 flex items-center justify-center">
                    <User size={48} className="text-indigo-600" />
                  </div>
                )}
                <div className="flex-1">
                  <h3 className="text-2xl font-bold text-gray-900">{selectedTechnician.name}</h3>
                  <p className="text-gray-600">{selectedTechnician.phone}</p>
                  <p className="text-gray-600">{selectedTechnician.email || 'N/A'}</p>
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
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Service Information</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-600">Service Categories</p>
                    <p className="text-sm font-medium text-gray-900">
                      {Array.isArray(selectedTechnician.skills) ? selectedTechnician.skills.join(', ') : selectedTechnician.skills || 'N/A'}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Experience</p>
                    <p className="text-sm font-medium text-gray-900">{selectedTechnician.experience || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">City</p>
                    <p className="text-sm font-medium text-gray-900">{selectedTechnician.city || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">District</p>
                    <p className="text-sm font-medium text-gray-900">{selectedTechnician.district || 'N/A'}</p>
                  </div>
                </div>
              </div>

              {/* Performance Metrics */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Performance Metrics</h3>
                <div className="grid grid-cols-3 gap-4">
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Star size={20} className="text-yellow-500" />
                      <p className="text-sm text-gray-600">Average Rating</p>
                    </div>
                    <p className="text-2xl font-bold text-gray-900">{selectedTechnician.rating?.toFixed(1) || '0.0'}</p>
                  </div>
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Calendar size={20} className="text-indigo-600" />
                      <p className="text-sm text-gray-600">Completed Jobs</p>
                    </div>
                    <p className="text-2xl font-bold text-gray-900">{selectedTechnician.completedJobs || 0}</p>
                  </div>
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Wallet size={20} className="text-green-600" />
                      <p className="text-sm text-gray-600">Wallet Balance</p>
                    </div>
                    <p className="text-2xl font-bold text-gray-900">₹{selectedTechnician.walletBalance || 0}</p>
                  </div>
                </div>
              </div>

              {/* Recent Bookings */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Bookings</h3>
                {recentBookings.length > 0 ? (
                  <div className="space-y-2">
                    {recentBookings.map((booking) => (
                      <div key={booking.id} className="border border-gray-200 rounded-lg p-3 flex items-center justify-between">
                        <div>
                          <p className="text-sm font-medium text-gray-900">{booking.serviceType || 'N/A'}</p>
                          <p className="text-xs text-gray-600">{booking.customerName || 'N/A'}</p>
                        </div>
                        <StatusBadge status={booking.status} variant="info" />
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-gray-500 text-center py-4">No recent bookings</p>
                )}
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-3 pt-4 border-t border-gray-200">
                {selectedTechnician.suspended ? (
                  <button
                    onClick={() => {
                      setShowDetailsModal(false);
                      handleActivate(selectedTechnician.id);
                    }}
                    className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium"
                  >
                    Activate Technician
                  </button>
                ) : (
                  <button
                    onClick={() => {
                      setShowDetailsModal(false);
                      handleSuspend(selectedTechnician.id);
                    }}
                    className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium"
                  >
                    Suspend Technician
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Confirm Dialog */}
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
