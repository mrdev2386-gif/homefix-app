# Razorpay Authentication Fix - Deployment Commands

## ✅ BUILD & DEPLOY

### Step 1: Build
```powershell
cd c:\Users\yash\projects\homefix\functions
npm run build
```

**Expected Output:**
```
> homefix-functions@1.0.0 build
> tsc

(no errors)
```

---

### Step 2: Deploy Test Functions
```powershell
firebase deploy --only functions:testRazorpayConnection,functions:testBankVerification
```

**Expected Output:**
```
✔  Deploy complete!

Function URL (testRazorpayConnection): https://...
Function URL (testBankVerification): https://...
```

---

### Step 3: Verify Configuration
```powershell
firebase functions:config:get
```

**Expected Output:**
```json
{
  "razorpay": {
    "key_id": "rzp_test_xxx",
    "key_secret": "xxx"
  }
}
```

**If empty or missing:**
```powershell
firebase functions:config:set razorpay.key_id="rzp_test_YOUR_KEY_ID"
firebase functions:config:set razorpay.key_secret="YOUR_KEY_SECRET"
firebase deploy --only functions
```

---

### Step 4: Monitor Logs
```powershell
firebase functions:log --follow
```

---

## 🧪 TESTING FROM FLUTTER

### Test 1: Basic Razorpay Connection
```dart
import 'package:cloud_functions/cloud_functions.dart';

void testRazorpayConnection() async {
  try {
    print('[TEST] Calling testRazorpayConnection...');
    
    final result = await FirebaseFunctions.instance
      .httpsCallable('testRazorpayConnection')
      .call();
    
    print('[TEST] Response: ${result.data}');
    
    if (result.data['success'] == true) {
      print('✅ RAZORPAY CONNECTION VERIFIED');
      print('Key Mode: ${result.data['details']['keyMode']}');
      print('Order ID: ${result.data['details']['orderId']}');
    } else {
      print('❌ RAZORPAY CONNECTION FAILED');
      print('Step: ${result.data['step']}');
      print('Message: ${result.data['message']}');
      print('Details: ${result.data['details']}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
}
```

### Test 2: Bank Verification Flow
```dart
void testBankVerification() async {
  try {
    print('[TEST] Calling testBankVerification...');
    
    final result = await FirebaseFunctions.instance
      .httpsCallable('testBankVerification')
      .call();
    
    print('[TEST] Response: ${result.data}');
    
    if (result.data['success'] == true) {
      print('✅ BANK VERIFICATION FLOW VERIFIED');
      print('Contact ID: ${result.data['details']['contactId']}');
      print('Fund Account ID: ${result.data['details']['fundAccountId']}');
      print('Fund Account Active: ${result.data['details']['fundAccountActive']}');
    } else {
      print('❌ BANK VERIFICATION FLOW FAILED');
      print('Message: ${result.data['message']}');
      print('Error: ${result.data['error']}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
}
```

---

## 📊 INTERPRETING RESULTS

### Test 1 Success ✅
```
✅ RAZORPAY CONNECTION VERIFIED
Key Mode: TEST
Order ID: order_xxx
```
→ **Diagnosis:** Keys are correct, API working
→ **Next:** Run Test 2

### Test 1 Failure - Config Issue ❌
```
❌ RAZORPAY CONNECTION FAILED
Step: config_loading
Message: Razorpay key_id not configured
```
→ **Diagnosis:** Keys not set in Firebase config
→ **Fix:**
```powershell
firebase functions:config:set razorpay.key_id="rzp_test_xxx"
firebase functions:config:set razorpay.key_secret="xxx"
firebase deploy --only functions
```

### Test 1 Failure - Auth Error ❌
```
❌ RAZORPAY CONNECTION FAILED
Step: api_call
Message: Razorpay API call failed
Error: Invalid API Key
```
→ **Diagnosis:** Keys are invalid or mode mismatch
→ **Fix:**
1. Go to https://dashboard.razorpay.com/app/keys
2. Copy correct test keys
3. Update config:
```powershell
firebase functions:config:unset razorpay
firebase functions:config:set razorpay.key_id="rzp_test_CORRECT_KEY"
firebase functions:config:set razorpay.key_secret="CORRECT_SECRET"
firebase deploy --only functions
```

### Test 2 Success ✅
```
✅ BANK VERIFICATION FLOW VERIFIED
Contact ID: cont_xxx
Fund Account ID: fa_xxx
Fund Account Active: true
```
→ **Diagnosis:** Complete flow working
→ **Next:** Deploy verifyTechnicianBankAccountSecure

---

## 🚀 FINAL DEPLOYMENT

### After Tests Pass
```powershell
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:verifyTechnicianBankAccountSecure
```

---

## 📋 TROUBLESHOOTING

### Build Fails
```powershell
# Clean and rebuild
rm -r lib
npm run build
```

### Config Not Showing
```powershell
# Verify config is set
firebase functions:config:get

# If empty, set it
firebase functions:config:set razorpay.key_id="rzp_test_xxx"
firebase functions:config:set razorpay.key_secret="xxx"

# Redeploy
firebase deploy --only functions
```

### Tests Timeout
```powershell
# Check logs for errors
firebase functions:log

# Increase timeout in Flutter
final result = await FirebaseFunctions.instance
  .httpsCallable('testRazorpayConnection')
  .withOptions(HttpsCallableOptions(timeout: Duration(seconds: 30)))
  .call();
```

### Keys Not Loading
```powershell
# Verify keys are set
firebase functions:config:get | findstr razorpay

# If not showing, set them
firebase functions:config:set razorpay.key_id="rzp_test_xxx"
firebase functions:config:set razorpay.key_secret="xxx"

# Redeploy
firebase deploy --only functions
```

---

## ✅ VERIFICATION CHECKLIST

- [ ] Build succeeds without errors
- [ ] Test functions deployed successfully
- [ ] Firebase config shows razorpay keys
- [ ] testRazorpayConnection returns success
- [ ] testBankVerification returns success
- [ ] Firebase logs show no errors
- [ ] Ready to deploy verifyTechnicianBankAccountSecure

---

## 📞 QUICK REFERENCE

### Key Commands
```powershell
# Build
npm run build

# Deploy test functions
firebase deploy --only functions:testRazorpayConnection,functions:testBankVerification

# Deploy all functions
firebase deploy --only functions

# View logs
firebase functions:log --follow

# Check config
firebase functions:config:get

# Set config
firebase functions:config:set razorpay.key_id="xxx"
firebase functions:config:set razorpay.key_secret="xxx"

# Unset config
firebase functions:config:unset razorpay
```

---

**Status:** ✅ READY FOR DEPLOYMENT
