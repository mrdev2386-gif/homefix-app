# Technician Service Moderation Panel - Testing Checklist

## 🎯 Pre-Testing Setup

### 1. Seed Test Data
- [ ] Run `scripts/seed-technician-services.js` to populate Firestore
- [ ] Verify 8 sample services created in `technician_services` collection
- [ ] Confirm status distribution: 3 pending, 3 approved, 1 rejected, 1 disabled

### 2. Admin Panel Access
- [ ] Navigate to Admin Panel: `http://localhost:3000/services`
- [ ] Verify page loads without errors
- [ ] Check browser console for any errors

---

## 📊 Statistics Cards Testing

### Expected Values (with sample data)
- [ ] **Total Listings**: Shows 8
- [ ] **Pending Approval**: Shows 3 (orange card)
- [ ] **Approved Listings**: Shows 3 (green card)
- [ ] **Disabled Listings**: Shows 1 (red card)

### Dynamic Updates
- [ ] Approve a pending service → Pending count decreases, Approved count increases
- [ ] Reject a pending service → Pending count decreases
- [ ] Disable an approved service → Approved count decreases, Disabled count increases
- [ ] Delete a service → Total count decreases

---

## 🔍 Filter Testing

### Status Filter
- [ ] Select "All Statuses" → Shows all 8 services
- [ ] Select "Pending" → Shows 3 services (Rajesh, Suresh, Prakash)
- [ ] Select "Approved" → Shows 3 services (Amit, Vikram, Sanjay)
- [ ] Select "Rejected" → Shows 1 service (Mohammed)
- [ ] Select "Disabled" → Shows 1 service (Ravi)

### Category Filter
- [ ] Select "All Categories" → Shows all services
- [ ] Select "Home Appliances" → Shows 2 services (AC repairs)
- [ ] Select "Plumbing" → Shows 1 service
- [ ] Select "Electrical" → Shows 1 service

### Search by Title
- [ ] Type "AC" → Shows 2 services (Split AC, Window AC)
- [ ] Type "Repair" → Shows 4 services
- [ ] Type "Professional" → Shows 3 services
- [ ] Type "xyz123" → Shows "No service listings found"
- [ ] Clear search → Shows all services

### Search by Technician
- [ ] Type "Kumar" → Shows 1 service (Rajesh Kumar)
- [ ] Type "Sharma" → Shows 1 service (Amit Sharma)
- [ ] Type "Singh" → Shows 1 service (Vikram Singh)
- [ ] Type "nonexistent" → Shows no results

### Combined Filters
- [ ] Status: Pending + Search: "AC" → Shows 2 pending AC services
- [ ] Category: Home Appliances + Status: Approved → Shows approved appliance services
- [ ] All filters active → Shows correctly filtered results

### Clear Filters
- [ ] Apply multiple filters → Click "Clear Filters" → All filters reset
- [ ] Verify button only appears when filters are active

---

## 📋 DataTable Testing

### Column Display
- [ ] **Image**: Shows service thumbnail or placeholder icon
- [ ] **Service Title**: Shows title + sub-service name
- [ ] **Category**: Shows category name
- [ ] **Service**: Shows service name
- [ ] **Technician**: Shows name + rating (⭐ format)
- [ ] **City/District**: Shows location
- [ ] **Price**: Shows ₹ amount
- [ ] **Created**: Shows formatted date
- [ ] **Status**: Shows color-coded badge
- [ ] **Actions**: Shows appropriate buttons based on status

### Status Badge Colors
- [ ] Pending → Blue badge
- [ ] Approved → Green badge
- [ ] Rejected → Red badge
- [ ] Disabled → Orange badge

### Action Buttons Visibility
- [ ] **Pending services**: Show View, Approve, Reject, Delete
- [ ] **Approved services**: Show View, Disable, Delete
- [ ] **Rejected services**: Show View, Delete
- [ ] **Disabled services**: Show View, Delete

### Sorting (if implemented)
- [ ] Click "Service Title" header → Sorts alphabetically
- [ ] Click again → Reverses sort order

---

## 👁️ Service Details Modal Testing

### Modal Opening
- [ ] Click "View" button → Modal opens
- [ ] Modal displays correct service data
- [ ] Modal has proper title "Service Details"
- [ ] Close button (X) works

### Content Display
- [ ] Service image displays (or placeholder if no image)
- [ ] Service title shows correctly
- [ ] Price displays with ₹ symbol
- [ ] Category, Service, Sub Service show correctly
- [ ] Description displays (if available)
- [ ] Status badge shows with correct color
- [ ] Technician name displays
- [ ] Technician phone displays
- [ ] Technician rating displays with ⭐
- [ ] Location (city/district) displays
- [ ] Created date shows in readable format

### Modal Actions
- [ ] Action buttons match service status
- [ ] Clicking action button closes modal and opens confirmation
- [ ] Modal backdrop click closes modal
- [ ] ESC key closes modal (if implemented)

---

## ✅ Action Testing

### Approve Action
- [ ] Click "Approve" on pending service
- [ ] Confirmation dialog appears: "Approve this service listing?"
- [ ] Click "Confirm" → Service status changes to "approved"
- [ ] Table refreshes automatically
- [ ] Statistics update (Pending -1, Approved +1)
- [ ] Status badge changes to green
- [ ] Action buttons update (now shows Disable instead of Approve/Reject)

### Reject Action
- [ ] Click "Reject" on pending service
- [ ] Confirmation dialog appears: "Reject this service listing?"
- [ ] Click "Confirm" → Service status changes to "rejected"
- [ ] Table refreshes automatically
- [ ] Statistics update (Pending -1)
- [ ] Status badge changes to red
- [ ] Action buttons update (only View and Delete remain)

