'use client';

import { useState, useEffect } from 'react';
import { PageHeader, DataTable, StatusBadge, Column, ConfirmDialog } from '@/components/ui';
import { Search, Filter, X, User, FileText, Image as ImageIcon } from 'lucide-react';
import { db } from '@/lib/firebase';
import { collection, query, where, orderBy, limit as firestoreLimit, getDocs, Timestamp } from 'firebase/firestore';
import { adminApi } from '@/lib/admin-api';

export default function ApplicationsPage() {
  const [applications, setApplications] = useState<any[]>([]);
  const [filteredApplications, setFilteredApplications] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedApplication, setSelectedApplication] = useState<any>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
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
    fetchApplications();
  }, []);

  useEffect(() => {
    filterApplications();
  }, [applications, searchTerm, statusFilter]);

  const fetchApplications = async () => {
    try {
      setLoading(true);
      // FIXED: Query only pending technician applications, not all technicians
      const techQuery = query(
        collection(db, 'technicians'),
        where('status', '==', 'pending'),
        orderBy('createdAt', 'desc'),
        firestoreLimit(100)
      );
      const snapshot = await getDocs(techQuery);
      const appsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));
      setApplications(appsData);
    } catch (error) {
      console.error('Error fetching applications:', error);
    } finally {
      setLoading(false);
    }
  };

  const filterApplications = () => {
    let filtered = [...applications];

    if (statusFilter !== 'all') {
      filtered = filtered.filter(a => a.status === statusFilter);
    }

    if (searchTerm) {
      filtered = filtered.filter(a => 
        a.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        a.phone?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredApplications(filtered);
  };

  const handleViewDetails = (application: any) => {
    setSelectedApplication(application);
    setShowDetailsModal(true);
  };

  const handleApprove = (techId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Approve Application',
      message: 'Are you sure you want to approve this technician application? The technician will be able to receive bookings.',
      onConfirm: async () => {
        try {
          await adminApi.approveTechnicianApp(techId);
          await fetchApplications();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error approving application:', error);
        }
      },
    });
  };

  const handleReject = (techId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Reject Application',
      message: 'Are you sure you want to reject this technician application?',
      variant: 'danger',
      requireInput: true,
      inputLabel: 'Rejection Reason',
      inputPlaceholder: 'Please provide the reason for rejection...',
      onConfirm: async (inputValue?: string) => {
        try {
          const reason = inputValue || 'Rejected by admin';
          await adminApi.rejectTechnicianApp(techId, reason);
          await fetchApplications();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error rejecting application:', error);
        }
      },
    });
  };

  const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'info' | 'default' => {
    const statusMap: Record<string, 'success' | 'warning' | 'error' | 'info' | 'default'> = {
      'pending': 'warning',
      'approved': 'success',
      'rejected': 'error',
    };
    return statusMap[status] || 'default';
  };

  const formatStatus = (status: string): string => {
    return status.charAt(0).toUpperCase() + status.slice(1);
  };

  const columns: Column[] = [
    { 
      key: 'name', 
      label: 'Technician Name',
      sortable: true,
      render: (item) => (
        <span className="text-sm font-medium text-gray-900">{item.name || 'N/A'}</span>
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
      label: 'Service Category',
      render: (item) => (
        <span className="text-sm text-gray-600">
          {Array.isArray(item.skills) ? item.skills.join(', ') : item.skills || 'N/A'}
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
      key: 'experience', 
      label: 'Experience',
      render: (item) => (
        <span className="text-sm text-gray-600">{item.experience || 'N/A'}</span>
      )
    },
    { 
      key: 'createdAt', 
      label: 'Application Date',
      render: (item) => {
        const date = item.createdAt instanceof Timestamp 
          ? item.createdAt.toDate().toLocaleDateString()
          : 'N/A';
        return <span className="text-sm text-gray-600">{date}</span>;
      }
    },
    {
      key: 'status',
      label: 'Status',
      render: (item) => (
        <StatusBadge 
          status={formatStatus(item.status || 'pending')} 
          variant={getStatusVariant(item.status || 'pending')}
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
          {item.status === 'pending' && (
            <>
              <button
                onClick={() => handleApprove(item.id)}
                className="px-3 py-1 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
              >
                Approve
              </button>
              <button
                onClick={() => handleReject(item.id)}
                className="px-3 py-1 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
              >
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
      <PageHeader
        title="Technician Applications"
        description="Review and verify new technician registrations"
      />

      {/* Filters */}
      <div className="bg-white rounded-xl border border-gray-200 p-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Search */}
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
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                <X size={18} />
              </button>
            )}
          </div>

          {/* Status Filter */}
          <div className="relative">
            <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={18} />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent appearance-none bg-white"
            >
              <option value="all">All Status</option>
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
            </select>
          </div>

          {/* Results Count */}
          <div className="flex items-center justify-end">
            <span className="text-sm text-gray-600">
              Showing {filteredApplications.length} of {applications.length} applications
            </span>
          </div>
        </div>
      </div>

      {/* Applications Table */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <DataTable
          columns={columns}
          data={filteredApplications}
          loading={loading}
          emptyMessage="No technician applications found"
        />
      </div>

      {/* Technician Details Modal */}
      {showDetailsModal && selectedApplication && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 p-6 flex items-center justify-between">
              <h2 className="text-xl font-bold text-gray-900">Technician Application Details</h2>
              <button
                onClick={() => setShowDetailsModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X size={24} />
              </button>
            </div>
            <div className="p-6 space-y-6">
              {/* Basic Information */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Basic Information</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-600">Full Name</p>
                    <p className="text-sm font-medium text-gray-900">{selectedApplication.name || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Phone Number</p>
                    <p className="text-sm font-medium text-gray-900">{selectedApplication.phone || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Email</p>
                    <p className="text-sm font-medium text-gray-900">{selectedApplication.email || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Status</p>
                    <StatusBadge 
                      status={formatStatus(selectedApplication.status || 'pending')} 
                      variant={getStatusVariant(selectedApplication.status || 'pending')}
                    />
                  </div>
                </div>
              </div>

              {/* Service Information */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Service Information</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-600">Service Category</p>
                    <p className="text-sm font-medium text-gray-900">
                      {Array.isArray(selectedApplication.skills) 
                        ? selectedApplication.skills.join(', ') 
                        : selectedApplication.skills || 'N/A'}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Experience</p>
                    <p className="text-sm font-medium text-gray-900">{selectedApplication.experience || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">City</p>
                    <p className="text-sm font-medium text-gray-900">{selectedApplication.city || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">District</p>
                    <p className="text-sm font-medium text-gray-900">{selectedApplication.district || 'N/A'}</p>
                  </div>
                </div>
              </div>

              {/* Documents */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Verification Documents</h3>
                <div className="grid grid-cols-3 gap-4">
                  <div className="border border-gray-200 rounded-lg p-4">
                    <div className="aspect-square bg-gray-100 rounded-lg flex items-center justify-center mb-2">
                      {selectedApplication.profileImageUrl ? (
                        <img 
                          src={selectedApplication.profileImageUrl} 
                          alt="Profile" 
                          className="w-full h-full object-cover rounded-lg"
                        />
                      ) : (
                        <User className="text-gray-400" size={48} />
                      )}
                    </div>
                    <p className="text-xs text-center text-gray-600">Profile Photo</p>
                  </div>
                  <div className="border border-gray-200 rounded-lg p-4">
                    <div className="aspect-square bg-gray-100 rounded-lg flex items-center justify-center mb-2">
                      <FileText className="text-gray-400" size={48} />
                    </div>
                    <p className="text-xs text-center text-gray-600">Government ID</p>
                  </div>
                  <div className="border border-gray-200 rounded-lg p-4">
                    <div className="aspect-square bg-gray-100 rounded-lg flex items-center justify-center mb-2">
                      <ImageIcon className="text-gray-400" size={48} />
                    </div>
                    <p className="text-xs text-center text-gray-600">Work Certificate</p>
                  </div>
                </div>
              </div>

              {/* Application Notes */}
              {selectedApplication.notes && (
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Application Notes</h3>
                  <p className="text-sm text-gray-700 bg-gray-50 p-4 rounded-lg">
                    {selectedApplication.notes}
                  </p>
                </div>
              )}

              {/* Action Buttons */}
              {selectedApplication.status === 'pending' && (
                <div className="flex items-center gap-3 pt-4 border-t border-gray-200">
                  <button
                    onClick={() => {
                      setShowDetailsModal(false);
                      handleApprove(selectedApplication.id);
                    }}
                    className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium"
                  >
                    Approve Application
                  </button>
                  <button
                    onClick={() => {
                      setShowDetailsModal(false);
                      handleReject(selectedApplication.id);
                    }}
                    className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium"
                  >
                    Reject Application
                  </button>
                </div>
              )}
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
        inputLabel="Rejection Reason"
        inputPlaceholder="Enter reason for rejection..."
      />
    </div>
  );
}
