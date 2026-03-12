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
    onConfirm: () => void;
    variant?: 'default' | 'danger';
    requireInput?: boolean;
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
          // Note: blockUser API may need updating to support reason parameter
          await adminApi.blockUser(customerId, true);
          // TODO: Pass reason to API if backend supports it
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
        <div className="flex items-center gap-2">
          {item.photoUrl ? (
            <img src={item.photoUrl} alt="" className="w-8 h-8 rounded-full object-cover" />
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
      key: 'city', 
      label: 'City',
      render: (item) => (
        <span className="text-sm text-gray-600">{item.city || item.district || 'N/A'}</span>
      )
    },
    { 
      key: 'totalBookings', 
      label: 'Total Bookings',
      render: (item) => (
        <span className="text-sm text-gray-900">{item.totalBookings || 0}</span>
      )
    },
    { 
      key: 'completedBookings', 
      label: 'Completed',
      render: (item) => (
        <span className="text-sm text-gray-900">{item.completedBookings || 0}</span>
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
            className="px-3 py-1 text-xs bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
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
              <option value="blocked">Blocked</option>
            </select>
          </div>

          <div className="flex items-center justify-end">
            <span className="text-sm text-gray-600">
              Showing {filteredCustomers.length} of {customers.length} customers
            </span>
          </div>
        </div>
      </div>

      {/* Customers Table */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <DataTable columns={columns} data={filteredCustomers} loading={loading} emptyMessage="No customers found" />
      </div>

      {/* Customer Details Modal */}
      {showDetailsModal && selectedCustomer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 p-6 flex items-center justify-between">
              <h2 className="text-xl font-bold text-gray-900">Customer Details</h2>
              <button onClick={() => setShowDetailsModal(false)} className="text-gray-400 hover:text-gray-600">
                <X size={24} />
              </button>
            </div>
            <div className="p-6 space-y-6">
              {/* Profile Section */}
              <div className="flex items-start gap-6">
                {selectedCustomer.photoUrl ? (
                  <img src={selectedCustomer.photoUrl} alt="" className="w-24 h-24 rounded-full object-cover" />
                ) : (
                  <div className="w-24 h-24 rounded-full bg-indigo-100 flex items-center justify-center">
                    <User size={48} className="text-indigo-600" />
                  </div>
                )}
                <div className="flex-1">
                  <h3 className="text-2xl font-bold text-gray-900">{selectedCustomer.name}</h3>
                  <p className="text-gray-600">{selectedCustomer.phone}</p>
                  <p className="text-gray-600">{selectedCustomer.email || 'N/A'}</p>
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
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Location Information</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-600">City</p>
                    <p className="text-sm font-medium text-gray-900">{selectedCustomer.city || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">District</p>
                    <p className="text-sm font-medium text-gray-900">{selectedCustomer.district || 'N/A'}</p>
                  </div>
                </div>
              </div>

              {/* Statistics */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Statistics</h3>
                <div className="grid grid-cols-3 gap-4">
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <ShoppingBag size={20} className="text-indigo-600" />
                      <p className="text-sm text-gray-600">Total Bookings</p>
                    </div>
                    <p className="text-2xl font-bold text-gray-900">{selectedCustomer.totalBookings || 0}</p>
                  </div>
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Calendar size={20} className="text-green-600" />
                      <p className="text-sm text-gray-600">Completed</p>
                    </div>
                    <p className="text-2xl font-bold text-gray-900">{selectedCustomer.completedBookings || 0}</p>
                  </div>
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <X size={20} className="text-red-600" />
                      <p className="text-sm text-gray-600">Cancelled</p>
                    </div>
                    <p className="text-2xl font-bold text-gray-900">{selectedCustomer.cancelledBookings || 0}</p>
                  </div>
                </div>
              </div>

              {/* Financial Info */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Financial Information</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Wallet size={20} className="text-green-600" />
                      <p className="text-sm text-gray-600">Wallet Balance</p>
                    </div>
                    <p className="text-2xl font-bold text-gray-900">₹{selectedCustomer.walletBalance || 0}</p>
                  </div>
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <ShoppingBag size={20} className="text-indigo-600" />
                      <p className="text-sm text-gray-600">Total Spent</p>
                    </div>
                    <p className="text-2xl font-bold text-gray-900">₹{selectedCustomer.totalSpent || 0}</p>
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
                          <p className="text-xs text-gray-600">
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
                  <p className="text-sm text-gray-500 text-center py-4">No recent bookings</p>
                )}
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-3 pt-4 border-t border-gray-200">
                {selectedCustomer.blocked ? (
                  <button
                    onClick={() => {
                      setShowDetailsModal(false);
                      handleUnblock(selectedCustomer.id);
                    }}
                    className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium"
                  >
                    Unblock Customer
                  </button>
                ) : (
                  <button
                    onClick={() => {
                      setShowDetailsModal(false);
                      handleBlock(selectedCustomer.id);
                    }}
                    className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium"
                  >
                    Block Customer
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
        inputLabel="Block Reason"
        inputPlaceholder="Enter reason for blocking..."
      />
    </div>
  );
}