### Disable Action
- [ ] Click "Disable" on approved service
- [ ] Confirmation dialog appears: "Disable this service listing?"
- [ ] Click "Confirm" → Service status changes to "disabled"
- [ ] Table refreshes automatically
- [ ] Statistics update (Approved -1, Disabled +1)
- [ ] Status badge changes to orange

### Delete Action
- [ ] Click "Delete" (trash icon) on any service
- [ ] Confirmation dialog appears with danger styling
- [ ] Click "Confirm" → Service is permanently removed
- [ ] Table refreshes automatically
- [ ] Statistics update (Total -1)
- [ ] Service no longer appears in table

### Cancel Actions
- [ ] Click "Cancel" in any confirmation dialog → No changes made
- [ ] Dialog closes
- [ ] Service remains unchanged

---

## 🔄 Real-time Updates Testing

### Auto-refresh After Actions
- [ ] Approve service → Table updates immediately
- [ ] Reject service → Table updates immediately
- [ ] Disable service → Table updates immediately
- [ ] Delete service → Table updates immediately
- [ ] No manual refresh needed

### Loading States
- [ ] Initial page load shows loading state
- [ ] Table shows skeleton/spinner while loading
- [ ] Data appears after loading completes

---

## 🎨 UI/UX Testing

### Responsive Design
- [ ] Desktop (1920x1080): All columns visible, proper spacing
- [ ] Tablet (768px): Layout adjusts, filters stack properly
- [ ] Mobile (375px): Table scrolls horizontally, filters stack vertically

### Visual Consistency
- [ ] All buttons have consistent styling
- [ ] Hover effects work on all interactive elements
- [ ] Colors match design system (indigo, green, red, orange)
- [ ] Spacing is consistent throughout
- [ ] Shadows and borders are subtle and consistent

### Accessibility
- [ ] All buttons have clear labels
- [ ] Color contrast meets WCAG standards
- [ ] Keyboard navigation works (Tab, Enter, ESC)
- [ ] Focus indicators are visible

---

## 🔐 Security Testing

### Firestore Rules (to be implemented)
- [ ] Only admins can read all services
- [ ] Only admins can update service status
- [ ] Only admins can delete services
- [ ] Technicians can only read their own services
- [ ] Customers can only read approved services

### Data Validation
- [ ] Cannot set invalid status values
- [ ] Cannot delete non-existent services
- [ ] Error handling for network failures

---

## 🚀 Integration Testing

### Customer App Integration
- [ ] Customer app queries `technician_services` collection
- [ ] Only services with `status === 'approved'` are visible
- [ ] Services filtered by user's district
- [ ] Disabled services are hidden
- [ ] Rejected services are hidden
- [ ] Pending services are hidden

### Technician App Integration
- [ ] Technician can create new service listing
- [ ] New listing has `status: 'pending'` by default
- [ ] Technician can view their own listings
- [ ] Technician receives notification when service is approved/rejected

---

## 🐛 Error Handling Testing

### Network Errors
- [ ] Disconnect internet → Shows error message
- [ ] Reconnect → Data loads successfully
- [ ] Failed action → Shows error alert

### Empty States
- [ ] No services in database → Shows "No service listings found"
- [ ] All services filtered out → Shows empty state
- [ ] No pending services → Pending count shows 0

### Edge Cases
- [ ] Service with missing image → Shows placeholder
- [ ] Service with missing technician name → Shows "Unknown"
- [ ] Service with missing location → Shows "N/A"
- [ ] Service with 0 rating → Shows "N/A"

---

## 📱 Cross-Browser Testing

- [ ] **Chrome**: All features work
- [ ] **Firefox**: All features work
- [ ] **Safari**: All features work
- [ ] **Edge**: All features work

---

## ⚡ Performance Testing

### Load Time
- [ ] Page loads in < 2 seconds with 100 services
- [ ] Filters apply instantly (< 100ms)
- [ ] Modal opens instantly
- [ ] Actions complete in < 1 second

### Data Volume
- [ ] Test with 10 services → Works smoothly
- [ ] Test with 100 services → Works smoothly
- [ ] Test with 1000 services → Consider pagination

---

## 📝 Documentation Testing

- [ ] README.md updated with new feature
- [ ] TECHNICIAN_SERVICE_MODERATION.md is accurate
- [ ] TECHNICIAN_SERVICE_MODERATION_SUMMARY.md is complete
- [ ] Sample data script works correctly
- [ ] All code comments are clear

---

## ✅ Final Checklist

### Before Deployment
- [ ] All tests pass
- [ ] No console errors
- [ ] No console warnings (except non-critical)
- [ ] Code is clean and well-commented
- [ ] Firestore security rules deployed
- [ ] Sample data seeded for demo

### After Deployment
- [ ] Admin can access moderation panel
- [ ] All actions work in production
- [ ] Customer app shows only approved services
- [ ] Technician app can create listings
- [ ] Notifications work (if implemented)

---

## 🎉 Success Criteria

✅ **Admin Panel**
- Statistics display correctly
- All filters work
- All actions work (approve/reject/disable/delete)
- Modal displays complete information
- UI is responsive and polished

✅ **Customer App**
- Only approved services visible
- Services filtered by location
- Disabled/rejected/pending services hidden

✅ **Technician App**
- Can create service listings
- Listings start with 'pending' status
- Can view own listings

✅ **Overall**
- No bugs or errors
- Fast and responsive
- Professional UI/UX
- Secure and validated

---

## 📞 Support

Issues found during testing? Contact: **9508322397**

---

**Testing Status**: ⏳ Ready for testing
**Last Updated**: 2026-01-XX
