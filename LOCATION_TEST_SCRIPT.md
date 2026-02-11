# Location Testing Script

## Quick Test Commands

### 1. Clean Build
```bash
cd apps/customer_app
flutter clean
flutter pub get
flutter run --release
```

### 2. Check Logs
```bash
# Filter for location logs only
adb logcat | grep "LocationProvider"
```

Expected output when working:
```
[LocationProvider] Step 1: Checking location service...
[LocationProvider] Location service enabled: true
[LocationProvider] Step 2: Checking permission...
[LocationProvider] Current permission: whileInUse
[LocationProvider] Permission granted: true
[LocationProvider] Step 3: Fetching position...
[LocationProvider] ✅ Position fetched: 28.6139, 77.2090
[LocationProvider] Step 4: Reverse geocoding...
[LocationProvider] ✅ Address: New Delhi, Delhi
```

---

## Manual Test Scenarios

### ✅ Scenario 1: First Time User (Happy Path)
**Steps**:
1. Fresh install app
2. Login
3. Tap location selector on dashboard
4. When permission dialog appears → Grant
5. Wait for location to load

**Expected Result**:
- ✅ Permission dialog shows
- ✅ Location fetches within 5 seconds
- ✅ Address displays (or coordinates if geocoding fails)
- ✅ No error messages
- ✅ Logs show all steps with ✅

**Pass Criteria**: Location displays correctly

---

### ✅ Scenario 2: Location Service Disabled
**Steps**:
1. Go to device Settings → Location
2. Turn OFF location
3. Open app
4. Tap location selector

**Expected Result**:
- ✅ Message: "Please enable location services in your device settings"
- ✅ No crash
- ✅ UI remains responsive
- ✅ Log shows: `Location service enabled: false`

**Pass Criteria**: Clear error message, no crash

---

### ✅ Scenario 3: Permission Denied (First Time)
**Steps**:
1. Fresh install
2. Tap location selector
3. When permission dialog appears → Deny

**Expected Result**:
- ✅ Message: "Location permission is required to find nearby services"
- ✅ No crash
- ✅ Can tap again to re-request
- ✅ Log shows: `Current permission: denied`

**Pass Criteria**: Clear message, can retry

---

### ✅ Scenario 4: Permission Denied Forever
**Steps**:
1. Deny permission
2. Check "Don't ask again"
3. Tap location selector again

**Expected Result**:
- ✅ Message: "Please enable location permission in app settings"
- ✅ Button/option to open settings
- ✅ No crash
- ✅ Log shows: `Current permission: deniedForever`

**Pass Criteria**: Guides user to settings

---

### ✅ Scenario 5: Timeout (Airplane Mode)
**Steps**:
1. Enable airplane mode
2. Tap location selector
3. Wait 10 seconds

**Expected Result**:
- ✅ Loading indicator shows for ~10 seconds
- ✅ Then shows: "Location request took too long. Please try again."
- ✅ No crash
- ✅ Log shows: `❌ Timeout`

**Pass Criteria**: Timeout handled gracefully

---

### ✅ Scenario 6: Poor GPS Signal (Indoor)
**Steps**:
1. Go indoors (basement/parking)
2. Tap location selector
3. Wait

**Expected Result**:
- ✅ Either fetches location (may take longer)
- ✅ Or times out with clear message
- ✅ Or shows coordinates if address unavailable
- ✅ No crash

**Pass Criteria**: Handles gracefully

---

### ✅ Scenario 7: Permission Granted, Then Revoked
**Steps**:
1. Grant permission initially
2. Location works
3. Go to Settings → Apps → HomeFix → Permissions
4. Revoke location permission
5. Return to app
6. Tap location selector

**Expected Result**:
- ✅ Detects permission revoked
- ✅ Shows permission denied message
- ✅ Can request permission again
- ✅ No crash

**Pass Criteria**: Detects permission change

---

### ✅ Scenario 8: Rapid Taps (Stress Test)
**Steps**:
1. Tap location selector rapidly 10 times
2. Observe behavior

**Expected Result**:
- ✅ No crash
- ✅ No multiple permission dialogs
- ✅ Handles gracefully
- ✅ Loading state managed correctly

**Pass Criteria**: No crash, stable behavior

---

## Automated Test Checklist

### Permission Tests
- [ ] Permission request shows on first use
- [ ] Permission denial handled
- [ ] Permission denial forever handled
- [ ] Permission granted works
- [ ] Permission revocation detected

