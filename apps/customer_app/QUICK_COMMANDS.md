# Quick Fix Commands

## ✅ EXACT FIX APPLIED

### What Was Fixed
1. ✅ Removed duplicate Firebase.initializeApp() from firebase_init.dart
2. ✅ Simplified main.dart initialization to EXACT order
3. ✅ App Check activated with debug provider only
4. ✅ Added debug log: "✅ App Check ACTIVATED"

### Initialization Order (VERIFIED)
```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();
await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.debug);
print('✅ App Check ACTIVATED');
runApp(const HomeFixApp());
```

## 🚀 Rebuild Now

### Quick Rebuild (with uninstall)
```powershell
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter clean && flutter pub get && adb uninstall com.homefix.customer && flutter run
```

### Or Use Script
```powershell
rebuild_with_uninstall.bat
```

## 🔍 Verify Success

Look for this log:
```
✅ App Check ACTIVATED
```

## ⚠️ If You See "No AppCheckProvider installed"

Force reinstall:
```powershell
adb uninstall com.homefix.customer
flutter run
```

## 📊 What Changed

| File | Action |
|------|--------|
| lib/main.dart | ✅ Fixed initialization order |
| lib/core/firebase/firebase_init.dart | ❌ DELETED (duplicate) |

## ✅ Expected Result

- No UNAUTHENTICATED errors
- Cloud Functions work correctly
- App Check properly initialized
- Single initialization point

---

**Run**: `rebuild_with_uninstall.bat`
**Docs**: See `FIREBASE_INIT_EXACT_FIX.md`
