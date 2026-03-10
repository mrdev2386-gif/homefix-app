# Runtime Debugging Quick Start

## Step 1: Build & Run with Debug Logs

```bash
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter clean
flutter pub get
flutter run
```

## Step 2: Open Console/Logcat

### Android Studio
1. Open Android Studio
2. View → Tool Windows → Logcat
3. Filter by: `[CARD]|[ADD TO CART]|[LIKE BUTTON]|[CartProvider]|[FavoritesProvider]|[FirestoreService]`

### VS Code
1. Run with debugger: `flutter run -d <device_id>`
2. Check Debug Console tab

### Command Line
```bash
flutter logs
```

---

## Step 3: Test Discount Price Display

### Action
1. Open app
2. Go to Home screen
3. Scroll to "All Services" or "Top Rated Services" section
4. Look at service cards

### Expected Logs
```
📊 [CARD BUILD] Service: AC Repair
   basePrice: 500.0
   offerPrice: 399.0
   originalPrice: 500.0
   hasOffer: true
   discountPercent: 20
```

### What to Check
- ✅ Is `offerPrice` showing a value (not null)?
- ✅ Is `hasOffer` true?
- ✅ Is `discountPercent` calculated correctly?
- ✅ Is discount badge visible on card?

### If Issue Found
- **offerPrice is null**: Firestore document missing `offerPrice` field
- **hasOffer is false**: Logic error in comparison
- **discountPercent is 0**: Offer price equals base price

---

## Step 4: Test Add to Cart Button

### Action
1. Tap "Get Service" button on any card
2. On service details screen, tap "Add to Cart" button
3. Check console

### Expected Logs (Complete Flow)
```
🟢 [CARD] GET SERVICE BUTTON TAPPED - Service: AC Repair
🛒 [ADD TO CART] Button tapped for: AC Repair
🛒 [ADD TO CART] State set to loading
🛒 [CartProvider.addItem] Called with item: AC Repair
🛒 [CartProvider.addItem] Calling firestore_service.addToCart()
🛒 [FirestoreService.addToCart] Called with userId=abc123, item=AC Repair
🛒 [FirestoreService.addToCart] Calling Cloud Function addToCartCallable
✅ [FirestoreService.addToCart] Cloud Function succeeded
✅ [CartProvider.addItem] Success
✅ [ADD TO CART] Item added successfully
✅ [ADD TO CART] Showing success dialog
```

### What to Check
- ✅ Is button tap detected (🟢 log)?
- ✅ Is CartProvider.addItem called (🛒 log)?
- ✅ Is userId available (not null)?
- ✅ Is Cloud Function called (🛒 log)?
- ✅ Does Cloud Function succeed (✅ log)?
- ✅ Is dialog shown (✅ log)?

### If Issue Found
- **No 🟢 log**: Button tap is blocked (overlay issue)
- **No 🛒 CartProvider log**: Provider not registered or not called
- **userId is null**: Auth issue
- **No Cloud Function log**: Network issue or function not deployed
- **❌ Cloud Function error**: Check Cloud Functions logs

---

## Step 5: Test Like Button

### Action
1. On service details screen, tap heart icon (top right)
2. Check console

### Expected Logs (Complete Flow)
```
❤️ [LIKE BUTTON] Tapped for service: AC Repair
❤️ [LIKE BUTTON] Calling toggleFavorite()
❤️ [FavoritesProvider.toggleFavorite] Called for serviceId=svc123, categoryId=cat456
❤️ [FavoritesProvider.toggleFavorite] wasFavorite=false
❤️ [FavoritesProvider.toggleFavorite] Optimistic UI updated, notifying listeners
❤️ [FavoritesProvider.toggleFavorite] Calling firestore_service.toggleFavorite()
❤️ [FirestoreService.toggleFavorite] Called with userId=abc123, serviceId=svc123, isFavorite=true
❤️ [FirestoreService.toggleFavorite] Calling Cloud Function toggleFavoriteCallable
✅ [FirestoreService.toggleFavorite] Cloud Function succeeded
✅ [LIKE BUTTON] After toggle, isFavorite: true
```

