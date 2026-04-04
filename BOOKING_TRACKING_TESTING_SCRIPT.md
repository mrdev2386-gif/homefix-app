# Booking Tracking System - Testing Script

## 🧪 Complete Testing Guide

---

## 📋 Pre-Testing Setup

### 1. Deploy the App
```powershell
cd c:\Users\yash\projects\homefix\apps\customer_app
flutter clean
flutter pub get
flutter run
```

### 2. Prepare Test Data
Create test bookings in Firestore with different statuses:

```javascript
// Run in Firestore console or use script
const testBookings = [
  {
    customerId: "test_user_123",
    serviceTitle: "AC Repair",
    status: "pending",
    finalAmount: 500,
    scheduledAt: new Date(),
    createdAt: new Date(),
    updatedAt: new Date(),
    addressSnapshot: {
      street: "123 Main St",
      city: "Delhi",
      district: "Central Delhi"
    },
    services: []
  },
  // Add more with different statuses
];
```

---

## ✅ Test Case 1: Booking Card Display

### Objective
Verify booking cards display correctly with Track button

### Steps
1. Open customer app
2. Navigate to "My Bookings" tab
3. Observe booking cards

### Expected Results
- ✅ Cards display with rounded corners (20px)
- ✅ Service name visible at top
- ✅ Status badge shows with correct color
- ✅ Date & time displayed
- ✅ Address shown (truncated if long)
- ✅ Price displayed in gradient box
- ✅ Track button visible (timeline icon)
- ✅ Details button visible (arrow icon)
- ✅ Soft shadow around card

### Pass Criteria
All elements visible and properly styled

---

## ✅ Test Case 2: Status Badge Colors

### Objective
Verify status badges show correct colors

### Test Data
| Status | Expected Color | Expected Text |
|--------|---------------|---------------|
| pending | 🟠 Orange | Pending |
| admin_approved | 🔵 Blue | Approved |
| technician_assigned | 🟣 Purple | Technician Assigned |
| in_progress | 🟢 Teal | In Progress |
| completed | ✅ Green | Completed |
| cancelled | 🔴 Red | Cancelled |

### Steps
1. Create bookings with each status
2. View in My Bookings
3. Check badge color and text

### Expected Results
- ✅ Each status shows correct color
- ✅ Badge text matches expected
- ✅ Icon displays correctly
- ✅ Badge has rounded corners
- ✅ Background color is light shade

### Pass Criteria
All 6 statuses display with correct colors

---

## ✅ Test Case 3: Track Button Functionality

### Objective
Verify Track button opens tracking sheet

### Steps
1. Open My Bookings
2. Tap Track button (timeline icon) on any card
3. Observe bottom sheet

### Expected Results
- ✅ Bottom sheet slides up smoothly
- ✅ Handle bar visible at top
- ✅ Header shows "Track Booking"
- ✅ Booking ID displayed
- ✅ Close button (X) visible
- ✅ Timeline visible below header

### Pass Criteria
Bottom sheet opens without errors

---

## ✅ Test Case 4: Timeline Display - Pending Status

### Objective
Verify timeline for pending booking

### Test Data
```json
{
  "status": "pending",
  "createdAt": "2025-01-15T10:00:00Z"
}
```

### Steps
1. Create booking with status "pending"
2. Open My Bookings
3. Tap Track button
4. Observe timeline

### Expected Results
```
✅ Request Placed (Green checkmark)
   📅 Jan 15, 10:00 AM

🔵 Admin Approved (Blue circle, current)
   (No timestamp)

⚪ Technician Assigned (Grey circle)
   (No timestamp)

⚪ Work Started (Grey circle)
   (No timestamp)

⚪ Completed (Grey circle)
   (No timestamp)
```

### Pass Criteria
- ✅ Step 0 completed (green)
- ✅ Step 1 current (blue/orange)
- ✅ Steps 2-4 future (grey)
- ✅ Only step 0 has timestamp

