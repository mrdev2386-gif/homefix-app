# BOOKING FLOW DEEP AUDIT - HomeFix System

**Audit Date**: 2026-04-07  
**Auditor**: Kiro AI  
**Scope**: Complete end-to-end booking flow from creation to completion

---

## EXECUTIVE SUMMARY

This audit traces the complete booking lifecycle in the HomeFix system, identifying the exact flow, status transitions, security measures, and potential issues.

### Key Findings:
✅ **STRENGTHS**:
- Robust idempotency protection prevents duplicate bookings
- Firestore transactions ensure atomic state changes
- Price manipulation protection via server-side validation
- Comprehensive status history tracking
- Security rules prevent direct client writes to bookings

⚠️ **CRITICAL ISSUES FOUND**:
1. **NO ADMIN APPROVAL UI** - Admin approval function exists but no UI found
2. **INCOMPLETE STATUS MACHINE** - Multiple status field names used inconsistently
3. **MISSING NOTIFICATION FLOW** - Admin not notified when booking created
4. **RACE CONDITION RISK** - Multiple technicians could accept same booking
5. **PAYMENT FLOW GAPS** - Wallet deduction logic not fully traced

---

## 1. BOOKING CREATION FLOW

### 1.1 Customer App Flow

**Entry Point**: `apps/customer_app/lib/features/cart/presentation/checkout_screen.dart`

**User Journey**:
```
Step 1: Address Selection → User selects/adds delivery address
Step 2: Schedule Selection → User picks date + time slot
Step 3: Summary Review → User reviews service, price, payment mode
Step 4: Confirm Booking → Triggers _finishBooking()
```

**Pre-Flight Validation** (Client-Side):
```dart
// Location: BookingProvider.createBookingRequest()
// File: apps/customer_app/lib/core/providers/booking_provider.dart

1. RE-FETCH service from technician_services (SOURCE OF TRUTH)
   - Verify service exists
   - Verify status == 'approved'
   - Price integrity check (±₹1 tolerance)

2. RE-FETCH technician from technicians collection
   - Verify technician exists
   - Verify isActive == true
   - Verify status == 'approved' OR technicianApproved == true

3. VERIFY category exists in categories collection

4. VERIFY district/normalized address present
```

**Cloud Function Call**:
```dart
// Function: createBookingRequest
// Location: functions/src/booking/unified_booking_lifecycle.ts

BookingService.createBookingRequest(
  serviceId: firstItem.serviceId,
  technicianId: checkout.selectedTechnicianId,
  categoryId: firstItem.categoryId,
  categoryName: firstItem.categoryName,
  scheduledDate: scheduledDate.toIso8601String(),
  scheduledTime: timeSlot,
  address: checkout.selectedAddress.toMap(),
  price: checkout.grandTotal,
  subcategoryId: firstItem.subServiceId,
  paymentMode: _paymentMode, // 'before_work' or 'after_work'
)
```

### 1.2 Cloud Function Processing

**Function**: `createBookingRequest`  
**Location**: `functions/src/booking/unified_booking_lifecycle.ts`

**Server-Side Validation**:
```typescript
1. Authentication Check
   - Verify context.auth.uid exists
   - Fetch customer profile from customers collection

2. Rate Limiting (non-fatal)
   - Check booking rate limit via checkBookingRateLimit()
   - Allows 10 bookings per hour per customer
   - Logs warning if check fails but doesn't block

3. Input Validation (STRICT)
   - serviceId: required string
   - technicianId: required string
   - categoryId: required
   - scheduledDate: required
   - scheduledTime: required
   - address: required object
   - price: must be positive number
   - paymentMode: must be 'before_work' or 'after_work'

4. Service Verification
   - Fetch from technician_services collection
   - Verify service exists
   - Verify technicianId matches
   - ENFORCE database price (basePrice = serviceData.price || price)

5. Technician Verification
   - Fetch from technicians collection
   - Verify technician exists
   - Verify verificationStatus == 'approved' OR status == 'approved'
```

