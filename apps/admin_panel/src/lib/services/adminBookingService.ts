import { db } from '@/lib/firebase';
import { 
  collection, 
  getDocs, 
  doc, 
  getDoc, 
  query, 
  orderBy, 
  onSnapshot, 
  where,
  limit as firestoreLimit,
  startAfter,
  QueryConstraint,
  DocumentSnapshot
} from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebaseClient';

export interface AdminBooking {
  id: string;
  customerId: string;
  customerName: string;
  customerPhone: string;
  customerEmail?: string;
  customerAddress: string;
  city: string;
  technicianId?: string;
  technicianName?: string;
  technicianPhone?: string;
  technicianRating?: number;
  technicianExperience?: string;
  technicianPhoto?: string;
  technicianTotalJobs?: number;
  serviceId: string;
  serviceName: string;
  serviceDescription?: string;
  categoryName: string;
  price: number;          // original price before offer (source of truth for strikethrough)
  offerPrice?: number;    // discounted price (if any)
  finalAmount: number;    // what customer actually pays — source of truth for main display
  originalPrice?: number; // original price (for reference)
  /** @deprecated use finalAmount */
  servicePrice: number;
  serviceImage?: string;
  bookingStatus?: string;
  bookingDate: any;
  timeSlot: string;
  notes?: string;
  status: string;
  paymentStatus: string;
  paymentMethod?: string;
  transactionId?: string;
  createdAt: any;
  adminApprovedAt?: any;
  technicianAcceptedAt?: any;
  serviceStartedAt?: any;
  completedAt?: any;
  cancelledAt?: any;
  rejectionReason?: string;
}

export interface PaginatedResult<T> {
  docs: T[];
  hasMore: boolean;
  nextCursor?: DocumentSnapshot;
  total?: number;
}

// Helper function to parse booking data
function parseBookingData(bookingDoc: any, user: any, technician: any, service: any): AdminBooking {
  const data = bookingDoc.data();
  
  let addressText = '';
  if (typeof data.address === 'string') {
    addressText = data.address;
  } else if (data.address && typeof data.address === 'object') {
    addressText = data.address.text || data.address.line1 || data.address.fullAddress || '';
  } else if (user?.address) {
    addressText = typeof user.address === 'string' ? user.address : user.address.text || user.address.line1 || '';
  }

  // Normalize status: bookingStatus takes priority, then status, then default
  // Handle all variants: pending_admin_review, pending_admin_approval, pending, etc.
  let effectiveStatus = data.bookingStatus || data.status || 'pending_admin_review';
  effectiveStatus = effectiveStatus.toLowerCase().trim();
  console.log('[parseBookingData] Booking', bookingDoc.id, 'raw status:', data.bookingStatus || data.status, '-> normalized:', effectiveStatus);

  const parsed = {
    id: bookingDoc.id,
    customerId: data.customerId,
    customerName: data.customerName || user?.name || 'Unknown Customer',
    customerPhone: data.customerPhone || user?.phone || '',
    customerEmail: user?.email || data.customerEmail || '',
    customerAddress: addressText,
    city: data.city || data.address?.city || user?.city || '',
    technicianId: data.technicianId,
    technicianName: data.technicianName || technician?.name,
    technicianPhone: data.technicianPhone || technician?.phone,
    technicianRating: technician?.rating,
    technicianExperience: technician?.experience,
    technicianPhoto: technician?.photo || technician?.profileImage || data.technicianPhoto,
    technicianTotalJobs: technician?.completedJobs || technician?.totalJobs || data.technicianTotalJobs,
    serviceId: data.serviceId,
    serviceName: data.serviceName || service?.name || 'Unknown Service',
    serviceDescription: service?.description || data.serviceDescription || '',
    categoryName: data.categoryName || service?.category || '',
    price: data.price || 0,
    offerPrice: data.offerPrice || service?.offerPrice,
    finalAmount: data.finalAmount || data.offerPrice || data.price || 0,
    originalPrice: data.originalPrice || data.price,
    servicePrice: data.finalAmount || data.offerPrice || data.price || 0, // kept for compat
    bookingStatus: data.bookingStatus,
    serviceImage: service?.image || data.serviceImage,
    bookingDate: data.bookingDate || data.scheduledDate,
    timeSlot: data.timeSlot || data.scheduledTime || '',
    notes: data.notes || data.customerNotes || '',
    status: effectiveStatus,
    paymentStatus: data.paymentStatus || 'pending',
    paymentMethod: data.paymentMethod,
    transactionId: data.transactionId,
    createdAt: data.createdAt,
    adminApprovedAt: data.adminApprovedAt || data.approvedAt,
    technicianAcceptedAt: data.technicianAcceptedAt || data.acceptedAt,
    serviceStartedAt: data.serviceStartedAt,
    completedAt: data.completedAt || data.serviceCompletedAt,
    cancelledAt: data.cancelledAt,
    rejectionReason: data.rejectionReason || data.cancellationReason
  } as AdminBooking;
  
  console.log('[PARSE BOOKING DATA] Firestore raw data:', {
    data_price: data.price,
    data_finalAmount: data.finalAmount,
    data_offerPrice: data.offerPrice,
    data_bookingStatus: data.bookingStatus,
    data_status: data.status,
  });
  
  console.log('[PARSE BOOKING DATA] Parsed result:', {
    parsed_price: parsed.price,
    parsed_finalAmount: parsed.finalAmount,
    parsed_offerPrice: parsed.offerPrice,
    parsed_bookingStatus: parsed.bookingStatus,
    parsed_status: parsed.status,
  });
  
  return parsed;
}

