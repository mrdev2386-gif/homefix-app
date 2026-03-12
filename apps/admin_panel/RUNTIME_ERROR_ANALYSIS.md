# Admin Panel Runtime Error - Root Cause Analysis

## 🚨 CRITICAL ISSUE

**Error**: `TypeError: subscribeToBooking is not a function`

**Location**: `src/app/(admin)/bookings/[bookingId]/page.tsx` (line 7)

**Root Cause**: Function name mismatch between import and export

---

## DETAILED ANALYSIS

### Service File: `adminBookingService.ts`

**Exported Functions**:
```typescript
export function subscribeToBookings(...)  // ← PLURAL
export async function getPaginatedBookings(...)
export async function getBookingById(...)
export async function approveBookingAction(...)
export async function rejectBookingAction(...)
export async function assignTechnician(...)
export async function markBookingActive(...)
export async function markBookingCompleted(...)
export async function updatePaymentStatus(...)
export async function getCustomerBookingCount(...)
```

**Key Finding**: Service exports `subscribeToBookings` (plural), NOT `subscribeToBooking` (singular)

---

## BROKEN IMPORTS

### File: `src/app/(admin)/bookings/[bookingId]/page.tsx`

**Line 7 - INCORRECT IMPORT**:
```typescript
import { 
  subscribeToBooking,  // ❌ WRONG - Function doesn't exist
  AdminBooking, 
  approveBookingAction, 
  rejectBookingAction,
  markBookingActive,
  markBookingCompleted,
  updatePaymentStatus,
  getCustomerBookingCount
} from '@/lib/services/adminBookingService';
```

**Line 68 - INCORRECT USAGE**:
```typescript
const unsubscribe = subscribeToBooking(bookingId, (bookingData) => {
  setBooking(bookingData);
  setLoading(false);
});
```

---

## CORRECT IMPLEMENTATION

The service file needs to export a single-booking subscription function. Currently, it only has:
- `subscribeToBookings()` - for multiple bookings with pagination
- `getBookingById()` - for fetching a single booking once

**Solution**: Add a new export function for real-time single booking subscription:

```typescript
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
```

---

## IMPACT ANALYSIS

### Pages Affected
- ✅ `src/app/(admin)/bookings/page.tsx` - Uses `subscribeToBookings` (correct)
- ❌ `src/app/(admin)/bookings/[bookingId]/page.tsx` - Uses `subscribeToBooking` (incorrect)

### Error Manifestation
When user clicks "View" button on bookings page or navigates to `/bookings/{id}`:
1. Page component mounts
2. useEffect tries to call `subscribeToBooking()`
3. Runtime error: `TypeError: subscribeToBooking is not a function`
4. Page fails to load
5. User sees blank/error state

---

## SOLUTION STEPS

### Step 1: Add Missing Function to Service
Add `subscribeToBooking()` function to `adminBookingService.ts`

### Step 2: Verify Exports
Ensure both functions are exported:
- `export function subscribeToBooking(...)`
- `export function subscribeToBookings(...)`

### Step 3: Verify Imports
Confirm booking details page imports correct function:
```typescript
import { subscribeToBooking, ... } from '@/lib/services/adminBookingService';
```

### Step 4: Test
1. Navigate to Bookings page
2. Click "View" on any booking
3. Verify booking details page loads without errors
4. Verify real-time updates work

---

## VERIFICATION CHECKLIST

After fix:
- [ ] `subscribeToBooking()` exported from service
- [ ] `subscribeToBookings()` still exported from service
- [ ] Booking details page imports `subscribeToBooking`
- [ ] Bookings list page imports `subscribeToBookings`
- [ ] No console errors when navigating to booking details
- [ ] Real-time updates work on booking details page
- [ ] Listener properly unsubscribes on page unmount
- [ ] All admin menu pages open instantly

---

## FILES TO MODIFY

1. **`src/lib/services/adminBookingService.ts`**
   - Add `subscribeToBooking()` function
   - Ensure proper export

2. **`src/app/(admin)/bookings/[bookingId]/page.tsx`**
   - Already has correct import (no change needed)
   - Will work once service exports the function

---

## EXPECTED RESULTS

After implementing the fix:
- ✅ Booking details page loads instantly
- ✅ Real-time booking updates work
- ✅ No runtime errors
- ✅ All admin pages accessible
- ✅ Listener cleanup works properly

