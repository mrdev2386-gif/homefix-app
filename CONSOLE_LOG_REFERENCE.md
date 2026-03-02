# 🔍 Console Log Quick Reference

## Profile Update Flow

### ✅ HEALTHY FLOW
```
[TECH WRITE] START uid=abc123 step=basicDetails
[TECH WRITE] payload={onboardingStep: basicDetails, ...}
[TECH WRITE] user=abc123
[CF saveTechnicianStepData] authUid=abc123
[CF saveTechnicianStepData] payload={"step":0,"stepName":"basicDetails",...}
[CF saveTechnicianStepData] WRITE SUCCESS
[TECH WRITE] SUCCESS via CF: {success: true, step: basicDetails}
[TECH PROVIDER] snapshot received=true
[TECH PROVIDER] data={isKycComplete: false, isApproved: false, step: basicDetails}
```

### ❌ FAILURE PATTERNS

#### Pattern 1: UI Not Calling Service
```
[No logs at all]
```
**Diagnosis:** Button not wired or form validation blocking
**Fix:** Check UI event handlers

#### Pattern 2: Cloud Function Not Deployed
```
[TECH WRITE] START uid=abc123 step=basicDetails
[TECH WRITE] payload={...}
[TECH WRITE] user=abc123
[TECH WRITE] ERROR: FirebaseFunctionsException: not-found
```
**Diagnosis:** Cloud Function doesn't exist
**Fix:** Deploy with `firebase deploy --only functions:saveTechnicianStepData`

#### Pattern 3: Authentication Issue
```
[TECH WRITE] START uid=abc123 step=basicDetails
[TECH WRITE] user=null
[TECH WRITE] ERROR: User not authenticated
```
**Diagnosis:** User logged out or token expired
**Fix:** Re-authenticate user

#### Pattern 4: Cloud Function Failing
```
[TECH WRITE] START uid=abc123 step=basicDetails
[CF saveTechnicianStepData] authUid=abc123
[CF saveTechnicianStepData] payload=...
[CF saveTechnicianStepData] ERROR: Technician profile not found
[TECH WRITE] ERROR: FirebaseFunctionsException: not-found
```
**Diagnosis:** Technician document doesn't exist in Firestore
**Fix:** Create technician profile first

#### Pattern 5: Firestore Write Blocked
```
[CF saveTechnicianStepData] authUid=abc123
[CF saveTechnicianStepData] payload=...
[CF saveTechnicianStepData] ERROR: PERMISSION_DENIED: Missing or insufficient permissions
```
**Diagnosis:** Firestore security rules blocking write
**Fix:** Check firestore.rules for technicians collection

#### Pattern 6: Provider Not Listening
```
[TECH WRITE] SUCCESS via CF: {success: true}
[No TECH PROVIDER logs]
```
**Diagnosis:** Stream disposed or not subscribed
**Fix:** Check TechnicianProvider initialization

---

## Service Creation Flow

### ✅ HEALTHY FLOW
```
[SERVICE CREATE] START
[SERVICE CREATE] payload={categoryId: cat1, title: "AC Repair", ...}
[TECH_SERVICE] Creating service for technician: abc123
[TECH_SERVICE] Input data: {...}
[TECH_SERVICE] Service created successfully: svc123
[SERVICE CREATE] SUCCESS
```

### ❌ FAILURE PATTERNS

#### Pattern 1: Not Approved
```
[SERVICE CREATE] START
[SERVICE CREATE] payload={...}
[SERVICE CREATE] ERROR: not approved
```
**Diagnosis:** Technician not approved by admin
**Fix:** Admin must approve technician (set isApproved=true, adminApproved=true)

#### Pattern 2: Validation Failed
```
[SERVICE CREATE] START
[TECH_SERVICE] Creating service for technician: abc123
[TECH_SERVICE] Validation failed: Title must be at least 5 characters
[SERVICE CREATE] ERROR: FirebaseFunctionsException - invalid-argument
```
**Diagnosis:** Input validation failed
**Fix:** Check form inputs meet requirements

