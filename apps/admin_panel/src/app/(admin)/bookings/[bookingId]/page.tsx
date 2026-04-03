'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { 
  subscribeToBooking, 
  AdminBooking, 
  approveBookingAction, 
  rejectBookingAction,
  markBookingActive,
  markBookingCompleted,
  updatePaymentStatus,
  getCustomerBookingCount
} from '@/lib/services/adminBookingService';
import { 
  BOOKING_STATUS, 
  normalizeBookingStatus,
  canApproveBooking,
  canRejectBooking,
  canMarkActive,
  canMarkCompleted,
  BOOKING_STATUS_VARIANTS
} from '@/lib/bookingStatus';
import { StatusBadge, ConfirmDialog } from '@/components/ui';
import { 
  ArrowLeft, CheckCircle, XCircle, User, Wrench, Calendar, Clock, 
  MapPin, Phone, Mail, Star, Package, CreditCard, RefreshCw, 
  IndianRupee, MessageSquare, Building, AlertCircle, ChevronRight
} from 'lucide-react';
import { Timestamp } from 'firebase/firestore';

const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'info' | 'default' => {
  const normalized = normalizeBookingStatus(status);
  return BOOKING_STATUS_VARIANTS[normalized] || 'default';
};

const formatStatus = (status: string) => {
  const normalized = normalizeBookingStatus(status);
  return normalized?.replace(/_/g, ' ') || 'Unknown';
};

const formatDate = (timestamp: any) => {
  if (!timestamp) return '-';
  try {
    if (timestamp instanceof Timestamp) return timestamp.toDate().toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
    if (timestamp.toDate) return timestamp.toDate().toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
    return '-';
  } catch { return '-'; }
};

const formatDateTime = (timestamp: any) => {
  if (!timestamp) return '-';
  try {
    let date: Date;
    if (timestamp instanceof Timestamp) date = timestamp.toDate();
    else if (timestamp.toDate) date = timestamp.toDate();
    else return '-';
    return date.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) + ' ' + 
           date.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });
  } catch { return '-'; }
};

export function generateStaticParams() { return []; }

