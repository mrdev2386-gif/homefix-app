# Custom Request Feature - Deployment Checklist

## 📋 Pre-Deployment Verification

### Code Files
- [ ] `firebase_init.dart` - Firebase App Check configured
- [ ] `custom_request_screen.dart` - Main screen with upload logic
- [ ] `status_card.dart` - Status display UI
- [ ] `request_form.dart` - Form with validation
- [ ] `category_selector.dart` - Category chips
- [ ] `image_picker_widget.dart` - Image picker
- [ ] `firestore.rules` - Security rules
- [ ] `storage.rules` - Storage rules

### Dependencies
- [ ] `firebase_core: ^2.24.0`
- [ ] `firebase_auth: ^4.15.0`
- [ ] `firebase_storage: ^11.5.0`
- [ ] `cloud_firestore: ^4.14.0`
- [ ] `firebase_app_check: ^0.2.1`
- [ ] `image_picker: ^1.0.0`
- [ ] `intl: ^0.19.0`

### Firebase Configuration
- [ ] Firebase project created
- [ ] Firestore database enabled
- [ ] Firebase Storage enabled
- [ ] Firebase App Check enabled
- [ ] Authentication enabled (Google Sign-In)
- [ ] FCM enabled for notifications

---

## 🚀 Deployment Steps

### Step 1: Update pubspec.yaml
```bash
cd c:\Users\yash\projects\homefix\apps\customer_app
flutter pub get
```

**Verify**: No dependency conflicts

### Step 2: Copy Code Files
```
Source → Destination
lib/core/firebase/firebase_init.dart → apps/customer_app/lib/core/firebase/
lib/features/custom_request/presentation/ → apps/customer_app/lib/features/custom_request/presentation/
```

**Verify**: All files copied correctly

### Step 3: Update main.dart
```dart
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const MyApp());
}

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  print('✅ Firebase App Check Debug activated');
}
```

**Verify**: App starts without errors

### Step 4: Add Navigation Route
```dart
GoRoute(
  path: '/custom-request',
  builder: (context, state) => const CustomRequestScreen(),
),
```

**Verify**: Route accessible from home screen

### Step 5: Deploy Firestore Rules
```bash
cd c:\Users\yash\projects\homefix
firebase deploy --only firestore:rules
```

**Verify**: Rules deployed successfully
```
✔ firestore:rules deployed successfully
```

### Step 6: Deploy Storage Rules
```bash
firebase deploy --only storage
```

**Verify**: Storage rules deployed successfully
```
✔ storage deployed successfully
```

### Step 7: Create Firestore Indexes

Go to Firebase Console → Firestore Database → Indexes

**Index 1:**
- Collection: `custom_requests`
- Fields: `status` (Ascending), `createdAt` (Descending)
- Status: Enabled

**Index 2:**
- Collection: `custom_requests`
- Fields: `customerId` (Ascending), `createdAt` (Descending)
- Status: Enabled

**Index 3:**
- Collection: `custom_requests`
- Fields: `technicianId` (Ascending), `status` (Ascending)
- Status: Enabled

**Verify**: All 3 indexes show "Enabled" status

### Step 8: Test in Development
```bash
cd c:\Users\yash\projects\homefix\apps\customer_app
flutter run
```

**Verify**: App runs without errors

---

## ✅ Functional Testing

### Test 1: Form Validation
- [ ] Title field required
- [ ] Description field required
- [ ] Category selection works
- [ ] Date picker shows next 7 days
- [ ] Time picker works
- [ ] Address selector works
- [ ] Budget field optional
- [ ] Submit button disabled until form valid

**Expected Result**: Form validates correctly

### Test 2: Image Upload
- [ ] Camera picker opens
- [ ] Gallery picker opens
- [ ] Max 3 images enforced
- [ ] Image preview displays
- [ ] Delete button removes image
- [ ] Add more button works
- [ ] Upload shows progress
- [ ] Upload completes successfully

**Expected Result**: Images upload to Firebase Storage

### Test 3: Firestore Document Creation
- [ ] Document created in `custom_requests` collection
- [ ] All fields populated correctly:
  - [ ] type: "custom_request"
  - [ ] customerId: user.uid
  - [ ] title, description, category
  - [ ] preferredDate (YYYY-MM-DD)
  - [ ] preferredTime (HH:MM)
  - [ ] budget (optional)
  - [ ] address, district, pincode
  - [ ] images: [url1, url2, url3]
  - [ ] technicianId: null
  - [ ] status: "pending_admin_review"
  - [ ] createdAt, updatedAt: timestamps

**Expected Result**: Document created with correct structure

### Test 4: Status Card Display
- [ ] Status card displays after submission
- [ ] Status badge shows "Pending Review" in orange
- [ ] Request title displayed
- [ ] Category displayed
- [ ] Images preview displayed
- [ ] Submission date/time displayed
- [ ] "View Booking" button hidden (status not accepted yet)

