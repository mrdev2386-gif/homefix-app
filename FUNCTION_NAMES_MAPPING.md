# Cloud Functions Name Mapping - Customer App Fix

## DEPLOYED FUNCTIONS (Verified from index.ts)

### Cart Management
- ✅ `addToCartCallable` - Add item to cart
- ✅ `updateCartQuantityCallable` - Update cart item quantity
- ✅ `removeFromCartCallable` - Remove item from cart
- ✅ `clearCartCallable` - Clear entire cart

### Favorites Management
- ✅ `toggleFavoriteCallable` - Toggle favorite status

### Booking Management
- ✅ `createBookingRequest` - Create new booking
- ✅ `cancelBooking` - Cancel existing booking
- ✅ `updateBookingStatusNew` - Update booking status

### User Profile
- ✅ `updateUserProfile` - Update user profile
- ✅ `manageAddress` - Manage addresses
- ✅ `submitServiceRating` - Submit service rating

### Notifications
- ✅ `saveFcmToken` - Save FCM token
- ✅ `removeFcmToken` - Remove FCM token
- ✅ `markNotificationRead` - Mark notification as read
- ✅ `markAllNotificationsRead` - Mark all notifications as read
- ✅ `deleteNotificationCallable` - Delete notification
- ✅ `deleteAllNotificationsCallable` - Delete all notifications

### Instant Booking
- ✅ `getInstantServices` - Get available instant services

### Custom Requests
- ✅ `createCustomServiceRequest` - Create custom service request
- ✅ `technicianRespondServiceRequest` - Technician respond to request
- ✅ `customerConfirmServicePayment` - Confirm payment for service
- ✅ `acceptProposal` - Accept proposal

### Matching
- ✅ `matchTechniciansV2` - Match technicians (exported)

### Partner Applications
- ✅ `submitPartnerApplication` - Submit partner application

### Support
- ✅ `submitSupportRequest` - Submit support request

### Referrals
- ✅ `validateReferralCode` - Validate referral code
- ✅ `processReferralCallable` - Process referral (if exists)

---

## FUNCTIONS NOT FOUND (Remove from customer app)

### ❌ generateInvoicePDF
- **Status**: NOT DEPLOYED
- **Location**: `job_details_screen.dart:line ~`
- **Action**: Remove or replace with alternative

### ❌ reportIssueCallable
- **Status**: NOT DEPLOYED
- **Location**: `job_details_screen.dart:line ~`
- **Action**: Remove or replace with alternative

### ❌ createUrgentBooking
- **Status**: NOT DEPLOYED
- **Location**: `urgent_booking_screen.dart:line ~`
- **Action**: Remove or replace with `createBookingRequest`

### ❌ confirmAfterWorkPayment
- **Status**: NOT DEPLOYED
- **Location**: `customer_booking_screen.dart:line ~`
- **Action**: Remove or replace with alternative

---

## FIXES REQUIRED

### 1. job_details_screen.dart
- Remove `generateInvoicePDF` call
- Remove `reportIssueCallable` call
- Keep `cancelBooking` (correct)

### 2. urgent_booking_screen.dart
- Replace `createUrgentBooking` with `createBookingRequest`
- Pass correct parameters

### 3. customer_booking_screen.dart
- Remove `confirmAfterWorkPayment` call
- Use `updateBookingStatusNew` instead

### 4. instant_booking_screen.dart
- Keep `getInstantServices` (correct)

---

## VERIFICATION CHECKLIST

- [ ] All function names match deployed functions
- [ ] No NOT_FOUND errors on function calls
- [ ] Region is asia-south1 (verified)
- [ ] Authentication is working
- [ ] No retry loops
