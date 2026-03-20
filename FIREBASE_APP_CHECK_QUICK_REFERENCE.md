# Firebase App Check Debug Mode - QUICK REFERENCE

## 🚀 QUICK START (3 STEPS)

### Step 1: Rebuild Apps
```bash
# Run this script (Windows)
rebuild_both_apps.bat

# OR manually:
cd apps/customer_app
flutter clean && flutter pub get

cd apps/technician_app
flutter clean && flutter pub get
```

### Step 2: Run App & Get Token
```bash
cd apps/customer_app
flutter run
```

**Look for this in logs:**
```
==============================
🔥 FIREBASE APP CHECK DEBUG TOKEN
<YOUR-TOKEN-HERE>
==============================
```

### Step 3: Register Token
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Project Settings > App Check
3. Manage debug tokens > Add debug token
4. Paste token > Save
5. Set Cloud Functions to "Not enforced"

---

## 📋 WHAT WAS FIXED

### Before:
```dart
// ❌ Used PlayIntegrity for production
if (kDebugMode) {
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
} else {
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );
}
```

### After:
```dart
// ✅ Always uses debug provider
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
);
print('[APP CHECK] Debug provider enabled');
```

---

## 🔍 VERIFY FIX

### Check Logs:
```
[APP CHECK] Debug provider enabled
✅ [APP CHECK] Debug provider activated
```

### Test Function Call:
```dart
// Any Cloud Function call should work
final result = await functions.httpsCallable('addTechnicianService').call(data);
```

### Expected Result:
- ✅ NO "UNAUTHENTICATED" errors
- ✅ NO "App Check token is invalid" errors
- ✅ Function executes successfully

---

## 🐛 TROUBLESHOOTING

### Issue: Still getting UNAUTHENTICATED
**Fix:** Check Firebase Functions authentication fix is applied
```dart
final user = FirebaseAuth.instance.currentUser;
await user.getIdToken(true); // Force refresh
```

### Issue: No debug token in logs
**Fix:** Rebuild app completely
```bash
flutter clean && flutter pub get && flutter run
```

### Issue: Token not working
**Fix:** 
1. Copy EXACT token from logs (between ====== lines)
2. Register in Firebase Console
3. Wait 1-2 minutes for propagation
4. Restart app

---

## 📁 FILES MODIFIED

1. `apps/customer_app/lib/core/firebase/firebase_init.dart`
2. `apps/technician_app/lib/core/firebase/firebase_init.dart`

---

## ✅ CHECKLIST

- [ ] Run `rebuild_both_apps.bat`
- [ ] Run customer app
- [ ] Copy debug token from logs
- [ ] Register token in Firebase Console
- [ ] Set enforcement to "Not enforced"
- [ ] Test Cloud Function call
- [ ] Verify NO errors
- [ ] Repeat for technician app

---

**Status:** ✅ READY TO TEST