**Idempotency Protection**:
```typescript
// Collection: booking_idempotency
// Key: idempotencyKey || `BK_${uid}_${Date.now()}`

await db.runTransaction(async (transaction) => {
  const idempotencyRef = db.collection('booking_idempotency').doc(finalIdempotencyKey);
  const idempotencyDoc = await transaction.get(idempotencyRef);

  if (idempotencyDoc.exists) {
    // Return existing booking ID - prevents duplicate
    throw new Error(`IDEMPOTENCY_DUPLICATE:${existingBookingId}`);
  }
  
  // Write booking + idempotency record atomically
  transaction.set(bookingsRef, bookingData);
  transaction.set(idempotencyRef, { bookingId, customerId, createdAt });
});
```

**Initial Status Determination**:
```typescript
const finalPaymentMethod = paymentMethod || 
  (paymentMode === 'before_work' || paymentMode === 'pay_before_work' 
    ? 'online' 
    : 'after_service');

const initialStatus = finalPaymentMethod === 'online' 
  ? 'awaiting_payment'  // Customer must pay first
  : 'pending';          // Goes to admin approval
```

**Booking Document Structure**:
```typescript
{
  bookingId: string,
  customerId: string,
  customerName: string,
  technicianId: string,
  technicianName: string,
  serviceId: string,
  serviceName: string,
  categoryId: string,
  categoryName: string,
  subcategoryId: string | null,
  quantity: number,
  durationMinutes: number | null,
  scheduledDate: string (ISO 8601),
  scheduledTime: string,
  address: {
    // Sanitized address object
  },
  price: number,              // SERVER-ENFORCED
  discountAmount: number,
  finalAmount: number,
  paymentMode: 'before_work' | 'after_work',
  paymentMethod: 'online' | 'after_service',
  bookingStatus: 'pending' | 'awaiting_payment',  // Initial status
  status: 'pending' | 'awaiting_payment',         // Duplicate field!
  statusHistory: [
    { status: string, timestamp: Timestamp }
  ],
  paymentStatus: 'pending',
  payment: {
    status: 'pending',
    paymentMethod: string,
    currency: 'INR'
  },
  adminApproval: null,
  approvedAt: null,
  approvedBy: null,
  acceptedAt: null,
  serviceStartedAt: null,
  serviceCompletedAt: null,
  cancelledAt: null,
  cancelledBy: null,
  cancellationReason: null,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### 1.3 Post-Creation Flow

**Customer App Response Handling**:
```dart
// Location: checkout_screen.dart _finishBooking()

if (status == 'pending_admin') {
  // Show "Booking Submitted - Pending Admin Approval" sheet
  _showBookingPendingSheet(bookingId);
} else {
  // Navigate to BookingStatusScreen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => BookingStatusScreen(bookingId: bookingId),
    ),
  );
}
```

**⚠️ CRITICAL ISSUE #1: NO ADMIN NOTIFICATION**
```
FINDING: Admin is NOT notified when booking is created
IMPACT: Admin must manually check for pending bookings
LOCATION: functions/src/booking/unified_booking_lifecycle.ts
EXPECTED: After booking creation, send FCM notification to all admins
STATUS: NOT IMPLEMENTED
```

---

## 2. ADMIN APPROVAL FLOW

### 2.1 Admin Approval Function

**Function**: `approveBookingByAdmin`  
**Location**: `functions/src/booking/unified_booking_lifecycle.ts`

**Flow**:
```typescript
1. Authentication
   - Verify user is admin (check admins collection)

2. Fetch Booking
   - Verify booking exists
   - Verify status is 'pending_admin_approval' OR 'pending'

3. Verify Technician
   - Verify technicianId is assigned
   - Verify technician exists
   - Verify verificationStatus == 'approved'

4. Update Booking (Transaction)
   - Set bookingStatus = 'approved_by_admin'
   - Set approvedAt = serverTimestamp
   - Set approvedBy = admin UID
   - Add to statusHistory

