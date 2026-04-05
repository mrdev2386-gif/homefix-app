# Razorpay Configuration - Quick Reference

## ✅ Current Status
- **Build**: ✅ Successful
- **Deployment**: ✅ Successful  
- **Configuration**: ✅ Verified
- **Keys**: ✅ Present in Firebase config

---

## 🔑 Configuration Source

### CORRECT (Current Implementation)
```typescript
// functions/src/payments/razorpay.ts
const getRazorpayConfig = () => {
    const config = functions.config();
    const { key_id, key_secret } = config.razorpay;
    return { key_id, key_secret };
};
```

### WRONG (Previous Implementation)
```javascript
// OLD - DO NOT USE
const razorpayKeyId = process.env.RAZORPAY_KEY_ID || '';
const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET || '';
```

---

## 🛠️ How to Update Razorpay Keys

### Step 1: Set Configuration
```bash
firebase functions:config:set razorpay.key_id="your_key_id"
firebase functions:config:set razorpay.key_secret="your_key_secret"
firebase functions:config:set razorpay.webhook_secret="your_webhook_secret"
```

### Step 2: Verify Configuration
```bash
firebase functions:config:get
```

### Step 3: Deploy Functions
```bash
firebase deploy --only functions
```

---

## 📍 Key Locations

| File | Purpose | Status |
|------|---------|--------|
| `functions/src/payments/razorpay.ts` | Payment integration | ✅ Correct |
| `functions/src/payments/razorpayWebhookV2.ts` | Webhook handler | ✅ Correct |
| `functions/lib/payments/razorpay.js` | Compiled (auto-generated) | ✅ Correct |
| `functions/lib/payments/razorpayWebhookV2.js` | Compiled (auto-generated) | ✅ Correct |

---

## 🔍 Verification Checklist

- [x] TypeScript source uses `functions.config()`
- [x] Compiled JavaScript uses `functions.config()`
- [x] Firebase config has razorpay keys
- [x] Functions deployed successfully
- [x] No compilation errors
- [x] No duplicate exports

---

## 🚨 Common Issues & Solutions

### Issue: "Razorpay configuration not found"
**Solution**: Set config using Firebase CLI
```bash
firebase functions:config:set razorpay.key_id="xxx" razorpay.key_secret="xxx"
```

### Issue: "Invalid payment signature"
**Solution**: Ensure webhook_secret is set
```bash
firebase functions:config:set razorpay.webhook_secret="xxx"
```

### Issue: Payment fails with authentication error
**Solution**: Verify keys are correct
```bash
firebase functions:config:get | grep razorpay
```

---

## 📚 Related Functions

### Payment Functions
- `initiateRazorpayPayment` - Create payment order
- `verifyRazorpayPayment` - Verify payment after checkout
- `createRazorpayOrder` - Create wallet credit order
- `initiateRefund` - Process refund

### Webhook Functions
- `razorpayWebhookV2` - Handle payment webhooks

---

## 🔐 Security Notes

1. **Never commit keys** to version control
2. **Use Firebase config** for sensitive data
3. **Verify webhook signatures** before processing
4. **Validate amounts** server-side (never trust client)
5. **Log all transactions** for audit trail

---

## 📞 Quick Commands

```bash
# View current config
firebase functions:config:get

# Set a key
firebase functions:config:set razorpay.key_id="value"

# Deploy functions
firebase deploy --only functions

# View function logs
firebase functions:log

# Test a function
firebase functions:shell
```

---

**Last Updated**: 2024
**Status**: ✅ PRODUCTION READY
