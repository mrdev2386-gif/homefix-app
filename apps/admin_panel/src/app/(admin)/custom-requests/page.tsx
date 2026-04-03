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
    onConfirm: (inputValue?: string) => void;
    variant?: 'default' | 'danger';
    requireInput?: boolean;
    inputLabel?: string;
    inputPlaceholder?: string;
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
      inputLabel: 'Rejection Reason',
      inputPlaceholder: 'Please provide the reason for rejection...',
      onConfirm: async (inputValue?: string) => {
        try {
          const reason = inputValue || 'Rejected by admin';
          await adminApi.rejectCustomRequest(requestId, reason);
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
        <span className="text-sm font-mono text-[#9CA3AF]">{item.id.substring(0, 8)}</span>
      )
    },
    {
      key: 'customerName',
      label: 'Customer',
      render: (item) => (
        <span className="text-sm text-[#E5E7EB]">{item.customerName || 'N/A'}</span>
      )
    },
    {
      key: 'description',
      label: 'Description',
      render: (item) => (
        <span className="text-sm text-[#E5E7EB] truncate max-w-xs block">{item.description || 'N/A'}</span>
      )
    },
    {
      key: 'category',
      label: 'Category',
      render: (item) => (
        <span className="text-sm text-[#9CA3AF]">{item.category || 'General'}</span>
      )
    },
    {
      key: 'location',
      label: 'Location',
      render: (item) => (
        <span className="text-sm text-[#9CA3AF]">{item.district || item.city || 'N/A'}</span>
      )
    },
    {
      key: 'createdAt',
      label: 'Requested Date',
      render: (item) => {
        const date = item.createdAt instanceof Timestamp
          ? item.createdAt.toDate().toLocaleDateString()
          : 'N/A';
        return <span className="text-sm text-[#9CA3AF]">{date}</span>;
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
            className="px-3 py-1 text-xs bg-[#1F2937] text-[#9CA3AF] rounded-lg hover:bg-[#374151] hover:text-[#E5E7EB] transition-colors"
          >
            View
          </button>
          {item.status === 'pending' && (
            <>
              <button
                onClick={() => handleAssignTechnician(item)}
                className="px-3 py-1 text-xs bg-[#6366F1] text-white rounded-lg hover:bg-[#4F46E5] transition-colors"
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
      <div className="bg-[#111827] rounded-xl p-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-[#6B7280]" size={16} />
            <input
              type="text"
              placeholder="Search by ID or customer name..."
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
              <option value="assigned">Assigned</option>
              <option value="in_progress">In Progress</option>
              <option value="resolved">Resolved</option>
              <option value="rejected">Rejected</option>
            </select>
          </div>

          <div className="flex items-center justify-end">
            <span className="text-sm text-[#6B7280]">
              {filteredRequests.length} of {requests.length} requests
            </span>
          </div>
        </div>
      </div>

      {/* Requests Table */}
      <div className="admin-card p-6">
        <DataTable
          columns={columns}
          data={filteredRequests}
          loading={loading}
          emptyMessage="No custom requests found"
        />
      </div>

      {/* Request Details Modal */}
      {showDetailsModal && selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="bg-[#111827] border border-[#1F2937] rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-[#111827] border-b border-[#1F2937] px-6 py-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-[#E5E7EB]">Request Details</h2>
              <button
                onClick={() => setShowDetailsModal(false)}
                className="p-1.5 text-[#6B7280] hover:text-[#E5E7EB] hover:bg-[#1F2937] rounded-lg transition-colors"
              >
                <X size={18} />
              </button>
            </div>
            <div className="p-6 space-y-5">
              <div className="grid grid-cols-2 gap-3">
                {[
                  { label: 'Request ID', value: selectedRequest.id },
                  { label: 'Customer', value: selectedRequest.customerName },
                  { label: 'Phone', value: selectedRequest.phone },
                  { label: 'Category', value: selectedRequest.category || 'General' },
                  { label: 'Requested Date', value: selectedRequest.createdAt instanceof Timestamp ? selectedRequest.createdAt.toDate().toLocaleString() : 'N/A' },
                ].map(({ label, value }) => (
                  <div key={label} className="bg-[#0F172A] rounded-lg p-3">
                    <p className="text-xs text-[#6B7280] mb-1">{label}</p>
                    <p className="text-sm font-medium text-[#E5E7EB]">{value || 'N/A'}</p>
                  </div>
                ))}
                <div className="bg-[#0F172A] rounded-lg p-3">
                  <p className="text-xs text-[#6B7280] mb-1">Status</p>
                  <StatusBadge
                    status={formatStatus(selectedRequest.status || 'pending')}
                    variant={getStatusVariant(selectedRequest.status || 'pending')}
                  />
                </div>
              </div>

              <div className="bg-[#0F172A] rounded-lg p-4">
                <p className="text-xs text-[#6B7280] mb-2">Description</p>
                <p className="text-sm text-[#E5E7EB] leading-relaxed">{selectedRequest.description || 'N/A'}</p>
              </div>

              <div className="bg-[#0F172A] rounded-lg p-4">
                <p className="text-xs text-[#6B7280] mb-2">Address</p>
                <p className="text-sm text-[#E5E7EB] leading-relaxed">
                  {selectedRequest.address || 'N/A'}<br />
                  {selectedRequest.district}, {selectedRequest.state}<br />
                  {selectedRequest.pincode}
                </p>
              </div>

              {selectedRequest.images && selectedRequest.images.length > 0 && (
                <div>
                  <p className="text-xs text-[#6B7280] mb-3">Uploaded Images</p>
                  <div className="grid grid-cols-3 gap-2">
                    {selectedRequest.images.map((img: string, idx: number) => (
                      <div key={idx} className="aspect-square bg-[#1F2937] rounded-lg flex items-center justify-center">
                        <ImageIcon className="text-[#374151]" size={28} />
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {selectedRequest.technicianName && (
                <div className="bg-[#0F172A] rounded-lg p-4">
                  <p className="text-xs text-[#6B7280] mb-1">Assigned Technician</p>
                  <p className="text-sm font-medium text-[#E5E7EB]">{selectedRequest.technicianName}</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Assign Technician Modal */}
      {showAssignModal && selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="bg-[#111827] border border-[#1F2937] rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-[#111827] border-b border-[#1F2937] px-6 py-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-[#E5E7EB]">Assign Technician</h2>
              <button
                onClick={() => setShowAssignModal(false)}
                className="p-1.5 text-[#6B7280] hover:text-[#E5E7EB] hover:bg-[#1F2937] rounded-lg transition-colors"
              >
                <X size={18} />
              </button>
            </div>
            <div className="p-6 space-y-3">
              {availableTechnicians.length === 0 ? (
                <p className="text-center text-[#6B7280] py-10 text-sm">No available technicians found in this area</p>
              ) : (
                availableTechnicians.map(tech => (
                  <div key={tech.id} className="bg-[#0F172A] rounded-lg p-4 hover:bg-[#1F2937] transition-colors">
                    <div className="flex items-center justify-between">
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-[#E5E7EB] text-sm">{tech.name}</p>
                        <div className="flex items-center gap-3 mt-1 flex-wrap">
                          <p className="text-xs text-[#6B7280]">{tech.city || tech.district}</p>
                          <p className="text-xs text-[#6B7280]">Rating: {tech.rating || 'N/A'}</p>
                          {tech.experience && (
                            <p className="text-xs text-[#6B7280]">Exp: {tech.experience}</p>
                          )}
                        </div>
                        <div className="mt-2">
                          <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs bg-green-500/20 text-green-400">
                            Online & Available
                          </span>
                        </div>
                      </div>
                      <button
                        onClick={() => handleAssign(selectedRequest.id, tech.id)}
                        className="ml-4 px-4 py-2 bg-[#6366F1] text-white rounded-lg hover:bg-[#4F46E5] transition-colors text-sm flex-shrink-0"
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
