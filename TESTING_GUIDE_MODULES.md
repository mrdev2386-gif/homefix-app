# Testing Guide - Reviews, Disputes & Risk Modules

## 🧪 Pre-Testing Setup

### 1. Ensure Admin Access
```javascript
// Verify your user has admin access
// Check Firestore: admins/{your-uid} exists
```

### 2. Seed Test Data (Optional)

#### Create Test Reviews
```javascript
// In Firebase Console or via script
db.collection('reviews').add({
  bookingId: 'test-booking-001',
  customerId: 'customer-123',
  customerName: 'John Doe',
  technicianId: 'tech-456',
  technicianName: 'Mike Smith',
  serviceId: 'service-789',
  rating: 4,
  reviewText: 'Great service, very professional!',
  isHidden: false,
  isFlagged: false,
  createdAt: firebase.firestore.FieldValue.serverTimestamp()
});
```

#### Create Test Disputes
```javascript
db.collection('disputes').add({
  bookingId: 'booking-001',
  customerId: 'customer-123',
  customerName: 'Jane Doe',
  technicianId: 'tech-456',
  technicianName: 'Mike Smith',
  issueType: 'Service Quality',
  description: 'Work was not completed as promised',
  evidenceUrls: [],
  amountInvolved: 500,
  status: 'open',
  adminNotes: '',
  createdAt: firebase.firestore.FieldValue.serverTimestamp()
});
```

#### Create Test Risk Signals
```javascript
db.collection('riskSignals').add({
  userId: 'user-789',
  userType: 'customer',
  riskType: 'Multiple Cancellations',
  riskScore: 65,
  triggerReason: 'Cancelled 5 bookings in last 7 days',
  status: 'open',
  createdAt: firebase.firestore.FieldValue.serverTimestamp()
});
```

---

## 📋 Test Cases

### REVIEWS MODULE

#### Test 1: Load Reviews
- [ ] Navigate to `/reviews`
- [ ] Verify reviews load with pagination
- [ ] Check skeleton loaders appear during load
- [ ] Verify 20 reviews per page

#### Test 2: Filter by Rating
- [ ] Click "5 ⭐" filter
- [ ] Verify only 5-star reviews show
- [ ] Click "1 ⭐" filter
- [ ] Verify only 1-star reviews show
- [ ] Click filter again to clear

#### Test 3: Filter by Status
- [ ] Click "Visible" filter
- [ ] Verify only non-hidden reviews show
- [ ] Click "Hidden" filter
- [ ] Verify only hidden reviews show
- [ ] Click "Flagged" filter
- [ ] Verify only flagged reviews show

#### Test 4: Search Functionality
- [ ] Type customer name in search
- [ ] Verify results filter in real-time
- [ ] Type technician name
- [ ] Verify results update
- [ ] Clear search
- [ ] Verify all results return

#### Test 5: Hide Review
- [ ] Click "Hide" button on a visible review
- [ ] Confirm action in dialog
- [ ] Verify review status changes to "Hidden"
- [ ] Check Firestore: `isHidden: true`
- [ ] Verify activity log created

#### Test 6: Unhide Review
- [ ] Filter to show hidden reviews
- [ ] Click "Unhide" button
- [ ] Verify review becomes visible
- [ ] Check Firestore: `isHidden: false`

#### Test 7: Flag Review
- [ ] Click "Flag" button on a review
- [ ] Verify "Flagged" badge appears
- [ ] Check Firestore: `isFlagged: true`

#### Test 8: View Details
- [ ] Click "View Details" button
- [ ] Verify modal opens with full review info
- [ ] Check all fields display correctly
- [ ] Close modal

#### Test 9: Pagination
- [ ] Scroll to bottom
- [ ] Click "Load More"
- [ ] Verify next 20 reviews load
- [ ] Check no duplicates

#### Test 10: Critical Review Badge
- [ ] Find review with rating ≤ 2
- [ ] Verify "Critical" badge displays
- [ ] Check red color coding

---

### DISPUTES MODULE

#### Test 1: Load Disputes
- [ ] Navigate to `/disputes`
- [ ] Verify disputes load
- [ ] Check tab navigation works

#### Test 2: Tab Filtering
- [ ] Click "Open" tab
- [ ] Verify only open disputes show
- [ ] Click "Investigating" tab
- [ ] Verify only investigating disputes show
- [ ] Click "Resolved" tab
- [ ] Verify only resolved disputes show

#### Test 3: Search Disputes
- [ ] Type dispute ID in search
- [ ] Verify results filter
- [ ] Type customer name
- [ ] Verify results update

#### Test 4: Mark as Investigating
- [ ] Click "Investigate" button
- [ ] Enter notes in modal
- [ ] Click "Confirm"
- [ ] Verify status changes to "investigating"
- [ ] Check Firestore update

#### Test 5: Resolve Dispute
- [ ] Click "Resolve" button
- [ ] Enter resolution notes
- [ ] Click "Confirm"
- [ ] Verify status changes to "resolved"
- [ ] Check `resolvedAt` timestamp
- [ ] Verify activity log

#### Test 6: Reject Dispute
- [ ] Click "Reject" button
- [ ] Enter rejection reason
- [ ] Click "Confirm"
- [ ] Verify status changes to "rejected"
- [ ] Check Firestore update

#### Test 7: Issue Refund
- [ ] Click "Refund" button
- [ ] Enter refund amount (e.g., 500)
- [ ] Enter notes
- [ ] Click "Confirm"
- [ ] Verify dispute resolved
- [ ] **CRITICAL:** Check customer wallet credited
- [ ] Verify wallet transaction created
- [ ] Check `customers/{customerId}/wallet_transactions`

