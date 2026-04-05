# 🚀 RAZORPAY CONSOLIDATION - QUICK DEPLOYMENT GUIDE

## ⚡ QUICK START (5 MINUTES)

### **Step 1: Set Configuration** (1 minute)
```bash
cd c:\Users\yash\projects\homefix\functions

# Set your Razorpay keys
firebase functions:config:set razorpay.key_id="rzp_test_YOUR_KEY_ID"
firebase functions:config:set razorpay.key_secret="YOUR_KEY_SECRET"
firebase functions:config:set razorpay.webhook_secret="YOUR_WEBHOOK_SECRET"

# Verify
firebase functions:config:get
```

### **Step 2: Build** (2 minutes)
```bash
npm run build
```

### **Step 3: Deploy** (2 minutes)
```bash
firebase deploy --only functions
```

### **Step 4: Verify** (1 minute)
```bash
firebase functions:log
```

---

## 📋 WHAT CHANGED

### **Deleted Files** ❌
- `functions/src/payments/createOrder.ts`
- `functions/src/payments/verifyPayment.ts`
- `functions/src/payments/razorpayWebhook.ts`
- `functions/src/services/razorpayService.ts`

### **Updated Files** ✅
- `functions/src/payments/razorpay.ts` - Now uses `functions.config()`
- `functions/src/payments/razorpayWebhookV2.ts` - Now uses `functions.config()`
- `functions/src/index.ts` - Removed duplicate exports

### **No Changes Needed** ✅
- Flutter apps (function names unchanged)
- Firestore collections
- Webhook URL

---

## 🔍 VERIFICATION

### **Check Duplicate Files Deleted**
```bash
cd c:\Users\yash\projects\homefix\functions\src\payments
dir
# Should show: after_service_payment.ts, payouts.ts, razorpay.ts, razorpayWebhookV2.ts
# Should NOT show: createOrder.ts, verifyPayment.ts, razorpayWebhook.ts
```

### **Check Configuration**
```bash
firebase functions:config:get
# Should show:
# {
#   "razorpay": {
#     "key_id": "rzp_test_xxx",
#     "key_secret": "xxx",
#     "webhook_secret": "xxx"
#   }
# }
```

### **Check Build**
```bash
npm run build
# Should complete without errors
```

### **Check Deployment**
```bash
firebase deploy --only functions
# Should show all functions deployed successfully
```

---

## 🧪 TESTING

### **Test 1: Customer Payment**
1. Open customer app
2. Create booking
3. Click "Pay Now"
4. Complete payment
5. Verify booking status = "confirmed" in Firestore

### **Test 2: Technician Wallet**
1. Open technician app
2. Click "Add Money"
3. Enter amount
4. Complete payment
5. Verify wallet balance increased

### **Test 3: Webhook**
1. Go to Razorpay Dashboard
2. Webhooks section
3. Find your webhook
4. Click "Send Test Event"
5. Check Firebase Functions logs

---

## 🐛 TROUBLESHOOTING

### **Error: "Razorpay configuration not found"**
```bash
# Solution: Set configuration
firebase functions:config:set razorpay.key_id="xxx"
firebase functions:config:set razorpay.key_secret="xxx"
firebase functions:config:set razorpay.webhook_secret="xxx"
firebase deploy --only functions
```

### **Error: "Build failed"**
```bash
# Solution: Clean and rebuild
rm -r lib
npm run build
```

### **Error: "Deployment failed"**
```bash
# Solution: Check logs
firebase functions:log
# Look for error messages
```

### **Payment not updating Firestore**
```bash
# Check:
1. Webhook URL is correct in Razorpay dashboard
2. Webhook secret is correct
3. Firebase Functions logs for errors
4. Firestore security rules allow updates
```

---

## 📊 FUNCTION REFERENCE

### **Customer App**
```dart
// Create order
initiateRazorpayPayment({
  'bookingId': 'booking_123'
})

// Verify payment
verifyRazorpayPayment({
  'bookingId': 'booking_123',
  'razorpayOrderId': 'order_xyz',
  'razorpayPaymentId': 'pay_abc',
  'razorpaySignature': 'signature_hash'
})
```

### **Technician App**
```dart
// Create wallet order
createRazorpayOrder({
  'amount': 500,
  'notes': 'Wallet credit'
})
```

---

## ✅ DEPLOYMENT CHECKLIST

- [ ] Deleted duplicate files verified
- [ ] Configuration set correctly
- [ ] Build completed successfully
- [ ] Functions deployed successfully
- [ ] Logs show no errors
- [ ] Customer payment tested
- [ ] Technician wallet tested
- [ ] Webhook tested
- [ ] Firestore updates verified

---

## 📞 SUPPORT

**Issues?**
1. Check Firebase Functions logs: `firebase functions:log`
2. Verify configuration: `firebase functions:config:get`
3. Test locally: `firebase emulators:start --only functions`
4. Contact: 9508322397

---

## 🎉 DONE!

Your Razorpay integration is now:
- ✅ Consolidated (no duplicates)
- ✅ Secure (Firebase config)
- ✅ Production-ready
- ✅ Backward compatible

**Ready for production deployment!**