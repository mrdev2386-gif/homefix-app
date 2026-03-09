# Firestore Security Rules - Complete Implementation Guide

## 🔐 Overview

This document explains the comprehensive Firestore Security Rules implemented for HomeFix platform. These rules enforce strict access control to prevent unauthorized data access and manipulation.

---

## 🎯 Security Principles

1. **Principle of Least Privilege**: Users can only access data they need
2. **Defense in Depth**: Multiple layers of validation
3. **Immutability**: Critical fields cannot be modified by users
4. **Audit Trail**: Protected fields track who/when changes occurred
5. **Zero Trust**: All requests are validated, no implicit trust

---

## 📋 Collection-Level Security

### 1. **Admins Collection** (`/admins/{adminId}`)

**Access Control:**
- ✅ Read: Only admins
- ❌ Write: No one (managed by super admin manually)

**Purpose:** Prevent privilege escalation attacks

---

### 2. **Technicians Collection** (`/technicians/{technicianId}`)

**Protected Fields (Admin-Only):**
```
- verificationStatus
- profileCompletion
- approvedAt, approvedBy
- rejectionReason
- isApproved, isKycComplete
- kycSubmittedAt
- isSuspended, suspendedAt, suspendedBy, suspensionReason
- avgRating, totalRatings, totalJobs
- walletBalance
```

**Access Control:**
- ✅ Read: Owner or Admin
- ✅ Create: Owner (during signup)
- ✅ Update: Owner (non-protected fields only)
- ✅ Update: Admin (all fields)
- ❌ Delete: No one

**Security Features:**
- Prevents self-approval: `verificationStatus` cannot be set to "approved" by technician
- Prevents rating manipulation: `avgRating`, `totalRatings` are read-only
- Prevents wallet manipulation: `walletBalance` is admin-only

**Example Attack Prevented:**
```javascript
// ❌ BLOCKED: Technician trying to self-approve
await technicianRef.update({
  verificationStatus: 'approved',
  isApproved: true
});
// Error: Missing or insufficient permissions
```

---

### 3. **Technician Services Collection** (`/technician_services/{serviceId}`)

**Protected Fields (Admin-Only):**
```
- status
- approvedAt, approvedBy
- rejectedAt, rejectedBy
- rejectionReason
- moderationNotes
```

**Access Control:**
- ✅ Read: Anyone (if approved) OR Owner OR Admin
- ✅ Create: Technician (status must be "pending")
- ✅ Update: Owner (non-protected fields only)
- ✅ Update: Admin (all fields)
- ✅ Delete: Owner (if pending/rejected) OR Admin

**Security Features:**
- Prevents self-approval: `status` cannot be set to "approved" by technician
- Enforces moderation workflow: New services default to "pending"
- Protects moderation history: `rejectionReason`, `moderationNotes` are admin-only

**Example Attack Prevented:**
```javascript
// ❌ BLOCKED: Technician trying to self-approve service
await serviceRef.update({
  status: 'approved',
  approvedAt: Timestamp.now()
});
// Error: Missing or insufficient permissions
```

---

### 4. **Customers Collection** (`/customers/{customerId}`)

**Protected Fields (Admin/Cloud Functions Only):**
```
- walletBalance
- referralCode
- referralRewardClaimed
- isSuspended, suspendedAt, suspensionReason
```

**Access Control:**
- ✅ Read: Owner or Admin
- ✅ Create: Owner
- ✅ Update: Owner (non-protected fields only)
- ✅ Update: Admin (all fields)
- ❌ Delete: No one

**Subcollections:**

**`/addresses/{addressId}`**
- ✅ Read/Write: Owner only

**`/payment_methods/{methodId}`**
- ✅ Read/Write: Owner only

**`/wallet_transactions/{transactionId}`**
- ✅ Read: Owner only
- ❌ Write: No one (Cloud Functions only)

**Security Features:**
- Prevents wallet manipulation: `walletBalance` is read-only
- Prevents referral fraud: `referralCode`, `referralRewardClaimed` are protected
- Immutable transactions: Wallet history cannot be modified

**Example Attack Prevented:**
```javascript
// ❌ BLOCKED: Customer trying to add wallet balance
await customerRef.update({
  walletBalance: 10000
});
// Error: Missing or insufficient permissions
```

---

### 5. **Bookings Collection** (`/bookings/{bookingId}`)

**Protected Fields (Cloud Functions Only):**
```
- status
- paymentStatus
- adminApproval
- finalAmount, refundAmount
- cancelledBy, cancellationReason
- completedAt, startedAt
```

