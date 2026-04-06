# TECHNICIAN ONBOARDING - RUNTIME VERIFICATION TEST SCRIPT

**Purpose**: Real runtime testing of technician onboarding system  
**Type**: Manual execution (can be automated with Flutter integration tests)  
**Tester**: QA Team / Developer  
**Environment**: Development / Staging

---

## PRE-TEST SETUP

### Requirements
- [ ] Flutter development environment set up
- [ ] Firebase project configured
- [ ] Admin panel accessible
- [ ] Test phone number available (for OTP)
- [ ] Firebase Emulator Suite running (optional, recommended)

### Test Data Preparation
```
Test Technician:
- Phone: +91 9876543210 (or your test number)
- Name: Test Technician Alpha
- State: Maharashtra
- District: Mumbai
- Aadhaar: 123456789012 (test number)
- Experience: 5 years
- Skills: Installation, Repair
- Category: Plumbing
```

---

## TEST 1: TECHNICIAN SIGNUP & ONBOARDING

### Test 1.1: Phone OTP Verification
**Steps**:
1. Open Technician App
2. Enter phone number: `+91 9876543210`
3. Request OTP
4. Enter OTP code
5. Verify login successful

**Expected Result**:
- ✅ OTP received
- ✅ Login successful
- ✅ Redirected to onboarding screen

**Firestore Verification**:
```bash
# Check if technician document created
firebase firestore:get technicians/{uid}

# Expected fields:
{
  "uid": "{uid}",
  "phone": "+919876543210",
  "role": "technician",
  "status": "pending",
  "isApproved": false,
  "onboardingStep": "basicDetails",
  "createdAt": {timestamp}
}
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 1.2: Step 1 - Basic Identity
**Steps**:
1. Enter full name: "Test Technician Alpha"
2. Select state: "Maharashtra"
3. Select district: "Mumbai"
4. Take profile photo (use camera or select from gallery)
5. Select service category: "Plumbing"
6. Select gender: "Male" (optional)
7. Select DOB: "01/01/1990" (optional)
8. Tap "Continue"

**Expected Result**:
- ✅ All fields accept input
- ✅ Photo upload shows progress
- ✅ Photo upload completes successfully
- ✅ Continue button enabled after required fields filled
- ✅ Navigation to Step 2

**Firestore Verification**:
```bash
firebase firestore:get technicians/{uid}

# Expected updates:
{
  "name": "Test Technician Alpha",
  "fullName": "Test Technician Alpha",
  "state": "Maharashtra",
  "district": "Mumbai",
  "profilePhotoUrl": "https://firebasestorage.googleapis.com/...",
  "primaryCategoryId": ["plumbing_category_id"],
  "gender": "Male",
  "dateOfBirth": "1990-01-01T00:00:00.000Z",
  "onboardingStep": "professional",
  "stepsCompleted": {
    "personalDetails": true
  },
  "updatedAt": {timestamp}
}
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 1.3: Step 2 - Professional Details
**Steps**:
1. Select experience years: "5 years"
2. Select skills: "Installation", "Repair"
3. Select service areas: "Residential", "Commercial"
4. Select working days: Mon, Tue, Wed, Thu, Fri
5. Select working hours: 9:00 AM - 6:00 PM
6. Toggle "Own tools": ON
7. Enter bio: "Experienced plumber with 5 years of expertise" (optional)
8. Tap "Continue"

**Expected Result**:
- ✅ All selections saved
- ✅ Continue button enabled
- ✅ Navigation to Step 3

**Firestore Verification**:
```bash
firebase firestore:get technicians/{uid}

# Expected updates:
{
  "experienceYears": 5,
  "skills": ["Installation", "Repair"],
  "serviceAreas": ["Residential", "Commercial"],
  "workingDays": [true, true, true, true, true, false, false],
  "startTime": "09:00",
  "endTime": "18:00",
  "hasOwnTools": true,
  "bio": "Experienced plumber with 5 years of expertise",
  "onboardingStep": "kyc",
  "stepsCompleted": {
    "personalDetails": true,
    "serviceCategories": true
  }
}
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 1.4: Step 3 - KYC Verification
**Steps**:
1. Enter Aadhaar number: "1234 5678 9012"
2. Tap "Capture Aadhaar Front"
3. Take photo of Aadhaar front
4. Wait for upload to complete
5. Tap "Capture Aadhaar Back"
6. Take photo of Aadhaar back
7. Wait for upload to complete
8. Tap "Continue"

**Expected Result**:
- ✅ Aadhaar number formatted as "XXXX XXXX XXXX"
- ✅ Aadhaar validation passes (12 digits)
- ✅ Front photo upload successful
- ✅ Back photo upload successful
- ✅ Continue button enabled
- ✅ Navigation to Step 4

**Firestore Verification**:
```bash
firebase firestore:get technicians/{uid}