---

## ✅ Test Case 5: Timeline Display - In Progress Status

### Objective
Verify timeline for in-progress booking

### Test Data
```json
{
  "status": "in_progress",
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T14:00:00Z"
}
```

### Steps
1. Create booking with status "in_progress"
2. Open My Bookings
3. Tap Track button
4. Observe timeline

### Expected Results
```
✅ Request Placed (Green checkmark)
   📅 Jan 15, 10:00 AM

✅ Admin Approved (Green checkmark)
   📅 Jan 15, 11:00 AM (estimated)

✅ Technician Assigned (Green checkmark)
   📅 Jan 15, 12:00 PM (estimated)

🟢 Work Started (Teal circle, current)
   📅 Jan 15, 02:00 PM

⚪ Completed (Grey circle)
   (No timestamp)
```

### Pass Criteria
- ✅ Steps 0-2 completed (green)
- ✅ Step 3 current (teal)
- ✅ Step 4 future (grey)
- ✅ Timestamps shown for completed/current

---

## ✅ Test Case 6: Timeline Display - Completed Status

### Objective
Verify timeline for completed booking

### Test Data
```json
{
  "status": "completed",
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T16:00:00Z"
}
```

### Steps
1. Create booking with status "completed"
2. Open My Bookings
3. Tap Track button
4. Observe timeline

### Expected Results
```
✅ Request Placed (Green checkmark)
   📅 Jan 15, 10:00 AM

✅ Admin Approved (Green checkmark)
   📅 Jan 15, 11:30 AM (estimated)

✅ Technician Assigned (Green checkmark)
   📅 Jan 15, 01:00 PM (estimated)

✅ Work Started (Green checkmark)
   📅 Jan 15, 02:30 PM (estimated)

✅ Completed (Green checkmark, current)
   📅 Jan 15, 04:00 PM
```

### Pass Criteria
- ✅ All 5 steps completed (green)
- ✅ All steps have timestamps
- ✅ No grey circles
- ✅ Last step is current

---

## ✅ Test Case 7: Timeline Display - Cancelled Status

### Objective
Verify timeline for cancelled booking

### Test Data
```json
{
  "status": "cancelled",
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T10:30:00Z"
}
```

### Steps
1. Create booking with status "cancelled"
2. Open My Bookings
3. Tap Track button
4. Observe timeline

### Expected Results
```
✅ Request Placed (Green checkmark)
   📅 Jan 15, 10:00 AM

🔴 Booking Cancelled (Red circle, current)
   📅 Jan 15, 10:30 AM
   "This booking will not proceed"
```

### Pass Criteria
- ✅ Only 2 steps shown
- ✅ Step 0 completed (green)
- ✅ Step 1 cancelled (red)
- ✅ Both have timestamps
- ✅ Cancellation message shown

---

## ✅ Test Case 8: Real-time Status Update

### Objective
Verify UI updates when status changes

### Steps
1. Open My Bookings with a pending booking
2. Note current status badge color (orange)
3. Open Firestore console
4. Change booking status to "admin_approved"
5. Observe app (do NOT refresh)

### Expected Results
- ✅ Status badge changes from orange to blue
- ✅ Badge text changes to "Approved"
- ✅ Track button color changes
- ✅ No manual refresh needed
- ✅ Change happens within 1-2 seconds

### Pass Criteria
UI updates automatically without refresh

---

## ✅ Test Case 9: Track Button with Different Statuses

### Objective
Verify Track button color matches status

### Test Data
| Status | Expected Track Button Color |
|--------|----------------------------|
| pending | Orange background |
| admin_approved | Blue background |
| technician_assigned | Purple background |
| in_progress | Teal background |
| completed | Green background |
| cancelled | Red background |

### Steps
1. Create bookings with each status
2. View in My Bookings
3. Check Track button color

### Expected Results
- ✅ Track button background matches status color (10% opacity)
- ✅ Track button border matches status color (30% opacity)
- ✅ Timeline icon color matches status color