#### Test 8: View Details
- [ ] Click "View Details"
- [ ] Verify all dispute info displays
- [ ] Check booking ID, amounts, dates
- [ ] Close modal

#### Test 9: Pagination
- [ ] Load more disputes
- [ ] Verify no duplicates

#### Test 10: Amount Display
- [ ] Verify ₹ symbol displays correctly
- [ ] Check amount formatting

---

### RISK MODULE

#### Test 1: Load Risk Signals
- [ ] Navigate to `/risk`
- [ ] Verify risk signals load
- [ ] Check risk score displays prominently

#### Test 2: Filter by Status
- [ ] Click "Open" filter
- [ ] Verify only open signals show
- [ ] Click "Reviewed" filter
- [ ] Verify only reviewed signals show

#### Test 3: Filter by Score
- [ ] Click "Critical" filter
- [ ] Verify only scores ≥70 show
- [ ] Click "High" filter
- [ ] Verify only scores 40-69 show
- [ ] Click "Low" filter
- [ ] Verify only scores <20 show

#### Test 4: Search Signals
- [ ] Type user ID in search
- [ ] Verify results filter
- [ ] Type trigger reason keyword
- [ ] Verify results update

#### Test 5: Block User
- [ ] Click "Block User" button
- [ ] Confirm action
- [ ] Verify status updates
- [ ] Check Firestore: status changed
- [ ] Verify activity log created

#### Test 6: Reset Risk Score
- [ ] Click "Reset Score" button
- [ ] Enter reason in prompt
- [ ] Confirm action
- [ ] Verify risk score = 0
- [ ] Check Firestore: `riskScore: 0`
- [ ] Verify metadata includes reason

#### Test 7: Color Coding
- [ ] Find signal with score ≥70
- [ ] Verify red color
- [ ] Find signal with score 40-69
- [ ] Verify amber color
- [ ] Find signal with score <40
- [ ] Verify indigo/blue color

#### Test 8: User Type Badge
- [ ] Find customer signal
- [ ] Verify blue badge with user icon
- [ ] Find technician signal
- [ ] Verify purple badge with wrench icon

#### Test 9: Pagination
- [ ] Load more signals
- [ ] Verify smooth loading

#### Test 10: Empty State
- [ ] Apply filters with no results
- [ ] Verify "No risk signals found" message
- [ ] Check shield icon displays

---

## 🔍 Backend Verification

### Check Cloud Functions
```bash
firebase functions:log --only admin_manageReview,admin_manageDispute,admin_manageRiskProfile
```

### Verify Activity Logs
```javascript
// In Firebase Console
db.collection('activity_logs')
  .orderBy('createdAt', 'desc')
  .limit(10)
  .get()
```

Expected fields:
- `actorType: 'admin'`
- `actorUid: <your-uid>`
- `action: 'review_hide' | 'dispute_resolve' | 'risk_reset'`
- `entityId: <review/dispute/signal-id>`
- `metadata: { reason?, amount? }`
- `createdAt: Timestamp`

### Verify Wallet Transactions (After Refund)
```javascript
// Check customer wallet
db.collection('customers').doc(customerId).get()
// Verify walletBalance increased

// Check transaction record
db.collection('customers').doc(customerId)
  .collection('wallet_transactions')
  .orderBy('createdAt', 'desc')
  .limit(1)
  .get()
```

Expected transaction:
- `type: 'credit'`
- `amount: <refund-amount>`
- `reason: 'Dispute refund: <dispute-id>'`
- `disputeId: <dispute-id>`
- `createdAt: Timestamp`

---

## 🐛 Common Issues & Solutions

### Issue: "Permission Denied"
**Solution:** Verify admin document exists in `admins/{your-uid}`

### Issue: "Function not found"
**Solution:** Deploy functions: `firebase deploy --only functions`

### Issue: "Index required"
**Solution:** Deploy indexes: `firebase deploy --only firestore:indexes`

### Issue: Reviews not loading
**Solution:** Check Firestore rules allow admin read access

### Issue: Refund not crediting wallet
**Solution:** 
1. Check customer document exists
2. Verify `walletBalance` field exists (initialize to 0 if missing)
3. Check Cloud Function logs for errors

### Issue: Pagination not working
**Solution:** Verify `createdAt` field exists on all documents

---

## ✅ Success Criteria

### Reviews Module
- ✅ All filters work correctly
- ✅ Search returns accurate results
- ✅ Hide/Unhide updates Firestore
- ✅ Flag/Unflag updates Firestore
- ✅ Activity logs created
- ✅ Pagination loads more reviews

### Disputes Module
- ✅ Tab filtering works
- ✅ Status updates correctly
- ✅ Refunds credit wallet
- ✅ Wallet transactions created
- ✅ Admin notes saved
- ✅ Activity logs created

### Risk Module
- ✅ Score filtering accurate
- ✅ Status filtering works
- ✅ Block user updates status
- ✅ Reset score sets to 0
- ✅ Color coding correct
- ✅ Activity logs created

---

## 📊 Performance Checks

- [ ] Page loads in <2 seconds
- [ ] Filters apply instantly
- [ ] Search debounces properly (300ms)
- [ ] Pagination smooth
- [ ] No console errors
- [ ] No memory leaks

---

## 🎉 Final Verification

Run through all test cases above. If all pass:

✅ **Reviews Module: PRODUCTION READY**
✅ **Disputes Module: PRODUCTION READY**
✅ **Risk Module: PRODUCTION READY**

Document any issues found and create tickets for fixes.