### What to Check
- ✅ Is button tap detected (❤️ log)?
- ✅ Is FavoritesProvider.toggleFavorite called (❤️ log)?
- ✅ Is optimistic UI updated (❤️ log)?
- ✅ Is Cloud Function called (❤️ log)?
- ✅ Does Cloud Function succeed (✅ log)?
- ✅ Is icon updated (❤️ log)?

### If Issue Found
- **No ❤️ log**: Button tap is blocked (overlay issue)
- **No FavoritesProvider log**: Provider not registered or not called
- **No Cloud Function log**: Network issue or function not deployed
- **❌ Cloud Function error**: Check Cloud Functions logs

---

## Troubleshooting Guide

### Issue: No logs appearing at all
**Solution:**
1. Check if app is running in debug mode
2. Check if console is properly connected
3. Try: `flutter logs --clear` then run again
4. Check if print() statements are being compiled out

### Issue: Button tap not detected (no 🟢 or ❤️ log)
**Possible Causes:**
1. Widget is blocked by overlay (Stack/Positioned issue)
2. GestureDetector not wrapping the button
3. Button is disabled (onPressed: null)

**Fix:**
1. Check widget hierarchy in code
2. Ensure GestureDetector wraps the button
3. Check if button is disabled

### Issue: Provider not called (no 🛒 or ❌ log)
**Possible Causes:**
1. Provider not registered in main.dart
2. Provider.of() not finding the provider
3. Provider is null

**Fix:**
1. Check main.dart MultiProvider list
2. Verify provider is ChangeNotifierProvider
3. Check if userId is set in provider

### Issue: Cloud Function fails (❌ log)
**Possible Causes:**
1. Cloud Function not deployed
2. Cloud Function has error
3. Network issue
4. Authentication issue

**Fix:**
1. Check Cloud Functions deployment: `firebase deploy --only functions`
2. Check Cloud Functions logs in Firebase Console
3. Check network connectivity
4. Check Firebase authentication

---

## Log Filtering Tips

### Filter by Feature
```bash
# Only cart logs
flutter logs | grep "CART"

# Only favorite logs
flutter logs | grep "LIKE"

# Only errors
flutter logs | grep "❌"

# Only success
flutter logs | grep "✅"
```

### Filter by Emoji
```bash
# All card events
flutter logs | grep "🔵\|🟢"

# All operations
flutter logs | grep "🛒\|❤️"

# All results
flutter logs | grep "✅\|❌"
```

---

## Next Steps After Debugging

1. **Identify the exact point where logs stop**
2. **Note the last successful log**
3. **Check the code at that point**
4. **Look for:**
   - Null values
   - Missing providers
   - Disabled buttons
   - Network errors
   - Cloud Function errors

5. **Report findings with:**
   - Complete console output
   - Last successful log
   - Expected next log
   - Actual behavior

---

## Quick Reference: Log Meanings

| Log | Meaning |
|-----|---------|
| 🔵 [CARD] | Card UI event |
| 🟢 [CARD] | Button tap on card |
| 🛒 [ADD TO CART] | Add to cart flow |
| 🛒 [CartProvider] | Cart provider action |
| 🛒 [FirestoreService] | Firestore cart operation |
| ❤️ [LIKE BUTTON] | Like button tap |
| ❤️ [FavoritesProvider] | Favorites provider action |
| ❤️ [FirestoreService] | Firestore favorite operation |
| ✅ | Success |
| ❌ | Error |
| ⚠️ | Warning |
| 📊 | Debug data |

---

## Files with Debug Logs

1. `real_services_sections.dart` - Card display & button taps
2. `service_details_screen.dart` - Add to cart & like button
3. `cart_provider.dart` - Cart provider operations
4. `favorites_provider.dart` - Favorites provider operations
5. `firestore_service.dart` - Cloud Function calls

---

**Ready to debug? Run the app and check the console!**
