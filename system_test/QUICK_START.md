# Quick Start Guide - HomeFix System Tests

## 5-Minute Setup

### Step 1: Navigate to Test Directory
```bash
cd c:\Users\yash\projects\homefix\system_test
```

### Step 2: Install Dependencies
```bash
npm install
```

### Step 3: Verify Firebase Credentials
```bash
# Check if serviceAccountKey.json exists
dir ..\scripts\serviceAccountKey.json

# If not found, download from Firebase Console:
# 1. Go to Firebase Console
# 2. Project Settings → Service Accounts
# 3. Generate New Private Key
# 4. Save as ../scripts/serviceAccountKey.json
```

### Step 4: Build Tests
```bash
npm run build
```

### Step 5: Run All Tests
```bash
npm run test:all
```

## Individual Test Commands

```bash
# Test Firebase connectivity
npm run test:firebase

# Test Firestore operations
npm run test:firestore

# Test authentication
npm run test:auth

# Test Cloud Functions
npm run test:functions

# Test booking system
npm run test:booking

# Test service creation
npm run test:services

# Test security rules
npm run test:security
```

## Expected Output

```
🚀 HOMEFIX PRODUCTION SYSTEM TEST SUITE
============================================================
Starting at: 2024-01-15T10:30:00.000Z
Total test modules: 6
============================================================

🔥 FIREBASE CONNECTION TESTS
============================================================

📋 Testing: Firebase Admin SDK Initialization
✅ PASS: Firebase Admin SDK Initialization (245ms)

📋 Testing: Firestore Connection
✅ PASS: Firestore Connection (156ms)

...

📊 TEST SUMMARY
============================================================
Total Tests: 64
✅ Passed: 64
❌ Failed: 0
⏭️  Skipped: 0
⏱️  Total Duration: 12600ms
============================================================

✅ ALL TESTS PASSED
```

## Troubleshooting

### Issue: "serviceAccountKey.json not found"

**Solution:**
```bash
# Download from Firebase Console
# Project Settings → Service Accounts → Generate New Private Key
# Save to: ../scripts/serviceAccountKey.json
```

### Issue: "PERMISSION_DENIED" errors

**Solution:**
```bash
# Ensure Firestore rules allow operations
# Check firestore.rules for proper allow/deny rules
firebase deploy --only firestore:rules
```

### Issue: "Functions not found"

**Solution:**
```bash
# Deploy Cloud Functions
firebase deploy --only functions

# Verify deployment
firebase functions:list
```

### Issue: Tests timeout

**Solution:**
```bash
# Increase timeout in test files
# Default: 30 seconds
# Modify in individual test files if needed
```

## Test Coverage

| Component | Tests | Status |
|-----------|-------|--------|
| Firebase Connection | 5 | ✅ |
| Firestore CRUD | 12 | ✅ |
| Authentication | 12 | ✅ |
| Cloud Functions | 7 | ✅ |
| Booking System | 7 | ✅ |
| Service Creation | 8 | ✅ |
| Security Rules | 12 | ✅ |
| **Total** | **64** | **✅** |

## Next Steps

1. **Run tests regularly** - Before each deployment
2. **Monitor performance** - Track execution times
3. **Review logs** - Check for warnings or errors
4. **Update tests** - Add new tests for new features
5. **Integrate with CI/CD** - Automate test execution

## Support

For detailed information, see [README.md](./README.md)

## Quick Reference

```bash
# Clean build
npm run clean && npm run build

# Run all tests
npm run test:all

# Run specific test
npm run test:firestore

# View test logs
npm run test:all 2>&1 | tee test-results.log
```

---

**Last Updated:** 2024-01-15
**Version:** 1.0.0
