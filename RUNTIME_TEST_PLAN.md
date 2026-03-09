# 🧪 RUNTIME TEST PLAN
## HomeFix Technician Approval System Verification

**Test Type:** Production Security Verification  
**Status:** READY FOR EXECUTION  
**Security Fixes:** All implemented and ready for testing

---

## 🎯 TEST SCENARIO 1: Approved Technician

### Prerequisites
```json
// Firestore: technicians/{technicianId}
{
  "status": "approved",
  "stepsCompleted": {
    "personalDetails": true,
    "serviceCategories": true,
    "portfolio": true,
    "verification": true
  },
  "name": "Test Technician",
  "email": "test@example.com",
  "district": "Test District",
  "skills": ["cleaning"],
  "aadhaarFrontUrl": "https://example.com/front.jpg",
  "profilePhotoUrl": "https://example.com/profile.jpg"
}
```

### Test Steps

#### 1. App Launch & Login
```bash
# Expected Behavior:
✅ Dashboard loads immediately
❌ NO "Waiting for Admin Approval" screen
✅ Profile completion shows exactly 100%
```

#### 2. Debug Log Verification
```dart
// Expected Console Output:
[TECH STATUS] approved
[PROFILE COMPLETION] 100
[SERVICE ALLOWED] true
```

#### 3. Service Creation Test
```dart
// Test Data:
Category: "cleaning"
Service: "Bathroom Cleaning"
Price: 500
Image: Upload test image
Description: "Professional bathroom cleaning"

// Expected Result:
✅ Service creation form accessible
✅ Submit button enabled
✅ Service created successfully
```

#### 4. Firestore Verification
```bash
# Check document exists:
technician_services/{serviceId}
{
  "name": "Bathroom Cleaning",
  "price": 500,
  "category": "cleaning",
  "technicianId": "{technicianId}",
  "district": "Test District",
  "isActive": true,
  "status": "active"
}
```

### Expected Results ✅
- Dashboard accessible immediately
- Profile completion = 100%
- Service creation successful
- Backend validation passes
- Document created in correct collection

---

## 🚫 TEST SCENARIO 2: Non-Approved Technician

### Prerequisites
```json
// Firestore: technicians/{technicianId}
{
  "status": "pending",
  "stepsCompleted": {
    "personalDetails": true,
    "serviceCategories": true,
    "portfolio": true,
    "verification": true
  }
}
```

### Test Steps

#### 1. App Launch & Login
```bash
# Expected Behavior:
❌ Dashboard blocked
✅ "Waiting for Admin Approval" screen appears
✅ Profile completion shows 100%
✅ Status message: "Profile under admin review"
```

#### 2. Manual Navigation Test
```dart
// Try to navigate to services screen manually
// Expected Result:
❌ Access blocked
✅ Redirected to waiting screen
```

#### 3. API Bypass Test
```typescript
// Try calling Cloud Function directly:
const result = await addTechnicianService({
  name: "Test Service",
  price: 100,
  category: "cleaning",
  imageUrl: "test.jpg"
});

// Expected Result:
❌ HttpsError("permission-denied")
✅ Error message: "Your profile is under admin review"
```

#### 4. Debug Log Verification
```dart
// Expected Console Output:
[TECH STATUS] pending
[PROFILE COMPLETION] 100
[SERVICE ALLOWED] false
```

### Expected Results ✅
- Dashboard access blocked
- Waiting screen displayed
- Service creation blocked (frontend)
- Backend validation rejects requests
- No bypass possible

---

## 🔄 TEST SCENARIO 3: App Restart Persistence

### Test Steps

#### 1. Initial State (Approved Technician)
```bash
✅ Login with approved technician
✅ Verify dashboard access
✅ Verify service creation works
```

#### 2. App Restart
```bash
✅ Close app completely (kill process)
✅ Clear app from recent apps
✅ Reopen app
```

#### 3. Post-Restart Verification
```bash
# Expected Behavior:
✅ Dashboard still opens correctly
✅ Profile completion remains 100%
✅ Service creation still works
✅ No cached state issues
✅ Fresh data loaded from Firestore
```

### Expected Results ✅
- Persistent correct behavior
- No state corruption
- Fresh server-side validation
- Security controls remain active

---

## 🔍 VERIFICATION CHECKLIST

### Frontend Security
- [ ] Single approval condition: `status == "approved"`
- [ ] Dynamic profile completion calculation
- [ ] Dashboard access guard working
- [ ] Service creation validation active
- [ ] No dual approval logic present

### Backend Security
- [ ] Cloud Functions validate approval
- [ ] Single source of truth enforced
- [ ] Profile completion calculated dynamically
- [ ] Authentication required
- [ ] Authorization enforced

### Debug Logging
- [ ] `[TECH STATUS]` logs show correct status
- [ ] `[PROFILE COMPLETION]` shows 100% when complete
- [ ] `[SERVICE ALLOWED]` matches approval status
- [ ] Backend logs approval validation

### Error Handling
- [ ] Non-approved technicians blocked gracefully
- [ ] Clear error messages displayed
- [ ] No bypass routes available
- [ ] Consistent behavior across restarts

---

## 🚨 CRITICAL SECURITY TESTS

### Test 1: Approval Bypass Attempt
```bash
# Manually set profileApproved = true in Firestore
# Expected: Should have NO EFFECT (field ignored)
# Status: "pending" should still block access
```

### Test 2: Profile Completion Manipulation
```bash
# Manually set profileCompletion = 100 in Firestore
# Expected: Should be IGNORED (calculated dynamically)
# Real completion should be used
```

### Test 3: Direct API Access
```bash
# Call service creation API with non-approved account
# Expected: HttpsError("permission-denied")
# No service should be created
```

---

## 📊 EXPECTED TEST RESULTS

### ✅ PASS CRITERIA

**Approved Technician:**
- ✅ Dashboard accessible immediately
- ✅ Profile completion = 100%
- ✅ Service creation successful
- ✅ Firestore document created correctly
- ✅ Debug logs show approved status

**Non-Approved Technician:**
- ✅ Dashboard blocked
- ✅ Waiting screen displayed
- ✅ Service creation blocked
- ✅ Backend rejects requests
- ✅ Debug logs show pending status

**App Restart:**
- ✅ Behavior consistent after restart
- ✅ No cached state issues
- ✅ Fresh validation from server

### ❌ FAIL CRITERIA

**Any of these indicate security vulnerability:**
- ❌ Non-approved technician accesses dashboard
- ❌ Service creation succeeds for pending status
- ❌ Dual approval logic still active
- ❌ Stored profile completion trusted
- ❌ Backend validation bypassed

---

## 🔧 TEST EXECUTION COMMANDS

### Firebase Console Verification
```bash
# Check technician document:
firebase firestore:get technicians/{technicianId}

# Check created services:
firebase firestore:get technician_services/{serviceId}

# Monitor logs:
firebase functions:log
```

### App Testing Commands
```bash
# Build and run technician app:
cd apps/technician_app
flutter clean
flutter pub get
flutter run

# Monitor debug output:
flutter logs
```

---

## 📞 SUPPORT

**If any test fails:**
1. Document exact failure behavior
2. Capture debug logs
3. Check Firestore document state
4. Contact: 9508322397

**Test Status:** READY FOR EXECUTION  
**Security Level:** MAXIMUM  
**Approval Required:** Production deployment approved after all tests pass