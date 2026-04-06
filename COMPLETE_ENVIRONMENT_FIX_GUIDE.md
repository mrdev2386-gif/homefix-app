# 🔧 Complete Environment Fix - Step by Step

**Status:** ✅ Functions cleaned and rebuilt  
**Razorpay:** ✅ Installed (v2.9.6)  
**Build:** ✅ Passing  

---

## ✅ WHAT I'VE DONE

1. ✅ Cleaned `node_modules` and `package-lock.json`
2. ✅ Fresh `npm install`
3. ✅ Verified Razorpay installed (v2.9.6)
4. ✅ Build passing (exit code 0)

---

## 🎯 WHAT YOU NEED TO DO

### PHASE 1: Network Stability (CRITICAL - DO FIRST)

#### On Your Computer:

1. **Turn OFF VPN** (if using)
   - Disconnect completely
   - VPNs block Firebase/Razorpay APIs

2. **Test Internet**
   ```bash
   ping google.com
   ping firestore.googleapis.com
   ```
   Both should respond without errors

3. **Flush DNS** (Windows)
   ```bash
   ipconfig /flushdns
   ```

4. **If still issues, switch network:**
   - WiFi → Mobile hotspot
   - Or try different WiFi

#### On Your Device/Emulator:

1. **Turn OFF VPN** on device
2. **Switch network** if needed
3. **Restart device/emulator completely**

---

### PHASE 2: Flutter Clean

```bash
# Navigate to technician app
cd apps/technician_app

# Clean everything
flutter clean

# Get dependencies fresh
flutter pub get

# Verify no errors
flutter doctor
```

---

### PHASE 3: Device/Emulator Reset

#### Android Emulator:

```bash
# Close emulator completely
# Then start fresh
emulator -avd YOUR_AVD_NAME
```

#### Physical Device:

1. Uninstall app completely
2. Restart device
3. Reinstall app fresh

---

### PHASE 4: Deploy Functions

```bash
# From project root
firebase deploy --only functions

# Wait for completion
# Should see: ✔ Deploy complete!
```

**Expected output:**
```
✔  functions: Finished running predeploy script.
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing codebase default for deployment
i  functions: updating Node.js 22 function...
✔  functions[...]: Successful update operation.
✔  Deploy complete!
```

---

### PHASE 5: Test Network Connectivity

#### Test 1: Basic Firebase

```dart
// In your app
try {
  await FirebaseFirestore.instance.collection('test').get();
  print('✅ Firebase connected');
} catch (e) {
  print('❌ Firebase error: $e');
  // If error, network still broken - go back to Phase 1
}
```

#### Test 2: Functions Call

```dart
// Call test function
try {
  final result = await FirebaseFunctions.instance
      .httpsCallable('testRazorpayConnection')
      .call();
  
  print('✅ Function called');
  print('Success: ${result.data['success']}');
  print('Message: ${result.data['message']}');
} catch (e) {
  print('❌ Function error: $e');
  // Check error type:
  // - "not found" → region mismatch
  // - "timeout" → network issue
  // - "unavailable" → functions not deployed
}
```

---

### PHASE 6: Check Firebase Logs

```bash
# Watch logs in real-time
firebase functions:log

# Or check specific function
firebase functions:log --only testRazorpayConnection
```

**Look for:**
```
[RAZORPAY] ========== INITIALIZING RAZORPAY SDK ==========
[RAZORPAY DEBUG] Razorpay type: function
[RAZORPAY] Instance created
[RAZORPAY] ✅ contacts.create: AVAILABLE
[RAZORPAY] ✅ fund_accounts.create: AVAILABLE
[RAZORPAY] ========== INITIALIZATION SUCCESS ==========
```

---

### PHASE 7: Test Razorpay SDK

#### From Firebase Console:

1. Go to Firebase Console → Functions
2. Find `testRazorpayConnection`
3. Click "Test function"
4. Run test

**Expected result:**
```json
{
  "success": true,
  "message": "Razorpay connection verified successfully",
  "details": {
    "keyMode": "TEST",
    "orderId": "order_xxx"
  }
}
```

