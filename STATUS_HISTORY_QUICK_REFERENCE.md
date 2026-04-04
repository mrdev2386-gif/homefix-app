# Status History Tracker - Quick Reference Guide

## 🚀 Quick Start

### Import the Tracker
```typescript
import { updateBookingStatus, initializeStatusHistory } from '../shared/status_history_tracker';
```

---

## 📖 Usage Patterns

### Pattern 1: Within a Transaction (RECOMMENDED)
```typescript
await db.runTransaction(async (transaction) => {
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingDoc = await transaction.get(bookingRef);
  const booking = bookingDoc.data()!;

  // Update status with automatic history tracking
  updateBookingStatus(
    transaction,
    bookingRef,
    'approved_by_admin',  // New status
    booking,              // Current booking data
    {                     // Additional fields to update
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      approvedBy: adminId,
    }
  );
});
```

### Pattern 2: Standalone (No Transaction)
```typescript
import { updateBookingStatusStandalone } from '../shared/status_history_tracker';

await updateBookingStatusStandalone(
  bookingId,
  'technician_accepted',
  {
    acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
  }
);
```

### Pattern 3: Initialize History for Old Bookings
```typescript
await db.runTransaction(async (transaction) => {
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingDoc = await transaction.get(bookingRef);
  const booking = bookingDoc.data()!;

  // Only creates history if it doesn't exist
  initializeStatusHistory(transaction, bookingRef, booking);
});
```

### Pattern 4: Safe Update (With Fallback)
```typescript
import { updateBookingStatusSafe } from '../shared/status_history_tracker';

await db.runTransaction(async (transaction) => {
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingDoc = await transaction.get(bookingRef);
  const booking = bookingDoc.data()!;

  // If history update fails, still updates status
  updateBookingStatusSafe(transaction, bookingRef, 'completed', booking);
});
```

---

## 🔍 Validation & Debugging

### Check Status History Integrity
```typescript
import { validateStatusHistoryIntegrity } from '../shared/status_history_tracker';

const result = await validateStatusHistoryIntegrity(bookingId);
console.log(result);
// { valid: true, message: 'Status history is valid' }
// OR
// { valid: false, message: 'Status mismatch: current=completed, last history=in_progress' }
```

### Retrieve Full History
```typescript
import { getStatusHistory } from '../shared/status_history_tracker';

const history = await getStatusHistory(bookingId);
console.log(history);
// [
//   { status: 'pending', timestamp: Timestamp(...) },
//   { status: 'approved_by_admin', timestamp: Timestamp(...) },
//   { status: 'technician_accepted', timestamp: Timestamp(...) },
//   { status: 'completed', timestamp: Timestamp(...) }
// ]
```

---

## 🔧 Migration Utilities

### Batch Initialize History
```typescript
import { batchInitializeStatusHistory } from '../shared/status_history_tracker';

const bookingIds = ['booking1', 'booking2', 'booking3'];
const result = await batchInitializeStatusHistory(bookingIds, 500);
console.log(result);
// { success: 2, failed: 0, skipped: 1 }
```

---

## 📊 What Gets Logged

Every status update logs:
```
[STATUS TRACKING] Booking: abc123xyz
[STATUS TRACKING] Old: pending → New: approved_by_admin
[STATUS TRACKING] History count before: 1
[STATUS TRACKING] History count after: 2
[STATUS TRACKING] ✅ Status updated successfully
```

---

## ⚠️ Important Notes

### ✅ DO:
- Always pass current booking data to `updateBookingStatus()`
- Use transactions for atomic updates
- Check logs for status tracking messages
- Use `updateBookingStatusSafe()` in error-prone contexts

### ❌ DON'T:
- Don't manually update `statusHistory` field
- Don't update `status` without using the tracker
- Don't assume past states when initializing history
- Don't skip transaction context when possible

---

## 🎯 Common Status Values

```typescript
// Booking lifecycle statuses
'pending'
'pending_admin_approval'
'approved_by_admin'
'technician_pending'
'technician_accepted'
'technician_rejected'
'service_in_progress'
'service_completed'
'completed'
'cancelled'
'rejected_by_admin'
```

---

## 🔄 Status Transition Examples

### Customer Creates Booking
```typescript
// Initial creation (in createBookingRequest)
statusHistory: [
  { status: 'pending', timestamp: serverTimestamp() }
]
```

### Admin Approves
```typescript
updateBookingStatus(t, bookingRef, 'approved_by_admin', booking, {
  approvedAt: serverTimestamp(),
  approvedBy: adminId,
});
// History: ['pending', 'approved_by_admin']
```

### Technician Accepts
```typescript
updateBookingStatus(t, bookingRef, 'technician_accepted', booking, {
  acceptedAt: serverTimestamp(),
});
// History: ['pending', 'approved_by_admin', 'technician_accepted']
```

### Service Starts
```typescript
updateBookingStatus(t, bookingRef, 'service_in_progress', booking, {
  serviceStartedAt: serverTimestamp(),
});
// History: [..., 'service_in_progress']
```

### Service Completes
```typescript
updateBookingStatus(t, bookingRef, 'service_completed', booking, {
  serviceCompletedAt: serverTimestamp(),
});
// History: [..., 'service_completed']
```

---

## 🐛 Troubleshooting

### Issue: History not updating
**Check**: Are you using `updateBookingStatus()` or manually updating?
**Solution**: Always use the tracker functions

### Issue: Duplicate entries in history
**Check**: The tracker prevents this automatically
**Solution**: If you see duplicates, check for manual updates

### Issue: Old bookings have no history
**Solution**: Use `initializeStatusHistory()` or `batchInitializeStatusHistory()`

### Issue: Status and history mismatch
**Check**: Use `validateStatusHistoryIntegrity(bookingId)`
**Solution**: Investigate manual updates or failed transactions

---

## 📚 Full API Reference

### Core Functions
- `updateBookingStatus(transaction, bookingRef, newStatus, currentData, additionalUpdates)`
- `updateBookingStatusStandalone(bookingId, newStatus, additionalUpdates)`
- `updateBookingStatusSafe(transaction, bookingRef, newStatus, currentData, additionalUpdates)`

### Migration Functions
- `initializeStatusHistory(transaction, bookingRef, currentData)`
- `initializeStatusHistoryStandalone(bookingId)`
- `batchInitializeStatusHistory(bookingIds, batchSize)`

### Utility Functions
- `getStatusHistory(bookingId)`
- `validateStatusHistoryIntegrity(bookingId)`

---

## 🎓 Best Practices

1. **Always use transactions** for status updates
2. **Pass current booking data** to avoid race conditions
3. **Use standalone versions** only when transactions aren't possible
4. **Check logs** to verify history is being tracked
5. **Validate integrity** periodically in production
6. **Initialize history** for old bookings during migration

---

## 📞 Support

- **Documentation**: `functions/src/shared/status_history_tracker.ts`
- **Analysis Report**: `BACKEND_STATUS_HISTORY_ANALYSIS.md`
- **Contact**: 9508322397

---

**Last Updated**: 2024
**Version**: 1.0 (Production)