5. Notify Technician
   - Send FCM notification to technician
   - Title: "New Job Available"
   - Body: "Admin approved a booking for {serviceName}"
```

**⚠️ CRITICAL ISSUE #2: NO ADMIN UI FOUND**
```
FINDING: Admin approval function exists but NO UI found in admin panel
SEARCHED: apps/admin_panel/**/*.{ts,tsx}
QUERY: approveBooking|booking.*approval
RESULT: No matches found
IMPACT: Admins cannot approve bookings - flow is blocked
STATUS: MISSING IMPLEMENTATION
```

### 2.2 Admin Rejection (NOT FOUND)

**Expected Function**: `rejectBookingByAdmin` or similar  
**Status**: NOT FOUND IN CODEBASE

---

## 3. TECHNICIAN FLOW

### 3.1 Technician Receives Booking

**Technician App Query**:
```dart
// Location: apps/technician_app/lib/core/services/booking_service.dart

Stream<List<Booking>> getPendingBookings(String techId) {
  return _db.collection('bookings')
      .where('technicianId', isEqualTo: techId)
      .where('status', whereIn: [BookingStatus.assigned, 'approved_by_admin'])
      .limit(20)
      .snapshots()
}
```

**UI Locations**:
- `apps/technician_app/lib/features/job_requests/job_requests_screen.dart`
- `apps/technician_app/lib/screens/job_details_screen.dart`

### 3.2 Technician Accepts Booking

**Function**: `technicianAcceptBooking`  
**Location**: `functions/src/booking/unified_booking_lifecycle.ts`

**Flow**:
```typescript
1. Authentication
   - Verify user is authenticated

2. Fetch Booking
   - Verify booking exists
   - Verify technicianId == current user UID
   - Verify bookingStatus == 'approved_by_admin'

3. Update Booking (Transaction)
   - Set bookingStatus = 'technician_accepted'
   - Set acceptedAt = serverTimestamp
   - Add to statusHistory

4. Notify Customer
   - Send FCM notification to customer
   - Title: "Booking Accepted"
   - Body: "Your booking has been accepted by the technician"
```

**⚠️ CRITICAL ISSUE #3: RACE CONDITION RISK**
```
FINDING: Multiple technicians could theoretically accept same booking
SCENARIO: If admin assigns booking to multiple technicians
PROTECTION: Transaction checks bookingStatus == 'approved_by_admin'
RISK LEVEL: LOW (requires admin error)
MITIGATION: Transaction will fail for second technician
STATUS: ACCEPTABLE (transaction provides protection)
```

### 3.3 Technician Rejects Booking

**Function**: `technicianRejectBooking`  
**Location**: `functions/src/booking/unified_booking_lifecycle.ts`

**Flow**:
```typescript
1. Authentication + Verification
   - Verify technicianId == current user
   - Verify bookingStatus == 'approved_by_admin'

2. Update Booking (Transaction)
   - Set bookingStatus = 'technician_rejected'
   - Set rejectedBy = technician UID
   - Set rejectedAt = serverTimestamp
   - Set rejectionReason = reason || 'Technician unavailable'

3. Notify Admin
   - Send FCM to all admins
   - Title: "Booking Rejected"
   - Body: "Technician rejected booking. Please reassign."
```

---

## 4. PAYMENT FLOW

### 4.1 Payment Modes

**Two Payment Modes**:
1. **Pay Before Work** (`before_work`)
   - paymentMethod = 'online'
   - initialStatus = 'awaiting_payment'
   - Customer must pay before service starts

2. **Pay After Work** (`after_work`)
   - paymentMethod = 'after_service'
   - initialStatus = 'pending'
   - Customer pays after service completion

### 4.2 Payment Confirmation

**Function**: `customerConfirmPayment`  
**Location**: `functions/src/booking/new_booking_flow.ts`

**Flow**:
```typescript
1. Authentication
   - Verify customer is authenticated
   - Verify customerId matches booking

2. Fetch Booking
   - Verify booking exists
   - Verify status == 'awaiting_payment'

