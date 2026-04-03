# 🔥 Firebase Auth Debug - Quick Reference

## Files Created

1. ✅ `apps/customer_app/lib/debug/firebase_test_screen.dart` - Test UI
2. ✅ `functions/src/testing/testAuth.ts` - Test Cloud Function
3. ✅ `functions/src/index.ts` - Export added
4. ✅ `deploy_test_auth.bat` - Deployment script
5. ✅ `FIREBASE_AUTH_DEBUG_TEST.md` - Full documentation

---

## Quick Deploy

```powershell
# From project root
.\deploy_test_auth.bat
```

---

## Quick Test

1. **Deploy function** (run script above)
2. **Add to app** - Temporarily add this to any screen:

```dart
import 'package:customer_app/debug/firebase_test_screen.dart';

// Add button
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const FirebaseTestScreen()),
  ),
  child: const Text('Test Auth'),
)
```

3. **Run app**
```powershell
cd apps\customer_app
flutter run
```

4. **Test**
   - Login
   - Tap "Test Auth" button
   - Tap "TEST CLOUD FUNCTION"

---

## Results

### ✅ SUCCESS = Auth Working
```
✅ SUCCESS
UID: abc123...
```
**Meaning:** Auth is fine. Problem is in your service layer.

### ❌ UNAUTHENTICATED = Auth Broken
```
❌ ERROR:
[firebase_functions/unauthenticated]
```
**Meaning:** Token not reaching backend. Fix:
- SHA certificates
- google-services.json
- App Check settings

---

## View Logs

```powershell
firebase functions:log --only testAuth
```

---

## Cleanup

```powershell
firebase functions:delete testAuth
```

---

## Full Documentation

See: `FIREBASE_AUTH_DEBUG_TEST.md`