### Pass Criteria
All Track buttons show correct colors

---

## ✅ Test Case 10: Timeline with statusHistory

### Objective
Verify timeline uses actual statusHistory if available

### Test Data
```json
{
  "status": "in_progress",
  "statusHistory": [
    {
      "status": "pending",
      "timestamp": "2025-01-15T10:00:00Z"
    },
    {
      "status": "accepted",
      "timestamp": "2025-01-15T10:30:00Z"
    },
    {
      "status": "assigned",
      "timestamp": "2025-01-15T11:00:00Z"
    },
    {
      "status": "in_progress",
      "timestamp": "2025-01-15T14:00:00Z"
    }
  ]
}
```

### Steps
1. Create booking with statusHistory
2. Open My Bookings
3. Tap Track button
4. Check timestamps

### Expected Results
- ✅ Step 0: Jan 15, 10:00 AM (from history)
- ✅ Step 1: Jan 15, 10:30 AM (from history)
- ✅ Step 2: Jan 15, 11:00 AM (from history)
- ✅ Step 3: Jan 15, 02:00 PM (from history)
- ✅ Step 4: No timestamp (future)

### Pass Criteria
Actual timestamps from statusHistory are used

---

## ✅ Test Case 11: Empty State

### Objective
Verify empty state when no bookings

### Steps
1. Login with new user (no bookings)
2. Navigate to My Bookings
3. Observe screen

### Expected Results
- ✅ Empty state illustration shown
- ✅ "No bookings yet" message
- ✅ "Book a service and track it here" subtitle
- ✅ "Book a Service" button visible
- ✅ No error messages

### Pass Criteria
Empty state displays correctly

---

## ✅ Test Case 12: Error Handling - Unknown Status

### Objective
Verify fallback for unknown status

### Test Data
```json
{
  "status": "unknown_status_xyz"
}
```

### Steps
1. Create booking with unknown status
2. View in My Bookings
3. Tap Track button

### Expected Results
- ✅ Badge shows "Processing" (grey)
- ✅ Track button shows default color
- ✅ Timeline defaults to step 0
- ✅ No crashes or errors
- ✅ App remains functional

### Pass Criteria
Unknown status handled gracefully

---

## ✅ Test Case 13: Bottom Sheet Interactions

### Objective
Verify bottom sheet interactions

### Steps
1. Open My Bookings
2. Tap Track button
3. Try these interactions:
   - Swipe down on handle bar
   - Tap outside sheet
   - Tap close button (X)
   - Scroll timeline content

### Expected Results
- ✅ Swipe down closes sheet
- ✅ Tap outside closes sheet
- ✅ Close button closes sheet
- ✅ Timeline scrolls smoothly
- ✅ Sheet doesn't close while scrolling

### Pass Criteria
All interactions work as expected

---

## ✅ Test Case 14: Performance Test

### Objective
Verify performance with many bookings

### Steps
1. Create 50+ bookings
2. Open My Bookings
3. Scroll through list
4. Tap Track on multiple bookings

### Expected Results
- ✅ List scrolls smoothly (60fps)
- ✅ Cards load without lag
- ✅ Track button responds instantly
- ✅ Bottom sheet opens quickly
- ✅ No memory leaks
- ✅ No frame drops

### Pass Criteria
App remains smooth with many bookings

---

## ✅ Test Case 15: Backward Compatibility

### Objective
Verify old bookings work without statusHistory

### Test Data
```json
{
  "status": "completed",
  "createdAt": "2025-01-10T10:00:00Z",
  "updatedAt": "2025-01-10T16:00:00Z"
  // No statusHistory field
}
```

### Steps
1. Create booking without statusHistory
2. View in My Bookings
3. Tap Track button
4. Check timeline

### Expected Results
- ✅ Card displays correctly
- ✅ Track button works
- ✅ Timeline shows all steps
- ✅ Timestamps auto-generated
- ✅ No errors or crashes