**Access Control:**
- ✅ Read: Customer OR Assigned Technician OR Admin
- ✅ Create: Customer (status must be "pending")
- ❌ Update: No one (must use Cloud Functions)
- ❌ Delete: No one

**Security Features:**
- **CRITICAL**: Booking status lifecycle is 100% controlled by Cloud Functions
- Prevents status manipulation: No direct updates allowed
- Prevents payment fraud: `finalAmount`, `paymentStatus` are immutable
- Audit trail: `cancelledBy`, `completedAt` tracked by system

**Example Attack Prevented:**
```javascript
// ❌ BLOCKED: Customer trying to mark booking as completed
await bookingRef.update({
  status: 'completed',
  completedAt: Timestamp.now()
});
// Error: Missing or insufficient permissions

// ❌ BLOCKED: Technician trying to change payment status
await bookingRef.update({
  paymentStatus: 'paid'
});
// Error: Missing or insufficient permissions
```

**Required Cloud Functions:**
```
- acceptBooking(bookingId, technicianId)
- rejectBooking(bookingId, technicianId)
- startBooking(bookingId, technicianId)
- completeBooking(bookingId, technicianId)
- cancelBooking(bookingId, userId, reason)
```

---

### 6. **Services Collection** (`/services/{serviceId}`)

**Access Control:**
- ✅ Read: Anyone
- ✅ Write: Admin only

**Purpose:** Service catalog is managed by admins

---

### 7. **Categories Collection** (`/categories/{categoryId}`)

**Access Control:**
- ✅ Read: Anyone
- ✅ Write: Admin only

**Purpose:** Category taxonomy is managed by admins

---

### 8. **Reviews Collection** (`/reviews/{reviewId}`)

**Access Control:**
- ✅ Read: Anyone
- ✅ Create: Customer (for their bookings)
- ❌ Update: No one (immutable)
- ❌ Delete: No one

**Security Features:**
- Reviews are immutable after creation
- Prevents review manipulation
- Maintains review integrity

---

### 9. **Coupons Collection** (`/coupons/{couponId}`)

**Access Control:**
- ✅ Read: Anyone (if active)
- ✅ Write: Admin only

**Purpose:** Prevents coupon fraud

---

### 10. **Notifications Collection** (`/notifications/{notificationId}`)

**Access Control:**
- ✅ Read: Owner only
- ✅ Update: Owner (only `isRead` field)
- ❌ Create/Delete: No one (Cloud Functions only)

**Security Features:**
- Users can only mark their own notifications as read
- Prevents notification spam

---

### 11. **Support Tickets Collection** (`/support_tickets/{ticketId}`)

**Access Control:**
- ✅ Read: Owner or Admin
- ✅ Create: Owner
- ✅ Update: Admin only
- ❌ Delete: No one

**Purpose:** Maintains support ticket history

---

### 12. **Referrals Collection** (`/referrals/{referralId}`)

**Access Control:**
- ✅ Read: Referrer or Referred User
- ❌ Write: No one (Cloud Functions only)

**Security Features:**
- Prevents referral fraud
- Ensures reward integrity

---

### 13. **Disputes Collection** (`/disputes/{disputeId}`)

**Access Control:**
- ✅ Read: Customer OR Technician OR Admin
- ✅ Create: Customer or Technician
- ✅ Update: Admin only
- ❌ Delete: No one

**Purpose:** Maintains dispute resolution history

---

### 14. **Custom Service Requests Collection** (`/custom_service_requests/{requestId}`)

**Access Control:**
- ✅ Read: Customer (own) OR Technicians (all)
- ✅ Create: Customer
- ❌ Update: No one (Cloud Functions only)
- ✅ Delete: Customer (if pending)

**Purpose:** Allows customers to request custom services

---

## 🛡️ Helper Functions

### `isAuthenticated()`
Checks if user is logged in

### `isAdmin()`
Checks if user exists in `/admins` collection

### `isOwner(userId)`
Checks if authenticated user owns the document

### `isFieldModified(field)`
Checks if specific field is being changed

### `isProtectedFieldModified(protectedFields)`
Checks if any protected field is being modified

---

## 🚀 Deployment

### Deploy Rules
```powershell
cd C:\Users\yash\projects\homefix
firebase deploy --only firestore:rules
```

### Verify Deployment
```powershell
firebase firestore:rules:get
```

---

## 🧪 Testing Security Rules

