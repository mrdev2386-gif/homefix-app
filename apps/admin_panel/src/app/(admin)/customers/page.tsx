'use client';

import { useState, useEffect } from 'react';
import { PageHeader, DataTable, StatusBadge, Column, ConfirmDialog } from '@/components/ui';
import { Search, Filter, X, User, Calendar, Wallet, ShoppingBag } from 'lucide-react';
import { db } from '@/lib/firebase';
import { collection, query, orderBy, limit as firestoreLimit, getDocs, where, Timestamp } from 'firebase/firestore';
import { adminApi } from '@/lib/admin-api';

export default function CustomersPage() {
  const [customers, setCustomers] = useState<any[]>([]);
  const [filteredCustomers, setFilteredCustomers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedCustomer, setSelectedCustomer] = useState<any>(null);
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
    fetchCustomers();
  }, []);

  useEffect(() => {
    filterCustomers();
  }, [customers, searchTerm, statusFilter]);

  const fetchCustomers = async () => {
    try {
      setLoading(true);
      const customersQuery = query(
        collection(db, 'customers'),
        orderBy('createdAt', 'desc'),
        firestoreLimit(100)
      );
      const snapshot = await getDocs(customersQuery);
      const customersData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));
      setCustomers(customersData);
    } catch (error) {
      console.error('Error fetching customers:', error);
    } finally {
      setLoading(false);
    }
  };

  const filterCustomers = () => {
    let filtered = [...customers];
    if (statusFilter !== 'all') {
      if (statusFilter === 'active') {
        filtered = filtered.filter(c => !c.blocked);
      } else if (statusFilter === 'blocked') {
        filtered = filtered.filter(c => c.blocked === true);
      }
    }
    if (searchTerm) {
      filtered = filtered.filter(c =>
        c.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.phone?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }
    setFilteredCustomers(filtered);
  };

  const handleViewDetails = async (customer: any) => {
    setSelectedCustomer(customer);
    try {
      const bookingsQuery = query(
        collection(db, 'bookings'),
        where('customerId', '==', customer.id),
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

  const handleBlock = (customerId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Block Customer',
      message: 'Are you sure you want to block this customer? They will not be able to place new bookings.',
      variant: 'danger',
      requireInput: true,
      inputLabel: 'Block Reason',
      inputPlaceholder: 'Please provide the reason for blocking...',
      onConfirm: async (inputValue?: string) => {
        try {
          await adminApi.blockUser(customerId, true);
          await fetchCustomers();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error blocking customer:', error);
        }
      },
    });
  };

  const handleUnblock = (customerId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Unblock Customer',
      message: 'Are you sure you want to unblock this customer? They will be able to place bookings again.',
      onConfirm: async () => {
        try {
          await adminApi.blockUser(customerId, false);
          await fetchCustomers();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error unblocking customer:', error);
        }
      },
    });
  };

  const columns: Column[] = [
    {
      key: 'name',
      label: 'Customer Name',
      sortable: true,
      render: (item) => (
        <div className="flex items-center gap-2.5">
          {item.photoUrl ? (
            <img src={item.photoUrl} alt="" className="w-8 h-8 rounded-full object-cover" />
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
      key: 'city',
      label: 'City',
      render: (item) => (
        <span className="text-sm text-[#9CA3AF]">{item.city || item.district || 'N/A'}</span>
      )
    },
    {
      key: 'totalBookings',
      label: 'Total Bookings',
      render: (item) => (
        <span className="text-sm text-[#E5E7EB]">{item.totalBookings || 0}</span>
      )
    },
    {
      key: 'completedBookings',
      label: 'Completed',
      render: (item) => (
        <span className="text-sm text-[#E5E7EB]">{item.completedBookings || 0}</span>
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
      label: 'Account Status',
      render: (item) => (
        <StatusBadge
          status={item.blocked ? 'Blocked' : 'Active'}
          variant={item.blocked ? 'error' : 'success'}
        />
      )
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
          {item.blocked ? (
            <button
              onClick={() => handleUnblock(item.id)}
              className="px-3 py-1 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
            >
              Unblock
            </button>
          ) : (
            <button
              onClick={() => handleBlock(item.id)}
              className="px-3 py-1 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
            >
              Block
            </button>
          )}
        </div>
      )
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Customers"
        description="Manage and monitor all platform customers"
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
              <option value="blocked">Blocked</option>
            </select>
          </div>

          <div className="flex items-center justify-end">
            <span className="text-sm text-[#6B7280]">
              {filteredCustomers.length} of {customers.length} customers
            </span>
          </div>
        </div>
      </div>

      {/* Customers Table */}
      <div className="admin-card p-6">
        <DataTable columns={columns} data={filteredCustomers} loading={loading} emptyMessage="No customers found" />
      </div>

      {/* Customer Details Modal */}
      {showDetailsModal && selectedCustomer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="bg-[#111827] border border-[#1F2937] rounded-xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-[#111827] border-b border-[#1F2937] px-6 py-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-[#E5E7EB]">Customer Details</h2>
              <button onClick={() => setShowDetailsModal(false)} className="p-1.5 text-[#6B7280] hover:text-[#E5E7EB] hover:bg-[#1F2937] rounded-lg transition-colors">
                <X size={18} />
              </button>
            </div>
            <div className="p-6 space-y-6">
              {/* Profile Section */}
              <div className="flex items-start gap-5">
                {selectedCustomer.photoUrl ? (
                  <img src={selectedCustomer.photoUrl} alt="" className="w-20 h-20 rounded-full object-cover flex-shrink-0" />
                ) : (
                  <div className="w-20 h-20 rounded-full bg-[#6366F1]/20 flex items-center justify-center flex-shrink-0">
                    <User size={36} className="text-[#6366F1]" />
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <h3 className="text-xl font-bold text-[#E5E7EB]">{selectedCustomer.name}</h3>
                  <p className="text-sm text-[#9CA3AF] mt-0.5">{selectedCustomer.phone}</p>
                  <p className="text-sm text-[#9CA3AF]">{selectedCustomer.email || 'N/A'}</p>
                  <div className="mt-2">
                    <StatusBadge
                      status={selectedCustomer.blocked ? 'Blocked' : 'Active'}
                      variant={selectedCustomer.blocked ? 'error' : 'success'}
                    />
                  </div>
                </div>
              </div>

              {/* Location Info */}
              <div>
                <p className="text-xs font-semibold text-[#6B7280] uppercase tracking-wider mb-3">Location Information</p>
                <div className="grid grid-cols-2 gap-3">
                  {[
                    { label: 'City', value: selectedCustomer.city },
                    { label: 'District', value: selectedCustomer.district },
                  ].map(({ label, value }) => (
                    <div key={label} className="bg-[#0F172A] rounded-lg p-3">
                      <p className="text-xs text-[#6B7280] mb-1">{label}</p>
                      <p className="text-sm font-medium text-[#E5E7EB]">{value || 'N/A'}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Statistics */}
              <div>
                <p className="text-xs font-semibold text-[#6B7280] uppercase tracking-wider mb-3">Statistics</p>
                <div className="grid grid-cols-3 gap-3">
                  <div className="bg-[#0F172A] rounded-lg p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <ShoppingBag size={15} className="text-[#6366F1]" />
                      <p className="text-xs text-[#6B7280]">Total Bookings</p>
                    </div>
                    <p className="text-2xl font-bold text-[#E5E7EB]">{selectedCustomer.totalBookings || 0}</p>
                  </div>
                  <div className="bg-[#0F172A] rounded-lg p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <Calendar size={15} className="text-green-500" />
                      <p className="text-xs text-[#6B7280]">Completed</p>
                    </div>
                    <p className="text-2xl font-bold text-[#E5E7EB]">{selectedCustomer.completedBookings || 0}</p>
                  </div>
                  <div className="bg-[#0F172A] rounded-lg p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <X size={15} className="text-red-500" />
                      <p className="text-xs text-[#6B7280]">Cancelled</p>
                    </div>
                    <p className="text-2xl font-bold text-[#E5E7EB]">{selectedCustomer.cancelledBookings || 0}</p>
                  </div>
                </div>
              </div>

              {/* Financial Info */}
              <div>
                <p className="text-xs font-semibold text-[#6B7280] uppercase tracking-wider mb-3">Financial Information</p>
                <div className="grid grid-cols-2 gap-3">
                  <div className="bg-[#0F172A] rounded-lg p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <Wallet size={15} className="text-green-500" />
                      <p className="text-xs text-[#6B7280]">Wallet Balance</p>
                    </div>
                    <p className="text-2xl font-bold text-[#E5E7EB]">₹{selectedCustomer.walletBalance || 0}</p>
                  </div>
                  <div className="bg-[#0F172A] rounded-lg p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <ShoppingBag size={15} className="text-[#6366F1]" />
                      <p className="text-xs text-[#6B7280]">Total Spent</p>
                    </div>
                    <p className="text-2xl font-bold text-[#E5E7EB]">₹{selectedCustomer.totalSpent || 0}</p>
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
                          <p className="text-xs text-[#6B7280]">
                            {booking.createdAt instanceof Timestamp
                              ? booking.createdAt.toDate().toLocaleDateString()
                              : 'N/A'}
                          </p>
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
                {selectedCustomer.blocked ? (
                  <button
                    onClick={() => { setShowDetailsModal(false); handleUnblock(selectedCustomer.id); }}
                    className="flex-1 px-4 py-2.5 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors text-sm font-medium"
                  >
                    Unblock Customer
                  </button>
                ) : (
                  <button
                    onClick={() => { setShowDetailsModal(false); handleBlock(selectedCustomer.id); }}
                    className="flex-1 px-4 py-2.5 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors text-sm font-medium"
                  >
                    Block Customer
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
        inputLabel="Block Reason"
        inputPlaceholder="Enter reason for blocking..."
      />
    </div>
  );
}
