# ✅ PRODUCTION VERIFICATION CHECKLIST

## Pre-Deployment Verification

### 1. NotificationsService Dispose Fix
- [ ] Run: `flutter clean && flutter pub get`
- [ ] Test: Logout and verify no crash
- [ ] Test: App background/foreground transitions
- [ ] Verify: No "disposed ChangeNotifier" errors in logs

### 2. AuthProvider Safety
- [ ] Test: Add new address - should not silently fail
- [ ] Test: Update address - should show error if auth fails
- [ ] Test: Delete address - should show error if auth fails
- [ ] Test: Payment method operations - should handle null user

### 3. CartProvider Timer Fix
- [ ] Test: Add item to cart multiple times rapidly
- [ ] Monitor: No multiple timeout warnings in logs
- [ ] Verify: Memory usage stable (no leak)
- [ ] Test: Cart loads within 15 seconds

### 4. BookingProvider Null Safety
- [ ] Test: Create booking with SharedPreferences available
- [ ] Test: Create booking if SharedPreferences fails (fallback)
- [ ] Verify: Idempotency key persists correctly
- [ ] Verify: No crash on booking creation

### 5. Location Race Condition
- [ ] Test: Open home screen as new user
- [ ] Verify: Services filter by location correctly
- [ ] Verify: No "loading..." state persists
- [ ] Test: Change location and verify services update

---

## Build & Test Commands

```bash
# Clean build
flutter clean
flutter pub get

# Run with debug logging
flutter run -v

# Build APK for testing
flutter build apk --debug

# Run tests
flutter test

# Check for issues
flutter analyze
```

---

## Deployment Steps

1. **Merge to main branch**
   ```bash
   git add .
   git commit -m "fix: Apply 5 critical production stability patches"
   git push origin main
   ```

2. **Build release APK**
   ```bash
   flutter build apk --release
   ```

3. **Test on real device**
   - Install APK on Android device
   - Run through all 5 test scenarios above
   - Monitor logs for errors

4. **Deploy to Play Store**
   - Upload to internal testing track first
   - Get team approval
   - Promote to production

---

## Rollback Plan

If issues occur:

1. Revert commit: `git revert <commit-hash>`
2. Rebuild and redeploy
3. Notify team of rollback

---

## Post-Deployment Monitoring

Monitor for 24 hours:
- [ ] Crash rate (should be 0%)
- [ ] ANR rate (should be 0%)
- [ ] User feedback in Play Store
- [ ] Firebase Crashlytics dashboard
- [ ] Performance metrics

---

## Success Criteria

✅ **All of the following must be true**:
1. No crashes on logout
2. No crashes on cart operations
3. No crashes on booking creation
4. Services filter by location correctly
5. No memory leaks detected
6. All auth operations handle errors properly

---

**Status**: Ready for deployment
**Risk Level**: LOW (all fixes are defensive, no breaking changes)
**Estimated Impact**: Eliminates 5 critical crash scenarios
