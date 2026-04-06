# Razorpay Fix - Deployment Checklist

## Pre-Deployment Verification ✅

- [x] Code changes applied to `functions/src/config/razorpay.ts`
- [x] Bug fix applied to `functions/src/payments/testRazorpay.ts`
- [x] TypeScript compilation successful (`npm run build`)
- [x] No TypeScript errors or warnings
- [x] Firebase config verified (`firebase functions:config:get`)
- [x] Singleton pattern verified (only 1 instance creation point)
- [x] All files use `getRazorpayInstance()` import

## Deployment Steps

### 1. Build Functions
```bash
cd functions
npm run build
```

**Expected**: ✅ No errors

### 2. Deploy to Firebase
```bash
firebase deploy --only functions
```

**Expected**: 
```
✔  functions: Finished running predeploy script.
✔  functions[...]: Successful update operation.
✔  Deploy complete!
```

### 3. Monitor Deployment
```bash
firebase functions:log --only verifyTechnicianBankAccountSecure
```

**Watch for**:
- `[RAZORPAY] Initializing Razorpay SDK singleton...`
- `[RAZORPAY] ✅ Singleton instance validated successfully`
- `[RAZORPAY] ✅ contacts.create: AVAILABLE`
- `[RAZORPAY] ✅ fund_accounts.create: AVAILABLE`

## Post-Deployment Testing

### Test 1: Bank Verification

**Action**: From Technician App
1. Navigate to Profile → Bank Details
2. Enter test bank details:
   - Name: Test Technician
   - Account: 123456789012
   - IFSC: SBIN0001234
3. Tap "Verify Bank Account"

**Expected Result**:
- ✅ No "SDK initialization failed" error
- ✅ Contact created successfully
- ✅ Fund account created successfully
- ✅ Verification status: "verified" or "failed" (based on bank details)

**Check Logs**:
```bash
firebase functions:log --only verifyTechnicianBankAccountSecure --limit 50
```

**Look for**:
```
[RAZORPAY] RazorpayLib type: function
[RAZORPAY] RazorpayClass type: function
[RAZORPAY] Instance created, type: object
[RAZORPAY] ✅ contacts.create: AVAILABLE
[BANK_VERIFY] Contact created - ID: cont_***
[BANK_VERIFY] Fund account created - ID: fa_***
```

### Test 2: Test Razorpay Connection

**Action**: Call test function
```bash
# From your app or using Firebase Console
# Call: testRazorpayConnection
```

**Expected Result**:
```json
{
  "success": true,
  "message": "Razorpay connection verified successfully",
  "diagnosis": {
    "configLoaded": true,
    "keyFormatValid": true,
    "sdkInitialized": true,
    "apiConnected": true,
    "authenticationWorking": true
  }
}
```

### Test 3: Technician Withdrawal

**Action**: From Technician App
1. Navigate to Wallet/Earnings
2. Ensure available balance > ₹100
3. Tap "Withdraw"
4. Enter amount: ₹100
5. Confirm withdrawal

**Expected Result**:
- ✅ No "SDK initialization failed" error
- ✅ Payout created successfully
- ✅ Balance deducted
- ✅ Transaction recorded

**Check Logs**:
```bash
firebase functions:log --only requestWithdrawal --limit 50
```

**Look for**:
```
[WITHDRAWAL] Withdrawal request - Technician: ***, Amount: 100
[RAZORPAY] ✅ payouts.create: AVAILABLE
[WITHDRAWAL] Razorpay payout created - ID: pout_***
[WITHDRAWAL] Withdrawal successful
```

### Test 4: Payment Order Creation

**Action**: From Customer App
1. Create a booking
2. Complete the service
3. Tap "Pay Now"

**Expected Result**:
- ✅ No "SDK initialization failed" error
- ✅ Razorpay order created
- ✅ Payment checkout opens
- ✅ Order ID returned to app

**Check Logs**:
```bash
firebase functions:log --only createPaymentOrder --limit 50
```

**Look for**:
```
[RAZORPAY] ✅ orders.create: AVAILABLE
[RAZORPAY] Order created successfully
```

## Success Criteria

All tests must pass:
- [ ] Bank verification works without SDK errors
- [ ] Test connection returns success
- [ ] Withdrawals process successfully
- [ ] Payment orders create successfully
- [ ] All logs show "✅ AVAILABLE" for required methods
- [ ] No "SDK initialization failed" errors in logs