### Service Tests
- [ ] Location service enabled check works
- [ ] Location service disabled handled
- [ ] Can open location settings

### Fetch Tests
- [ ] Position fetches successfully
- [ ] Timeout after 10 seconds
- [ ] Geocoding works
- [ ] Geocoding failure handled (shows coordinates)
- [ ] Network errors handled

### UI Tests
- [ ] Loading indicator shows
- [ ] Error messages display
- [ ] Address displays
- [ ] No UI blocking
- [ ] Can retry after error

---

## Log Analysis

### Success Pattern:
```
[LocationProvider] Step 1: Checking location service...
[LocationProvider] Location service enabled: true
[LocationProvider] Step 2: Checking permission...
[LocationProvider] Current permission: whileInUse
[LocationProvider] Permission granted: true
[LocationProvider] Step 3: Fetching position...
[LocationProvider] ✅ Position fetched: XX.XXXX, YY.YYYY
[LocationProvider] Step 4: Reverse geocoding...
[LocationProvider] ✅ Address: [Address]
```

### Service Disabled Pattern:
```
[LocationProvider] Step 1: Checking location service...
[LocationProvider] Location service enabled: false
```

### Permission Denied Pattern:
```
[LocationProvider] Step 2: Checking permission...
[LocationProvider] Current permission: denied
[LocationProvider] Permission after request: denied
```

### Timeout Pattern:
```
[LocationProvider] Step 3: Fetching position...
[LocationProvider] ❌ Timeout: TimeoutException
```

---

## Performance Benchmarks

### Target Metrics:
- **Permission Check**: < 100ms
- **Service Check**: < 100ms
- **Position Fetch**: 2-5 seconds (normal)
- **Geocoding**: 1-3 seconds (normal)
- **Total Time**: < 8 seconds (normal)
- **Timeout**: 10 seconds (max)

### Measure Performance:
```dart
// Add to LocationProvider for testing
final stopwatch = Stopwatch()..start();
// ... fetch location ...
debugPrint('[LocationProvider] ⏱️ Total time: ${stopwatch.elapsedMilliseconds}ms');
```

---

## Device-Specific Tests

### Android 13
- [ ] Permission dialog shows
- [ ] Location fetches
- [ ] All error scenarios work

### Android 14
- [ ] Permission dialog shows
- [ ] Location fetches
- [ ] All error scenarios work
- [ ] No new permission issues

### Different Manufacturers
- [ ] Samsung (One UI)
- [ ] Xiaomi (MIUI)
- [ ] OnePlus (OxygenOS)
- [ ] Google Pixel (Stock Android)

---

## Regression Tests

After any code changes, verify:
- [ ] Location still fetches
- [ ] Permissions still work
- [ ] Error handling still works
- [ ] Logs still show
- [ ] No new crashes

---

## Production Monitoring

### Metrics to Track:
1. **Success Rate**: % of successful location fetches
2. **Average Time**: Time to fetch location
3. **Error Rate**: % of failures by type
4. **Permission Denial Rate**: % of users denying permission

### Firebase Analytics Events:
```dart
// Add these to track in production
analytics.logEvent(
  name: 'location_fetch_success',
  parameters: {'time_ms': elapsedTime},
);

analytics.logEvent(
  name: 'location_fetch_failed',
  parameters: {'error': errorType},
);
```

---

## Troubleshooting Guide

### Problem: No logs appearing
**Solution**: 
```bash
# Check if app is running
adb shell ps | grep homefix

# Clear logcat and try again
adb logcat -c
adb logcat | grep LocationProvider
```

### Problem: Permission dialog doesn't show
**Solution**:
```bash
# Reset app permissions
adb shell pm reset-permissions com.homefix.customer

# Or reinstall app
flutter clean
flutter run
```

### Problem: Always times out
**Solution**:
1. Check GPS is enabled
2. Try outdoors
3. Check internet connection
4. Verify Google Play Services updated

---

## Sign-Off Checklist

Before marking as complete:
- [ ] All 8 scenarios tested and passed
- [ ] Logs show correct information
- [ ] No crashes in any scenario
- [ ] Error messages are user-friendly
- [ ] Performance is acceptable
- [ ] Works on Android 13 and 14
- [ ] Tested on at least 2 different devices
- [ ] Code reviewed
- [ ] Documentation complete

---

**Test Status**: ⏳ READY FOR TESTING
**Tester**: _______________
**Date**: _______________
**Result**: ⬜ PASS  ⬜ FAIL
**Notes**: _______________
