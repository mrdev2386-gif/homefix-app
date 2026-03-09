# Cloud Functions v2 Migration - Deployment Checklist

## Pre-Deployment Verification ✅

### Code Quality Checks
- [x] **No `functions.config()` in production code**
  - Verified: Only 1 comment reference in v2_templates (safe)
  - Command: `findstr /s /i "functions.config()" src\*.ts`
  
- [x] **TypeScript build successful**
  - Exit Code: 0
  - Errors: 0
  - Command: `npm run build`

- [x] **All environment variables use `process.env`**
  - bank_verification.ts: ✅ Updated
  - razorpay.ts: ✅ Already compliant
  - razorpayWebhookV2.ts: ✅ Already compliant

### Documentation
- [x] Migration report created: `FUNCTIONS_CONFIG_MIGRATION_REPORT.md`
- [x] Setup guide created: `ENV_VARIABLES_SETUP_GUIDE.md`
- [x] Quick summary created: `MIGRATION_SUMMARY.md`

---

## Environment Setup

### Required Variables
```bash
RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxxx
RAZORPAY_WEBHOOK_SECRET=xxxxxxxxxxxxxxxxxxxxx
```

### Setup Commands

#### For Staging
```bash
firebase use staging
firebase functions:config:set \
  razorpay.key_id="rzp_test_xxxxxxxxxxxxx" \
  razorpay.key_secret="test_secret_here" \
  razorpay.webhook_secret="test_webhook_secret"
```

#### For Production
```bash
firebase use production
firebase functions:config:set \
  razorpay.key_id="rzp_live_xxxxxxxxxxxxx" \
  razorpay.key_secret="live_secret_here" \
  razorpay.webhook_secret="live_webhook_secret"
```

### Verification
```bash
# Check current config
firebase functions:config:get

# Should show:
# {
#   "razorpay": {
#     "key_id": "rzp_xxx",
#     "key_secret": "xxx",
#     "webhook_secret": "xxx"
#   }
# }
```

---

## Deployment Steps

### Step 1: Staging Deployment
```bash
# Switch to staging project
firebase use staging

# Build functions
cd C:\Users\yash\projects\homefix\functions
npm run build

# Deploy only bank verification function first
firebase deploy --only functions:verifyTechnicianBankAccount

# Monitor logs
firebase functions:log --only verifyTechnicianBankAccount
```

**Expected Output:**
```
✔ functions[verifyTechnicianBankAccount]: Successful update operation.
```

### Step 2: Staging Testing
- [ ] Test bank verification flow
  - [ ] Open technician app
  - [ ] Navigate to bank verification
  - [ ] Enter test bank details
  - [ ] Verify success/failure response
  
- [ ] Check Cloud Functions logs
  ```bash
  firebase functions:log --only verifyTechnicianBankAccount --limit 50
  ```
  
- [ ] Verify no errors:
  - [ ] No "Container Healthcheck failed"
  - [ ] No "PORT=8080" errors
  - [ ] No "functions.config()" errors
  - [ ] No "undefined" configuration errors

### Step 3: Full Staging Deployment
```bash
# Deploy all functions to staging
firebase deploy --only functions

# Monitor for 10 minutes
firebase functions:log --limit 100
```

### Step 4: Production Deployment
```bash
# Switch to production
firebase use production

# Verify environment variables are set
firebase functions:config:get

# Deploy all functions
firebase deploy --only functions

# Monitor logs
firebase functions:log --limit 100
```

---

## Post-Deployment Verification

### Immediate Checks (0-5 minutes)
- [ ] All functions deployed successfully
- [ ] No deployment errors in console
- [ ] Cloud Functions dashboard shows all functions healthy
- [ ] No container startup errors in logs

### Functional Testing (5-30 minutes)
- [ ] **Bank Verification**
  - [ ] Test with valid bank details
  - [ ] Test with invalid bank details
  - [ ] Verify Razorpay API calls work
  - [ ] Check Firestore updates

- [ ] **Payment Processing**
  - [ ] Test wallet credit flow
  - [ ] Test booking payment flow
  - [ ] Verify webhook processing
  - [ ] Check payment logs

- [ ] **Webhook Endpoints**
  - [ ] Test Razorpay webhook delivery
  - [ ] Verify signature validation
  - [ ] Check transaction processing

### Monitoring (30 minutes - 24 hours)
- [ ] Monitor error rates in Cloud Functions dashboard
- [ ] Check for any configuration-related errors
- [ ] Verify cold start times are acceptable (<2s)
- [ ] Monitor memory usage
- [ ] Check invocation success rate (target: >99.9%)

---

## Rollback Plan

### If Issues Occur

#### Option 1: Quick Rollback (Recommended)
```bash
# Revert to previous deployment
firebase deploy --only functions --force

# Or revert specific function
firebase deploy --only functions:verifyTechnicianBankAccount --force
```

#### Option 2: Code Rollback
```bash
# Revert the commit
git revert HEAD

# Rebuild and deploy
npm run build
firebase deploy --only functions
```

#### Option 3: Emergency Hotfix
If critical issues occur, temporarily restore old code:
```typescript
// EMERGENCY ONLY - NOT RECOMMENDED
const RAZORPAY_KEY_ID = functions.config().razorpay?.key_id || process.env.RAZORPAY_KEY_ID;
```

**Note:** This will cause v2 errors but may work temporarily in v1 runtime.

---

## Success Criteria

### ✅ Deployment Successful If:
1. All functions deploy without errors
2. No container startup failures
3. Bank verification works correctly
4. Payment processing works correctly
5. Webhooks process successfully
6. No increase in error rates
7. Cold start times are acceptable
8. All logs show clean startup

### ❌ Rollback Required If:
1. Container healthcheck failures
2. Configuration errors in logs
3. Payment processing failures
4. Webhook signature failures
5. Error rate >1%
6. Critical functionality broken

---

## Monitoring Commands

### Real-time Log Monitoring
```bash
# All functions
firebase functions:log --limit 100

# Specific function
firebase functions:log --only verifyTechnicianBankAccount

# Filter for errors
firebase functions:log | findstr /i "error"

# Filter for config issues
firebase functions:log | findstr /i "config"
```

### Cloud Console Monitoring
1. Go to: https://console.cloud.google.com
2. Select project
3. Navigate to: Cloud Functions
4. Check:
   - Invocations graph
   - Error rate
   - Execution time
   - Memory usage

---

## Support Contacts

### Internal
- **Developer:** [Your Name]
- **DevOps:** [DevOps Contact]
- **On-Call:** [On-Call Number]

### External
- **Firebase Support:** https://firebase.google.com/support
- **Razorpay Support:** https://razorpay.com/support
- **Google Cloud Support:** https://cloud.google.com/support

---

## Sign-Off

### Pre-Deployment
- [ ] Code reviewed by: _______________
- [ ] Environment variables verified by: _______________
- [ ] Staging tested by: _______________
- [ ] Approved for production by: _______________

### Post-Deployment
- [ ] Production deployment completed by: _______________
- [ ] Functional testing completed by: _______________
- [ ] Monitoring verified by: _______________
- [ ] Sign-off by: _______________

**Deployment Date:** _______________  
**Deployment Time:** _______________  
**Deployed By:** _______________

---

## Notes

_Add any deployment-specific notes here:_

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-XX  
**Status:** Ready for Deployment
