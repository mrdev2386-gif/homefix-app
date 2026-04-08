# BOOKING FLOW - ACTION PLAN

**Created**: 2026-04-07  
**Priority**: P0 - CRITICAL  
**Estimated Effort**: 2-3 days

---

## OVERVIEW

This action plan addresses the critical issues found in the booking flow audit. The primary blockers are:
1. Missing admin approval UI
2. Missing admin notification on booking creation

Without these, bookings cannot progress beyond the initial creation stage.

---

## PHASE 1: IMMEDIATE FIXES (P0) - Day 1

### 1.1 Add Admin Notification on Booking Creation

**Priority**: P0 - CRITICAL  
**Effort**: 2 hours  
**File**: `functions/src/booking/unified_booking_lifecycle.ts`

**Implementation**:

```typescript
// In createBookingRequest function, after successful booking creation
// Add this code after the transaction completes

console.log(`✅ [BOOKING] Created booking: ${bookingId}`);

// NEW: Notify all admins
try {
  const adminsSnapshot = await db.collection('admins').get();
  const notificationPromises = [];
  
  for (const adminDoc of adminsSnapshot.docs) {
    const adminData = adminDoc.data();
    if (adminData?.fcmToken) {
      notificationPromises.push(
        sendNotificationToToken({
          token: adminData.fcmToken,
          title: 'New Booking Request',
          body: `${bookingData.customerName} requested ${bookingData.serviceName} for ${scheduledDate}`,
          data: { 
            bookingId, 
            type: 'new_booking',
            customerId: uid,
            technicianId,
            serviceId,
          },
        })
      );
    }
  }
  
  await Promise.allSettled(notificationPromises);
  console.log(`📧 [BOOKING] Notified ${notificationPromises.length} admins`);
} catch (notificationError) {
  // Non-fatal - log but don't block booking creation
  console.error('⚠️ [BOOKING] Failed to notify admins:', notificationError);
}

// Continue with existing return statement
if (finalPaymentMethod === 'online') {
  // ... existing code
}
```

**Testing**:
1. Create a booking from customer app
2. Check Firebase Console → Functions → Logs
3. Verify admin receives FCM notification
4. Check admin's notifications collection in Firestore

**Deployment**:
```bash
cd functions
npm run deploy -- --only functions:createBookingRequest
```

---

### 1.2 Build Admin Approval UI

**Priority**: P0 - CRITICAL  
**Effort**: 6 hours  
**Location**: `apps/admin_panel/src/app/bookings/`

#### Step 1: Create Booking Types (30 min)

**File**: `apps/admin_panel/src/types/booking.ts`

```typescript
export interface Booking {
  bookingId: string;
  customerId: string;
  customerName: string;
  technicianId: string;
  technicianName: string;
  serviceId: string;
  serviceName: string;
  categoryId: string;
  categoryName: string;
  scheduledDate: string;
  scheduledTime: string;
  address: {
    fullAddress: string;
    district: string;
    state: string;
    pincode: string;
  };
  price: number;
  finalAmount: number;
  paymentMode: 'before_work' | 'after_work';
  paymentMethod: 'online' | 'after_service';
  bookingStatus: string;
  status: string;
  statusHistory: Array<{
    status: string;
    timestamp: any;
  }>;
  paymentStatus: string;
  createdAt: any;
  updatedAt: any;
}

export type BookingStatus = 
  | 'pending'
  | 'pending_admin_approval'
  | 'approved_by_admin'
  | 'technician_accepted'
  | 'service_in_progress'
  | 'service_completed'
  | 'completed'
  | 'cancelled'
  | 'rejected_by_admin'
  | 'technician_rejected';
```

#### Step 2: Create Firebase Hook (1 hour)

**File**: `apps/admin_panel/src/hooks/useBookings.ts`

```typescript
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
```

#### Step 3: Create Booking Actions (1 hour)

**File**: `apps/admin_panel/src/lib/firebase-bookings.ts`