// Subscribe to single booking with real-time updates
export function subscribeToBooking(
  bookingId: string,
  callback: (booking: AdminBooking | null) => void
) {
  return onSnapshot(doc(db, 'bookings', bookingId), async (snapshot) => {
    try {
      if (!snapshot.exists()) {
        callback(null);
        return;
      }

      const data = snapshot.data();
      
      const [userSnap, technicianSnap, serviceSnap] = await Promise.all([
        data.customerId ? getDoc(doc(db, 'users', data.customerId)) : Promise.resolve(null),
        data.technicianId ? getDoc(doc(db, 'technicians', data.technicianId)) : Promise.resolve(null),
        data.serviceId ? getDoc(doc(db, 'services', data.serviceId)) : Promise.resolve(null)
      ]);

      const user = userSnap?.exists() ? userSnap.data() : null;
      const technician = technicianSnap?.exists() ? technicianSnap.data() : null;
      const service = serviceSnap?.exists() ? serviceSnap.data() : null;

      const booking = parseBookingData(snapshot, user, technician, service);
      callback(booking);
    } catch (error) {
      console.error('Error in booking subscription:', error);
      callback(null);
    }
  });
}

// Optimized: Fetch paginated bookings with minimal data
export async function getPaginatedBookings(
  pageSize: number = 20,
  cursor?: DocumentSnapshot,
  filters?: { status?: string; paymentStatus?: string }
): Promise<PaginatedResult<AdminBooking>> {
  try {
    const constraints: QueryConstraint[] = [
      orderBy('createdAt', 'desc'),
      firestoreLimit(pageSize + 1)
    ];

    if (filters?.status) {
      constraints.push(where('status', '==', filters.status));
    }
    if (filters?.paymentStatus) {
      constraints.push(where('paymentStatus', '==', filters.paymentStatus));
    }
    if (cursor) {
      constraints.push(startAfter(cursor));
    }

    const q = query(collection(db, 'bookings'), ...constraints);
    const snapshot = await getDocs(q);
    
    const docs = snapshot.docs.slice(0, pageSize);
    const hasMore = snapshot.docs.length > pageSize;
    const nextCursor = docs.length > 0 ? docs[docs.length - 1] : undefined;

    // Fetch related data only for current page
    const bookingIds = docs.map(d => d.id);
    const customerIds = [...new Set(docs.map(d => d.data().customerId))];
    const technicianIds = [...new Set(docs.map(d => d.data().technicianId).filter(Boolean))];
    const serviceIds = [...new Set(docs.map(d => d.data().serviceId))];

    const [usersSnap, techniciansSnap, servicesSnap] = await Promise.all([
      customerIds.length > 0 ? getDocs(query(collection(db, 'users'), where('__name__', 'in', customerIds))) : Promise.resolve({ docs: [] }),
      technicianIds.length > 0 ? getDocs(query(collection(db, 'technicians'), where('__name__', 'in', technicianIds))) : Promise.resolve({ docs: [] }),
      serviceIds.length > 0 ? getDocs(query(collection(db, 'services'), where('__name__', 'in', serviceIds))) : Promise.resolve({ docs: [] })
    ]);

    const usersMap = new Map<string, any>(usersSnap.docs.map(d => [d.id, d.data()] as [string, any]));
    const techniciansMap = new Map<string, any>(techniciansSnap.docs.map(d => [d.id, d.data()] as [string, any]));
    const servicesMap = new Map<string, any>(servicesSnap.docs.map(d => [d.id, d.data()] as [string, any]));

    const bookings = docs.map((bookingDoc) => {
      const data = bookingDoc.data();
      const user = usersMap.get(data.customerId);
      const technician = data.technicianId ? techniciansMap.get(data.technicianId) : null;
      const service = servicesMap.get(data.serviceId);
      return parseBookingData(bookingDoc, user, technician, service);
    });

    return { docs: bookings, hasMore, nextCursor };
  } catch (error) {
    console.error('Error fetching paginated bookings:', error);
    throw error;
  }
}

