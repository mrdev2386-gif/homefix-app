# 🔍 Onboarding Bug - Root Cause Analysis

## Executive Summary

**Bug**: After completing onboarding, app redirects to Step 4 (Work Portfolio) instead of Home Screen on app restart. Profile completion shows inconsistent values (80% vs 100%).

**Root Cause**: **MULTIPLE CALCULATION METHODS** for profile completion percentage across different parts of the codebase, causing state inconsistency.

---

## 🎯 Root Causes Identified

### ROOT CAUSE #1: **Dual Profile Completion Calculation Logic**

There are **TWO DIFFERENT** methods calculating profile completion:

#### Method 1: `OnboardingValidationService.calculateProfileCompletion()` 
**Location**: `lib/core/services/onboarding_validation_service.dart:166`

```dart
static int calculateProfileCompletion(Map<String, dynamic> formData) {
  int totalFields = 0;
  int completedFields = 0;

  // Step 1 fields (6 mandatory)
  totalFields += 6;
  if (formData['fullName']?.toString().trim().isNotEmpty == true) completedFields++;
  if (formData['state']?.toString().isNotEmpty == true) completedFields++;
  if (formData['district']?.toString().isNotEmpty == true) completedFields++;
  if (formData['profilePhotoUrl']?.toString().isNotEmpty == true) completedFields++;
  final categories = formData['primaryCategoryId'];
  if (categories != null && categories is List && categories.isNotEmpty) completedFields++;
  if (formData['experienceYears'] != null && formData['experienceYears'] > 0) completedFields++;

  // Step 2 fields (1 mandatory)
  totalFields += 1;
  final skills = formData['skills'];
  if (skills != null && skills is List && skills.isNotEmpty) completedFields++;

  // Step 3 fields (3 mandatory)
  totalFields += 3;
  final aadhaar = formData['aadhaarNumber']?.toString().replaceAll(' ', '');
  if (aadhaar != null && aadhaar.length == 12) completedFields++;
  if (formData['aadhaarFrontUrl']?.toString().isNotEmpty == true) completedFields++;
  if (formData['aadhaarBackUrl']?.toString().isNotEmpty == true) completedFields++;

  // Step 4 fields (2 mandatory)
  totalFields += 2;
  final description = formData['experienceDescription']?.toString().trim();
  if (description != null && description.length >= 20) completedFields++;
  if (formData['workPreference']?.toString().isNotEmpty == true) completedFields++;

  return ((completedFields / totalFields) * 100).round();
}
```

**Total**: 12 fields = 100%

---

#### Method 2: `Technician.calculateProfileCompletion()`
**Location**: `lib/core/models/technician.dart:428`

```dart
int calculateProfileCompletion() {
  if (stepsCompleted != null && stepsCompleted!.isNotEmpty) {
    // Count only the required steps: basic, professional, kyc, portfolio
    // Exclude bank step from completion calculation
    final requiredSteps = ['basic', 'professional', 'kyc', 'portfolio'];
    int completedSteps = 0;
    for (final stepKey in requiredSteps) {
      if (stepsCompleted![stepKey] == true) completedSteps++;
    }
    return ((completedSteps / requiredSteps.length) * 100).round().clamp(0, 100);
  }
  
  int completed = 0;
  int total = 8; // Updated total for new fields
  if (name.isNotEmpty) completed++; // Basic info
  if (phone.isNotEmpty) completed++; // Phone
  if (profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty) completed++; // Profile photo
  if (skills.isNotEmpty) completed++; // Skills
  if (experienceYears != null && experienceYears! > 0) completed++; // Experience years
  if ((aadhaarFrontUrl != null && aadhaarFrontUrl!.isNotEmpty) || (panNumber != null && panNumber!.isNotEmpty)) completed++; // KYC
  
  // New Step 4 fields (required for completion)
  if (experienceDescription != null && experienceDescription!.isNotEmpty) completed++; // Experience description
  if (workPreference != null && workPreference!.isNotEmpty) completed++; // Work preference
  
  return ((completed / total) * 100).round().clamp(0, 100);
}
```

**Total**: 
- **Path A** (stepsCompleted exists): 4 steps = 100%
- **Path B** (fallback): 8 fields = 100%

---

### 🔴 **THE PROBLEM**