# Expected updates (CRITICAL: Check encryption):
{
  "aadhaarNumber": "{encrypted_value}", // MUST BE ENCRYPTED
  "aadhaarMasked": "XXXX-XXXX-9012",
  "aadhaarFrontUrl": "https://firebasestorage.googleapis.com/...",
  "aadhaarBackUrl": "https://firebasestorage.googleapis.com/...",
  "onboardingStep": "portfolio",
  "stepsCompleted": {
    "personalDetails": true,
    "serviceCategories": true,
    "verification": true
  }
}
```

**Security Check**:
- [ ] Verify Aadhaar is NOT stored in plain text
- [ ] Verify only masked Aadhaar visible in UI

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 1.5: Step 4 - Work Portfolio (OPTIONAL)
**Steps**:
1. Enter experience description: "I have worked on residential and commercial plumbing projects for 5 years"
2. Select tools: "Wrench", "Pipe Cutter"
3. Select work preference: "Both"
4. Upload portfolio photos (optional)
5. Tap "Continue"

**Expected Result**:
- ✅ All fields accept input
- ✅ Continue button enabled
- ✅ Navigation to Success screen

**Firestore Verification**:
```bash
firebase firestore:get technicians/{uid}

# Expected updates:
{
  "experienceDescription": "I have worked on residential and commercial plumbing projects for 5 years",
  "tools": ["Wrench", "Pipe Cutter"],
  "workPreference": "Both",
  "portfolioPhotos": ["url1", "url2"],
  "onboardingStep": "submitted",
  "stepsCompleted": {
    "personalDetails": true,
    "serviceCategories": true,
    "portfolio": true,
    "verification": true
  }
}
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

## TEST 2: SUBMISSION FLOW

### Test 2.1: Submit Onboarding
**Steps**:
1. Review all entered data on success screen
2. Tap "Submit for Verification"
3. Wait for submission to complete

**Expected Result**:
- ✅ Loading indicator shown
- ✅ Submission successful message
- ✅ Navigation to success/pending screen

**Firestore Verification**:
```bash
firebase firestore:get technicians/{uid}

# Expected final state:
{
  "isKycComplete": true,
  "onboardingCompleted": true,
  "onboardingStep": "submitted",
  "status": "pending",
  "kycStatus": "pending",
  "submittedAt": {timestamp},
  "profileCompletion": 100
}
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 2.2: Prevent Duplicate Submission
**Steps**:
1. After successful submission, try to submit again
2. Close app and reopen
3. Try to edit profile
4. Try to submit again

**Expected Result**:
- ✅ Cannot submit twice
- ✅ Profile locked after submission
- ✅ Shows "Pending Review" status
- ✅ No duplicate documents in Firestore

**Firestore Verification**:
```bash
# Check for duplicate submissions
firebase firestore:query technicians --where uid == {uid}

# Should return ONLY ONE document
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

## TEST 3: ADMIN PANEL VERIFICATION

### Test 3.1: View Pending Technicians
**Steps**:
1. Open admin panel in browser
2. Login as admin
3. Navigate to "Technicians" section
4. Filter by status: "Pending"

**Expected Result**:
- ✅ Admin panel loads successfully
- ✅ Technicians list visible
- ✅ Test technician appears in pending list
- ✅ All data visible (name, phone, category, etc.)

**Data Verification**:
- [ ] Name: "Test Technician Alpha"
- [ ] Phone: "+91 9876543210"
- [ ] Status: "Pending"
- [ ] Category: "Plumbing"
- [ ] Experience: "5 years"

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 3.2: View Technician Details
**Steps**:
1. Click on test technician in list
2. View full profile details
3. Check all uploaded documents

**Expected Result**:
- ✅ Profile details page opens
- ✅ All fields populated correctly
- ✅ Profile photo visible
- ✅ Aadhaar photos visible (front & back)
- ✅ Aadhaar number masked (XXXX-XXXX-9012)

