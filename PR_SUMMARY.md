# HomeFix Firebase Fixes - Pull Request Summary

## Overview
This PR addresses critical Firebase security and functionality issues including App Check, Storage uploads, Firestore permissions, video playback, and partner onboarding.

---

## Changes by Area

### 1. Firebase App Check (`apps/customer_app/lib/main.dart`)
**Issue**: App Check debug token missing, 403 errors in debug mode

**Changes**:
- Added `onTokenChange` listener to log debug token at startup
- Enhanced debug logging with clear instructions for adding token to Firebase Console
- Added fallback error handling for App Check failures

**Files Changed**:
- `apps/customer_app/lib/main.dart` (lines 48-69)

### 2. Storage Rules (`storage.rules`)
**Issue**: Upload path mismatch between client and rules

**Changes**:
- Aligned rules with client code paths:
  - `users/{userId}/profile/profile.jpg` 
  - `technicians/{techId}/{docType}/{fileName}`
- Added proper content type and size validation
- Added metadata.ownerId for support attachments

**Rules Updated**:
- User profile images (lines 37-53)
- Technician documents (lines 61-72)
- Video reels (lines 74-79)
- Support attachments (lines 81-85)

### 3. Firestore Rules (`firestore.rules`)
**Issue**: Permission denied on addresses and FCM tokens

**Changes**:
- Added explicit rules for `customers/{userId}/addresses/{addressId}` (lines 85-90)
- Added explicit rules for `customers/{userId}/fcmTokens/{tokenId}` (lines 97-102)
- Added explicit rules for `technicians/{techId}/fcmTokens/{tokenId}` (lines 77-83)
- All owner-write rules properly scoped to `request.auth.uid`

### 4. Partner Onboarding UI
**Issue**: Broken 8-step UI, submit button not working

**Files Changed**:
- `partner_onboarding_screen_v2.dart` - Main screen with progress indicator
- `onboarding_step_personal.dart` - Personal info with validation
- `onboarding_step_categories.dart` - Categories with subcategories
- `onboarding_step_experience.dart` - Experience with level indicator
- `onboarding_step_photo.dart` - Profile photo upload
- `onboarding_step_id_proof.dart` - ID document upload
- `onboarding_step_address.dart` - Service address
- `onboarding_step_bank.dart` - Bank details with validation
- `onboarding_step_terms.dart` - Terms agreement

**Improvements**:
- Modern card-based UI with gradients and shadows
- Animated step transitions
- Persistent TextEditingControllers (created in initState, disposed properly)
- Inline validation with error messages
- Loading state on submit button
- Success dialog animation

### 5. Location Dialogs (`apps/customer_app/lib/core/widgets/location_dialogs.dart`)
**Issue**: Location fetch needed modern confirmation popup

**Changes**:
- Created `LocationConfirmDialog` with:
  - Static map preview placeholder
  - GPS accuracy badge
  - Label selection (Home/Work/Other)
  - Editable address fields
  - Confirm & Save button
- Created `LocationDetectionDialog` for loading state
- Created `LocationPermissionDialog` for permission denial

**Usage**:
```dart
final result = await LocationConfirmDialog.show(
  context: context,
  address: detectedAddress,
  latitude: lat,
  longitude: lng,
);
if (result != null) {
  // Save address to Firestore
}
```

### 6. Functions Service (`apps/customer_app/lib/core/services/functions_service.dart`)
**Issue**: Missing callable functions for secure operations

**Changes Added**:
- `saveFcmToken()` - Securely save FCM token
- `submitPartnerApplication()` - Submit partner application
- `saveAddress()` - Securely save address

### 7. QA Documentation (`QA_TESTING_GUIDE.md`)
Created comprehensive testing guide including:
- Environment setup
- App Check debug token configuration
- Firebase emulator testing
- Test scenarios for all features
- Security rules testing
- Deployment commands
- Troubleshooting common issues

---

## Files Changed Summary

| File | Changes |
|------|---------|
| `apps/customer_app/lib/main.dart` | App Check debug token logging |
| `storage.rules` | Path alignment, content validation |
| `firestore.rules` | Addresses & FCM tokens rules |
| `apps/customer_app/lib/core/widgets/location_dialogs.dart` | New location confirm modal |
| `apps/customer_app/lib/core/services/functions_service.dart` | Added callable functions |
| `apps/customer_app/lib/features/profile/presentation/partner_onboarding_screen_v2.dart` | Modern onboarding UI |
| `apps/customer_app/lib/features/profile/presentation/widgets/*.dart` | All 8 step widgets modernized |
| `QA_TESTING_GUIDE.md` | Comprehensive QA guide |

---

## Security Compliance

✅ **No public write rules** - All writes require authentication  
✅ **No wildcard permissions** - Explicit paths for each collection  
✅ **Owner-only writes** - Users can only modify their own data  
✅ **App Check enabled** - Debug mode with Play Integrity in production  
✅ **Callable functions** - Sensitive operations go through Cloud Functions  

---

## Deployment Commands

```bash
# Deploy Firebase rules
firebase deploy --only firestore:rules,storage

# Deploy Cloud Functions (after implementing backend)
firebase deploy --only functions
```

---

## Testing Checklist

- [ ] App Check debug token appears in logs
- [ ] Profile photo upload succeeds
- [ ] ID proof upload succeeds
- [ ] Partner onboarding submits successfully
- [ ] Video playback uses getDownloadURL()
- [ ] Location confirm popup works
- [ ] Addresses can be saved/edited/deleted
- [ ] FCM tokens are saved correctly
- [ ] No PERMISSION_DENIED errors in normal flow

---

## Known Issues / Future Work

1. **Cloud Functions**: Backend implementation needed for:
   - `submitPartnerApplication`
   - `saveFcmToken`
   - `saveAddress`
   - `updateUserProfile`

2. **Static Maps**: Replace placeholder with real Google Static Maps API key

3. **Tests**: Integration tests using Firebase Emulators need to be implemented
