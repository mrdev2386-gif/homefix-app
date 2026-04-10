# Notification System - Exact Code Changes Reference

## File 1: `functions/src/booking/booking_notifications.ts`

### Change 1: Add Payment Confirmation Notifications (Line ~85)

**Location:** After the `paid_escrow` status check  
**Before:**
```typescript
// ================================================
// STATUS: paid_escrow (Pay Before Work)
// ================================================
if (newStatus === 'paid_escrow' || after.paymentStatus === 'paid_escrow') {
  // Notify admin about paid booking
}
```

**After:**
```typescript
// ================================================
// STATUS: paid_escrow (Pay Before Work)
// ================================================
if (newStatus === 'paid_escrow' || after.paymentStatus === 'paid_escrow') {
  // Notify customer about payment confirmation
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: '💳 Payment Confirmed!',
    body: 'Your payment has been received. Technician will arrive soon.',
    type: 'payment_success',
    data: { bookingId, screen: 'booking_details' },
    priority: 'high',
  }).catch(err => console.error('[BOOKING] Payment confirmation notification failed:', err));

  // Notify technician about payment received
  if (technicianId) {
    await sendUserNotification({
      userId: technicianId,
      userType: 'technician',
      title: '💰 Payment Received!',
      body: `Payment confirmed for booking #${bookingId.substring(0, 6)}. You can now proceed.`,
      type: 'payment_received',
      data: { bookingId, screen: 'booking_details' },
      priority: 'high',
    }).catch(err => console.error('[BOOKING] Technician payment notification failed:', err));
  }
}
```

---

### Change 2: Add Error Handling to Payment Notification (Line ~75)

**Location:** In the `awaiting_customer_payment` status check  
**Before:**
```typescript
if (newStatus === 'awaiting_customer_payment') {
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: '🛠️ Service Finished!',
    body: 'Technician has finished work. Please show your QR code to complete payment.',
    type: 'job_completed',
    data: { bookingId, screen: 'payment_qr' },
    priority: 'high'
  });
}
```

**After:**
```typescript
if (newStatus === 'awaiting_customer_payment') {
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: '🛠️ Service Finished!',
    body: 'Technician has finished work. Please show your QR code to complete payment.',
    type: 'job_completed',
    data: { bookingId, screen: 'payment_qr' },
    priority: 'high'
  }).catch(err => console.error('[BOOKING] Payment notification failed:', err));
}
```

---

### Change 3: Enhance Admin Approval Notifications (Line ~110)

**Location:** In `handleAdminApproved()` function  
**Before:**
```typescript
async function handleAdminApproved(
  customerId: string,
  technicianId: string,
  bookingId: string,
  booking: any
) {
  // Fetch booking details for better messaging
  const serviceName = booking.serviceName || 'Service';
  const technicianName = booking.technicianName || 'A technician';

  // Notify customer
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: '✅ Booking Approved!',
    body: `Your ${serviceName} booking has been approved and assigned to ${technicianName}.`,
    type: 'booking_confirmed',
    data: {
      bookingId,
      screen: 'booking_details',
    },
    priority: 'high',
  }).catch(err => console.error('[BOOKING] Customer notification failed:', err));

  // Notify technician (if assigned)
  if (technicianId) {
    const customerName = booking.customerName || 'A customer';
    await sendUserNotification({
      userId: technicianId,
      userType: 'technician',
      title: '🔔 New Job Assigned!',
      body: `${serviceName} job assigned from ${customerName}. Review and accept/reject.`,
      type: 'new_instant_booking',
      data: {
        bookingId,
        screen: 'booking_details',
      },
      priority: 'high',
    }).catch(err => console.error('[BOOKING] Technician notification failed:', err));
  }
}
```

**After:**
```typescript
async function handleAdminApproved(
  customerId: string,
  technicianId: string,
  bookingId: string,
  booking: any
) {
  // Fetch booking details for better messaging
  const serviceName = booking.serviceName || 'Service';
  const technicianName = booking.technicianName || 'A technician';
  const customerName = booking.customerName || 'A customer';

  // Notify customer
  await sendUserNotification({
    userId: customerId,
    userType: 'customer',
    title: '✅ Booking Approved!',
    body: `Your ${serviceName} booking has been approved and assigned to ${technicianName}.`,
    type: 'booking_confirmed',
    data: {
      bookingId,
      screen: 'booking_details',
    },
    priority: 'high',
  }).catch(err => console.error('[BOOKING] Customer notification failed:', err));

  // Notify technician (if assigned)
  if (technicianId) {
    await sendUserNotification({
      userId: technicianId,
      userType: 'technician',
      title: '🔔 New Job Assigned!',
      body: `${serviceName} job assigned from ${customerName}. Review and accept/reject.`,
      type: 'new_instant_booking',
      data: {
        bookingId,
        screen: 'booking_details',
      },
      priority: 'high',
    }).catch(err => console.error('[BOOKING] Technician notification failed:', err));
  }

  console.log(`[BOOKING NOTIFICATION] Admin approved booking ${bookingId} - notifications sent to customer and technician`);
}
```

---

### Change 4: Add Error Tracking (Line ~100)

**Location:** In the catch block of `onBookingStatusChange` trigger  
**Before:**
```typescript
    } catch (error) {
      console.error(`[BOOKING NOTIFICATION] Error for booking ${bookingId}:`, error);
      // Don't fail the function - notifications are best-effort
    }
