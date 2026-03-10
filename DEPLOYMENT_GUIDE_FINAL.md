# 🚀 DEPLOYMENT GUIDE - CRITICAL ISSUES FIXES

**Project**: HomeFix Customer App  
**Version**: Production Ready  
**Date**: 2024

---

## Pre-Deployment Verification

### 1. Firestore Configuration

Verify these collections exist and have data:

```
✅ technician_services/{serviceId}
   - status: "approved"
   - state: "maharashtra"
   - district: "mumbai"
   - technicianDistrict: "mumbai"
   - originalPrice: 500
   - offerPrice: 299
   - urgentBookingEnabled: true
   - rating: 4.5
   - createdAt: Timestamp

✅ customers/{uid}
   - state: "maharashtra"
   - district: "mumbai"
   - primaryAddress: "..."

✅ categories/{categoryId}/services/{serviceId}/subServices/{subServiceId}
   - name: "AC Repair - 1 Hour"
   - price: 299
   - isActive: true
```

### 2. Cloud Functions Deployed

Verify these functions are deployed:

```bash
firebase deploy --only functions:addToCartCallable
firebase deploy --only functions:updateCartQuantityCallable
firebase deploy --only functions:removeFromCartCallable
firebase deploy --only functions:clearCartCallable
firebase deploy --only functions:toggleFavoriteCallable
firebase deploy --only functions:manageAddress
firebase deploy --only functions:updateUserProfile
```

### 3. Firestore Security Rules

Verify rules allow:
- ✅ Customers can read/write their own data
- ✅ Cart operations via Cloud Functions
- ✅ Favorites operations via Cloud Functions
- ✅ Services readable by all authenticated users

---

## Deployment Steps

### Step 1: Build Flutter App

```bash
cd apps/customer_app

# Clean build
flutter clean
flutter pub get

# Build APK
flutter build apk --release

# Or build AAB for Play Store
flutter build appbundle --release
```

### Step 2: Deploy to Firebase

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy hosting (if applicable)
firebase deploy --only hosting
```

### Step 3: Install on Device

```bash
# Install APK
flutter install --release

# Or use adb
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## Post-Deployment Testing

### Test 1: Home Screen Services Display

**Steps**:
1. Open app and login
2. Navigate to Home screen
3. Scroll down to see service sections

**Expected Results**:
- ✅ "Recommended" section shows services
- ✅ "Latest" section shows services
- ✅ "Popular" section shows categories
- ✅ "Nearby" section shows services
- ✅ "Top Rated" section shows services
- ✅ No Firestore errors in console

**Logs to Check**:
```
✅ No "FAILED_PRECONDITION" errors
✅ No "PERMISSION_DENIED" errors
✅ Services load within 2 seconds
```

---

### Test 2: Service Card UI

**Steps**:
1. Look at any service card on Home screen
2. Verify all elements display

**Expected Results**:
- ✅ Service image displays
- ✅ Service name visible
- ✅ Technician name visible
- ✅ Rating badge shows (e.g., "4.5 ⭐")
- ✅ Price displays (e.g., "₹299")
- ✅ If offer exists: original price strikethrough + offer price bold
- ✅ If urgent enabled: Orange "⚡ Urgent" badge visible

**Example Card**:
```
┌─────────────────────┐
│   [Service Image]   │
│  ⭐ 4.5  ⚡ Urgent  │
│                     │
│  AC Repair Service  │
│  👤 John Technician │
│  📍 MUMBAI          │
│                     │
│  ₹500 (strikethrough)
│  ₹299 (bold)        │
└─────────────────────┘
```

---

### Test 3: Service Details Page

**Steps**:
1. Tap on any service card
2. Verify service details page loads

**Expected Results**:
- ✅ Service image displays at top
- ✅ Service name shows
- ✅ Technician name visible
- ✅ Rating displays
- ✅ "About Service" description shows
- ✅ Sub-services list displays (if available)
- ✅ Urgent badge shows (if enabled)
- ✅ "Add to Cart" button functional

**Logs to Check**:
```
✅ No "Stream has already been listened to" errors
✅ Sub-services load within 1 second
✅ No Firestore path errors
```

---

### Test 4: Sub-Services Loading

**Steps**:
1. Open service details page
2. Scroll to "Available Sub-Services" section
3. Verify sub-services display

**Expected Results**:
- ✅ Sub-services list shows
- ✅ Each sub-service shows: image, name, price
- ✅ Can tap to select sub-service
- ✅ Selected sub-service highlighted
- ✅ Price updates when sub-service selected

**Example Sub-Service**:
```
┌──────────────────────────┐
│ [Image] AC Repair - 1hr  │
│         ₹299             │
│         ✓ (if selected)  │
└──────────────────────────┘
```

---

### Test 5: Add to Cart

**Steps**:
1. Open service details
2. Select a sub-service (if available)
3. Tap "Add to Cart" button
4. Verify success notification

**Expected Results**:
- ✅ Button shows loading spinner
- ✅ Success notification appears
- ✅ "VIEW CART" action in notification
- ✅ Cart count updates in header
- ✅ Item appears in cart

**Logs to Check**:
```
✅ Cloud Function "addToCartCallable" executes
✅ Item written to customers/{uid}/cart/{itemId}
✅ No validation errors
```

---

### Test 6: Favorites Toggle

**Steps**:
1. Open service details
2. Tap heart icon (top right)
3. Verify favorite status changes