### Test 1: Technician Self-Approval Attack
```javascript
// Should FAIL
const technicianRef = db.collection('technicians').doc(technicianId);
await technicianRef.update({
  verificationStatus: 'approved',
  isApproved: true
});
// Expected: Error - Missing or insufficient permissions
```

### Test 2: Service Self-Approval Attack
```javascript
// Should FAIL
const serviceRef = db.collection('technician_services').doc(serviceId);
await serviceRef.update({
  status: 'approved'
});
// Expected: Error - Missing or insufficient permissions
```

### Test 3: Wallet Balance Manipulation
```javascript
// Should FAIL
const customerRef = db.collection('customers').doc(customerId);
await customerRef.update({
  walletBalance: 10000
});
// Expected: Error - Missing or insufficient permissions
```

### Test 4: Booking Status Manipulation
```javascript
// Should FAIL
const bookingRef = db.collection('bookings').doc(bookingId);
await bookingRef.update({
  status: 'completed'
});
// Expected: Error - Missing or insufficient permissions
```

### Test 5: Review Modification
```javascript
// Should FAIL
const reviewRef = db.collection('reviews').doc(reviewId);
await reviewRef.update({
  rating: 5
});
// Expected: Error - Missing or insufficient permissions
```

---

## 🔧 Required Cloud Functions

To support the security rules, implement these Cloud Functions:

### Booking Management
```javascript
exports.acceptBooking = functions.https.onCall(async (data, context) => {
  // Validate technician
  // Update booking status to 'accepted'
  // Assign technician
  // Send notification
});

exports.startBooking = functions.https.onCall(async (data, context) => {
  // Validate technician is assigned
  // Update status to 'in_progress'
  // Set startedAt timestamp
});

exports.completeBooking = functions.https.onCall(async (data, context) => {
  // Validate technician
  // Update status to 'completed'
  // Set completedAt timestamp
  // Process payment
});

exports.cancelBooking = functions.https.onCall(async (data, context) => {
  // Validate user
  // Update status to 'cancelled'
  // Set cancelledBy and cancellationReason
  // Process refund if applicable
});
```

### Wallet Management
```javascript
exports.addWalletBalance = functions.https.onCall(async (data, context) => {
  // Validate payment
  // Update walletBalance
  // Create wallet_transaction record
});

exports.deductWalletBalance = functions.https.onCall(async (data, context) => {
  // Validate sufficient balance
  // Update walletBalance
  // Create wallet_transaction record
});
```

### Referral Management
```javascript
exports.processReferral = functions.firestore
  .document('customers/{customerId}')
  .onCreate(async (snap, context) => {
    // Check if referred by someone
    // Create referral record
    // Credit reward to referrer
  });
```

---

## 📊 Security Audit Checklist

- [ ] Technicians cannot self-approve
- [ ] Services cannot be self-approved
- [ ] Wallet balance cannot be manipulated
- [ ] Booking status requires Cloud Functions
- [ ] Reviews are immutable
- [ ] Referral rewards are protected
- [ ] Admin collection is read-only
- [ ] Wallet transactions are immutable
- [ ] Payment status cannot be changed by users
- [ ] Ratings cannot be manipulated
- [ ] Coupons are admin-managed
- [ ] Notifications are system-generated

---

## 🐛 Troubleshooting

### Issue: "Missing or insufficient permissions"
**Cause:** User trying to modify protected field
**Solution:** Use Cloud Function for that operation

### Issue: Admin cannot update documents
**Cause:** Admin document not in `/admins` collection
**Solution:** Add admin UID to `/admins/{uid}` collection

### Issue: Booking updates failing
**Cause:** Direct updates are blocked
**Solution:** Use Cloud Functions (acceptBooking, startBooking, etc.)

---

## 📝 Best Practices

1. **Never bypass security rules** - Always use Cloud Functions for protected operations
2. **Test rules thoroughly** - Use Firebase Emulator Suite
3. **Monitor rule violations** - Check Firebase Console for denied requests
4. **Keep rules updated** - Review rules when adding new features
5. **Document changes** - Update this file when modifying rules

---

## 🔗 Related Documentation

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Cloud Functions Guide](https://firebase.google.com/docs/functions)
- [Dashboard Access Guard](DASHBOARD_ACCESS_GUARD.md)
- [Technician Service Moderation](TECHNICIAN_SERVICE_MODERATION.md)

---

## 📞 Support

For security concerns, contact: **9508322397**

---

**Last Updated:** 2026-01-XX
**Version:** 1.0.0
