# Runtime Debug Checklist

## Pre-Testing Setup

- [ ] Flutter SDK installed and updated
- [ ] Android Studio / VS Code with Flutter extension
- [ ] Device connected or emulator running
- [ ] App built successfully: `flutter clean && flutter pub get`

---

## Test 1: Discount Price Display

### Setup
- [ ] App running on device/emulator
- [ ] Logcat/Console open and filtering for logs
- [ ] Logged in to customer account

### Test Steps
1. [ ] Navigate to Home screen
2. [ ] Scroll to "All Services" section
3. [ ] Look for service cards with discount badges
4. [ ] Check console for logs

### Expected Logs
```
📊 [CARD BUILD] Service: [Service Name]
   basePrice: [Price]
   offerPrice: [Discounted Price]
   originalPrice: [Original Price]
   hasOffer: true
   discountPercent: [Percentage]
```

### Verification
- [ ] 📊 log appears for each card
- [ ] `offerPrice` is not null
- [ ] `hasOffer` is true
- [ ] `discountPercent` is > 0
- [ ] Discount badge visible on card
- [ ] Strikethrough price visible

### If Failed
- [ ] Check if `offerPrice` is null → Firestore data issue
- [ ] Check if `hasOffer` is false → Logic issue
- [ ] Check if badge not visible → UI rendering issue
- [ ] Document exact log output

---

## Test 2: Add to Cart Button

### Setup
- [ ] App running on device/emulator
- [ ] Logcat/Console open and filtering for logs
- [ ] Logged in to customer account
- [ ] On Home screen

### Test Steps
1. [ ] Tap "Get Service" button on any card
2. [ ] Wait for navigation to ServiceDetailsScreen
3. [ ] Tap "Add to Cart" button
4. [ ] Check console for complete flow
5. [ ] Verify success dialog appears

### Expected Logs (Complete Chain)
```
🟢 [CARD] GET SERVICE BUTTON TAPPED - Service: [Name]
🛒 [ADD TO CART] Button tapped for: [Name]
🛒 [ADD TO CART] State set to loading
🛒 [CartProvider.addItem] Called with item: [Name]
🛒 [CartProvider.addItem] Calling firestore_service.addToCart()
🛒 [FirestoreService.addToCart] Called with userId=[ID], item=[Name]
🛒 [FirestoreService.addToCart] Calling Cloud Function addToCartCallable
✅ [FirestoreService.addToCart] Cloud Function succeeded
✅ [CartProvider.addItem] Success
✅ [ADD TO CART] Item added successfully
✅ [ADD TO CART] Showing success dialog
```

### Verification
- [ ] 🟢 button tap log appears
- [ ] 🛒 ADD TO CART log appears
- [ ] 🛒 CartProvider log appears
- [ ] userId is not null
- [ ] 🛒 FirestoreService log appears
- [ ] ✅ Cloud Function success log appears
- [ ] Success dialog appears on screen
- [ ] Dialog has "Added to Cart" title
- [ ] Dialog has "Continue" and "Go to Cart" buttons

### If Failed
- [ ] No 🟢 log → Button tap blocked (overlay issue)
- [ ] No 🛒 CartProvider log → Provider not registered
- [ ] userId is null → Auth issue
- [ ] No Cloud Function log → Network issue
- [ ] ❌ error log → Cloud Function error
- [ ] No dialog → UI rendering issue
- [ ] Document exact log output and error

---

## Test 3: Like Button (Favorites)

### Setup
- [ ] App running on device/emulator
- [ ] Logcat/Console open and filtering for logs
- [ ] Logged in to customer account
- [ ] On ServiceDetailsScreen

### Test Steps
1. [ ] Tap heart icon (top right of screen)
2. [ ] Check console for complete flow
3. [ ] Verify icon changes color
4. [ ] Verify snackbar appears
5. [ ] Tap heart again to toggle off
6. [ ] Verify icon changes back

### Expected Logs (Complete Chain)
```
❤️ [LIKE BUTTON] Tapped for service: [Name]
❤️ [LIKE BUTTON] Calling toggleFavorite()
❤️ [FavoritesProvider.toggleFavorite] Called for serviceId=[ID], categoryId=[ID]
❤️ [FavoritesProvider.toggleFavorite] wasFavorite=false
❤️ [FavoritesProvider.toggleFavorite] Optimistic UI updated, notifying listeners
❤️ [FavoritesProvider.toggleFavorite] Calling firestore_service.toggleFavorite()
❤️ [FirestoreService.toggleFavorite] Called with userId=[ID], serviceId=[ID], isFavorite=true
❤️ [FirestoreService.toggleFavorite] Calling Cloud Function toggleFavoriteCallable
✅ [FirestoreService.toggleFavorite] Cloud Function succeeded
✅ [LIKE BUTTON] After toggle, isFavorite: true
```

### Verification
- [ ] ❤️ button tap log appears
- [ ] ❤️ FavoritesProvider log appears
- [ ] `wasFavorite` value is correct
- [ ] Optimistic UI update log appears
- [ ] ❤️ FirestoreService log appears
- [ ] ✅ Cloud Function success log appears
- [ ] Icon changes to filled heart (red)
- [ ] Snackbar shows "Added to favorites"
- [ ] Toggle off works (icon becomes outline)
- [ ] Snackbar shows "Removed from favorites"

