# Firebase Functions Region Fix - Complete Deployment Guide

## 🔍 Root Cause Analysis

### Issue Identified
**CRITICAL REGION MISMATCH**: Cloud Functions were deployed across multiple regions causing "function not found" errors.

### Before Fix:
- ❌ Most functions: `us-central1`
- ❌ Some functions: `asia-south1`
- ❌ Flutter apps: `asia-south1`
- ❌ Result: Function calls failing with "not-found" errors

### After Fix:
- ✅ ALL functions: `asia-south1`
- ✅ Flutter apps: `asia-south1`
- ✅ Result: Consistent region across entire stack

---

## 📋 Functions Updated

### Technician Service Management (services_management.ts)
- ✅ `addTechnicianService` → `asia-south1`
- ✅ `updateTechnicianService` → `asia-south1`
- ✅ `deleteTechnicianService` → `asia-south1`
- ✅ `toggleTechnicianServiceStatus` → `asia-south1`
- ✅ `getMyTechnicianServices` → `asia-south1`

### Technician Profile Management (profile_management.ts)
- ✅ `updateTechnicianPersonalDetails` → `asia-south1`
- ✅ `updateTechnicianBankDetails` → `asia-south1`
- ✅ `reuploadVerificationDocument` → `asia-south1`
- ✅ `adminUpdateBankStatus` → `asia-south1`
- ✅ `adminUpdateDocumentStatus` → `asia-south1`

### Technician Tracking (tracking.ts)
- ✅ `updateLocation` → `asia-south1`
- ✅ `toggleOnlineStatus` → `asia-south1`

### Custom Requests (custom_request.ts)
- ✅ `createCustomServiceRequest` → `asia-south1`
- ✅ `adminApproveServiceRequest` → `asia-south1`
- ✅ `technicianRespondServiceRequest` → `asia-south1`
- ✅ `customerConfirmServicePayment` → `asia-south1`
- ✅ `getTechnicianInbox` → `asia-south1`
- ✅ `getCustomRequestDetail` → `asia-south1`

### Admin Services (admin/services.ts)
- ✅ `deleteService` → `asia-south1`

---

## 🚀 Deployment Steps

### Step 1: Build Functions
```powershell
cd C:\Users\yash\projects\homefix\functions
npm run build
```

**Expected Output:**
```
✔ functions: Finished running predeploy script.
```

### Step 2: Deploy ALL Functions
```powershell
firebase deploy --only functions
```

**CRITICAL**: Deploy ALL functions, not individual ones. This ensures consistency.

**Expected Output:**
```
✔ functions: Finished running predeploy script.
i functions: preparing codebase functions for deployment
i functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔ functions: required API cloudfunctions.googleapis.com is enabled
✔ functions: required API cloudbuild.googleapis.com is enabled
i functions: uploading functions archive to Firebase...
✔ functions: functions archive uploaded successfully
i functions: updating functions...
✔ functions[asia-south1-addTechnicianService]: Successful update operation.
✔ functions[asia-south1-updateTechnicianService]: Successful update operation.
✔ functions[asia-south1-deleteTechnicianService]: Successful update operation.
...
✔ Deploy complete!
```

### Step 3: Verify Deployment in Firebase Console
1. Go to: https://console.firebase.google.com/
2. Select your project
3. Navigate to: **Functions** → **Dashboard**
4. Verify ALL functions show region: **asia-south1**

### Step 4: Clean Old Functions (Optional)
If you see duplicate functions in different regions:

```powershell
# Delete old us-central1 functions
firebase functions:delete addTechnicianService --region us-central1
firebase functions:delete updateTechnicianService --region us-central1
firebase functions:delete deleteTechnicianService --region us-central1
firebase functions:delete toggleTechnicianServiceStatus --region us-central1
firebase functions:delete getMyTechnicianServices --region us-central1
firebase functions:delete updateTechnicianPersonalDetails --region us-central1
firebase functions:delete updateTechnicianBankDetails --region us-central1
firebase functions:delete reuploadVerificationDocument --region us-central1
firebase functions:delete toggleOnlineStatus --region us-central1
firebase functions:delete getTechnicianInbox --region us-central1
firebase functions:delete technicianRespondServiceRequest --region us-central1
firebase functions:delete getCustomRequestDetail --region us-central1
```

---

## ✅ Verification Checklist

### Backend Verification
- [ ] All functions built successfully (`npm run build`)
- [ ] All functions deployed successfully
- [ ] Firebase Console shows all functions in `asia-south1`
- [ ] No duplicate functions in `us-central1`

### Flutter App Verification (Technician App)

#### 1. Test Add Service
```dart
// Should succeed without "not-found" error
await FunctionsService().addService(
  name: "Test Service",
  price: 500,
  imageUrl: "https://example.com/image.jpg",
  category: "plumbing",
);
```