```typescript
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';

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
  // TODO: Implement when rejectBookingByAdmin function is created
  throw new Error('Reject booking function not yet implemented');
}
```

#### Step 4: Create Booking List Component (2 hours)

**File**: `apps/admin_panel/src/components/bookings/BookingList.tsx`

```typescript
'use client';

import { useState } from 'react';
import { usePendingBookings } from '@/hooks/useBookings';
import { approveBooking } from '@/lib/firebase-bookings';
import { Booking } from '@/types/booking';
import { LoadingState } from '@/components/ui/LoadingState';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';

export function BookingList() {
  const { bookings, loading, error } = usePendingBookings();
  const [selectedBooking, setSelectedBooking] = useState<Booking | null>(null);
  const [isApproving, setIsApproving] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  const handleApprove = async (booking: Booking) => {
    setSelectedBooking(booking);
    setShowConfirm(true);
  };

  const confirmApprove = async () => {
    if (!selectedBooking) return;
    
    setIsApproving(true);
    try {
      await approveBooking(selectedBooking.bookingId);
      setShowConfirm(false);
      setSelectedBooking(null);
    } catch (err: any) {
      alert(`Failed to approve: ${err.message}`);
    } finally {
      setIsApproving(false);
    }
  };

  if (loading) return <LoadingState message="Loading bookings..." />;
  if (error) return <div className="text-red-600">Error: {error}</div>;
  if (bookings.length === 0) {
    return (
      <div className="text-center py-12 text-gray-500">
        No pending bookings
      </div>
    );
  }

  return (
    <>
      <div className="space-y-4">
        {bookings.map((booking) => (
          <div
            key={booking.bookingId}
            className="bg-white rounded-lg shadow p-6 border border-gray-200"
          >
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <h3 className="text-lg font-semibold text-gray-900">
                  {booking.serviceName}
                </h3>
                <p className="text-sm text-gray-600 mt-1">
                  Customer: {booking.customerName}
                </p>
                <p className="text-sm text-gray-600">
                  Technician: {booking.technicianName}
                </p>
                <p className="text-sm text-gray-600">
                  Scheduled: {booking.scheduledDate} at {booking.scheduledTime}
                </p>
                <p className="text-sm text-gray-600">
                  Location: {booking.address?.district}, {booking.address?.state}
                </p>
                <p className="text-lg font-bold text-green-600 mt-2">
                  ₹{booking.finalAmount}
                </p>
              </div>
              
              <div className="flex flex-col gap-2">
                <button
                  onClick={() => handleApprove(booking)}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
                >
                  Approve
                </button>
                <button
                  disabled
                  className="px-4 py-2 bg-gray-300 text-gray-500 rounded-lg cursor-not-allowed"
                  title="Reject function not yet implemented"
                >
                  Reject
                </button>
              </div>
            </div>
            
            <div className="mt-4 pt-4 border-t border-gray-200">
              <span className="inline-block px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm">
                {booking.bookingStatus}
              </span>
              <span className="ml-2 text-sm text-gray-500">
                Created: {new Date(booking.createdAt?.toDate()).toLocaleString()}
              </span>
            </div>
          </div>
        ))}
      </div>

      <ConfirmDialog
        isOpen={showConfirm}
        onClose={() => setShowConfirm(false)}
        onConfirm={confirmApprove}
        title="Approve Booking"
        message={`Are you sure you want to approve this booking for ${selectedBooking?.customerName}?`}
        confirmText="Approve"
        isLoading={isApproving}
      />
    </>
  );
}
```

#### Step 5: Create Bookings Page (1 hour)

**File**: `apps/admin_panel/src/app/bookings/page.tsx`

```typescript
import { BookingList } from '@/components/bookings/BookingList';

export default function BookingsPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">
          Pending Bookings
        </h1>
        <p className="text-gray-600 mt-2">
          Review and approve booking requests
        </p>
      </div>
      
      <BookingList />
    </div>
  );
}
```