### If Failed
- [ ] No ❤️ log → Button tap blocked (overlay issue)
- [ ] No FavoritesProvider log → Provider not registered
- [ ] No Cloud Function log → Network issue
- [ ] ❌ error log → Cloud Function error
- [ ] Icon doesn't change → UI not updating
- [ ] No snackbar → Feedback not showing
- [ ] Document exact log output and error

---

## Test 4: Verify Firestore Data

### Setup
- [ ] Firebase Console open
- [ ] Logged in to Firebase project

### Test Steps
1. [ ] Go to Firestore Database
2. [ ] Navigate to `technician_services` collection
3. [ ] Find a service document
4. [ ] Check fields:
   - [ ] `basePrice` exists and > 0
   - [ ] `offerPrice` exists (if discount expected)
   - [ ] `originalPrice` exists (if discount expected)
   - [ ] `status` = "approved"
   - [ ] `technicianId` exists and not empty
   - [ ] `categoryId` exists and not empty

### Verification
- [ ] All required fields present
- [ ] No null values for critical fields
- [ ] Prices are valid numbers
- [ ] Status is "approved"

### If Failed
- [ ] Missing fields → Add to Firestore
- [ ] Null values → Update documents
- [ ] Wrong status → Update status to "approved"
- [ ] Document exact issues

---

## Test 5: Verify Cloud Functions

### Setup
- [ ] Firebase Console open
- [ ] Cloud Functions section

### Test Steps
1. [ ] Check if these functions exist:
   - [ ] `addToCartCallable`
   - [ ] `toggleFavoriteCallable`
2. [ ] Check function status (should be green/deployed)
3. [ ] Check recent logs for errors

### Verification
- [ ] All functions deployed
- [ ] No recent errors in logs
- [ ] Functions are active

### If Failed
- [ ] Function not deployed → Deploy: `firebase deploy --only functions`
- [ ] Function has errors → Check logs and fix
- [ ] Document exact issues

---

## Test 6: Verify Providers in main.dart

### Setup
- [ ] Code editor open
- [ ] main.dart file visible

### Test Steps
1. [ ] Check MultiProvider list
2. [ ] Verify these providers exist:
   - [ ] `CartProvider`
   - [ ] `FavoritesProvider`
3. [ ] Verify they are ChangeNotifierProvider
4. [ ] Verify they are registered before use

### Verification
- [ ] CartProvider registered
- [ ] FavoritesProvider registered
- [ ] Both are ChangeNotifierProvider
- [ ] Both have proper initialization

### If Failed
- [ ] Provider missing → Add to MultiProvider
- [ ] Wrong type → Change to ChangeNotifierProvider
- [ ] Document exact issues

---

## Test 7: Check Network Connectivity

### Setup
- [ ] Device/emulator connected to internet
- [ ] Firebase project accessible

### Test Steps
1. [ ] Check device internet connection
2. [ ] Try accessing Firebase Console
3. [ ] Check if Cloud Functions are reachable

### Verification
- [ ] Device has internet
- [ ] Firebase Console accessible
- [ ] Cloud Functions responding

### If Failed
- [ ] No internet → Connect to WiFi/mobile data
- [ ] Firebase not accessible → Check credentials
- [ ] Cloud Functions not responding → Check deployment
- [ ] Document exact issues

---

## Summary Checklist

### Discount Price Display
- [ ] 📊 log appears
- [ ] offerPrice not null
- [ ] hasOffer true
- [ ] Badge visible
- [ ] Strikethrough visible

### Add to Cart
- [ ] 🟢 button tap detected
- [ ] 🛒 CartProvider called
- [ ] userId available
- [ ] Cloud Function called
- [ ] ✅ success logged
- [ ] Dialog appears

### Like Button
- [ ] ❤️ button tap detected
- [ ] ❤️ FavoritesProvider called
- [ ] Optimistic UI updated
- [ ] Cloud Function called
- [ ] ✅ success logged
- [ ] Icon changes
- [ ] Snackbar appears

### Data & Infrastructure
- [ ] Firestore data valid
- [ ] Cloud Functions deployed
- [ ] Providers registered
- [ ] Network connected

---

## Issue Resolution Template

### Issue Found
**Feature**: [Discount/Add to Cart/Like]
**Last Successful Log**: [Log message]
**Expected Next Log**: [Log message]
**Actual Result**: [What happened]

### Root Cause
[Analysis of why it failed]

### Fix Applied
[Code changes made]

### Verification
- [ ] Issue resolved
- [ ] All logs appear
- [ ] Feature works end-to-end

---

## Notes

- Keep console open during all tests
- Take screenshots of logs for documentation
- Test on both Android and iOS if possible
- Test with different services (with/without offers)
- Test with different user accounts
- Document all findings

---

**Status**: Ready for testing
**Date**: [Current Date]
**Tester**: [Your Name]
