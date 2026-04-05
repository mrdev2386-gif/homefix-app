# Bank Verification Cache - Quick Action Guide

## 🎯 IMMEDIATE ACTIONS

### Action 1: Deploy Cache-Disabled Version
```bash
cd c:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions:verifyTechnicianBankAccountSecure
```

**Expected Output:**
```
✔  Deploy complete!
Function URL (verifyTechnicianBankAccountSecure): https://...
```

---

### Action 2: Clear Stale Cache Data (Firestore)

#### Option A: Delete Idempotency Records
```
1. Go to Firebase Console
2. Firestore → verificationRequests collection
3. Find records for your technician
4. Delete them
```

#### Option B: Clear Technician Bank Fields
```
1. Go to Firebase Console
2. Firestore → technicians/{uid}
3. Delete or set to null:
   - bankVerified
   - bankVerificationStatus
   - fundAccountId
   - bankVerificationMessage
   - verificationLock
```

#### Option C: Use Force Flag (Recommended - No Cleanup Needed)
```dart
// Just pass force: true - no Firestore cleanup needed
final result = await FirebaseFunctions.instance
  .httpsCallable('verifyTechnicianBankAccountSecure')
  .call({
    'accountHolderName': 'John Doe',
    'accountNumber': '123456789012',
    'ifscCode': 'SBIN0001234',
    'force': true  // Bypass all caches
  });
```

---

### Action 3: Test Fresh Verification

#### Test 1: Normal Call (Cache Disabled)
```dart
void testFreshVerification() async {
  try {
    print('[TEST] Testing fresh verification...');
    
    final result = await FirebaseFunctions.instance
      .httpsCallable('verifyTechnicianBankAccountSecure')
      .call({
        'accountHolderName': 'John Doe',
        'accountNumber': '123456789012',
        'ifscCode': 'SBIN0001234'
      });
    
    print('[TEST] Result: ${result.data}');
    
    if (result.data['success'] == true) {
      print('✅ FRESH VERIFICATION SUCCESSFUL');
      print('Fund Account ID: ${result.data['fundAccountId']}');
    } else {
      print('❌ VERIFICATION FAILED');
      print('Message: ${result.data['message']}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
}
```

#### Test 2: Force Fresh Verification
```dart
void testForceVerification() async {
  try {
    print('[TEST] Testing force fresh verification...');
    
    final result = await FirebaseFunctions.instance
      .httpsCallable('verifyTechnicianBankAccountSecure')
      .call({
        'accountHolderName': 'John Doe',
        'accountNumber': '123456789012',
        'ifscCode': 'SBIN0001234',
        'force': true  // Force bypass cache
      });
    
    print('[TEST] Result: ${result.data}');
    
    if (result.data['success'] == true) {
      print('✅ FORCE VERIFICATION SUCCESSFUL');
    } else {
      print('❌ FORCE VERIFICATION FAILED');
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
}
```

---

### Action 4: Monitor Firebase Logs
```bash
firebase functions:log --follow
```

**Look for:**
```
[BANK_VERIFY] Force flag: false
[BANK_VERIFY] ⚠️ CACHE DISABLED - FORCING FRESH VERIFICATION
[BANK_VERIFY] Creating new Razorpay contact
[BANK_VERIFY] Contact created - ID: cont_xxx
[BANK_VERIFY] Creating fund account
[BANK_VERIFY] Fund account created - ID: fa_xxx, Active: true
[BANK_VERIFY] Verification successful
BANK VERIFY RESPONSE SENT
```

---

## 📊 EXPECTED RESULTS

### Success ✅
```json
{
  "success": true,
  "status": "verified",
  "message": "Bank account verified successfully",
  "fundAccountId": "fa_xxx"
}
```

### Failure ❌
```json
{
  "success": false,
  "status": "failed",
  "message": "Bank account validation failed. Please check your details and try again."
}
```

---

## 🔍 WHAT'S HAPPENING

### Before (With Cache)
```
Request 1: Fresh API call → Success → Cached
Request 2: Same account → Returns cached success
Request 3: Same account → Returns cached success (even if data changed)
```

### Now (Cache Disabled)
```
Request 1: Fresh API call → Success
Request 2: Same account → Fresh API call
Request 3: Same account → Fresh API call
```

---

## ✅ VERIFICATION STEPS

1. ✅ Deploy cache-disabled version
2. ✅ Clear Firestore cache data (optional)
3. ✅ Call function with test data
4. ✅ Check Firebase logs
5. ✅ Verify fresh API call made
6. ✅ Verify contact created
7. ✅ Verify fund account created
8. ✅ Verify real result returned

---

## 🚀 QUICK COMMANDS

### Deploy
```bash
cd c:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions:verifyTechnicianBankAccountSecure
```

### Monitor Logs
```bash
firebase functions:log --follow
```

### Clear Firestore (Optional)
```
Firebase Console → Firestore → verificationRequests → Delete all
```

---

## 📝 NOTES

- **Cache is DISABLED** - All calls make fresh Razorpay API calls
- **Force flag works** - Pass `force: true` to explicitly bypass cache
- **No cleanup needed** - Use force flag instead of clearing Firestore
- **Logs show status** - Watch for "CACHE DISABLED" message

---

## 🎯 SUCCESS CRITERIA

- [ ] Function deployed successfully
- [ ] Firebase logs show "CACHE DISABLED"
- [ ] Fresh Razorpay API call made
- [ ] Contact created successfully
- [ ] Fund account created successfully
- [ ] Real verification result returned
- [ ] No cached failures returned

---

**Status:** ✅ READY FOR TESTING
