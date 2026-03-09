'use client';

import { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, Timestamp } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '@/lib/firebase';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import Modal from '@/components/ui/Modal';
import PageHeader from '@/components/ui/PageHeader';
import LoadingState from '@/components/ui/LoadingState';
import EmptyState from '@/components/ui/EmptyState';
import ErrorState from '@/components/ui/ErrorState';
import ConfirmDialog from '@/components/ui/ConfirmDialog';
import { ClipboardList, Search, Filter, Eye, User, Phone, MapPin, Calendar, Clock, DollarSign, FileText } from 'lucide-react';

interface BookingApproval {
  id: string;
  serviceName: string;
  serviceCategory?: string;
  subService?: string;
  customerName: string;
  customerPhone?: string;
  customerAddress?: string;
  district: string;
  technicianName?: string;
  technicianId?: string;
  technicianPhone?: string;
  technicianExperience?: number;
  price: number;
  preferredDate: Timestamp;
  preferredTime?: string;
  customerNotes?: string;
  status: string;
  createdAt: Timestamp;
}

export default function BookingApprovalsPage() {
  const [bookings, setBookings] = useState<BookingApproval[]>([]);
  const [filteredBookings, setFilteredBookings] = useState<BookingApproval[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedBooking, setSelectedBooking] = useState<BookingApproval | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showApproveDialog, setShowApproveDialog] = useState(false);
  const [showRejectDialog, setShowRejectDialog] = useState(false);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedDistrict, setSelectedDistrict] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [rejectionReason, setRejectionReason] = useState('');

  const itemsPerPage = 20;
  const districts = [...new Set(bookings.map(booking => booking.district))];

  useEffect(() => {
    const q = query(
      collection(db, 'bookings'),
      where('status', '==', 'PENDING_ADMIN_APPROVAL')
    );

    const unsubscribe = onSnapshot(q, 
      (snapshot) => {
        const bookingData = snapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        })) as BookingApproval[];
        
        setBookings(bookingData.sort((a, b) => 
          b.createdAt.toMillis() - a.createdAt.toMillis()
        ));
        setLoading(false);
        setError(null);
      },
      (err) => {
        console.error('Error fetching booking approvals:', err);
        setError('Failed to load booking approvals');
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  useEffect(() => {
    let filtered = bookings;

    if (searchTerm) {
      filtered = filtered.filter(booking =>
        booking.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        booking.serviceName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        booking.technicianName?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (selectedDistrict) {
      filtered = filtered.filter(booking => booking.district === selectedDistrict);
    }

    setFilteredBookings(filtered);
    setCurrentPage(1);
  }, [bookings, searchTerm, selectedDistrict]);

  const paginatedBookings = filteredBookings.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const totalPages = Math.ceil(filteredBookings.length / itemsPerPage);

  const handleApprove = async (bookingId: string) => {
    setProcessingId(bookingId);
    try {
      const approveBooking = httpsCallable(functions, 'approveBooking');
      await approveBooking({ bookingId });
      
      setShowApproveDialog(false);
      setSelectedBooking(null);
      // Show success toast
    } catch (error) {
      console.error('Error approving booking:', error);
      alert('Failed to approve booking');
    } finally {
      setProcessingId(null);
    }
  };

  const handleReject = async (bookingId: string) => {
    setProcessingId(bookingId);
    try {
      const rejectBooking = httpsCallable(functions, 'rejectBooking');
      await rejectBooking({ 
        bookingId,
        reason: rejectionReason.trim() || undefined
      });
      
      setShowRejectDialog(false);
      setSelectedBooking(null);
      setRejectionReason('');
      // Show success toast
    } catch (error) {
      console.error('Error rejecting booking:', error);
      alert('Failed to reject booking');
    } finally {
      setProcessingId(null);
    }
  };

  const openDetailsModal = (booking: BookingApproval) => {
    setSelectedBooking(booking);
    setShowDetailsModal(true);
  };

  const openApproveDialog = (booking: BookingApproval) => {
    setSelectedBooking(booking);
    setShowApproveDialog(true);
  };

  const openRejectDialog = (booking: BookingApproval) => {
    setSelectedBooking(booking);
    setShowRejectDialog(true);
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'PENDING_ADMIN_APPROVAL':
        return <Badge variant="warning" className="text-xs">Pending Approval</Badge>;
      case 'ADMIN_APPROVED':
        return <Badge variant="success" className="text-xs">Approved</Badge>;
      case 'CANCELLED':
        return <Badge variant="destructive" className="text-xs">Rejected</Badge>;
      default:
        return <Badge variant="secondary" className="text-xs">{status}</Badge>;
    }
  };

  if (loading) return <LoadingState />;
  if (error) return <ErrorState message={error} />;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Booking Approvals"
        description="Review and approve booking requests submitted by customers"
      />

      {/* Search and Filters */}
      <Card className="p-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-[#6B7280] w-4 h-4" />
            <input
              type="text"
              placeholder="Search by customer, service, or technician..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-[#1F2937] border border-[#374151] rounded-lg text-[#E5E7EB] placeholder-[#6B7280] focus:outline-none focus:ring-2 focus:ring-[#6366F1] focus:border-transparent"
            />
          </div>
          <div className="relative">
            <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 text-[#6B7280] w-4 h-4" />
            <select
              value={selectedDistrict}
              onChange={(e) => setSelectedDistrict(e.target.value)}
              className="pl-10 pr-8 py-2 bg-[#1F2937] border border-[#374151] rounded-lg text-[#E5E7EB] focus:outline-none focus:ring-2 focus:ring-[#6366F1] focus:border-transparent"
            >
              <option value="">All Districts</option>
              {districts.map(district => (
                <option key={district} value={district}>{district}</option>
              ))}
            </select>
          </div>
        </div>
      </Card>

      {filteredBookings.length === 0 ? (
        <EmptyState
          icon={ClipboardList}
          title="No Bookings Pending Admin Approval"
          description="All booking requests have been reviewed"
        />
      ) : (
        <>
          {/* Bookings Table */}
          <Card className="overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-[#1F2937] border-b border-[#374151]">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Booking ID</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Service</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Customer</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Technician</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Location</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Price</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Date</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#374151]">
                  {paginatedBookings.map((booking) => (
                    <tr key={booking.id} className="hover:bg-[#1F2937] transition-colors">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-mono text-[#E5E7EB]">
                          {booking.id.substring(0, 8)}...
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-[#E5E7EB]">{booking.serviceName}</div>
                        {booking.serviceCategory && (
                          <div className="text-sm text-[#9CA3AF]">{booking.serviceCategory}</div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-[#E5E7EB]">{booking.customerName}</div>
                        {booking.customerPhone && (
                          <div className="text-sm text-[#9CA3AF]">{booking.customerPhone}</div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-[#E5E7EB]">{booking.technicianName || 'Not assigned'}</div>
                        {booking.technicianPhone && (
                          <div className="text-sm text-[#9CA3AF]">{booking.technicianPhone}</div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-[#E5E7EB]">{booking.district}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-[#E5E7EB]">₹{booking.price}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-[#E5E7EB]">
                          {booking.preferredDate.toDate().toLocaleDateString()}
                        </div>
                        {booking.preferredTime && (
                          <div className="text-sm text-[#9CA3AF]">{booking.preferredTime}</div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {getStatusBadge(booking.status)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => openDetailsModal(booking)}
                        >
                          <Eye className="w-4 h-4 mr-1" />
                          View
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between">
              <div className="text-sm text-[#9CA3AF]">
                Showing {((currentPage - 1) * itemsPerPage) + 1} to {Math.min(currentPage * itemsPerPage, filteredBookings.length)} of {filteredBookings.length} bookings
              </div>
              <div className="flex space-x-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                  disabled={currentPage === 1}
                >
                  Previous
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                  disabled={currentPage === totalPages}
                >
                  Next
                </Button>
              </div>
            </div>
          )}
        </>
      )}

      {/* Booking Details Modal */}
      {selectedBooking && (
        <Modal
          isOpen={showDetailsModal}
          onClose={() => setShowDetailsModal(false)}
          title="Booking Details"
          size="xl"
        >
          <div className="max-h-[80vh] overflow-y-auto">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Left Column */}
              <div className="space-y-6">
                {/* Booking Information */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <ClipboardList className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Booking Information</h3>
                  </div>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Booking ID</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-mono">{selectedBooking.id}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Service Name</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedBooking.serviceName}</p>
                    </div>
                    {selectedBooking.serviceCategory && (
                      <div>
                        <label className="block text-sm font-medium text-[#9CA3AF]">Service Category</label>
                        <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedBooking.serviceCategory}</p>
                      </div>
                    )}
                    {selectedBooking.subService && (
                      <div>
                        <label className="block text-sm font-medium text-[#9CA3AF]">Sub-Service</label>
                        <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedBooking.subService}</p>
                      </div>
                    )}
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Price</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">₹{selectedBooking.price}</p>
                    </div>
                  </div>
                </div>

                {/* Customer Information */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <User className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Customer Information</h3>
                  </div>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Name</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedBooking.customerName}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Phone</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedBooking.customerPhone || 'Not provided'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Address</label>
                      <p className="mt-1 text-sm text-[#E5E7EB]">{selectedBooking.customerAddress || 'Not provided'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">District</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedBooking.district}</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Right Column */}
              <div className="space-y-6">
                {/* Technician Information */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <User className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Technician Information</h3>
                  </div>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Name</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedBooking.technicianName || 'Not assigned'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Technician ID</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-mono">{selectedBooking.technicianId || 'Not assigned'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Phone</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedBooking.technicianPhone || 'Not provided'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Experience</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">
                        {selectedBooking.technicianExperience ? `${selectedBooking.technicianExperience} years` : 'Not provided'}
                      </p>
                    </div>
                  </div>
                </div>

                {/* Schedule */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <Calendar className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Schedule</h3>
                  </div>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Preferred Date</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">
                        {selectedBooking.preferredDate.toDate().toLocaleDateString()}
                      </p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Preferred Time</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedBooking.preferredTime || 'Not specified'}</p>
                    </div>
                  </div>
                </div>

                {/* Additional Notes */}
                {selectedBooking.customerNotes && (
                  <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                    <div className="flex items-center gap-2 mb-4">
                      <FileText className="w-5 h-5 text-[#6366F1]" />
                      <h3 className="text-lg font-semibold text-[#E5E7EB]">Additional Notes</h3>
                    </div>
                    <p className="text-sm text-[#E5E7EB]">{selectedBooking.customerNotes}</p>
                  </div>
                )}
              </div>
            </div>

            {/* Sticky Action Footer */}
            <div className="sticky bottom-0 bg-[#111827] border-t border-[#374151] p-6 mt-6 -mx-6 -mb-6">
              <div className="flex items-center justify-between">
                <div>
                  <span className="text-sm text-[#9CA3AF]">Booking ID:</span>
                  <span className="ml-2 text-sm text-[#E5E7EB] font-mono">{selectedBooking.id}</span>
                </div>
                <div className="flex space-x-3">
                  <Button
                    variant="outline"
                    onClick={() => {
                      setShowDetailsModal(false);
                      openRejectDialog(selectedBooking);
                    }}
                    className="text-red-400 border-red-400 hover:bg-red-400/10"
                    disabled={processingId === selectedBooking.id}
                  >
                    Reject Booking
                  </Button>
                  <Button
                    onClick={() => {
                      setShowDetailsModal(false);
                      openApproveDialog(selectedBooking);
                    }}
                    className="bg-green-600 hover:bg-green-700 text-white"
                    disabled={processingId === selectedBooking.id}
                  >
                    Approve Booking
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </Modal>
      )}

      {/* Approve Confirmation Dialog */}
      <ConfirmDialog
        isOpen={showApproveDialog}
        onCancel={() => setShowApproveDialog(false)}
        onConfirm={() => selectedBooking && handleApprove(selectedBooking.id)}
        title="Approve Booking"
        message={`Are you sure you want to approve this booking for "${selectedBooking?.serviceName}"? The booking will proceed to technician acceptance.`}
        confirmText="Approve"
      />

      {/* Reject Confirmation Dialog */}
      <ConfirmDialog
        isOpen={showRejectDialog}
        onCancel={() => {
          setShowRejectDialog(false);
          setRejectionReason('');
        }}
        onConfirm={(inputValue) => {
          if (inputValue) setRejectionReason(inputValue);
          selectedBooking && handleReject(selectedBooking.id);
        }}
        title="Reject Booking"
        message={`Are you sure you want to reject this booking for "${selectedBooking?.serviceName}"?`}
        confirmText="Reject"
        variant="danger"
        requireInput={true}
        inputLabel="Rejection Reason (Optional)"
        inputPlaceholder="Provide a reason for rejection..."
      />
    </div>
  );
}