**Expected Results**:
- ✅ Heart icon changes color (white → red)
- ✅ Haptic feedback (vibration)
- ✅ Favorite persists in Firestore
- ✅ Can toggle on/off multiple times

**Logs to Check**:
```
✅ Cloud Function "toggleFavoriteCallable" executes
✅ Item written to customers/{uid}/favorites/{serviceId}
✅ Optimistic UI update works
```

---

### Test 7: Location Filtering

**Steps**:
1. Set user location to "Mumbai, Maharashtra"
2. Go to Home screen
3. Check "Recommended" and "Nearby" sections

**Expected Results**:
- ✅ Only services from Mumbai district show
- ✅ Services from other districts filtered out
- ✅ Location-based filtering works correctly

**Logs to Check**:
```
✅ User location loaded: state=maharashtra, district=mumbai
✅ Services filtered by district
✅ Correct number of services returned
```

---

### Test 8: Urgent Badge Display

**Steps**:
1. Find a service with `urgentBookingEnabled=true`
2. Check service card
3. Check service details page

**Expected Results**:
- ✅ Orange "⚡ Urgent" badge on card
- ✅ Orange "⚡ Urgent" badge on details page
- ✅ Badge styling matches design

---

### Test 9: No UI Overflow

**Steps**:
1. Open service details page
2. Rotate device (portrait ↔ landscape)
3. Scroll through entire page
4. Check all screen sizes

**Expected Results**:
- ✅ No "RenderFlex overflowed" errors
- ✅ Layout adapts to screen size
- ✅ Smooth scrolling
- ✅ No layout jank

**Logs to Check**:
```
✅ No Flutter layout errors
✅ No widget overflow warnings
```

---

### Test 10: Booking Flow End-to-End

**Steps**:
1. Select service
2. Select sub-service
3. Add to cart
4. Go to cart
5. Proceed to checkout
6. Complete booking

**Expected Results**:
- ✅ All steps work without errors
- ✅ Data persists at each step
- ✅ Booking created in Firestore
- ✅ Confirmation shown to user

**Firestore Verification**:
```
✅ bookings/{bookingId} created with:
   - customerId
   - serviceId
   - subServiceId
   - technicianId
   - status: "pending"
   - createdAt: Timestamp
```

---

## Troubleshooting

### Issue: Services Not Showing

**Cause**: Firestore data not seeded or wrong status

**Fix**:
```bash
# Check Firestore console
# Verify technician_services collection has documents with:
# - status: "approved"
# - state: "maharashtra"
# - district: "mumbai"

# Seed data if needed
node scripts/seed-technician-services.js
```

### Issue: "FAILED_PRECONDITION" Error

**Cause**: Composite index required

**Fix**:
```bash
# This should NOT happen with current code
# If it does, check firestore_service.dart for orderBy clauses
# Remove orderBy and use in-memory sorting instead
```

### Issue: Sub-Services Not Loading

**Cause**: Wrong Firestore path or missing data

**Fix**:
```bash
# Verify path: categories/{categoryId}/services/{serviceId}/subServices
# Check that subServices have isActive: true
# Verify categoryId is passed correctly from service card
```

### Issue: Cart Not Updating

**Cause**: Cloud Function error or Firestore rules

**Fix**:
```bash
# Check Cloud Functions logs
firebase functions:log

# Verify Firestore rules allow cart writes
# Check that addToCartCallable is deployed
firebase deploy --only functions:addToCartCallable
```

### Issue: Location Filtering Not Working

**Cause**: User location not set or wrong format

**Fix**:
```bash
# Verify user profile has:
# - state: "maharashtra" (lowercase)
# - district: "mumbai" (lowercase)

# Check LocationProvider initialization
# Verify _getUserLocation() returns correct values
```

---

## Performance Monitoring

### Metrics to Track

1. **Service Load Time**
   - Target: < 2 seconds
   - Monitor: Firestore query latency

2. **UI Render Time**
   - Target: < 60ms per frame
   - Monitor: Flutter DevTools

3. **Cart Operations**
   - Target: < 1 second
   - Monitor: Cloud Function execution time

4. **Favorites Toggle**
   - Target: < 500ms
   - Monitor: Firestore write latency

### Firebase Console Checks

```
✅ Firestore
   - Read operations: Monitor usage
   - Write operations: Monitor usage
   - Storage: Monitor size

✅ Cloud Functions
   - Execution time: Should be < 1s
   - Error rate: Should be 0%
   - Memory usage: Monitor

✅ Authentication
   - Active users: Monitor growth
   - Sign-in success rate: Should be > 99%
```

---

## Rollback Plan

If issues occur after deployment:

### Rollback Flutter App
```bash
# Revert to previous APK version
adb install -r previous_version.apk

# Or rebuild from previous commit
git checkout previous_commit
flutter build apk --release
```

### Rollback Cloud Functions
```bash
# Redeploy previous version
firebase deploy --only functions --force
```

### Rollback Firestore Rules
```bash
# Redeploy previous rules
firebase deploy --only firestore:rules --force
```

---

## Sign-Off

- [ ] All tests passed
- [ ] No console errors
- [ ] No Firestore errors
- [ ] Performance acceptable
- [ ] Ready for production

**Deployed By**: _______________  
**Date**: _______________  
**Version**: _______________

---

## Support

For issues or questions:
- **Contact**: 9508322397
- **Email**: support@homefix.app
- **Documentation**: See CRITICAL_ISSUES_FINAL_VERIFICATION.md

---

**Status**: ✅ READY FOR PRODUCTION DEPLOYMENT
