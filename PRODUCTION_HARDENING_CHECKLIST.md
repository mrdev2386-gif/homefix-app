# HomeFix Production Hardening Checklist

## 1. Firebase Console Configuration

### App Check Setup
- [ ] Enable App Check in Firebase Console
- [ ] Register Android app with Play Integrity provider
- [ ] Register iOS app with DeviceCheck provider
- [ ] Add debug tokens for development devices
- [ ] Verify App Check enforcement is enabled for Firestore
- [ ] Verify App Check enforcement is enabled for Storage

### Firestore Indexes
- [ ] Deploy composite indexes from firestore.indexes.json
- [ ] Verify indexes are built (check Firebase Console → Firestore → Indexes)
- [ ] Test queries that require composite indexes

### Security Rules
- [ ] Deploy firestore.rules
- [ ] Deploy storage.rules
- [ ] Test rules with Firebase Emulator Suite
- [ ] Verify no public write access
- [ ] Verify authenticated read access for user data

## 2. Cloud Functions Deployment

### Required Commands
```bash
cd functions
npm run build
firebase deploy --only functions
```

### Function Verification
- [ ] `createBooking` callable works
- [ ] `matchTechnicians` callable works
- [ ] `updateBookingStatus` callable works
- [ ] Firestore triggers fire correctly
- [ ] Background functions scheduled correctly

### Environment Configuration
```bash
# Set required config
firebase functions:config:set razorpay.key_id="your_key_id" razorpay.key_secret="your_key_secret"
firebase functions:config:set app.name="homefix" environment="production"
```

## 3. Android Configuration

### Google Play Services
- [ ] Verify Google Play services version (min 20.0.0+)
- [ ] Configure Google API Manager project
- [ ] Enable required APIs:
  - Google Maps Platform (if using location)
  - Firebase Cloud Messaging

### API Key Restrictions
```json
{
  "restrictions": {
    "apiKeys": [
      {
        "keyRestrictionType": "androidApps",
        "androidApps": [
          {
            "digitialSignature": "SHA-256_FINGERPRINT",
            "packageName": "com.homefix.customer"
          }
        ]
      }
    ]
  }
}
```

### ExoPlayer Video Playback Fix
- [ ] Use Firebase Storage getDownloadURL() for video URLs
- [ ] Do NOT use direct storage URLs
- [ ] Implement token refresh handling

## 4. iOS Configuration

### Info.plist Updates
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to find nearby technicians.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to upload photos for your bookings.</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access for profile photos.</string>
```

### App Check
- [ ] Configure App Check provider in AppDelegate
- [ ] Test on physical device (simulator won't work)

## 5. Security Checklist

### Authentication
- [ ] Email/password authentication enabled
- [ ] Phone authentication enabled (OTP)
- [ ] Anonymous auth disabled (if not needed)
- [ ] Account deletion enabled

### Firestore Security
- [ ] All writes require authentication
- [ ] No collection has `allow write: if true`
- [ ] Owner-only access for user documents
- [ ] Admin-only access for sensitive data

### Storage Security
- [ ] No public write access
- [ ] Metadata validation enabled
- [ ] File size limits enforced
- [ ] Content type validation enabled

## 6. Performance Checklist

### Firestore
- [ ] Use queries instead of documents where possible
- [ ] Implement pagination for lists
- [ ] Cache frequently accessed data
- [ ] Use document references for nested data

### Cloud Functions
- [ ] Implement cold start mitigation
- [ ] Set appropriate timeout limits
- [ ] Configure memory allocation
- [ ] Enable function scaling

## 7. Monitoring & Logging

### Firebase Crashlytics
- [ ] Crashlytics enabled
- [ ] Custom logs added for debugging
- [ ] Error boundaries implemented in Flutter

### Performance Monitoring
- [ ] Firebase Performance enabled
- [ ] Network request monitoring
- [ ] Slow rendering detection

## 8. Known Issues & Mitigations

### BLASTBufferQueue Errors (Android)
- **Cause**: Android graphics buffer issues with some devices
- **Mitigation**: 
  - Update to latest Flutter SDK
  - Use hardware acceleration carefully
  - Report to Flutter team if persistent

### GoogleApiManager DEVELOPER_ERROR
- **Cause**: API key configuration issue
- **Fix**:
  - Enable Maps SDK for Android in Google Cloud Console
  - Add SHA-256 fingerprint to API key restrictions
  - Verify API key is included in AndroidManifest.xml

### ExoPlayer 403 Errors
- **Cause**: Direct storage URLs without authentication token
- **Fix**:
  ```dart
  // CORRECT: Use getDownloadURL()
  final ref = FirebaseStorage.instance.ref(path);
  final url = await ref.getDownloadURL();
  videoPlayerController.setNetworkSrc(url);
  ```

### Navigator Null Crash
- **Cause**: Context used after widget disposal
- **Fix**:
  ```dart
  if (!mounted) return;
  Navigator.of(context).pop();
  ```

## 9. Testing Checklist

### Unit Tests
- [ ] Cloud Functions unit tests pass
- [ ] Flutter widget tests pass
- [ ] Service layer tests pass

### Integration Tests
- [ ] Firebase Emulator Suite tests pass
- [ ] E2E tests for critical flows:
  - User registration
  - Booking creation
  - Technician matching
  - Payment processing

## 10. Deployment Commands Summary

```bash
# 1. Deploy Firestore rules
firebase deploy --only firestore:rules

# 2. Deploy Storage rules  
firebase deploy --only storage:rules

# 3. Deploy Firestore indexes
firebase deploy --only firestore:indexes

# 4. Build and deploy Cloud Functions
cd functions
npm run build
firebase deploy --only functions

# 5. Deploy to specific environment
firebase use production  # or staging
firebase deploy --only firestore,storage,functions

# 6. Full deploy (includes hosting)
firebase deploy
```

## 11. Rollback Plan

If issues arise after deployment:

```bash
# Rollback Firestore rules
firebase firestore:rules:deploy --only previous_rules_backup.rules

# Rollback Cloud Functions
firebase functions:rollback

# Check deployment status
firebase deploy:list
```

## 12. Post-Deployment Verification

- [ ] Test user registration flow
- [ ] Test booking creation with test payment
- [ ] Verify technician matching returns results
- [ ] Check push notifications work
- [ ] Monitor Crashlytics for new errors
- [ ] Check Cloud Functions logs for errors
- [ ] Verify App Check rejection logs (if any)
