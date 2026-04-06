# 🔧 Environment + Runtime Stability Fix

**This is NOT a code issue. This is an environment/network/cache issue.**

---

## 🎯 GOAL

Fix network connectivity, clear all caches, and ensure stable runtime environment for Razorpay SDK.

---

## ⚠️ CRITICAL: DO THIS FIRST

### Step 1: Fix Internet/DNS (CRITICAL)

**On your development machine:**

1. **Turn OFF VPN** (if using)
   - VPNs can block Firebase/Razorpay APIs
   - Disconnect completely

2. **Switch Network**
   - If on WiFi → Try mobile hotspot
   - If on mobile → Try different WiFi
   - Test with stable connection

3. **Restart Internet**
   - Windows: `ipconfig /flushdns`
   - Restart router if needed

4. **Test Basic Connectivity**
   ```bash
   ping google.com
   ping firestore.googleapis.com
   ```

**On your device/emulator:**

1. **Turn OFF VPN** on device
2. **Switch network** (WiFi ↔ Mobile data)
3. **Restart device/emulator**

---

## 🧪 Step 2: Test Firebase Connectivity

**Run your app and check:**

```dart
// Should load without errors
FirebaseFirestore.instance.collection('test').get()
```

**Common errors indicating network issues:**
- ❌ "Unable to resolve host firestore.googleapis.com"
- ❌ "Failed to get document because the client is offline"
- ❌ "Network error"
- ❌ "Connection timeout"

**If you see these errors:**
- Network is still broken
- Go back to Step 1
- DO NOT proceed until Firebase connects

---

## 🧹 Step 3: Clear Flutter + Device Cache

### Clear Flutter Cache

```bash
# Navigate to your app directory
cd apps/technician_app

# Clean everything
flutter clean

# Get dependencies fresh
flutter pub get

# Clear build cache
rm -rf build/
```

### Clear Device Cache

**Android Emulator:**
```bash
# Wipe data
emulator -avd YOUR_AVD_NAME -wipe-data
```

**Physical Device:**
1. Uninstall app completely
2. Clear app data from Settings
3. Restart device
4. Reinstall app fresh

---

## 🔄 Step 4: Restart Emulator/Device

### Emulator

```bash
# Close emulator completely
# Then restart fresh
emulator -avd YOUR_AVD_NAME
```

### Physical Device

1. Power off completely
2. Wait 10 seconds
3. Power on
4. Wait for full boot

---

## 🌍 Step 5: Verify Firebase Functions Region

**Check your app's functions service:**

```dart
// apps/technician_app/lib/core/services/functions_service.dart
// or wherever you initialize functions

// Should match deployed region
FirebaseFunctions.instanceFor(region: 'asia-south1')
```

**Verify deployed functions region:**
```bash
firebase functions:list
```

**Common mismatch:**
- App calls `us-central1`
- Functions deployed to `asia-south1`
- Result: Function not found

---

## 🧪 Step 6: Test Simple Function First

**Before testing Razorpay, test basic connectivity:**

```dart
// Call a simple function
final result = await FirebaseFunctions.instance
    .httpsCallable('testRazorpayConnection')
    .call();

print(result.data);
```

**If this fails:**
- Environment is still broken
- Check network again
- Check Firebase project ID
- Check function region

---

## 🚀 Step 7: Clean Redeploy Functions

```bash
# Navigate to functions directory
cd functions

# Remove all cached dependencies
rm -rf node_modules
rm -rf package-lock.json

# Fresh install
npm install

# Verify razorpay installed
npm list razorpay
# Should show: razorpay@2.9.2

# Build
npm run build
# Should exit with code 0

# Deploy clean
cd ..
firebase deploy --only functions

# Wait for deployment to complete
# Should see: ✔ Deploy complete!
```

---

## 🧪 Step 8: Test Again

### Test 1: Network Connectivity

```bash
# From your machine
ping firestore.googleapis.com
ping YOUR_PROJECT.cloudfunctions.net
```

### Test 2: Firebase Connection

```dart
// In your app
await FirebaseFirestore.instance.collection('test').get();
// Should work without errors
```

### Test 3: Functions Call

```dart
// Call test function
final result = await FirebaseFunctions.instance
    .httpsCallable('testRazorpayConnection')
    .call();

print('Success: ${result.data['success']}');
```

