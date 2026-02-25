# 🔍 HomeFix Technician App - Duplicate & Dead Code Audit

**Date:** 2026-01-XX  
**Scope:** Full technician app codebase  
**Status:** READ-ONLY AUDIT (No modifications made)

---

## 🚨 CRITICAL DUPLICATES

### 1. Technician Model Duplication

**Files:**
- `lib/core/models/technician.dart` (CANONICAL)
- `lib/core/models/technician_enhanced.dart` (DUPLICATE)

**Issue:** P0 - Model Conflict

**Details:**
- Both files define identical `OnboardingStep` enum and extension
- Both define `Technician` class with same core fields
- `technician_enhanced.dart` adds 15 new fields (languagePreferences, referralCodeUsed, panNumber, etc.)
- Both have identical `fromFirestore()` and `toMap()` logic
- **CANONICAL:** `technician.dart` (used in imports across codebase)
- **DUPLICATE:** `technician_enhanced.dart` (NOT imported anywhere)

**Safe Fix Recommendation:**
```
MERGE technician_enhanced.dart INTO technician.dart:
1. Keep technician.dart as canonical
2. Add all 15 new fields from technician_enhanced.dart
3. Update fromFirestore() to handle new fields
4. Update toMap() to serialize new fields
5. Delete technician_enhanced.dart
6. No import changes needed (already using technician.dart)
```

**Risk:** LOW - technician_enhanced.dart is unused, safe to delete after merge

---

### 2. Step 1 - Basic Identity (3 Versions)

**Files:**
- `lib/screens/onboarding_steps/step1_basic_identity.dart` (CANONICAL)
- `lib/screens/onboarding_steps/step1_basic_identity_enhanced.dart` (DUPLICATE)
- `lib/screens/onboarding_steps/step1_basic_identity_hardened.dart` (DUPLICATE)

**Issue:** P0 - Duplicate UI Components

**Details:**

| Feature | Base | Enhanced | Hardened |
|---------|------|----------|----------|
| Photo upload | ✅ | ✅ | ✅ |
| Name field | ✅ | ✅ | ✅ (with validation) |
| City field | ✅ | ✅ | ✅ |
| Gender selector | ✅ | ✅ | ✅ |
| DOB picker | ✅ | ✅ | ✅ |
| Category selector | ✅ | ✅ | ✅ |
| Language multi-select | ❌ | ✅ | ❌ |
| Referral code input | ❌ | ✅ | ❌ |
| Phone display (verified) | ❌ | ✅ | ✅ |
| Auto-capitalize name | ❌ | ❌ | ✅ |
| Name validation | ❌ | ❌ | ✅ |

**Currently Used:** `step1_basic_identity.dart` (imported in technician_onboarding_flow_screen.dart)

**Safe Fix Recommendation:**
```
CONSOLIDATE into single step1_basic_identity.dart:
1. Keep base structure from step1_basic_identity.dart
2. Add phone display from hardened version
3. Add auto-capitalize + validation from hardened version
4. Add language selector from enhanced version
5. Add referral code input from enhanced version
6. Delete step1_basic_identity_enhanced.dart
7. Delete step1_basic_identity_hardened.dart
8. Update technician_onboarding_flow_screen.dart import (no change needed)
```

**Risk:** LOW - Only base version is imported, others are orphaned

---

### 3. Step 4 - Bank Details (3 Versions)

**Files:**
- `lib/screens/onboarding_steps/step4_bank_details.dart` (CANONICAL)
- `lib/screens/onboarding_steps/step4_bank_details_enhanced.dart` (DUPLICATE)
- `lib/screens/onboarding_steps/step4_bank_details_hardened.dart` (DUPLICATE)

**Issue:** P0 - Duplicate UI Components

**Details:**

