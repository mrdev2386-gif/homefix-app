# 🔥 App Check Debug Token Extraction Guide

## ✅ Code Updated

The App Check initialization has been enhanced to **GUARANTEE** the debug token prints to console with maximum visibility.

---

## 📋 Step-by-Step Instructions

### STEP 1: Clean Build (MANDATORY)

```powershell
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter clean
flutter pub get
flutter run
```

**⚠️ CRITICAL:** Hot reload will NOT work. You MUST do a full clean build.

---

### STEP 2: Find the Debug Token

The token will appear in console with this format:

```
TOKEN_EXTRACTOR: ========================================
TOKEN_EXTRACTOR: 🔥 APP_CHECK_DEBUG_TOKEN: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
TOKEN_EXTRACTOR: ========================================
TOKEN_EXTRACTOR: Copy this token ↑ and register it in:
TOKEN_EXTRACTOR: Firebase Console → App Check → Debug tokens
TOKEN_EXTRACTOR: ========================================
```

**Also look for:**
```
🔥🔥🔥 APP_CHECK_DEBUG_TOKEN: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX 🔥🔥🔥
```

### How to Search in Console

**VS Code:**
- Press `Ctrl+F`
- Search for: `APP_CHECK_DEBUG_TOKEN`

**Android Studio:**
- Open Logcat
- Filter: `APP_CHECK_DEBUG_TOKEN`

**Command Line:**
- Look for lines starting with `TOKEN_EXTRACTOR:` or `🔥🔥🔥`

---

### STEP 3: Copy the Token

