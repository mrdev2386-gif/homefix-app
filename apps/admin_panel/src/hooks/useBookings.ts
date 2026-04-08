import { useState, useEffect } from 'react';
import { collection, query, where, orderBy, limit, onSnapshot } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Booking } from '@/types/booking';

export function usePendingBookings() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, 'bookings'),
      where('bookingStatus', 'in', ['pending', 'pending_admin_approval']),
      orderBy('createdAt', 'desc'),
      limit(50)
    );

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const bookingsList = snapshot.docs.map(doc => ({
          ...doc.data(),
          bookingId: doc.id,
        })) as Booking[];
        setBookings(bookingsList);
        setLoading(false);
      },
      (err) => {
        console.error('Error fetching bookings:', err);
        setError(err.message);
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  return { bookings, loading, error };
}