| Feature | Base | Enhanced | Hardened |
|---------|------|----------|----------|
| Account holder field | ✅ | ✅ | ✅ |
| Account number field | ✅ | ✅ | ✅ |
| Confirm account field | ❌ | ✅ | ✅ |
| IFSC validation | ✅ | ✅ | ✅ |
| Bank name field | ✅ | ✅ | ✅ |
| UPI field | ✅ | ✅ | ✅ |
| Account type selector | ❌ | ✅ | ❌ |
| Payout preference selector | ❌ | ✅ | ❌ |
| Masked account display | ❌ | ✅ | ✅ |
| Visibility toggle | ❌ | ✅ | ✅ |
| Account match validation | ❌ | ✅ | ✅ |

**Currently Used:** `step4_bank_details.dart` (imported in technician_onboarding_flow_screen.dart)

**Safe Fix Recommendation:**
```
CONSOLIDATE into single step4_bank_details.dart:
1. Keep base structure from step4_bank_details.dart
2. Add confirm account field from hardened version
3. Add masked display + visibility toggle from hardened version
4. Add account match validation from hardened version
5. Add account type selector from enhanced version
6. Add payout preference selector from enhanced version
7. Delete step4_bank_details_enhanced.dart
8. Delete step4_bank_details_hardened.dart
9. Update technician_onboarding_flow_screen.dart import (no change needed)
```

**Risk:** LOW - Only base version is imported, others are orphaned

---

### 4. Limited Dashboard (2 Versions)

**Files:**
- `lib/screens/limited_dashboard.dart` (BASIC)
- `lib/screens/limited_dashboard_enhanced.dart` (ENHANCED)

**Issue:** P1 - Duplicate Dashboard Screens

**Details:**

| Feature | Basic | Enhanced |
|---------|-------|----------|
| Header | ✅ | ✅ (more detailed) |
| Status card | ❌ | ✅ (gradient, animated) |
| Limitation items | ❌ | ✅ (detailed list) |
| Refresh button | ❌ | ✅ |
| Contact support | ❌ | ✅ |
| Logout button | ✅ | ✅ |
| Menu items | ✅ (3 items) | ❌ (buttons instead) |

**Currently Used:** `limited_dashboard.dart` (imported in main.dart)

**Safe Fix Recommendation:**
```
CONSOLIDATE into single limited_dashboard.dart:
1. Use enhanced version as base (better UX)
2. Rename LimitedDashboardScreen → LimitedDashboard
3. Delete limited_dashboard.dart
4. Update main.dart import to use enhanced version
5. Verify routing in AuthGate still works
```

**Risk:** LOW - Basic version is used, enhanced is orphaned

---

## ⚠️ SAFE CLEANUP CANDIDATES

### 1. Image Utilities Duplication

**Files:**
- `lib/core/utils/image_size_guard.dart` (HARDENED - 500KB limit)
- `lib/core/services/image_compression_service.dart` (LEGACY - 500KB limit)
- `lib/core/utils/image_utils.dart` (URL sanitization only)

**Issue:** P1 - Duplicate Image Compression Logic

**Details:**
- Both `image_size_guard.dart` and `image_compression_service.dart` do identical compression
- Same max size (500KB), same quality (75), same resize logic
- `image_size_guard.dart` is newer (hardened version)
- `image_compression_service.dart` is legacy
- `image_utils.dart` is different (URL sanitization) - keep it

**Currently Used:**
- `image_size_guard.dart` - NOT imported anywhere (dead code)
- `image_compression_service.dart` - NOT imported anywhere (dead code)
- `image_utils.dart` - Used in safe_network_image.dart

**Safe Fix Recommendation:**
```
CONSOLIDATE image compression:
1. Keep image_size_guard.dart (newer, better structured)
2. Delete image_compression_service.dart (legacy duplicate)
3. Keep image_utils.dart (different purpose - URL sanitization)
4. Add imports to TechnicianProvider where image upload happens
5. Verify image upload flow uses image_size_guard.dart
```

**Risk:** LOW - Both are unused, safe to consolidate

---

### 2. Step 3 - KYC Verification (2 Versions)

**Files:**
- `lib/screens/onboarding_steps/step3_kyc_verification.dart` (CANONICAL)
- `lib/screens/onboarding_steps/step3_kyc_verification_enhanced.dart` (DUPLICATE)

**Issue:** P1 - Duplicate UI Component

