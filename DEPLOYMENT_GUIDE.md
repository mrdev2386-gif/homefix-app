# HomeFix System Audit - Deployment Guide

## CRITICAL: READ BEFORE DEPLOYING

This guide covers deployment of all fixes from the comprehensive 11-step system audit. Follow each step carefully to ensure production stability.

---

## PRE-DEPLOYMENT CHECKLIST

- [ ] All code reviewed
- [ ] All tests passing locally
- [ ] Firestore rules reviewed
- [ ] Cloud Functions tested
- [ ] Admin panel tested
- [ ] Customer app tested
- [ ] Technician app tested
- [ ] Backup of current production data
- [ ] Rollback plan documented

---

## STEP 1: DEPLOY FIRESTORE INDEXES

**Why:** Composite indexes are required for scalable queries on large datasets.

```bash
# Deploy indexes
firebase deploy --only firestore:indexes

# Verify indexes created
firebase firestore:indexes
```

**Expected Output:**
```
✓ Deployed indexes for collection bookings
✓ Deployed indexes for collection technicians
✓ Deployed indexes for collection technician_services
✓ Deployed indexes for collection users
✓ Deployed indexes for collection reviews
✓ Deployed indexes for collection security_audit_logs
```

**Indexes Created:**
- bookings: status + createdAt
- bookings: customerId + createdAt
- bookings: technicianId + createdAt
- bookings: paymentStatus + createdAt
- technicians: status + rating + createdAt
- technicians: city + rating
- technicians: isOnline + rating
- technician_services: status + createdAt
- technician_services: technicianId + createdAt
- technician_services: categoryId + createdAt
- users: city + createdAt
- users: isSuspended + createdAt
- reviews: technicianId + createdAt
- reviews: bookingId + createdAt
- security_audit_logs: userId + timestamp
- security_audit_logs: eventType + timestamp

---

## STEP 2: DEPLOY FIRESTORE RULES

**Why:** Updated rules enforce security and prevent unauthorized writes.

```bash
# Deploy rules
firebase deploy --only firestore:rules

# Verify rules deployed
firebase firestore:rules
```

**Expected Output:**
```
✓ Deployed firestore rules
```

**Rules Verified:**
- ✅ Customers cannot edit technician services
- ✅ Customers cannot approve bookings
- ✅ Technicians cannot modify other services
- ✅ Technicians cannot approve bookings
- ✅ Admins pass role validation
- ✅ All wallet writes blocked (Cloud Functions only)
- ✅ All booking writes blocked (Cloud Functions only)

---

## STEP 3: BUILD CLOUD FUNCTIONS

**Why:** New functions must be compiled before deployment.

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Verify build successful
ls -la lib/

# Expected files:
# - lib/booking/booking_creation.js
# - lib/shared/booking_state_machine.js
# - lib/shared/wallet_safety.js
# - lib/shared/query_optimization.js
# - lib/shared/security_audit.js
```

**Expected Output:**
```
✓ Compiled 5 new files
✓ No TypeScript errors
✓ All imports resolved
```

---

## STEP 4: DEPLOY CLOUD FUNCTIONS

**Why:** New functions must be deployed to Firebase.

```bash
# Deploy all functions
firebase deploy --only functions

# Monitor deployment
firebase functions:log

# Verify functions deployed
firebase functions:list
```

**Expected Output:**
```
✓ Deployed createBookingRequest
✓ Deployed approveBookingByAdmin
✓ Deployed technicianAcceptBooking
✓ Deployed startService
✓ Deployed completeService
✓ Deployed technicianRejectBooking
✓ Deployed cancelBooking
✓ Deployed razorpayWebhookV2
✓ All functions deployed successfully
```

**New Functions Deployed:**
1. `createBookingRequest` - Booking creation with idempotency
2. `approveBookingByAdmin` - Admin booking approval
3. `technicianAcceptBooking` - Technician job acceptance
4. `startService` - Service start
5. `completeService` - Service completion
6. `technicianRejectBooking` - Technician job rejection
7. `cancelBooking` - Booking cancellation
8. `razorpayWebhookV2` - Payment webhook handler

---

## STEP 5: TEST BOOKING CREATION

**Why:** Verify new booking creation function works correctly.

```bash
# Test booking creation
firebase functions:shell