1. **During Onboarding**: `OnboardingValidationService` calculates based on **12 fields**
2. **After Restart**: `Technician.calculateProfileCompletion()` calculates based on **4 steps** OR **8 fields**
3. **Services Screen**: Uses `Technician.calculateProfileCompletion()` 
4. **Status Guard**: Uses `profileCompletion` field from Firestore (written by onboarding)

**Result**: 
- Onboarding writes `profileCompletion: 100` (12/12 fields)
- After restart, `Technician.calculateProfileCompletion()` returns **80%** (4/5 steps if services step not marked complete)
- Services screen shows "100% complete" (reads Firestore field)
- Home screen shows "80%" (calculates from model)

---

### ROOT CAUSE #2: **Missing `services` Step in stepsCompleted**

**Location**: `lib/core/services/onboarding_service.dart:244`

```dart
final updateData = <String, dynamic>{
  'onboardingStep': stepName,
  'stepsCompleted': {
    'basic': step >= 0,
    'professional': step >= 1,
    'kyc': step >= 2,
    'portfolio': step >= 3,  // Fixed: was 'bank', now 'portfolio'
    'services': step >= 4,   // ⚠️ THIS IS NEVER SET TO TRUE
  },
};
```

**The Issue**: 
- Onboarding has 5 steps (0-4): Basic, Professional, KYC, Portfolio, Success
- Step 4 is the **Success screen**, not a data collection step
- The `services` flag is set to `true` only when `step >= 4`
- But step 4 is never saved because it's the final success screen
- Therefore, `stepsCompleted.services` is **ALWAYS FALSE**

**Impact**:
```dart
// In Technician.calculateProfileCompletion()
final requiredSteps = ['basic', 'professional', 'kyc', 'portfolio'];
int completedSteps = 0;
for (final stepKey in requiredSteps) {
  if (stepsCompleted![stepKey] == true) completedSteps++;
}
return ((completedSteps / requiredSteps.length) * 100).round();
```

If all 4 steps are complete: **100%**
If only 3 steps complete (missing portfolio): **75%**
If services flag was checked: would be **80%** (4/5)

---

### ROOT CAUSE #3: **Resume Logic Redirects to Wrong Step**

**Location**: `lib/screens/technician_onboarding_flow_screen.dart:52`

```dart
void _resumeFromLastStep() async {
  final provider = context.read<TechnicianProvider>();
  final tech = provider.technician;

  if (tech != null) {
    final step = tech.currentOnboardingStep;
    final stepsCompleted = tech.stepsCompleted ?? {};
    
    int safeStep = step.stepIndex;
    
    final completedSteps = [
      if (stepsCompleted['basic'] == true) 0,
      if (stepsCompleted['professional'] == true) 1,
      if (stepsCompleted['kyc'] == true) 2,
      if (stepsCompleted['portfolio'] == true) 3,  // ✅ Correct
    ];
    
    if (completedSteps.isNotEmpty) {
      final highestCompleted = completedSteps.last;
      if (highestCompleted > safeStep) {
        safeStep = highestCompleted;
      }
    }
    
    safeStep = safeStep.clamp(0, 3);  // ⚠️ Clamps to step 3 (Portfolio)
    
    if (_currentStep != safeStep) {
      setState(() {
        _currentStep = safeStep;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(safeStep);  // ⚠️ Jumps to step 3
      }
    }
  }
}
```

**The Issue**:
- After completing all steps, `onboardingStep` in Firestore is set to `4` (Success)
- But `safeStep.clamp(0, 3)` forces it back to step 3 (Portfolio)
- User sees Portfolio screen instead of Success screen

---

### ROOT CAUSE #4: **Inconsistent Field Names in Firestore**

**Location**: Multiple files

The code uses inconsistent field names:
- `stepsCompleted.portfolio` (new)
- `stepsCompleted.bank` (old/legacy)
- `stepsCompleted.services` (never set)

**Evidence**:
```dart
// onboarding_service.dart:244
'portfolio': step >= 3,  // Fixed: was 'bank', now 'portfolio'

// technician.dart:241
final bool resolvedKyc =
    data['isKycComplete'] == true ||
    data['onboardingCompleted'] == true ||
    (stepsMap['kyc'] == true &&
     stepsMap['portfolio'] == true &&  // Fixed: was 'bank', now 'portfolio'
     stepsMap['services'] == true);
```