3. Idempotency Check
   - If already paid, return success (idempotent)

4. Wallet Deduction (TRANSACTION)
   - Deduct amount from customer wallet
   - Update booking status = 'confirmed'
   - Update paymentStatus = 'paid'
   - Add to statusHistory

5. Notify Technician
   - Send FCM notification
   - Title: "Payment Received"
   - Body: "Customer has paid. You can start the service."
```

**⚠️ CRITICAL ISSUE #4: WALLET DEDUCTION NOT FULLY TRACED**
```
FINDING: Wallet deduction logic referenced but not fully visible
LOCATION: Payment confirmation function mentions wallet deduction
CONCERN: Need to verify:
  1. Wallet balance check before deduction
  2. Transaction atomicity (booking + wallet update)
  3. Rollback on failure
  4. Insufficient balance handling
STATUS: REQUIRES DEEPER AUDIT OF WALLET SYSTEM
```

---

## 5. SERVICE EXECUTION FLOW

### 5.1 Start Service

**Function**: `startService`  
**Location**: `functions/src/booking/unified_booking_lifecycle.ts`

**Flow**:
```typescript
1. Verify technician is assigned
2. Verify bookingStatus == 'technician_accepted'
3. Check payment status (if paymentMethod == 'online')
   - Verify payment.status == 'paid' OR paymentStatus == 'paid'
   - Throw error if not paid
4. Update bookingStatus = 'service_in_progress'
5. Set serviceStartedAt = serverTimestamp
6. Notify customer
```

### 5.2 Complete Service

**Function**: `completeService`  
**Location**: `functions/src/booking/unified_booking_lifecycle.ts`

**Flow**:
```typescript
1. Verify technician is assigned
2. Verify bookingStatus == 'service_in_progress'
3. Update bookingStatus = 'service_completed'
4. Set serviceCompletedAt = serverTimestamp
5. Set paymentStatus = 'pending' (for after_service payments)
6. Notify customer
```

---

## 6. STATUS MACHINE ANALYSIS

### 6.1 Valid Status Transitions

**Defined in**: `functions/src/booking/unified_booking_lifecycle.ts`

```typescript
const VALID_STATUS_TRANSITIONS = {
  'pending': ['approved_by_admin', 'rejected_by_admin', 'cancelled'],
  'pending_admin_approval': ['approved_by_admin', 'rejected_by_admin', 'cancelled'],
  'approved_by_admin': ['technician_accepted', 'technician_rejected', 'cancelled'],
  'technician_accepted': ['service_in_progress', 'cancelled'],
  'service_in_progress': ['service_completed', 'cancelled'],
  'service_completed': ['completed', 'cancelled'],
  'completed': [],
  'cancelled': [],
  'rejected_by_admin': [],
  'technician_rejected': [],
};
```

### 6.2 Status Field Inconsistency

**⚠️ CRITICAL ISSUE #5: MULTIPLE STATUS FIELDS**
```
FINDING: Booking document has BOTH 'status' and 'bookingStatus' fields
LOCATIONS:
  - Booking model: uses 'status' field
  - Cloud Functions: use 'bookingStatus' field
  - Firestore queries: mix both fields

EXAMPLES:
  - createBookingRequest sets BOTH: status: initialStatus, bookingStatus: initialStatus
  - getPendingBookings queries: where('status', whereIn: [...])
  - approveBookingByAdmin updates: bookingStatus = 'approved_by_admin'

