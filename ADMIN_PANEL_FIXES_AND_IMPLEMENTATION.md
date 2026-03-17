# Admin Panel - Bug Fixes & Implementation Guide

## Quick Fix Checklist

### 🔴 CRITICAL - Must Fix Before Deployment

#### 1. Missing `rejectTechnician` Cloud Function

**Problem**: Admin panel calls non-existent function, causing 404 errors when rejecting technicians.

**Fix Option A: Simple - Use existing approveTechnician with flag**

File: `functions/src/index.ts`

Add this export:
```typescript
// Around line 560, after admin_approveTechnician export
export const rejectTechnician = functions.https.onCall(async (data, context) => {
    const adminTechMgmt = (await import('./admin/technician_management')).default || 
                          require('./admin/technician_management');
    return adminTechMgmt.approveTechnician({ 
        ...data, 
        approve: false 
    }, context);
});
```

**OR**

**Fix Option B: Complete - Create dedicated function**

File: `functions/src/admin/technician_management.ts`

Add at end of file:
```typescript
export const rejectTechnician = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { uid, reason } = data;
    
    if (!uid) {
        throw new functions.https.HttpsError('invalid-argument', 'UID required');
    }
    
    const techRef = db.collection('technicians').doc(uid);
    const techDoc = await techRef.get();
    
    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician not found');
    }
    
    await techRef.update({
        status: 'rejected',
        isApproved: false,
        adminApproved: false,
        isVerified: false,
        isActive: false,
        kycStatus: 'rejected',
        rejectionReason: reason || 'Application rejected',
        rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
        rejectedBy: context.auth!.uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    await sendPushNotification(uid, 'technicians', {
        title: 'Application Not Approved',
        body: reason || 'Your technician application could not be approved at this time.',
        data: { type: 'app_status', status: 'rejected', reason: reason }
    });
    
    return { success: true };
});
```

Then add to `functions/src/index.ts`:
```typescript
const adminTechMgmt = require('./admin/technician_management');
export const rejectTechnician = adminTechMgmt.rejectTechnician;
```

**Testing**:
```bash
# Deploy functions
firebase deploy --only functions

# Test rejection
curl -X POST http://localhost:5001/your-project/us-central1/rejectTechnician \
  -H "Content-Type: application/json" \
  -d '{"uid": "test-tech-id", "reason": "Insufficient experience"}'
```

---

#### 2. Fix Dashboard Revenue Calculation

**Problem**: Revenue fields show hardcoded fake values instead of actual data.

File: `apps/admin_panel/src/app/(admin)/dashboard/page.tsx`

**Current Code (Lines 125-132)**:
```typescript
setStats({
  // ... other stats
  todayRevenue: 12450, // TODO: replace with actual revenue query
  monthlyRevenue: 245678, // TODO: replace with actual revenue query
});
```

**Fixed Code**:
```typescript
// Add this helper function at the top of the useEffect
const calculateRevenue = async () => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  const thirtyDaysAgo = new Date(today);
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  
  // Revenue = sum of prices from completed bookings
  const todayBookingsSnap = await getDocs(query(
    collection(db, 'bookings'),
    where('status', '==', 'completed'),
    where('completedAt', '>=', Timestamp.fromDate(today)),
    where('completedAt', '<', Timestamp.fromDate(tomorrow))
  ));
  
  const monthlyBookingsSnap = await getDocs(query(
    collection(db, 'bookings'),
    where('status', '==', 'completed'),
    where('completedAt', '>=', Timestamp.fromDate(thirtyDaysAgo))
  ));
  
  const todayRevenue = todayBookingsSnap.docs.reduce((sum, doc) => {
    return sum + (doc.data().finalAmount || doc.data().amount || 0);
  }, 0);
  
  const monthlyRevenue = monthlyBookingsSnap.docs.reduce((sum, doc) => {
    return sum + (doc.data().finalAmount || doc.data().amount || 0);
  }, 0);
  
  return { todayRevenue, monthlyRevenue };
};

// Then in fetchDashboardData, replace the setStats call with:
const revenueData = await calculateRevenue();
setStats({
  totalBookings: totalBookingsSnap.data().count,
  pendingBookings: pendingBookingsSnap.data().count,
  customRequests: customRequestsSnap.data().count,
  pendingCustomRequests: pendingCustomRequestsSnap.data().count,
  techApplications: techApplicationsSnap.data().count,
  activeTechnicians: activeTechniciansSnap.data().count,
  totalCustomers: totalCustomersSnap.data().count,
  completedBookings: completedBookingsSnap.data().count,
  todayRevenue: revenueData.todayRevenue,
  monthlyRevenue: revenueData.monthlyRevenue,
});
```