**Token Format:**
```
XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

**Example:**
```
A1B2C3D4-E5F6-G7H8-I9J0-K1L2M3N4O5P6
```

**Copy ONLY the token string** (not the prefix text)

---

### STEP 4: Register Token in Firebase Console

1. **Open Firebase Console:**
   - Go to: https://console.firebase.google.com
   - Select your HomeFix project

2. **Navigate to App Check:**
   - Click **App Check** in left sidebar
   - Click **Apps** tab

3. **Find Your Android App:**
   - Look for your technician app package name
   - Example: `com.homefix.technician_app`

4. **Add Debug Token:**
   - Scroll to **Debug tokens** section
   - Click **Add debug token**
   - Paste the token you copied
   - Click **Save**

5. **Verify:**
   - Token should appear in the list
   - Status should be **Active**

---

### STEP 5: Restart App (FULL RESTART)

**⚠️ IMPORTANT:** Do a COMPLETE restart, not hot reload

```powershell
# Stop the app completely (Ctrl+C in terminal)
# Then run again:
flutter run
```

---

### STEP 6: Verify Success

After restart, check console for:

```
✅ [APP_CHECK] ✅ Activated (Mode: Debug)
```

**And NO errors like:**
- ❌ App attestation failed (403)
- ❌ Too many attempts
- ❌ Placeholder token

---

## 🚨 Troubleshooting

### Issue: Token Not Appearing in Console

**Solution 1: Check Debug Mode**
```dart
// Verify kDebugMode is true
debugPrint('kDebugMode: $kDebugMode');
```

**Solution 2: Check Console Output**
- Ensure you're looking at the correct console
- Try searching for `TOKEN_EXTRACTOR`
- Check Android Studio Logcat if using VS Code

**Solution 3: Wait Longer**
- Token generation can take 5-10 seconds
- Wait for app to fully start
- Look for the token after login screen appears

### Issue: Token Shows "TOKEN_NOT_AVAILABLE"

**Cause:** Token generation failed

**Solution:**
1. Check internet connection
2. Verify Firebase project is configured correctly
3. Check `google-services.json` is in correct location:
   ```
   apps/technician_app/android/app/google-services.json
   ```
4. Try running again after 1 minute

### Issue: "APP_CHECK_TOKEN_ERROR" in Console

**This is NORMAL on first run!**

The error message will say:
```
TOKEN_EXTRACTOR: ❌ APP_CHECK_TOKEN_ERROR: ...
TOKEN_EXTRACTOR: This may be normal on first run.
TOKEN_EXTRACTOR: Token will be generated after app fully starts.
```

**Solution:**
- Wait for app to fully load
- Navigate to any screen
- Check console again - token should appear
- If not, restart app once more

### Issue: Still Getting 403 Errors After Registration

**Solution:**
1. **Verify token is registered:**
   - Firebase Console → App Check → Apps
   - Check token appears in Debug tokens list

2. **Verify correct app:**
   - Ensure you registered token for the TECHNICIAN app
   - Not the customer app

3. **Clear app data:**
   ```powershell
   flutter clean
   flutter run
   ```

4. **Wait 1-2 minutes:**
   - Firebase needs time to propagate the token
   - Try again after waiting

---

## ✅ Success Checklist

- [ ] Ran `flutter clean && flutter pub get && flutter run`
- [ ] Found token in console (search for `APP_CHECK_DEBUG_TOKEN`)
- [ ] Copied full token string (UUID format)
- [ ] Opened Firebase Console → App Check
- [ ] Found technician Android app
- [ ] Added debug token
- [ ] Saved token
- [ ] Restarted app completely
- [ ] Verified no 403 errors
- [ ] Confirmed `[APP_CHECK] ✅ Activated` in console

---

## 📊 Expected Console Output

### On App Start (Success):

```
TOKEN_EXTRACTOR: main() started
TOKEN_EXTRACTOR: [APP_CHECK] Firebase initialized
TOKEN_EXTRACTOR: [APP_CHECK] Environment Verification: kDebugMode=true
TOKEN_EXTRACTOR: [APP_CHECK] ========================================
TOKEN_EXTRACTOR: [APP_CHECK] ACTIVATING DEBUG MODE
TOKEN_EXTRACTOR: [APP_CHECK] ========================================
TOKEN_EXTRACTOR: [APP_CHECK] Debug provider activated (Debug Mode)
TOKEN_EXTRACTOR: [APP_CHECK] Fetching debug token...
TOKEN_EXTRACTOR: ========================================
TOKEN_EXTRACTOR: 🔥 APP_CHECK_DEBUG_TOKEN: A1B2C3D4-E5F6-G7H8-I9J0-K1L2M3N4O5P6
TOKEN_EXTRACTOR: ========================================
TOKEN_EXTRACTOR: Copy this token ↑ and register it in:
TOKEN_EXTRACTOR: Firebase Console → App Check → Debug tokens
TOKEN_EXTRACTOR: ========================================
🔥🔥🔥 APP_CHECK_DEBUG_TOKEN: A1B2C3D4-E5F6-G7H8-I9J0-K1L2M3N4O5P6 🔥🔥🔥
TOKEN_EXTRACTOR: [APP_CHECK] ✅ Activated (Mode: Debug)
TOKEN_EXTRACTOR: [APP_CHECK] App Check activation process complete
TOKEN_EXTRACTOR: [APP_CHECK] Services starting
```

---

## 🎯 What Happens After Registration

Once the debug token is registered:

1. **App Check validates successfully**
   - No more 403 errors
   - Firebase calls work normally

2. **Profile updates persist**
   - `[TECH WRITE] SUCCESS via CF`
   - Data saves to Firestore

3. **Services create successfully**
   - `[SERVICE CREATE] SUCCESS`
   - Documents appear in Firestore

4. **All Firebase features work**
   - Cloud Functions
   - Firestore
   - Storage
   - Messaging

---

## 🔒 Security Notes

**This is SAFE for development:**
- Debug tokens only work in debug builds
- Production builds use Play Integrity
- No security is weakened
- App Check remains active

**DO NOT:**
- Share debug tokens publicly
- Use debug tokens in production
- Disable App Check completely

---

## 📞 Need Help?

If you still can't find the token after following all steps:

1. **Capture full console output:**
   - From app start to login screen
   - Save to a text file

2. **Check these files exist:**
   - `apps/technician_app/android/app/google-services.json`
   - `apps/technician_app/lib/firebase_options.dart`

3. **Verify Firebase project:**
   - Firebase Console → Project Settings
   - Check Android app is registered
   - Verify package name matches

4. **Try alternative method:**
   - Check Android Studio Logcat
   - Filter by "AppCheck" or "TOKEN"
   - Look for debug token in native logs

---

## 🎉 Success!

Once you see this in console:
```
✅ [APP_CHECK] ✅ Activated (Mode: Debug)
```

And NO 403 errors → **You're done!**

The app is now ready for testing profile updates and service creation.