// Optimized: Get booking by ID with minimal queries
export async function getBookingById(bookingId: string): Promise<AdminBooking | null> {
  try {
    const bookingDoc = await getDoc(doc(db, 'bookings', bookingId));
    
    if (!bookingDoc.exists()) {
      return null;
    }

    const data = bookingDoc.data();
    
    const [userSnap, technicianSnap, serviceSnap] = await Promise.all([
      data.customerId ? getDoc(doc(db, 'users', data.customerId)) : Promise.resolve(null),
      data.technicianId ? getDoc(doc(db, 'technicians', data.technicianId)) : Promise.resolve(null),
      data.serviceId ? getDoc(doc(db, 'services', data.serviceId)) : Promise.resolve(null)
    ]);

    const user = userSnap?.exists() ? userSnap.data() : null;
    const technician = technicianSnap?.exists() ? technicianSnap.data() : null;
    const service = serviceSnap?.exists() ? serviceSnap.data() : null;

    return parseBookingData(bookingDoc, user, technician, service);
  } catch (error) {
    console.error('Error fetching booking by ID:', error);
    throw error;
  }
}

// Subscribe to bookings with real-time updates.
// Handles all status variants and ensures loading always completes.
export function subscribeToBookings(
  callback: (bookings: AdminBooking[]) => void,
  pageSize: number = 20,
  filters?: { status?: string; paymentStatus?: string }
) {
  const constraints: QueryConstraint[] = [
    orderBy('createdAt', 'desc'),
    firestoreLimit(pageSize)
  ];

  // Map frontend status to all possible backend variants
  if (filters?.status && filters.status !== 'all') {
    const statusVariants: Record<string, string[]> = {
      'pending_admin_approval': ['pending_admin_approval', 'pending_admin_review', 'pending_admin', 'pending'],
      'approved_by_admin': ['approved_by_admin', 'admin_approved', 'assigned'],
      'technician_accepted': ['technician_accepted', 'confirmed'],
      'service_in_progress': ['service_in_progress', 'in_progress'],
      'service_completed': ['service_completed', 'completed'],
      'rejected': ['rejected', 'rejected_by_admin', 'admin_rejected', 'technician_rejected', 'cancelled'],
    };
    const variants = statusVariants[filters.status] || [filters.status];
    constraints.push(where('status', 'in', variants));
  }

  if (filters?.paymentStatus) {
    constraints.push(where('paymentStatus', '==', filters.paymentStatus));
  }

  const q = query(collection(db, 'bookings'), ...constraints);

  let firstSnapshotReceived = false;
  const timeoutId = setTimeout(() => {
    if (!firstSnapshotReceived) {
      console.warn('[subscribeToBookings] Timeout — no snapshot after 10s, preserving existing state');
    }
  }, 10_000);

  return onSnapshot(
    q,
    async (snapshot) => {
      firstSnapshotReceived = true;
      clearTimeout(timeoutId);
      try {
        const docs = snapshot.docs;
        console.log('[subscribeToBookings] Snapshot received:', docs.length, 'docs');

        // CRITICAL FIX: Do NOT reset state on empty snapshot
        // Empty snapshot can be transient Firestore issue
        if (docs.length === 0) {
          console.log('[subscribeToBookings] Empty snapshot — skipping state update');
          return;
        }

        const customerIds = [...new Set(docs.map(d => d.data().customerId).filter(Boolean))];
        const technicianIds = [...new Set(docs.map(d => d.data().technicianId).filter(Boolean))];
        const serviceIds = [...new Set(docs.map(d => d.data().serviceId).filter(Boolean))];

        const [usersSnap, techniciansSnap, servicesSnap] = await Promise.all([
          customerIds.length > 0
            ? getDocs(query(collection(db, 'users'), where('__name__', 'in', customerIds))).catch(() => ({ docs: [] }))
            : Promise.resolve({ docs: [] }),
          technicianIds.length > 0
            ? getDocs(query(collection(db, 'technicians'), where('__name__', 'in', technicianIds))).catch(() => ({ docs: [] }))
            : Promise.resolve({ docs: [] }),
          serviceIds.length > 0
            ? getDocs(query(collection(db, 'services'), where('__name__', 'in', serviceIds))).catch(() => ({ docs: [] }))
            : Promise.resolve({ docs: [] }),
        ]);

        const usersMap = new Map<string, any>(usersSnap.docs.map(d => [d.id, d.data()] as [string, any]));
        const techniciansMap = new Map<string, any>(techniciansSnap.docs.map(d => [d.id, d.data()] as [string, any]));
        const servicesMap = new Map<string, any>(servicesSnap.docs.map(d => [d.id, d.data()] as [string, any]));

        const bookings = docs.map((bookingDoc) => {
          const data = bookingDoc.data();
          const user = usersMap.get(data.customerId);
          const technician = data.technicianId ? techniciansMap.get(data.technicianId) : null;
          const service = servicesMap.get(data.serviceId);
          return parseBookingData(bookingDoc, user, technician, service);
        });

        console.log('[subscribeToBookings] Parsed:', bookings.length, 'bookings');
        callback(bookings);
      } catch (error) {
        console.error('[subscribeToBookings] Error processing snapshot:', error);
        // Do not reset state on processing error
      }
    },
    (error) => {
      firstSnapshotReceived = true;
      clearTimeout(timeoutId);
      console.error('[subscribeToBookings] Snapshot error:', error.code, error.message);
      // Do not clear state on error — preserve existing bookings
    }
  );
}

