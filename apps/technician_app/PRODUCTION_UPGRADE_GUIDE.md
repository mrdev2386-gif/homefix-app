# HomeFix Technician Onboarding - Production Upgrade Guide

**Status:** IMPLEMENTATION READY  
**Priority:** CRITICAL  
**Timeline:** 2-3 days for full implementation

---

## 📋 IMPLEMENTATION CHECKLIST

### Phase 1: Model & Data Layer (Day 1)

- [ ] Replace `technician.dart` with enhanced model from `technician_enhanced.dart`
  - Adds: languagePreferences, referralCodeUsed, panNumber, panImageUrl, accountType, payoutPreference, maxDailyJobs, dynamicPricingAllowed, teamSize, maxTravelDistanceKm, completion flags, submissionTimestamp
  - Adds helper methods: isOnboardingFullyComplete, isPendingApproval

- [ ] Update `onboarding_service.dart` to add duplicate check handling
  ```dart
  // Add error handling for duplicate_technician error code
  if (e.code == 'duplicate_technician') {
    throw Exception('This Aadhaar/phone is already registered');
  }
  ```

- [ ] Update `technician_provider.dart` to track all completion flags
  ```dart
  bool _profileCompleted = false;
  bool _kycCompleted = false;
  bool _bankCompleted = false;
  bool _servicesCompleted = false;
  ```

### Phase 2: UI Layer - Enhanced Steps (Day 1-2)

- [ ] Replace Step 1 with `step1_basic_identity_enhanced.dart`
  - Adds: Language preferences multi-select, Referral code input, Phone display, Auto-capitalize name
  - Improves: Better UX with verified phone badge

- [ ] Replace Step 3 with `step3_kyc_verification_enhanced.dart`
  - Adds: PAN number collection, PAN image upload
  - Improves: Better security notice mentioning duplicate detection

- [ ] Replace Step 4 with `step4_bank_details_enhanced.dart`
  - Adds: Account confirmation validation, Account type selector, Payout preference selector
  - Improves: Masked account number display, Visibility toggle

- [ ] Replace Step 5 with `step5_service_setup_enhanced.dart`
  - Adds: Price validation (> 0), Service requirement validation, Max daily jobs, Dynamic pricing toggle
  - Improves: Better error messages, Required field indicators

### Phase 3: Routing & Access Control (Day 2)

- [ ] Create `limited_dashboard_enhanced.dart` for pending technicians
  - Shows: Profile, Support, Logout, Status card
  - Hides: Jobs, Earnings, Go-online toggle

- [ ] Update main routing logic in `main.dart`:
  ```dart
  if (technician.isPendingApproval) {
    return const LimitedDashboardScreen();
  } else if (technician.canAccessDashboard) {
    return const DashboardScreen();
  } else {
    return const TechnicianOnboardingFlowScreen();
  }
  ```

- [ ] Update `dashboard_screen.dart` to check `canAccessDashboard`
  ```dart
  if (!technician.canAccessDashboard) {
    return const LimitedDashboardScreen();
  }
  ```

### Phase 4: Cloud Functions (Day 2-3)

**CRITICAL:** Update Cloud Functions for duplicate protection and atomic submission

#### Function: `saveTechnicianDocuments`
```javascript
// Add duplicate check BEFORE saving
const existingAadhaar = await db.collection('technicians')
  .where('aadhaarHash', '==', aadhaarHash)
  .limit(1)
  .get();

if (!existingAadhaar.empty && existingAadhaar.docs[0].id !== uid) {
  throw new functions.https.HttpsError(
    'already-exists',
    'duplicate_technician: This Aadhaar is already registered'
  );
}

// Add phone duplicate check
const existingPhone = await db.collection('technicians')
  .where('phone', '==', phone)
  .limit(1)
  .get();

if (!existingPhone.empty && existingPhone.docs[0].id !== uid) {
  throw new functions.https.HttpsError(
    'already-exists',
    'duplicate_technician: This phone is already registered'
  );
}

// Generate Aadhaar hash (SHA-256)
const crypto = require('crypto');
const aadhaarHash = crypto
  .createHash('sha256')
  .update(aadhaarNumber)
  .digest('hex');

// Save with hash
await db.collection('technicians').doc(uid).update({
  aadhaarNumber: aadhaarNumber, // Store masked version
  aadhaarHash: aadhaarHash, // Store hash for duplicate check
  aadhaarFrontUrl: aadhaarFrontUrl,
  aadhaarBackUrl: aadhaarBackUrl,
  profilePhotoUrl: profilePhotoUrl,
  kycCompleted: true,
  status: 'kyc_pending',
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

#### Function: `submitTechnicianKyc`
```javascript
// Atomic submission - set ALL flags at once
const batch = db.batch();
const techRef = db.collection('technicians').doc(uid);

batch.update(techRef, {
  profileCompleted: true,
  kycCompleted: true,
  bankCompleted: true,
  servicesCompleted: true,
  status: 'pending_approval',
  onboardingStep: 'submitted',
  submissionTimestamp: admin.firestore.FieldValue.serverTimestamp(),
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
});

