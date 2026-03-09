# Secure Booking Lifecycle Cloud Functions

## 🔐 Overview

This document explains the secure booking lifecycle management system implemented through Firebase Cloud Functions. All booking status updates are handled exclusively through backend functions to prevent client-side manipulation and ensure data integrity.

---

## 🎯 Security Architecture

### Why Cloud Functions Only?

**Problem:** Firestore Security Rules block all direct booking updates to prevent:
- ❌ Status manipulation (customers marking bookings as completed)
- ❌ Payment fraud (changing payment status)
- ❌ Assignment manipulation (technicians self-assigning bookings)
- ❌ Price manipulation (changing final amounts)

**Solution:** All booking lifecycle operations go through validated Cloud Functions with:
- ✅ Authentication checks
- ✅ Role-based authorization
- ✅ Status transition validation
- ✅ Audit trail logging
- ✅ Push notification triggers

---

## 📊 Booking Status Flow

```
Customer Selects Technician & Creates Booking
         ↓
[pending_admin_approval]
         ↓
    (technicianId already set)
         ↓
Admin Notified → notifyAdminNewBooking (trigger)
         ↓
Admin Reviews & Approves → approveBookingByAdmin()
         ↓
[waiting_technician_acceptance]
         ↓
Technician Accepts → technicianAcceptBooking()
         ↓
[accepted]
         ↓
Technician Starts → technicianStartJob()
         ↓
[in_progress]
         ↓
Technician Completes → completeBooking()
         ↓
[completed]

(Can be cancelled at any stage before completion)
(Technician can reject → back to pending_admin_approval)
```

### Key Points:
- ✅ Customer selects specific technician when booking
- ✅ `technicianId` is set at booking creation (NOT auto-assigned)
- ✅ Admin must review and approve before technician can start
- ✅ Admin receives push notification for every new booking
- ✅ No automatic technician assignment logic

---

## 🔧 Cloud Functions Reference

### 0️⃣ Admin Notification Trigger

**Function Name:** `notifyAdminNewBooking`

**Type:** Firestore Trigger (automatic)

**Purpose:** Automatically notifies all admins when a new booking is created

**Trigger:** `bookings/{bookingId}` document created

**Behavior:**
1. Fetches customer details from `customers/{customerId}`
2. Fetches technician details from `technicians/{technicianId}`
3. Sends push notification to all admin devices

**Notification:**
- 📢 Title: "New Booking Request"
- 📢 Body: "A customer has booked a service. Please review and approve."
- 📢 Data: `bookingId`, `customerName`, `technicianName`, `serviceName`

**Admin Action Required:**
- Review booking details in admin panel
- Verify customer and technician information
- Approve or reject the booking

---

### 1️⃣ Admin Approve Booking

**Function Name:** `approveBookingByAdmin`

**Purpose:** Admin approves a pending booking and assigns it to a technician

**Input:**
```typescript
{
  bookingId: string
}
```

**Authorization:**
- ✅ Caller must exist in `/admins` collection
- ❌ Regular users cannot call this function

**Validation:**
- Booking must exist
- Status must be `pending_admin_approval`
- Cannot approve cancelled bookings

**Firestore Updates:**
```typescript
bookings/{bookingId}:
  status: "waiting_technician_acceptance"
  approvedAt: serverTimestamp()
  approvedBy: adminUid
```

**Notifications:**
- 📱 Technician receives "New Booking Request" notification

**Response:**
```typescript
{
  success: true,
  status: "waiting_technician_acceptance"
}
```

**Error Codes:**
- `unauthenticated`: User not logged in
- `permission-denied`: User is not an admin
- `not-found`: Booking doesn't exist
- `failed-precondition`: Invalid booking status

**Example Usage (Flutter):**
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('approveBookingByAdmin')
  .call({'bookingId': bookingId});
```

---

### 2️⃣ Technician Accept Booking

**Function Name:** `technicianAcceptBooking`

**Purpose:** Assigned technician accepts the booking request

**Input:**
```typescript
{
  bookingId: string
}
```

**Authorization:**
- ✅ Caller must be the assigned technician (`assignedTechnicianId`)
- ❌ Other technicians cannot accept

**Validation:**
- Booking must exist
- Status must be `waiting_technician_acceptance`
- Caller must match `assignedTechnicianId`

**Firestore Updates:**
```typescript
bookings/{bookingId}:
  status: "accepted"
  acceptedAt: serverTimestamp()
