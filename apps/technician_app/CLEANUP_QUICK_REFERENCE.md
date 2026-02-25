# 🗑️ Quick Cleanup Reference

## Files to DELETE (After Consolidation)

### Models
```
DELETE: lib/core/models/technician_enhanced.dart
KEEP:   lib/core/models/technician.dart (merge features into this)
```

### Onboarding Steps
```
DELETE: lib/screens/onboarding_steps/step1_basic_identity_enhanced.dart
DELETE: lib/screens/onboarding_steps/step1_basic_identity_hardened.dart
KEEP:   lib/screens/onboarding_steps/step1_basic_identity.dart

DELETE: lib/screens/onboarding_steps/step3_kyc_verification_enhanced.dart
KEEP:   lib/screens/onboarding_steps/step3_kyc_verification.dart

DELETE: lib/screens/onboarding_steps/step4_bank_details_enhanced.dart
DELETE: lib/screens/onboarding_steps/step4_bank_details_hardened.dart
KEEP:   lib/screens/onboarding_steps/step4_bank_details.dart

DELETE: lib/screens/onboarding_steps/step5_service_setup_enhanced.dart
KEEP:   lib/screens/onboarding_steps/step5_service_setup.dart
```

### Dashboards
```
DELETE: lib/screens/limited_dashboard_enhanced.dart
KEEP:   lib/screens/limited_dashboard.dart (or use enhanced as base)
```

### Image Utilities
```
DELETE: lib/core/services/image_compression_service.dart
DELETE: lib/core/utils/image_size_guard.dart (integrate into provider first)
KEEP:   lib/core/utils/image_utils.dart (URL sanitization)
```

### Legacy Screens
```
DELETE: lib/screens/onboarding_screen.dart
```

---

## Files to KEEP (Canonical Versions)

```
✅ lib/core/models/technician.dart
✅ lib/screens/onboarding_steps/step1_basic_identity.dart
✅ lib/screens/onboarding_steps/step2_professional_details.dart
✅ lib/screens/onboarding_steps/step3_kyc_verification.dart
✅ lib/screens/onboarding_steps/step4_bank_details.dart
✅ lib/screens/onboarding_steps/step5_service_setup.dart
✅ lib/screens/onboarding_steps/step6_success.dart
✅ lib/screens/limited_dashboard.dart
✅ lib/screens/dashboard_screen.dart
✅ lib/screens/technician_onboarding_flow_screen.dart
✅ lib/core/utils/image_utils.dart
```

---

## Files to MODIFY

### 1. lib/core/models/technician.dart
**Add these fields from technician_enhanced.dart:**
```dart
final List<String>? languagePreferences;
final String? referralCodeUsed;
final String? panNumber;
final String? panImageUrl;
final String? accountType;
final String? payoutPreference;
final int? maxDailyJobs;
final bool dynamicPricingAllowed;
final String? teamSize;
final int? maxTravelDistanceKm;
final bool profileCompleted;
final bool kycCompleted;
final bool bankCompleted;
final bool servicesCompleted;
final DateTime? submissionTimestamp;
```

**Add these getters from technician_enhanced.dart:**
```dart
bool get isOnboardingFullyComplete {
  return profileCompleted && kycCompleted && bankCompleted && servicesCompleted;
}

bool get isPendingApproval {
  return isKycComplete && !isApproved;
}
```

### 2. lib/screens/onboarding_steps/step1_basic_identity.dart
**Add from hardened version:**
- Auto-capitalize name on blur
- Name validation
- Phone display from Firebase Auth

**Add from enhanced version:**
- Language multi-select
- Referral code input

### 3. lib/screens/onboarding_steps/step3_kyc_verification.dart
**Add from enhanced version:**
- PAN number field
- PAN image upload

### 4. lib/screens/onboarding_steps/step4_bank_details.dart
**Add from hardened version:**
- Confirm account number field
- Account match validation
- Masked account display
- Visibility toggle

**Add from enhanced version:**
- Account type selector
- Payout preference selector

### 5. lib/screens/onboarding_steps/step5_service_setup.dart
**Add from enhanced version:**
- Price validation (> 0)
- Max daily jobs field
- Dynamic pricing toggle

### 6. lib/screens/limited_dashboard.dart
**Replace with enhanced version or merge:**
- Status card with gradient
- Limitation items list
- Refresh button
- Contact support button
- Better UX overall

### 7. lib/main.dart
**Remove this route:**
```dart
'/onboarding_legacy': (_) => const OnboardingScreen(),  // DELETE THIS LINE
```

---

## Verification Commands

```bash
# Check for broken imports
flutter analyze

# Check for unused imports
dart fix --dry-run

# Run tests
flutter test

# Check bundle size
flutter build apk --analyze-size

# Search for deleted file references
grep -r "step1_basic_identity_enhanced" lib/
grep -r "step1_basic_identity_hardened" lib/
grep -r "technician_enhanced" lib/
grep -r "image_compression_service" lib/
grep -r "image_size_guard" lib/
grep -r "onboarding_screen" lib/
```

---

## Consolidation Order (Recommended)

1. **Technician Model** (foundation for everything)
2. **Step 1** (basic identity)
3. **Step 3** (KYC)
4. **Step 4** (bank)
5. **Step 5** (services)
6. **Limited Dashboard**
7. **Image Utilities**
8. **Routing Cleanup**

---

## Testing After Each Phase

```bash
# After model consolidation
flutter pub get
flutter analyze

# After each step consolidation
flutter run --debug

# After dashboard consolidation
flutter run --debug
# Test: Go through full onboarding flow
# Test: Check limited dashboard display

# After image utilities
flutter run --debug
# Test: Upload image in Step 1
# Verify: Image is < 500KB

# After routing cleanup
flutter run --debug
# Test: App startup
# Test: Login flow
# Test: Onboarding flow
```

---

## Files Summary

**Total Files to Delete:** 10  
**Total Files to Keep:** 11  
**Total Files to Modify:** 7  
**Total Files Unchanged:** 50+

**Estimated Bundle Size Reduction:** 15-20KB  
**Estimated Time:** 2-3 hours