IMPACT: Potential query mismatches, confusion, bugs
RECOMMENDATION: Standardize on ONE field name across entire codebase
```

### 6.3 Complete Status Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     BOOKING LIFECYCLE                            │
└─────────────────────────────────────────────────────────────────┘

CUSTOMER CREATES BOOKING
         │
         ├─→ paymentMethod == 'online'
         │   └─→ awaiting_payment
         │       └─→ customerConfirmPayment()
         │           └─→ confirmed
         │               └─→ (continues below)
         │
         └─→ paymentMethod == 'after_service'
             └─→ pending
                 │
                 ▼
         ┌───────────────┐
         │ pending_admin │  ← ADMIN APPROVAL NEEDED
         └───────────────┘
                 │
                 ├─→ approveBookingByAdmin()
                 │   └─→ approved_by_admin
                 │       │
                 │       ├─→ technicianAcceptBooking()
                 │       │   └─→ technician_accepted
                 │       │       │
                 │       │       ├─→ startService()
                 │       │       │   └─→ service_in_progress
                 │       │       │       │
                 │       │       │       └─→ completeService()
                 │       │       │           └─→ service_completed
                 │       │       │               │
                 │       │       │               └─→ (payment if after_service)
                 │       │       │                   └─→ completed ✅
                 │       │       │
                 │       │       └─→ cancelBooking()
                 │       │           └─→ cancelled ❌
                 │       │
                 │       └─→ technicianRejectBooking()
                 │           └─→ technician_rejected ❌
                 │               └─→ (admin reassigns)
                 │
                 └─→ rejectBookingByAdmin() [NOT FOUND]
                     └─→ rejected_by_admin ❌

TERMINAL STATES:
  ✅ completed
  ❌ cancelled
  ❌ rejected_by_admin
  ❌ technician_rejected
```

---

## 7. SECURITY ANALYSIS

### 7.1 Firestore Security Rules

**Location**: `firestore.rules`

**Bookings Collection Rules**:
```javascript
match /bookings/{bookingId} {
  // READ: Customer, Technician, or Admin
  allow read: if isSignedIn()
    && (resource.data.customerId == request.auth.uid
        || resource.data.technicianId == request.auth.uid
        || isAdmin());

  // CREATE: Customer only, limited initial statuses
  allow create: if isSignedIn()
    && request.resource.data.customerId == request.auth.uid
    && request.resource.data.status in ['pending', 'pending_admin_review', 'awaiting_payment'];

  // UPDATE: BLOCKED - must use Cloud Functions
  allow update: if false;
  
  // DELETE: BLOCKED
  allow delete: if false;
}
```

**✅ SECURITY STRENGTHS**:
1. All status updates go through Cloud Functions
2. Customers cannot modify bookings directly
3. Price manipulation prevented (server-side validation)
4. Technicians cannot assign themselves to bookings
5. Only authorized users can read booking details

**⚠️ SECURITY CONCERNS**:
1. No rate limiting on booking creation (client-side)
2. Idempotency keys are predictable (`BK_${uid}_${timestamp}`)
3. No validation of address data structure

### 7.2 Idempotency Protection

**Collection**: `booking_idempotency`

**Mechanism**:
```typescript
// 24-hour TTL on idempotency records
const expiresAt = Timestamp.fromDate(
  new Date(Date.now() + 24 * 60 * 60 * 1000)
);

// Atomic check + write in transaction
await db.runTransaction(async (transaction) => {
  const idempotencyDoc = await transaction.get(idempotencyRef);
  if (idempotencyDoc.exists) {
    throw new Error(`IDEMPOTENCY_DUPLICATE:${existingBookingId}`);
  }
  transaction.set(bookingsRef, bookingData);
  transaction.set(idempotencyRef, { bookingId, customerId, createdAt });
});
```

**✅ PROTECTION LEVEL**: STRONG
- Prevents duplicate bookings from double-taps
- Prevents retry storms
- 24-hour window prevents stale keys

---

## 8. RACE CONDITIONS & EDGE CASES

### 8.1 Duplicate Booking Prevention

**Scenario**: Customer taps "Confirm" multiple times

**Protection**:
```dart
// Client-side: Submit lock
if (_submitLock || _isProcessing) {
  debugPrint('⚠️ Submit already in progress – ignoring duplicate tap');
  return;
}
_submitLock = true;
```

**Server-side**: Idempotency key check

**✅ STATUS**: PROTECTED

### 8.2 Multiple Technicians Accepting Same Booking