**Expected**: ✅ Service created successfully
**Error Before Fix**: ❌ `firebase_functions/not-found`

#### 2. Test Delete Service
```dart
// Should succeed without "not-found" error
await FunctionsService().deleteService(serviceId);
```

**Expected**: ✅ Service deleted successfully
**Error Before Fix**: ❌ `firebase_functions/not-found`

#### 3. Test Toggle Service Status
```dart
// Should succeed without "not-found" error
await FunctionsService().toggleServiceStatus(serviceId);
```

**Expected**: ✅ Status toggled successfully
**Error Before Fix**: ❌ `firebase_functions/not-found`

#### 4. Test Update Profile
```dart
// Should succeed without "not-found" error
await FunctionsService().updateTechnicianPersonalDetails(
  fullName: "Updated Name",
);
```

**Expected**: ✅ Profile updated successfully
**Error Before Fix**: ❌ `firebase_functions/not-found`

#### 5. Test Online Status Toggle
```dart
// Should succeed without "not-found" error
await FunctionsService().updateTechnicianOnlineStatus(true);
```

**Expected**: ✅ Status updated successfully
**Error Before Fix**: ❌ `firebase_functions/not-found`

---

## 🐛 Troubleshooting

### Issue: "Function not found" error persists

**Solution 1**: Clear Flutter cache
```powershell
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter clean
flutter pub get
```

**Solution 2**: Verify region in Flutter
```dart
// Check this file: lib/core/services/functions_service.dart
final FirebaseFunctions _functions =
    FirebaseFunctions.instanceFor(region: 'asia-south1'); // ✅ Correct
```

**Solution 3**: Force token refresh
```dart
final user = FirebaseAuth.instance.currentUser;
await user?.getIdToken(true); // Force refresh
```

**Solution 4**: Check Firebase Console
- Verify function exists in `asia-south1`
- Check function logs for errors
- Verify App Check is not blocking requests

### Issue: Build errors in Cloud Functions

**Solution**: Check TypeScript version
```powershell
cd C:\Users\yash\projects\homefix\functions
npm list typescript
# Should be: typescript@4.9.5
```

### Issue: Deployment timeout

**Solution**: Deploy in smaller batches
```powershell
# Deploy only technician functions first
firebase deploy --only functions:addTechnicianService,functions:updateTechnicianService,functions:deleteTechnicianService

# Then deploy remaining functions
firebase deploy --only functions
```

---

## 📊 Expected Results

### Before Fix
```
[ERROR] FirebaseFunctionsException: not-found
[ERROR] Function deleteTechnicianService not found
[ERROR] Region mismatch: calling asia-south1 but function in us-central1
```

### After Fix
```
✅ [FUNCTION CALL] Calling: deleteTechnicianService
✅ [FUNCTION CALL] UID: abc123xyz
✅ [AUTH SUCCESS] Authenticated UID: abc123xyz
✅ [SERVICE_DELETE] Service xyz123 soft deleted
✅ Service deleted successfully
```

---

## 🔐 Security Notes

1. **Authentication**: All functions verify `context.auth` before execution
2. **Token Refresh**: Flutter apps refresh tokens before each call
3. **Ownership**: Functions verify user owns the resource before modification
4. **Logging**: Comprehensive logging for debugging and audit trails

---

## 📝 Files Modified

### Backend (Cloud Functions)
1. `functions/src/technician/services_management.ts`
2. `functions/src/technician/profile_management.ts`
3. `functions/src/technician/tracking.ts`
4. `functions/src/custom_request.ts`
5. `functions/src/admin/services.ts`

### Frontend (Flutter - Technician App)
1. `apps/technician_app/lib/core/services/functions_service.dart` (already correct)
2. `apps/technician_app/lib/core/services/technician_catalog_service.dart` (region added)

---

## 🎯 Success Criteria

- ✅ All Cloud Functions deployed to `asia-south1`
- ✅ Flutter apps configured for `asia-south1`
- ✅ No "function not found" errors
- ✅ Service creation works
- ✅ Service deletion works
- ✅ Service updates work
- ✅ Profile updates work
- ✅ Online status toggle works

---

## 📞 Support

If issues persist after following this guide:
1. Check Firebase Console logs
2. Enable debug logging in Flutter app
3. Verify App Check configuration
4. Contact: 9508322397

---

## 📄 Related Documentation

- [Firebase Functions Auth Fix](FIREBASE_FUNCTIONS_AUTH_FIX.md)
- [Technician Service Moderation](TECHNICIAN_SERVICE_MODERATION.md)
- [Main README](README.md)

---

**Last Updated**: 2026-01-XX
**Status**: ✅ READY FOR DEPLOYMENT
