# Diagnostic Logs Added - Runtime Investigation

## ✅ Changes Made

All diagnostic logs have been added to trace the exact failure points. NO business logic was changed.

---

## 📍 PART 1 — Profile Update Trace

### File: `apps/technician_app/lib/core/services/onboarding_service.dart`

**Added logs in `saveStepData()` method:**
```dart
debugPrint('[TECH WRITE] START uid=$uid step=$stepName');
debugPrint('[TECH WRITE] payload=$updateData');
debugPrint('[TECH WRITE] user=${_auth.currentUser?.uid}');
// ... after CF call ...
debugPrint('[TECH WRITE] SUCCESS via CF: ${result.toString()}');
// ... in catch ...
debugPrint('[TECH WRITE] ERROR: $e');
```

---

## 📍 PART 2 — Cloud Function Server Logs

### File: `functions/src/technician/onboarding.ts`

**Added logs in `saveTechnicianStepData` function:**
```typescript
console.log(`[CF saveTechnicianStepData] authUid=${uid}`);
console.log(`[CF saveTechnicianStepData] payload=`, JSON.stringify(data));
// ... after write ...
console.log(`[CF saveTechnicianStepData] WRITE SUCCESS`);
// ... in catch ...
console.error(`[CF saveTechnicianStepData] ERROR:`, error);
```

---

## 📍 PART 3 — Service Creation Trace

### File: `apps/technician_app/lib/core/services/technician_catalog_service.dart`

**Added logs in `createService()` method:**
```dart
debugPrint('[SERVICE CREATE] START');
debugPrint('[SERVICE CREATE] payload=$payload');
// ... on success ...
debugPrint('[SERVICE CREATE] SUCCESS');
// ... on error ...
debugPrint('[SERVICE CREATE] ERROR: FirebaseFunctionsException - ${e.code}: ${e.message}');
debugPrint('[SERVICE CREATE] ERROR: $e');
```

**Note:** Service creation Cloud Function (`functions/src/technician/createTechnicianService.ts`) already has comprehensive logging.

---

## 📍 PART 4 — Category Data Trace

### File: `apps/technician_app/lib/core/services/category_data_service.dart`

**Enhanced logs in `getCategories()` method:**
```dart
debugPrint('[CATEGORY] START: fetching from service_categories...');
debugPrint('[CATEGORY] docs=${snapshot.docs.length}');
debugPrint('[CategoryDataService] SUCCESS: Fetched categories: ${count}');
debugPrint('[CATEGORY] ERROR: orderBy "order" failed: $e');
debugPrint('[CATEGORY] ZERO docs in service_categories - trying fallback');
debugPrint('[CATEGORY] WARNING: no active categories found');
```

---

## 📍 PART 5 — Provider Data Flow

### File: `apps/technician_app/lib/core/providers/technician_provider.dart`

**Added logs in `_listenToTechnicianData()` method:**
```dart
debugPrint('[TECH PROVIDER] snapshot received=${tech != null}');
if (tech != null) {
  debugPrint('[TECH PROVIDER] data={isKycComplete: ${tech.isKycComplete}, isApproved: ${tech.isApproved}, step: ${tech.currentOnboardingStep}}');
}
```

---

## 🚀 NEXT STEPS

### 1. Deploy Cloud Function
```powershell
cd C:\Users\yash\projects\homefix
firebase deploy --only functions:saveTechnicianStepData
```

### 2. Clean Build
```powershell
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter clean
flutter pub get
```

### 3. Run App
```powershell
flutter run
```

---

## 🔍 PART 7 — Evidence Collection

### Actions to Perform in App:

#### A. Update Profile
1. Navigate to profile/onboarding screen
2. Update any field (name, district, etc.)
3. Save changes

