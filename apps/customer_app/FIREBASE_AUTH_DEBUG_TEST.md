# Firebase Auth + Cloud Functions Debug Test

## 🎯 Purpose
Isolated test to verify if Firebase Auth token is correctly sent to Cloud Functions.

## 📁 Files Created

### 1. Flutter Test Screen
**Location:** `apps/customer_app/lib/debug/firebase_test_screen.dart`

### 2. Cloud Function
**Location:** `functions/src/testing/testAuth.ts`

### 3. Export Added
**Location:** `functions/src/index.ts` (testAuth exported)

---

## 🚀 Deployment Steps

### Step 1: Deploy Test Function

```powershell
cd c:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions:testAuth
```

**Expected Output:**
```
✔  functions[testAuth(asia-south1)] Successful create operation.
```

### Step 2: Add Test Screen to App

Open `apps/customer_app/lib/main.dart` and temporarily add navigation:

```dart
// Add import at top
import 'debug/firebase_test_screen.dart';

// Add button in your home screen or drawer
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FirebaseTestScreen()),
    );
  },
  child: const Text('DEBUG: Test Auth'),
)
```

### Step 3: Run Customer App

```powershell
cd c:\Users\yash\projects\homefix\apps\customer_app
flutter run
```

---

## 🧪 Testing Procedure

### 1. Login
- Open the customer app
- Login with Google/Phone (ensure user is authenticated)

### 2. Navigate to Test Screen
- Tap the "DEBUG: Test Auth" button
- You should see:
  - Current user UID
  - Current user email/phone

### 3. Run Test
- Tap "TEST CLOUD FUNCTION" button
- Wait for response

---

## 📊 Expected Results

### ✅ CASE 1: SUCCESS (Auth Working)
**Screen shows:**
```
✅ SUCCESS

UID: abc123xyz...

Full Response: {success: true, uid: abc123xyz..., email: user@example.com, timestamp: 2024-...}
```

**Console logs (Flutter):**
```
🔥 UID: abc123xyz...
🔥 EMAIL: user@example.com
🔥 TOKEN LENGTH: 1234
🔥 TOKEN PREVIEW: eyJhbGciOiJSUzI1NiIsImtpZCI6IjFkYzBmMTc...
```

**Firebase Console logs:**
```
🔥 TEST FUNCTION CALLED
📦 Data: {test: true, timestamp: ...}
🔐 Context Auth: {uid: abc123xyz..., token: {...}}
✅ UID: abc123xyz...
✅ Token: {email: user@example.com, ...}
```

**Diagnosis:** ✅ Auth is working correctly. Problem is in your service layer.

---

### ❌ CASE 2: UNAUTHENTICATED ERROR
**Screen shows:**
```
❌ ERROR:

[firebase_functions/unauthenticated] Authentication required
```

**Firebase Console logs:**
```
🔥 TEST FUNCTION CALLED
📦 Data: {test: true, timestamp: ...}
🔐 Context Auth: null
❌ AUTH IS NULL
```

**Diagnosis:** ❌ Auth token not reaching backend. Possible causes:

1. **SHA-256 Certificate Mismatch**
   - Check Firebase Console → Project Settings → SHA certificates
   - Run: `cd android && ./gradlew signingReport`
   - Add missing SHA-256 to Firebase

2. **Wrong google-services.json**
   - Verify file at: `apps/customer_app/android/app/google-services.json`
   - Ensure it matches Firebase project

3. **App Check Blocking**
   - Check if App Check is enabled in Firebase Console
   - Temporarily disable for testing

4. **Token Not Being Sent**
   - Check if `cloud_functions` package is correctly configured
   - Verify Firebase initialization in `main.dart`

---

### ❌ CASE 3: FUNCTION NOT FOUND
**Screen shows:**
```
❌ ERROR:

[firebase_functions/not-found] Function testAuth not found
```

**Diagnosis:** Function not deployed or wrong region.

**Fix:**
```powershell
cd c:\Users\yash\projects\homefix\functions
firebase deploy --only functions:testAuth
```

---

## 🔍 Debugging Commands

### Check Deployed Functions
```powershell
firebase functions:list
```

### View Function Logs
```powershell
firebase functions:log --only testAuth
```

### Check Firebase Project
```powershell
firebase projects:list
firebase use
```

---

## 🛠️ Troubleshooting

### Issue: Token is null
**Check:**
```dart
final user = FirebaseAuth.instance.currentUser;
final token = await user?.getIdToken(true);
print("Token: $token");
```

### Issue: Wrong region
**Verify in code:**
```dart
final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
```

### Issue: Firebase not initialized
**Check main.dart:**
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## 📝 Next Steps Based on Results

### If SUCCESS (Case 1):
1. ✅ Auth is working
2. ❌ Problem is in your existing service layer
3. **Action:** Review your actual Cloud Functions that are failing
4. **Check:** Are they using `context.auth` correctly?
5. **Check:** Are they deployed to correct region?

### If UNAUTHENTICATED (Case 2):
1. ❌ Auth token not reaching backend
2. **Action:** Fix SHA certificates
3. **Action:** Verify google-services.json
4. **Action:** Check App Check settings
5. **Action:** Re-test after fixes

---

## 🧹 Cleanup (After Testing)

### Remove Test Code
1. Remove navigation button from main.dart
2. Keep test files for future debugging
3. Optionally delete function:
   ```powershell
   firebase functions:delete testAuth
   ```

---

## 📞 Support

If test fails with unexpected errors, provide:
1. Screenshot of test screen
2. Flutter console logs
3. Firebase function logs
4. Firebase project ID

---

## ⚠️ IMPORTANT

- **DO NOT** modify existing business logic
- **DO NOT** deploy other functions during this test
- **DO NOT** test in production environment
- This is ONLY for debugging auth flow
