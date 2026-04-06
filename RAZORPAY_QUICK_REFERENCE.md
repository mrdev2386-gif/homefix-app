# 🚀 Razorpay System - Quick Reference Card

## 📊 SYSTEM STATUS

**✅ ALL SYSTEMS OPERATIONAL - PRODUCTION READY**

---

## 🔧 QUICK FIXES

### Flutter Hot Reload Error

```bash
# Error: generateTechnicianWalletQR not found
# Solution: Hot restart (not hot reload)
```

**Steps:**
1. Stop app (red square)
2. Run again (green play)

---

## 🚀 DEPLOYMENT

```bash
# 1. Set config
firebase functions:config:set razorpay.key_id="xxx"
firebase functions:config:set razorpay.key_secret="xxx"
firebase functions:config:set razorpay.webhook_secret="xxx"
firebase functions:config:set razorpay.payout_account="xxx"

# 2. Build
cd functions && npm run build

# 3. Deploy
firebase deploy --only functions
```

---

## 🧪 TESTING

### Bank KYC
```
Profile → Bank Details → Submit → "Bank Verified ✅"
```

### QR Payment
```
Wallet → Receive Payment → Generate QR → Pay ₹100 → Wallet +₹90
```

### Withdrawal
```
Wallet → Withdraw → ₹500 → Submit → Bank credit in 30 mins
```

---

## 🔍 MONITORING

```bash
# Logs
firebase functions:log --only razorpayWebhookV2

# Firestore
payment_logs - All events
platform_fees - QR fees (10%)
payouts - Withdrawals
```

---

## 🐛 TROUBLESHOOTING

| Issue | Solution |
|-------|----------|
| SDK not initialized | Check `firebase functions:config:get razorpay` |
| Bank verification failed | Check logs for specific error |
| Webhook signature invalid | Verify webhook secret matches dashboard |
| Withdrawal failed | Check `bankVerified` and `fundAccountId` |

---

## 📋 KEY FUNCTIONS

| Function | Purpose | Region |
|----------|---------|--------|
| `verifyTechnicianBankAccountSecure` | Bank KYC | asia-south1 |
| `generateTechnicianWalletQR` | QR generation | asia-south1 |
| `requestWithdrawal` | Withdrawal | asia-south1 |
| `razorpayWebhookV2` | Payment webhook | us-central1 |

---

## 💰 PLATFORM FEE

**QR Payments:** 10% platform fee auto-deducted

```
Customer pays: ₹100
Platform fee: ₹10 (10%)
Technician gets: ₹90
```

---

## 🔐 SECURITY

- ✅ Signature verification (HMAC SHA256)
- ✅ Idempotency protection
- ✅ Replay attack prevention (24h)
- ✅ Rate limiting (5 KYC/hour, 3 withdrawals/day)
- ✅ Atomic transactions

---

## 📊 DATA FLOW

```
Bank KYC:
technicians/{uid} → bankVerified: true

QR Payment:
Razorpay → Webhook → Wallet +90% → platform_fees +10%

Withdrawal:
Wallet -₹X → Razorpay Payout → Bank +₹X
```

---

## 📞 SUPPORT DOCS

1. **RAZORPAY_AUDIT_EXECUTIVE_SUMMARY.md** - Overview
2. **RAZORPAY_COMPLETE_AUDIT_AND_FIX.md** - Detailed audit
3. **RAZORPAY_DEPLOYMENT_QUICK_START.md** - Deployment guide
4. **WALLET_HOT_RELOAD_FIX.md** - Flutter issue fix

---

## ✅ CHECKLIST

- [x] Razorpay SDK initialized
- [x] Bank KYC working
- [x] QR payments working
- [x] Withdrawals working
- [x] Webhook secure
- [x] Build passing
- [x] Ready for production

---

**Status:** ✅ PRODUCTION READY  
**Last Updated:** $(Get-Date)
