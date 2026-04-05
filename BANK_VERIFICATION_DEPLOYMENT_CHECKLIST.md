# BANK VERIFICATION SYSTEM - DEPLOYMENT CHECKLIST

## ✅ PRE-DEPLOYMENT CHECKLIST

### Environment Setup
- [ ] Razorpay API keys configured in Firebase Functions
- [ ] Service account key available for migration script
- [ ] Firebase CLI installed and authenticated
- [ ] Node.js and npm installed (for functions)

### Backup
- [ ] Firestore data exported
  ```bash
  firebase firestore:export gs://YOUR_BUCKET/backups/technicians-$(date +%Y%m%d)
  ```
- [ ] Current functions code backed up
  ```bash
  cd functions && cp -r lib lib_backup_$(date +%Y%m%d)
  ```

### Code Review
- [ ] All 12 fixes reviewed and understood
- [ ] Migration script tested on staging
- [ ] Firestore rules reviewed
- [ ] Documentation read and understood

---

## 🚀 DEPLOYMENT CHECKLIST

### Step 1: Migration
- [ ] Navigate to scripts directory
  ```bash
  cd scripts
  ```
- [ ] Run migration script
  ```bash
  node add_bank_verification_fields.js
  ```
- [ ] Verify output shows successful updates
- [ ] Check sample technician document has new fields:
  - `verificationLock: false`
  - `verificationAttempts: 0`
  - `lastVerificationAttemptAt: null`

### Step 2: Deploy Functions
- [ ] Navigate to functions directory
  ```bash
  cd functions
  ```
- [ ] Install dependencies (if needed)
  ```bash
  npm install
  ```
- [ ] Build functions
  ```bash
  npm run build
  ```
- [ ] Deploy functions
  ```bash
  firebase deploy --only functions
  ```
- [ ] Verify deployment success in console
- [ ] Check new functions are listed:
  - `verifyTechnicianBankAccountSecure`
  - `checkBankVerificationStatus`
  - `cleanupStuckBankVerifications`
  - `cleanupOldIdempotencyRecords`

### Step 3: Deploy Firestore Rules
- [ ] Review rules changes
- [ ] Deploy rules
  ```bash
  firebase deploy --only firestore:rules
  ```
- [ ] Verify rules deployed successfully

---

## 🧪 POST-DEPLOYMENT TESTING

### Test 1: Normal Verification
- [ ] Open technician app
- [ ] Navigate to Profile → Bank Details
- [ ] Submit valid bank details
- [ ] Verify status changes: `verifying` → `verified`
- [ ] Check `fundAccountId` created
- [ ] Check `razorpayContactId` created

### Test 2: Idempotency
- [ ] Submit same bank details again
- [ ] Verify response is instant (cached)
- [ ] Check logs show "Idempotent request detected"
- [ ] Verify no new Razorpay API call made

### Test 3: Race Condition Protection
- [ ] Attempt to submit verification twice rapidly
- [ ] Verify second request blocked
- [ ] Check error: "Verification already in progress"

### Test 4: Rate Limiting
- [ ] Submit 5 verification attempts
- [ ] Attempt 6th verification
- [ ] Verify blocked with "Too many attempts"
- [ ] Wait 1 hour and verify counter resets

### Test 5: Duplicate Prevention
- [ ] Verify a bank account successfully
- [ ] Attempt to verify again
- [ ] Verify returns "Already verified" immediately
- [ ] Check no new fund account created

### Test 6: Safe Retry
- [ ] Submit invalid bank details (to fail)
- [ ] Verify status changes to `failed`
- [ ] Submit correct details
- [ ] Verify new verification succeeds
- [ ] Check old fund account overwritten

### Test 7: Auto-Cleanup
- [ ] Manually set a technician to `verifying` status
- [ ] Set `updatedAt` to 5 minutes ago
- [ ] Wait 10 minutes for scheduled function
- [ ] Verify status changed to `failed`
- [ ] Check message: "Verification timeout. Please retry."

### Test 8: Data Masking
- [ ] Check function logs
  ```bash
  firebase functions:log --only verifyTechnicianBankAccountSecure
  ```
- [ ] Verify account numbers are masked: `****1234`
- [ ] Verify no full account numbers in logs

---

## 📊 MONITORING CHECKLIST

### Immediate (First Hour)
- [ ] Check function logs for errors
  ```bash
  firebase functions:log --only verifyTechnicianBankAccountSecure --limit 50
  ```
- [ ] Verify no stuck verifications
  ```javascript
  db.collection('technicians')
    .where('bankVerificationStatus', '==', 'verifying')
    .get()
  ```
- [ ] Check idempotency records created
  ```javascript
  db.collection('verificationRequests').limit(10).get()
  ```

### First 24 Hours
- [ ] Monitor verification success rate
- [ ] Check for duplicate fund accounts in Razorpay
- [ ] Verify cleanup function ran (check logs at 10-minute intervals)
- [ ] Review payment_logs for patterns
- [ ] Check for rate limit hits

### First Week
- [ ] Analyze verification metrics
- [ ] Review support tickets related to bank verification
- [ ] Check idempotency cache hit rate
- [ ] Verify no stuck verifications
- [ ] Confirm cleanup functions running daily

---

## 🔍 VERIFICATION QUERIES

### Check Stuck Verifications
```javascript
const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000);
db.collection('technicians')
  .where('bankVerificationStatus', '==', 'verifying')
  .where('updatedAt', '<', twoMinutesAgo)
  .get()
  .then(snapshot => console.log(`Stuck: ${snapshot.size}`));
```