#### Step 6: Add Navigation Link (30 min)

**File**: `apps/admin_panel/src/components/layout/Sidebar.tsx` (or equivalent)

```typescript
// Add to navigation items
{
  name: 'Bookings',
  href: '/bookings',
  icon: CalendarIcon, // or appropriate icon
  badge: pendingCount, // optional: show count
}
```

**Testing**:
1. Navigate to `/bookings` in admin panel
2. Verify pending bookings are displayed
3. Click "Approve" on a booking
4. Verify confirmation dialog appears
5. Confirm approval
6. Check booking status changes to `approved_by_admin`
7. Verify technician receives notification

**Deployment**:
```bash
cd apps/admin_panel
npm run build
firebase deploy --only hosting:admin
```

---

## PHASE 2: SHORT-TERM FIXES (P1) - Day 2

### 2.1 Standardize Status Field Name

**Priority**: P1 - HIGH  
**Effort**: 4 hours

**Strategy**: Use `bookingStatus` as the standard field

#### Step 1: Update Booking Model (30 min)

**File**: `apps/customer_app/lib/core/models/booking.dart`

```dart
// Change from:
final String status;

// To:
final String bookingStatus;

// Update fromFirestore:
bookingStatus: (data['bookingStatus'] ?? data['status'] ?? 'pending').toString(),

// Update toMap:
'bookingStatus': bookingStatus,
```

#### Step 2: Update All Queries (2 hours)

Search and replace in all files:
```bash
# Customer app
grep -r "where('status'" apps/customer_app/lib/
# Replace with: where('bookingStatus'

# Technician app
grep -r "where('status'" apps/technician_app/lib/
# Replace with: where('bookingStatus'
```

#### Step 3: Update Cloud Functions (1 hour)

Ensure all Cloud Functions use `bookingStatus` consistently.

#### Step 4: Data Migration (30 min)

**File**: `functions/src/migrations/standardize_booking_status.ts`

```typescript
// One-time migration script
export async function migrateBookingStatus() {
  const bookings = await db.collection('bookings').get();
  const batch = db.batch();
  
  bookings.docs.forEach(doc => {
    const data = doc.data();
    if (data.status && !data.bookingStatus) {
      batch.update(doc.ref, { bookingStatus: data.status });
    }
  });
  
  await batch.commit();
  console.log(`Migrated ${bookings.size} bookings`);
}
```

---

### 2.2 Implement Admin Rejection Function

**Priority**: P1 - HIGH  
**Effort**: 2 hours

**File**: `functions/src/booking/unified_booking_lifecycle.ts`

```typescript
// ==========================================
// ADMIN REJECT BOOKING
// ==========================================
export const rejectBookingByAdmin = functions
  .region('asia-south1')
  .https.onCall(
    secureCallable(async (data, context) => {
      console.log('✅ [rejectBookingByAdmin] Auth UID:', context.auth?.uid);
      
      const { bookingId, reason } = data;
      const uid = context.auth?.uid;

      if (!uid) {
        console.error('❌ [rejectBookingByAdmin] context.auth is NULL');
        throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
      }
      if (!bookingId) {
        throw new functions.https.HttpsError('invalid-argument', 'bookingId required');
      }

      // Verify admin
      const adminDoc = await db.collection('admins').doc(uid).get();
      if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can reject bookings');
      }

      const bookingRef = db.collection('bookings').doc(bookingId);
      const bookingSnap = await bookingRef.get();

      if (!bookingSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Booking not found');
      }

      const booking = bookingSnap.data()!;

      if (booking.bookingStatus !== 'pending_admin_approval' && booking.bookingStatus !== 'pending') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          `Cannot reject booking with status: ${booking.bookingStatus}`
        );
      }

      // Update booking
      await db.runTransaction(async (t) => {
        const freshDoc = await t.get(bookingRef);
        if (!freshDoc.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');
        const freshBooking = freshDoc.data()!;
        
        updateBookingStatus(t, bookingRef, 'rejected_by_admin', freshBooking, {
          bookingStatus: 'rejected_by_admin',
          rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
          rejectedBy: uid,
          rejectionReason: sanitize(reason) || 'Rejected by admin',
        });
      });

      // Notify customer
      const customerDoc = await db.collection('customers').doc(booking.customerId).get();
      const customerData = customerDoc.data();

      if (customerData?.fcmToken) {
        await sendNotificationToToken({
          token: customerData.fcmToken,
          title: 'Booking Rejected',
          body: `Your booking request was rejected. ${reason || ''}`,
          data: { bookingId, type: 'booking_rejected' },
        });
      }

      return { success: true, bookingStatus: 'rejected_by_admin' };
    })
  );
```

