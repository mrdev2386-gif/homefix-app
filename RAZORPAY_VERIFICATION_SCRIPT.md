# Razorpay Fix Verification Script

## Prerequisites
- Firebase CLI installed and logged in
- Functions deployed with the latest fix

## Step 1: Deploy Functions
```bash
cd functions
npm run build
firebase deploy --only functions
```

Wait for deployment to complete (usually 2-5 minutes).

## Step 2: Test Razorpay Connection
```bash
# Test the Razorpay SDK initialization
firebase functions:call testRazorpayConnection
```

**Expected Output:**
```json
{
  "success": true,
  "message": "Razorpay connection verified successfully",
  "details": {
    "keyMode": "TEST",
    "orderId": "order_xxxxx",
    "orderStatus": "created"
  },
  "diagnosis": {
    "configLoaded": true,
    "keyFormatValid": true,
    "sdkInitialized": true,
    "apiConnected": true,
    "authenticationWorking": true
  }
}
```

## Step 3: Check Logs for DEBUG Output
```bash
firebase functions:log --only testRazorpayConnection --limit 50
```

**Look for this in the logs:**
```
[RAZORPAY] Initializing Razorpay SDK singleton...
[RAZORPAY] Key ID: rzp_test_xxxxx
[RAZORPAY] Key mode: TEST
[RAZORPAY] DEBUG: {
  type: 'function',
  hasContacts: true,
  hasCreate: 'function',
  hasFundAccounts: true,
  hasOrders: true,
  hasPayments: true
}
[RAZORPAY] ✅ Singleton instance validated successfully
[RAZORPAY] ✅ contacts.create: AVAILABLE
[RAZORPAY] ✅ fund_accounts.create: AVAILABLE
[RAZORPAY] ✅ orders.create: AVAILABLE
[RAZORPAY] ✅ payments.fetch: AVAILABLE
[TEST_RAZORPAY] ✓ Razorpay SDK initialized successfully (shared instance)
[TEST_RAZORPAY] ✓ Order created successfully
[TEST_RAZORPAY] Order ID: order_xxxxx
[TEST_RAZORPAY] ✅ ALL TESTS PASSED
```

## Step 4: Test Bank Verification (Optional)

### Option A: Using Firebase Console
1. Go to Firebase Console → Functions
2. Find `testBankVerification` function
3. Click "Test function"
4. Click "Run test"

### Option B: Using Technician App
1. Open Technician App
2. Login as a technician
3. Go to Profile → Bank Details
4. Enter test details:
   - Name: Test User
   - Account: 123456789012
   - IFSC: SBIN0001234
5. Click "Verify Bank Account"

### Check Bank Verification Logs
```bash
firebase functions:log --only verifyTechnicianBankAccountSecure --limit 50
```

**Expected in logs:**
```
[BANK_VERIFY] Starting verification
[RAZORPAY] DEBUG: {
  type: 'function',
  hasContacts: true,
  hasCreate: 'function',
  hasFundAccounts: true
}
[BANK_VERIFY] Creating new Razorpay contact
[BANK_VERIFY] Contact created - ID: cont_xxxxx
[BANK_VERIFY] Creating fund account
[BANK_VERIFY] Fund account created - ID: fa_xxxxx, Active: true
[BANK_VERIFY] Verification successful
```

## Success Criteria

✅ **SYSTEM FIXED** if you see:
- `hasContacts: true`
- `hasCreate: 'function'`
- `hasFundAccounts: true`
- `Contact created - ID: cont_xxxxx`
- `Fund account created - ID: fa_xxxxx`
- No errors in logs

❌ **SYSTEM NOT FIXED** if you see:
- `hasContacts: false`
- `hasCreate: 'undefined'`
- `CRITICAL ERROR: contacts.create not available`
- Any initialization errors

## Troubleshooting

### If deployment fails:
```bash
# Check for TypeScript errors
cd functions
npm run build

# Check Firebase login
firebase login

# Check project selection
firebase use --add
```

### If function call fails:
```bash
# Check if functions are deployed
firebase functions:list

# Check function logs for errors
firebase functions:log --limit 100
```

### If Razorpay config is missing:
```bash
# Check current config
firebase functions:config:get

# Set Razorpay config (if missing)
firebase functions:config:set razorpay.key_id="rzp_test_xxxxx"
firebase functions:config:set razorpay.key_secret="your_secret_key"

# Redeploy after config change
firebase deploy --only functions
```

## Quick Verification Command

Run this single command to test everything:
```bash
firebase functions:call testRazorpayConnection && firebase functions:log --only testRazorpayConnection --limit 20
```

## What to Share if Issues Occur

If the fix doesn't work, share:
1. Full output of `firebase functions:log --only testRazorpayConnection --limit 50`
2. The DEBUG log section showing `hasContacts`, `hasCreate`, etc.
3. Any error messages
4. Output of `firebase functions:config:get`

---

**Note**: I cannot execute these commands for you as I don't have access to your Firebase project. You need to run these commands in your terminal.
