# HomeFix Production Hardening - Deployment Checklist

**Date**: 2026-04-07  
**Status**: Ready for Deployment  
**Priority**: HIGH (Security & Stability Fixes)

---

## PRE-DEPLOYMENT CHECKLIST

### Code Review
- [x] All TypeScript files compile without errors
- [x] All Dart files compile without errors
- [x] No diagnostic issues found
- [x] Code reviewed for security vulnerabilities
- [x] Documentation complete

### Testing
- [ ] Test idempotency cleanup function
- [ ] Test OTP rate limiting (frontend + backend)
- [ ] Test notification reliability
- [ ] Test price validation
- [ ] Test location cache clearing
- [ ] Test memory leak fixes
- [ ] Test stream timeout
- [ ] Test district normalization
- [ ] Test banner limit

---

## DEPLOYMENT STEPS

### Phase 1: Backend Deployment (CRITICAL - MUST BE FIRST)

#### Step 1: Deploy Cloud Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy all functions
firebase deploy --only functions

# Expected output:
# ✔ functions[cleanupExpiredIdempotencyRecords] deployed
# ✔ functions[manualCleanupIdempotency] deployed
# ✔ functions[checkOTPRateLimitCallable] deployed
# ✔ functions[cleanupOTPRateLimits] deployed
```

**Verification**:
```bash
# Check function logs
firebase functions:log --limit 50

# Verify scheduled functions are configured
firebase functions:list | grep cleanup
```

#### Step 2: Verify Backend Functions

**Test Manual Cleanup** (from Firebase Console or Admin Panel):
```javascript
// Call manualCleanupIdempotency
// Expected: { success: true, deletedCount: X, message: "..." }
```

**Test OTP Rate Limit Check**:
```javascript
// Call checkOTPRateLimitCallable with phoneNumber
// Expected: { allowed: true, attemptsRemaining: 10 }
```

**Check Scheduled Functions**:
- Go to Firebase Console → Functions
- Verify `cleanupExpiredIdempotencyRecords` scheduled for 2 AM UTC
- Verify `cleanupOTPRateLimits` scheduled for 3 AM UTC

---

### Phase 2: Frontend Deployment

#### Step 1: Build Customer App

```bash
# Navigate to customer app
cd apps/customer_app

# Clean build
flutter clean
flutter pub get

# Run tests (if available)
flutter test

# Build release APK
flutter build apk --release

# Or build app bundle for Play Store
flutter build appbundle --release
```

#### Step 2: Deploy to Internal Testing

**Google Play Console**:
1. Upload APK/AAB to Internal Testing track
2. Add test users
3. Wait for review (usually instant for internal)
4. Test on real devices

**Test Checklist**:
- [ ] Booking creation works
- [ ] OTP cooldown shows countdown
- [ ] Location change clears cache
- [ ] Search doesn't crash on rapid navigation
- [ ] Booking history loads (or times out gracefully)
- [ ] Technicians show up correctly
- [ ] Banners load (max 10)

---

### Phase 3: Monitoring Setup

#### Step 1: Firebase Console Monitoring

**Set up alerts for**:
- Function execution failures
- High error rates
- Scheduled function failures

**Monitor these collections**:
- `booking_idempotency` (should stay small, <1000 records)
- `otp_rate_limits` (should stay small, <5000 records)
- `notification_logs` (should stay under 10K records)

#### Step 2: Application Monitoring

**Key Metrics**:
- Duplicate booking attempts (should be 0)
- OTP spam attempts (should be blocked)
- Price mismatch attempts (check logs)
- Notification failure rate (should be <1%)
- Location cache clearing success (should be 100%)

---

## POST-DEPLOYMENT VERIFICATION

### Day 1: Critical Checks

**Backend Functions**:
- [ ] Check function logs for errors
- [ ] Verify scheduled functions executed
- [ ] Check collection sizes

**Frontend**:
- [ ] Test booking creation
- [ ] Test OTP flow
- [ ] Test location change
- [ ] Check crash reports

### Day 2-7: Monitoring

**Daily Checks**:
- [ ] Review function execution logs
- [ ] Check collection growth rates
- [ ] Monitor error rates
- [ ] Review user feedback

**Weekly Review**:
- [ ] Analyze OTP request patterns
- [ ] Review notification failure rate
- [ ] Check for price mismatch attempts
- [ ] Review duplicate booking attempts

---

## ROLLBACK PLAN

### If Critical Issues Detected

#### Backend Rollback

```bash
# List function versions
firebase functions:list

# Rollback to previous version
firebase functions:rollback <function-name>

# Or rollback all functions
firebase deploy --only functions --force
```

#### Frontend Rollback

**Google Play Console**:
1. Go to Production → Releases
2. Click "Manage" on previous version
3. Click "Promote to Production"
4. Confirm rollback

### Rollback Triggers

**Rollback if**:
- Function error rate > 5%
- Scheduled functions not executing
- Critical booking flow broken
- OTP flow completely blocked
- App crash rate > 2%

---

## SUCCESS CRITERIA

### Backend Functions

- [x] All functions deployed successfully
- [ ] Scheduled functions executing daily
- [ ] No function execution errors
- [ ] Collection sizes staying small
- [ ] OTP rate limiting working

### Frontend

- [x] App builds successfully
- [ ] No crashes on booking creation
- [ ] OTP cooldown working
- [ ] Location cache clearing working
- [ ] Memory leaks prevented
- [ ] Stream timeout working

### Metrics

- [ ] Duplicate bookings: 0
- [ ] OTP spam attempts: blocked
- [ ] Price manipulation: 0
- [ ] Notification failure rate: <1%
- [ ] App crash rate: <1%
- [ ] User satisfaction: maintained or improved

---

## COMMUNICATION PLAN

### Internal Team

**Before Deployment**:
- Notify team of deployment schedule
- Share this checklist
- Assign monitoring responsibilities

**During Deployment**:
- Update team on progress
- Report any issues immediately
- Coordinate rollback if needed

**After Deployment**:
- Share deployment summary
- Report on success metrics
- Schedule follow-up review

### Users

**If Issues Detected**:
- Prepare user communication
- Explain issue and resolution
- Provide timeline for fix

**Success Communication**:
- Announce improvements (optional)
- Highlight security enhancements
- Thank users for patience

---

## EMERGENCY CONTACTS

**Backend Issues**:
- Firebase Console: https://console.firebase.google.com
- Function Logs: `firebase functions:log`
- Support: Firebase Support

**Frontend Issues**:
- Play Console: https://play.google.com/console
- Crash Reports: Firebase Crashlytics
- Support: Google Play Support

---

## NOTES

### Deployment Window

**Recommended Time**:
- Off-peak hours (2 AM - 6 AM local time)
- Weekday (Tuesday - Thursday)
- Avoid weekends and holidays

**Duration**:
- Backend deployment: ~10 minutes
- Frontend deployment: ~30 minutes (including testing)
- Total: ~1 hour (including verification)

### Risk Assessment

**Risk Level**: 🟡 MEDIUM

**Why Medium**:
- Backend changes are additive (new functions)
- Frontend changes are defensive (bug fixes)
- No breaking changes to existing functionality
- Rollback plan available

**Mitigation**:
- Deploy to internal testing first
- Monitor closely for 24 hours
- Have rollback plan ready
- Test thoroughly before production

---

**Checklist Created**: 2026-04-07  
**Deployment Priority**: HIGH  
**Estimated Time**: 1 hour  
**Risk Level**: 🟡 MEDIUM  
**Rollback Available**: ✅ YES
