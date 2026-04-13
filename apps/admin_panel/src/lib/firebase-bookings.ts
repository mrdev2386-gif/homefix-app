import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebaseClient';

export async function approveBooking(bookingId: string): Promise<void> {
  const approveBookingByAdmin = httpsCallable(functions, 'approveBookingByAdmin');
  
  try {
    const result = await approveBookingByAdmin({ bookingId });
    console.log('Booking approved:', result.data);
  } catch (error: any) {
    console.error('Error approving booking:', error);
    throw new Error(error.message || 'Failed to approve booking');
  }
}

export async function rejectBooking(bookingId: string, reason: string): Promise<void> {
  const rejectBookingByAdmin = httpsCallable(functions, 'rejectBookingByAdmin');
  
  try {
    const result = await rejectBookingByAdmin({ bookingId, reason });
    console.log('Booking rejected:', result.data);
  } catch (error: any) {
    console.error('Error rejecting booking:', error);
    throw new Error(error.message || 'Failed to reject booking');
  }
}
