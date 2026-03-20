# 🔥 Firebase Functions - Quick Reference Card

## ✅ CORRECT PATTERN (Use This)

```dart
import '../firebase/firebase_functions_instance.dart';

class MyService {
  // ✅ Use getter, not final field
  FirebaseFunctions get _functions => FirebaseFunctionsInstance.instance;
  
  Future<void> callFunction() async {
    // ✅ Step 1: Ensure auth is ready
    await FirebaseFunctionsInstance.ensureAuthReady();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // ✅ Step 2: Check user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    
    // ✅ Step 3: Refresh token
    await user.getIdToken(true);
    
    // ✅ Step 4: Debug log
    debugPrint('[AUTH] UID: ${user.uid}');
    
    // ✅ Step 5: Call function
    final callable = _functions.httpsCallable('functionName');
    final result = await callable.call(data);
  }
}
```

---

## ❌ WRONG PATTERNS (Don't Use)

```dart
// ❌ Creating new instances
final FirebaseFunctions _functions = FirebaseFunctions.instance;
final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

// ❌ Calling without auth ready
await callable.call(data); // UNAUTHENTICATED error

// ❌ Skipping delay
await FirebaseFunctionsInstance.ensureAuthReady();
await callable.call(data); // May fail - no delay

// ❌ Not refreshing token
final user = FirebaseAuth.instance.currentUser;
await callable.call(data); // May use stale token

// ❌ Manual headers
final callable = _functions.httpsCallable(
  'functionName',
  options: HttpsCallableOptions(
    headers: {'Authorization': 'Bearer $token'}, // Don't do this
  ),
);
```

---

## 📋 Checklist for Every Function Call

- [ ] Import `firebase_functions_instance.dart`
- [ ] Use `FirebaseFunctionsInstance.instance`
- [ ] Call `ensureAuthReady()` first
- [ ] Add 500ms delay after auth ready
- [ ] Check user is not null
- [ ] Refresh token with `getIdToken(true)`
- [ ] Add debug logging
- [ ] Let SDK handle auth headers

---

## 🔍 Quick Verification

```powershell
# Find remaining direct usages (should be 0)
findstr /s /n "FirebaseFunctions.instance" apps\customer_app\lib\*.dart | findstr /v "firebase_functions_instance.dart"

# Find calls without auth ready (should be 0)
findstr /s /n "httpsCallable" apps\customer_app\lib\*.dart | findstr /v "ensureAuthReady"
```

---

## 🚨 Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| UNAUTHENTICATED | Auth not ready | Add `ensureAuthReady()` + delay |
| UNAUTHENTICATED | Stale token | Add `getIdToken(true)` |
| UNAUTHENTICATED | Multiple instances | Use global instance |
| UNAUTHENTICATED | Called too early | Wait for auth state |
| DEADLINE_EXCEEDED | Timeout | Check network/backend |
| PERMISSION_DENIED | Wrong user | Check auth rules |

---

## 📞 Quick Help

**Issue**: UNAUTHENTICATED errors
**Fix**: Follow the 5-step pattern above

**Issue**: Works sometimes
**Fix**: Add more delay (increase to 1000ms)

**Issue**: Compilation errors
**Fix**: Run `flutter pub get`

**Contact**: 9508322397

---

**Remember**: ONE instance, ALWAYS wait for auth, ALWAYS refresh token!