#### Pattern 3: Cloud Function Error
```
[SERVICE CREATE] START
[TECH_SERVICE] Creating service for technician: abc123
[TECH_SERVICE] ERROR: Category verification failed
[SERVICE CREATE] ERROR: FirebaseFunctionsException
```
**Diagnosis:** Category doesn't exist or inactive
**Fix:** Ensure categories collection has active documents

---

## Category Loading Flow

### ✅ HEALTHY FLOW
```
[CATEGORY] START: fetching from service_categories...
[CATEGORY] docs=5
[CategoryDataService] SUCCESS: Fetched categories: 5
```

### ❌ FAILURE PATTERNS

#### Pattern 1: Empty Collection
```
[CATEGORY] START: fetching from service_categories...
[CATEGORY] docs=0
[CATEGORY] ZERO docs in service_categories - trying fallback
[CATEGORY] WARNING: no active categories found
```
**Diagnosis:** No categories in Firestore
**Fix:** Seed categories collection

#### Pattern 2: Index Missing
```
[CATEGORY] START: fetching from service_categories...
[CATEGORY] ERROR: orderBy "order" failed: index not found
```
**Diagnosis:** Firestore composite index missing
**Fix:** Create index or remove orderBy

#### Pattern 3: Network Error
```
[CATEGORY] START: fetching from service_categories...
[CategoryDataService] FirebaseException: unavailable - network is down
```
**Diagnosis:** No internet connection
**Fix:** Check network connectivity

---

## Provider Stream Flow

### ✅ HEALTHY FLOW
```
[TECH PROVIDER] snapshot received=true
[TECH PROVIDER] data={isKycComplete: true, isApproved: true, step: submitted}
[ADMIN PIPELINE] Approval detected: true
[ADMIN PIPELINE] Admin approved: true
[ADMIN PIPELINE] Status: approved
```

### ❌ FAILURE PATTERNS

#### Pattern 1: Document Not Found
```
[TECH PROVIDER] snapshot received=false
```
**Diagnosis:** Technician document doesn't exist
**Fix:** Create technician profile

#### Pattern 2: Permission Denied
```
[Stream Error] Firestore listener error: FirebaseException
[FirebaseException] permission-denied - user may not have access
```
**Diagnosis:** Security rules blocking read
**Fix:** Check firestore.rules read permissions

#### Pattern 3: Network Unavailable
```
[Stream Error] Firestore listener error: FirebaseException
[FirebaseException] unavailable - network is down
```
**Diagnosis:** No internet or Firestore offline
**Fix:** Check network connectivity

---

## 🎯 Quick Diagnosis Checklist

### Profile Not Persisting?
1. ✅ See `[TECH WRITE] START`? → UI is calling service
2. ✅ See `[CF saveTechnicianStepData]`? → Cloud Function receiving call
3. ✅ See `WRITE SUCCESS`? → Firestore write succeeded
4. ✅ See `[TECH PROVIDER] snapshot`? → Stream is listening
5. ❌ If any step missing → That's your failure point

### Services Not Creating?
1. ✅ See `[SERVICE CREATE] START`? → UI is calling service
2. ✅ See `[TECH_SERVICE] Creating`? → Cloud Function receiving call
3. ✅ See approval check pass? → Technician is approved
4. ✅ See validation pass? → Input data is valid
5. ✅ See `Service created successfully`? → Write succeeded
6. ❌ If any step missing → That's your failure point

### Categories Not Loading?
1. ✅ See `[CATEGORY] START`? → Service is being called
2. ✅ See `docs=X` where X > 0? → Documents exist
3. ✅ See `SUCCESS`? → Query succeeded
4. ❌ If docs=0 → Collection is empty
5. ❌ If ERROR → Query failed (index/network issue)

---

## 📞 Firebase Console Checks

### Cloud Functions Logs
1. Go to Firebase Console → Functions
2. Click on `saveTechnicianStepData`
3. View logs tab
4. Look for `[CF saveTechnicianStepData]` entries

### Firestore Data
1. Go to Firebase Console → Firestore Database
2. Check collections:
   - `technicians/{uid}` - Should have your user document
   - `categories` or `service_categories` - Should have active documents
   - `technician_services` - Should have service documents after creation

### Authentication
1. Go to Firebase Console → Authentication
2. Verify user exists and is signed in
3. Check UID matches logs
