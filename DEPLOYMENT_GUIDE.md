# Firebase Functions UNAUTHENTICATED Fix - Deployment Guide

## CRITICAL: DO NOT SKIP THESE STEPS

---

## PHASE 1: PRE-DEPLOYMENT VERIFICATION

### 1.1 Verify Project Alignment
```bash
# Check current Firebase project
firebase use

# Expected output:
# Currently using project: homefix-aa42d
```

**Action**: If project is wrong, run:
```bash
firebase use homefix-aa42d
```

### 1.2 Verify Frontend Configuration
```bash
# Check firebase_options.dart
grep -n "projectId" apps/technician_app/lib/firebase_options.dart

# Expected output:
# projectId: 'homefix-aa42d'
```

### 1.3 Verify Backend Configuration
```bash
# Check index.ts
grep -n "admin.initializeApp" functions/src/index.ts

# Expected output:
# if (!admin.apps.length) {
#     admin.initializeApp();
# }
```

---

## PHASE 2: BACKEND DEPLOYMENT

### 2.1 Build Functions
```bash
cd functions
npm run build
```

**Expected Output**:
```
✔ Compiled successfully
```

### 2.2 Deploy Functions
```bash
firebase deploy --only functions
```

**Expected Output**:
```
✔ functions[addTechnicianService(us-central1)]: Successful update operation.
✔ functions[updateTechnicianService(us-central1)]: Successful update operation.
✔ functions[toggleTechnicianServiceStatus(us-central1)]: Successful update operation.
✔ functions[deleteTechnicianService(us-central1)]: Successful update operation.
✔ functions[getMyTechnicianServices(us-central1)]: Successful update operation.
```

### 2.3 Verify Deployment
```bash
firebase functions:list

# Expected output:
# addTechnicianService(us-central1)
# updateTechnicianService(us-central1)
# toggleTechnicianServiceStatus(us-central1)
# deleteTechnicianService(us-central1)
# getMyTechnicianServices(us-central1)
```

---

## PHASE 3: FRONTEND VERIFICATION

### 3.1 Clean Build
```bash
cd apps/technician_app
flutter clean
flutter pub get
```

### 3.2 Build APK
```bash
flutter build apk --debug
```

**Expected Output**:
```
✔ Built build/app/outputs/flutter-apk/app-debug.apk
```

### 3.3 Install on Device
```bash
flutter install
```

---

## PHASE 4: RUNTIME TESTING

### 4.1 Start Log Monitoring
```bash
# Terminal 1: Monitor backend logs
firebase functions:log --follow
```

### 4.2 Trigger Test
```bash
# Terminal 2: Run app and trigger addService
flutter run

# In app:
# 1. Login with technician account
# 2. Navigate to Add Service
# 3. Fill form and submit
```

### 4.3 Verify Frontend Logs
```
# Expected in Flutter console:
🚀 [ADDSERVICE] Authenticated user: {uid}
🔥 [ADDSERVICE] ID TOKEN OBTAINED
🔥 [ADDSERVICE] UID: {uid}
🔥 [ADDSERVICE] TOKEN LENGTH: {length}
🔥 [ADDSERVICE] TIMESTAMP: {iso8601}
🔍 [ADDSERVICE] Validating token claims...
✅ [ADDSERVICE] Token validation passed
🚀 [ADDSERVICE] Calling Cloud Function with authenticated user: {uid}
🚀 [ADDSERVICE] Region: us-central1
🚀 [ADDSERVICE] Project: homefix-aa42d
✅ [ADDSERVICE] SUCCESS - Service created
```

### 4.4 Verify Backend Logs
```
# Expected in Firebase console:
🔥 [FUNCTION START] addTechnicianService triggered
🔥 [REQUEST TIMESTAMP] {iso8601}
🔥 [CONTEXT AUTH] { uid: "...", token: {...} }
🔥 [CONTEXT UID] {uid}
🔥 [CONTEXT TOKEN] PRESENT
🔥 [AUTH SUCCESS] Authenticated UID: {uid}
[TECH STATUS] approved
[PROFILE COMPLETION] 100
[SERVICE_ADD] ✅ Service {serviceId} created for technician {uid}
```

