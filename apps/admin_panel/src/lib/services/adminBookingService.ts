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
    addressText = data.address.text || data.address.line1 || '';
  } else if (user?.address) {
    addressText = typeof user.address === 'string' ? user.address : user.address.text || user.address.line1 || '';
  }

  return {
    id: bookingDoc.id,
    customerId: data.customerId,
    customerName: user?.name || data.customerName || 'Unknown Customer',
    customerPhone: user?.phone || data.customerPhone || '',
    customerEmail: user?.email || data.customerEmail || '',
    customerAddress: addressText,
    city: data.city || user?.city || '',
    technicianId: data.technicianId,
    technicianName: technician?.name || data.technicianName,
    technicianPhone: technician?.phone || data.technicianPhone,
    technicianRating: technician?.rating,
    technicianExperience: technician?.experience,
    technicianPhoto: technician?.photo || technician?.profileImage || data.technicianPhoto,
    technicianTotalJobs: technician?.totalJobs || technician?.completedJobs || data.technicianTotalJobs,
    serviceId: data.serviceId,
    serviceName: service?.name || data.serviceName || 'Unknown Service',
    serviceDescription: service?.description || data.serviceDescription || '',
    categoryName: service?.category || data.categoryName || '',
    servicePrice: data.totalPrice || data.price || 0,
    offerPrice: service?.offerPrice || data.offerPrice,
    serviceImage: service?.image || data.serviceImage,
    bookingDate: data.bookingDate || data.scheduledDate,
    timeSlot: data.timeSlot || data.scheduledTime || '',
    notes: data.notes || data.customerNotes || '',
    status: data.status,
    paymentStatus: data.paymentStatus || 'PENDING',
    paymentMethod: data.paymentMethod,
    transactionId: data.transactionId,
    createdAt: data.createdAt,
    adminApprovedAt: data.adminApprovedAt,
    technicianAcceptedAt: data.technicianAcceptedAt,
    serviceStartedAt: data.serviceStartedAt,
    completedAt: data.completedAt,
    cancelledAt: data.cancelledAt,
    rejectionReason: data.rejectionReason
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

    const usersMap = new Map(usersSnap.docs.map(d => [d.id, d.data()]));
    const techniciansMap = new Map(techniciansSnap.docs.map(d => [d.id, d.data()]));
    const servicesMap = new Map(servicesSnap.docs.map(d => [d.id, d.data()]));

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

// Optimized: Subscribe to paginated bookings
export function subscribeToBookings(
  callback: (bookings: AdminBooking[], hasMore: boolean) => void,
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
  
  return onSnapshot(q, async (snapshot) => {
    try {
      const docs = snapshot.docs;
      
      // Fetch related data only for current page
      const customerIds = [...new Set(docs.map(d => d.data().customerId))];
      const technicianIds = [...new Set(docs.map(d => d.data().technicianId).filter(Boolean))];
      const serviceIds = [...new Set(docs.map(d => d.data().serviceId))];

      const [usersSnap, techniciansSnap, servicesSnap] = await Promise.all([
        customerIds.length > 0 ? getDocs(query(collection(db, 'users'), where('__name__', 'in', customerIds))) : Promise.resolve({ docs: [] }),
        technicianIds.length > 0 ? getDocs(query(collection(db, 'technicians'), where('__name__', 'in', technicianIds))) : Promise.resolve({ docs: [] }),
        serviceIds.length > 0 ? getDocs(query(collection(db, 'services'), where('__name__', 'in', serviceIds))) : Promise.resolve({ docs: [] })
      ]);

      const usersMap = new Map(usersSnap.docs.map(d => [d.id, d.data()]));
      const techniciansMap = new Map(techniciansSnap.docs.map(d => [d.id, d.data()]));
      const servicesMap = new Map(servicesSnap.docs.map(d => [d.id, d.data()]));

      const bookings = docs.map((bookingDoc) => {
        const data = bookingDoc.data();
        const user = usersMap.get(data.customerId);
        const technician = data.technicianId ? techniciansMap.get(data.technicianId) : null;
        const service = servicesMap.get(data.serviceId);
        return parseBookingData(bookingDoc, user, technician, service);
      });

      callback(bookings, docs.length >= pageSize);
    } catch (error) {
      console.error('Error in booking subscription:', error);
      callback([], false);
    }
  });
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
  const approve = httpsCallable(functions, 'approveBooking');
  await approve({ bookingId });
}

export async function rejectBookingAction(bookingId: string, reason?: string) {
  const reject = httpsCallable(functions, 'rejectBooking');
  await reject({ bookingId, reason });
}

export async function assignTechnician(bookingId: string, technicianId: string) {
  const assign = httpsCallable(functions, 'assignTechnician');
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