**Data Verification**:
- [ ] All personal details correct
- [ ] All professional details correct
- [ ] All documents uploaded
- [ ] No missing fields

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

## TEST 4: APPROVAL FLOW

### Test 4.1: Approve Technician
**Steps**:
1. In admin panel, open test technician profile
2. Click "Approve" button
3. Confirm approval
4. Wait for success message

**Expected Result**:
- ✅ Approval confirmation dialog shown
- ✅ Approval successful message
- ✅ Status changes to "Approved"
- ✅ Technician removed from pending list

**Firestore Verification**:
```bash
firebase firestore:get technicians/{uid}

# Expected updates:
{
  "isApproved": true,
  "adminApproved": true,
  "isVerified": true,
  "status": "approved",
  "kycStatus": "approved",
  "isActive": true,
  "approvedAt": {timestamp},
  "approvedBy": "{admin_uid}"
}
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 4.2: Verify Notification Sent
**Steps**:
1. Check technician app for push notification
2. Check notification content

**Expected Result**:
- ✅ Push notification received
- ✅ Notification title: "Welcome to HomeFix!"
- ✅ Notification body: "Your profile has been approved..."

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

## TEST 5: ACTIVATION & GO ONLINE

### Test 5.1: Login After Approval
**Steps**:
1. Open technician app
2. Login with test account
3. Check dashboard

**Expected Result**:
- ✅ Login successful
- ✅ Dashboard loads
- ✅ "Go Online" toggle visible
- ✅ No "Pending Approval" message

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 5.2: Go Online
**Steps**:
1. Tap "Go Online" toggle
2. Wait for status update

**Expected Result**:
- ✅ Toggle switches to ON
- ✅ Status changes to "Online"
- ✅ Green indicator shown

**Firestore Verification**:
```bash
firebase firestore:get technicians/{uid}

# Expected update:
{
  "isOnline": true,
  "lastOnlineAt": null
}
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 5.3: Receive Job Requests
**Steps**:
1. Create test booking from customer app
2. Check if technician receives notification
3. Check if booking appears in technician app

**Expected Result**:
- ✅ Booking notification received
- ✅ Booking visible in "Available Jobs" section
- ✅ Can accept/reject booking

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

## TEST 6: EDGE CASES

### Test 6.1: Submit Twice (Duplicate Prevention)
**Steps**:
1. Complete onboarding
2. Submit for verification
3. Close app
4. Reopen app
5. Try to submit again

**Expected Result**:
- ✅ Cannot submit twice
- ✅ Shows "Already Submitted" or "Pending Review"
- ✅ No duplicate Firestore writes

**Firestore Verification**:
```bash
# Check submission count
firebase firestore:query technicians --where uid == {uid}

# Should return ONLY ONE document
# submittedAt should have ONLY ONE timestamp
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 6.2: Close App Mid-Onboarding
**Steps**:
1. Start new onboarding
2. Complete Step 1
3. Start Step 2
4. Fill half the fields
5. Force close app
6. Reopen app

**Expected Result**:
- ✅ App resumes from Step 2
- ✅ Step 1 data preserved
- ✅ Step 2 partial data preserved (if saved)
- ✅ No data loss

**Firestore Verification**:
```bash
firebase firestore:get technicians/{uid}

# Verify Step 1 data still present
# Verify onboardingStep = "professional" or "basic"
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 6.3: Edit After Submission
**Steps**:
1. Complete onboarding and submit
2. Try to go back to edit profile
3. Try to change name
4. Try to re-upload documents

**Expected Result**:
- ✅ Cannot edit after submission
- ✅ Shows "Profile Locked" or "Under Review"
- ✅ Edit buttons disabled

