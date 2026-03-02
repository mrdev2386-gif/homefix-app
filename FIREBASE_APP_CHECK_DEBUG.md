# Firebase App Check - Debug Token Setup

## ✅ STATUS: ALREADY CONFIGURED

Both apps already have Firebase App Check debug provider enabled.

---

## 📱 How to Get Debug Token

### Step 1: Run App on Real Device
```powershell
# Customer App
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter run

# OR Technician App
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter run
```

### Step 2: Check Terminal Output
Look for this line in the terminal:
```
🔥 Firebase App Check Debug Token: <YOUR_TOKEN_HERE>
```

### Step 3: Register Token in Firebase Console
1. Go to Firebase Console → App Check
2. Click on your Android app
3. Click "Manage debug tokens"
4. Add the token from terminal
5. Save

---

## 🔧 Current Configuration

### Customer App
**File:** `apps/customer_app/lib/core/firebase/firebase_init.dart`

```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode 
    ? AndroidProvider.debug 
    : AndroidProvider.playIntegrity,
);
```

### Technician App
**File:** `apps/technician_app/lib/core/firebase/firebase_init.dart`

```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode 
    ? AndroidProvider.debug 
    : AndroidProvider.playIntegrity,
);
```

---

## 🎯 Behavior

### Debug Mode (flutter run)
- Uses `AndroidProvider.debug`
- Prints debug token to console
- Token must be registered in Firebase Console
- No 403 errors during development

### Release Mode (flutter build apk --release)
- Uses `AndroidProvider.playIntegrity`
- Production-safe
- No debug tokens needed
- Automatic verification via Play Store

---

## 🔍 Expected Console Output

When running on real device:
```
🔧 [AppCheck] Debug mode - using debug provider (no 403 expected)
✅ App Check initialized with AndroidProvider.debug
🔥 Firebase App Check Debug Token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

---

## ⚠️ Important Notes

1. **Debug tokens are device-specific**
   - Each device generates a unique token
   - Register all development devices

2. **Token persistence**
   - Token stays the same for each device
   - Only need to register once per device

3. **Production safety**
   - Debug provider ONLY in debug mode
   - Release builds use Play Integrity
   - No security compromise

4. **Token refresh**
   - Tokens refresh automatically
   - Console shows: "🔐 App Check token refreshed"

---

## 🐛 Troubleshooting

### Issue: No token in console
**Check:**
- Running on real device (not emulator)
- Debug mode (not release)
- App Check initialized before Firebase calls

### Issue: 403 Forbidden errors
**Solution:**
1. Get debug token from console
2. Register in Firebase Console → App Check
3. Wait 1-2 minutes for propagation
4. Restart app

### Issue: Token not working
**Check:**
- Token registered for correct app (package name)
- Token copied completely (no spaces)
- Firebase Console changes saved

---

## 📞 Support

For issues:
- Phone: **9508322397**
- Check Firebase Console → App Check
- Verify package name matches

---

## ✅ Verification Checklist

- [x] Firebase App Check imported
- [x] Debug provider configured
- [x] Token printing enabled
- [x] Production safety maintained
- [x] No duplicate initialization
- [x] Error handling present
- [x] Both apps configured

**Status: READY FOR USE**
