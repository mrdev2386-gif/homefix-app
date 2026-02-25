# 🚀 Quick Reference - Technician Onboarding

## File Structure
```
lib/
├── screens/
│   ├── technician_onboarding_flow_screen.dart    ← Main controller
│   └── onboarding_steps/
│       ├── step1_basic_identity.dart
│       ├── step2_professional_details.dart
│       ├── step3_kyc_verification.dart
│       ├── step4_bank_details.dart
│       ├── step5_service_setup.dart
│       └── step6_success.dart
├── core/
│   ├── models/technician.dart                    ← Updated
│   ├── services/onboarding_service.dart          ← Cloud Function calls
│   └── providers/technician_provider.dart        ← Updated
└── main.dart                                      ← Updated routing
```

## Key Classes

### TechnicianOnboardingFlowScreen
Main PageView controller managing all 6 steps.

```dart
// Usage in main.dart
if (tech == null || !isKycComplete) {
  return const TechnicianOnboardingFlowScreen();
}
```

### OnboardingService
Calls Cloud Functions for all writes.

```dart
// Save basic details
await onboardingService.saveBasicDetails(
  fullName: 'John Doe',
  email: 'john@example.com',
  district: 'Mumbai',
  experienceYears: 5,
);

// Save documents
await onboardingService.saveDocuments(
  aadhaarNumber: '123456789012',
  aadhaarFrontUrl: 'gs://...',
  aadhaarBackUrl: 'gs://...',
  profilePhotoUrl: 'gs://...',
);

// Submit application
await onboardingService.submitApplication();
```

### TechnicianProvider
State management for onboarding.

```dart
// Upload image
final url = await provider.uploadDocumentImage(file, 'aadhaar_front');

// Submit KYC
await provider.submitKycApplication();

// Refresh data
await provider.refreshTechnicianData();
```

## Technician Status States

```
"onboarding"        → Initial state, user filling form
"kyc_pending"       → KYC submitted, awaiting admin review
"pending_approval"  → KYC approved, awaiting admin approval for services
"approved"          → Fully approved, can access dashboard
"rejected"          → KYC rejected, can restart
"blocked"           → Account blocked, cannot access
```

## Access Control

```dart
// In _AuthenticatedGate (main.dart)

if (tech == null || !isKycComplete) {
  // → TechnicianOnboardingFlowScreen
}

if (isKycComplete && !isApproved) {
  // → ApplicationStatusScreen (pending/rejected)
}

if (isApproved && !adminApproved) {
  // → ApplicationStatusScreen (awaiting service approval)
}

if (isApproved && adminApproved) {
  // → DashboardScreen (full access)
}
```

## Form Data Flow

```dart
// In TechnicianOnboardingFlowScreen
final Map<String, dynamic> _formData = {};

// Each step updates formData
Step1BasicIdentity(
  formData: _formData,
  onDataChanged: (key, value) {
    _formData[key] = value;
  },
)

// On submit, all data sent to Cloud Functions
await provider.submitKycApplication();
```

## Validation Functions

```dart
// Aadhaar validation
final error = OnboardingService.validateAadhaar('123456789012');
// Returns null if valid, error message if invalid

// Aadhaar masking
final masked = OnboardingService.maskAadhaar('123456789012');
// Returns: "1234-5678-9012"

// IFSC validation (in Step 4)
final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
if (!ifscRegex.hasMatch(ifscCode)) {
  // Invalid IFSC
}

// Account number validation (in Step 4)
if (!/^\d{9,18}$/.test(accountNumber)) {
  // Invalid account number
}
```

## Image Upload

```dart
// In TechnicianProvider
final url = await provider.uploadDocumentImage(
  file,           // File object
  'aadhaar_front', // Type: 'aadhaar_front', 'aadhaar_back', 'selfie', 'profile_photo'
  maxRetries: 3,  // Retry up to 3 times
);

// Storage path: technicians/{uid}/kyc/{type}.jpg
// Returns: Download URL
```

## Cloud Functions

### Required Functions
1. `createTechnicianProfile` - After OTP
2. `saveTechnicianBasicDetails` - Step 1
3. `saveTechnicianDocuments` - Step 3
4. `saveTechnicianBankDetails` - Step 4
5. `saveTechnicianServices` - Step 5
6. `submitTechnicianKyc` - Final submit
7. `approveTechnicianKyc` - Admin approval
8. `rejectTechnicianKyc` - Admin rejection
9. `updateTechnicianStatus` - Online/offline toggle