**Details:**
- Enhanced version adds PAN collection fields
- Base version has Aadhaar fields only
- Both have identical structure otherwise
- Only base version is imported

**Currently Used:** `step3_kyc_verification.dart`

**Safe Fix Recommendation:**
```
CONSOLIDATE into single step3_kyc_verification.dart:
1. Add PAN fields from enhanced version
2. Delete step3_kyc_verification_enhanced.dart
3. No import changes needed
```

**Risk:** LOW - Only base version is imported

---

### 3. Step 5 - Service Setup (2 Versions)

**Files:**
- `lib/screens/onboarding_steps/step5_service_setup.dart` (CANONICAL)
- `lib/screens/onboarding_steps/step5_service_setup_enhanced.dart` (DUPLICATE)

**Issue:** P1 - Duplicate UI Component

**Details:**
- Enhanced version adds price validation, max daily jobs, dynamic pricing
- Base version has basic service selection
- Only base version is imported

**Currently Used:** `step5_service_setup.dart`

**Safe Fix Recommendation:**
```
CONSOLIDATE into single step5_service_setup.dart:
1. Add price validation from enhanced version
2. Add max daily jobs field from enhanced version
3. Add dynamic pricing toggle from enhanced version
4. Delete step5_service_setup_enhanced.dart
5. No import changes needed
```

**Risk:** LOW - Only base version is imported

---

## 🧹 DEAD CODE

### 1. Unused Enhanced/Hardened Files

**Files (NOT imported anywhere):**
- `lib/screens/onboarding_steps/step1_basic_identity_enhanced.dart`
- `lib/screens/onboarding_steps/step1_basic_identity_hardened.dart`
- `lib/screens/onboarding_steps/step3_kyc_verification_enhanced.dart`
- `lib/screens/onboarding_steps/step4_bank_details_enhanced.dart`
- `lib/screens/onboarding_steps/step4_bank_details_hardened.dart`
- `lib/screens/onboarding_steps/step5_service_setup_enhanced.dart`
- `lib/core/models/technician_enhanced.dart`
- `lib/screens/limited_dashboard_enhanced.dart`
- `lib/core/services/image_compression_service.dart`
- `lib/core/utils/image_size_guard.dart`

**Issue:** P2 - Dead Code

**Details:**
- These files were created during development/hardening phases
- They are NOT imported in any active code
- They increase bundle size and maintenance burden
- They create confusion about which version is canonical

**Safe Fix Recommendation:**
```
DELETE all unused enhanced/hardened files after consolidation:
1. Merge features into canonical versions
2. Delete orphaned files
3. Verify no imports reference deleted files
4. Run `flutter analyze` to confirm no broken imports
```

**Risk:** LOW - All are unused, safe to delete

---

### 2. Unused Onboarding Screen

**File:**
- `lib/screens/onboarding_screen.dart`

**Issue:** P2 - Legacy Code

**Details:**
- Referenced in main.dart as `/onboarding_legacy` route
- Never used in actual flow (AuthGate uses TechnicianOnboardingFlowScreen)
- Created before TechnicianOnboardingFlowScreen was built

**Currently Used:** NO (legacy route only)

**Safe Fix Recommendation:**
```
DELETE onboarding_screen.dart:
1. Remove `/onboarding_legacy` route from main.dart
2. Verify no deep links reference it
3. Delete the file
```

**Risk:** LOW - Legacy code, not in active flow

---

## 🔁 ROUTING ISSUES

### 1. Multiple Onboarding Entry Points

**Issue:** P1 - Routing Confusion

**Details:**
- `TechnicianOnboardingFlowScreen` - CANONICAL (6-step flow)
- `OnboardingScreen` - LEGACY (unused)
- Both are defined in main.dart routes

**Current Routing (main.dart):**
```dart
routes: {
  '/home': (_) => const DashboardScreen(),
  '/onboarding': (_) => const TechnicianOnboardingFlowScreen(),
  '/onboarding_legacy': (_) => const OnboardingScreen(),  // UNUSED
  '/login': (_) => const LoginScreen(),
}
```

