# BOOKING SYSTEM - QUICK TEST GUIDE

**Purpose**: Verify the booking system is working end-to-end after deployment

---

## PRE-REQUISITES

- ✅ Cloud Functions deployed
- ✅ Admin panel deployed
- ✅ Customer app installed on test device
- ✅ Technician app installed on test device
- ✅ Admin app or web panel accessible

---

## QUICK TEST (5 Minutes)

### Step 1: Create Booking (Customer App)

1. Open customer app
2. Login as test customer
3. Select any service (e.g., "AC Repair")
4. Choose a technician
5. Fill booking details:
   - Date: Tomorrow
   - Time: 10:00 AM
   - Address: Use saved address
6. Click "Book Now"

**Expected**: 
- ✅ Success message
- ✅ Booking ID displayed
- ✅ Status: "Pending Approval"

**If Failed**: Check Cloud Function logs
```bash
firebase functions:log --only createBookingRequest --lines 20
```

---

### Step 2: Verify Admin Notification (Admin Device)

1. Wait 5 seconds
2. Check admin device notification tray

**Expected**:
- ✅ Notification appears
- ✅ Title: "New Booking Pending Approval"
- ✅ Body contains customer name

**If Failed**: Check notification logs
```bash
firebase functions:log --only createBookingRequest | grep "Notified"
```

---

### Step 3: Approve Booking (Admin Panel)

1. Open admin panel: `https://your-admin-url.web.app/bookings`
2. Login as admin
3. Verify booking appears in list
4. Click "Approve" button
5. Confirm in dialog

**Expected**:
- ✅ Booking visible in pending list
- ✅ Approve button clickable
- ✅ Success message after approval
- ✅ Booking disappears from pending list

**If Failed**: 
- Check browser console for errors
- Check Cloud Function logs:
```bash
firebase functions:log --only approveBookingByAdmin --lines 20
```

---

### Step 4: Verify Technician Notification (Technician Device)

1. Wait 5 seconds
2. Check technician device notification tray

**Expected**:
- ✅ Notification appears
- ✅ Title: "New Job Available"
- ✅ Body contains service name

**If Failed**: Check notification logs
```bash
firebase functions:log --only approveBookingByAdmin | grep "notification"
```

---

### Step 5: Accept Booking (Technician App)

1. Open technician app
2. Navigate to "Pending Bookings"
3. Verify booking appears
4. Tap "Accept"

**Expected**:
- ✅ Booking visible
- ✅ Accept button works
- ✅ Booking moves to "Active Bookings"

**If Failed**: Check Cloud Function logs
```bash
firebase functions:log --only technicianAcceptBooking --lines 20
```

---

## PASS/FAIL CRITERIA

### ✅ PASS if:
- All 5 steps completed successfully
- No errors in console or logs
- Notifications delivered within 5 seconds
- Status transitions correct

### ❌ FAIL if:
- Any step fails
- Errors in console or logs
- Notifications not delivered
- Status transitions incorrect

---

## TROUBLESHOOTING

### Issue: "Function not found"

**Solution**:
```bash
# Verify functions are deployed
firebase functions:list | grep "Booking"

# Redeploy if missing
firebase deploy --only functions:approveBookingByAdmin
```

---

### Issue: "Permission denied"

**Solution**:
1. Verify user is in `admins` collection in Firestore
2. Check Firestore rules are deployed:
```bash
firebase deploy --only firestore:rules
```

---

### Issue: No notification received

**Solution**:
1. Verify FCM token exists in user document
2. Check notification logs:
```bash
firebase functions:log | grep "notification"
```
3. Verify device has internet connection
4. Check app has notification permissions

---

### Issue: Booking not appearing in admin panel

**Solution**:
1. Check Firestore directly:
   - Open Firebase Console
   - Go to Firestore
   - Check `bookings` collection
   - Verify `bookingStatus` field
2. Check admin panel query:
   - Should query: `where('bookingStatus', 'in', ['pending', 'pending_admin_approval'])`
3. Check browser console for errors

---

## DETAILED TEST (30 Minutes)

For comprehensive testing, follow the full checklist in:
`BOOKING_SYSTEM_FINAL_DEPLOYMENT.md` → "END-TO-END TESTING CHECKLIST"

---

## MONITORING COMMANDS

### Real-time logs
```bash
firebase functions:log --follow
```

### Filter by function
```bash
firebase functions:log --only createBookingRequest --follow
```

### Search for errors
```bash
firebase functions:log | grep "ERROR"
```

### Search for specific booking
```bash
firebase functions:log | grep "BOOKING_ID_HERE"
```

---

## SUCCESS CONFIRMATION

After completing the quick test, confirm:

- [ ] Customer can create booking
- [ ] Admin receives notification
- [ ] Admin can approve booking
- [ ] Technician receives notification
- [ ] Technician can accept booking

**If all checked**: ✅ SYSTEM IS WORKING

**If any unchecked**: ❌ REVIEW TROUBLESHOOTING SECTION

---

## NEXT STEPS AFTER SUCCESSFUL TEST

1. Monitor for 24 hours
2. Check error rates in Firebase Console
3. Verify notification delivery rates
4. Review booking completion rates
5. Mark deployment as complete

---

**Quick Test Duration**: ~5 minutes  
**Full Test Duration**: ~30 minutes  
**Recommended**: Run quick test immediately, full test within 24 hours
