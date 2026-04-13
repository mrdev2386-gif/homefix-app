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
  getCustomerBookingCount,
  fetchAllTechnicians,
} from '@/lib/services/adminBookingService';
import {
  BOOKING_STATUS,
  normalizeBookingStatus,
  canApproveBooking,
  canRejectBooking,
  canMarkActive,
  canMarkCompleted,
  BOOKING_STATUS_VARIANTS,
} from '@/lib/bookingStatus';
import { StatusBadge, ConfirmDialog } from '@/components/ui';
import {
  ArrowLeft, CheckCircle, XCircle, RefreshCw, CreditCard,
  Phone, Mail, Star, MapPin, Building, AlertCircle, X, UserCog,
} from 'lucide-react';
import { Timestamp } from 'firebase/firestore';

const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'info' | 'default' => {
  const normalized = normalizeBookingStatus(status);
  return BOOKING_STATUS_VARIANTS[normalized] || 'default';
};

const formatStatus = (status: string) =>
  normalizeBookingStatus(status)?.replace(/_/g, ' ') || 'Unknown';

const fmt = (ts: any, time = false) => {
  if (!ts) return '—';
  try {
    const d: Date = ts instanceof Timestamp ? ts.toDate() : ts.toDate?.() ?? null;
    if (!d) return '—';
    const date = d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
    if (!time) return date;
    return `${date}, ${d.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}`;
  } catch { return '—'; }
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
  const [showChangeTechModal, setShowChangeTechModal] = useState(false);
  const [technicians, setTechnicians] = useState<{ id: string; name: string; phone: string; rating: number; completedJobs: number }[]>([]);
  const [selectedTech, setSelectedTech] = useState<{ id: string; name: string; phone: string; rating: number; completedJobs: number } | null>(null);
  const [techLoading, setTechLoading] = useState(false);
  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean; title: string; message: string; onConfirm: () => void; variant?: 'default' | 'danger';
  }>({ isOpen: false, title: '', message: '', onConfirm: () => {} });

  useEffect(() => {
    if (!bookingId) return;
    return subscribeToBooking(bookingId, (data) => { setBooking(data); setLoading(false); });
  }, [bookingId]);

  useEffect(() => {
    if (booking?.customerId) getCustomerBookingCount(booking.customerId).then(setCustomerBookingCount);
  }, [booking?.customerId]);

  const withConfirm = (title: string, message: string, action: () => Promise<any>, variant?: 'danger') => {
    setConfirmDialog({
      isOpen: true, title, message, variant,
      onConfirm: async () => {
        setProcessing(true);
        try {
          await action();
          setConfirmDialog(p => ({ ...p, isOpen: false }));
        } catch (e: any) {
          alert(`Failed: ${e.message}`);
        } finally { setProcessing(false); }
      },
    });
  };

  const getTimeline = (b: AdminBooking) => {
    const s = normalizeBookingStatus(b.status);
    const after = (...statuses: string[]) => (statuses as any[]).includes(s);
    return [
      { label: 'Booking Created',      date: b.createdAt,            done: true },
      { label: 'Admin Approved',        date: b.adminApprovedAt,      done: after(BOOKING_STATUS.APPROVED_BY_ADMIN, BOOKING_STATUS.TECHNICIAN_ACCEPTED, BOOKING_STATUS.SERVICE_IN_PROGRESS, BOOKING_STATUS.SERVICE_COMPLETED) },
      { label: 'Technician Accepted',   date: b.technicianAcceptedAt, done: after(BOOKING_STATUS.TECHNICIAN_ACCEPTED, BOOKING_STATUS.SERVICE_IN_PROGRESS, BOOKING_STATUS.SERVICE_COMPLETED) },
      { label: 'Service Started',       date: b.serviceStartedAt,     done: after(BOOKING_STATUS.SERVICE_IN_PROGRESS, BOOKING_STATUS.SERVICE_COMPLETED) },
      { label: 'Service Completed',     date: b.completedAt,          done: s === BOOKING_STATUS.SERVICE_COMPLETED },
    ];
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[#0B1120] p-6">
        <div className="max-w-7xl mx-auto animate-pulse space-y-4">
          <div className="h-14 bg-[#1F2937] rounded-xl w-full" />
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            {[1, 2, 3].map(i => <div key={i} className="h-48 bg-[#1F2937] rounded-xl" />)}
          </div>
        </div>
      </div>
    );
  }

  if (!booking) {
    return (
      <div className="min-h-screen bg-[#0B1120] flex items-center justify-center">
        <div className="text-center">
          <AlertCircle className="w-10 h-10 text-red-500 mx-auto mb-3" />
          <p className="text-[#E5E7EB] font-medium mb-4">Booking not found</p>
          <button onClick={() => router.push('/bookings')} className="px-4 py-2 bg-[#6366F1] text-white rounded-lg text-sm hover:bg-[#4F46E5]">
            Back to Bookings
          </button>
        </div>
      </div>
    );
  }

  const hasOffer = !!(booking.offerPrice && booking.offerPrice < booking.price);

  return (
    <div className="min-h-screen bg-[#0B1120]">
      {/* ── Sticky Header ── */}
      <div className="bg-[#111827] border-b border-[#1F2937] sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 h-14 flex items-center justify-between gap-4">
          {/* Left: back + id + status + date */}
          <div className="flex items-center gap-3 min-w-0">
            <button onClick={() => router.push('/bookings')} className="p-1.5 hover:bg-[#1F2937] rounded-lg text-[#9CA3AF] flex-shrink-0">
              <ArrowLeft size={17} />
            </button>
            <span className="text-xs font-mono text-[#6B7280] hidden sm:block">{booking.id.substring(0, 12)}</span>
            <StatusBadge status={formatStatus(booking.status)} variant={getStatusVariant(booking.status)} />
            <span className="text-xs text-[#6B7280] hidden md:block">
              {fmt(booking.bookingDate)} {booking.timeSlot ? `· ${booking.timeSlot}` : ''}
            </span>
          </div>

          {/* Right: action buttons */}
          <div className="flex items-center gap-2 flex-shrink-0">
            {canApproveBooking(booking.status) && (
              <>
                <button onClick={() => withConfirm('Approve Booking', 'This will notify the technician. Continue?', () => approveBookingAction(bookingId))}
                  disabled={processing}
                  className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white rounded-lg text-xs font-medium flex items-center gap-1.5">
                  <CheckCircle size={13} /> Approve
                </button>
                <button onClick={() => withConfirm('Reject Booking', 'This will cancel the booking. Continue?', () => rejectBookingAction(bookingId, 'Rejected by admin'), 'danger')}
                  disabled={processing}
                  className="px-3 py-1.5 bg-red-600 hover:bg-red-700 disabled:opacity-50 text-white rounded-lg text-xs font-medium flex items-center gap-1.5">
                  <XCircle size={13} /> Reject
                </button>
              </>
            )}
            {canMarkActive(booking.status) && (
              <button onClick={() => withConfirm('Start Service', 'Mark this booking as in progress?', () => markBookingActive(bookingId))}
                disabled={processing}
                className="px-3 py-1.5 bg-[#6366F1] hover:bg-[#4F46E5] disabled:opacity-50 text-white rounded-lg text-xs font-medium flex items-center gap-1.5">
                <RefreshCw size={13} /> Start
              </button>
            )}
            {canMarkCompleted(booking.status) && (
              <button onClick={() => withConfirm('Complete Service', 'Mark the service as completed?', () => markBookingCompleted(bookingId))}
                disabled={processing}
                className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white rounded-lg text-xs font-medium flex items-center gap-1.5">
                <CheckCircle size={13} /> Complete
              </button>
            )}
            {booking.paymentStatus === 'PENDING' && (
              <button onClick={() => withConfirm('Update Payment', 'Mark payment as paid?', () => updatePaymentStatus(bookingId, 'PAID'))}
                disabled={processing}
                className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white rounded-lg text-xs font-medium flex items-center gap-1.5">
                <CreditCard size={13} /> Mark Paid
              </button>
            )}
          </div>
        </div>
      </div>

      {/* ── Body ── */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

          {/* ── LEFT (span-2) ── */}
          <div className="lg:col-span-2 space-y-5">

            {/* Service Card */}
            <div className="admin-card p-5">
              <div className="flex gap-4">
                {booking.serviceImage && (
                  <img src={booking.serviceImage} alt={booking.serviceName}
                    className="w-16 h-16 object-cover rounded-lg flex-shrink-0" />
                )}
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-[#E5E7EB]">{booking.serviceName}</p>
                  <p className="text-xs text-[#6B7280] mt-0.5">{booking.categoryName}</p>
                  <div className="mt-2 flex items-center gap-3">
                    {hasOffer ? (
                      <>
                        <span className="text-base font-bold text-emerald-400">₹{booking.finalAmount}</span>
                        <span className="text-sm text-[#6B7280] line-through">₹{booking.price}</span>
                      </>
                    ) : (
                      <span className="text-base font-bold text-[#E5E7EB]">₹{booking.finalAmount}</span>
                    )}
                  </div>
                </div>
              </div>
              {booking.notes && (
                <p className="mt-4 pt-4 border-t border-[#1F2937] text-sm text-[#9CA3AF]">{booking.notes}</p>
              )}
            </div>

            {/* Timeline */}
            <div className="admin-card p-5">
              <p className="text-xs font-semibold text-[#6B7280] uppercase tracking-wider mb-4">Timeline</p>
              <div className="relative pl-5">
                {/* vertical line */}
                <div className="absolute left-[7px] top-2 bottom-2 w-px bg-[#1F2937]" />
                <div className="space-y-4">
                  {getTimeline(booking).map((step, idx) => (
                    <div key={idx} className="flex items-start gap-3 relative">
                      <div className={`w-3.5 h-3.5 rounded-full border-2 flex-shrink-0 mt-0.5 relative z-10 ${
                        step.done ? 'bg-emerald-500 border-emerald-500' : 'bg-[#0B1120] border-[#374151]'
                      }`} />
                      <div className="flex-1 flex items-center justify-between min-w-0">
                        <p className={`text-sm ${step.done ? 'text-[#E5E7EB] font-medium' : 'text-[#4B5563]'}`}>
                          {step.label}
                        </p>
                        {step.done && step.date && (
                          <p className="text-xs text-[#6B7280] flex-shrink-0 ml-3">{fmt(step.date, true)}</p>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Address */}
            {booking.customerAddress && (
              <div className="admin-card p-5">
                <p className="text-xs font-semibold text-[#6B7280] uppercase tracking-wider mb-3">Service Address</p>
                <p className="text-sm text-[#E5E7EB]">{booking.customerAddress}</p>
                {booking.city && (
                  <p className="text-xs text-[#6B7280] mt-1 flex items-center gap-1.5">
                    <Building size={12} />{booking.city}
                  </p>
                )}
              </div>
            )}

            {/* Rejection Reason */}
            {booking.rejectionReason && (
              <div className="admin-card p-5 border-l-2 border-red-500 bg-red-500/5">
                <p className="text-xs font-semibold text-red-400 uppercase tracking-wider mb-2">Rejection Reason</p>
                <p className="text-sm text-red-300">{booking.rejectionReason}</p>
              </div>
            )}
          </div>

          {/* ── RIGHT ── */}
          <div className="space-y-5">

            {/* Customer */}
            <div className="admin-card p-5">
              <p className="text-xs font-semibold text-[#6B7280] uppercase tracking-wider mb-3">Customer</p>
              <p className="font-semibold text-[#E5E7EB]">{booking.customerName}</p>
              <div className="mt-2 space-y-1.5">
                <p className="text-sm text-[#9CA3AF] flex items-center gap-2">
                  <Phone size={12} className="flex-shrink-0" />{booking.customerPhone}
                </p>
                {booking.customerEmail && (
                  <p className="text-sm text-[#9CA3AF] flex items-center gap-2">
                    <Mail size={12} className="flex-shrink-0" />{booking.customerEmail}
                  </p>
                )}
              </div>
              <p className="mt-3 pt-3 border-t border-[#1F2937] text-xs text-[#6B7280]">
                {customerBookingCount} previous booking{customerBookingCount !== 1 ? 's' : ''}
              </p>
            </div>

            {/* Technician */}
            <div className="admin-card p-5">
              <div className="flex items-center justify-between mb-3">
                <p className="text-xs font-semibold text-[#6B7280] uppercase tracking-wider">Technician</p>
                <button
                  onClick={async () => {
                    setShowChangeTechModal(true);
                    setTechLoading(true);
                    try {
                      const techs = await fetchAllTechnicians();
                      setTechnicians(techs);
                      if (booking.technicianId) setSelectedTech(techs.find(t => t.id === booking.technicianId) || null);
                    } finally { setTechLoading(false); }
                  }}
                  className="text-xs text-[#6366F1] hover:text-[#818CF8] flex items-center gap-1 font-medium"
                >
                  <UserCog size={12} /> {booking.technicianId ? 'Change' : 'Assign'}
                </button>
              </div>
              {booking.technicianId ? (
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-full bg-[#1F2937] flex items-center justify-center text-sm font-medium text-[#9CA3AF] overflow-hidden flex-shrink-0">
                    {booking.technicianPhoto
                      ? <img src={booking.technicianPhoto} alt="" className="w-full h-full object-cover" />
                      : booking.technicianName?.charAt(0).toUpperCase()}
                  </div>
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-[#E5E7EB] truncate">{booking.technicianName}</p>
                    <div className="flex items-center gap-2 mt-0.5">
                      <span className="text-xs text-[#9CA3AF] flex items-center gap-1">
                        <Star size={10} className="fill-yellow-400 text-yellow-400" />
                        {booking.technicianRating?.toFixed(1) || '—'}
                      </span>
                      {booking.technicianPhone && (
                        <span className="text-xs text-[#6B7280]">{booking.technicianPhone}</span>
                      )}
                    </div>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-[#4B5563]">No technician assigned</p>
              )}
            </div>

            {/* Payment */}
            <div className="admin-card p-5">
              <p className="text-xs font-semibold text-[#6B7280] uppercase tracking-wider mb-3">Payment</p>
              <div className="flex items-center justify-between">
                <span className="text-lg font-bold text-[#E5E7EB]">₹{booking.finalAmount}</span>
                <StatusBadge
                  status={booking.paymentStatus || 'PENDING'}
                  variant={booking.paymentStatus === 'PAID' ? 'success' : 'warning'}
                />
              </div>
              {(booking.paymentMethod || booking.transactionId) && (
                <div className="mt-3 pt-3 border-t border-[#1F2937] space-y-1">
                  {booking.paymentMethod && (
                    <p className="text-xs text-[#9CA3AF]">{booking.paymentMethod}</p>
                  )}
                  {booking.transactionId && (
                    <p className="text-xs text-[#6B7280] font-mono">{booking.transactionId.substring(0, 14)}…</p>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* ── Change Technician Modal ── */}
      {showChangeTechModal && (
        <div className="fixed inset-0 bg-black/75 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-[#111827] rounded-2xl w-full max-w-2xl border border-[#1F2937] flex flex-col max-h-[80vh]">
            <div className="flex items-center justify-between px-5 py-4 border-b border-[#1F2937]">
              <p className="font-semibold text-[#E5E7EB]">{booking.technicianId ? 'Change Technician' : 'Assign Technician'}</p>
              <button onClick={() => setShowChangeTechModal(false)} className="text-[#6B7280] hover:text-[#E5E7EB]"><X size={18} /></button>
            </div>
            <div className="p-5 overflow-y-auto flex-1">
              {techLoading ? (
                <div className="flex gap-3 overflow-x-auto">
                  {[1, 2, 3].map(i => <div key={i} className="min-w-[180px] h-24 bg-[#1F2937] rounded-xl animate-pulse flex-shrink-0" />)}
                </div>
              ) : (
                <div className="flex gap-3 overflow-x-auto pb-1">
                  {technicians.map(t => (
                    <div key={t.id} onClick={() => setSelectedTech(t)}
                      className={`min-w-[180px] p-4 rounded-xl border cursor-pointer flex-shrink-0 transition-colors ${
                        selectedTech?.id === t.id ? 'border-[#6366F1] bg-[#6366F1]/10' : 'border-[#1F2937] hover:border-[#374151]'
                      }`}>
                      <p className="font-medium text-[#E5E7EB] text-sm">{t.name}</p>
                      <p className="text-xs text-[#9CA3AF] mt-1">{t.phone}</p>
                      <p className="text-xs text-[#6B7280] mt-1">⭐ {t.rating.toFixed(1)} · {t.completedJobs} jobs</p>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <div className="border-t border-[#1F2937] px-5 py-4 flex gap-3">
              <button onClick={() => setShowChangeTechModal(false)}
                className="flex-1 py-2 bg-[#1F2937] text-[#E5E7EB] rounded-lg hover:bg-[#374151] text-sm">
                Cancel
              </button>
              <button
                disabled={!selectedTech || processing}
                onClick={() => {
                  if (!selectedTech) return;
                  withConfirm('Assign Technician', `Assign ${selectedTech.name} to this booking?`, async () => {
                    const { approveBookingWithTechnician } = await import('@/lib/services/adminBookingService');
                    await approveBookingWithTechnician(bookingId, selectedTech.id);
                    setShowChangeTechModal(false);
                  });
                }}
                className="flex-1 py-2 bg-[#6366F1] text-white rounded-lg hover:bg-[#4F46E5] disabled:opacity-50 text-sm font-medium">
                Assign
              </button>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        isOpen={confirmDialog.isOpen}
        title={confirmDialog.title}
        message={confirmDialog.message}
        onConfirm={confirmDialog.onConfirm}
        onCancel={() => setConfirmDialog(p => ({ ...p, isOpen: false }))}
        variant={confirmDialog.variant}
      />
    </div>
  );
}