await batch.commit();
```

#### Function: `approveTechnicianKyc` (Admin only)
```javascript
// Verify admin role
if (!context.auth.token.admin) {
  throw new functions.https.HttpsError(
    'permission-denied',
    'Only admins can approve technicians'
  );
}

await db.collection('technicians').doc(uid).update({
  isApproved: true,
  adminApproved: true,
  status: 'approved',
  onboardingStep: 'approved',
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
});

// Send notification
await admin.messaging().sendToDevice(fcmToken, {
  notification: {
    title: 'Account Approved!',
    body: 'Your account has been approved. You can now start accepting jobs.',
  },
});
```

### Phase 5: Firestore Security Rules (Day 3)

Update `firestore.rules`:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /technicians/{uid} {
      // Client can only read own document
      allow read: if request.auth.uid == uid;
      
      // Client can only write specific fields
      allow write: if request.auth.uid == uid && 
        !request.resource.data.keys().hasAny([
          'isApproved',
          'adminApproved',
          'status',
          'aadhaarHash',
          'onboardingStep',
          'submissionTimestamp',
          'role',
          'rating',
          'walletBalance',
          'adminNotes'
        ]);
      
      // Admin can write any field
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

### Phase 6: Testing (Day 3)

- [ ] Test Step 1: Language selection, Referral code, Auto-capitalize
- [ ] Test Step 3: PAN validation, Duplicate Aadhaar detection
- [ ] Test Step 4: Account confirmation match, Payout preference
- [ ] Test Step 5: Price validation, Service requirement, Max daily jobs
- [ ] Test Submission: All flags set atomically
- [ ] Test Limited Dashboard: Pending technicians see limited UI
- [ ] Test Approval Flow: Technician gets notified and gains full access
- [ ] Test Duplicate Prevention: Reject duplicate Aadhaar/phone

---

## 🔄 MIGRATION PATH

### For Existing Technicians

1. **Backward Compatibility:** Old technicians without new fields will still work
2. **Gradual Migration:** New fields are optional, existing data preserved
3. **No Data Loss:** All existing technicians keep their status and data

### For New Technicians

1. **Full Flow:** Must complete all 6 steps with new validations
2. **Duplicate Check:** Aadhaar/phone checked before submission
3. **Atomic Submission:** All flags set together, no partial states

---

## 📊 FIELD MAPPING

### Step 1 → Firestore
```
fullName → name
district → district
gender → gender
dateOfBirth → dateOfBirth
languagePreferences → languagePreferences (NEW)
referralCode → referralCodeUsed (NEW)
profilePhotoUrl → profilePhotoUrl
```

### Step 3 → Firestore
```
aadhaarNumber → aadhaarNumber
aadhaarFrontUrl → aadhaarFrontUrl
aadhaarBackUrl → aadhaarBackUrl
selfieUrl → profilePhotoUrl
panNumber → panNumber (NEW)
panImageUrl → panImageUrl (NEW)
```

### Step 4 → Firestore
```
accountHolder → accountHolderName
accountNumber → bankAccountNumber
ifscCode → ifscCode
bankName → bankName
upiId → upiId
accountType → accountType (NEW)
payoutPreference → payoutPreference (NEW)
```

### Step 5 → Firestore
```
offeredServices → servicesOffered
basePrice → basePrice
visitingCharge → visitingCharge
maxTravelDistance → maxTravelDistanceKm
emergencyService → emergencyServiceAvailable
maxDailyJobs → maxDailyJobs (NEW)
dynamicPricing → dynamicPricingAllowed (NEW)
serviceDescription → serviceDescription
```

### Completion Flags → Firestore
```
profileCompleted → profileCompleted (NEW)
kycCompleted → kycCompleted (NEW)
bankCompleted → bankCompleted (NEW)
servicesCompleted → servicesCompleted (NEW)
submissionTimestamp → submissionTimestamp (NEW)
```

---

## 🚀 DEPLOYMENT STEPS

1. **Backup Firestore** - Export current data
2. **Deploy Cloud Functions** - Update all functions with duplicate checks
3. **Update Firestore Rules** - Deploy new security rules
4. **Update Flutter App** - Replace models and UI files
5. **Test in Staging** - Full end-to-end testing
6. **Gradual Rollout** - 10% → 50% → 100%
7. **Monitor** - Watch for errors and duplicate rejections

---

## ⚠️ CRITICAL NOTES

1. **Aadhaar Hashing:** Must be done in Cloud Function, never on client
2. **Duplicate Check:** Must happen BEFORE saving, not after
3. **Atomic Submission:** All flags must be set together
4. **Limited Dashboard:** Must be enforced in routing, not just UI
5. **Backward Compatibility:** Don't break existing technicians

---

## 📞 SUPPORT

For questions or issues:
- Contact: 9508322397
- Email: support@homefix.app
- Slack: #technician-onboarding

---

## ✅ FINAL CHECKLIST

- [ ] All enhanced files created
- [ ] Cloud Functions updated
- [ ] Firestore rules updated
- [ ] Routing logic updated
- [ ] Limited dashboard integrated
- [ ] Testing completed
- [ ] Staging deployment successful
- [ ] Production deployment ready

**Status:** READY FOR IMPLEMENTATION ✅