**Impact**: If Firestore still has `bank: true` but code checks `portfolio: true`, completion calculation fails.

---

## 📊 Data Flow Analysis

### Onboarding Submission Flow

```
1. User completes Step 3 (Portfolio)
   ↓
2. _saveCurrentStep() called
   ↓
3. OnboardingValidationService.calculateProfileCompletion(_formData)
   → Returns 100% (12/12 fields complete)
   ↓
4. saveStepData(step: 3, data: {..., profileCompletion: 100})
   ↓
5. Cloud Function writes to Firestore:
   {
     profileCompletion: 100,
     onboardingStep: 4,
     stepsCompleted: {
       basic: true,
       professional: true,
       kyc: true,
       portfolio: true,
       services: false  // ⚠️ Never set to true
     }
   }
   ↓
6. User sees Success screen (Step 4)
```

### App Restart Flow

```
1. App starts → AuthGate
   ↓
2. Fetches technician document from Firestore
   ↓
3. Technician.fromFirestore() parses data
   ↓
4. calculateProfileCompletion() called
   ↓
5. Checks stepsCompleted map:
   {
     basic: true,
     professional: true,
     kyc: true,
     portfolio: true,
     services: false
   }
   ↓
6. Counts: 4/4 required steps = 100%
   BUT if code checks 'services': 4/5 = 80%
   ↓
7. TechnicianStatusGuard checks profileCompletion field
   → Reads 100 from Firestore
   ↓
8. BUT if it calls calculateProfileCompletion():
   → Returns 80% (if services is checked)
   ↓
9. Redirects to onboarding screen
   ↓
10. _resumeFromLastStep() reads onboardingStep: 4
    ↓
11. Clamps to step 3 (Portfolio)
    ↓
12. User sees Portfolio screen instead of Dashboard
```

---

## 🔍 Exact Problematic Code Locations

### 1. **Dual Calculation Methods**
- **File**: `lib/core/services/onboarding_validation_service.dart`
- **Line**: 166-195
- **Issue**: Calculates based on 12 individual fields

- **File**: `lib/core/models/technician.dart`
- **Line**: 428-461
- **Issue**: Calculates based on 4 steps OR 8 fields (inconsistent)

### 2. **Missing Services Step**
- **File**: `lib/core/services/onboarding_service.dart`
- **Line**: 244-251
- **Issue**: `services: step >= 4` never becomes true

### 3. **Resume Logic**
- **File**: `lib/screens/technician_onboarding_flow_screen.dart`
- **Line**: 52-77
- **Issue**: Clamps to step 3, preventing success screen

### 4. **Status Guard**
- **File**: `lib/core/widgets/technician_status_guard.dart`
- **Line**: 107-110
- **Issue**: Reads `profileCompletion` from Firestore, not calculated

### 5. **Services Screen**
- **File**: `lib/features/technician/services/services_screen.dart`
- **Line**: 70-71
- **Issue**: Calls `calculateProfileCompletion()` which may return different value

---

## ✅ Correct Architecture

### Single Source of Truth

**Principle**: Profile completion should be calculated **ONCE** and stored in Firestore. All screens should read this value, not recalculate.

```dart
// ✅ CORRECT: Single calculation method
class ProfileCompletionService {
  static int calculateCompletion(Map<String, dynamic> stepsCompleted) {
    final requiredSteps = ['basic', 'professional', 'kyc', 'portfolio'];
    int completed = 0;
    
    for (final step in requiredSteps) {
      if (stepsCompleted[step] == true) completed++;
    }
    
    return ((completed / requiredSteps.length) * 100).round();
  }
}

// ✅ CORRECT: All screens read from Firestore
final profileCompletion = technician.profileCompletion; // From Firestore
```

### Step Completion Logic

```dart
// ✅ CORRECT: Mark step complete when saved
'stepsCompleted': {
  'basic': step >= 0,
  'professional': step >= 1,
  'kyc': step >= 2,
  'portfolio': step >= 3,
  // Remove 'services' - not a data collection step
}

// ✅ CORRECT: Calculate completion
final completion = (completedSteps / 4) * 100; // 4 required steps
```

