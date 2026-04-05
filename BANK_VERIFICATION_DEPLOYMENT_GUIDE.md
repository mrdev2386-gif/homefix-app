# BANK VERIFICATION SYSTEM - PRODUCTION DEPLOYMENT GUIDE

## 🎯 Overview

This guide covers the deployment of the **production-safe bank verification system** with:
- ✅ Idempotency (no duplicate verifications)
- ✅ Race condition protection (verification locks)
- ✅ Rate limiting (max 5 attempts per hour)
- ✅ Auto-cleanup (stuck verifications)
- ✅ Secure data handling (masked account numbers)
- ✅ Safe retries (resubmission allowed)

---

## 📋 Pre-Deployment Checklist

### 1. Environment Variables
Ensure these are set in Firebase Functions:

```bash
firebase functions:config:set \
  razorpay.key_id="YOUR_RAZORPAY_KEY_ID" \
  razorpay.key_secret="YOUR_RAZORPAY_KEY_SECRET"
```

Verify:
```bash
firebase functions:config:get
```

### 2. Firestore Indexes
No additional indexes required for this update.

### 3. Firestore Rules
Update `firestore.rules` with:

```javascript
// Verification requests (idempotency)
match /verificationRequests/{requestId} {
  allow read, write: if false; // Only Cloud Functions
}

// Technicians - protect verification fields
match /technicians/{technicianId} {
  allow update: if request.auth.uid == technicianId 
    && !request.resource.data.diff(resource.data).affectedKeys().hasAny([
      'verificationLock',
      'verificationAttempts',
      'lastVerificationAttemptAt',
      'bankVerified',
      'bankVerificationStatus',
      'fundAccountId',
      'razorpayContactId'
    ]);
}
```

---

## 🚀 Deployment Steps

### Step 1: Backup Current System

```bash
# Export current technician data
firebase firestore:export gs://YOUR_BUCKET/backups/technicians-$(date +%Y%m%d)

# Backup current functions
cd functions
cp -r lib lib_backup_$(date +%Y%m%d)
```

### Step 2: Run Migration Script

Add new fields to existing technician documents:

```bash
cd scripts
node add_bank_verification_fields.js
```

Expected output:
```
🔄 Starting migration: Add bank verification security fields...

📊 Found 150 technician documents

✅ Queued: John Doe
✅ Queued: Jane Smith
...

💾 Committed batch of 150 updates

==================================================
📈 Migration Summary:
==================================================
✅ Updated: 150
⏭️  Skipped: 0
❌ Errors: 0
==================================================

✨ Migration complete!
```

### Step 3: Deploy Cloud Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

This will deploy:
- ✅ `verifyTechnicianBankAccountSecure` (updated)
- ✅ `checkBankVerificationStatus` (updated)
- ✅ `cleanupStuckBankVerifications` (new - scheduled)
- ✅ `cleanupOldIdempotencyRecords` (new - scheduled)

### Step 4: Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### Step 5: Verify Deployment

#### Check Function Logs
```bash
firebase functions:log --only verifyTechnicianBankAccountSecure --limit 10
```

#### Test Verification Flow
1. Open technician app
2. Go to Profile → Bank Details
3. Submit bank account details
4. Verify status changes: `verifying` → `verified` or `failed`

#### Check Scheduled Functions
```bash
# View scheduled functions
firebase functions:list | grep cleanup

# Check cleanup logs (after 10 minutes)
firebase functions:log --only cleanupStuckBankVerifications
```

---

## 🔍 Verification Tests

### Test 1: Normal Verification Flow

```bash
# Call function via Firebase Console or app
{
  "accountHolderName": "John Doe",
  "accountNumber": "1234567890",
  "ifscCode": "SBIN0001234"
}
```

Expected:
- Status: `verifying` → `verified`
- Lock: `true` → `false`
- `fundAccountId` created
- `razorpayContactId` created (or reused)

### Test 2: Idempotency Check

Submit same details twice immediately:

**First call:**
```json
{
  "success": true,
  "status": "verified",
  "fundAccountId": "fa_xxx",
  "cached": false
}
```

**Second call (within 24 hours):**
```json
{
  "success": true,
  "status": "verified",
  "fundAccountId": "fa_xxx",
  "cached": true  // ← Idempotent response
}
```

### Test 3: Race Condition Protection

Try submitting verification while one is in progress:

Expected error:
```json
{
  "code": "failed-precondition",
  "message": "Verification already in progress. Please wait."
}
```

### Test 4: Rate Limiting

Submit 6 verification attempts within 1 hour:

Expected on 6th attempt:
```json
{
  "code": "resource-exhausted",
  "message": "Too many verification attempts. Please try again after 1 hour."
}
```

### Test 5: Auto-Cleanup

1. Manually set a technician to `verifying` status
2. Set `updatedAt` to 5 minutes ago
3. Wait for scheduled function (runs every 10 minutes)
4. Verify status changed to `failed` with message: "Verification timeout. Please retry."

---

## 📊 Monitoring

### Key Metrics to Track

1. **Verification Success Rate**
```javascript
// Query payment_logs
db.collection('payment_logs')
  .where('action', '==', 'bank_verification_success')
  .where('createdAt', '>=', last24Hours)
  .count()
```

2. **Stuck Verifications Cleaned**
```javascript
db.collection('payment_logs')
  .where('action', '==', 'bank_verification_cleanup')
  .where('createdAt', '>=', last24Hours)
  .count()
```

