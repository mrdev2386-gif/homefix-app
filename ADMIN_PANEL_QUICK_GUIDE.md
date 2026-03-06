# HomeFix Admin Panel - Quick Reference Guide

## 🚀 Getting Started

### Access Admin Panel
```
URL: http://localhost:3000 (development)
Login: Use admin credentials
```

### Navigation
- Dashboard - Platform overview
- Bookings - Manage service bookings
- Custom Requests - Handle custom service requests
- Technicians - Manage technician accounts
- Applications - Review technician applications
- Customers - Manage customer accounts
- Services - Moderate technician services
- Reviews - Manage customer reviews
- Disputes - Resolve booking disputes

---

## 📊 Dashboard

### Quick Actions
- **Approve Booking** - Click green checkmark on pending bookings
- **Reject Booking** - Click red X on pending bookings
- **View Details** - Click on any item for full information

### Statistics Cards
- Total Bookings - All bookings in system
- Pending Bookings - Awaiting admin approval
- Active Technicians - Approved and active
- Total Customers - All registered customers
- Pending Applications - Technician applications awaiting review
- Pending Custom Requests - Custom requests awaiting assignment
- Completed Bookings - Successfully completed services
- Monthly Revenue - Total revenue this month

---

## 📅 Bookings Management

### Workflow
1. **Pending Admin** → Admin reviews → Approve/Reject
2. **Approved** → Assign technician
3. **Technician Assigned** → Technician accepts
4. **In Progress** → Service being performed
5. **Completed** → Service finished

### Actions
- **View** - See full booking details
- **Approve** - Move to approved status
- **Reject** - Reject with reason
- **Assign** - Assign available technician

### Filters
- Search by Booking ID or Customer Name
- Filter by Status
- View results count

---

## 📝 Custom Requests

### Workflow
1. **Pending** → Admin reviews → Assign/Reject
2. **Assigned** → Technician contacted
3. **In Progress** → Service being performed
4. **Resolved** → Request completed

### Actions
- **View** - See full request details with images
- **Assign** - Assign technician (filtered by location)
- **Reject** - Reject with reason
- **Resolve** - Mark as completed

### Smart Features
- Technicians filtered by customer's district
- Only online technicians shown
- Image gallery for uploaded photos

---

## 👷 Technicians

### Actions
- **View Profile** - See complete technician information
- **Suspend** - Deactivate technician account
- **Activate** - Reactivate suspended account
- **View Services** - See all services created by technician

### Profile Information
- Personal details
- Contact information
- Service categories
- Rating and reviews
- Completed bookings
- Created services

---

## 📋 Applications

### Approval Process
1. Review application details
2. Check experience and qualifications
3. Approve or Reject

### On Approval
- New technician account created
- Status set to 'approved'
- Technician can login and create services

### On Rejection
- Application marked as rejected
- Reason recorded
- Applicant notified

---

## 👥 Customers

### Actions
- **View Profile** - See customer details
- **Suspend** - Deactivate customer account
- **Activate** - Reactivate suspended account
- **View Bookings** - See booking history
- **View Reviews** - See submitted reviews

### Profile Information
- Personal details
- Contact information
- Saved addresses
- Wallet balance
- Booking history
- Reviews submitted

---

## 🛠️ Services

### Moderation Workflow
1. Technician creates service → Status: Pending
2. Admin reviews → Approve/Reject/Disable
3. If approved → Visible to customers

### Actions
- **View** - See full service details
- **Approve** - Make visible to customers
- **Reject** - Reject service listing
- **Disable** - Hide from customers
- **Delete** - Remove permanently

### Filters
- Search by title or technician name
- Filter by status (pending, approved, rejected, disabled)
- Filter by category

---

## ⭐ Reviews

### Actions
- **View** - See full review text
- **Hide** - Hide from public view
- **Unhide** - Make visible again
- **Flag** - Mark as abusive
- **Delete** - Remove permanently

### Filters
- Filter by rating (1-5 stars)
- Filter by status (Visible, Hidden, Flagged)
- Search by customer or technician name

---

## ⚖️ Disputes

### Resolution Workflow
1. **Open** → New dispute created
2. **Under Review** → Admin investigating
3. **Resolved** → Issue resolved
4. **Closed** → Dispute closed

### Actions
- **View** - See full dispute details
- **Mark Under Review** - Start investigation
- **Resolve** - Close with resolution
- **Issue Refund** - Process refund to customer
- **Close** - Close without action

### Refund Process
- Enter refund amount
- Add resolution notes
- Confirm refund
- Customer wallet automatically credited

---

## 🔍 Search & Filter Tips

### Search
- Type in search box
- Results filter in real-time
- Clear with X button

### Status Filters
- Select from dropdown
- Results update immediately
- "All" shows everything

### Results Count
- Always visible
- Shows filtered vs total
- Updates in real-time

---

## ⚠️ Important Notes

### Confirmations
- All destructive actions require confirmation
- Rejection actions require reason
- Cannot undo deletions

### Data Refresh
- Most pages auto-refresh after actions
- Manual refresh available
- Real-time updates where applicable

### Error Handling
- Errors logged to console
- User-friendly messages shown
- Retry available on failures

---

## 🎯 Common Tasks

### Approve a Booking
1. Go to Bookings or Dashboard
2. Find pending booking
3. Click "Approve" button
4. Confirm action

### Assign Technician to Request
1. Go to Custom Requests
2. Find pending request
3. Click "Assign" button
4. Select technician from list
5. Confirm assignment

### Approve Technician Application
1. Go to Applications
2. Find pending application
3. Click "View" to review details
4. Click "Approve" button
5. Confirm action
6. New technician account created

### Moderate Service Listing
1. Go to Services
2. Find pending service
3. Click "View" to review
4. Click "Approve" or "Reject"
5. Confirm action

### Resolve Dispute
1. Go to Disputes
2. Find open dispute
3. Click "View" for details
4. Click "Resolve" or "Issue Refund"
5. Enter notes/amount
6. Confirm action

---

## 📱 Keyboard Shortcuts

- **Esc** - Close modal
- **Enter** - Confirm action (in modal)
- **Tab** - Navigate form fields

---

## 🆘 Troubleshooting

### Data Not Loading
- Check internet connection
- Refresh page
- Check browser console for errors

### Action Failed
- Check error message
- Verify permissions
- Try again
- Check Firestore rules

### Search Not Working
- Clear search box
- Try different keywords
- Check spelling

---

## 📞 Support

### For Technical Issues
- Check browser console (F12)
- Review error messages
- Check Firestore logs

### For Questions
- See `ADMIN_PANEL_COMPLETE_STATUS.md` for details
- Review module-specific documentation
- Contact development team

---

**Quick Start:** Dashboard → Review pending items → Take action → Confirm
**Most Common:** Approve bookings, Assign technicians, Moderate services
**Remember:** All actions require confirmation, Most actions are reversible
