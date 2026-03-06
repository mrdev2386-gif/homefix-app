'use client';

import { useState, useEffect } from 'react';
import { PageHeader, Table, StatusBadge, Column, ConfirmDialog } from '@/components/ui';
import { Search, Filter, X, AlertTriangle, CheckCircle, XCircle, FileText } from 'lucide-react';
import { db } from '@/lib/firebase';
import { collection, query, orderBy, limit as firestoreLimit, getDocs, doc, updateDoc, Timestamp } from 'firebase/firestore';

interface Dispute {
  id: string;
  bookingId: string;
  customerId: string;
  customerName: string;
  technicianId: string;
  technicianName: string;
  reason: string;
  description?: string;
  status: 'open' | 'under_review' | 'resolved' | 'closed';
  resolution?: string;
  createdAt: any;
  resolvedAt?: any;
}

export default function DisputesPage() {
  const [disputes, setDisputes] = useState<Dispute[]>([]);
  const [filteredDisputes, setFilteredDisputes] = useState<Dispute[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedDispute, setSelectedDispute] = useState<Dispute | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    onConfirm: () => void;
    variant?: 'default' | 'danger';
  }>({ isOpen: false, title: '', message: '', onConfirm: () => {} });

  useEffect(() => {
    fetchDisputes();
  }, []);

  useEffect(() => {
    filterDisputes();
  }, [disputes, searchTerm, statusFilter]);

  const fetchDisputes = async () => {
    try {
      setLoading(true);
      const disputesQuery = query(
        collection(db, 'disputes'),
        orderBy('createdAt', 'desc'),
        firestoreLimit(100)
      );
      const snapshot = await getDocs(disputesQuery);
      const disputesData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as Dispute[];
      setDisputes(disputesData);
    } catch (error) {
      console.error('Error fetching disputes:', error);
    } finally {
      setLoading(false);
    }
  };

  const filterDisputes = () => {
    let filtered = [...disputes];

    if (statusFilter !== 'all') {
      filtered = filtered.filter(d => d.status === statusFilter);
    }

    if (searchTerm) {
      filtered = filtered.filter(d => 
        d.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.bookingId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.customerName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.technicianName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.reason?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredDisputes(filtered);
  };

  const handleViewDetails = (dispute: Dispute) => {
    setSelectedDispute(dispute);
    setShowDetailsModal(true);
  };

  const handleResolve = (dispute: Dispute) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Resolve Dispute',
      message: 'Are you sure you want to mark this dispute as resolved? This action will close the dispute.',
      onConfirm: async () => {
        try {
          await updateDoc(doc(db, 'disputes', dispute.id), {
            status: 'resolved',
            resolvedAt: Timestamp.now()
          });
          await fetchDisputes();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error resolving dispute:', error);
        }
      },
    });
  };

  const handleClose = (dispute: Dispute) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Close Dispute',
      message: 'Are you sure you want to close this dispute? This action cannot be undone.',
      variant: 'danger',
      onConfirm: async () => {
        try {
          await updateDoc(doc(db, 'disputes', dispute.id), {
            status: 'closed'
          });
          await fetchDisputes();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error closing dispute:', error);
        }
      },
    });
  };

  const handleUnderReview = (dispute: Dispute) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Mark Under Review',
      message: 'Are you sure you want to mark this dispute as under review?',
      onConfirm: async () => {
        try {
          await updateDoc(doc(db, 'disputes', dispute.id), {
            status: 'under_review'
          });
          await fetchDisputes();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error updating dispute:', error);
        }
      },
    });
  };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    if (timestamp instanceof Timestamp) {
      return timestamp.toDate().toLocaleDateString();
    }
    return 'N/A';
  };

  const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'info' | 'default' => {
    const statusMap: Record<string, 'success' | 'warning' | 'error' | 'info' | 'default'> = {
      'open': 'warning',
      'under_review': 'info',
      'resolved': 'success',
      'closed': 'default',
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
      label: 'Dispute ID',
      render: (item) => (
        <span className="text-sm font-mono text-[#6366F1]">
          {item.id.substring(0, 8)}
        </span>
      )
    },
    { 
      key: 'bookingId', 
      label: 'Booking ID',
      render: (item) => (
        <span className="text-sm text-[#9CA3AF]">
          {item.bookingId ? item.bookingId.substring(0, 8) : 'N/A'}
        </span>
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
      key: 'technicianName', 
      label: 'Technician',
      render: (item) => (
        <span className="text-sm text-[#E5E7EB]">{item.technicianName || 'N/A'}</span>
      )
    },
    { 
      key: 'reason', 
      label: 'Reason',
      render: (item) => (
        <span className="text-sm text-[#9CA3AF] truncate max-w-xs block">
          {item.reason || 'N/A'}
        </span>
      )
    },
    {
      key: 'status',
      label: 'Status',
      render: (item) => (
        <StatusBadge 
          status={formatStatus(item.status)} 
          variant={getStatusVariant(item.status)}
        />
      )
    },
    { 
      key: 'createdAt', 
      label: 'Created',
      render: (item) => (
        <span className="text-sm text-[#9CA3AF]">{formatDate(item.createdAt)}</span>
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
            className="p-2 text-[#9CA3AF] hover:text-[#E5E7EB] hover:bg-[#1F2937] rounded-lg transition-colors"
            title="View Details"
          >
            <FileText size={16} />
          </button>
          {item.status === 'open' && (
            <button
              onClick={() => handleUnderReview(item)}
              className="p-2 text-blue-400 hover:bg-blue-500/10 rounded-lg transition-colors"
              title="Mark Under Review"
            >
              <AlertTriangle size={16} />
            </button>
          )}
          {item.status === 'open' || item.status === 'under_review' ? (
            <button
              onClick={() => handleResolve(item)}
              className="p-2 text-green-400 hover:bg-green-500/10 rounded-lg transition-colors"
              title="Resolve Dispute"
            >
              <CheckCircle size={16} />
            </button>
          ) : null}
          {item.status !== 'closed' && item.status !== 'resolved' && (
            <button
              onClick={() => handleClose(item)}
              className="p-2 text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
              title="Close Dispute"
            >
              <XCircle size={16} />
            </button>
          )}
        </div>
      )
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Disputes"
        description="Manage disputes between customers and technicians"
      />

      {/* Filters */}
      <div className="admin-card p-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-[#6B7280]" size={18} />
            <input
              type="text"
              placeholder="Search by ID, customer, technician..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input-field w-full pl-10 pr-4"
            />
            {searchTerm && (
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-[#6B7280] hover:text-[#E5E7EB]"
              >
                <X size={18} />
              </button>
            )}
          </div>

          {/* Status Filter */}
          <div className="relative">
            <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 text-[#6B7280]" size={18} />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="input-field w-full pl-10 pr-4 appearance-none"
            >
              <option value="all">All Status</option>
              <option value="open">Open</option>
              <option value="under_review">Under Review</option>
              <option value="resolved">Resolved</option>
              <option value="closed">Closed</option>
            </select>
          </div>

          {/* Results Count */}
          <div className="flex items-center justify-end">
            <span className="text-sm text-[#9CA3AF]">
              Showing {filteredDisputes.length} of {disputes.length} disputes
            </span>
          </div>
        </div>
      </div>

      {/* Disputes Table */}
      <div className="admin-card p-6">
        <Table
          columns={columns}
          data={filteredDisputes}
          loading={loading}
          emptyMessage="No disputes found"
        />
      </div>

      {/* Dispute Details Modal */}
      {showDetailsModal && selectedDispute && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="sticky top-0 bg-[#111827] border-b border-[#1F2937] p-6 flex items-center justify-between">
              <h2 className="text-xl font-bold text-[#E5E7EB]">Dispute Details</h2>
              <button
                onClick={() => setShowDetailsModal(false)}
                className="text-[#6B7280] hover:text-[#E5E7EB]"
              >
                <X size={24} />
              </button>
            </div>
            <div className="p-6 space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-[#6B7280]">Dispute ID</p>
                  <p className="text-sm font-medium text-[#E5E7EB]">{selectedDispute.id}</p>
                </div>
                <div>
                  <p className="text-sm text-[#6B7280]">Status</p>
                  <StatusBadge 
                    status={formatStatus(selectedDispute.status)} 
                    variant={getStatusVariant(selectedDispute.status)}
                  />
                </div>
                <div>
                  <p className="text-sm text-[#6B7280]">Booking ID</p>
                  <p className="text-sm font-medium text-[#6366F1]">
                    {selectedDispute.bookingId ? selectedDispute.bookingId.substring(0, 8) : 'N/A'}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-[#6B7280]">Created</p>
                  <p className="text-sm font-medium text-[#E5E7EB]">{formatDate(selectedDispute.createdAt)}</p>
                </div>
                <div>
                  <p className="text-sm text-[#6B7280]">Customer</p>
                  <p className="text-sm font-medium text-[#E5E7EB]">{selectedDispute.customerName || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-sm text-[#6B7280]">Technician</p>
                  <p className="text-sm font-medium text-[#E5E7EB]">{selectedDispute.technicianName || 'N/A'}</p>
                </div>
              </div>
              <div>
                <p className="text-sm text-[#6B7280] mb-2">Reason</p>
                <p className="text-sm text-[#E5E7EB] bg-[#1F2937] p-4 rounded-lg">
                  {selectedDispute.reason || 'N/A'}
                </p>
              </div>
              {selectedDispute.description && (
                <div>
                  <p className="text-sm text-[#6B7280] mb-2">Description</p>
                  <p className="text-sm text-[#E5E7EB] bg-[#1F2937] p-4 rounded-lg">
                    {selectedDispute.description}
                  </p>
                </div>
              )}
              {selectedDispute.resolution && (
                <div>
                  <p className="text-sm text-[#6B7280] mb-2">Resolution</p>
                  <p className="text-sm text-[#E5E7EB] bg-green-500/10 p-4 rounded-lg border border-green-500/30">
                    {selectedDispute.resolution}
                  </p>
                </div>
              )}
              {selectedDispute.resolvedAt && (
                <div>
                  <p className="text-sm text-[#6B7280]">Resolved At</p>
                  <p className="text-sm font-medium text-[#E5E7EB]">{formatDate(selectedDispute.resolvedAt)}</p>
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
      />
    </div>
  );
}
