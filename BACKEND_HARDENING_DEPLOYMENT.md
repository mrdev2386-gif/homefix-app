# 🔐 BACKEND HARDENING DEPLOYMENT GUIDE

## 📋 DEPLOYMENT CHECKLIST

### ✅ STEP 1: Deploy Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions:technicianRespondBooking
firebase deploy --only functions:updateBookingStatusNew
firebase deploy --only functions:validateWalletIntegrity
firebase deploy --only functions:sendBookingNotification
firebase deploy --only functions:monitorBookingHealth
```

### ✅ STEP 2: Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### ✅ STEP 3: Create Firestore Indexes

```bash
# booking_idempotency collection
firebase firestore:indexes

# Add composite index:
# Collection: bookings
# Fields: status (Ascending), startedAt (Ascending)

# Collection: technician_wallets
# Fields: balance (Ascending)
```

### ✅ STEP 4: Enable Scheduled Functions

Ensure Cloud Scheduler API is enabled:
```bash
gcloud services enable cloudscheduler.googleapis.com
```

### ✅ STEP 5: Test Idempotency

```javascript
// Test script
const functions = require('firebase-functions-test')();
const myFunctions = require('./lib/technician/booking_actions_hardened');

// Call with same idempotencyKey twice
const result1 = await myFunctions.technicianRespondBooking({
  bookingId: 'test123',
  action: 'accept',
  idempotencyKey: 'test_key_001'
}, { auth: { uid: 'tech123' }});

const result2 = await myFunctions.technicianRespondBooking({
  bookingId: 'test123',
  action: 'accept',
  idempotencyKey: 'test_key_001'
}, { auth: { uid: 'tech123' }});

// result1 === result2 (cached)
console.assert(JSON.stringify(result1) === JSON.stringify(result2));
```

---

## 🔍 VERIFICATION TESTS

### Test 1: Idempotency Protection
```bash
# Call accept twice with same key
# Expected: Second call returns cached result
# Expected: No duplicate wallet credit
```

### Test 2: Multi-Device Concurrency
```bash
# Open booking on 2 devices
# Tap accept on both simultaneously
# Expected: Only one succeeds
# Expected: Other gets ALREADY_ACCEPTED error
```

### Test 3: Wallet Atomicity
```bash
# Complete booking
# Expected: Wallet balance updated
# Expected: Transaction record created
# Expected: Both in same transaction
```

### Test 4: Rate Limiting
```bash
# Call accept 6 times in 10 seconds
# Expected: 6th call fails with resource-exhausted
# Expected: Logged to abuse_logs
```

### Test 5: Availability Validation
```bash
# Assign booking outside working hours
# Expected: Rejected with "Outside working hours"
```

### Test 6: Wallet Integrity Cron
```bash
# Manually corrupt wallet balance
# Wait 24 hours (or trigger manually)
# Expected: Logged to suspicious_wallets
# Expected: Admin alert created
```

---

## 🚨 MONITORING SETUP

### CloudWatch/Stackdriver Alerts

**Alert 1: Negative Wallet**
```
Metric: custom/negative_wallet_count
Condition: > 0
Action: Email admin
```

**Alert 2: Stuck Bookings**
```
Metric: custom/stuck_booking_count
Condition: > 5
Action: Email admin
```

**Alert 3: High Idempotency Collision**
```
Metric: custom/idempotency_collision_rate
Condition: > 0.1
Action: Email admin
```

---

## 📊 FIRESTORE COLLECTIONS CREATED

### booking_idempotency
```
{
  key: string,
  result: any,
  createdAt: Timestamp,
  expiresAt: Timestamp (TTL 24h)
}
```

### rate_limits
```
{
  userId: string,
  actionCount: number,
  windowStart: Timestamp
}
```

### abuse_logs
```
{
  userId: string,
  action: string,
  timestamp: Timestamp,
  reason: string
}
```

### admin_alerts
```
{
  type: string,
  severity: 'low' | 'medium' | 'high' | 'critical',
  createdAt: Timestamp,
  ...metadata
}
```

### suspicious_wallets
```
{
  technicianId: string,
  reportedBalance: number,
  calculatedBalance: number,
  diff: number,
  transactionCount: number,
  detectedAt: Timestamp
}
```

---

## 🔐 SECURITY VALIDATION

### Firestore Rules Test

```bash
# Install emulator
npm install -g firebase-tools

# Start emulator
firebase emulators:start --only firestore

# Run test suite
npm test
```

**Test Cases:**
1. ✅ Client cannot write to booking_idempotency
2. ✅ Client cannot write to bookings directly
3. ✅ Client cannot write to technician_wallets
4. ✅ Client cannot read other technician's wallet
5. ✅ Only admin can read admin_alerts

---

## 📈 PERFORMANCE BENCHMARKS

### Expected Metrics

| Operation | Latency | Success Rate |
|-----------|---------|--------------|
| Accept Booking | <500ms | 99.9% |
| Complete Booking | <800ms | 99.9% |
| Idempotency Check | <100ms | 100% |
| Rate Limit Check | <50ms | 100% |
| Wallet Integrity | <5min | 100% |

---

## 🐛 TROUBLESHOOTING

### Issue: Idempotency key collision
**Solution:** Keys include timestamp, collision impossible

### Issue: Rate limit false positive
**Solution:** Increase window size or threshold

### Issue: Wallet integrity false positive
**Solution:** Check for floating point precision (use 0.01 tolerance)

### Issue: Scheduled function not running
**Solution:** Verify Cloud Scheduler API enabled

---

## 🚀 ROLLOUT PLAN

### Phase 1: Staging (Week 1)
- Deploy to staging environment
- Run automated tests
- Manual QA testing

### Phase 2: Canary (Week 2)
- Deploy to 10% of production traffic
- Monitor for 48 hours
- Check error rates

### Phase 3: Full Rollout (Week 3)
- Deploy to 100% production
- Monitor for 7 days
- Review admin_alerts daily

---

## ✅ ACCEPTANCE CRITERIA

- [ ] All 10 Cloud Functions deployed
- [ ] Firestore rules deployed
- [ ] Indexes created
- [ ] Scheduled functions running
- [ ] Idempotency tested (2 calls = 1 result)
- [ ] Multi-device tested (only 1 accepts)
- [ ] Wallet atomicity tested
- [ ] Rate limiting tested
- [ ] Availability validation tested
- [ ] Monitoring alerts configured
- [ ] Admin dashboard shows alerts
- [ ] No production errors for 48h

---

## 📞 SUPPORT

**Critical Issues:** Immediately rollback
```bash
firebase functions:delete technicianRespondBooking
firebase deploy --only functions:technicianRespondBooking@previous
```

**Non-Critical Issues:** Create ticket in admin_alerts collection

---

## 🎯 SUCCESS METRICS

After 1 week in production:

- ✅ Zero duplicate wallet credits
- ✅ Zero race condition errors
- ✅ <1% idempotency cache hit rate (normal)
- ✅ Zero negative wallets
- ✅ <5 stuck bookings per day
- ✅ 99.9% function success rate

---

**Deployment Date:** _____________  
**Deployed By:** _____________  
**Verified By:** _____________  
**Status:** ⚠️ PENDING DEPLOYMENT
