# 🔬 Runtime Investigation Execution Checklist

## Pre-Flight Checks

- [ ] All diagnostic logs added (see DIAGNOSTIC_LOGS_ADDED.md)
- [ ] No business logic changed
- [ ] No security rules weakened
- [ ] Ready to deploy and test

---

## Step 1: Deploy Cloud Function

```powershell
cd C:\Users\yash\projects\homefix
firebase deploy --only functions:saveTechnicianStepData
```

**Expected Output:**
```
✔  functions[saveTechnicianStepData(us-central1)] Successful update operation.
```

**If deployment fails:**
- Check Firebase CLI is logged in: `firebase login`
- Check project is set: `firebase use --add`
- Check functions/package.json has no errors

---

## Step 2: Clean Build

```powershell
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter clean
flutter pub get
```

**Expected Output:**
```
Running "flutter pub get" in technician_app...
Got dependencies!
```

---

## Step 3: Run App

```powershell
flutter run
```

**Wait for:**
```
✓ Built build\app\outputs\flutter-apk\app-debug.apk
```

---

## Step 4: Test Profile Update

### Actions:
1. Open technician app
2. Navigate to profile/onboarding screen
3. Update any field (e.g., name, district)
4. Click Save/Next button

### Capture Console Output:
Look for these log patterns in order:

```
[TECH WRITE] START uid=...
[TECH WRITE] payload=...
[TECH WRITE] user=...
```

Then either:
```
[TECH WRITE] SUCCESS via CF: ...
[TECH PROVIDER] snapshot received=...
```

OR:
```
[TECH WRITE] ERROR: ...
```

### Record Results:
- [ ] Logs appeared: YES / NO
- [ ] Success or Error: _______________
- [ ] Error message (if any): _______________

---

## Step 5: Check Firebase Console - Cloud Functions

1. Open Firebase Console: https://console.firebase.google.com
2. Select your project
3. Go to Functions → saveTechnicianStepData
4. Click "Logs" tab
5. Look for recent entries with `[CF saveTechnicianStepData]`

### Record Results:
- [ ] Logs found: YES / NO
- [ ] authUid present: YES / NO
- [ ] WRITE SUCCESS: YES / NO
- [ ] ERROR (if any): _______________

---

## Step 6: Check Firebase Console - Firestore

1. Go to Firestore Database
2. Navigate to `technicians` collection
3. Find your user document (use UID from logs)
4. Check fields:
   - `updatedAt` - Should be recent timestamp
   - `onboardingStep` - Should match what you saved
   - `isKycComplete` - Note value
   - `isApproved` - Note value

### Record Results:
- [ ] Document exists: YES / NO
- [ ] updatedAt is recent: YES / NO
- [ ] onboardingStep correct: YES / NO
- [ ] Data persisted: YES / NO

---

## Step 7: Test Service Creation

### Actions:
1. Navigate to services/catalog screen
2. Click "Add Service" button
3. Fill in all required fields:
   - Category
   - Subcategory
   - Title (min 5 chars)
   - Description (min 20 chars)
   - Price
   - Duration
   - Image
4. Click Save/Submit

### Capture Console Output:
Look for:
```
[SERVICE CREATE] START
[SERVICE CREATE] payload=...
```

Then either:
```
[SERVICE CREATE] SUCCESS
```

OR:
```
[SERVICE CREATE] ERROR: ...
```

### Record Results:
- [ ] Logs appeared: YES / NO
- [ ] Success or Error: _______________
- [ ] Error message (if any): _______________
- [ ] Approval check passed: YES / NO

---

## Step 8: Check Firebase Console - Services

1. Go to Firestore Database
2. Navigate to `technician_services` collection
3. Look for newly created service document

### Record Results:
- [ ] Service document created: YES / NO
- [ ] createdAt timestamp recent: YES / NO
- [ ] All fields populated: YES / NO

---

## Step 9: Test Category Loading

### Actions:
1. Navigate to categories/services selection screen
2. Observe category list loading

### Capture Console Output:
Look for:
```
[CATEGORY] START: fetching from service_categories...
[CATEGORY] docs=X
```

