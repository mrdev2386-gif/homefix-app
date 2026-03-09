# Booking Lifecycle - Quick Reference

## 📋 Correct Booking Flow

### Customer Creates Booking
```typescript
// Customer selects technician from list and creates booking
bookings/{bookingId}:
  customerId: "customer_uid"
  technicianId: "technician_uid"  // Already set by customer
  serviceId: "service_id"
  serviceName: "AC Repair"
  price: 500
  district: "Mumbai"
  status: "pending_admin_approval"
  paymentStatus: "pending"
  createdAt: serverTimestamp()
```

### Automatic Admin Notification
```typescript
// Trigger: notifyAdminNewBooking (Firestore onCreate)
// Sends push notification to all admins
Title: "New Booking Request"
Body: "A customer has booked a service. Please review and approve."
Data: {
  bookingId,
  customerName,
  technicianName,
  serviceName
}
```

### Admin Reviews Booking
Admin panel displays:
- Customer: name, phone, district, address
- Technician: name, experience, skills, rating
- Service: name, price, description

### Admin Approves
```typescript
// Function: approveBookingByAdmin
// Validates technician availability before approval
await functions.httpsCallable('approveBookingByAdmin')({
  bookingId: "booking_123"
});

// Validates:
// - verificationStatus == "approved"
// - profileCompletion == 100
// - isAvailable == true

// Updates:
status: "waiting_technician_acceptance"
approvedAt: serverTimestamp()
approvedBy: "admin_uid"

// Notification to technician:
"New Booking Assigned - Please accept or reject"
```

### Admin Rejects
```typescript
// Function: rejectBookingByAdmin
await functions.httpsCallable('rejectBookingByAdmin')({
  bookingId: "booking_123",
  rejectionReason: "Invalid service request"
});

// Updates:
status: "rejected_by_admin"
rejectedAt: serverTimestamp()
rejectedBy: "admin_uid"
rejectionReason: "Invalid service request"

// Notification to customer:
"Booking Rejected - Please try another technician or service"
```

### Technician Accepts
```typescript
// Function: technicianAcceptBooking
status: "accepted"
acceptedAt: serverTimestamp()

// Technician availability updated:
technicians/{technicianId}:
  isAvailable: false
```

### Technician Starts Job
```typescript
// Function: technicianStartJob
status: "in_progress"
jobStartedAt: serverTimestamp()
```

### Technician Completes
```typescript
// Function: completeBooking
status: "completed"
completedAt: serverTimestamp()
paymentStatus: "pending_customer_payment"

// Technician availability updated:
technicians/{technicianId}:
  isAvailable: true
  totalJobs: increment(1)
```

### Customer Makes Payment
```typescript
// Function: verifyBookingPayment
await functions.httpsCallable('verifyBookingPayment')({
  bookingId: "booking_123",
  paymentId: "pay_razorpay123",
  paymentGatewayResponse: {
    razorpay_order_id: "order_123",
    razorpay_payment_id: "pay_123",
    razorpay_signature: "signature_hash"
  }
});

// Validates:
// - Payment signature
// - Payment amount matches booking
// - Payment status is successful
// - No duplicate payment

// Updates:
bookings/{bookingId}:
  paymentStatus: "paid"
  paidAt: serverTimestamp()
  transactionId: paymentId

technicians/{technicianId}:
  walletBalance: increment(bookingAmount)
  totalEarnings: increment(bookingAmount)

// Notifications:
// Customer: "Payment Successful"
// Technician: "Payment Received - ₹{amount}"
```

## 🔑 Key Changes

### ✅ What Changed:
1. **No automatic assignment** - Customer selects technician
2. **technicianId set at creation** - Not assigned later
3. **Admin notification trigger** - Automatic on booking creation
4. **Admin must approve** - Manual review before work begins
5. **Admin can reject** - With rejection reason sent to customer
6. **Technician availability validation** - Checks verification, profile completion, and availability
7. **Automatic availability updates** - Technician marked unavailable when accepting, available when completing/cancelling
8. **Technician rejection** - Goes back to pending_admin_approval
9. **Secure payment verification** - Server-side Razorpay integration with duplicate protection
10. **Automatic earnings credit** - Technician wallet updated on payment verification