### Check Failed Verifications (Last 24h)
```javascript
const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
db.collection('payment_logs')
  .where('action', '==', 'bank_verification_failed')
  .where('createdAt', '>=', yesterday)
  .get()
  .then(snapshot => console.log(`Failed: ${snapshot.size}`));
```

### Check Idempotency Cache Hits
```javascript
db.collection('payment_logs')
  .where('action', '==', 'bank_verification_attempt')
  .where('status', '==', 'already_verified')
  .get()
  .then(snapshot => console.log(`Cache hits: ${snapshot.size}`));
```

### Check Rate Limit Hits
```bash
firebase functions:log --only verifyTechnicianBankAccountSecure | grep "resource-exhausted"
```

### Check Active Locks
```javascript
db.collection('technicians')
  .where('verificationLock', '==', true)
  .get()
  .then(snapshot => {
    console.log(`Active locks: ${snapshot.size}`);
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const lockAge = Date.now() - data.updatedAt.toMillis();
      console.log(`${doc.id}: ${lockAge}ms`);
    });
  });
```

---

## 🐛 TROUBLESHOOTING CHECKLIST

### Issue: Verification Stuck
- [ ] Check if cleanup function is running
  ```bash
  firebase functions:log --only cleanupStuckBankVerifications
  ```
- [ ] Manually fix if needed
  ```javascript
  db.collection('technicians').doc('TECH_ID').update({
    bankVerificationStatus: 'failed',
    bankVerificationMessage: 'Verification timeout. Please retry.',
    verificationLock: false
  });
  ```

### Issue: Rate Limit Not Resetting
- [ ] Check `lastVerificationAttemptAt` timestamp
- [ ] Manually reset if needed
  ```javascript
  db.collection('technicians').doc('TECH_ID').update({
    verificationAttempts: 0,
    lastVerificationAttemptAt: null
  });
  ```

### Issue: Duplicate Contacts
- [ ] Check Razorpay dashboard for duplicates
- [ ] Review logs for "Creating new Razorpay contact"
- [ ] Verify `razorpayContactId` is being reused

### Issue: Lock Not Released
- [ ] Query for stuck locks (see above)
- [ ] Manually release if needed
  ```javascript
  db.collection('technicians').doc('TECH_ID').update({
    verificationLock: false
  });
  ```

---

## 📈 SUCCESS METRICS

### Day 1
- [ ] Zero deployment errors
- [ ] All tests passing
- [ ] No stuck verifications
- [ ] No duplicate fund accounts

### Week 1
- [ ] Verification success rate > 95%
- [ ] Idempotency cache hit rate > 10%
- [ ] Rate limit hits < 1%
- [ ] Zero support tickets for stuck verifications

### Month 1
- [ ] System running smoothly
- [ ] Cleanup functions working
- [ ] No manual interventions needed
- [ ] Cost savings realized

---

## 🔄 ROLLBACK CHECKLIST

### If Critical Issues Occur
- [ ] Stop new verifications (if needed)
- [ ] Restore previous functions
  ```bash
  cd functions
  rm -rf lib
  mv lib_backup_YYYYMMDD lib
  firebase deploy --only functions
  ```
- [ ] Restore Firestore data (if needed)
  ```bash
  firebase firestore:import gs://bucket/backups/technicians-YYYYMMDD
  ```
- [ ] Notify team and users
- [ ] Document issues for post-mortem

---

## 📝 DOCUMENTATION CHECKLIST

### Created Documents
- [x] `BANK_VERIFICATION_SCHEMA.md` - Schema documentation
- [x] `BANK_VERIFICATION_DEPLOYMENT_GUIDE.md` - Detailed deployment guide
- [x] `BANK_VERIFICATION_PRODUCTION_SAFE.md` - Quick reference
- [x] `BANK_VERIFICATION_FLOW_DIAGRAM.md` - Visual flow diagrams
- [x] `BANK_VERIFICATION_EXECUTIVE_SUMMARY.md` - Executive summary
- [x] `BANK_VERIFICATION_DEPLOYMENT_CHECKLIST.md` - This checklist

### Updated Documents
- [x] `functions/src/technician/bank_verification.ts` - Complete rewrite
- [x] `functions/src/index.ts` - Export new functions

### New Files
- [x] `functions/src/technician/bank_verification_cleanup.ts` - Cleanup functions
- [x] `scripts/add_bank_verification_fields.js` - Migration script

---

## ✅ FINAL SIGN-OFF

### Development
- [ ] Code reviewed
- [ ] Tests passing
- [ ] Documentation complete
- [ ] Ready for deployment

### QA
- [ ] Manual testing complete
- [ ] Integration testing complete
- [ ] Security review complete
- [ ] Approved for production

### DevOps
- [ ] Deployment plan reviewed
- [ ] Monitoring configured
- [ ] Alerts set up
- [ ] Rollback plan ready

### Product
- [ ] Requirements met
- [ ] User experience validated
- [ ] Business metrics defined
- [ ] Approved for release

---

## 📞 CONTACTS

- **Technical Lead:** _____________
- **DevOps:** _____________
- **Support:** 9508322397
- **Emergency:** _____________

---

## 🎉 DEPLOYMENT COMPLETE

- [ ] All checklist items completed
- [ ] System verified working
- [ ] Monitoring in place
- [ ] Team notified
- [ ] Documentation updated

**Deployment Date:** _____________  
**Deployed By:** _____________  
**Version:** 2.0.0  
**Status:** ✅ PRODUCTION