**Safe Fix Recommendation:**
```
CLEAN UP routing:
1. Keep only /onboarding → TechnicianOnboardingFlowScreen
2. Remove /onboarding_legacy route
3. Delete OnboardingScreen file
4. AuthGate already routes to TechnicianOnboardingFlowScreen (correct)
```

**Risk:** LOW - Legacy route is unused

---

### 2. Dashboard Route Uniqueness

**Status:** ✅ CLEAN

**Details:**
- `/home` → DashboardScreen (approved technicians)
- LimitedDashboard (pending approval) - no route, shown directly in AuthGate
- BlockScreen (blocked users) - no route, shown directly in AuthGate
- ApplicationStatusScreen (rejected/suspended) - no route, shown directly in AuthGate

**Recommendation:** KEEP AS IS (correct pattern)

---

## 📦 MODEL CONFLICTS

### 1. Technician Model Field Duplication

**Issue:** P0 - Field Duplication

**Details:**
- `technician.dart` has core fields + KYC fields
- `technician_enhanced.dart` duplicates all fields + adds 15 new ones
- New fields in enhanced: languagePreferences, referralCodeUsed, panNumber, panImageUrl, accountType, payoutPreference, maxDailyJobs, dynamicPricingAllowed, teamSize, maxTravelDistanceKm, profileCompleted, kycCompleted, bankCompleted, servicesCompleted, submissionTimestamp

**Safe Fix Recommendation:**
```
MERGE technician_enhanced.dart into technician.dart:
1. Add all 15 new fields to technician.dart
2. Update fromFirestore() to deserialize new fields
3. Update toMap() to serialize new fields
4. Add new getter methods (isOnboardingFullyComplete, isPendingApproval)
5. Delete technician_enhanced.dart
```

**Risk:** LOW - Enhanced version is unused

---

### 2. OnboardingStep Enum Duplication

**Issue:** P1 - Enum Duplication

**Details:**
- `OnboardingStep` enum defined in both technician.dart and technician_enhanced.dart
- Identical definitions
- Extension methods identical

**Safe Fix Recommendation:**
```
CONSOLIDATE:
1. Keep OnboardingStep in technician.dart only
2. Delete duplicate from technician_enhanced.dart
```

**Risk:** LOW - Identical definitions

---

## 🧠 PERFORMANCE RISKS

### 1. Unused Image Compression Utilities

**Issue:** P2 - Dead Code in Bundle

**Details:**
- `image_size_guard.dart` - NOT imported anywhere
- `image_compression_service.dart` - NOT imported anywhere
- Both add ~2KB to bundle size
- Image upload in TechnicianProvider doesn't use either

**Safe Fix Recommendation:**
```
INTEGRATE image compression:
1. Add image_size_guard.dart import to TechnicianProvider
2. Call ImageSizeGuard.validateAndCompress() before upload
3. Delete image_compression_service.dart
4. Verify image upload works end-to-end
```

**Risk:** MEDIUM - Image validation not enforced, could allow large uploads

---

### 2. Multiple Model Instantiations

**Issue:** P2 - Memory Inefficiency

**Details:**
- Technician model loaded from Firestore in multiple places
- TechnicianProvider loads it
- OnboardingService reads it separately
- No caching mechanism

**Safe Fix Recommendation:**
```
OPTIMIZE model loading:
1. Centralize Technician loading in TechnicianProvider
2. OnboardingService should use provider's cached instance
3. Add refresh() method to invalidate cache
4. Reduce Firestore reads
```

**Risk:** LOW - Not critical, but inefficient

---

## ✅ CLEAN AREAS

### 1. Cloud Functions Integration

**Status:** ✅ CLEAN

**Details:**
- OnboardingService correctly calls Cloud Functions
- No duplicate CF calls
- Proper error handling
- Idempotent guards in place

---

### 2. Firestore Rules

**Status:** ✅ CLEAN

**Details:**
- firestore_hardened.rules is canonical
- No duplicate rules files
- Proper field protection (allow write: if false)

---

### 3. Routing Logic

**Status:** ✅ MOSTLY CLEAN

**Details:**
- AuthGate has clear routing order
- No orphan routes (except legacy /onboarding_legacy)
- Proper state checks

