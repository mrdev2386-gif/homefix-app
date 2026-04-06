# 🚀 Deploy and Test - Quick Guide

## 📋 PRE-DEPLOYMENT CHECKLIST

- [x] Runtime fixes applied to `functions/src/config/razorpay.ts`
- [x] Build passing (`npm run build` exit code 0)
- [x] Razorpay package installed (`razorpay@2.9.2`)
- [x] Test functions available

---

## 🚀 DEPLOYMENT COMMANDS

### 1. Verify Config (CRITICAL)

```bash
firebase functions:config:get
```

**Expected output:**
```json
{
  "razorpay": {
    "key_id": "rzp_test_xxx",
    "key_secret": "xxx",
    "webhook_secret": "xxx",
    "payout_account": "xxx"
  }
}
```

**If missing, set now:**
```bash
firebase functions:config:set razorpay.key_id="YOUR_KEY_ID"
firebase functions:config:set razorpay.key_secret="YOUR_KEY_SECRET"
firebase functions:config:set razorpay.webhook_secret="YOUR_WEBHOOK_SECRET"
firebase functions:config:set razorpay.payout_account="YOUR_PAYOUT_ACCOUNT"
```

### 2. Build Functions

```bash
cd functions
npm run build
```

**Expected:**
```
> homefix-functions@1.0.0 build
> tsc

Exit Code: 0
```

### 3. Deploy

```bash
firebase deploy --only functions
```

**Wait for:**
```
✔  functions: Finished running predeploy script.
✔  functions[...]: Successful update operation.
✔  Deploy complete!
```

---

## 🧪 RUNTIME TESTING

### Test 1: Razorpay Connection

**From Firebase Console:**
1. Go to Firebase Console → Functions
2. Find `testRazorpayConnection`
3. Click "Test function"
4. Click "Run test"

**Expected result:**
```json
{
  "success": true,
  "message": "Razorpay connection verified successfully",
  "details": {
    "keyMode": "TEST",
    "orderId": "order_xxx",
    "orderStatus": "created"
  }
}
```

**Check logs:**
```bash
firebase functions:log --only testRazorpayConnection --limit 50
```

**Look for:**
```
[RAZORPAY] ========== INITIALIZATION SUCCESS ==========
[RAZORPAY] ✅ contacts.create: AVAILABLE
[RAZORPAY] ✅ fund_accounts.create: AVAILABLE
[RAZORPAY] ✅ orders.create: AVAILABLE
[RAZORPAY] ✅ payments.fetch: AVAILABLE
[RAZORPAY] ✅ payouts.create: AVAILABLE
[RAZORPAY] ✅ qrCodes.create: AVAILABLE
```

### Test 2: Bank Verification (Requires Auth)

**From your app:**
```dart
// Call the test function
final result = await FirebaseFunctions.instance
    .httpsCallable('testBankVerification')
    .call();

print(result.data);
```

**Expected result:**
```json
{
  "success": true,
  "message": "Bank verification flow test passed",
  "details": {
    "contactId": "cont_xxx",
    "fundAccountId": "fa_xxx",
    "fundAccountActive": true
  }
}
```

### Test 3: Real Bank KYC

**From technician app:**
1. Open Profile → Bank Details
2. Enter test bank details:
   - Account Number: `123456789012`
   - IFSC: `SBIN0001234`
   - Account Holder: `Test User`
3. Submit
4. Check status changes to "Verifying..." then "Bank Verified ✅"

**Check logs:**
```bash
firebase functions:log --only verifyTechnicianBankAccountSecure --limit 50
```

**Look for:**
```
[RAZORPAY] ✅ contacts.create: AVAILABLE
[RAZORPAY] ✅ fund_accounts.create: AVAILABLE
[BANK_VERIFY] Contact created: cont_xxx
[BANK_VERIFY] Fund account created: fa_xxx
[BANK_VERIFY] Verification successful
```

---

## 🔍 MONITORING

### Real-time Logs

```bash
# Watch all function logs
firebase functions:log

# Watch specific function
firebase functions:log --only verifyTechnicianBankAccountSecure

# Watch with filter
firebase functions:log | grep RAZORPAY
```

### Check Firestore

```javascript
// Check payment logs
db.collection('payment_logs')
  .orderBy('createdAt', 'desc')
  .limit(10)
  .get()

// Check bank verification status
db.collection('technicians').doc(uid).get()
  .then(doc => console.log({
    bankVerified: doc.data().bankVerified,
    bankVerificationStatus: doc.data().bankVerificationStatus,
    fundAccountId: doc.data().fundAccountId
  }))
```

---

## ❌ IF TESTS FAIL

### Scenario 1: "contacts.create not available"

**Check logs for:**
```
[RAZORPAY DEBUG] Instance structure
```

**If contacts.create is NOT 'function':**

```bash
# Clean reinstall
cd functions
rm -rf node_modules package-lock.json
npm install
npm run build
firebase deploy --only functions
```

### Scenario 2: "Razorpay credentials not configured"

```bash
# Set config
firebase functions:config:set razorpay.key_id="YOUR_KEY"
firebase functions:config:set razorpay.key_secret="YOUR_SECRET"

# Redeploy
firebase deploy --only functions
```

### Scenario 3: "Invalid key_id format"

**Check:**
- Key starts with `rzp_test_` or `rzp_live_`
- No extra spaces
- Correct key from Razorpay dashboard

```bash
# Get current config
firebase functions:config:get razorpay.key_id

# If wrong, reset
firebase functions:config:unset razorpay.key_id
firebase functions:config:set razorpay.key_id="CORRECT_KEY"
firebase deploy --only functions
```

### Scenario 4: Build fails

```bash
# Check for errors
cd functions
npm run build

# If errors, check TypeScript version
npm list typescript

# Reinstall if needed
npm install typescript@5.4.5 --save-dev
npm run build
```

---

## ✅ SUCCESS CRITERIA

Your deployment is successful when:

1. ✅ `testRazorpayConnection()` returns `success: true`
2. ✅ Logs show all 6 methods as `AVAILABLE`
3. ✅ `testBankVerification()` returns `success: true`
4. ✅ Real bank KYC works in app
5. ✅ No errors in Firebase logs

---

## 📊 EXPECTED TIMELINE

| Step | Time | Status |
|------|------|--------|
| Config verification | 1 min | ⏳ |
| Build | 30 sec | ⏳ |
| Deploy | 2-5 min | ⏳ |
| Test connection | 30 sec | ⏳ |
| Test bank verification | 1 min | ⏳ |
| Real KYC test | 2 min | ⏳ |

**Total:** ~10 minutes

---

## 🎯 QUICK COMMANDS

```bash
# Full deployment sequence
cd functions
npm run build
cd ..
firebase deploy --only functions

# Test immediately after deploy
firebase functions:log --only testRazorpayConnection

# Monitor real-time
firebase functions:log
```

---

## 📞 SUPPORT

If issues persist after following this guide:

1. **Check logs** for `[RAZORPAY DEBUG]` lines
2. **Verify** all 6 methods show as `AVAILABLE`
3. **Review** `RAZORPAY_RUNTIME_FIX_COMPLETE.md` for detailed troubleshooting
4. **Check** Razorpay dashboard for API status

---

**Ready to deploy?** Run the commands above! 🚀