**Scenario**: Admin assigns booking to multiple technicians (error)

**Protection**:
```typescript
// Transaction checks current status
await db.runTransaction(async (t) => {
  const freshDoc = await t.get(bookingRef);
  if (freshBooking.bookingStatus !== 'approved_by_admin') {
    throw new Error('Booking already accepted');
  }
  // Update to technician_accepted
});
```

**✅ STATUS**: PROTECTED (transaction ensures only one accept)

### 8.3 Concurrent Status Updates

**Scenario**: Customer cancels while technician accepts

**Protection**: Firestore transactions + status validation

**✅ STATUS**: PROTECTED

### 8.4 Price Manipulation

**Scenario**: Customer modifies price in client before sending

**Protection**:
```typescript
// Server fetches price from technician_services (source of truth)
const basePrice = serviceData.price || price || 0;
// Client price is ignored if service has price
```

**✅ STATUS**: PROTECTED

### 8.5 Wallet Insufficient Balance

**Scenario**: Customer confirms payment but wallet has insufficient balance

**Protection**: NOT FULLY VISIBLE IN AUDIT

**⚠️ STATUS**: REQUIRES WALLET SYSTEM AUDIT

---

## 9. NOTIFICATION FLOW

### 9.1 Notification Points

**Implemented**:
1. ✅ Admin approves → Technician notified
2. ✅ Technician accepts → Customer notified
3. ✅ Technician rejects → Admin notified
4. ✅ Service starts → Customer notified
5. ✅ Service completes → Customer notified

**Missing**:
1. ❌ Booking created → Admin NOT notified
2. ❌ Payment confirmed → Technician NOT notified (found in code but not verified)
3. ❌ Booking cancelled → Opposite party NOT notified

### 9.2 Notification Helper

**Location**: `functions/src/shared/notification_helper.ts`

**Function**: `sendNotificationToToken()`

**Features**:
- FCM token-based delivery
- Idempotency key support
- Notification persistence in Firestore
- Deep link support

---

## 10. CRITICAL ISSUES SUMMARY

### 🔴 CRITICAL (Blocking)

**1. NO ADMIN APPROVAL UI**
- **Impact**: Bookings stuck in pending state
- **Location**: Admin panel missing booking approval screen
- **Fix Required**: Build admin UI for booking approval/rejection
- **Priority**: P0 - BLOCKING

**2. ADMIN NOT NOTIFIED ON BOOKING CREATION**
- **Impact**: Admin must manually check for new bookings
- **Location**: `createBookingRequest` function
- **Fix Required**: Add FCM notification to all admins after booking creation
- **Priority**: P0 - CRITICAL

### 🟡 HIGH (Important)

**3. STATUS FIELD INCONSISTENCY**
- **Impact**: Potential query bugs, confusion
- **Location**: Throughout codebase
- **Fix Required**: Standardize on 'bookingStatus' or 'status' everywhere
- **Priority**: P1 - HIGH

**4. WALLET DEDUCTION NOT FULLY AUDITED**
- **Impact**: Potential payment bugs
- **Location**: Payment confirmation flow
- **Fix Required**: Deep audit of wallet system
- **Priority**: P1 - HIGH

### 🟢 MEDIUM (Enhancement)

**5. PREDICTABLE IDEMPOTENCY KEYS**
- **Impact**: Theoretical security concern
- **Location**: `BK_${uid}_${timestamp}` format
- **Fix Required**: Use UUID or crypto.randomBytes()
- **Priority**: P2 - MEDIUM

**6. NO ADMIN REJECTION FUNCTION**
- **Impact**: Admin cannot reject bookings
- **Location**: Missing function
- **Fix Required**: Implement `rejectBookingByAdmin` function
- **Priority**: P2 - MEDIUM

---

## 11. RECOMMENDATIONS

### Immediate Actions (P0)

1. **Build Admin Approval UI**
   ```
   - Create booking list screen in admin panel
   - Show pending bookings (status: pending_admin_approval)
   - Add approve/reject buttons
   - Call approveBookingByAdmin Cloud Function
   ```

