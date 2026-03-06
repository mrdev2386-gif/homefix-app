import { db } from '@/lib/firebase';
import { collection, getDocs, doc, getDoc, query, orderBy, onSnapshot } from 'firebase/firestore';

export interface AdminBooking {
  id: string;
  customerId: string;
  customerName: string;
  customerPhone: string;
  customerAddress: string;
  city: string;
  technicianId?: string;
  technicianName?: string;
  technicianPhone?: string;
  technicianRating?: number;
  technicianExperience?: string;
  serviceId: string;
  serviceName: string;
  categoryName: string;
  servicePrice: number;
  serviceImage?: string;
  bookingDate: any;
  timeSlot: string;
  status: string;
  paymentStatus: string;
  paymentMethod?: string;
  transactionId?: string;
  createdAt: any;
  adminApprovedAt?: any;
  technicianAcceptedAt?: any;
  serviceStartedAt?: any;
  completedAt?: any;
}

export async function getAdminBookings(): Promise<AdminBooking[]> {
  try {
    const bookingsSnap = await getDocs(query(collection(db, 'bookings'), orderBy('createdAt', 'desc')));
    
    const [usersSnap, techniciansSnap, servicesSnap] = await Promise.all([
      getDocs(collection(db, 'users')),
      getDocs(collection(db, 'technicians')),
      getDocs(collection(db, 'services'))
    ]);

    const usersMap = new Map(usersSnap.docs.map(d => [d.id, d.data()]));
    const techniciansMap = new Map(techniciansSnap.docs.map(d => [d.id, d.data()]));
    const servicesMap = new Map(servicesSnap.docs.map(d => [d.id, d.data()]));

    const bookings = bookingsSnap.docs.map((bookingDoc) => {
      const data = bookingDoc.data();
      
      const user = usersMap.get(data.customerId);
      const technician = data.technicianId ? techniciansMap.get(data.technicianId) : null;
      const service = servicesMap.get(data.serviceId);
      
      // Handle address - convert object to string if needed
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
        customerAddress: addressText,
        city: data.city || user?.city || '',
        technicianId: data.technicianId,
        technicianName: technician?.name || data.technicianName,
        technicianPhone: technician?.phone || data.technicianPhone,
        technicianRating: technician?.rating,
        technicianExperience: technician?.experience,
        serviceId: data.serviceId,
        serviceName: service?.name || data.serviceName || 'Unknown Service',
        categoryName: service?.category || data.categoryName || '',
        servicePrice: data.totalPrice || data.price || 0,
        serviceImage: service?.image || data.serviceImage,
        bookingDate: data.bookingDate || data.scheduledDate,
        timeSlot: data.timeSlot || data.scheduledTime || '',
        status: data.status,
        paymentStatus: data.paymentStatus || 'PENDING',
        paymentMethod: data.paymentMethod,
        transactionId: data.transactionId,
        createdAt: data.createdAt,
        adminApprovedAt: data.adminApprovedAt,
        technicianAcceptedAt: data.technicianAcceptedAt,
        serviceStartedAt: data.serviceStartedAt,
        completedAt: data.completedAt
      } as AdminBooking;
    });

    return bookings;
  } catch (error) {
    console.error('Error fetching admin bookings:', error);
    throw error;
  }
}

export function subscribeToBookings(callback: (bookings: AdminBooking[]) => void) {
  const q = query(collection(db, 'bookings'), orderBy('createdAt', 'desc'));
  
  return onSnapshot(q, async () => {
    try {
      const bookings = await getAdminBookings();
      callback(bookings);
    } catch (error) {
      console.error('Error in booking subscription:', error);
    }
  });
}


import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';

export async function approveBookingAction(bookingId: string) {
  const approve = httpsCallable(functions, 'approveBooking');
  await approve({ bookingId });
}

export async function rejectBookingAction(bookingId: string, reason?: string) {
  const reject = httpsCallable(functions, 'rejectBooking');
  await reject({ bookingId, reason });
}