Then either:
```
[CategoryDataService] SUCCESS: Fetched categories: X
```

OR:
```
[CATEGORY] ERROR: ...
[CATEGORY] WARNING: no active categories found
```

### Record Results:
- [ ] Logs appeared: YES / NO
- [ ] Categories count: _______________
- [ ] Success or Error: _______________
- [ ] Categories displayed in UI: YES / NO

---

## Step 10: Check Firebase Console - Categories

1. Go to Firestore Database
2. Check these collections:
   - `categories`
   - `service_categories`
   - `technician_categories`
3. Look for documents with `isActive: true`

### Record Results:
- [ ] Collection exists: _______________
- [ ] Document count: _______________
- [ ] Sample document has isActive=true: YES / NO

---

## Step 11: Compile Evidence Report

### Profile Update Evidence:
```
✅ / ❌ Profile update working

Console logs:
[paste relevant logs]

Firebase Console verification:
- Cloud Function logs: [found/not found]
- Firestore data: [persisted/not persisted]

Failure point (if failed): _______________
```

### Service Creation Evidence:
```
✅ / ❌ Service creation working

Console logs:
[paste relevant logs]

Firebase Console verification:
- Cloud Function logs: [found/not found]
- Firestore data: [created/not created]

Failure point (if failed): _______________
```

### Category Loading Evidence:
```
✅ / ❌ Category loading working

Console logs:
[paste relevant logs]

Firebase Console verification:
- Collection: [exists/missing]
- Document count: _______________

Failure point (if failed): _______________
```

---

## Step 12: Identify Root Cause

Based on evidence, the failure is at:

- [ ] App not calling service (no START logs)
- [ ] Cloud Function not deployed (START but no CF logs)
- [ ] Cloud Function failing (CF logs show ERROR)
- [ ] Firestore write blocked (CF tries but fails)
- [ ] Provider not refreshing (write succeeds but no snapshot)
- [ ] Categories collection empty (docs=0)
- [ ] Approval check failing (not approved error)
- [ ] Network/connectivity issue (unavailable errors)

**Root Cause:** _______________________________________________

**Evidence:** _______________________________________________

---

## Step 13: Report Findings

Create a summary with:

1. **What was tested:** Profile update, service creation, category loading
2. **What worked:** List successful operations
3. **What failed:** List failed operations with exact error messages
4. **Failure point:** Exact layer where failure occurred
5. **Console logs:** Full relevant logs
6. **Firebase Console screenshots:** (optional but helpful)
7. **Next steps:** Recommended fix based on root cause

---

## 🚨 Common Issues & Quick Fixes

### Issue: "Cloud Function not found"
**Fix:** Deploy function: `firebase deploy --only functions:saveTechnicianStepData`

### Issue: "Permission denied"
**Fix:** Check firestore.rules for technicians collection

### Issue: "Technician profile not found"
**Fix:** Create profile first via onboarding flow

### Issue: "Not approved"
**Fix:** Admin must set isApproved=true and adminApproved=true in Firestore

### Issue: "Categories empty"
**Fix:** Seed categories collection with active documents

### Issue: "Network unavailable"
**Fix:** Check internet connection and Firebase project status

---

## 📋 Final Checklist

Before reporting findings:

- [ ] All 3 tests performed (profile, service, categories)
- [ ] Console logs captured for each test
- [ ] Firebase Console checked for each test
- [ ] Failure points identified
- [ ] Root cause determined
- [ ] Evidence compiled
- [ ] Ready to proceed with targeted fix

---

## 🎯 Success Criteria

Investigation is complete when you can answer:

1. **Does profile update persist to Firestore?** YES / NO
2. **If NO, at which layer does it fail?** _______________
3. **Do services get created in Firestore?** YES / NO
4. **If NO, at which layer does it fail?** _______________
5. **Do categories load from Firestore?** YES / NO
6. **If NO, what is the root cause?** _______________

**Once you have these answers, STOP and report findings.**
**Do NOT attempt fixes until root cause is confirmed.**