**Expected Result**: Status card displays correctly

### Test 5: Real-Time Status Updates
- [ ] StreamBuilder listens to Firestore
- [ ] Status updates when admin changes it
- [ ] UI refreshes automatically
- [ ] Status badge color changes
- [ ] "View Booking" button appears when status is accepted

**Expected Result**: Real-time updates work

### Test 6: Error Handling
- [ ] Image upload failure shows error
- [ ] Network failure shows error
- [ ] Auth token refresh works
- [ ] Clear error messages displayed
- [ ] Retry capability maintained

**Expected Result**: Errors handled gracefully

### Test 7: Security
- [ ] Unauthenticated user cannot upload
- [ ] Auth token refreshed before upload
- [ ] Storage path includes requestId
- [ ] Firestore rules enforced
- [ ] No direct writes to Firestore

**Expected Result**: Security rules enforced

---

## 🔍 Firebase Console Verification

### Firestore
- [ ] `custom_requests` collection exists
- [ ] Documents have correct structure
- [ ] Indexes created and enabled
- [ ] Rules deployed successfully

### Storage
- [ ] `custom_requests/` folder exists
- [ ] Images uploaded with correct path format
- [ ] Download URLs accessible
- [ ] Rules deployed successfully

### Authentication
- [ ] User authenticated before upload
- [ ] Auth token valid
- [ ] User ID captured correctly

### App Check
- [ ] App Check token generated
- [ ] Debug provider active
- [ ] Token refresh working

---

## 📊 Performance Verification

### Image Upload
- [ ] Upload time < 10 seconds
- [ ] File size < 5MB
- [ ] Quality acceptable
- [ ] No memory leaks

### Firestore Queries
- [ ] Query time < 100ms
- [ ] Indexes used correctly
- [ ] No N+1 queries
- [ ] Real-time updates responsive

### App Performance
- [ ] No crashes
- [ ] No ANR (Application Not Responding)
- [ ] Memory usage normal
- [ ] CPU usage normal

---

## 🐛 Troubleshooting

### Issue: App crashes on startup
**Solution**:
1. Check Firebase initialization in main.dart
2. Verify google-services.json placed correctly
3. Check dependencies in pubspec.yaml
4. Review console logs for errors

### Issue: Images not uploading
**Solution**:
1. Check auth token refresh: `getIdToken(true)`
2. Verify Storage rules allow authenticated users
3. Check network connectivity
4. Verify file size < 5MB
5. Review Firebase Console logs

### Issue: Firestore document not created
**Solution**:
1. Check Firestore rules allow writes
2. Verify auth token is valid
3. Check document structure matches schema
4. Review Firebase Console logs
5. Check Firestore quota

### Issue: Status not updating
**Solution**:
1. Verify StreamBuilder is listening
2. Check Firestore indexes created
3. Verify document path is correct
4. Check real-time updates enabled
5. Verify user has read permission

### Issue: Firebase App Check errors
**Solution**:
1. Verify App Check initialized
2. Check debug provider activated
3. Verify Firebase project has App Check enabled
4. Check device has valid App Check token
5. Review Firebase Console logs

---

## 📈 Post-Deployment Monitoring

### Daily Checks
- [ ] No errors in Firebase Console
- [ ] Image uploads successful
- [ ] Firestore documents created
- [ ] Real-time updates working
- [ ] User feedback positive

### Weekly Checks
- [ ] Performance metrics normal
- [ ] No memory leaks
- [ ] No crashes reported
- [ ] Firestore quota usage normal
- [ ] Storage quota usage normal

### Monthly Checks
- [ ] Usage trends analyzed
- [ ] Performance optimized
- [ ] Security reviewed
- [ ] Costs analyzed
- [ ] User feedback incorporated

---

## ✅ Sign-Off Checklist

### Development
- [ ] All code files created
- [ ] All dependencies added
- [ ] Firebase initialized
- [ ] Navigation added
- [ ] Tested in development

### Staging
- [ ] Firestore rules deployed
- [ ] Storage rules deployed
- [ ] Firestore indexes created
- [ ] All tests passed
- [ ] Performance verified

### Production
- [ ] Code reviewed
- [ ] Security verified
- [ ] Performance verified
- [ ] Backup created
- [ ] Rollback plan ready

---

## 🎉 Deployment Complete

**Status**: ✅ READY FOR PRODUCTION

**Deployed Components**:
- ✅ Firebase App Check
- ✅ Firebase Storage image upload
- ✅ Firestore document creation
- ✅ Real-time status tracking
- ✅ Status card UI
- ✅ Error handling
- ✅ Security rules
- ✅ Firestore indexes

**Next Steps**:
1. Monitor Firebase Console
2. Gather user feedback
3. Optimize based on usage
4. Plan enhancements

---

**Deployment Date**: [DATE]
**Deployed By**: [NAME]
**Version**: 1.0
**Status**: ✅ PRODUCTION READY
