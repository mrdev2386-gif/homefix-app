# HomeFix System Test Suite

Production-ready automated testing infrastructure for HomeFix platform.

## Overview

This test suite provides comprehensive verification of:
- Firebase connectivity and configuration
- Firestore data integrity and operations
- Authentication flows and user management
- Booking system lifecycle
- Service creation and moderation
- Security rules enforcement
- Cloud Functions execution

## Prerequisites

- Node.js 20+
- Firebase Admin SDK credentials (`serviceAccountKey.json`)
- Active Firebase project
- TypeScript 5.4+

## Setup

### 1. Install Dependencies

```bash
cd system_test
npm install
```

### 2. Configure Firebase Credentials

Place your `serviceAccountKey.json` in the `scripts/` directory:

```bash
cp /path/to/serviceAccountKey.json ../scripts/
```

### 3. Build TypeScript

```bash
npm run build
```

## Running Tests

### Run All Tests

```bash
npm run test:all
```

### Run Individual Test Suites

```bash
# Firebase Connection Tests
npm run test:firebase

# Firestore Integrity Tests
npm run test:firestore

# Authentication Flow Tests
npm run test:auth

# Cloud Functions Tests
npm run test:functions

# Booking System Tests
npm run test:booking

# Service Creation Tests
npm run test:services

# Security Rules Tests
npm run test:security
```

## Test Modules

### 1. Firebase Connection Test (`firebase_connection_test.ts`)

Verifies Firebase Admin SDK initialization and connectivity:
- ✅ Admin SDK initialization
- ✅ Firestore connection
- ✅ Firebase Auth connection
- ✅ Firebase Storage connection
- ✅ Collections metadata

**Run:** `npm run test:firebase`

### 2. Firestore Integrity Test (`firestore_integrity_test.ts`)

Validates Firestore data structure and CRUD operations:
- ✅ Collections existence (services, categories, bookings, technicians, users)
- ✅ Write operations
- ✅ Read operations
- ✅ Update operations
- ✅ Delete operations
- ✅ Query operations
- ✅ Transaction support
- ✅ Batch write operations

**Run:** `npm run test:firestore`

### 3. Authentication Flow Test (`auth_flow_test.ts`)

Tests Firebase Auth user management:
- ✅ User creation
- ✅ User retrieval by UID
- ✅ User retrieval by email
- ✅ Custom claims management
- ✅ Technician profile creation
- ✅ Custom token generation
- ✅ User disable/enable
- ✅ User deletion

**Run:** `npm run test:auth`

### 4. Cloud Functions Test (`cloud_functions_test.ts`)

Verifies Cloud Functions deployment and execution:
- ✅ Functions deployment status
- ✅ Callable function execution
- ✅ Error handling
- ✅ Function configuration (region, timeout, memory)

**Run:** `npm run test:functions`

### 5. Booking System Test (`booking_system_test.ts`)

Tests complete booking lifecycle:
- ✅ Booking creation
- ✅ Booking verification
- ✅ Customer booking queries
- ✅ Pending booking queries
- ✅ Booking messages (subcollections)
- ✅ Status transitions
- ✅ Data cleanup

**Run:** `npm run test:booking`

### 6. Service Creation Test (`service_creation_test.ts`)

Validates technician service listing workflow:
- ✅ Service creation
- ✅ Service verification
- ✅ Technician service queries
- ✅ Pending service queries (admin)
- ✅ Location-based queries
- ✅ Category-based queries
- ✅ Batch service creation
- ✅ Service approval simulation

**Run:** `npm run test:services`

### 7. Security Rules Test (`security_rules_test.ts`)

Verifies Firestore security rules enforcement:
- ✅ Admin collection protection
- ✅ Technician protected fields
- ✅ Booking protected fields
- ✅ Service moderation fields
- ✅ Wallet transaction read-only
- ✅ Review immutability
- ✅ Coupon read-only
- ✅ Collection existence verification

**Run:** `npm run test:security`

## Test Output

Each test produces detailed output:

```
📋 Testing: Firebase Connection
✅ PASS: Firebase Admin SDK Initialization (245ms)
✅ PASS: Firestore Connection (156ms)
✅ PASS: Firebase Auth Connection (189ms)

📊 TEST SUMMARY
============================================================
Total Tests: 5
✅ Passed: 5
❌ Failed: 0
⏭️  Skipped: 0
⏱️  Total Duration: 590ms
============================================================
```

## Test Data Management

All tests use temporary test data with automatic cleanup:

- Test users are created with unique email addresses
- Test documents are created in temporary collections
- All test data is deleted after test completion
- No production data is modified

## Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

## Troubleshooting

### serviceAccountKey.json Not Found

```bash
# Ensure the file exists in scripts/ directory
ls ../scripts/serviceAccountKey.json

# If missing, download from Firebase Console:
# Project Settings → Service Accounts → Generate New Private Key
```

### Firebase Connection Timeout

```bash
# Check Firebase project is active
firebase projects:list

# Verify credentials are valid
npm run test:firebase
```

### Firestore Rules Blocking Tests

```bash
# Ensure Firestore rules allow test operations
# Check firestore.rules for proper allow/deny rules

# Temporarily relax rules for testing (not recommended for production)
firebase deploy --only firestore:rules
```

### Cloud Functions Not Found

```bash
# Ensure functions are deployed
firebase deploy --only functions

# Check function status
firebase functions:list
```

## Performance Benchmarks

Expected test execution times:

| Test Suite | Duration | Tests |
|-----------|----------|-------|
| Firebase Connection | ~600ms | 5 |
| Firestore Integrity | ~2000ms | 12 |
| Authentication Flow | ~3000ms | 12 |
| Cloud Functions | ~1500ms | 7 |
| Booking System | ~2500ms | 7 |
| Service Creation | ~2000ms | 8 |
| Security Rules | ~1000ms | 12 |
| **Total** | **~12.6s** | **64** |

## CI/CD Integration

### GitHub Actions Example

```yaml
name: System Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '20'
      - run: cd system_test && npm install
      - run: cd system_test && npm run build
      - run: cd system_test && npm run test:all
        env:
          FIREBASE_SERVICE_ACCOUNT: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
```

## Best Practices

1. **Run Before Deployment**
   ```bash
   npm run test:all
   ```

2. **Run Specific Tests During Development**
   ```bash
   npm run test:firestore
   npm run test:booking
   ```

3. **Monitor Test Performance**
   - Track execution times
   - Alert on performance degradation
   - Optimize slow tests

4. **Keep Tests Isolated**
   - Each test creates and cleans up its own data
   - No dependencies between tests
   - Can run in any order

5. **Review Test Logs**
   - Check for warnings
   - Monitor error patterns
   - Track failed tests

## Maintenance

### Adding New Tests

1. Create new test file in `src/`
2. Import `TestLogger` and `FirebaseTestHelper`
3. Implement test logic
4. Add npm script in `package.json`
5. Update this README

### Updating Existing Tests

1. Modify test file
2. Run `npm run build`
3. Test changes: `npm run test:specific`
4. Commit changes

## Support

For issues or questions:
1. Check test output for error messages
2. Review Firestore rules
3. Verify Firebase credentials
4. Check Cloud Functions deployment status

## License

Proprietary - HomeFix © 2026
