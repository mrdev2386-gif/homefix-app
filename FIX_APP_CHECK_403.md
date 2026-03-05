# Fix Firebase App Check 403 Error - Quick Guide

## Problem
```
Error: FirebaseException: App attestation failed (403)
Error: Too many attempts
```

## Solution Steps

### Step 1: Run App and Get Debug Token ✅

The code is already updated. Run:

```bash
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter clean
flutter pub get
flutter run
```

### Step 2: Copy Debug Token from Logs

Look for this in console:

```
✅ Firebase App Check Debug Mode Enabled
🔥 Firebase App Check Debug Token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
📋 Copy this token and register it in Firebase Console → App Check → Manage Debug Tokens
```

**Copy the token (the XXXX-XXXX-XXXX part)**

### Step 3: Register Token in Firebase Console

1. Open: https://console.firebase.google.com
2. Select your HomeFix project
3. Navigate to: **App Check** → **Apps**
4. Find: **customer_app** (Android)
5. Click: **Manage Debug Tokens**
6. Click: **Add Debug Token**
7. Paste the token from logs
8. Click: **Save**

### Step 4: Restart App

```bash
# Stop the app (Ctrl+C)
flutter run
```

### Step 5: Verify It Works

Test address selection:
- Go to Profile → Service Location
- Select State and District
- Click Save

**Expected Result:**
- ✅ No 403 errors
- ✅ Location updates successfully
- ✅ Cloud Functions work

**Logs should show:**
```
✅ Firebase App Check Debug Mode Enabled
🔥 Firebase App Check Debug Token: XXXX
App Check token successfully obtained
```

## Troubleshooting

### Issue: Token not showing in logs
**Solution:** Ensure you're running in debug mode, not release mode

### Issue: Still getting 403 after registration
**Solution:** 
- Wait 5 minutes for token to propagate
- Clear app data: `flutter clean`
- Restart app

### Issue: "Too many attempts" error
**Solution:**
- This happens when token is not registered
- Follow Step 3 to register the token
- Wait a few minutes and try again

## Important Notes

1. **Each device needs its own token**
   - If you test on multiple devices, register each token

2. **Debug mode only**
   - This only works in debug builds
   - Production builds use automatic attestation

3. **Token is device-specific**
   - Emulators need their own tokens
   - Physical devices need their own tokens

## Quick Commands

```bash
# Clean and rebuild
flutter clean && flutter pub get && flutter run

# Check logs for token
# Look for: 🔥 Firebase App Check Debug Token
```

## Status Checklist

- [x] Code updated with debug token logging
- [ ] Run app and get token from logs
- [ ] Register token in Firebase Console
- [ ] Verify Cloud Functions work
- [ ] No more 403 errors

---

**Next Action:** Run the app and copy the debug token from logs, then register it in Firebase Console.