### Pass Criteria
Old bookings work perfectly

---

## 📊 Test Results Summary

### Test Execution Checklist

```
□ Test Case 1:  Booking Card Display
□ Test Case 2:  Status Badge Colors
□ Test Case 3:  Track Button Functionality
□ Test Case 4:  Timeline - Pending
□ Test Case 5:  Timeline - In Progress
□ Test Case 6:  Timeline - Completed
□ Test Case 7:  Timeline - Cancelled
□ Test Case 8:  Real-time Update
□ Test Case 9:  Track Button Colors
□ Test Case 10: Timeline with History
□ Test Case 11: Empty State
□ Test Case 12: Unknown Status
□ Test Case 13: Bottom Sheet Interactions
□ Test Case 14: Performance Test
□ Test Case 15: Backward Compatibility
```

### Results Template

```
Test Case: _______________
Status: ☐ Pass  ☐ Fail
Notes: _____________________
Screenshot: ________________
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Track button not visible
**Solution**: 
- Check booking_card.dart imported booking_tracking_sheet.dart
- Run `flutter pub get`
- Hot restart app (R)

### Issue 2: Wrong status colors
**Solution**:
- Verify status value in Firestore (lowercase)
- Check _getStatusColor() switch statement
- Clear app cache and rebuild

### Issue 3: Timeline not updating
**Solution**:
- Check StreamBuilder is working
- Verify Firestore connection
- Check console for errors

### Issue 4: Bottom sheet not opening
**Solution**:
- Check showModalBottomSheet() call
- Verify context is valid
- Check for navigation errors

### Issue 5: Timestamps not showing
**Solution**:
- Check statusHistory format in Firestore
- Verify timestamp parsing
- Check _getStepTimestamp() logic

---

## 📝 Test Report Template

```markdown
# Booking Tracking System - Test Report

**Date**: _______________
**Tester**: _______________
**App Version**: _______________
**Device**: _______________

## Test Results

| Test Case | Status | Notes |
|-----------|--------|-------|
| TC1: Card Display | ☐ Pass ☐ Fail | |
| TC2: Badge Colors | ☐ Pass ☐ Fail | |
| TC3: Track Button | ☐ Pass ☐ Fail | |
| TC4: Timeline Pending | ☐ Pass ☐ Fail | |
| TC5: Timeline Progress | ☐ Pass ☐ Fail | |
| TC6: Timeline Complete | ☐ Pass ☐ Fail | |
| TC7: Timeline Cancelled | ☐ Pass ☐ Fail | |
| TC8: Real-time Update | ☐ Pass ☐ Fail | |
| TC9: Button Colors | ☐ Pass ☐ Fail | |
| TC10: With History | ☐ Pass ☐ Fail | |
| TC11: Empty State | ☐ Pass ☐ Fail | |
| TC12: Unknown Status | ☐ Pass ☐ Fail | |
| TC13: Interactions | ☐ Pass ☐ Fail | |
| TC14: Performance | ☐ Pass ☐ Fail | |
| TC15: Backward Compat | ☐ Pass ☐ Fail | |

## Summary

Total Tests: 15
Passed: ___
Failed: ___
Pass Rate: ___%

## Issues Found

1. _______________
2. _______________
3. _______________

## Recommendations

1. _______________
2. _______________
3. _______________

## Sign-off

Tester: _______________
Date: _______________
Status: ☐ Approved ☐ Rejected
```

---

## ✅ Final Verification

Before marking as complete, verify:

- [ ] All 15 test cases executed
- [ ] Pass rate > 95%
- [ ] No critical bugs found
- [ ] Performance acceptable
- [ ] Backward compatibility confirmed
- [ ] Documentation reviewed
- [ ] Screenshots captured
- [ ] Test report completed

---

**Status**: Ready for Testing  
**Version**: 1.0  
**Last Updated**: 2025-01-XX
