# Quick Reference - Booking Lifecycle Functions

## 🚀 Quick Start

### Deploy
```bash
cd backend
firebase deploy --only functions
```

### Verify
```bash
firebase functions:list
```

### Test
```bash
firebase emulators:start --only functions
```

---

## 📋 Functions at a Glance

| Function | Input | Status Change | Notification |
|----------|-------|----------------|--------------|
| **approveBooking** | `bookingId` | `PENDING_ADMIN_APPROVAL` → `ADMIN_APPROVED` | Customer |
| **rejectBooking** | `bookingId`, `reason?` | `PENDING_ADMIN_APPROVAL` → `REJECTED` | Customer |
| **markBookingActive** | `bookingId` | `TECHNICIAN_ACCEPTED` → `IN_PROGRESS` | Customer |
| **completeBooking** | `bookingId` | `IN_PROGRESS` → `COMPLETED` | Customer + Tech |
| **updateBookingPayment** | `bookingId`, `paymentStatus` | Updates `paymentStatus` | Customer (if PAID) |

---

## 🔐 Security

All functions require:
- ✅ Admin authentication
- ✅ Admin custom claim: `{ "admin": true }`
- ✅ Valid booking ID
- ✅ Correct status transition

---

## 📝 Audit Trail

All actions logged to `booking_audit_logs` collection:
```
adminId: string
action: string
bookingId: string
details: object
timestamp: Timestamp
```

---

## 🔔 Notifications

Sent via FCM to:
- **Customer:** All status changes
- **Technician:** When booking completed

---

## 🧪 Test Commands

### Approve Booking
```javascript
const fn = firebase.functions().httpsCallable('approveBooking');
await fn({ bookingId: 'test-123' });
```

### Reject Booking
```javascript
const fn = firebase.functions().httpsCallable('rejectBooking');
await fn({ bookingId: 'test-123', reason: 'Not available' });
```

### Mark Active
```javascript
const fn = firebase.functions().httpsCallable('markBookingActive');
await fn({ bookingId: 'test-123' });
```

### Complete Booking
```javascript
const fn = firebase.functions().httpsCallable('completeBooking');
await fn({ bookingId: 'test-123' });
```

### Update Payment
```javascript
const fn = firebase.functions().httpsCallable('updateBookingPayment');
await fn({ bookingId: 'test-123', paymentStatus: 'PAID' });
```

---

## 🐛 Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `permission-denied` | Not admin | Set admin custom claim |
| `not-found` | Booking doesn't exist | Verify booking ID |
| `failed-precondition` | Wrong status | Check current status |
| `invalid-argument` | Missing parameter | Provide all required fields |

---

## 📊 Status Flow

```
PENDING_ADMIN_APPROVAL
├─ approveBooking() → ADMIN_APPROVED
│  └─ [Tech accepts] → TECHNICIAN_ACCEPTED
│     └─ markBookingActive() → IN_PROGRESS
│        └─ completeBooking() → COMPLETED
│
└─ rejectBooking() → REJECTED
```

---

## 📚 Documentation

- **Full Guide:** `BOOKING_FUNCTIONS_IMPLEMENTATION.md`
- **Deployment:** `DEPLOYMENT_VERIFICATION_GUIDE.md`
- **Code Changes:** `CODE_CHANGES_REFERENCE.md`
- **Research:** `DEEP_RESEARCH_CLOUD_FUNCTIONS.md`

---

## ✅ Checklist

- [ ] Deploy functions: `firebase deploy --only functions`
- [ ] Verify deployment: `firebase functions:list`
- [ ] Set admin custom claim in Firebase Console
- [ ] Test each function
- [ ] Check audit logs in Firestore
- [ ] Verify notifications sent
- [ ] Monitor logs: `firebase functions:log`

---

## 🎯 Next Steps

1. Deploy to production
2. Test in admin panel
3. Monitor logs
4. Verify notifications
5. Review audit trail

---

**Status:** ✅ READY FOR PRODUCTION
**Version:** 1.0.0