// Get customer booking count
export async function getCustomerBookingCount(customerId: string): Promise<number> {
  try {
    const snapshot = await getDocs(query(collection(db, 'bookings'), where('customerId', '==', customerId), firestoreLimit(1000)));
    return snapshot.size;
  } catch (error) {
    console.error('Error getting customer booking count:', error);
    return 0;
  }
}

// Cloud Function calls
export async function approveBookingAction(bookingId: string) {
  try {
    console.log('[approveBookingAction] Calling approveBookingByAdmin with bookingId:', bookingId);
    const approve = httpsCallable(functions, 'approveBookingByAdmin');
    const result = await approve({ bookingId });
    console.log('[approveBookingAction] Success:', result.data);
    return result.data;
  } catch (error: any) {
    console.error('[approveBookingAction] Error:', error.code, error.message);
    throw new Error(`Failed to approve booking: ${error.message}`);
  }
}

export async function rejectBookingAction(bookingId: string, reason?: string) {
  try {
    console.log('[rejectBookingAction] Calling rejectBookingByAdmin with bookingId:', bookingId);
    const reject = httpsCallable(functions, 'rejectBookingByAdmin');
    const result = await reject({ bookingId, reason });
    console.log('[rejectBookingAction] Success:', result.data);
    return result.data;
  } catch (error: any) {
    console.error('[rejectBookingAction] Error:', error.code, error.message);
    throw new Error(`Failed to reject booking: ${error.message}`);
  }
}

