# 🔧 App Check & Firestore Fix Guide

## ✅ App Check Configuration Verified

The App Check code in `main.dart` is **CORRECT**:

```dart
if (kDebugMode) {
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
} else {
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
}
```

**DO NOT modify this code** - it's already secure and environment-aware.

---

## 🔥 PART 1: Fix App Check 403 Errors

### Step 1: Extract Debug Token

1. **Run the app in DEBUG mode:**
   ```powershell
   cd C:\Users\yash\projects\homefix\apps\technician_app
   flutter run
   ```

2. **Find the debug token in console output:**
   Look for this line:
   ```
   TOKEN_EXTRACTOR: 🔥 APP_CHECK_DEBUG_TOKEN: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```

3. **Copy the entire token** (format: `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`)

### Step 2: Register Debug Token in Firebase

1. Go to **Firebase Console**: https://console.firebase.google.com
2. Select your project
3. Navigate to **App Check** (left sidebar)
4. Click on **Apps** tab
5. Find your **Android app** (com.homefix.technician_app or similar)
6. Scroll to **Debug tokens** section
7. Click **Add debug token**
8. Paste the token you copied
9. Click **Save**

### Step 3: Restart App

**IMPORTANT:** Do a FULL restart, not hot reload:
```powershell
# Stop the app completely
# Then run again:
flutter run
```

### Expected Result

✅ No more "App attestation failed (403)" errors
✅ Console shows: `[APP_CHECK] ✅ Activated (Mode: Debug)`

---

## 📊 PART 2: Create Missing Firestore Index

### Option A: Click the Link (Easiest)

1. Run the app
2. Navigate to FAQ or any screen that triggers the index error
3. In console, you'll see an error with a **clickable link**
4. Click the link - it opens Firebase Console with pre-filled index settings
5. Click **Create Index**
6. Wait for status to change to **Enabled** (takes 1-5 minutes)

### Option B: Manual Creation

1. Go to **Firebase Console** → **Firestore Database**
2. Click **Indexes** tab
3. Click **Composite** tab
4. Click **Create Index**
5. Fill in:
   - **Collection ID**: `faqs`
   - **Fields to index**:
     - Field: `category`, Order: **Ascending**
     - Field: `order`, Order: **Ascending**
   - **Query scope**: Collection
6. Click **Create**
7. Wait for status: **Building** → **Enabled**

### Expected Result

✅ FAQ loads without "index not found" errors
✅ No fallback warnings in console

---

## 🔐 PART 3: Verify Technician Approval Status

### Check Your Approval Status

1. Go to **Firebase Console** → **Firestore Database**
2. Navigate to `technicians` collection
3. Find your document (use your UID from console logs)
4. Check these fields:

```
isApproved: true          ← MUST be true
adminApproved: true       ← MUST be true
isKycComplete: true       ← MUST be true
status: "approved"        ← Should be "approved"
```

### If Fields Are Missing or False

**Manually set them:**
1. Click on your technician document
2. Click **Edit document**
3. Set:
   - `isApproved` = `true` (boolean)
   - `adminApproved` = `true` (boolean)
   - `isKycComplete` = `true` (boolean)
   - `status` = `"approved"` (string)
4. Click **Update**

---

## 🧪 PART 4: Test Profile Update

### Run the Test

1. **Open technician app**
2. **Navigate to profile screen**
3. **Update any field** (name, district, etc.)
4. **Click Save**

### Expected Console Output

```
[TECH WRITE] START uid=abc123 step=basicDetails
[TECH WRITE] payload={onboardingStep: basicDetails, ...}
[TECH WRITE] user=abc123
[CF saveTechnicianStepData] authUid=abc123
[CF saveTechnicianStepData] payload=...
[CF saveTechnicianStepData] WRITE SUCCESS
[TECH WRITE] SUCCESS via CF: {success: true, step: basicDetails}
[TECH PROVIDER] snapshot received=true
[TECH PROVIDER] data={isKycComplete: true, isApproved: true, ...}
```

### Verify in Firestore

1. Go to **Firestore Database** → `technicians/{your-uid}`
2. Check `updatedAt` field - should be recent timestamp
3. Check your updated field - should have new value

### If It Fails

**Check console for error pattern:**

#### Pattern 1: No logs at all
**Cause:** UI not calling service
**Fix:** Check button is wired correctly