## Rollback Procedure

If any test fails:

### 1. Check Logs First
```bash
firebase functions:log --limit 100
```

Look for:
- `[RAZORPAY] CRITICAL ERROR:`
- `SDK initialization failed`
- Any error messages

### 2. If Critical Issues Found

**Option A: Quick Fix**
- Identify the issue from logs
- Apply fix
- Redeploy

**Option B: Rollback**
```bash
# Revert the commit
git revert HEAD

# Rebuild
cd functions
npm run build

# Redeploy
firebase deploy --only functions
```

## Monitoring

### First 24 Hours
Monitor these metrics:
- Bank verification success rate
- Withdrawal success rate
- Payment order creation success rate
- Error logs for "SDK initialization failed"

### Commands
```bash
# Watch live logs
firebase functions:log --only verifyTechnicianBankAccountSecure

# Check error logs
firebase functions:log --only verifyTechnicianBankAccountSecure | grep ERROR

# Check success rate
firebase functions:log --only verifyTechnicianBankAccountSecure | grep "✅"
```

## Expected Log Output (Success)

```
[RAZORPAY] Initializing Razorpay SDK singleton...
[RAZORPAY] Key ID: rzp_live_***
[RAZORPAY] Key mode: LIVE
[RAZORPAY] RazorpayLib type: function
[RAZORPAY] RazorpayLib.default: undefined
[RAZORPAY] RazorpayClass type: function
[RAZORPAY] RazorpayClass is function: true
[RAZORPAY] Instance created, type: object
[RAZORPAY] Instance constructor: Razorpay
[RAZORPAY] DEBUG: {
  type: 'function',
  instanceType: 'object',
  hasContacts: true,
  contactsType: 'object',
  hasCreate: 'function',
  hasFundAccounts: true,
  fundAccountsType: 'object',
  hasFundAccountsCreate: 'function',
  hasOrders: true,
  ordersType: 'object',
  hasPayments: true,
  paymentsType: 'object',
  hasPayouts: true,
  payoutsType: 'object'
}
[RAZORPAY] Instance keys: [ 'contacts', 'fund_accounts', 'orders', 'payments', 'payouts', ... ]
[RAZORPAY] ✅ Singleton instance validated successfully
[RAZORPAY] ✅ contacts.create: AVAILABLE
[RAZORPAY] ✅ fund_accounts.create: AVAILABLE
[RAZORPAY] ✅ orders.create: AVAILABLE
[RAZORPAY] ✅ payments.fetch: AVAILABLE
[RAZORPAY] ✅ payouts.create: AVAILABLE
```

## Troubleshooting

### Issue: "RazorpayClass is not a function"

**Check**:
```bash
firebase functions:log | grep "RazorpayLib type"
```

**Expected**: `RazorpayLib type: function`

**If not**: Razorpay package may be corrupted
```bash
cd functions
rm -rf node_modules
npm install
npm run build
firebase deploy --only functions
```

### Issue: "contacts.create not available"

**Check**:
```bash
firebase functions:log | grep "Instance keys"
```

**Expected**: Should include `contacts`, `fund_accounts`, `orders`, `payments`, `payouts`

**If not**: Check Razorpay SDK version
```bash
cd functions
npm list razorpay
```

**Expected**: `razorpay@2.9.2`

### Issue: "Config not found"

**Check**:
```bash
firebase functions:config:get
```

**Expected**:
```json
{
  "razorpay": {
    "key_id": "rzp_live_***",
    "key_secret": "***"
  }
}
```

**If missing**: Set config
```bash
firebase functions:config:set razorpay.key_id="YOUR_KEY_ID" razorpay.key_secret="YOUR_KEY_SECRET"
firebase deploy --only functions
```

## Sign-Off

- [ ] All pre-deployment checks passed
- [ ] Deployment successful
- [ ] All post-deployment tests passed
- [ ] Logs show successful initialization
- [ ] No errors in production
- [ ] Monitoring in place

**Deployed by**: _________________  
**Date**: _________________  
**Time**: _________________  
**Status**: ✅ SUCCESS / ❌ ROLLBACK

---

**Ready to deploy!** 🚀