**Firestore Verification**:
```bash
# Verify no updates after submission
firebase firestore:get technicians/{uid}

# updatedAt should NOT change after submittedAt
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 6.4: Network Failure During Upload
**Steps**:
1. Start Step 3 (KYC)
2. Enter Aadhaar number
3. Start uploading Aadhaar front photo
4. Turn off WiFi/mobile data mid-upload
5. Wait for error
6. Turn on network
7. Retry upload

**Expected Result**:
- ✅ Upload fails with error message
- ✅ Error message: "Network error. Please try again."
- ✅ Retry button shown
- ✅ Retry successful after network restored

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 6.5: Invalid Aadhaar Number
**Steps**:
1. Go to Step 3 (KYC)
2. Enter invalid Aadhaar: "123" (too short)
3. Try to continue
4. Enter invalid Aadhaar: "abcd5678901" (non-numeric)
5. Try to continue

**Expected Result**:
- ✅ Validation error shown: "Aadhaar must be exactly 12 digits"
- ✅ Continue button disabled
- ✅ Cannot proceed until valid Aadhaar entered

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 6.6: Admin Approves While User Edits
**Steps**:
1. Complete onboarding but don't submit
2. Keep app open on Step 2
3. Admin manually approves technician in Firestore
4. User tries to continue to Step 3

**Expected Result**:
- ⚠️ POTENTIAL RACE CONDITION
- Expected: Profile locked or sync conflict detected
- Actual: (Test and document)

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

## TEST 7: REJECTION FLOW

### Test 7.1: Admin Rejects Technician
**Steps**:
1. Create new test technician
2. Complete onboarding and submit
3. Admin opens profile
4. Admin clicks "Reject"
5. Admin enters reason: "Documents unclear"
6. Confirm rejection

**Expected Result**:
- ✅ Rejection successful
- ✅ Status changes to "Suspended"
- ✅ Rejection reason saved

**Firestore Verification**:
```bash
firebase firestore:get technicians/{uid}

# Expected updates:
{
  "status": "suspended",
  "isApproved": false,
  "adminApproved": false,
  "isActive": false,
  "kycStatus": "rejected",
  "rejectionReason": "Documents unclear",
  "rejectedAt": {timestamp},
  "rejectedBy": "{admin_uid}"
}
```

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

### Test 7.2: Rejected Technician Cannot Go Online
**Steps**:
1. Login as rejected technician
2. Try to toggle "Go Online"

**Expected Result**:
- ✅ Cannot go online
- ✅ Error message: "Your account is suspended"
- ✅ Shows rejection reason

**Result**: [ ] PASS / [ ] FAIL  
**Issues Found**: _______________

---

## FINAL TEST SUMMARY

### Overall Results

| Test | Status | Issues |
|------|--------|--------|
| Test 1.1: Phone OTP | [ ] PASS / [ ] FAIL | |
| Test 1.2: Step 1 Basic | [ ] PASS / [ ] FAIL | |
| Test 1.3: Step 2 Professional | [ ] PASS / [ ] FAIL | |
| Test 1.4: Step 3 KYC | [ ] PASS / [ ] FAIL | |
| Test 1.5: Step 4 Portfolio | [ ] PASS / [ ] FAIL | |
| Test 2.1: Submission | [ ] PASS / [ ] FAIL | |
| Test 2.2: Duplicate Prevention | [ ] PASS / [ ] FAIL | |
| Test 3.1: Admin View Pending | [ ] PASS / [ ] FAIL | |
| Test 3.2: Admin View Details | [ ] PASS / [ ] FAIL | |
| Test 4.1: Admin Approval | [ ] PASS / [ ] FAIL | |
| Test 4.2: Notification | [ ] PASS / [ ] FAIL | |
| Test 5.1: Login After Approval | [ ] PASS / [ ] FAIL | |
| Test 5.2: Go Online | [ ] PASS / [ ] FAIL | |
| Test 5.3: Receive Jobs | [ ] PASS / [ ] FAIL | |
| Test 6.1: Duplicate Submit | [ ] PASS / [ ] FAIL | |
| Test 6.2: Close Mid-Onboarding | [ ] PASS / [ ] FAIL | |
| Test 6.3: Edit After Submit | [ ] PASS / [ ] FAIL | |
| Test 6.4: Network Failure | [ ] PASS / [ ] FAIL | |
| Test 6.5: Invalid Aadhaar | [ ] PASS / [ ] FAIL | |
| Test 6.6: Race Condition | [ ] PASS / [ ] FAIL | |
| Test 7.1: Rejection | [ ] PASS / [ ] FAIL | |
| Test 7.2: Rejected Cannot Online | [ ] PASS / [ ] FAIL | |

### Critical Issues Found
1. _______________
2. _______________
3. _______________

### Recommendations
1. _______________
2. _______________
3. _______________

---

**Test Completed By**: _______________  
**Date**: _______________  
**Environment**: _______________  
**Overall Status**: [ ] PASS / [ ] FAIL
