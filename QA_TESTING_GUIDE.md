# HomeFix QA Testing Guide

## Overview

This guide covers testing procedures for the HomeFix Flutter customer app, including Firebase emulator setup, App Check debug token configuration, and deployment steps.

---

## 1. Environment Setup

### Prerequisites
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install Flutter dependencies
cd apps/customer_app
flutter pub get
```

### Firebase Project Configuration
- **Project ID**: `homefix-prod` (or your project ID)
- **Android Package**: `com.homefix.customer`
- **iOS Bundle ID**: `com.homefix.customer`

---

## 2. App Check Debug Token Setup

### Step 1: Get Debug Token
```bash
# Clean and run the app
cd apps/customer_app
flutter clean
flutter pub get
flutter run -v
```

### Step 2: Find Token in Logs
Look for this output in the console:
```
═══════════════════════════════════════════════════════════
🎫 APP CHECK DEBUG TOKEN:
   Copy this token and add it to Firebase Console:
   Firebase Console → App Check → Apps → Manage debug tokens
   Token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
═══════════════════════════════════════════════════════════
```

### Step 3: Add Token to Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **App Check** → **Apps**
4. Click on your Android app
5. Click **Manage debug tokens**
6. Click **Add debug token**
7. Paste the token from logs
8. Click **Save**

### Troubleshooting App Check
If token doesn't appear:
1. Uninstall the app completely
2. Run `flutter clean`
3. Run `flutter run` again
4. Wait 10-15 seconds for token to generate

---

## 3. Firebase Emulator Testing

### Start Emulators
```bash
# From project root
firebase emulators:start --only firestore,storage,functions
```

### Emulator URLs
- Firestore: http://localhost:8080
- Storage: http://localhost:9199
- Functions: http://localhost:5001
- Emulator UI: http://localhost:4000

### Configure App for Emulators
In `main.dart`, add before `runApp()`:
```dart
if (kDebugMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

---

## 4. Test Scenarios

### 4.1 Profile Photo Upload
```
1. Login with test account
2. Go to Profile → Edit Profile
3. Tap profile photo
4. Select image from gallery
5. Verify upload succeeds (no 403/404 errors)
6. Verify image displays correctly
```

**Expected Logs:**
```
[StorageService] Uploading profile photo for user: <uid>
[StorageService] Upload path: users/<uid>/profile/profile.jpg
[StorageService] Upload complete. URL: https://...
```

### 4.2 Partner Onboarding Flow
```
1. Login with test account
2. Go to Profile → Become a Partner
3. Complete all 8 steps:
   - Personal Info (name, phone, email)
   - Service Categories (select at least 1)
   - Experience (years)
   - Profile Photo (upload)
   - ID Proof (upload)
   - Address (enter full address)
   - Bank Details (account, IFSC)
   - Terms (accept)
4. Click Submit Application
5. Verify success dialog appears
```

**Expected Behavior:**
- Each step validates before allowing Next
- Submit button shows loading state
- Success dialog appears on completion
- Application saved to Firestore

### 4.3 Video Playback
```
1. Navigate to a service with video
2. Tap to play video
3. Verify video loads without 403 error
```

**Expected Logs:**
```
[VideoService] Getting download URL for: videos/service_xxx.mp4
[VideoService] Download URL obtained: https://firebasestorage.googleapis.com/...
```

### 4.4 Location Detection
```
1. Open app
2. Tap location selector
3. Allow location permission
4. Verify location confirm popup appears
5. Edit address if needed
6. Tap Confirm & Save
```

**Expected Behavior:**
- Loading dialog shows during detection
- Confirm popup shows with map preview
- Address fields are editable
- Save succeeds without errors

### 4.5 Address Management
```
1. Go to Profile → Saved Addresses
2. Add new address
3. Edit existing address
4. Delete address
5. Set default address
```

---

## 5. Security Rules Testing

### Test Firestore Rules
```bash
# Install rules testing library
npm install @firebase/rules-unit-testing

# Run tests
npm test
```

### Manual Rule Testing
```javascript
// Test customer can read own addresses
firebase.firestore()
  .collection('customers')
  .doc(userId)
  .collection('addresses')
  .get()
// Should succeed for authenticated user

// Test customer cannot read other's addresses
firebase.firestore()
  .collection('customers')
  .doc(otherUserId)
  .collection('addresses')
  .get()
// Should fail with PERMISSION_DENIED
```

### Test Storage Rules
```javascript
// Test user can upload to own profile
firebase.storage()
  .ref(`users/${userId}/profile/profile.jpg`)
  .put(file)
// Should succeed

// Test user cannot upload to other's profile
firebase.storage()
  .ref(`users/${otherUserId}/profile/profile.jpg`)
  .put(file)
// Should fail with 403
```

---

## 6. Deployment

### Deploy Firebase Rules
```bash
# Deploy all rules
firebase deploy --only firestore:rules,storage

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Deploy only Storage rules
firebase deploy --only storage
```

### Deploy Cloud Functions
```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:submitPartnerApplication
```

### Full Deployment
```bash
firebase deploy --only storage,firestore:rules,functions
```

---

## 7. Test Accounts

### Customer Test Account
- Phone: +91 9999999999
- OTP: 123456 (test mode)

### Partner Test Account
- Phone: +91 8888888888
- OTP: 123456 (test mode)

---

## 8. Common Issues & Solutions

### Issue: App Check 403 Error
**Solution:**
1. Ensure debug token is added to Firebase Console
2. Uninstall app and reinstall
3. Check logs for new token

### Issue: Storage Upload 404
**Solution:**
1. Verify storage rules allow the path
2. Check upload path matches rules exactly
3. Ensure user is authenticated

### Issue: Firestore Permission Denied
**Solution:**
1. Check Firestore rules for the collection
2. Verify user authentication
3. Check if App Check is blocking

### Issue: Video 403 Error
**Solution:**
1. Ensure using `getDownloadURL()` before playback
2. Check storage rules for video path
3. Verify App Check token is valid

---

## 9. Checklist Before Release

- [ ] All test scenarios pass
- [ ] No console errors during normal flow
- [ ] App Check works in release mode
- [ ] Storage uploads succeed
- [ ] Firestore reads/writes work
- [ ] Video playback works
- [ ] Partner onboarding completes
- [ ] Location detection works
- [ ] Profile photo upload works
- [ ] Address management works

---

## 10. Wireless ADB Testing

### Connect Device
```bash
# Enable wireless debugging on device
# Settings → Developer Options → Wireless debugging

# Connect via ADB
adb connect 192.168.31.178:5555

# Verify connection
adb devices

# Run Flutter
flutter run
```

### View Logs
```bash
# View all logs
adb logcat

# Filter Flutter logs
adb logcat | grep flutter

# Filter Firebase logs
adb logcat | grep -E "(Firebase|AppCheck|Storage)"
```

---

## Contact

For issues with this guide, contact the development team.