2. **Add Admin Notification on Booking Creation**
   ```typescript
   // In createBookingRequest after booking creation
   const adminsSnapshot = await db.collection('admins').get();
   for (const adminDoc of adminsSnapshot.docs) {
     const adminData = adminDoc.data();
     if (adminData?.fcmToken) {
       await sendNotificationToToken({
         token: adminData.fcmToken,
         title: 'New Booking Request',
         body: `${customerName} requested ${serviceName}`,
         data: { bookingId, type: 'new_booking' },
       });
     }
   }
   ```

### Short-term Actions (P1)

3. **Standardize Status Field**
   - Choose 'bookingStatus' as standard
   - Update all queries to use 'bookingStatus'
   - Update Booking model to use 'bookingStatus'
   - Add migration script if needed

4. **Audit Wallet System**
   - Trace wallet deduction flow
   - Verify transaction atomicity
   - Check insufficient balance handling
   - Verify rollback on failure

### Medium-term Actions (P2)

5. **Implement Admin Rejection**
   ```typescript
   export const rejectBookingByAdmin = functions
     .region('asia-south1')
     .https.onCall(async (data, context) => {
       // Similar to approveBookingByAdmin
       // Set status to 'rejected_by_admin'
       // Notify customer
     });
   ```

6. **Enhance Idempotency Keys**
   ```typescript
   import { randomBytes } from 'crypto';
   const idempotencyKey = `BK_${randomBytes(16).toString('hex')}`;
   ```

---

## 12. TESTING CHECKLIST

### Manual Testing Required

- [ ] Create booking with "Pay Before Work" mode
- [ ] Create booking with "Pay After Work" mode
- [ ] Verify admin receives notification
- [ ] Admin approves booking
- [ ] Verify technician receives notification
- [ ] Technician accepts booking
- [ ] Verify customer receives notification
- [ ] Technician starts service
- [ ] Technician completes service
- [ ] Customer makes payment (if after_service)
- [ ] Verify booking reaches 'completed' status

### Edge Case Testing

- [ ] Double-tap booking confirmation (idempotency)
- [ ] Cancel booking at each status
- [ ] Technician rejects booking
- [ ] Insufficient wallet balance
- [ ] Network failure during booking creation
- [ ] Multiple technicians assigned to same booking

### Security Testing

- [ ] Attempt to modify booking price from client
- [ ] Attempt to update booking status directly (should fail)
- [ ] Attempt to read other user's bookings (should fail)
- [ ] Attempt to create booking for another customer (should fail)

---

## 13. FILES AUDITED

### Customer App
- `apps/customer_app/lib/core/models/booking.dart`
- `apps/customer_app/lib/core/services/booking_service.dart`
- `apps/customer_app/lib/core/providers/booking_provider.dart`
- `apps/customer_app/lib/features/cart/presentation/checkout_screen.dart`

### Technician App
- `apps/technician_app/lib/core/services/booking_service.dart`
- `apps/technician_app/lib/features/job_requests/job_requests_screen.dart`
- `apps/technician_app/lib/screens/job_details_screen.dart`

### Cloud Functions
- `functions/src/booking/unified_booking_lifecycle.ts`
- `functions/src/booking/new_booking_flow.ts`
- `functions/src/shared/notification_helper.ts`
- `functions/src/shared/booking_state_machine.ts`

### Security
- `firestore.rules`

---

## 14. CONCLUSION

The HomeFix booking system has a **solid foundation** with strong security measures, idempotency protection, and transaction-based state management. However, there are **critical gaps** in the admin approval flow that block the booking lifecycle from completing.

**Most Critical Fix**: Implement admin approval UI and notification system to unblock the booking flow.

**Overall Security**: STRONG - No major vulnerabilities found  
**Overall Architecture**: GOOD - Well-structured with clear separation of concerns  
**Overall Completeness**: INCOMPLETE - Missing admin UI and some notification flows

---

**End of Audit Report**