---

## PHASE 5: FAILURE DIAGNOSIS

### If Frontend Shows Error
```
❌ [ADDSERVICE] ERROR: {error}
```

**Action**: Check logs for:
1. Is user authenticated? (Check `🚀 [ADDSERVICE] Authenticated user`)
2. Is token obtained? (Check `🔥 [ADDSERVICE] ID TOKEN OBTAINED`)
3. Is token valid? (Check `✅ [ADDSERVICE] Token validation passed`)

### If Backend Shows Error
```
❌ [AUTH FAILED] NO AUTH CONTEXT - Request rejected
```

**Action**: This means `context.auth` is null. Check:
1. Is function deployed? (`firebase functions:list`)
2. Is region correct? (Should be `us-central1`)
3. Is project correct? (`firebase use`)

### If Token Validation Fails
```
❌ Token audience mismatch: expected homefix-aa42d, got {other}
```

**Action**: Token is for wrong project. Check:
1. Frontend `firebase_options.dart` projectId
2. Backend `admin.initializeApp()` project
3. Run `firebase use homefix-aa42d`

---

## PHASE 6: PRODUCTION DEPLOYMENT

### 6.1 Pre-Production Checklist
- [ ] All logs show successful auth flow
- [ ] No UNAUTHENTICATED errors
- [ ] Token validation passes
- [ ] Service created successfully
- [ ] Backend logs show context.auth.uid
- [ ] No errors in 10+ test runs

### 6.2 Production Deployment
```bash
# Deploy to production
firebase deploy --only functions

# Verify
firebase functions:list
firebase functions:log --limit 100
```

### 6.3 Monitor Production
```bash
# Watch logs for 24 hours
firebase functions:log --follow

# Look for:
# ✅ Successful service creations
# ❌ Any UNAUTHENTICATED errors
# ⚠️ Any token validation failures
```

---

## PHASE 7: ROLLBACK PLAN

### If Issues Occur
```bash
# Revert to previous version
git revert HEAD

# Rebuild and redeploy
cd functions
npm run build
firebase deploy --only functions
```

---

## VERIFICATION MATRIX

| Check | Frontend | Backend | Status |
|-------|----------|---------|--------|
| Project ID | homefix-aa42d | admin.initializeApp() | ✅ |
| Region | us-central1 | us-central1 | ✅ |
| Auth Context | getIdToken(true) | context.auth | ✅ |
| Token Validation | JwtTokenValidator | console.log | ✅ |
| Logging | 🔥 [ADDSERVICE] | 🔥 [FUNCTION START] | ✅ |
| Error Handling | try/catch | HttpsError | ✅ |

---

## QUICK REFERENCE

### Deploy Backend
```bash
cd functions && npm run build && firebase deploy --only functions
```

### Check Logs
```bash
firebase functions:log --follow
```

### Test Frontend
```bash
cd apps/technician_app && flutter run
```

### Verify Deployment
```bash
firebase functions:list
```

---

## SUCCESS CRITERIA

✅ **All of the following must be true**:

1. Frontend logs show: `✅ [ADDSERVICE] SUCCESS - Service created`
2. Backend logs show: `🔥 [AUTH SUCCESS] Authenticated UID: {uid}`
3. No UNAUTHENTICATED errors in logs
4. Service appears in Firestore `technician_services` collection
5. Service status is `pending` (awaiting admin approval)
6. Service `technicianId` matches authenticated user UID

---

## SUPPORT

If issues persist:

1. Check `ROOT_CAUSE_ANALYSIS.md` for detailed explanation
2. Review logs using `firebase functions:log`
3. Verify project alignment with `firebase use`
4. Check token validation in frontend logs
5. Verify backend receives context.auth in logs

---

## FINAL CHECKLIST

- [ ] Backend deployed successfully
- [ ] Frontend builds without errors
- [ ] Test run shows success logs
- [ ] No UNAUTHENTICATED errors
- [ ] Service created in Firestore
- [ ] Production deployment approved
- [ ] Monitoring enabled
- [ ] Rollback plan ready