```

**Notifications:**
- 📱 Customer receives "Booking Accepted" notification

**Response:**
```typescript
{
  success: true,
  status: "accepted"
}
```

**Error Codes:**
- `unauthenticated`: User not logged in
- `permission-denied`: Not the assigned technician
- `not-found`: Booking doesn't exist
- `failed-precondition`: Invalid booking status

**Example Usage (Flutter):**
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('technicianAcceptBooking')
  .call({'bookingId': bookingId});
```

---

### 3️⃣ Technician Start Job

**Function Name:** `technicianStartJob`

**Purpose:** Technician marks job as started when arriving at customer location

**Input:**
```typescript
{
  bookingId: string
}
```

**Authorization:**
- ✅ Caller must be the assigned technician
- ❌ Other users cannot start the job

**Validation:**
- Booking must exist
- Status must be `accepted`
- Caller must match `assignedTechnicianId`

**Firestore Updates:**
```typescript
bookings/{bookingId}:
  status: "in_progress"
  jobStartedAt: serverTimestamp()
```

**Notifications:**
- 📱 Customer receives "Job Started" notification

**Response:**
```typescript
{
  success: true,
  status: "in_progress"
}
```

**Error Codes:**
- `unauthenticated`: User not logged in
- `permission-denied`: Not the assigned technician
- `not-found`: Booking doesn't exist
- `failed-precondition`: Invalid booking status

**Example Usage (Flutter):**
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('technicianStartJob')
  .call({'bookingId': bookingId});
```

---

### 4️⃣ Complete Booking

**Function Name:** `completeBooking`

**Purpose:** Technician marks job as completed after finishing work

**Input:**
```typescript
{
  bookingId: string
}
```

**Authorization:**
- ✅ Caller must be the assigned technician
- ❌ Other users cannot complete the booking

**Validation:**
- Booking must exist
- Status must be `in_progress`
- Caller must match `assignedTechnicianId`

**Firestore Updates:**
```typescript
bookings/{bookingId}:
  status: "completed"
  completedAt: serverTimestamp()
  paymentStatus: "pending_customer_payment"

technicians/{technicianId}:
  totalJobs: increment(1)
```

**Notifications:**
- 📱 Customer receives "Job Completed - Please Pay & Review" notification

**Response:**
```typescript
{
  success: true,
  status: "completed"
}
```

**Error Codes:**
- `unauthenticated`: User not logged in
- `permission-denied`: Not the assigned technician
- `not-found`: Booking doesn't exist
- `failed-precondition`: Invalid booking status

**Example Usage (Flutter):**
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('completeBooking')
  .call({'bookingId': bookingId});
```

---

### 5️⃣ Cancel Booking

**Function Name:** `cancelBooking`

**Purpose:** Cancel a booking (by customer, technician, or admin)

**Input:**
```typescript
{
  bookingId: string,
  reason?: string
}
```

**Authorization:**
- ✅ Customer who created the booking
- ✅ Assigned technician
- ✅ Admin
- ❌ Other users cannot cancel

**Validation:**
- Booking must exist
- Status must NOT be `completed`
- Caller must be customer, technician, or admin

**Firestore Updates:**
```typescript
bookings/{bookingId}:
  status: "cancelled"
  cancelledAt: serverTimestamp()
  cancelledBy: callerUid
  cancellationReason: reason || "No reason provided"
```

**Notifications:**
- 📱 Other party receives "Booking Cancelled" notification
- If admin cancels: Both customer and technician notified

**Response:**
```typescript
{
  success: true,
  status: "cancelled"
}
```

**Error Codes:**
- `unauthenticated`: User not logged in
- `permission-denied`: User not authorized to cancel
- `not-found`: Booking doesn't exist
- `failed-precondition`: Cannot cancel completed booking

**Example Usage (Flutter):**
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('cancelBooking')
  .call({
    'bookingId': bookingId,
    'reason': 'Customer unavailable'
  });
```

---

### 6️⃣ Technician Reject Booking

**Function Name:** `technicianRejectBooking`

**Purpose:** Technician rejects a booking request (before accepting)

**Input:**
```typescript
{
  bookingId: string,
  reason?: string
}
```

**Authorization:**
- ✅ Caller must be the assigned technician
- ❌ Other users cannot reject

**Validation:**
- Booking must exist
- Status must be `waiting_technician_acceptance`
- Caller must match `assignedTechnicianId`

**Firestore Updates:**
```typescript
bookings/{bookingId}:
  status: "pending_admin_approval"  // Back to pending
  assignedTechnicianId: deleted
  rejectedBy: technicianUid
  rejectedAt: serverTimestamp()
  rejectionReason: reason || "Technician unavailable"