#### Pattern 2: "Cloud Function not found"
**Cause:** Function not deployed
**Fix:** 
```powershell
cd C:\Users\yash\projects\homefix
firebase deploy --only functions:saveTechnicianStepData
```

#### Pattern 3: "Technician profile not found"
**Cause:** Document doesn't exist
**Fix:** Complete onboarding flow first

#### Pattern 4: "Permission denied"
**Cause:** Firestore rules blocking
**Fix:** Check firestore.rules for technicians collection

---

## 🛠️ PART 5: Test Service Creation

### Prerequisites

**CRITICAL:** You MUST be approved before creating services.

Verify in Firestore:
```
technicians/{uid}:
  isApproved: true
  adminApproved: true
```

### Run the Test

1. **Navigate to services/catalog screen**
2. **Click "Add Service"**
3. **Fill in all fields:**
   - Category (select from dropdown)
   - Subcategory (select from dropdown)
   - Title (min 5 characters)
   - Description (min 20 characters)
   - Price (number > 0)
   - Duration (minutes > 0)
   - Image (upload or select)
4. **Click Save/Submit**

### Expected Console Output

```
[SERVICE CREATE] START
[SERVICE CREATE] payload={categoryId: cat1, title: "AC Repair", ...}
[TECH_SERVICE] Creating service for technician: abc123
[TECH_SERVICE] Input data: {...}
[TECH_SERVICE] Service created successfully: svc123
[SERVICE CREATE] SUCCESS
```

### Verify in Firestore

1. Go to **Firestore Database** → `technician_services`
2. Find newly created document
3. Check fields are populated correctly

### If It Fails

#### Error: "not approved"
**Fix:** Set `isApproved=true` and `adminApproved=true` in Firestore

#### Error: "Category not found"
**Fix:** Ensure `categories` collection has active documents

#### Error: "Validation failed"
**Fix:** Check all required fields meet minimum requirements

---

## 🧹 PART 6: Clean Build (If Needed)

Only run this if you're experiencing persistent issues:

```powershell
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter clean
flutter pub get
flutter run
```

**When to use:**
- After updating dependencies
- After changing native code
- After Firebase configuration changes
- When experiencing unexplained errors

---

## ✅ Success Checklist

After completing all steps, verify:

- [ ] App Check debug token registered in Firebase Console
- [ ] No "App attestation failed (403)" errors in console
- [ ] FAQ Firestore index created and enabled
- [ ] Technician document has `isApproved=true` and `adminApproved=true`
- [ ] Profile updates show `[TECH WRITE] SUCCESS via CF` in console
- [ ] Profile updates persist to Firestore (check `updatedAt` timestamp)
- [ ] Service creation shows `[SERVICE CREATE] SUCCESS` in console
- [ ] Services appear in `technician_services` collection

---

## 🚨 Common Issues & Solutions

### Issue: "App Check token not appearing in console"

**Solution:**
1. Ensure you're running in DEBUG mode (not release)
2. Check console for `TOKEN_EXTRACTOR:` prefix
3. Try force refresh:
   ```dart
   final token = await FirebaseAppCheck.instance.getToken(true);
   ```

### Issue: "Index creation stuck at 'Building'"

**Solution:**
- Wait 5-10 minutes (can take time for large collections)
- Check Firebase Console for any error messages
- If stuck > 30 minutes, delete and recreate

### Issue: "Profile updates not persisting"

**Solution:**
1. Check Cloud Function logs in Firebase Console
2. Verify function is deployed: `firebase functions:list`
3. Check Firestore rules allow writes to technicians collection
4. Verify user is authenticated (check `FirebaseAuth.instance.currentUser`)

### Issue: "Services not creating"

**Solution:**
1. Verify approval status in Firestore
2. Check categories collection exists and has active documents
3. Verify all required fields are filled
4. Check Cloud Function logs for detailed error

---

## 📞 Need Help?

If issues persist after following this guide:

1. **Capture console logs** - Full output from app start to error
2. **Check Firebase Console logs** - Functions → Logs tab
3. **Verify Firestore data** - Check actual document values
4. **Check network** - Ensure stable internet connection

---

## 🎯 Final Verification

Run this complete test sequence:

1. ✅ Start app → No App Check errors
2. ✅ Navigate to FAQ → Loads without index error
3. ✅ Update profile → Success message + Firestore updated
4. ✅ Create service → Success message + Document created
5. ✅ Check Firestore → All data persisted correctly

**If all 5 pass → System is working correctly! 🎉**