**OR More Efficient (using aggregation)**:

Consider using Cloud Functions for this calculation if bookings exceed 1000:

File: `functions/src/admin/dashboard.ts`

```typescript
export const getDashboardStats = functions.https.onCall(async (data, context) => {
  await assertAdmin(context);
  const db = admin.firestore();
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  const thirtyDaysAgo = new Date(today);
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  
  // Calculate revenue using aggregation if available
  // Fall back to calculation on client if using Firestore lite
  
  return {
    counters: {
      // ... existing counters
      revenueToday: await getRevenue(db, today, tomorrow),
      totalRevenue: await getRevenue(db, thirtyDaysAgo, tomorrow)
    }
  };
});

async function getRevenue(db: admin.firestore.Firestore, startDate: Date, endDate: Date) {
  const snapshot = await db.collection('bookings')
    .where('status', '==', 'completed')
    .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
    .where('completedAt', '<', admin.firestore.Timestamp.fromDate(endDate))
    .get();
  
  return snapshot.docs.reduce((sum, doc) => {
    return sum + (doc.data().finalAmount || doc.data().amount || 0);
  }, 0);
}
```

---

#### 3. Add Error Notifications to Dashboard

**Problem**: When approve/reject fails, user gets no feedback.

File: `apps/admin_panel/src/app/(admin)/dashboard/page.tsx`

**Add toast state** (after other useState):
```typescript
const [toast, setToast] = useState<{
  show: boolean;
  message: string;
  type: 'success' | 'error';
}>({ show: false, message: '', type: 'success' });

const showNotification = (message: string, type: 'success' | 'error') => {
  setToast({ show: true, message, type });
  setTimeout(() => setToast({ show: false, message: '', type: 'success' }), 3000);
};
```

**Update handlers**:
```typescript
const handleApproveBooking = async (bookingId: string) => {
  try {
    setLoading(true);
    await adminApi.approveBookingRequest(bookingId);
    await fetchDashboardData();
    showNotification('Booking approved successfully', 'success');
  } catch (error: any) {
    console.error('Error approving booking:', error);
    showNotification(
      `Error: ${error.message || 'Failed to approve booking'}`,
      'error'
    );
  } finally {
    setLoading(false);
  }
};

const handleRejectBooking = async (bookingId: string) => {
  try {
    setLoading(true);
    await adminApi.rejectBookingRequest(bookingId, 'Rejected by admin');
    await fetchDashboardData();
    showNotification('Booking rejected', 'success');
  } catch (error: any) {
    console.error('Error rejecting booking:', error);
    showNotification(`Error: ${error.message || 'Failed to reject'}`, 'error');
  } finally {
    setLoading(false);
  }
};
```

**Render notification**:
```typescript
return (
  <div className="space-y-6">
    {/* Add toast notification */}
    {toast.show && (
      <div className={`p-4 rounded-lg ${
        toast.type === 'success' ? 'bg-green-500/20 text-green-300' : 'bg-red-500/20 text-red-300'
      }`}>
        {toast.message}
      </div>
    )}
    {/* Rest of page */}
    ...
  </div>
);
```