```

**Notifications:**
- 📱 Customer receives "Finding Another Technician" notification

**Response:**
```typescript
{
  success: true,
  status: "pending_admin_approval"
}
```

**Error Codes:**
- `unauthenticated`: User not logged in
- `permission-denied`: Not the assigned technician
- `not-found`: Booking doesn't exist
- `failed-precondition`: Invalid booking status

**Example Usage (Flutter):**
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('technicianRejectBooking')
  .call({
    'bookingId': bookingId,
    'reason': 'Schedule conflict'
  });
```

---

## 📱 Flutter Integration

### Setup Firebase Functions

```dart
// lib/core/services/booking_service.dart
import 'package:cloud_functions/cloud_functions.dart';

class BookingService {
  final _functions = FirebaseFunctions.instance;

  // Admin approve booking
  Future<void> approveBooking(String bookingId) async {
    try {
      await _functions
        .httpsCallable('approveBookingByAdmin')
        .call({'bookingId': bookingId});
    } on FirebaseFunctionsException catch (e) {
      throw _handleError(e);
    }
  }

  // Technician accept booking
  Future<void> acceptBooking(String bookingId) async {
    try {
      await _functions
        .httpsCallable('technicianAcceptBooking')
        .call({'bookingId': bookingId});
    } on FirebaseFunctionsException catch (e) {
      throw _handleError(e);
    }
  }

  // Technician start job
  Future<void> startJob(String bookingId) async {
    try {
      await _functions
        .httpsCallable('technicianStartJob')
        .call({'bookingId': bookingId});
    } on FirebaseFunctionsException catch (e) {
      throw _handleError(e);
    }
  }

  // Complete booking
  Future<void> completeBooking(String bookingId) async {
    try {
      await _functions
        .httpsCallable('completeBooking')
        .call({'bookingId': bookingId});
    } on FirebaseFunctionsException catch (e) {
      throw _handleError(e);
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _functions
        .httpsCallable('cancelBooking')
        .call({
          'bookingId': bookingId,
          'reason': reason,
        });
    } on FirebaseFunctionsException catch (e) {
      throw _handleError(e);
    }
  }

  // Reject booking
  Future<void> rejectBooking(String bookingId, String reason) async {
    try {
      await _functions
        .httpsCallable('technicianRejectBooking')
        .call({
          'bookingId': bookingId,
          'reason': reason,
        });
    } on FirebaseFunctionsException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please log in to continue';
      case 'permission-denied':
        return 'You do not have permission to perform this action';
      case 'not-found':
        return 'Booking not found';
      case 'failed-precondition':
        return e.message ?? 'Invalid booking status';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
```

---

## 🧪 Testing Guide

### Test 1: Admin Approval Flow

```javascript
// Admin approves booking
const result = await admin.firestore()
  .collection('bookings')
  .doc(bookingId)
  .get();

console.log('Before:', result.data().status); // pending_admin_approval

await approveBookingByAdmin({ bookingId });

const updated = await admin.firestore()
  .collection('bookings')
  .doc(bookingId)
  .get();

console.log('After:', updated.data().status); // waiting_technician_acceptance
console.log('Approved by:', updated.data().approvedBy);
```

### Test 2: Technician Accept Flow

```javascript
// Technician accepts booking
await technicianAcceptBooking({ bookingId });

const booking = await admin.firestore()
  .collection('bookings')
  .doc(bookingId)
  .get();

console.log('Status:', booking.data().status); // accepted
console.log('Accepted at:', booking.data().acceptedAt);
```

### Test 3: Complete Booking Flow

```javascript
// Start job
await technicianStartJob({ bookingId });

// Complete job
await completeBooking({ bookingId });

const booking = await admin.firestore()
  .collection('bookings')
  .doc(bookingId)
  .get();

console.log('Status:', booking.data().status); // completed
console.log('Payment Status:', booking.data().paymentStatus); // pending_customer_payment

// Check technician stats updated
const tech = await admin.firestore()
  .collection('technicians')
  .doc(technicianId)
  .get();

console.log('Total Jobs:', tech.data().totalJobs); // incremented
```