#### From Your App:

```dart
// Call test function
final result = await FirebaseFunctions.instance
    .httpsCallable('testRazorpayConnection')
    .call();

if (result.data['success'] == true) {
  print('✅ Razorpay SDK working');
} else {
  print('❌ Razorpay SDK failed');
  print('Error: ${result.data['message']}');
}
```

---

### PHASE 8: Test Bank KYC

```dart
// Try bank verification
try {
  final result = await FirebaseFunctions.instance
      .httpsCallable('verifyTechnicianBankAccountSecure')
      .call({
        'accountHolderName': 'Test User',
        'accountNumber': '123456789012',
        'ifscCode': 'SBIN0001234',
      });
  
  print('✅ Bank KYC working');
  print('Status: ${result.data['status']}');
} catch (e) {
  print('❌ Bank KYC failed: $e');
}
```

---

## 🔍 TROUBLESHOOTING

### Error: "Unable to resolve host firestore.googleapis.com"

**Cause:** Network/DNS issue

**Fix:**
1. Turn off VPN
2. Flush DNS: `ipconfig /flushdns`
3. Switch network
4. Restart device

### Error: "Function not found"

**Cause:** Region mismatch or not deployed

**Fix:**
```dart
// Check region matches deployed functions
FirebaseFunctions.instanceFor(region: 'asia-south1')
```

```bash
# Verify deployed
firebase functions:list
```

### Error: "Connection timeout"

**Cause:** Network blocking or slow connection

**Fix:**
1. Check firewall
2. Try different network
3. Check internet speed

### Error: "Razorpay credentials not configured"

**Cause:** Firebase config missing

**Fix:**
```bash
firebase functions:config:set razorpay.key_id="YOUR_KEY"
firebase functions:config:set razorpay.key_secret="YOUR_SECRET"
firebase deploy --only functions
```

---

## ✅ SUCCESS CHECKLIST

Your environment is ready when:

- [ ] VPN is OFF
- [ ] `ping firestore.googleapis.com` works
- [ ] Firebase Firestore loads data
- [ ] Functions deployed successfully
- [ ] `testRazorpayConnection()` returns success
- [ ] Logs show "INITIALIZATION SUCCESS"
- [ ] All 6 Razorpay methods show as AVAILABLE
- [ ] Bank KYC test passes

---

## 📊 EXPECTED TIMELINE

| Phase | Time | Action |
|-------|------|--------|
| Network Fix | 5 min | Turn off VPN, test connectivity |
| Flutter Clean | 3 min | `flutter clean && flutter pub get` |
| Device Reset | 2 min | Restart device/emulator |
| Deploy Functions | 5 min | `firebase deploy --only functions` |
| Test Connectivity | 2 min | Test Firebase + Functions |
| Test Razorpay | 2 min | Call `testRazorpayConnection()` |
| Test Bank KYC | 2 min | Try bank verification |

**Total: ~20 minutes**

---

## 🎯 QUICK COMMANDS

### Network Test
```bash
ping google.com
ping firestore.googleapis.com
ipconfig /flushdns
```

### Flutter Clean
```bash
cd apps/technician_app
flutter clean
flutter pub get
```

### Deploy
```bash
firebase deploy --only functions
```

### Test
```bash
firebase functions:log --only testRazorpayConnection
```

---

## 📝 NOTES

1. **DO NOT skip network checks** - Most issues are network-related
2. **DO NOT use VPN** - It blocks Firebase/Razorpay APIs
3. **DO NOT proceed if Firebase doesn't connect** - Fix network first
4. **DO test simple function first** - Before testing Razorpay

---

## 🚨 CRITICAL RULES

1. Network stability FIRST
2. Firebase connectivity SECOND
3. Functions deployment THIRD
4. Razorpay testing LAST

**Follow this order. Do not skip steps.**

---

**Environment Status:** ✅ Functions ready for deployment  
**Next Step:** Follow phases above  
**Expected Result:** Stable runtime with working Razorpay SDK
