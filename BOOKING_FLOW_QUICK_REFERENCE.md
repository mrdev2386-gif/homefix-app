# BOOKING FLOW QUICK REFERENCE

**Last Updated**: 2026-04-07

---

## STATUS FLOW CHEAT SHEET

```
Customer Creates → pending/awaiting_payment
                    ↓
Admin Approves   → approved_by_admin
                    ↓
Tech Accepts     → technician_accepted
                    ↓
Service Starts   → service_in_progress
                    ↓
Service Done     → service_completed
                    ↓
Payment Done     → completed ✅
```

---

## KEY FUNCTIONS

### Customer App
```dart
// Create booking
BookingProvider.createBookingRequest()
→ BookingService.createBookingRequest()
→ Cloud Function: createBookingRequest

// Cancel booking
BookingService.cancelBooking(bookingId, reason)
→ Cloud Function: updateBookingStatusNew

// Confirm payment
BookingService.confirmPayment(bookingId, paymentMethod)
→ Cloud Function: customerConfirmPayment
```

### Technician App
```dart
// Accept booking
BookingService.acceptBooking(bookingId)
→ Cloud Function: technicianAcceptBooking

// Reject booking
BookingService.rejectBooking(bookingId, reason)
→ Cloud Function: technicianRejectBooking

// Start service
→ Cloud Function: startService

// Complete service
BookingService.markWorkCompleted(bookingId)
→ Cloud Function: completeService
```

### Admin Panel
```typescript
// Approve booking
→ Cloud Function: approveBookingByAdmin
// ⚠️ UI NOT IMPLEMENTED

// Reject booking
→ Cloud Function: rejectBookingByAdmin
// ❌ FUNCTION NOT FOUND
```

---

## STATUS FIELD NAMES

⚠️ **INCONSISTENCY ALERT**: Two field names used interchangeably

- `status` - Used in Booking model, some queries
- `bookingStatus` - Used in Cloud Functions, some queries

**Recommendation**: Standardize on `bookingStatus`

---

## SECURITY RULES

```javascript
// Bookings collection
allow read: if isCustomer || isTechnician || isAdmin
allow create: if isCustomer && status in ['pending', 'awaiting_payment']
allow update: if false  // ✅ Forces Cloud Functions
allow delete: if false
```

---

## IDEMPOTENCY

**Key Format**: `BK_${uid}_${timestamp}` or custom  
**TTL**: 24 hours  
**Collection**: `booking_idempotency`

**Protection**:
- Prevents duplicate bookings
- Transaction-based check
- Returns existing booking ID if duplicate

---

## PAYMENT MODES

### Pay Before Work
```
paymentMode: 'before_work'
paymentMethod: 'online'
initialStatus: 'awaiting_payment'
→ Customer pays → confirmed → service starts
```

### Pay After Work
```
paymentMode: 'after_work'
paymentMethod: 'after_service'
initialStatus: 'pending'
→ Admin approves → service → customer pays
```

---

## CRITICAL ISSUES (P0)

### 1. NO ADMIN APPROVAL UI
**Impact**: Bookings stuck in pending  
**Location**: Admin panel  
**Fix**: Build booking approval screen

### 2. ADMIN NOT NOTIFIED
**Impact**: Admin doesn't know about new bookings  
**Location**: createBookingRequest function  
**Fix**: Add FCM notification after booking creation

---

## VALIDATION CHECKLIST

### Client-Side (BookingProvider)
- ✅ Service exists and approved
- ✅ Technician exists and approved
- ✅ Price matches (±₹1 tolerance)
- ✅ Category exists
- ✅ Address has district

### Server-Side (Cloud Function)
- ✅ User authenticated
- ✅ Rate limiting (10/hour)
- ✅ Input validation
- ✅ Service verification
- ✅ Technician verification
- ✅ Price enforcement (database price)
- ✅ Idempotency check

---

## NOTIFICATION POINTS

| Event | Recipient | Status |
|-------|-----------|--------|
| Booking created | Admin | ❌ MISSING |
| Admin approves | Technician | ✅ |
| Technician accepts | Customer | ✅ |
| Technician rejects | Admin | ✅ |
| Service starts | Customer | ✅ |
| Service completes | Customer | ✅ |
| Payment confirmed | Technician | ⚠️ VERIFY |

---

## RACE CONDITION PROTECTION

### Duplicate Booking
- Client: Submit lock (`_submitLock`)
- Server: Idempotency key check

### Multiple Accepts
- Transaction checks `bookingStatus == 'approved_by_admin'`
- Only first accept succeeds

### Concurrent Updates
- Firestore transactions
- Status validation in transaction

---

## TESTING COMMANDS

```bash
# Deploy functions
cd functions
npm run deploy

# Test booking creation
# Use customer app → checkout flow

# Check booking in Firestore
# Console → bookings collection

# Check idempotency
# Console → booking_idempotency collection

# Check logs
# Firebase Console → Functions → Logs
# Filter: [createBookingRequest]
```

---

## QUICK DEBUG

### Booking stuck in pending?
1. Check if admin approval UI exists
2. Check if admin received notification
3. Manually approve via Cloud Function

### Technician not seeing booking?
1. Check booking.technicianId matches
2. Check booking.status == 'approved_by_admin'
3. Check technician FCM token

### Payment not working?
1. Check paymentMode and paymentMethod
2. Check wallet balance
3. Check payment.status field
4. Review wallet transaction logs

---

## FILE LOCATIONS

### Customer App
- Model: `apps/customer_app/lib/core/models/booking.dart`
- Service: `apps/customer_app/lib/core/services/booking_service.dart`
- Provider: `apps/customer_app/lib/core/providers/booking_provider.dart`
- UI: `apps/customer_app/lib/features/cart/presentation/checkout_screen.dart`

### Technician App
- Service: `apps/technician_app/lib/core/services/booking_service.dart`
- UI: `apps/technician_app/lib/features/job_requests/job_requests_screen.dart`

### Cloud Functions
- Main: `functions/src/booking/unified_booking_lifecycle.ts`
- Payment: `functions/src/booking/new_booking_flow.ts`

### Security
- Rules: `firestore.rules`

---

## NEXT STEPS

1. **Immediate**: Build admin approval UI
2. **Immediate**: Add admin notification on booking creation
3. **Short-term**: Standardize status field name
4. **Short-term**: Audit wallet system
5. **Medium-term**: Implement admin rejection function
6. **Medium-term**: Enhance idempotency keys

---

**For detailed analysis, see**: `BOOKING_FLOW_DEEP_AUDIT.md`