export default function BookingDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const bookingId = params.bookingId as string;
  
  const [booking, setBooking] = useState<AdminBooking | null>(null);
  const [loading, setLoading] = useState(true);
  const [customerBookingCount, setCustomerBookingCount] = useState(0);
  const [processing, setProcessing] = useState(false);
  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    onConfirm: () => void;
    variant?: 'default' | 'danger';
  }>({ isOpen: false, title: '', message: '', onConfirm: () => {} });

  useEffect(() => {
    if (!bookingId) return;
    const unsubscribe = subscribeToBooking(bookingId, (bookingData) => {
      setBooking(bookingData);
      setLoading(false);
    });
    return () => unsubscribe();
  }, [bookingId]);

  useEffect(() => {
    if (booking?.customerId) {
      getCustomerBookingCount(booking.customerId).then(setCustomerBookingCount);
    }
  }, [booking?.customerId]);

  const getTimeline = (b: AdminBooking) => {
    const normalizedStatus = normalizeBookingStatus(b.status);
    return [
      { label: 'Booking Created', date: b.createdAt, completed: true },
      { label: 'Admin Approved', date: b.adminApprovedAt, completed: ([BOOKING_STATUS.APPROVED_BY_ADMIN, BOOKING_STATUS.TECHNICIAN_ACCEPTED, BOOKING_STATUS.SERVICE_IN_PROGRESS, BOOKING_STATUS.SERVICE_COMPLETED] as any[]).includes(normalizedStatus) },
      { label: 'Technician Accepted', date: b.technicianAcceptedAt, completed: ([BOOKING_STATUS.TECHNICIAN_ACCEPTED, BOOKING_STATUS.SERVICE_IN_PROGRESS, BOOKING_STATUS.SERVICE_COMPLETED] as any[]).includes(normalizedStatus) },
      { label: 'Service Started', date: b.serviceStartedAt, completed: ([BOOKING_STATUS.SERVICE_IN_PROGRESS, BOOKING_STATUS.SERVICE_COMPLETED] as any[]).includes(normalizedStatus) },
      { label: 'Service Completed', date: b.completedAt, completed: normalizedStatus === BOOKING_STATUS.SERVICE_COMPLETED },
    ];
  };

  const handleApprove = () => {
    setConfirmDialog({
      isOpen: true,
      title: 'Approve Booking',
      message: 'This will notify the technician. Continue?',
      onConfirm: async () => {
        setProcessing(true);
        try {
          await approveBookingAction(bookingId);
          setConfirmDialog(prev => ({ ...prev, isOpen: false }));
        } catch (error: any) {
          alert(`Failed: ${error.message}`);
        } finally {
          setProcessing(false);
        }
      },
    });
  };

  const handleReject = () => {
    setConfirmDialog({
      isOpen: true,
      title: 'Reject Booking',
      message: 'This will cancel the booking. Continue?',
      variant: 'danger',
      onConfirm: async () => {
        setProcessing(true);
        try {
          await rejectBookingAction(bookingId, 'Rejected by admin');
          setConfirmDialog(prev => ({ ...prev, isOpen: false }));
        } catch (error: any) {
          alert(`Failed: ${error.message}`);
        } finally {
          setProcessing(false);
        }
      },
    });
  };

  const handleMarkActive = () => {
    setConfirmDialog({
      isOpen: true,
      title: 'Start Service',
      message: 'Mark this booking as in progress?',
      onConfirm: async () => {
        setProcessing(true);
        try {
          await markBookingActive(bookingId);
          setConfirmDialog(prev => ({ ...prev, isOpen: false }));
        } catch (error: any) {
          alert(`Failed: ${error.message}`);
        } finally {
          setProcessing(false);
        }
      },
    });
  };

  const handleMarkCompleted = () => {
    setConfirmDialog({
      isOpen: true,
      title: 'Complete Service',
      message: 'Mark the service as completed?',
      onConfirm: async () => {
        setProcessing(true);
        try {
          await markBookingCompleted(bookingId);
          setConfirmDialog(prev => ({ ...prev, isOpen: false }));
        } catch (error: any) {
          alert(`Failed: ${error.message}`);
        } finally {
          setProcessing(false);
        }
      },
    });
  };

  const handleUpdatePayment = (status: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Update Payment',
      message: `Update payment status to ${status}?`,
      onConfirm: async () => {
        setProcessing(true);
        try {
          await updatePaymentStatus(bookingId, status);
          setConfirmDialog(prev => ({ ...prev, isOpen: false }));
        } catch (error: any) {
          alert(`Failed: ${error.message}`);
        } finally {
          setProcessing(false);
        }
      },
    });
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[#0B1120] p-4 sm:p-6">
        <div className="max-w-7xl mx-auto">
          <div className="animate-pulse space-y-4">
            <div className="h-8 bg-[#1F2937] rounded w-64"></div>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
              {[1, 2, 3].map(i => (
                <div key={i} className="h-48 bg-[#1F2937] rounded-lg"></div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!booking) {
    return (
      <div className="min-h-screen bg-[#0B1120] p-4 sm:p-6 flex items-center justify-center">
        <div className="text-center">
          <AlertCircle className="w-10 h-10 text-red-500 mx-auto mb-3" />
          <h2 className="text-lg font-semibold text-[#E5E7EB] mb-2">Booking Not Found</h2>
          <button onClick={() => router.push('/bookings')} className="px-4 py-2 bg-[#6366F1] text-white rounded-lg text-sm hover:bg-[#4F46E5]">
            Back to Bookings
          </button>
        </div>
      </div>
    );
  }

  const normalizedStatus = normalizeBookingStatus(booking.status);

  return (
    <div className="min-h-screen bg-[#0B1120]">
      {/* Header */}
      <div className="bg-[#111827] border-b border-[#1F2937] sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-3">
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-3 min-w-0">
              <button onClick={() => router.push('/bookings')} className="p-1.5 hover:bg-[#1F2937] rounded-lg text-[#9CA3AF] flex-shrink-0">
                <ArrowLeft size={18} />
              </button>
              <div className="min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-xs text-[#6B7280] font-mono">{booking.id.substring(0, 10)}</span>
                  <StatusBadge status={formatStatus(booking.status)} variant={getStatusVariant(booking.status)} />
                </div>
                <p className="text-sm text-[#6B7280]">{formatDate(booking.bookingDate)} • {booking.timeSlot || 'Not set'}</p>
              </div>
            </div>
            
            {/* Action Buttons */}
            <div className="flex items-center gap-2 flex-wrap justify-end">
              {canApproveBooking(booking.status) && (
                <>
                  <button onClick={handleApprove} disabled={processing} className="px-3 py-1.5 bg-green-600 hover:bg-green-700 disabled:opacity-50 text-white rounded-lg text-xs sm:text-sm font-medium flex items-center gap-1.5 whitespace-nowrap">
                    <CheckCircle size={14} /> Approve
                  </button>
                  <button onClick={handleReject} disabled={processing} className="px-3 py-1.5 bg-red-600 hover:bg-red-700 disabled:opacity-50 text-white rounded-lg text-xs sm:text-sm font-medium flex items-center gap-1.5 whitespace-nowrap">
                    <XCircle size={14} /> Reject
                  </button>
                </>
              )}
              {canMarkActive(booking.status) && (
                <button onClick={handleMarkActive} disabled={processing} className="px-3 py-1.5 bg-[#6366F1] hover:bg-[#4F46E5] disabled:opacity-50 text-white rounded-lg text-xs sm:text-sm font-medium flex items-center gap-1.5 whitespace-nowrap">
                  <RefreshCw size={14} /> Start
                </button>
              )}
              {canMarkCompleted(booking.status) && (
                <button onClick={handleMarkCompleted} disabled={processing} className="px-3 py-1.5 bg-green-600 hover:bg-green-700 disabled:opacity-50 text-white rounded-lg text-xs sm:text-sm font-medium flex items-center gap-1.5 whitespace-nowrap">
                  <CheckCircle size={14} /> Complete
                </button>
              )}
              {booking.paymentStatus === 'PENDING' && (
                <button onClick={() => handleUpdatePayment('PAID')} disabled={processing} className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white rounded-lg text-xs sm:text-sm font-medium flex items-center gap-1.5 whitespace-nowrap">
                  <CreditCard size={14} /> Mark Paid
                </button>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
        {/* Main Grid Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* LEFT SIDE - Main Content (span-2) */}
          <div className="lg:col-span-2 space-y-6">
            {/* Service Details Card */}
            <div className="admin-card p-6">
              <h3 className="text-lg font-semibold text-[#E5E7EB] mb-4 flex items-center gap-2">
                <Package size={18} className="text-[#6366F1]" /> Service Details
              </h3>
              <div className="flex gap-4">
                {booking.serviceImage && (
                  <img src={booking.serviceImage} alt={booking.serviceName} className="w-20 h-20 object-cover rounded-lg flex-shrink-0" />
                )}
                <div className="flex-1 min-w-0">
                  <h4 className="font-medium text-[#E5E7EB]">{booking.serviceName}</h4>
                  <p className="text-sm text-[#9CA3AF]">{booking.categoryName}</p>
                  <div className="mt-3 flex flex-wrap items-center gap-3 text-sm">
                    <span className="font-semibold text-[#E5E7EB]">₹{booking.servicePrice}</span>
                    {booking.offerPrice && booking.offerPrice < booking.servicePrice && (
                      <span className="text-green-400">₹{booking.offerPrice} (Offer)</span>
                    )}
                    <span className="text-[#9CA3AF] flex items-center gap-1"><Clock size={12} />{booking.timeSlot}</span>
                  </div>
                </div>
              </div>
              {booking.notes && (
                <div className="mt-4 pt-4 border-t border-[#1F2937]">
                  <p className="text-sm text-[#9CA3AF] flex items-start gap-2"><MessageSquare size={14} className="mt-0.5 flex-shrink-0" />{booking.notes}</p>
                </div>
              )}
            </div>

            {/* Timeline Card */}
            <div className="admin-card p-6">
              <h3 className="text-lg font-semibold text-[#E5E7EB] mb-4 flex items-center gap-2">
                <Clock size={18} className="text-[#6366F1]" /> Booking Timeline
              </h3>
              <div className="space-y-3">
                {getTimeline(booking).map((step, idx) => (
                  <div key={idx} className="flex items-center gap-3">
                    <div className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${step.completed ? 'bg-green-600' : 'bg-[#374151]'}`}>
                      {step.completed ? <CheckCircle size={14} className="text-white" /> : <div className="w-2 h-2 rounded-full bg-[#6B7280]" />}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className={`text-sm ${step.completed ? 'text-[#E5E7EB] font-medium' : 'text-[#6B7280]'}`}>{step.label}</p>
                    </div>
                    <p className="text-xs text-[#6B7280] flex-shrink-0">{formatDateTime(step.date)}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Address Card */}
            {booking.customerAddress && (
              <div className="admin-card p-6">
                <h3 className="text-lg font-semibold text-[#E5E7EB] mb-4 flex items-center gap-2">
                  <MapPin size={18} className="text-[#6366F1]" /> Service Address
                </h3>
                <div className="space-y-2">
                  <p className="text-sm text-[#E5E7EB]">
                    {booking.customerAddress || 'Address not available'}
                  </p>
                  {booking.city && <p className="text-sm text-[#9CA3AF] flex items-center gap-2"><Building size={14} />{booking.city}</p>}
                </div>
              </div>
            )}

            {/* Rejection Reason */}
            {booking.rejectionReason && (
              <div className="admin-card p-6 border-l-4 border-red-600 bg-red-600/10">
                <h3 className="text-lg font-semibold text-red-400 mb-2">Rejection Reason</h3>
                <p className="text-sm text-red-300">{booking.rejectionReason}</p>
              </div>
            )}
          </div>

          {/* RIGHT SIDE - Info Cards */}
          <div className="space-y-6">
            {/* Customer Card */}
            <div className="admin-card p-6">
              <h3 className="text-lg font-semibold text-[#E5E7EB] mb-4 flex items-center gap-2">
                <User size={18} className="text-[#6366F1]" /> Customer
              </h3>
              <div className="space-y-3">
                <div>
                  <p className="text-xs text-[#6B7280] mb-1">Name</p>
                  <p className="font-medium text-[#E5E7EB]">{booking.customerName}</p>
                </div>
                <div>
                  <p className="text-xs text-[#6B7280] mb-1">Phone</p>
                  <p className="text-sm text-[#E5E7EB] flex items-center gap-2"><Phone size={14} />{booking.customerPhone}</p>
                </div>
                {booking.customerEmail && (
                  <div>
                    <p className="text-xs text-[#6B7280] mb-1">Email</p>
                    <p className="text-sm text-[#E5E7EB] flex items-center gap-2"><Mail size={14} />{booking.customerEmail}</p>
                  </div>
                )}
                <div className="pt-3 border-t border-[#1F2937]">
                  <p className="text-xs text-[#6B7280]">{customerBookingCount} previous booking(s)</p>
                </div>
              </div>
            </div>

            {/* Technician Card */}
            <div className="admin-card p-6">
              <h3 className="text-lg font-semibold text-[#E5E7EB] mb-4 flex items-center gap-2">
                <Wrench size={18} className="text-[#6366F1]" /> Technician
              </h3>
              {booking.technicianId ? (
                <div className="space-y-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-[#1F2937] flex items-center justify-center text-[#9CA3AF] font-medium text-sm overflow-hidden flex-shrink-0">
                      {booking.technicianPhoto ? (
                        <img src={booking.technicianPhoto} alt="" className="w-full h-full object-cover" />
                      ) : (
                        <span>{booking.technicianName?.charAt(0).toUpperCase()}</span>
                      )}
                    </div>
                    <div className="min-w-0">
                      <p className="font-medium text-[#E5E7EB] text-sm">{booking.technicianName}</p>
                      <p className="text-xs text-[#6B7280] flex items-center gap-1"><Star size={10} className="fill-yellow-400 text-yellow-400" />{booking.technicianRating?.toFixed(1) || '-'}</p>
                    </div>
                  </div>
                  {booking.technicianPhone && <p className="text-xs text-[#9CA3AF] flex items-center gap-2"><Phone size={12} />{booking.technicianPhone}</p>}
                  {booking.technicianTotalJobs !== undefined && <p className="text-xs text-[#9CA3AF]">{booking.technicianTotalJobs} jobs completed</p>}
                </div>
              ) : (
                <div className="text-center py-4">
                  <p className="text-sm text-[#6B7280] mb-3">No technician assigned</p>
                  <button className="text-sm text-[#6366F1] hover:text-[#4F46E5] font-medium">Assign Technician</button>
                </div>
              )}
            </div>

            {/* Payment Card */}
            <div className="admin-card p-6">
              <h3 className="text-lg font-semibold text-[#E5E7EB] mb-4 flex items-center gap-2">
                <CreditCard size={18} className="text-[#6366F1]" /> Payment
              </h3>
              <div className="space-y-3">
                <div>
                  <p className="text-xs text-[#6B7280] mb-1">Status</p>
                  <StatusBadge status={booking.paymentStatus || 'PENDING'} variant={booking.paymentStatus === 'PAID' ? 'success' : 'warning'} />
                </div>
                {booking.paymentMethod && (
                  <div>
                    <p className="text-xs text-[#6B7280] mb-1">Method</p>
                    <p className="text-sm text-[#E5E7EB]">{booking.paymentMethod}</p>
                  </div>
                )}
                {booking.transactionId && (
                  <div>
                    <p className="text-xs text-[#6B7280] mb-1">Transaction ID</p>
                    <p className="text-xs text-[#9CA3AF] font-mono break-all">{booking.transactionId.substring(0, 12)}...</p>
                  </div>
                )}
                <div className="pt-3 border-t border-[#1F2937]">
                  <p className="text-sm font-semibold text-[#E5E7EB]">₹{booking.servicePrice}</p>
                </div>
              </div>
            </div>

            {/* Booking Metadata Card */}
            <div className="admin-card p-6">
              <h3 className="text-lg font-semibold text-[#E5E7EB] mb-4">Details</h3>
              <div className="space-y-3 text-sm">
                <div className="flex justify-between">
                  <span className="text-[#6B7280]">Booking ID</span>
                  <span className="text-[#E5E7EB] font-mono">{booking.id.substring(0, 12)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-[#6B7280]">Created</span>
                  <span className="text-[#E5E7EB]">{formatDateTime(booking.createdAt)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-[#6B7280]">Service</span>
                  <span className="text-[#E5E7EB]">{booking.serviceName}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
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
