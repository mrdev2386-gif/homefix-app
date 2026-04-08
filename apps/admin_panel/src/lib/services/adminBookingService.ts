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
import { functions } from '@/lib/firebase';

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
  servicePrice: number;
  offerPrice?: number;
  serviceImage?: string;
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

  // Normalize status: bookingStatus takes priority over status
  const effectiveStatus = data.bookingStatus || data.status || 'pending_admin_review';

  return {
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
    servicePrice: data.finalAmount || data.price || 0,
    offerPrice: service?.offerPrice || data.offerPrice,
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
// The onSnapshot error handler guarantees setLoading(false) even on
// permission-denied / network errors — the async-callback catch alone
// is NOT enough because Firestore snapshot errors bypass it.
export function subscribeToBookings(
  callback: (bookings: AdminBooking[]) => void,
  pageSize: number = 20,
  filters?: { status?: string; paymentStatus?: string }
) {
  const constraints: QueryConstraint[] = [
    orderBy('createdAt', 'desc'),
    firestoreLimit(pageSize)
  ];

  if (filters?.status) {
    constraints.push(where('status', '==', filters.status));
  }
  if (filters?.paymentStatus) {
    constraints.push(where('paymentStatus', '==', filters.paymentStatus));
  }

  const q = query(collection(db, 'bookings'), ...constraints);

  // Timeout failsafe: if the first snapshot never arrives, stop loading.
  let firstSnapshotReceived = false;
  const timeoutId = setTimeout(() => {
    if (!firstSnapshotReceived) {
      console.warn('[subscribeToBookings] Timeout — no snapshot after 10s. Resolving empty.');
      callback([]);
    }
  }, 10_000);

  return onSnapshot(
    q,
    // ✅ success handler
    async (snapshot) => {
      firstSnapshotReceived = true;
      clearTimeout(timeoutId);
      try {
        const docs = snapshot.docs;
        console.log('[subscribeToBookings] Snapshot received, docs:', docs.length);

        if (docs.length === 0) {
          callback([]);
          return;
        }

        // Booking docs already contain denormalized customerName / technicianName
        // so secondary lookups are best-effort only — failures must not block loading.
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

        console.log('[subscribeToBookings] Parsed bookings:', bookings.length);
        callback(bookings);
      } catch (error) {
        console.error('[subscribeToBookings] Error processing snapshot:', error);
        // Still resolve so loading stops — use raw booking data without enrichment
        const bookings = snapshot.docs.map(d => parseBookingData(d, null, null, null));
        callback(bookings);
      }
    },
    // ✅ error handler — this is the path that was previously missing
    (error) => {
      firstSnapshotReceived = true;
      clearTimeout(timeoutId);
      console.error('[subscribeToBookings] Firestore snapshot error:', error.code, error.message);
      callback([]);
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
  const approve = httpsCallable(functions, 'approveBookingByAdmin');
  await approve({ bookingId });
}

export async function rejectBookingAction(bookingId: string, reason?: string) {
  const reject = httpsCallable(functions, 'rejectBookingByAdmin');
  await reject({ bookingId, reason });
}

export async function approveBookingWithTechnician(bookingId: string, technicianId: string) {
  const approve = httpsCallable(functions, 'approveBookingByAdmin');
  await approve({ bookingId, overrideTechnicianId: technicianId });
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
  const fn = httpsCallable<unknown, { success: boolean; technicians: TechnicianOption[] }>(functions, 'getAllTechniciansForAdmin');
  const result = await fn({});
  return result.data.technicians;
}

export async function assignTechnician(bookingId: string, technicianId: string) {
  const assign = httpsCallable(functions, 'adminChangeTechnician');
  await assign({ bookingId, technicianId });
}

export async function markBookingActive(bookingId: string) {
  const markActive = httpsCallable(functions, 'markBookingActive');
  await markActive({ bookingId });
}

export async function markBookingCompleted(bookingId: string) {
  const complete = httpsCallable(functions, 'completeBooking');
  await complete({ bookingId });
}

export async function updatePaymentStatus(bookingId: string, paymentStatus: string) {
  const updatePayment = httpsCallable(functions, 'updateBookingPayment');
  await updatePayment({ bookingId, paymentStatus });
}