### Test 4: Security Tests

```javascript
// ❌ Should FAIL: Customer trying to approve booking
try {
  await approveBookingByAdmin({ bookingId });
} catch (e) {
  console.log('Expected error:', e.code); // permission-denied
}

// ❌ Should FAIL: Wrong technician accepting booking
try {
  await technicianAcceptBooking({ bookingId });
} catch (e) {
  console.log('Expected error:', e.code); // permission-denied
}

// ❌ Should FAIL: Completing booking without starting
try {
  await completeBooking({ bookingId });
} catch (e) {
  console.log('Expected error:', e.code); // failed-precondition
}
```

---

## 🚀 Deployment

### 1. Build Functions
```powershell
cd C:\Users\yash\projects\homefix\functions
npm run build
```

### 2. Deploy Functions
```powershell
firebase deploy --only functions:approveBookingByAdmin,functions:technicianAcceptBooking,functions:technicianStartJob,functions:completeBooking,functions:cancelBooking,functions:technicianRejectBooking
```

### 3. Verify Deployment
```powershell
firebase functions:list
```

---

## 📊 Firestore Structure

### Booking Document Fields

```typescript
{
  bookingId: string;
  customerId: string;
  assignedTechnicianId?: string;
  serviceId: string;
  serviceName: string;
  
  // Status tracking
  status: 'pending_admin_approval' | 'waiting_technician_acceptance' | 
          'accepted' | 'in_progress' | 'completed' | 'cancelled';
  
  // Payment tracking
  paymentStatus: 'pending' | 'pending_customer_payment' | 'paid' | 'refunded';
  finalAmount: number;
  
  // Timestamps
  createdAt: Timestamp;
  approvedAt?: Timestamp;
  acceptedAt?: Timestamp;
  jobStartedAt?: Timestamp;
  completedAt?: Timestamp;
  cancelledAt?: Timestamp;
  
  // Audit trail
  approvedBy?: string;
  cancelledBy?: string;
  cancellationReason?: string;
  rejectedBy?: string;
  rejectionReason?: string;
}
```

---

## 🔔 Notification Triggers

Each function automatically sends push notifications:

| Function | Recipient | Title | Body |
|----------|-----------|-------|------|
| `approveBookingByAdmin` | Technician | "New Booking Request" | "You have a new booking request for {service}" |
| `technicianAcceptBooking` | Customer | "Booking Accepted" | "Your booking has been accepted by the technician" |
| `technicianStartJob` | Customer | "Job Started" | "Your technician has started working on your service" |
| `completeBooking` | Customer | "Job Completed" | "Please make payment and leave a review" |
| `cancelBooking` | Other Party | "Booking Cancelled" | "{Actor} has cancelled the booking" |
| `technicianRejectBooking` | Customer | "Booking Update" | "Finding another technician for you" |

---

## 🐛 Troubleshooting

### Issue: "permission-denied" error
**Cause:** User not authorized for the action
**Solution:** 
- For admin functions: Ensure user exists in `/admins` collection
- For technician functions: Verify `assignedTechnicianId` matches caller

### Issue: "failed-precondition" error
**Cause:** Invalid status transition
**Solution:** Check current booking status matches required status

### Issue: Notifications not received
**Cause:** FCM token not saved or invalid
**Solution:** Ensure `saveFcmToken` is called after login

### Issue: Function timeout
**Cause:** Firestore query taking too long
**Solution:** Check Firestore indexes are deployed

---

## 📝 Best Practices

1. **Always use Cloud Functions** - Never update booking status directly from client
2. **Handle errors gracefully** - Show user-friendly error messages
3. **Show loading states** - Functions may take 1-3 seconds
4. **Refresh UI after success** - Listen to Firestore streams for real-time updates
5. **Log all actions** - Use activity logs for audit trail
6. **Test all flows** - Verify each status transition works

---

## 🔗 Related Documentation

- [Firestore Security Rules](FIRESTORE_SECURITY_RULES.md)
- [Dashboard Access Guard](DASHBOARD_ACCESS_GUARD.md)
- [Push Notifications Guide](PUSH_NOTIFICATION_SYSTEM_GUIDE.md)
- [Admin Panel Guide](ADMIN_PANEL_QUICK_GUIDE.md)

---

## 📞 Support

For issues or questions, contact: **9508322397**

---

**Last Updated:** 2026-01-XX
**Version:** 1.0.0