# In shell:
> createBookingRequest({
    serviceId: 'service123',
    technicianId: 'tech123',
    categoryId: 'cat123',
    categoryName: 'Plumbing',
    scheduledDate: '2024-01-15',
    scheduledTime: '10:00 AM',
    address: { line1: '123 Main St', city: 'Delhi' },
    price: 500,
    idempotencyKey: 'test_key_123'
  })

# Expected response:
{
  success: true,
  bookingId: 'booking_xyz',
  bookingStatus: 'pending_admin_approval',
  message: 'Booking created successfully. Awaiting admin approval.'
}
```

---

## STEP 6: TEST BOOKING STATE TRANSITIONS

**Why:** Verify state machine prevents invalid transitions.

```bash
# Test valid transition
firebase functions:shell

# In shell:
> approveBookingByAdmin({ bookingId: 'booking_xyz' })

# Expected response:
{
  success: true,
  bookingStatus: 'approved_by_admin'
}

# Test invalid transition (should fail)
> approveBookingByAdmin({ bookingId: 'booking_xyz' })

# Expected error:
HttpsError: failed-precondition: Cannot approve booking with status: approved_by_admin
```

---

## STEP 7: TEST PAYMENT WEBHOOK

**Why:** Verify payment webhook idempotency works.

```bash
# Send test webhook
curl -X POST https://your-project.cloudfunctions.net/razorpayWebhookV2 \
  -H "Content-Type: application/json" \
  -H "X-Razorpay-Signature: <signature>" \
  -d '{
    "event": "payment.captured",
    "payload": {
      "payment": {
        "entity": {
          "id": "pay_123",
          "order_id": "order_123",
          "amount": 50000,
          "currency": "INR",
          "status": "captured",
          "captured": true,
          "created_at": 1234567890
        }
      }
    }
  }'

# Expected response:
200 OK

# Send same webhook again (should be idempotent)
# Expected response:
200 OK (duplicate safely ignored)
```

---

## STEP 8: TEST WALLET OPERATIONS

**Why:** Verify wallet safety guards work.

```bash
# Test wallet credit
firebase functions:shell

# In shell:
> creditWalletAtomic(
    'tech123',
    500,
    'booking_payout',
    'booking_xyz',
    'Payment for booking'
  )

# Expected response:
{
  success: true,
  transactionId: 'txn_123',
  newBalance: 500
}

# Test duplicate credit (should be idempotent)
> creditWalletAtomic(
    'tech123',
    500,
    'booking_payout',
    'booking_xyz',
    'Payment for booking'
  )

# Expected response:
{
  success: true,
  transactionId: 'txn_123',
  newBalance: 500
}
```

---

## STEP 9: TEST ADMIN PANEL QUERIES

**Why:** Verify pagination works for large datasets.

```bash
# Test paginated bookings
firebase functions:shell

# In shell:
> getPaginatedBookings({
    pageSize: 20,
    filters: { status: 'pending_admin_approval' }
  })

# Expected response:
{
  items: [...20 bookings...],
  hasMore: true,
  nextCursor: DocumentSnapshot
}

# Test next page
> getPaginatedBookings({
    pageSize: 20,
    cursor: nextCursor,
    filters: { status: 'pending_admin_approval' }
  })

# Expected response:
{
  items: [...next 20 bookings...],
  hasMore: true,
  nextCursor: DocumentSnapshot
}
```

---

## STEP 10: VERIFY SECURITY AUDIT

**Why:** Ensure security checks are working.

```bash
# Test admin verification
firebase functions:shell

