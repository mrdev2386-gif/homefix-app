# Firebase Notification System - Quick Reference Guide

## 🚀 Quick Start Testing

### Test All 8 Flows in 10 Minutes

```bash
# 1. Create Test Booking
firebase functions:shell
> createBookingRequest({
    serviceId: 'service-123',
    technicianId: 'tech-123',
    categoryId: 'cat-123',
    categoryName: 'Plumbing',
    scheduledDate: '2025-01-20',
    scheduledTime: '10:00 AM',
    address: { line1: 'Test Address', city: 'Test City' }
  })

# Expected: Booking created, admin notified
# Check: notification_failures collection (should be empty)
```

### Test Admin Approval
```bash
# 2. Approve Booking
> approveBookingByAdmin({ bookingId: 'booking-123' })

# Expected: Customer + Technician notified
# Check: Firestore notifications collection for 2 new docs
```

### Test Technician Accept
```bash
# 3. Technician Accept
> technicianAcceptBooking({ bookingId: 'booking-123' })

# Expected: Customer notified
# Check: Firestore notifications collection
```

### Test Payment
```bash
# 4. Simulate Payment
firebase firestore:update bookings/booking-123 \
  --data 'paymentStatus=paid_escrow'

# Expected: Customer + Technician payment notifications
# Check: Firestore notifications collection
```

---

## 📊 Monitoring Dashboard

### Key Metrics to Track

```sql
-- Notification Success Rate
SELECT 
  type,
  COUNT(*) as total,
  SUM(CASE WHEN failedCount = 0 THEN 1 ELSE 0 END) as successful,
  ROUND(100 * SUM(CASE WHEN failedCount = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate
FROM notification_delivery_stats
WHERE timestamp > TIMESTAMP_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY type;

-- Failure Analysis
SELECT 
  type,
  COUNT(*) as failure_count,
  AVG(failedCount) as avg_failed_devices
FROM notification_delivery_stats
WHERE failedCount > 0
  AND timestamp > TIMESTAMP_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY type;

-- Error Tracking
SELECT 
  error,
  COUNT(*) as count,
  MAX(timestamp) as last_occurrence
FROM notification_failures
WHERE timestamp > TIMESTAMP_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY error
ORDER BY count DESC;
```

---

## 🔍 Debugging Checklist

### Issue: Notifications Not Received

**Step 1: Check FCM Token**
```bash
# Verify token exists
firebase firestore:inspect users/USER_ID/fcmTokens

# Expected: At least 1 token document
```

**Step 2: Check Notification Document**
```bash
# Verify notification created
firebase firestore:inspect notifications \
  --filter 'userId==USER_ID' \
  --limit 5

# Expected: Recent notification documents
```

**Step 3: Check Delivery Stats**
```bash
# Check if delivery was attempted
firebase firestore:inspect notification_delivery_stats \
  --filter 'userId==USER_ID' \
  --limit 5

# Expected: successCount > 0 or failedCount > 0
```

**Step 4: Check Failures**
```bash
# Check for errors
firebase firestore:inspect notification_failures \
  --limit 10

# Expected: Empty or specific error messages
```

**Step 5: Check Cloud Logs**
```bash
# View function logs
firebase functions:log --only onBookingStatusChange

# Look for: [NOTIFICATION] 🚀 Sending
```

---

## 🛠️ Common Issues & Fixes

### Issue 1: "No FCM tokens found"
**Cause:** User hasn't saved FCM token  
**Fix:** 
```dart
// In customer app, ensure this runs on login
await PushNotificationService().initialize();
```

### Issue 2: "Token invalid"
**Cause:** Token expired or revoked  
**Fix:** Automatic - token deleted after 3 failures

### Issue 3: "Duplicate notification"
**Cause:** Same notification sent twice  
**Fix:** Automatic - duplicate check prevents this

### Issue 4: "Notification not in Firestore"
**Cause:** Notification document creation failed  
**Fix:** Check notification_failures collection for error

### Issue 5: "High failure rate"
**Cause:** Network issues or token problems  
**Fix:** Monitor notification_delivery_stats, check error patterns

---

## 📈 Performance Tuning

### Optimize Notification Delivery

```typescript
// Current: Sends to all tokens sequentially
// Improvement: Batch send to reduce latency

// Before (current)
const results = await Promise.allSettled(tokenPromises);

// After (optimized)
const batchSize = 100;
for (let i = 0; i < tokenPromises.length; i += batchSize) {
  const batch = tokenPromises.slice(i, i + batchSize);
  await Promise.allSettled(batch);
}
```

### Reduce Firestore Writes

```typescript
// Current: Writes to notification_delivery_stats for every send
// Improvement: Batch writes every 100 notifications

// Implement batching in notification_helper.ts
let batchCount = 0;
const BATCH_THRESHOLD = 100;

if (failedCount > 0) {
  batchCount++;
  if (batchCount >= BATCH_THRESHOLD) {
    // Write batch stats
    batchCount = 0;
  }
}
```

---

## 🔐 Security Checklist

- [x] No client-side FCM sends
- [x] All notifications via Cloud Functions
- [x] Firestore rules prevent unauthorized writes
- [x] Notification documents include userId for access control
- [x] Error messages don't expose sensitive data
- [x] Rate limiting on notification sends (via booking rate limit)

---

## 📋 Deployment Checklist

Before deploying to production:

- [ ] All 8 test flows pass
- [ ] No errors in notification_failures collection
- [ ] Success rate > 95%
- [ ] Cloud Function logs clean
- [ ] Firestore rules verified
- [ ] Monitoring alerts configured
- [ ] Rollback plan documented
- [ ] Team notified of changes

---

## 🚨 Emergency Procedures

### If Notifications Stop Working

1. **Immediate:** Check Cloud Function status
   ```bash
   firebase functions:list
   ```

2. **Check Logs:** Look for errors
   ```bash
   firebase functions:log --only onBookingStatusChange
   ```

3. **Verify Firestore:** Check if documents are being created
   ```bash
   firebase firestore:inspect notifications --limit 5
   ```

4. **Rollback if Needed:**
   ```bash
   git revert HEAD
   firebase deploy --only functions
   ```

5. **Notify Users:** Post status update

---

## 📞 Support Contacts

- **On-Call Engineer:** [Contact]
- **Firebase Support:** https://firebase.google.com/support
- **Slack Channel:** #homefix-notifications

---

## 📚 Related Documentation

- [Full Verification Report](FIREBASE_NOTIFICATION_SYSTEM_VERIFICATION_REPORT.md)
- [Fixes Applied](NOTIFICATION_SYSTEM_FIXES_APPLIED.md)
- [Firebase Cloud Functions Guide](https://firebase.google.com/docs/functions)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)