---

### 4. Provider Pattern

**Status:** ✅ CLEAN

**Details:**
- TechnicianProvider is single source of truth
- No duplicate providers
- Proper state management

---

## 📋 CONSOLIDATION CHECKLIST

### Phase 1: Model Consolidation (P0)

- [ ] Merge technician_enhanced.dart into technician.dart
  - [ ] Add 15 new fields
  - [ ] Update fromFirestore()
  - [ ] Update toMap()
  - [ ] Add new getter methods
- [ ] Delete technician_enhanced.dart
- [ ] Run `flutter analyze` - verify no broken imports
- [ ] Test technician data loading

### Phase 2: Step Consolidation (P0)

**Step 1:**
- [ ] Merge step1_basic_identity_enhanced.dart features
- [ ] Merge step1_basic_identity_hardened.dart features
- [ ] Delete both enhanced/hardened versions
- [ ] Test Step 1 UI

**Step 3:**
- [ ] Merge step3_kyc_verification_enhanced.dart features
- [ ] Delete enhanced version
- [ ] Test Step 3 UI

**Step 4:**
- [ ] Merge step4_bank_details_enhanced.dart features
- [ ] Merge step4_bank_details_hardened.dart features
- [ ] Delete both enhanced/hardened versions
- [ ] Test Step 4 UI

**Step 5:**
- [ ] Merge step5_service_setup_enhanced.dart features
- [ ] Delete enhanced version
- [ ] Test Step 5 UI

### Phase 3: Dashboard Consolidation (P1)

- [ ] Merge limited_dashboard_enhanced.dart into limited_dashboard.dart
- [ ] Delete limited_dashboard_enhanced.dart
- [ ] Update main.dart if needed
- [ ] Test limited dashboard display

### Phase 4: Image Utilities Consolidation (P1)

- [ ] Integrate image_size_guard.dart into TechnicianProvider
- [ ] Delete image_compression_service.dart
- [ ] Test image upload with size validation
- [ ] Verify < 500KB enforcement

### Phase 5: Routing Cleanup (P2)

- [ ] Delete onboarding_screen.dart
- [ ] Remove `/onboarding_legacy` route from main.dart
- [ ] Run `flutter analyze`
- [ ] Test app startup flow

### Phase 6: Verification

- [ ] Run `flutter analyze` - 0 issues
- [ ] Run `flutter test` - all tests pass
- [ ] Test full onboarding flow
- [ ] Test dashboard access
- [ ] Test limited dashboard
- [ ] Verify no broken imports
- [ ] Check bundle size reduction

---

## 📊 SUMMARY

| Category | Count | Severity | Action |
|----------|-------|----------|--------|
| Duplicate Models | 1 | P0 | Merge |
| Duplicate UI Steps | 6 | P0 | Consolidate |
| Duplicate Dashboards | 1 | P1 | Consolidate |
| Duplicate Image Utils | 2 | P1 | Consolidate |
| Dead Code Files | 10 | P2 | Delete |
| Legacy Routes | 1 | P2 | Remove |
| **TOTAL** | **21** | - | - |

---

## 🎯 PRODUCTION READINESS IMPACT

**Before Cleanup:**
- Bundle size: Inflated with 10 unused files
- Maintenance burden: High (multiple versions to maintain)
- Developer confusion: High (which version is canonical?)
- Code quality: Medium (dead code present)

**After Cleanup:**
- Bundle size: Reduced by ~15-20KB
- Maintenance burden: Low (single canonical version per component)
- Developer confusion: None (clear single source of truth)
- Code quality: High (no dead code)

---

## ⚠️ CRITICAL NOTES

1. **DO NOT DELETE** before merging features
2. **RUN TESTS** after each consolidation phase
3. **VERIFY IMPORTS** - use `flutter analyze`
4. **BACKUP** before starting consolidation
5. **COMMIT FREQUENTLY** - one consolidation per commit

---

**Audit Completed:** ✅ READ-ONLY  
**Next Step:** Execute consolidation checklist in order  
**Estimated Time:** 2-3 hours for full consolidation + testing