### Calling Cloud Functions

```dart
// In OnboardingService
final result = await _callFunction('saveTechnicianBasicDetails', {
  'fullName': fullName,
  'email': email,
  'district': district,
  'experienceYears': experienceYears,
});
```

## Firestore Security Rules

```
✅ Technicians can only read/write own profile
✅ Protected fields (isApproved, adminApproved) server-side only
✅ All writes via Cloud Functions
✅ Services only manageable by approved technicians
✅ Bookings visible only to involved parties
```

## Testing Checklist

### Step 1: Basic Identity
- [ ] Camera capture works
- [ ] Photo preview displays
- [ ] Form validation works
- [ ] Category dropdown works

### Step 2: Professional Details
- [ ] Experience selector works
- [ ] Skills multi-select works
- [ ] Time picker works
- [ ] Tools toggle works

### Step 3: KYC Verification
- [ ] Aadhaar validation works
- [ ] Camera capture works
- [ ] Image upload shows progress
- [ ] Security notice displays

### Step 4: Bank Details
- [ ] Account number validation works
- [ ] IFSC format validation works
- [ ] UPI format validation works
- [ ] Security notice displays

### Step 5: Service Setup
- [ ] Service multi-select works
- [ ] Price fields accept numbers
- [ ] Emergency toggle works

### Step 6: Success
- [ ] Success screen displays
- [ ] Buttons work correctly

### Resume Flow
- [ ] Close app mid-onboarding
- [ ] Reopen app
- [ ] Resume from last step
- [ ] Form data pre-filled

### Admin Approval
- [ ] Admin approves technician
- [ ] Technician receives notification
- [ ] Dashboard becomes accessible

## Common Errors & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "User not authenticated" | No Firebase Auth | Ensure user logged in via OTP |
| "Technician profile not found" | Profile not created | Call `createTechnicianProfile` first |
| "Invalid Aadhaar format" | Not 12 digits | Validate before sending |
| "Upload timed out" | Slow network | Retry with exponential backoff |
| "Permission denied" | Not approved | Check `isApproved` flag |
| "All steps must be completed" | Incomplete form | Verify all steps done |

## Debugging Tips

```dart
// Enable debug logging
debugPrint('[OnboardingService] Saved basic details via Cloud Function');

// Check technician status
final tech = context.read<TechnicianProvider>().technician;
debugPrint('Status: ${tech?.status}');
debugPrint('KYC Complete: ${tech?.isKycComplete}');
debugPrint('Approved: ${tech?.isApproved}');

// Check form data
debugPrint('Form data: $_formData');

// Check current step
debugPrint('Current step: $_currentStep');
```

## Performance Tips

- ✅ Use debounced autosave (not on every keystroke)
- ✅ Compress images before upload (80% quality)
- ✅ Use deterministic storage paths (prevent duplicates)
- ✅ Implement retry logic with exponential backoff
- ✅ Cache form data in memory (not persistent)
- ✅ Use lazy loading for images

## Security Reminders

- ❌ NEVER write `isApproved` from client
- ❌ NEVER write `adminApproved` from client
- ❌ NEVER log full Aadhaar numbers
- ❌ NEVER log full account numbers
- ❌ NEVER store images in Firestore
- ✅ ALWAYS validate on server-side
- ✅ ALWAYS use Cloud Functions for writes
- ✅ ALWAYS mask sensitive data for display

## Deployment Steps

1. Deploy Cloud Functions
   ```bash
   firebase deploy --only functions
   ```

2. Update Firestore Rules
   ```bash
   firebase deploy --only firestore:rules
   ```

3. Test in staging
   ```bash
   flutter run --release
   ```

4. Deploy to production
   ```bash
   flutter build apk --release
   ```

## Useful Links

- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Firebase Storage Documentation](https://firebase.google.com/docs/storage)
- [Flutter Firebase Plugin](https://firebase.flutter.dev/)

## Support

For issues or questions:
1. Check ONBOARDING_IMPLEMENTATION.md
2. Check CLOUD_FUNCTIONS_TEMPLATE.js
3. Review firestore.rules
4. Check debug logs
5. Contact: support@homefix.app

---

**Last Updated:** 2026-01-XX
**Version:** 1.0
