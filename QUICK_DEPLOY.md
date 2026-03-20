# 🚀 QUICK DEPLOYMENT GUIDE

## ONE-COMMAND DEPLOY

```powershell
cd C:\Users\yash\projects\homefix && .\scripts\deploy-region-fix.bat
```

---

## MANUAL DEPLOY (3 STEPS)

### Step 1: Build
```powershell
cd C:\Users\yash\projects\homefix\functions
npm run build
```

### Step 2: Deploy
```powershell
firebase deploy --only functions
```

### Step 3: Verify
```powershell
cd C:\Users\yash\projects\homefix
.\scripts\verify-region-fix.bat
```

---

## VERIFICATION CHECKLIST

### Firebase Console
- [ ] All functions show region: **asia-south1**
- [ ] No functions in us-central1
- [ ] All functions status: **Deployed**

### Technician App Tests
- [ ] Add service ✅
- [ ] Update service ✅
- [ ] Delete service ✅
- [ ] Toggle status ✅
- [ ] Update profile ✅
- [ ] Toggle online ✅

---

## EXPECTED LOGS

### ✅ Success
```
🔥 [FUNCTION START] addTechnicianService triggered
🔥 [AUTH SUCCESS] Authenticated UID: abc123xyz
✅ [SERVICE_ADD] Service created successfully
```

### ❌ Error (Before Fix)
```
❌ FirebaseFunctionsException: not-found
❌ Function addTechnicianService not found
```

---

## TROUBLESHOOTING

### Issue: Build fails
```powershell
cd C:\Users\yash\projects\homefix\functions
npm install
npm run build
```

### Issue: Deploy fails
```powershell
firebase login
firebase use --add
firebase deploy --only functions
```

### Issue: Function not found
1. Check Firebase Console for function region
2. Verify Flutter app uses asia-south1
3. Clear Flutter cache: `flutter clean`
4. Redeploy functions

---

## FILES CHANGED

### Backend (5 files)
1. `functions/src/technician/services_management.ts`
2. `functions/src/technician/profile_management.ts`
3. `functions/src/technician/tracking.ts`
4. `functions/src/custom_request.ts`
5. `functions/src/admin/services.ts`

### Frontend (1 file)
1. `apps/technician_app/lib/core/services/technician_catalog_service.dart`

---

## FUNCTIONS UPDATED (18 total)

### Service Management (5)
- addTechnicianService
- updateTechnicianService
- deleteTechnicianService
- toggleTechnicianServiceStatus
- getMyTechnicianServices

### Profile Management (5)
- updateTechnicianPersonalDetails
- updateTechnicianBankDetails
- reuploadVerificationDocument
- adminUpdateBankStatus
- adminUpdateDocumentStatus

### Tracking (2)
- updateLocation
- toggleOnlineStatus

### Custom Requests (6)
- createCustomServiceRequest
- adminApproveServiceRequest
- technicianRespondServiceRequest
- customerConfirmServicePayment
- getTechnicianInbox
- getCustomRequestDetail

---

## REGION CONFIGURATION

### ✅ Correct (After Fix)
```typescript
// Backend
functions.region('asia-south1').https.onCall(...)

// Flutter
FirebaseFunctions.instanceFor(region: 'asia-south1')
```

### ❌ Incorrect (Before Fix)
```typescript
// Backend
functions.region('us-central1').https.onCall(...)
// or
functions.https.onCall(...) // defaults to us-central1

// Flutter
FirebaseFunctions.instanceFor(region: 'asia-south1')
// MISMATCH!
```

---

## DOCUMENTATION

- **Full Guide**: REGION_FIX_DEPLOYMENT.md
- **Technical Details**: REGION_FIX_SUMMARY.md
- **Executive Summary**: REGION_FIX_EXECUTIVE_SUMMARY.md
- **This Guide**: QUICK_DEPLOY.md

---

## SUPPORT

**Phone**: 9508322397

---

**Status**: ✅ READY
**Time to Deploy**: ~5 minutes
**Confidence**: 100%