### Test 4: Bank KYC

```dart
// Try bank verification
// Should work without DNS errors
```

---

## ✅ EXPECTED RESULTS

After following all steps:

- ✅ No DNS errors
- ✅ Firebase connects properly
- ✅ Functions callable without timeout
- ✅ Razorpay SDK loads fully
- ✅ `contacts.create` works
- ✅ Bank KYC succeeds
- ✅ QR generation works

---

## ❌ TROUBLESHOOTING

### Issue: "Unable to resolve host"

**Cause:** DNS/Network issue

**Fix:**
1. Turn off VPN
2. Switch network
3. Flush DNS: `ipconfig /flushdns`
4. Restart device

### Issue: "Function not found"

**Cause:** Region mismatch

**Fix:**
```dart
// Match deployed region
FirebaseFunctions.instanceFor(region: 'asia-south1')
```

### Issue: "Connection timeout"

**Cause:** Firewall/Network blocking

**Fix:**
1. Check firewall settings
2. Allow Firebase domains
3. Try different network

### Issue: "Client is offline"

**Cause:** No internet connection

**Fix:**
1. Check internet connection
2. Test with `ping google.com`
3. Restart network

---

## 🔍 VERIFICATION CHECKLIST

Before testing Razorpay:

- [ ] VPN is OFF
- [ ] Internet is stable
- [ ] Can ping firestore.googleapis.com
- [ ] Firebase connects without errors
- [ ] Flutter cache cleared
- [ ] Device/emulator restarted
- [ ] App reinstalled fresh
- [ ] Functions region matches
- [ ] Simple function call works
- [ ] Functions redeployed clean

**Only proceed to Razorpay testing after ALL checks pass.**

---

## 📊 DIAGNOSTIC COMMANDS

### Check Network

```bash
# Test DNS
nslookup firestore.googleapis.com
nslookup YOUR_PROJECT.cloudfunctions.net

# Test connectivity
ping google.com
ping firestore.googleapis.com

# Flush DNS (Windows)
ipconfig /flushdns

# Flush DNS (Mac/Linux)
sudo dscacheutil -flushcache
```

### Check Flutter

```bash
# Flutter doctor
flutter doctor -v

# Check devices
flutter devices

# Check pub cache
flutter pub cache repair
```

### Check Firebase

```bash
# Check project
firebase projects:list

# Check functions
firebase functions:list

# Check config
firebase functions:config:get

# Check logs
firebase functions:log
```

---

## 🎯 STEP-BY-STEP EXECUTION

### Phase 1: Network (5 minutes)

```bash
# 1. Turn off VPN
# 2. Test connectivity
ping google.com
ping firestore.googleapis.com

# 3. If fails, switch network
# 4. Test again
```

### Phase 2: Flutter Clean (3 minutes)

```bash
cd apps/technician_app
flutter clean
flutter pub get
```

### Phase 3: Device Reset (2 minutes)

```bash
# Uninstall app
# Restart device
# Reinstall app
```

### Phase 4: Functions Redeploy (5 minutes)

```bash
cd functions
rm -rf node_modules package-lock.json
npm install
npm run build
cd ..
firebase deploy --only functions
```

### Phase 5: Test (2 minutes)

```dart
// Test simple function
final result = await FirebaseFunctions.instance
    .httpsCallable('testRazorpayConnection')
    .call();
```

**Total Time: ~20 minutes**

---

## 🚨 CRITICAL RULES

1. **DO NOT debug SDK until network is stable**
2. **DO NOT skip network checks**
3. **DO NOT proceed if Firebase doesn't connect**
4. **DO NOT test Razorpay with VPN on**
5. **DO NOT use cached dependencies**

---

## ✅ SUCCESS CRITERIA

Your environment is ready when:

1. ✅ `ping firestore.googleapis.com` works
2. ✅ Firebase Firestore loads data
3. ✅ Simple function call succeeds
4. ✅ No DNS errors in logs
5. ✅ No timeout errors
6. ✅ No "client offline" errors

**Only then proceed to test Razorpay SDK.**

---

**Fix Type:** Environment + Network + Cache  
**Not a Code Issue:** Confirmed  
**Action Required:** Follow steps above