# In shell:
> verifyAdmin('admin_uid')

# Expected response:
true

# Test non-admin
> verifyAdmin('customer_uid')

# Expected response:
false

# Test suspicious activity detection
> checkSuspiciousActivity('user_uid', 'failed_login', 60)

# Expected response:
{
  suspicious: false,
  count: 0
}
```

---

## STEP 11: RUN END-TO-END TEST

**Why:** Verify complete user lifecycle works.

```bash
# 1. Create customer
firebase functions:shell
> createCustomer({ name: 'John', phone: '9876543210' })

# 2. Create technician
> createTechnician({ name: 'Tech', skills: ['plumbing'] })

# 3. Admin approves technician
> approveTechnician({ uid: 'tech_uid' })

# 4. Technician creates service
> addTechnicianService({ name: 'Plumbing', price: 500 })

# 5. Admin approves service
> admin_approveService({ serviceId: 'service_uid' })

# 6. Customer creates booking
> createBookingRequest({
    serviceId: 'service_uid',
    technicianId: 'tech_uid',
    categoryId: 'cat_uid',
    categoryName: 'Plumbing',
    scheduledDate: '2024-01-15',
    scheduledTime: '10:00 AM',
    address: { line1: '123 Main St', city: 'Delhi' },
    price: 500
  })

# 7. Admin approves booking
> approveBookingByAdmin({ bookingId: 'booking_uid' })

# 8. Technician accepts job
> technicianAcceptBooking({ bookingId: 'booking_uid' })

# 9. Technician starts service
> startService({ bookingId: 'booking_uid' })

# 10. Technician completes service
> completeService({ bookingId: 'booking_uid' })

# 11. Process payment
> razorpayWebhookV2(payment_webhook)

# 12. Verify wallet updated
> getWalletBalance('tech_uid')

# Expected response:
425 (500 - 15% commission)
```

---

## STEP 12: MONITOR PRODUCTION

**Why:** Ensure system is stable after deployment.

```bash
# Monitor function logs
firebase functions:log

# Check for errors
firebase functions:log --limit 100

# Monitor Firestore usage
firebase firestore:usage

# Check security audit logs
firebase firestore:query security_audit_logs --limit 100

# Monitor payment processing
firebase firestore:query payment_logs --limit 100
```

---

## ROLLBACK PROCEDURE

If issues occur, follow this rollback procedure:

```bash
# 1. Revert Cloud Functions
firebase deploy --only functions --force

# 2. Revert Firestore Rules
firebase deploy --only firestore:rules --force

# 3. Revert Firestore Indexes
firebase deploy --only firestore:indexes --force

# 4. Verify rollback
firebase functions:list
firebase firestore:rules
firebase firestore:indexes
```

---

## POST-DEPLOYMENT VERIFICATION

After deployment, verify:

- [ ] All functions deployed successfully
- [ ] Firestore rules enforced
- [ ] Composite indexes created
- [ ] Booking creation works
- [ ] State transitions validated
- [ ] Payment webhook working
- [ ] Wallet operations atomic
- [ ] Admin panel queries paginated
- [ ] Security audit logging
- [ ] End-to-end flow complete
- [ ] No errors in logs
- [ ] Performance acceptable

---

## MONITORING CHECKLIST

Daily monitoring tasks:

- [ ] Check function error rates
- [ ] Monitor Firestore read/write usage
- [ ] Review security audit logs
- [ ] Check payment processing logs
- [ ] Monitor wallet operations
- [ ] Verify query performance
- [ ] Check for suspicious activity
- [ ] Review admin actions

---

## SUPPORT

For deployment issues:

1. Check `firebase functions:log` for errors
2. Review `SYSTEM_AUDIT_COMPLETE.md` for architecture
3. Check `validation_checklist.ts` for test procedures
4. Review `security_audit.ts` for security checks

---

**Deployment Status:** Ready for Production

**Last Updated:** 2024

**Version:** 1.0.0
