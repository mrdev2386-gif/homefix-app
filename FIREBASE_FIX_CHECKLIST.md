# 🚀 FIREBASE APP CHECK - IMMEDIATE ACTION REQUIRED

## ✅ COMPLETED
- [x] Fixed firebase_options.dart (wrong app ID → correct app ID)

---

## 🔴 MANUAL STEPS REQUIRED (Do these NOW)

### Step 1: Update SHA-256 in Firebase Console (5 minutes)

1. Open: https://console.firebase.google.com/project/homefix-aa42d/settings/general
2. Scroll to "Your apps" → Find "Technician App" (package: `com.homefix.technician`)
3. Click "Add fingerprint" under SHA certificate fingerprints
4. Paste this SHA-256:
   ```
   93:A9:84:61:64:1F:73:9F:94:D7:3D:EE:2D:7B:90:B6:78:D7:DF:C0:F1:4F:4E:68:EF:A9:7C:C4:14:B7:A3:9E
   ```
5. Click "Save"
6. **IMPORTANT:** Delete the old wrong SHA-256 if present: `93:DD:67:69:CA:54:7B:67:52:1A:7C:66:F1:E1:CA:1C:D2:72:29:97`

---

### Step 2: Download Fresh google-services.json (2 minutes)

1. Same page → Technician App → Click "google-services.json" download button
2. Replace file at: `apps\technician_app\android\app\google-services.json`
3. Verify the file contains the correct SHA-256

---

### Step 3: Clean Build (3 minutes)

```powershell
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter clean
flutter pub get
cd android
.\gradlew clean
cd ..
```

---

### Step 4: Run App and Get Debug Token (2 minutes)

```powershell
flutter run
```

**Look for this in terminal:**
```
🔥 Firebase App Check Debug Token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

**Copy the token!**

---

### Step 5: Register Debug Token (3 minutes)

1. Open: https://console.firebase.google.com/project/homefix-aa42d/appcheck/apps
2. Find "Technician App" → Click "Manage debug tokens"
3. Click "Add debug token"
4. Paste the token from Step 4
5. Description: "Debug Device - [Your Device Name]"
6. Click "Save"

---

## 🎯 SUCCESS CRITERIA

After completing all steps, you should see:

✅ No "403 App attestation failed" errors
✅ Debug token printed in terminal
✅ Firestore queries work
✅ Cloud Functions work
✅ No "Unknown calling package name" errors

---

## 🆘 IF STILL FAILING

Check these:

1. **Verify correct app ID in firebase_options.dart:**
   ```dart
   appId: '1:663243229047:android:7cab612c44e5b787f44372'
   ```
   (Should end with `7cab612c44e5b787f44372`, NOT `8c42de21fe943a63f44372`)

2. **Verify SHA-256 in Firebase Console matches:**
   ```
   93:A9:84:61:64:1F:73:9F:94:D7:3D:EE:2D:7B:90:B6:78:D7:DF:C0:F1:4F:4E:68:EF:A9:7C:C4:14:B7:A3:9E
   ```

3. **Verify package name in build.gradle:**
   ```gradle
   applicationId = "com.homefix.technician"
   ```

4. **Check App Check enforcement is OFF for debug:**
   - Firebase Console → App Check → Apps → Technician App
   - Enforcement should be "Off" or "Unenforced" during development

---

## 📞 SUPPORT

If issues persist after all steps:
- Check full diagnostic report: `FIREBASE_APP_CHECK_DIAGNOSIS.md`
- Contact: 9508322397