export async function approveBookingWithTechnician(bookingId: string, technicianId: string) {
  try {
    console.log('[approveBookingWithTechnician] Calling approveBookingByAdmin with bookingId:', bookingId, 'technicianId:', technicianId);
    const approve = httpsCallable(functions, 'approveBookingByAdmin');
    const result = await approve({ bookingId, overrideTechnicianId: technicianId });
    console.log('[approveBookingWithTechnician] Success:', result.data);
    return result.data;
  } catch (error: any) {
    console.error('[approveBookingWithTechnician] Error:', error.code, error.message);
    throw new Error(`Failed to approve booking with technician: ${error.message}`);
  }
}

export async function changeTechnicianAction(bookingId: string, technicianId: string) {
  const change = httpsCallable(functions, 'adminChangeTechnician');
  await change({ bookingId, technicianId });
}

export interface TechnicianOption {
  id: string;
  name: string;
  phone: string;
  rating: number;
  completedJobs: number;
}

export async function fetchAllTechnicians(): Promise<TechnicianOption[]> {
  // Direct Firestore query — avoids auth requirement of the Cloud Function
  const snapshot = await getDocs(
    query(
      collection(db, 'technicians'),
      where('status', 'in', ['approved', 'active']),
      firestoreLimit(100)
    )
  );
  return snapshot.docs.map(d => {
    const data = d.data();
    return {
      id: d.id,
      name: data.name || 'Unknown',
      phone: data.phone || '',
      rating: data.rating || 0,
      completedJobs: data.completedJobs || data.totalJobs || 0,
    };
  });
}

export async function assignTechnician(bookingId: string, technicianId: string) {
  const assign = httpsCallable(functions, 'adminChangeTechnician');
  await assign({ bookingId, technicianId });
}

export async function markBookingActive(bookingId: string) {
  try {
    console.log('[markBookingActive] Calling markBookingActive with bookingId:', bookingId);
    const markActive = httpsCallable(functions, 'markBookingActive');
    const result = await markActive({ bookingId });
    console.log('[markBookingActive] Success:', result.data);
    return result.data;
  } catch (error: any) {
    console.error('[markBookingActive] Error:', error.code, error.message);
    throw new Error(`Failed to mark booking active: ${error.message}`);
  }
}

export async function markBookingCompleted(bookingId: string) {
  try {
    console.log('[markBookingCompleted] Calling completeService with bookingId:', bookingId);
    const complete = httpsCallable(functions, 'completeService');
    const result = await complete({ bookingId });
    console.log('[markBookingCompleted] Success:', result.data);
    return result.data;
  } catch (error: any) {
    console.error('[markBookingCompleted] Error:', error.code, error.message);
    throw new Error(`Failed to complete booking: ${error.message}`);
  }
}

export async function updatePaymentStatus(bookingId: string, paymentStatus: string) {
  try {
    console.log('[updatePaymentStatus] Calling updateBookingPayment with bookingId:', bookingId, 'status:', paymentStatus);
    const updatePayment = httpsCallable(functions, 'updateBookingPayment');
    const result = await updatePayment({ bookingId, paymentStatus });
    console.log('[updatePaymentStatus] Success:', result.data);
    return result.data;
  } catch (error: any) {
    console.error('[updatePaymentStatus] Error:', error.code, error.message);
    throw new Error(`Failed to update payment status: ${error.message}`);
  }
}