### Resume Logic

```dart
// ✅ CORRECT: Allow navigation to success screen
void _resumeFromLastStep() {
  final stepsCompleted = tech.stepsCompleted ?? {};
  
  // Check if all required steps are complete
  final allComplete = 
    stepsCompleted['basic'] == true &&
    stepsCompleted['professional'] == true &&
    stepsCompleted['kyc'] == true &&
    stepsCompleted['portfolio'] == true;
  
  if (allComplete) {
    // Navigate to success screen (step 4)
    _currentStep = 4;
    _pageController.jumpToPage(4);
  } else {
    // Find last incomplete step
    int lastStep = 0;
    if (stepsCompleted['basic'] == true) lastStep = 1;
    if (stepsCompleted['professional'] == true) lastStep = 2;
    if (stepsCompleted['kyc'] == true) lastStep = 3;
    
    _currentStep = lastStep;
    _pageController.jumpToPage(lastStep);
  }
}
```

---

## 🛠️ Safe Fix Plan

### Phase 1: Unify Calculation Logic

1. **Remove** `Technician.calculateProfileCompletion()` method
2. **Keep** `OnboardingValidationService.calculateProfileCompletion()` as single source
3. **Update** all screens to read `technician.profileCompletion` from Firestore
4. **Add** validation: `profileCompletion` field must exist in Firestore

### Phase 2: Fix Step Completion

1. **Remove** `services` from `stepsCompleted` map
2. **Update** required steps to: `['basic', 'professional', 'kyc', 'portfolio']`
3. **Ensure** `portfolio` step is marked complete when Step 3 is saved

### Phase 3: Fix Resume Logic

1. **Update** `_resumeFromLastStep()` to check all 4 required steps
2. **Allow** navigation to step 4 (Success) when all steps complete
3. **Remove** `safeStep.clamp(0, 3)` restriction

### Phase 4: Fix Status Guard

1. **Update** `TechnicianStatusGuard` to read `profileCompletion` from Firestore only
2. **Add** fallback calculation if field missing
3. **Ensure** consistent behavior across all screens

### Phase 5: Data Migration

1. **Create** Cloud Function to migrate existing technician documents
2. **Recalculate** `profileCompletion` for all technicians
3. **Remove** legacy `bank` and `services` fields from `stepsCompleted`
4. **Add** `portfolio` field if missing

---

## 🎯 Implementation Priority

### Critical (Fix Immediately)
1. ✅ Unify profile completion calculation
2. ✅ Fix resume logic to allow success screen
3. ✅ Remove `services` step from completion check

### High (Fix Soon)
4. ✅ Update all screens to read from Firestore
5. ✅ Add data migration for existing users

### Medium (Fix Later)
6. ✅ Clean up legacy field names
7. ✅ Add comprehensive logging

---

## 📝 Testing Checklist

After implementing fixes:

- [ ] Complete onboarding from scratch
- [ ] Verify profileCompletion = 100% in Firestore
- [ ] Restart app
- [ ] Verify redirects to Dashboard, not Portfolio
- [ ] Check Services screen shows 100%
- [ ] Check Home screen shows 100%
- [ ] Verify Status Guard allows dashboard access
- [ ] Test with partially complete profile (should resume correctly)
- [ ] Test with legacy data (bank field instead of portfolio)

---

## 🔒 Prevention Measures

1. **Single Source of Truth**: Always read `profileCompletion` from Firestore
2. **No Recalculation**: Never recalculate completion on client side
3. **Server-Side Validation**: Cloud Functions validate and set completion
4. **Comprehensive Tests**: Add unit tests for completion logic
5. **Logging**: Add debug logs for state transitions

---

## 📚 Related Files

- `lib/core/services/onboarding_validation_service.dart`
- `lib/core/models/technician.dart`
- `lib/core/services/onboarding_service.dart`
- `lib/screens/technician_onboarding_flow_screen.dart`
- `lib/core/widgets/technician_status_guard.dart`
- `lib/features/technician/services/services_screen.dart`
- `lib/main.dart`

---

**Analysis Complete** ✅

The root cause is **multiple calculation methods** creating state inconsistency. The fix requires **unifying the calculation logic** and ensuring **single source of truth** from Firestore.