### ❌ Removed:
- Automatic technician matching logic
- `assignedTechnicianId` field (use `technicianId`)
- Auto-assignment algorithms

## 🚀 Deployment

```powershell
cd functions
npm run build
firebase deploy --only functions:notifyAdminNewBooking,functions:approveBookingByAdmin,functions:rejectBookingByAdmin,functions:technicianAcceptBooking,functions:technicianStartJob,functions:completeBooking,functions:cancelBooking,functions:technicianRejectBooking,functions:verifyBookingPayment,functions:refundBookingPayment
```

## 📊 Booking Document Structure

```typescript
{
  bookingId: string;
  customerId: string;
  technicianId: string;  // Set by customer at creation
  serviceId: string;
  serviceName: string;
  price: number;
  district: string;
  
  status: 'pending_admin_approval' | 'rejected_by_admin' | 'waiting_technician_acceptance' | 
          'accepted' | 'in_progress' | 'completed' | 'cancelled';
  
  paymentStatus: 'pending' | 'pending_customer_payment' | 'paid' | 'refunded';
  
  createdAt: Timestamp;
  approvedAt?: Timestamp;
  approvedBy?: string;
  acceptedAt?: Timestamp;
  jobStartedAt?: Timestamp;
  completedAt?: Timestamp;
  cancelledAt?: Timestamp;
  cancelledBy?: string;
  cancellationReason?: string;
  rejectedBy?: string;
  rejectedAt?: Timestamp;
  rejectionReason?: string;
  
  // Payment fields
  paidAt?: Timestamp;
  transactionId?: string;
  paymentMethod?: string;
  
  // Refund fields
  refundedAt?: Timestamp;
  refundReason?: string;
  refundedBy?: string;
  refundId?: string;
}
```

## 🔐 Security Rules

```javascript
// Booking creation - customer sets technicianId
allow create: if isAuthenticated() 
  && request.resource.data.customerId == request.auth.uid
  && request.resource.data.status == 'pending_admin_approval';

// All updates through Cloud Functions only
allow update: if false;
```

## 📱 Admin Panel Integration

```typescript
// Fetch pending bookings
const pendingBookings = await db
  .collection('bookings')
  .where('status', '==', 'pending_admin_approval')
  .orderBy('createdAt', 'desc')
  .get();

// Display booking details
for (const doc of pendingBookings.docs) {
  const booking = doc.data();
  
  // Fetch related data
  const customer = await db.collection('customers').doc(booking.customerId).get();
  const technician = await db.collection('technicians').doc(booking.technicianId).get();
  
  // Show in UI for admin review
}

// Approve booking
await approveBooking(bookingId);

// Reject booking
await rejectBooking(bookingId, "Invalid service request");
```

## 🔒 Technician Document Structure

```typescript
{
  technicianId: string;
  name: string;
  verificationStatus: 'pending' | 'approved' | 'rejected';
  profileCompletion: number;  // 0-100
  isAvailable: boolean;       // Managed by Cloud Functions
  totalJobs: number;
  avgRating: number;
  skills: string[];
  experience: number;
  
  // Earnings tracking
  walletBalance: number;      // Current balance
  totalEarnings: number;      // Lifetime earnings
}
```

### Availability State Management:
- ✅ `isAvailable: true` - Technician can accept new bookings
- ❌ `isAvailable: false` - Technician has active booking
- 🔒 Only Cloud Functions can update this field

### Earnings Management:
- 💰 `walletBalance` - Updated on payment verification
- 📊 `totalEarnings` - Lifetime earnings tracker
- 🔒 Only Cloud Functions can update these fields