**Expected Console Logs:**
```
[TECH WRITE] START uid=... step=...
[TECH WRITE] payload={...}
[TECH WRITE] user=...
[CF saveTechnicianStepData] authUid=...
[CF saveTechnicianStepData] payload=...
[CF saveTechnicianStepData] WRITE SUCCESS
[TECH WRITE] SUCCESS via CF: {success: true, step: ...}
[TECH PROVIDER] snapshot received=true
[TECH PROVIDER] data={isKycComplete: ..., isApproved: ..., step: ...}
```

#### B. Add Service
1. Navigate to services/catalog screen
2. Try to add a new service
3. Fill in all fields and submit

**Expected Console Logs:**
```
[SERVICE CREATE] START
[SERVICE CREATE] payload={...}
[TECH_SERVICE] Creating service for technician: ...
[TECH_SERVICE] Input data: {...}
[TECH_SERVICE] Service created successfully: ...
[SERVICE CREATE] SUCCESS
```

#### C. Open Categories
1. Navigate to categories/services selection
2. Observe category loading

**Expected Console Logs:**
```
[CATEGORY] START: fetching from service_categories...
[CATEGORY] docs=X
[CategoryDataService] SUCCESS: Fetched categories: X
```

---

## 🎯 Failure Point Detection

Based on logs, we will identify EXACTLY which layer is failing:

### ❌ App not calling CF
**Symptom:** No `[TECH WRITE] START` log
**Cause:** UI not triggering save method

### ❌ CF not receiving call
**Symptom:** `[TECH WRITE] START` but no `[CF saveTechnicianStepData]`
**Cause:** Cloud Function not deployed or network issue

### ❌ CF failing
**Symptom:** `[CF saveTechnicianStepData]` but `ERROR` log
**Cause:** Server-side validation or Firestore write failure

### ❌ Firestore write blocked
**Symptom:** CF logs show attempt but Firestore rejects
**Cause:** Security rules blocking write

### ❌ Provider not refreshing
**Symptom:** CF succeeds but no `[TECH PROVIDER] snapshot received`
**Cause:** Stream not listening or disposed

### ❌ Categories empty
**Symptom:** `[CATEGORY] docs=0` or `ZERO docs`
**Cause:** No categories in Firestore or wrong collection name

### ❌ Services function failing
**Symptom:** `[SERVICE CREATE] ERROR`
**Cause:** Approval check failing or Cloud Function error

---

## 📋 Evidence Report Template

After running the app, capture and report:

```
=== PROFILE UPDATE TEST ===
Action: Updated profile field X
Logs:
[paste relevant logs here]

Result: ✅ Success / ❌ Failed
Failure Point: [if failed, identify from list above]

=== SERVICE CREATION TEST ===
Action: Attempted to add service
Logs:
[paste relevant logs here]

Result: ✅ Success / ❌ Failed
Failure Point: [if failed, identify from list above]

=== CATEGORY LOADING TEST ===
Action: Opened categories screen
Logs:
[paste relevant logs here]

Result: ✅ Success / ❌ Failed
Failure Point: [if failed, identify from list above]

=== FIRESTORE CONSOLE CHECK ===
Collection: technicians/{uid}
- Document exists: Yes/No
- Last updatedAt timestamp: [timestamp]
- isKycComplete: true/false
- isApproved: true/false

Collection: technician_services
- Document count: X
- Last created service: [timestamp]

Collection: categories / service_categories
- Document count: X
- Sample doc with isActive=true: Yes/No
```

---

## ⚠️ IMPORTANT

- DO NOT proceed with fixes until evidence is collected
- Capture EXACT console output for each test
- Check Firebase Console for actual Firestore data
- Verify Cloud Functions logs in Firebase Console
- Note any error messages or stack traces

---

## 🔗 Related Files

- `apps/technician_app/lib/core/services/onboarding_service.dart`
- `apps/technician_app/lib/core/services/technician_catalog_service.dart`
- `apps/technician_app/lib/core/services/category_data_service.dart`
- `apps/technician_app/lib/core/providers/technician_provider.dart`
- `functions/src/technician/onboarding.ts`
- `functions/src/technician/createTechnicianService.ts`
