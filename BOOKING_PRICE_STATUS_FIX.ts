/**
 * BOOKING PRICE & STATUS FIX - CRITICAL CHANGES
 * 
 * ISSUE 1: Price field mismatch
 * - Admin panel reads: booking.finalAmount
 * - Cloud function writes: price field only
 * - FIX: Always write both price AND finalAmount
 * 
 * ISSUE 2: Status not updating in admin panel
 * - Admin panel doesn't refetch after approval
 * - Real-time subscription should handle it but race condition exists
 * - FIX: Ensure status fields are consistent (bookingStatus + status)
 * 
 * ISSUE 3: Field name inconsistency
 * - Some places use bookingStatus, others use status
 * - FIX: Always write both fields for backward compatibility
 */

// ============================================
// FIX 1: In approveBookingByAdmin function
// ============================================
// BEFORE:
/*
await db.runTransaction(async (t) => {
    const freshDoc = await t.get(bookingRef);
    if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
    const freshBooking = freshDoc.data()!;
    updateBookingStatus(t, bookingRef, 'approved_by_admin', freshBooking, {
        bookingStatus: 'approved_by_admin',
        status: 'approved_by_admin',
        technicianId: assignedTechnicianId,
        technicianName: techData.name || freshBooking.technicianName || 'Technician',
        technicianPhone: techData.phone || freshBooking.technicianPhone || '',
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
        approvedBy: uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});
*/

// AFTER:
/*
await db.runTransaction(async (t) => {
    const freshDoc = await t.get(bookingRef);
    if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
    const freshBooking = freshDoc.data()!;
    const finalAmount = freshBooking.finalAmount ?? freshBooking.price ?? 0;
    updateBookingStatus(t, bookingRef, 'approved_by_admin', freshBooking, {
        bookingStatus: 'approved_by_admin',
        status: 'approved_by_admin',
        finalAmount: finalAmount,
        price: finalAmount,
        technicianId: assignedTechnicianId,
        technicianName: techData.name || freshBooking.technicianName || 'Technician',
        technicianPhone: techData.phone || freshBooking.technicianPhone || '',
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
        approvedBy: uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});
*/

// ============================================
// FIX 2: In admin panel - Add console logging
// ============================================
// File: apps/admin_panel/src/lib/services/adminBookingService.ts
// In parseBookingData function, add:
/*
console.log('[parseBookingData] Booking', bookingDoc.id, {
  price: data.price,
  finalAmount: data.finalAmount,
  basePrice: data.basePrice,
  offerPrice: data.offerPrice,
  bookingStatus: data.bookingStatus,
  status: data.status,
});
*/

// ============================================
// FIX 3: In admin panel - Force refetch after approval
// ============================================
// File: apps/admin_panel/src/app/(admin)/bookings/page.tsx
// In handleApprove function, add refetch:
/*
const handleApprove = (bookingId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Approve Booking',
      message: 'This will notify the technician. Are you sure?',
      onConfirm: async () => {
        setProcessing(true);
        try {
          await approveBookingAction(bookingId);
          // CRITICAL: Force refetch after approval
          const updated = await getBookingById(bookingId);
          if (updated) {
            setBookings(prev => prev.map(b => b.id === bookingId ? updated : b));
          }
          setConfirmDialog(prev => ({ ...prev, isOpen: false }));
        } catch (error: any) {
          alert(`Failed: ${error.message}`);
        } finally {
          setProcessing(false);
        }
      },
    });
  };
*/

// ============================================
// FIX 4: Ensure booking creation sets both fields
// ============================================
// File: functions/src/booking/unified_booking_lifecycle.ts
// In createBookingRequest, bookingData object:
/*
const bookingData = {
  // ... other fields ...
  price: finalPrice,           // For backward compatibility
  finalAmount: finalPrice,     // Primary field for admin panel
  originalPrice: basePrice,
  offerPrice: rawOfferPrice,
  // ... rest of fields ...
};
*/

// ============================================
// FIX 5: Admin panel booking type definition
// ============================================
// File: apps/admin_panel/src/lib/services/adminBookingService.ts
// Ensure AdminBooking interface has:
/*
export interface AdminBooking {
  // ... other fields ...
  basePrice: number;           // original price before offer
  offerPrice?: number;         // discounted price (if any)
  finalAmount: number;         // what customer actually pays — source of truth
  servicePrice: number;        // kept for compat (deprecated)
  // ... rest of fields ...
}
*/

// ============================================
// DEPLOYMENT STEPS
// ============================================
/*
1. Update functions/src/booking/unified_booking_lifecycle.ts:
   - Line ~95: Add finalAmount preservation in approveBookingByAdmin
   - Line ~1050: Ensure bookingData has both price and finalAmount

2. Update apps/admin_panel/src/lib/services/adminBookingService.ts:
   - Add console.log in parseBookingData for debugging
   - Ensure getBookingById is exported for refetch

3. Update apps/admin_panel/src/app/(admin)/bookings/page.tsx:
   - Import getBookingById
   - Add refetch logic after approval

4. Deploy:
   firebase deploy --only functions
   npm run build && npm run deploy (for admin panel)

5. Test:
   - Create booking with offer price
   - Approve in admin panel
   - Verify finalAmount shows correctly
   - Verify status updates immediately
*/
