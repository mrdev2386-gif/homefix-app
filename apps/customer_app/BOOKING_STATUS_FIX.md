# Booking Status Field Priority Fix

## Problem
The Booking model had inconsistent status field handling:
- Firestore documents could have either `status` or `bookingStatus` fields
- UI was using `bookingStatus` directly instead of the unified `status` getter
- This caused status mismatches when admin approved and technician accepted bookings

## Solution

### 1. Booking Model (`booking.dart`)
**Changed:** Status field priority in `fromFirestore()` method
```dart
// BEFORE: Only checked bookingStatus
bookingStatus: (data['bookingStatus'] ?? 'pending').toString(),

// AFTER: Prioritizes 'status' over 'bookingStatus'
final status = data['status'] ?? data['bookingStatus'] ?? 'pending';
bookingStatus: status.toString(),
```

**Updated:** Status getter documentation
```dart
// Primary status getter - always use this
String get status => bookingStatus;
```

### 2. Booking Detail Screen (`booking_detail_screen.dart`)
**Changed:** All status references to use the unified `status` getter
- Line 31: `initState()` - Use `booking.status` instead of checking both fields
- Line 50: `build()` - Use `booking.status` instead of checking both fields
- Line 75: Technician section - Added support for `service_in_progress` status
- Line 95: Technician message - Added support for `service_in_progress` status
- Line 115: Cancel button - Support both `pending_admin_approval` and `pending_admin_review`
- Line 130: Pay Now button - Support both `awaiting_payment` and `confirmed`
- Line 145: Cancelled state - Support `rejected` status
- Line 160: Rate service - Support `service_completed` status
- Line 169: Call technician - Support `service_completed` and `rejected` statuses

### 3. Status Tracker Widget (`status_tracker.dart`)
**Updated:** `_getCurrentStepIndex()` to handle new status values
- Added support for `pending_admin_approval` (maps to step 0)
- Added support for `approved_by_admin` (maps to step 1)
- Added support for `service_in_progress` (maps to step 3)
- Added support for `technician_accepted` (maps to step 3)
- Added support for `service_completed` (maps to step 4)
- Added support for `rejected` status (terminal state)

### 4. Booking Status Utils (`booking_status_utils.dart`)
**Updated:** Valid statuses list and display names
- Added: `admin_rejected`, `technician_rejected`, `cancelled_by_customer`
- Updated `getBookingStatusDisplayName()` to handle all new statuses

## Status Flow (Booking Lifecycle)

```
1. pending_admin_approval
   ↓ (Admin approves)
2. approved_by_admin
   ↓ (Technician accepts)
3. technician_accepted
   ↓ (Payment confirmed)
4. awaiting_payment / confirmed
   ↓ (Service starts)
5. service_in_progress
   ↓ (Service completes)
6. service_completed
```

## Terminal States
- `rejected` - Admin rejected the booking
- `cancelled` / `cancelled_by_customer` - Customer cancelled
- `technician_rejected` - Technician declined

## Key Rule
✅ **Always trust `status` over `bookingStatus`**
- Use `booking.status` getter in UI
- Never access `booking.bookingStatus` directly
- Firestore reads prioritize `status` field

## Testing Checklist
- [ ] Create booking → shows `pending_admin_approval`
- [ ] Admin approves → shows `approved_by_admin`
- [ ] Technician accepts → shows `technician_accepted`
- [ ] Service starts → shows `service_in_progress`
- [ ] Service completes → shows `service_completed`
- [ ] Customer can rate after completion
- [ ] Status tracker displays correct step
- [ ] All status transitions work correctly