---

### 🟠 HIGH - Should Fix Before Beta

#### 4. Resolve Duplicate Function Exports

**Problem**: `approveTechnician` exported from 3 different files, unclear which is used.

**Audit Current Exports**:
```bash
# Find all approveTechnician exports
grep -rn "export.*approveTechnician" functions/src/
```

**Result**:
- `functions/src/admin/technician_management.ts` - Line 53 ✅ KEEP (main implementation)
- `functions/src/admin/technician_approval.ts` - Line 23 - REMOVE
- `functions/src/admin/technicians.ts` - Line 68 - REMOVE

**Fix**:

File: `functions/src/index.ts`

Keep only:
```typescript
import * as adminTechMgmt from './admin/technician_management';
export const admin_approveTechnician = adminTechMgmt.approveTechnician;
export const approveTechnician = adminTechMgmt.approveTechnician; // Keep for backward compatibility
export const rejectTechnician = adminTechMgmt.rejectTechnician; // New function
```

Remove other imports and exports of `approveTechnician` from:
- `technician_approval.ts` exports
- `technicians.ts` exports

---

#### 5. Add Pagination to Bookings Page

**Problem**: Loads all bookings without limit, causes performance issues at scale.

File: `apps/admin_panel/src/app/(admin)/bookings/page.tsx`

**Current code** (Line 30):
```typescript
const unsubscribe = subscribeToBookings((bookingsData) => {
  console.log('Fetched bookings:', bookingsData.length);
  setBookings(bookingsData);
  setLoading(false);
});
```

**Fix - Implement pagination**:
```typescript
const ITEMS_PER_PAGE = 50;
const [currentPage, setCurrentPage] = useState(1);
const [hasMore, setHasMore] = useState(true);

useEffect(() => {
  // Load bookings with pagination
  const startIndex = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIndex = startIndex + ITEMS_PER_PAGE;
  
  const unsubscribe = subscribeToBookings((allBookingsData) => {
    const paginatedBookings = allBookingsData.slice(startIndex, endIndex);
    setBookings(paginatedBookings);
    setHasMore(allBookingsData.length > endIndex);
    setLoading(false);
  });

  return () => unsubscribe();
}, [currentPage]);

// Add pagination controls
const pageCount = Math.ceil(bookings.length / ITEMS_PER_PAGE);
```

Add to JSX:
```tsx
{/* Pagination controls */}
<div className="flex gap-2 mt-4 justify-center">
  <button
    disabled={currentPage === 1}
    onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
    className="px-3 py-1 bg-indigo-600 disabled:bg-gray-600 rounded"
  >
    Previous
  </button>
  <span className="px-3 py-1">Page {currentPage}</span>
  <button
    disabled={!hasMore}
    onClick={() => setCurrentPage(p => p + 1)}
    className="px-3 py-1 bg-indigo-600 disabled:bg-gray-600 rounded"
  >
    Next
  </button>
</div>
```

---

### ⚠️ MEDIUM PRIORITY

#### 6. Implement Finance Module

Files to create:
- `apps/admin_panel/src/app/(admin)/finance/page.tsx` (main finance dashboard)
- `apps/admin_panel/src/app/(admin)/finance/wallet/page.tsx` (wallet management)
- `apps/admin_panel/src/app/(admin)/finance/payouts/page.tsx` (payout processing)
- `apps/admin_panel/src/app/(admin)/finance/transactions/page.tsx` (transaction history)

**Start with**: Copy structure from Bookings page, adapt for finance data

---

#### 7. Implement Settings Module

File to create:
- `apps/admin_panel/src/app/(admin)/settings/page.tsx`

**Key Features**:
```typescript
interface SystemSettings {
  commission_percentage: number;
  min_wallet_balance: number;
  max_booking_radius_km: number;
  service_request_timeout_minutes: number;
  payout_min_amount: number;
  support_email: string;
  support_phone: string;
}
```