**Update Admin UI**:
```typescript
// In firebase-bookings.ts
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
```

---

## PHASE 3: MEDIUM-TERM IMPROVEMENTS (P2) - Day 3

### 3.1 Enhance Idempotency Keys

**Priority**: P2 - MEDIUM  
**Effort**: 1 hour

```typescript
import { randomBytes } from 'crypto';

// In createBookingRequest
const finalIdempotencyKey = idempotencyKey || `BK_${randomBytes(16).toString('hex')}`;
```

### 3.2 Add Booking Analytics Dashboard

**Priority**: P2 - MEDIUM  
**Effort**: 4 hours

Create admin dashboard showing:
- Total bookings today/week/month
- Pending approval count
- Average approval time
- Completion rate
- Revenue metrics

---

## DEPLOYMENT CHECKLIST

### Before Deployment
- [ ] Run TypeScript build: `npm run build`
- [ ] Run tests: `npm test`
- [ ] Review changes in staging
- [ ] Backup Firestore data

### Deploy Functions
```bash
cd functions
npm run deploy
```

### Deploy Admin Panel
```bash
cd apps/admin_panel
npm run build
firebase deploy --only hosting:admin
```

### Post-Deployment
- [ ] Test booking creation flow
- [ ] Test admin approval flow
- [ ] Verify notifications working
- [ ] Check Cloud Function logs
- [ ] Monitor error rates

---

## TESTING PLAN

### Manual Testing
1. Create booking from customer app
2. Verify admin receives notification
3. Login to admin panel
4. Navigate to bookings page
5. Verify booking appears in list
6. Click approve
7. Verify confirmation dialog
8. Confirm approval
9. Verify technician receives notification
10. Check booking status in Firestore

### Edge Cases
- [ ] Approve already approved booking (should fail gracefully)
- [ ] Approve cancelled booking (should fail)
- [ ] Multiple admins approving same booking (race condition)
- [ ] Network failure during approval
- [ ] Admin without FCM token

---

## ROLLBACK PLAN

If issues occur:

1. **Revert Cloud Functions**:
```bash
firebase functions:delete createBookingRequest
firebase deploy --only functions:createBookingRequest
```

2. **Revert Admin Panel**:
```bash
firebase hosting:rollback admin
```

3. **Database Rollback**:
- Restore from Firestore backup
- Or manually update affected bookings

---

## SUCCESS METRICS

- [ ] Admin receives notification within 5 seconds of booking creation
- [ ] Admin can approve booking in < 3 clicks
- [ ] Technician receives notification within 5 seconds of approval
- [ ] Zero booking creation failures
- [ ] < 1% approval failures

---

## NEXT STEPS AFTER COMPLETION

1. Monitor booking flow for 1 week
2. Gather admin feedback on UI
3. Implement admin rejection UI
4. Add booking search/filter
5. Add bulk approval feature
6. Implement booking reassignment
7. Add booking analytics

---

**For detailed audit findings, see**: `BOOKING_FLOW_DEEP_AUDIT.md`  
**For quick reference, see**: `BOOKING_FLOW_QUICK_REFERENCE.md`