3. **Rate Limit Hits**
```bash
firebase functions:log --only verifyTechnicianBankAccountSecure | grep "resource-exhausted"
```

4. **Idempotency Cache Hits**
```bash
firebase functions:log --only verifyTechnicianBankAccountSecure | grep "Idempotent request"
```

### Firestore Queries

**Find technicians with failed verifications:**
```javascript
db.collection('technicians')
  .where('bankVerificationStatus', '==', 'failed')
  .get()
```

**Find stuck verifications (manual check):**
```javascript
const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000);
db.collection('technicians')
  .where('bankVerificationStatus', '==', 'verifying')
  .where('updatedAt', '<', twoMinutesAgo)
  .get()
```

**Check idempotency records:**
```javascript
db.collection('verificationRequests')
  .orderBy('createdAt', 'desc')
  .limit(10)
  .get()
```

---

## 🐛 Troubleshooting

### Issue 1: Verification Stuck in "verifying"

**Symptoms:**
- Status remains "verifying" for > 2 minutes
- Lock remains `true`

**Solution:**
```javascript
// Manual fix (run in Firebase Console)
db.collection('technicians').doc('TECHNICIAN_ID').update({
  bankVerificationStatus: 'failed',
  bankVerificationMessage: 'Verification timeout. Please retry.',
  verificationLock: false
});
```

Or wait for auto-cleanup (runs every 10 minutes).

### Issue 2: Rate Limit Not Resetting

**Symptoms:**
- User still blocked after 1 hour

**Solution:**
```javascript
// Reset attempts manually
db.collection('technicians').doc('TECHNICIAN_ID').update({
  verificationAttempts: 0,
  lastVerificationAttemptAt: null
});
```

### Issue 3: Duplicate Contacts Created

**Symptoms:**
- Multiple `razorpayContactId` values in logs

**Check:**
```bash
firebase functions:log --only verifyTechnicianBankAccountSecure | grep "Creating new Razorpay contact"
```

**Solution:**
- System now reuses existing `razorpayContactId`
- No action needed for new verifications
- Old duplicates can be cleaned up manually in Razorpay dashboard

### Issue 4: Idempotency Records Not Expiring

**Symptoms:**
- `verificationRequests` collection growing

**Solution:**
- Scheduled cleanup runs daily at 2 AM
- Manual cleanup:
```javascript
const now = admin.firestore.Timestamp.now();
db.collection('verificationRequests')
  .where('expiresAt', '<', now)
  .get()
  .then(snapshot => {
    const batch = db.batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    return batch.commit();
  });
```

---

## 📈 Performance Optimization

### Firestore Indexes (if needed)

If queries are slow, create these indexes:

```bash
# Cleanup query index
firebase firestore:indexes:create \
  --collection-group=technicians \
  --field=bankVerificationStatus \
  --field=updatedAt

# Idempotency cleanup index
firebase firestore:indexes:create \
  --collection-group=verificationRequests \
  --field=expiresAt
```

---

## 🔐 Security Audit

### Data Masking Verification

Check logs to ensure account numbers are masked:

```bash
firebase functions:log --only verifyTechnicianBankAccountSecure | grep "accountNumber"
```

Expected format: `****1234` (not full account number)

### Lock Release Verification

Ensure locks are always released:

```javascript
// Query technicians with stuck locks
db.collection('technicians')
  .where('verificationLock', '==', true)
  .get()
  .then(snapshot => {
    console.log(`Found ${snapshot.size} technicians with active locks`);
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const lockAge = Date.now() - data.updatedAt.toMillis();
      console.log(`${doc.id}: Lock age = ${lockAge}ms`);
    });
  });
```

---

## 📝 Rollback Plan

If issues occur, rollback to previous version:

```bash
# Restore previous functions
cd functions
rm -rf lib
mv lib_backup_YYYYMMDD lib

# Redeploy
npm run build
firebase deploy --only functions

# Restore Firestore data (if needed)
firebase firestore:import gs://YOUR_BUCKET/backups/technicians-YYYYMMDD
```

---

## ✅ Post-Deployment Checklist

- [ ] Migration script completed successfully
- [ ] All functions deployed without errors
- [ ] Firestore rules updated
- [ ] Test verification flow works
- [ ] Idempotency working (duplicate requests return cached result)
- [ ] Race condition protection working (concurrent requests blocked)
- [ ] Rate limiting working (6th attempt blocked)
- [ ] Auto-cleanup scheduled function running
- [ ] Logs show masked account numbers
- [ ] No stuck verifications after 10 minutes
- [ ] Monitoring dashboard updated

---

## 📞 Support

For issues or questions:
- Check logs: `firebase functions:log`
- Review Firestore data: Firebase Console
- Contact: 9508322397

---

## 🎉 Success Criteria

System is production-ready when:
1. ✅ 0 duplicate fund accounts created
2. ✅ 0 stuck verifications after 10 minutes
3. ✅ 100% lock release rate
4. ✅ Idempotency cache hit rate > 10%
5. ✅ Rate limiting blocks excessive attempts
6. ✅ All account numbers masked in logs
7. ✅ Resubmission works for failed verifications

---

**Deployment Date:** _____________
**Deployed By:** _____________
**Version:** 2.0.0 (Production-Safe Bank Verification)