---

#### 8. Add Session Timeout

File: `apps/admin_panel/src/components/AuthProvider.tsx`

Add inactivity timer:
```typescript
const [inactivityTimer, setInactivityTimer] = useState<NodeJS.Timeout | null>(null);
const INACTIVITY_TIMEOUT = 30 * 60 * 1000; // 30 minutes

const resetInactivityTimer = () => {
  if (inactivityTimer) clearTimeout(inactivityTimer);
  
  const timer = setTimeout(async () => {
    console.log('Session timeout due to inactivity');
    await signOutUser();
    setUser(null);
    setIsAdmin(false);
  }, INACTIVITY_TIMEOUT);
  
  setInactivityTimer(timer);
};

useEffect(() => {
  window.addEventListener('mousemove', resetInactivityTimer);
  window.addEventListener('keydown', resetInactivityTimer);
  
  resetInactivityTimer(); // Initialize timer
  
  return () => {
    window.removeEventListener('mousemove', resetInactivityTimer);
    window.removeEventListener('keydown', resetInactivityTimer);
    if (inactivityTimer) clearTimeout(inactivityTimer);
  };
}, [inactivityTimer]);
```

---

## Testing These Fixes

### Test rejectTechnician Function
```typescript
// In browser console after deploying functions
const { httpsCallable } = await import('firebase/functions');
const { functions } = await import('@/lib/firebase');

const fn = httpsCallable(functions, 'rejectTechnician');
const result = await fn({ 
  uid: 'test-tech-id',
  reason: 'Insufficient documentation'
});
console.log(result.data);
```

### Test Revenue Calculation
```typescript
// Dashboard should show real revenue after reload
// Verify by completing a booking and checking dashboard
```

### Test Error Notifications
```typescript
// Go to dashboard
// Try to approve/reject a booking
// Should see success/error toast notification
```

---

## Deployment Checklist

### Before Deploying to Production

- [ ] All 6 critical bugs fixed
- [ ] Functions deployed: `firebase deploy --only functions`
- [ ] Frontend built: `npm run build`
- [ ] Test rejection workflow end-to-end:
  - [ ] Create test technician app
  - [ ] Approve (should succeed)
  - [ ] Create another test app
  - [ ] Reject (should succeed with reason)
  - [ ] Verify status updated in Firestore
- [ ] Test revenue calculation:
  - [ ] Complete a booking manually in Firestore
  - [ ] Dashboard should show revenue
  - [ ] Refresh and verify persists
- [ ] Test error cases:
  - [ ] Try to approve non-existent ID
  - [ ] Should show error toast
  - [ ] Try with invalid data
  - [ ] Should show validation error

### Monitoring After Launch

- [ ] Monitor function errors in Firebase Console
- [ ] Check for common errors:
  - `rejectTechnician not found` → Function not deployed
  - `admin claim missing` → Authentication issue
  - `Firestore permission denied` → Rules issue
- [ ] Setup alerts for key metrics:
  - Admin panel error rate
  - Approval function latency

---

## Files Affected Summary

### Modified Files (6)
1. `functions/src/index.ts` - Add function exports
2. `functions/src/admin/technician_management.ts` - Add rejectTechnician
3. `apps/admin_panel/src/app/(admin)/dashboard/page.tsx` - Fix revenue, add notifications
4. `apps/admin_panel/src/components/AuthProvider.tsx` - Add session timeout (optional)

### New Files Needed (3)
1. `apps/admin_panel/src/app/(admin)/finance/page.tsx`
2. `apps/admin_panel/src/app/(admin)/settings/page.tsx`
3. `apps/admin_panel/src/app/(admin)/audit-logs/page.tsx` (phase 2)

### Files to Verify
- `apps/admin_panel/src/lib/admin-api.ts` - Already correct
- `firestore.rules` - Already correct
- `apps/admin_panel/src/components/AuthProvider.tsx` - Already secure

---