```

**After:**
```typescript
    } catch (error) {
      console.error(`[BOOKING NOTIFICATION] ❌ Error for booking ${bookingId}:`, error);
      // Track notification failure
      await db.collection('notification_failures').add({
        bookingId,
        error: error instanceof Error ? error.message : String(error),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      }).catch(err => console.error('[BOOKING] Failed to log notification error:', err));
      // Don't fail the function - notifications are best-effort
    }
```

---

### Change 5: Enhance Logging (Line ~95)

**Location:** Before the catch block  
**Before:**
```typescript
      console.log(`[BOOKING NOTIFICATION] Notifications sent for booking: ${bookingId}`);
```

**After:**
```typescript
      console.log(`[BOOKING NOTIFICATION] ✅ All notifications sent for booking: ${bookingId}`);
```

---

## File 2: `functions/src/shared/notification_helper.ts`

### Change 1: Add Initial Logging (Line ~120)

**Location:** At the start of `sendUserNotification()` function  
**Before:**
```typescript
export async function sendUserNotification(input: SendNotificationInput): Promise<{
  success: boolean;
  notificationId?: string;
  skipped?: boolean;
  error?: string;
}> {
  const {
    userId,
    userType,
    title,
    body,
    type,
    data = {},
    imageUrl,
    priority = 'normal',
  } = input;

  try {
```

**After:**
```typescript
export async function sendUserNotification(input: SendNotificationInput): Promise<{
  success: boolean;
  notificationId?: string;
  skipped?: boolean;
  error?: string;
}> {
  const {
    userId,
    userType,
    title,
    body,
    type,
    data = {},
    imageUrl,
    priority = 'normal',
  } = input;

  console.log(`[NOTIFICATION] 🚀 Sending ${type} to ${userType}:${userId}`);

  try {
```

---

### Change 2: Add Delivery Statistics Tracking (Line ~200)

**Location:** After `Promise.allSettled()` call  
**Before:**
```typescript
    // Use allSettled to never fail due to individual token failures
    const results = await Promise.allSettled(tokenPromises);
    const failedCount = results.filter(r => r.status === 'rejected').length;

    if (failedCount > 0) {
      console.warn(`[NOTIFICATION] ${failedCount}/${tokenPromises.length} tokens failed for ${userType}:${userId}`);
    }
```

**After:**
```typescript
    // Use allSettled to never fail due to individual token failures
    const results = await Promise.allSettled(tokenPromises);
    const failedCount = results.filter(r => r.status === 'rejected').length;
    const successCount = tokenPromises.length - failedCount;

    console.log(`[NOTIFICATION] 📊 Delivery Summary: ${successCount}/${tokenPromises.length} devices`);
    if (failedCount > 0) {
      console.warn(`[NOTIFICATION] ⚠️ ${failedCount} devices failed to receive notification`);
      // Track failures for monitoring
      await db.collection('notification_delivery_stats').add({
        userId,
        userType,
        type,
        totalAttempts: tokenPromises.length,
        successCount,
        failedCount,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      }).catch(() => {});
    }
```

---

## Deployment Checklist

### Pre-Deployment
- [ ] Read all 3 documentation files
- [ ] Review code changes above
- [ ] Test locally with Firebase emulator
- [ ] Get code review approval

### Deployment
- [ ] Backup current functions
- [ ] Apply changes to `booking_notifications.ts`
- [ ] Apply changes to `notification_helper.ts`
- [ ] Run `npm run build`
- [ ] Deploy: `firebase deploy --only functions`

### Post-Deployment
- [ ] Monitor Cloud Function logs
- [ ] Check notification_failures collection (should be empty)
- [ ] Check notification_delivery_stats collection (should have entries)
- [ ] Test all 8 flows manually
- [ ] Verify customer receives approval notification
- [ ] Verify payment notifications sent

### Rollback (if needed)
- [ ] `git revert HEAD`
- [ ] `firebase deploy --only functions`
- [ ] Verify functions reverted

---

## Testing Commands

### Test Notification Sending
```bash
firebase functions:shell
> sendUserNotification({
    userId: 'test-customer-id',
    userType: 'customer',
    title: 'Test Notification',
    body: 'This is a test',
    type: 'general',
    priority: 'high'
  })
```

### Check Logs
```bash
firebase functions:log --only onBookingStatusChange
firebase functions:log --only sendUserNotification
```

### Verify Collections
```bash
firebase firestore:inspect notifications --limit 5
firebase firestore:inspect notification_failures --limit 5
firebase firestore:inspect notification_delivery_stats --limit 5
```

---

## Verification Queries

### Check Success Rate
```sql
SELECT 
  COUNT(*) as total,
  SUM(CASE WHEN failedCount = 0 THEN 1 ELSE 0 END) as successful,
  ROUND(100 * SUM(CASE WHEN failedCount = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate
FROM notification_delivery_stats
WHERE timestamp > TIMESTAMP_SUB(NOW(), INTERVAL 1 HOUR);
```

### Check Failures
```sql
SELECT 
  error,
  COUNT(*) as count
FROM notification_failures
WHERE timestamp > TIMESTAMP_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY error;
```

---

## Support

For issues:
1. Check Cloud Function logs
2. Check notification_failures collection
3. Check notification_delivery_stats collection
4. Review documentation files
5. Contact on-call engineer

