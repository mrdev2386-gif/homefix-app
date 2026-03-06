'use client';

import { useState, useEffect } from 'react';
import { PageHeader, DataTable, StatusBadge, Column, ConfirmDialog } from '@/components/ui';
import { Search, Filter, X, Image as ImageIcon } from 'lucide-react';
import { db } from '@/lib/firebase';
import { collection, query, where, orderBy, limit as firestoreLimit, getDocs, Timestamp } from 'firebase/firestore';
import { adminApi } from '@/lib/admin-api';

export default function CustomRequestsPage() {
  const [requests, setRequests] = useState<any[]>([]);
  const [filteredRequests, setFilteredRequests] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedRequest, setSelectedRequest] = useState<any>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [availableTechnicians, setAvailableTechnicians] = useState<any[]>([]);
  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    onConfirm: () => void;
    variant?: 'default' | 'danger';
    requireInput?: boolean;
  }>({ isOpen: false, title: '', message: '', onConfirm: () => {} });

  useEffect(() => {
    fetchRequests();
  }, []);

  useEffect(() => {
    filterRequests();
  }, [requests, searchTerm, statusFilter]);

  const fetchRequests = async () => {
    try {
      setLoading(true);
      const requestsQuery = query(
        collection(db, 'custom_requests'),
        orderBy('createdAt', 'desc'),
        firestoreLimit(100)
      );
      const snapshot = await getDocs(requestsQuery);
      const requestsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));
      setRequests(requestsData);
    } catch (error) {
      console.error('Error fetching requests:', error);
    } finally {
      setLoading(false);
    }
  };

  const filterRequests = () => {
    let filtered = [...requests];

    if (statusFilter !== 'all') {
      filtered = filtered.filter(r => r.status === statusFilter);
    }

    if (searchTerm) {
      filtered = filtered.filter(r => 
        r.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.customerName?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredRequests(filtered);
  };

  const handleViewDetails = (request: any) => {
    setSelectedRequest(request);
    setShowDetailsModal(true);
  };

  const handleAssignTechnician = async (request: any) => {
    setSelectedRequest(request);
    try {
      const techQuery = query(
        collection(db, 'technicians'),
        where('status', '==', 'approved'),
        where('isOnline', '==', true),
        firestoreLimit(20)
      );
      const techSnapshot = await getDocs(techQuery);
      let techs = techSnapshot.docs.map(doc => ({ 
        id: doc.id, 
        ...doc.data() 
      })) as Array<{ id: string; district?: string; [key: string]: any }>;
      
      // Filter by district if available
      if (request.district) {
        techs = techs.filter(t => t.district === request.district);
      }
      
      setAvailableTechnicians(techs);
      setShowAssignModal(true);
    } catch (error) {
      console.error('Error fetching technicians:', error);
    }
  };

  const handleMarkResolved = (requestId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Mark as Resolved',
      message: 'Are you sure you want to mark this request as resolved?',
      onConfirm: async () => {
        try {
          await adminApi.convertCustomRequest(requestId);
          await fetchRequests();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error marking resolved:', error);
        }
      },
    });
  };

  const handleReject = (requestId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Reject Request',
      message: 'Are you sure you want to reject this custom request?',
      variant: 'danger',
      requireInput: true,
      onConfirm: async () => {
        try {
          await adminApi.rejectCustomRequest(requestId, 'Rejected by admin');
          await fetchRequests();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error rejecting request:', error);
        }
      },
    });
  };

  const handleAssign = async (requestId: string, technicianId: string) => {
    try {
      await adminApi.approveServiceRequest(requestId, technicianId);
      await fetchRequests();
      setShowAssignModal(false);
    } catch (error) {
      console.error('Error assigning technician:', error);
    }
  };

  const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'info' | 'default' => {
    const statusMap: Record<string, 'success' | 'warning' | 'error' | 'info' | 'default'> = {
      'pending': 'warning',
      'assigned': 'info',
      'in_progress': 'info',
      'resolved': 'success',
      'rejected': 'error',
    };
    return statusMap[status] || 'default';
  };

  const formatStatus = (status: string): string => {
    return status.split('_').map(word => 
      word.charAt(0).toUpperCase() + word.slice(1)
    ).join(' ');
  };

  const columns: Column[] = [
    { 
      key: 'id', 
      label: 'Request ID',
      sortable: true,
      render: (item) => (
        <span className="text-sm font-mono text-gray-900">
          {item.id.substring(0, 8)}
        </span>
      )
    },
    { 
      key: 'customerName', 
      label: 'Customer',
      render: (item) => (
        <span className="text-sm text-gray-900">{item.customerName || 'N/A'}</span>
      )
    },
    { 
      key: 'description', 
      label: 'Description',
      render: (item) => (
        <span className="text-sm text-gray-900 truncate max-w-xs block">
          {item.description || 'N/A'}
        </span>
      )
    },
    { 
      key: 'category', 
      label: 'Category',
      render: (item) => (
        <span className="text-sm text-gray-600">{item.category || 'General'}</span>
      )
    },
    { 
      key: 'location', 
      label: 'Location',
      render: (item) => (
        <span className="text-sm text-gray-600">{item.district || item.city || 'N/A'}</span>
      )
    },
    { 
      key: 'createdAt', 
      label: 'Requested Date',
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
                onClick={() => handleAssignTechnician(item)}
                className="px-3 py-1 text-xs bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
              >
                Assign
              </button>
              <button
                onClick={() => handleReject(item.id)}
                className="px-3 py-1 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
              >
                Reject
              </button>
            </>
          )}
          {(item.status === 'assigned' || item.status === 'in_progress') && (
            <button
              onClick={() => handleMarkResolved(item.id)}
              className="px-3 py-1 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
            >
              Resolve
            </button>
          )}
        </div>
      )
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Custom Requests"
        description="Review and manage custom service requests from customers"
      />

      {/* Filters */}
      <div className="bg-white rounded-xl border border-gray-200 p-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={18} />
            <input
              type="text"
              placeholder="Search by ID or customer name..."
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
              <option value="assigned">Assigned</option>
              <option value="in_progress">In Progress</option>
              <option value="resolved">Resolved</option>
              <option value="rejected">Rejected</option>
            </select>
          </div>

          {/* Results Count */}
          <div className="flex items-center justify-end">
            <span className="text-sm text-gray-600">
              Showing {filteredRequests.length} of {requests.length} requests
            </span>
          </div>
        </div>
      </div>

      {/* Requests Table */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <DataTable
          columns={columns}
          data={filteredRequests}
          loading={loading}
          emptyMessage="No custom requests found"
        />
      </div>

      {/* Request Details Modal */}
      {showDetailsModal && selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 p-6 flex items-center justify-between">
              <h2 className="text-xl font-bold text-gray-900">Request Details</h2>
              <button
                onClick={() => setShowDetailsModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X size={24} />
              </button>
            </div>
            <div className="p-6 space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-gray-600">Request ID</p>
                  <p className="text-sm font-medium text-gray-900">{selectedRequest.id}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Status</p>
                  <StatusBadge 
                    status={formatStatus(selectedRequest.status || 'pending')} 
                    variant={getStatusVariant(selectedRequest.status || 'pending')}
                  />
                </div>
                <div>
                  <p className="text-sm text-gray-600">Customer</p>
                  <p className="text-sm font-medium text-gray-900">{selectedRequest.customerName || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Category</p>
                  <p className="text-sm font-medium text-gray-900">{selectedRequest.category || 'General'}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Phone</p>
                  <p className="text-sm font-medium text-gray-900">{selectedRequest.phone || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Requested Date</p>
                  <p className="text-sm font-medium text-gray-900">
                    {selectedRequest.createdAt instanceof Timestamp 
                      ? selectedRequest.createdAt.toDate().toLocaleString()
                      : 'N/A'}
                  </p>
                </div>
              </div>
              <div>
                <p className="text-sm text-gray-600 mb-2">Description</p>
                <p className="text-sm text-gray-900">{selectedRequest.description || 'N/A'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600 mb-2">Address</p>
                <p className="text-sm text-gray-900">
                  {selectedRequest.address || 'N/A'}<br />
                  {selectedRequest.district}, {selectedRequest.state}<br />
                  {selectedRequest.pincode}
                </p>
              </div>
              {selectedRequest.images && selectedRequest.images.length > 0 && (
                <div>
                  <p className="text-sm text-gray-600 mb-2">Uploaded Images</p>
                  <div className="grid grid-cols-3 gap-2">
                    {selectedRequest.images.map((img: string, idx: number) => (
                      <div key={idx} className="aspect-square bg-gray-100 rounded-lg flex items-center justify-center">
                        <ImageIcon className="text-gray-400" size={32} />
                      </div>
                    ))}
                  </div>
                </div>
              )}
              {selectedRequest.technicianName && (
                <div>
                  <p className="text-sm text-gray-600 mb-2">Assigned Technician</p>
                  <p className="text-sm font-medium text-gray-900">{selectedRequest.technicianName}</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Assign Technician Modal */}
      {showAssignModal && selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 p-6 flex items-center justify-between">
              <h2 className="text-xl font-bold text-gray-900">Assign Technician</h2>
              <button
                onClick={() => setShowAssignModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X size={24} />
              </button>
            </div>
            <div className="p-6 space-y-4">
              {availableTechnicians.length === 0 ? (
                <p className="text-center text-gray-500 py-8">No available technicians found in this area</p>
              ) : (
                availableTechnicians.map(tech => (
                  <div key={tech.id} className="border border-gray-200 rounded-lg p-4 hover:border-indigo-500 transition-colors">
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <p className="font-medium text-gray-900">{tech.name}</p>
                        <div className="flex items-center gap-4 mt-1">
                          <p className="text-sm text-gray-600">{tech.city || tech.district}</p>
                          <p className="text-sm text-gray-600">Rating: {tech.rating || 'N/A'}</p>
                          {tech.experience && (
                            <p className="text-sm text-gray-600">Exp: {tech.experience}</p>
                          )}
                        </div>
                        <div className="mt-2">
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-green-100 text-green-700">
                            Online & Available
                          </span>
                        </div>
                      </div>
                      <button
                        onClick={() => handleAssign(selectedRequest.id, tech.id)}
                        className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
                      >
                        Assign
                      </button>
                    </div>
                  </div>
                ))
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
        inputLabel="Reason for rejection"
        inputPlaceholder="Enter reason..."
      />
    </div>
  );
}
