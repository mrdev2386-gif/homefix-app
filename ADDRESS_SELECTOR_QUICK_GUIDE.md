# Address Selector - Quick Reference

## What Was Implemented

Complete "Delivering To" address selector with 3 fully functional options:

### 1. Current Location ✅
- GPS-based location with permission handling
- Saves location to Firestore automatically
- Shows loading indicator
- Error handling with user feedback

### 2. Add New Address ✅
- Opens address form
- Saves via Cloud Function
- Returns to previous screen

### 3. Saved Addresses ✅
- Shows list of saved addresses
- Tap to select
- Persists selection to user profile
- Updates UI immediately

## Files Changed

### New Files
1. `apps/customer_app/lib/core/services/address_service.dart` - Address management service

### Modified Files
1. `apps/customer_app/lib/core/providers/location_provider.dart` - Enhanced with permissions & persistence
2. `apps/customer_app/lib/features/dashboard/dashboard_screen.dart` - Updated bottom sheet handlers
3. `apps/customer_app/lib/features/profile/presentation/saved_addresses_screen.dart` - Added selection persistence
4. `apps/customer_app/pubspec.yaml` - Added permission_handler
5. `apps/customer_app/ios/Runner/Info.plist` - Added location permissions

## How It Works

### User Taps "DELIVERING TO"
```
Dashboard → Bottom Sheet Opens
```

### Option 1: Current Location
```
Tap → Close Sheet → Loading Dialog → Check Permission
  ├─ Denied → SnackBar with "Settings" button
  └─ Granted → Get GPS → Save to Firestore → Update UI → Close Loading
```

### Option 2: Add New Address
```
Tap → Close Sheet → Navigate to AddEditAddressScreen → Fill Form → Save → Return
```

### Option 3: Saved Addresses
```
Tap → Close Sheet → Navigate to SavedAddressesScreen → Tap Address → Persist Selection → SnackBar → Return → UI Updates
```

## Key Features

### Security
- No direct Firestore writes from UI
- All mutations via Cloud Functions
- Read-only address access

### UX
- Loading indicators
- Error messages
- Success feedback
- Permission handling
- Smooth navigation

### Persistence
- Selected address saved to user profile
- Loads on app start
- Survives app restart

## Testing

### Quick Test Flow
1. Open app → Tap "DELIVERING TO"
2. Test "Current Location" → Should request permission → Get GPS → Save → Update UI
3. Test "Add New Address" → Should open form → Fill & save → Return
4. Test "Saved Addresses" → Should show list → Tap one → Update UI → Show success

### Expected Behavior
- ✅ All 3 options clickable
- ✅ Current Location requests permission
- ✅ GPS location saves to Firestore
- ✅ Add New Address opens form
- ✅ Saved Addresses shows list
- ✅ Tapping address updates UI
- ✅ Selection persists across restarts
- ✅ Loading indicators appear
- ✅ Error messages show when needed

## Dependencies Added

```yaml
permission_handler: ^11.0.1
```

Run: `flutter pub get`

## Platform Permissions

### Android (Already Present)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (Added)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby services and deliver to your address</string>
```

## Cloud Function Required

**Function:** `manageAddress`

**Actions:** add, edit, delete, setDefault

Must be deployed and working.

## Firestore Structure

### User Profile
```
customers/{userId}
  └─ selectedAddressId: "address_doc_id"
```

### Addresses
```
customers/{userId}/addresses/{addressId}
  ├─ label: "Home|Office|Other|Current Location"
  ├─ fullAddress: "Complete address"
  ├─ latitude: 12.345
  ├─ longitude: 78.901
  └─ isDefault: false
```

## Common Issues & Solutions

### Permission Denied
- User sees SnackBar with "Settings" button
- Tapping opens app settings
- User can enable location permission

### GPS Not Working
- Check if location services enabled on device
- Check if app has permission
- Try on real device (not emulator)

### Address Not Persisting
- Verify Cloud Function is deployed
- Check Firestore security rules
- Check network connection

### UI Not Updating
- Verify LocationProvider is properly initialized
- Check if `notifyListeners()` is called
- Verify Consumer/Provider setup

## Next Steps

### Optional Enhancements
1. Add Google Maps picker to address form
2. Add address autocomplete
3. Validate delivery range
4. Show recent locations
5. Add address verification

## Summary

✅ All 3 address selector options fully functional
✅ Production-grade architecture
✅ Secure Firestore operations
✅ Proper permission handling
✅ Error handling & loading states
✅ Zero compilation errors
✅ Ready for production
