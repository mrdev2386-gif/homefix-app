# Firebase Functions Cleanup & Consolidation Checklist

**Date:** March 11, 2026  
**Priority:** HIGH  
**Status:** READY FOR EXECUTION

---

## Phase 1: IMMEDIATE CLEANUP (Risk: LOW-MEDIUM)

### Task 1.1: Remove Duplicate `createTechnicianService` Export ✅
**Priority:** HIGH | **Time:** 30 mins | **Risk:** LOW

**Steps:**
- [ ] Open `functions/src/index.ts`
- [ ] Locate line with: `export const createTechnicianService = techServicesManagement.addTechnicianService;`
- [ ] DELETE this line (it's a duplicate of `addTechnicianService`)
- [ ] Search frontend code for calls to `createTechnicianService`
- [ ] If found, update calls to use `addTechnicianService` instead
- [ ] Compile and test: `npm run build` in functions directory
- [ ] Run tests: `npm test`
- [ ] Verify in emulator: Functions should have 158 exports (down from 159)

**Files to Check for Usage:**
- `apps/technician_app/lib/**/*.dart` - Search for "createTechnicianService"
- `apps/customer_app/lib/**/*.dart` - Search for "createTechnicianService"
- `apps/admin_panel/**/*.js|ts` - Search for "createTechnicianService"

**Verification:**
- [ ] Firebase emulator loads successfully
- [ ] Technician service creation still works
- [ ] No TypeScript compilation errors

---

### Task 1.2: Remove Deprecated `razorpayWebhook` ✅
**Priority:** HIGH | **Time:** 1-2 hours | **Risk:** MEDIUM

**Pre-Deployment Verification:**
- [ ] Check Firebase Console > Cloud Functions
- [ ] Find webhook URL for payment processing
- [ ] Verify it's using `razorpayWebhookV2` endpoint
- [ ] Note the webhook trigger path/region

**Steps:**
1. [ ] Open `functions/src/index.ts`
2. [ ] Locate & DELETE: `export const razorpayWebhook = techBankVerification.razorpayBankWebhook;`
   - WAIT: This might be wrong. Check actual export name
   - Verify in payments/razorpay.ts what's exported as razorpayWebhook
3. [ ] Locate the actual deprecated webhook (marked with @deprecated)
4. [ ] Remove from index.ts exports
5. [ ] In Firebase Console:
   - [ ] Go to Cloud Functions
   - [ ] Find the old webhook function
   - [ ] Record its trigger URL before deletion
   - [ ] Verify new `razorpayWebhookV2` function is deployed
   - [ ] Verify trigger URL is different/updated
6. [ ] Update Razorpay dashboard:
   - [ ] Log into Razorpay account
   - [ ] Go to Settings > Webhooks
   - [ ] Verify webhook URL matches `razorpayWebhookV2` endpoint
   - [ ] Test webhook delivery (Razorpay provides test button)
7. [ ] Compile and deploy: `npm run build && firebase deploy --only functions:razorpayWebhookV2`
8. [ ] Test payment flow end-to-end

**Payment Flow Test:**
- [ ] Customer initiates payment
- [ ] Payment gateway processes order
- [ ] Webhook is triggered
- [ ] Order status is updated in Firestore
- [ ] Customer sees confirmation

**Rollback Plan:**
- [ ] Keep old webhook URL in Razorpay config for 24 hours as backup
- [ ] Monitor function logs for errors
- [ ] If issues, rollback to previous deployment

---

### Task 1.3: Consolidate Booking Status Update Functions ⚠️
**Priority:** HIGH | **Time:** 2-3 hours | **Risk:** MEDIUM

**Analysis Required First:**
- [ ] Check `functions/src/booking/new_booking_flow.ts`
- [ ] Find all variants of `updateBookingStatus*`
- [ ] Review implementation differences:
  - `updateBookingStatus` - Original
  - `updateBookingStatusNew` - Alternative
  - `updateBookingStatusGeneric` - Generic version
- [ ] Check which handles wallet transactions correctly
- [ ] Review all Firestore trigger functions that may call these

**Decision Matrix:**
```
IF updateBookingStatus has wallet safety checks:
   → Keep this one, remove others

IF updateBookingStatusGeneric is the safest:
   → Keep this one, rename to updateBookingStatus
   → Remove alternatives

IF they all do different things:
   → Document each purpose
   → Keep all but add clear comments
   → Create wrapper function if needed
```

**Steps:**
1. [ ] Read impact analysis for booking workflow
2. [ ] Make decision on which version to keep
3. [ ] Update all frontend callables that use deprecated versions
4. [ ] Update all Firestore triggers that call deprecated versions
5. [ ] Remove deprecated exports from index.ts
6. [ ] Create migration guide for any apps still calling old versions
7. [ ] Test complete booking flow:
   - [ ] Customer creates booking
   - [ ] Admin approves
   - [ ] Technician accepts
   - [ ] Technician starts job
   - [ ] Booking completed
   - [ ] Payment processed
   - [ ] Wallet updated correctly

**Documentation:**
- [ ] Document the one "canonical" booking status update function
- [ ] Explain wallet transaction handling
- [ ] Document any special cases

---

## Phase 2: VERIFICATION TASKS (Risk: MEDIUM-HIGH)

### Task 2.1: Investigate `handlePaymentWebhook` Function
**Priority:** MEDIUM | **Time:** 1 hour | **Risk:** MEDIUM

**Questions to Answer:**
- [ ] Where is this function defined? (find file)
- [ ] What does it do? (compare with razorpayWebhookV2)
- [ ] Is it actually used/called from anywhere?
- [ ] Is it redundant with razorpayWebhookV2?
- [ ] Is it a backup webhook?

**Investigation Steps:**
1. [ ] Search for "handlePaymentWebhook" in all functions
2. [ ] Check if it's in production_hardening.ts
3. [ ] Compare implementation with razorpayWebhookV2
4. [ ] Check Firebase console functions list for this function
5. [ ] Check logs for recent invocations
6. [ ] Check Razorpay webhooks configuration

**Decision:**
- [ ] If unused → Mark for deprecation/removal
- [ ] If alternative implementation → Document purpose
- [ ] If backup → Keep but document as such

---

### Task 2.2: Verify `createBookingIdempotent` Usage
**Priority:** MEDIUM | **Time:** 30 mins | **Risk:** LOW

**Questions to Answer:**
- [ ] Is this function ever called from frontend?
- [ ] Is it a wrapper around createBookingRequest?
- [ ] What makes it "idempotent"?
- [ ] Is it critical for production?

**Investigation Steps:**
- [ ] Search frontend code for "createBookingIdempotent"
- [ ] Check if it's called by any scheduled jobs
- [ ] Review implementation vs createBookingRequest
- [ ] Check usage in last 30 days (Firebase analytics)

**Decision:**
- [ ] If unused → Mark for removal
- [ ] If important → Document importance clearly
- [ ] If supplement → Document relationship to createBookingRequest

---

### Task 2.3: Verify Production Hardening Functions Status
**Priority:** MEDIUM | **Time:** 2 hours | **Risk:** MEDIUM

**15 Functions to Verify:**
```
✓ handlePaymentWebhook
✓ createBookingIdempotent
✓ updateTechnicianHeartbeat
✓ createPayoutLedgerEntry
✓ generateWeeklyPayoutReport
✓ getTechnicianEarnings
✓ trackAnalyticsEvent
✓ validateBookingCreation
✓ sanitizeBookingInput
✓ cleanupStaleTechnicianHeartbeats
✓ cleanupRateLimitRecords
✓ checkSystemHealth
✓ onBookingStateChange
✓ generateAnalyticsSnapshot
✓ trackTechnicianMetrics
```

**For Each Function:**
- [ ] Find where it's defined
- [ ] Find who is calling it (frontend or internals)
- [ ] Check recent usage logs
- [ ] Determine if it's:
  - [ ] Active/used
  - [ ] Backup/alternative implementation
  - [ ] Internal utility
  - [ ] Legacy code
  - [ ] Hook for future use

**Spreadsheet to Create:**
```
Function Name | File | Caller | Active? | Purpose | Decision
```

---

### Task 2.4: Check for Duplicate Booking Triggers
**Priority:** MEDIUM | **Time:** 1 hour | **Risk:** MEDIUM  

**Issue:** Multiple booking triggers might be listening to same path
```
onBookingCreatedMatch
onBookingCreated
onStaleTechnicianCleanup
```

**Verification:**
- [ ] Locate onBookingCreatedMatch in matching/matching_v2.ts
- [ ] Locate onBookingCreated in matching/engine.ts
- [ ] Compare trigger paths
- [ ] Check if both listen to same bookings collection
- [ ] Review implementations - are they executing duplicate logic?

**Decision:**
- [ ] If identical triggers → Remove duplicate
- [ ] If different logic → Document why both needed
- [ ] If only one should be active → Update index.ts

**Testing:**
- [ ] Create test booking
- [ ] Monitor Firebase logs
- [ ] Verify trigger fires appropriate number of times (should be once)

---

## Phase 3: DOCUMENTATION (Risk: LOW)

### Task 3.1: Create Function Manifest
**Priority:** MEDIUM | **Time:** 2 hours | **Effort:** Write script

**Output File:** `FUNCTION_MANIFEST.md`

**Contents:**
- Function name
- File location
- Type (callable/trigger/webhook/scheduled)
- Frontend usage (which apps call it)
- Firestore paths (for triggers)
- Webhook URLs (for webhooks)
- Last modified date
- Status (active/deprecated/unclear)

**Script to Generate:**
```bash
# Run in functions directory
npm run generate-manifest
```

---

### Task 3.2: Create Webhook Configuration Document
**Priority:** HIGH | **Time:** 1 hour

**Output File:** `WEBHOOK_CONFIGURATION.md`

**Contents:**
```
WEBHOOK: razorpayWebhookV2
  - File: payments/razorpayWebhookV2.ts
  - URL: <auto-generated by Firebase, get from console>
  - Events Handled: payment success, failure, refund
  - Razorpay Config URL: https://dashboard.razorpay.com/app/webhooks
  
WEBHOOK: razorpayBankWebhook
  - File: technician/bank_verification.ts
  - URL: <auto-generated by Firebase>
  - Events Handled: bank verification complete
  
WEBHOOK: razorpayPayoutWebhook
  - File: finance/payout_logic.ts
  - URL: <auto-generated by Firebase>
  - Events Handled: payout processed, failed
```

**Action Items:**
- [ ] Get actual webhook URLs from Firebase console
- [ ] Get webhook URLs from Razorpay dashboard
- [ ] Verify they match
- [ ] Document process for updating webhooks

---

### Task 3.3: Create Firestore Trigger Mapping
**Priority:** MEDIUM | **Time:** 1 hour

**Output File:** `FIRESTORE_TRIGGERS_MAPPING.md`

**Contents:**
```
TRIGGER: onBookingStatusChange
  - Path: bookings/{bookingId}
  - Event: onUpdate
  - Purpose: Notify users of status changes
  - Output: Sends notifications, updates frontend
  
TRIGGER: syncTechnicianApprovalToServices
  - Path: technicians/{techId}
  - Event: onUpdate
  - Condition: If approval status changed
  - Purpose: Auto-sync approval to all technician services
  
[... continue for all 18 Firestore triggers ...]
```

---

## Phase 4: TESTING CHECKLIST

### Critical Paths to Test After Changes

#### Payment Flow Test ✓
- [ ] Customer selects service
- [ ] Customer confirms booking
- [ ] Razorpay payment widget opens
- [ ] Payment succeeds
- [ ] Webhook received (check logs)
- [ ] Booking status updates to PENDING_APPROVAL
- [ ] Admin notification received
- [ ] Admin approves
- [ ] Technician notification received

#### Booking Workflow Test ✓
- [ ] Customer creates booking request
- [ ] Admin approves booking
- [ ] Booking status updates correctly
- [ ] Technician receives notification
- [ ] Technician accepts booking
- [ ] Customer receives confirmation
- [ ] Booking status changes to ACCEPTED
- [ ] Technician starts job
- [ ] Job in progress
- [ ] Technician marks complete
- [ ] Payment processed
- [ ] Technician wallet updated

#### Technician Onboarding Test ✓
- [ ] Technician signs up
- [ ] Saves personal details
- [ ] Uploads documents
- [ ] Selects services
- [ ] Submits KYC
- [ ] Admin approves
- [ ] KYC status updates in UI
- [ ] Services sync to approval

#### Notifications Test ✓
- [ ] New booking → Admin notification
- [ ] Booking approved → Technician notification
- [ ] Booking cancelled → Both notifications
- [ ] Review created → Notifications sent
- [ ] Deposit enough: FCM tokens saved
- [ ] Notifications marked as read

### Automated Tests
- [ ] Run all unit tests: `npm test`
- [ ] Run all integration tests
- [ ] Check function deployment logs for errors
- [ ] Monitor error rates in Firebase console

---

## Deployment Plan

### Pre-Deployment Checklist
- [ ] All code changes committed
- [ ] All tests passing
- [ ] Code review approved
- [ ] No compilation warnings
- [ ] Functions build successfully: `npm run build`
- [ ] Emulator tests pass locally
- [ ] Production config verified

### Deployment Steps
1. [ ] Deploy to staging environment first
2. [ ] Run full QA test suite
3. [ ] Monitor logs for 24 hours
4. [ ] Get approval for production deployment
5. [ ] Schedule maintenance window (off-peak hours)
6. [ ] Deploy to production: `firebase deploy --only functions`
7. [ ] Monitor logs for errors
8. [ ] Test key payment/booking flows
9. [ ] Confirm no customer impact

### Rollback Plan
- [ ] Keep previous deployment version tagged
- [ ] If critical errors occur: `firebase deploy --only functions --force-with-rollback`
- [ ] Notify team immediately
- [ ] Investigate and fix before redeploy

---

## Success Criteria

### Phase 1 Completion
- [ ] Duplicate export removed
- [ ] Deprecated webhook removed
- [ ] Booking status consolidated
- [ ] All tests passing
- [ ] No compilation errors
- [ ] Function count reduced from 159 to 156

### Phase 2 Completion
- [ ] 15 unclear functions verified
- [ ] Booking triggers deduplicated
- [ ] All decisions documented
- [ ] Functions ready for next phase

### Phase 3 Completion
- [ ] Function manifest created
- [ ] Webhook configuration documented
- [ ] Trigger mapping completed
- [ ] Team trained on documentation

### Phase 4 Completion
- [ ] All critical paths tested
- [ ] No regressions found
- [ ] Performance validated
- [ ] Ready for production

---

## Sign-Off

**Prepared by:** Audit Agent  
**Date:** March 11, 2026  

**Review Status:**
- [ ] Technical Review: _____ (sign)
- [ ] QA Review: _____ (sign)
- [ ] Management Approval: _____ (sign)

**Execution Timeline:**
- Phase 1: Week 1 (2 hrs work)
- Phase 2: Week 2 (3-4 hrs work)
- Phase 3: Week 2-3 (4 hrs work)
- Phase 4: Week 3 (Full QA cycle)

**Total Effort:** 10-15 hours over 3 weeks

---

## Additional Resources

- [Firebase Functions Comprehensive Audit Report](FIREBASE_FUNCTIONS_COMPREHENSIVE_AUDIT_REPORT.md)
- [Firebase Audit Executive Summary](FIREBASE_AUDIT_EXECUTIVE_SUMMARY.md)
- [Firebase Console](https://console.firebase.google.com/)
- [Razorpay Dashboard](https://dashboard.razorpay.com/)
- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
