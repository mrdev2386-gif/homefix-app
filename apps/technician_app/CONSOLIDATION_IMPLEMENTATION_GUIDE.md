# 🔧 Consolidation Implementation Guide

## Phase 1: Technician Model Consolidation

### Step 1.1: Update technician.dart

**File:** `lib/core/models/technician.dart`

**Add these fields to the Technician class constructor:**

```dart
// Add to field declarations (after emergencyServiceAvailable)
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

**Add to constructor parameters:**

```dart
this.languagePreferences,
this.referralCodeUsed,
this.panNumber,
this.panImageUrl,
this.accountType,
this.payoutPreference,
this.maxDailyJobs,
this.dynamicPricingAllowed = false,
this.teamSize,
this.maxTravelDistanceKm,
this.profileCompleted = false,
this.kycCompleted = false,
this.bankCompleted = false,
this.servicesCompleted = false,
this.submissionTimestamp,
```

**Add to fromFirestore() method (in return statement):**

```dart
languagePreferences: List<String>.from(data['languagePreferences'] ?? []),
referralCodeUsed: data['referralCodeUsed'],
panNumber: data['panNumber'],
panImageUrl: data['panImageUrl'],
accountType: data['accountType'],
payoutPreference: data['payoutPreference'],
maxDailyJobs: data['maxDailyJobs'],
dynamicPricingAllowed: data['dynamicPricingAllowed'] ?? false,
teamSize: data['teamSize'],
maxTravelDistanceKm: data['maxTravelDistanceKm'],
profileCompleted: data['profileCompleted'] ?? false,
kycCompleted: data['kycCompleted'] ?? false,
bankCompleted: data['bankCompleted'] ?? false,
servicesCompleted: data['servicesCompleted'] ?? false,
submissionTimestamp: data['submissionTimestamp'] != null
    ? (data['submissionTimestamp'] as Timestamp).toDate()
    : null,
```

**Add to toMap() method:**

```dart
'languagePreferences': languagePreferences,
'referralCodeUsed': referralCodeUsed,
'panNumber': panNumber,
'panImageUrl': panImageUrl,
'accountType': accountType,
'payoutPreference': payoutPreference,
'maxDailyJobs': maxDailyJobs,
'dynamicPricingAllowed': dynamicPricingAllowed,
'teamSize': teamSize,
'maxTravelDistanceKm': maxTravelDistanceKm,
'profileCompleted': profileCompleted,
'kycCompleted': kycCompleted,
'bankCompleted': bankCompleted,
'servicesCompleted': servicesCompleted,
'submissionTimestamp': submissionTimestamp != null ? Timestamp.fromDate(submissionTimestamp!) : null,
```

**Add new getter methods (after existing getters):**

```dart
/// Check if technician has completed all onboarding steps
bool get isOnboardingFullyComplete {
  return profileCompleted && kycCompleted && bankCompleted && servicesCompleted;
}

/// Check if technician is pending approval
bool get isPendingApproval {
  return isKycComplete && !isApproved;
}
```

### Step 1.2: Verify and Test

```bash
cd apps/technician_app
flutter analyze
# Should show 0 issues

flutter pub get
# Should succeed
```

### Step 1.3: Delete technician_enhanced.dart

```bash
rm lib/core/models/technician_enhanced.dart
```

### Step 1.4: Verify no broken imports

```bash
grep -r "technician_enhanced" lib/
# Should return 0 results

flutter analyze
# Should show 0 issues
```

---

## Phase 2: Step 1 Consolidation

### Step 2.1: Update step1_basic_identity.dart

**File:** `lib/screens/onboarding_steps/step1_basic_identity.dart`

**Add imports:**

```dart
import 'package:firebase_auth/firebase_auth.dart';
```

**Add to _Step1BasicIdentityState class:**

```dart
String? _nameError;

// Add this method
String _capitalizeWords(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

void _onNameBlur() {
  final capitalized = _capitalizeWords(_nameController.text);
  _nameController.value = _nameController.value.copyWith(
    text: capitalized,
    selection: TextSelection.collapsed(offset: capitalized.length),
  );
  widget.onDataChanged('fullName', capitalized);
  _validateName();
}

void _validateName() {
  setState(() {
    _nameError = _nameController.text.trim().isEmpty ? 'Name is required' : null;
  });
}
```

**Update _buildTextField for name field:**

```dart
// Replace the name field section with:
_buildNameField(),
```

**Add new method:**

```dart
Widget _buildNameField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'Full Name',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '*',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _nameError != null ? Colors.red : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _nameController,
          onChanged: (value) => widget.onDataChanged('fullName', value),
          onEditingComplete: _onNameBlur,
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6366F1), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      if (_nameError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _nameError!,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.red),
          ),
        ),
    ],
  );
}

Widget _buildPhoneDisplay(String phone) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4FF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFE0E7FF),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        const Icon(Icons.phone_verified_outlined, color: Color(0xFF6366F1), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Number (Verified)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                phone,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

**Update build() method to add phone display and language selector:**

```dart
// In the Column children, after _buildPhotoUpload():
const SizedBox(height: 24),
_buildPhoneDisplay(FirebaseAuth.instance.currentUser?.phoneNumber ?? 'Not verified'),
const SizedBox(height: 24),
_buildNameField(),
const SizedBox(height: 16),
// ... rest of fields ...
_buildLanguageSelector(),
const SizedBox(height: 16),
_buildReferralCodeInput(),
```

**Add language selector method:**

```dart
Widget _buildLanguageSelector() {
  final List<String> _languageOptions = ['English', 'Hindi', 'Tamil', 'Telugu', 'Kannada', 'Marathi'];
  List<String> _selectedLanguages = widget.formData['languagePreferences'] ?? [];
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Languages (Optional)',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _languageOptions.map((lang) {
          final isSelected = _selectedLanguages.contains(lang);
          return FilterChip(
            label: Text(lang),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedLanguages.add(lang);
                } else {
                  _selectedLanguages.remove(lang);
                }
              });
              widget.onDataChanged('languagePreferences', _selectedLanguages);
            },
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF6366F1),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

Widget _buildReferralCodeInput() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Referral Code (Optional)',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: TextField(
          onChanged: (value) => widget.onDataChanged('referralCode', value),
          decoration: InputDecoration(
            hintText: 'Enter referral code if you have one',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: const Icon(Icons.card_giftcard_outlined, color: Color(0xFF6366F1), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Get rewards when you refer other technicians',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: const Color(0xFF9CA3AF),
        ),
      ),
    ],
  );
}
```

### Step 2.2: Delete enhanced and hardened versions

```bash
rm lib/screens/onboarding_steps/step1_basic_identity_enhanced.dart
rm lib/screens/onboarding_steps/step1_basic_identity_hardened.dart
```

### Step 2.3: Verify

```bash
flutter analyze
# Should show 0 issues

flutter run --debug
# Test Step 1 UI
```

---

## Phase 3: Step 4 Consolidation

### Step 3.1: Update step4_bank_details.dart

**Add confirm account field and validation:**

```dart
late TextEditingController _confirmAccountController;
bool _showAccountNumber = false;
bool _showConfirmAccount = false;

// In initState:
_confirmAccountController = TextEditingController(
  text: widget.formData['confirmAccountNumber'] ?? '',
);

// In dispose:
_confirmAccountController.dispose();

// Add validation method:
String? _validateAccountMatch() {
  if (_accountNumberController.text.isEmpty || _confirmAccountController.text.isEmpty) {
    return null;
  }
  if (_accountNumberController.text != _confirmAccountController.text) {
    return 'Accounts do not match';
  }
  return null;
}
```

**Update build() to add confirm field:**

```dart
// After account number field:
const SizedBox(height: 16),
_buildMaskedField(
  controller: _confirmAccountController,
  label: 'Confirm Account Number',
  hint: 'Re-enter account number',
  icon: Icons.check_circle_outline,
  error: _validateAccountMatch(),
  showPassword: _showConfirmAccount,
  onToggle: () => setState(() => _showConfirmAccount = !_showConfirmAccount),
  onChanged: (value) {
    widget.onDataChanged('confirmAccountNumber', value);
    setState(() {});
  },
),
```

**Add masked field builder:**

```dart
Widget _buildMaskedField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  String? error,
  required bool showPassword,
  required VoidCallback onToggle,
  required Function(String) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: error != null ? Colors.red : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: !showPassword,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
              onPressed: onToggle,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            error,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.red),
          ),
        ),
    ],
  );
}
```

### Step 3.2: Delete enhanced and hardened versions

```bash
rm lib/screens/onboarding_steps/step4_bank_details_enhanced.dart
rm lib/screens/onboarding_steps/step4_bank_details_hardened.dart
```

### Step 3.3: Verify

```bash
flutter analyze
flutter run --debug
# Test Step 4 UI
```

---

## Phase 4: Step 3 & 5 Consolidation

### Step 4.1: Update step3_kyc_verification.dart

**Add PAN fields from enhanced version:**

```dart
late TextEditingController _panController;
File? _panImage;

// In initState:
_panController = TextEditingController(
  text: widget.formData['panNumber'] ?? '',
);

// In dispose:
_panController.dispose();

// Add to build() after Aadhaar fields:
const SizedBox(height: 16),
_buildTextField(
  controller: _panController,
  label: 'PAN Number (Optional)',
  hint: 'Enter PAN number',
  icon: Icons.credit_card_outlined,
  onChanged: (value) => widget.onDataChanged('panNumber', value),
),
const SizedBox(height: 16),
_buildPanImageUpload(),
```

**Add PAN image upload method:**

```dart
Widget _buildPanImageUpload() {
  return GestureDetector(
    onTap: _isPanUploading ? null : _pickPanImage,
    child: Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: _isPanUploading
          ? const Center(child: CircularProgressIndicator())
          : _panImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_panImage!, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_outlined, color: Color(0xFF6366F1), size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'Upload PAN Image',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
    ),
  );
}

Future<void> _pickPanImage() async {
  // Similar to Aadhaar image upload
}
```

### Step 4.2: Update step5_service_setup.dart

**Add price validation and new fields:**

```dart
// Add to build() method:
_buildPriceField(),
const SizedBox(height: 16),
_buildMaxDailyJobsField(),
const SizedBox(height: 16),
_buildDynamicPricingToggle(),

// Add methods:
Widget _buildPriceField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Base Price (Optional)',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final price = int.tryParse(value) ?? 0;
            if (price > 0) {
              widget.onDataChanged('basePrice', price);
            }
          },
          decoration: InputDecoration(
            hintText: 'Enter base price in rupees',
            prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF6366F1), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    ],
  );
}

Widget _buildMaxDailyJobsField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Max Daily Jobs (Optional)',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final jobs = int.tryParse(value);
            if (jobs != null && jobs > 0) {
              widget.onDataChanged('maxDailyJobs', jobs);
            }
          },
          decoration: InputDecoration(
            hintText: 'Maximum jobs per day',
            prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF6366F1), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    ],
  );
}

Widget _buildDynamicPricingToggle() {
  bool _dynamicPricing = widget.formData['dynamicPricingAllowed'] ?? false;
  
  return Row(
    children: [
      Expanded(
        child: Text(
          'Allow Dynamic Pricing',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      Switch(
        value: _dynamicPricing,
        onChanged: (value) {
          widget.onDataChanged('dynamicPricingAllowed', value);
        },
        activeColor: const Color(0xFF6366F1),
      ),
    ],
  );
}
```

### Step 4.3: Delete enhanced versions

```bash
rm lib/screens/onboarding_steps/step3_kyc_verification_enhanced.dart
rm lib/screens/onboarding_steps/step5_service_setup_enhanced.dart
```

### Step 4.4: Verify

```bash
flutter analyze
flutter run --debug
# Test Steps 3 and 5
```

---

## Phase 5: Dashboard Consolidation

### Step 5.1: Replace limited_dashboard.dart

**Option A: Use enhanced version as base**

```bash
# Backup current version
cp lib/screens/limited_dashboard.dart lib/screens/limited_dashboard_backup.dart

# Replace with enhanced version
cp lib/screens/limited_dashboard_enhanced.dart lib/screens/limited_dashboard.dart

# Update class name if needed
# Change: class LimitedDashboardScreen → class LimitedDashboard
```

### Step 5.2: Delete enhanced version

```bash
rm lib/screens/limited_dashboard_enhanced.dart
```

### Step 5.3: Verify

```bash
flutter analyze
flutter run --debug
# Test limited dashboard display
```

---

## Phase 6: Image Utilities Consolidation

### Step 6.1: Integrate image_size_guard into TechnicianProvider

**File:** `lib/core/providers/technician_provider.dart`

**Add import:**

```dart
import 'package:technician_app/core/utils/image_size_guard.dart';
```

**Update uploadDocumentImage method:**

```dart
Future<String> uploadDocumentImage(File imageFile, String documentType) async {
  try {
    // Validate and compress image
    final validatedFile = await ImageSizeGuard.validateAndCompress(imageFile);
    
    // Rest of upload logic...
  } catch (e) {
    debugPrint('[TechnicianProvider] Image validation error: $e');
    rethrow;
  }
}
```

### Step 6.2: Delete unused utilities

```bash
rm lib/core/services/image_compression_service.dart
```

### Step 6.3: Verify

```bash
flutter analyze
flutter run --debug
# Test image upload in Step 1
# Verify image is < 500KB
```

---

## Phase 7: Routing Cleanup

### Step 7.1: Update main.dart

**Remove legacy route:**

```dart
// DELETE THIS LINE:
'/onboarding_legacy': (_) => const OnboardingScreen(),
```

### Step 7.2: Delete legacy screen

```bash
rm lib/screens/onboarding_screen.dart
```

### Step 7.3: Verify

```bash
flutter analyze
# Should show 0 issues

flutter run --debug
# Test app startup
# Test login flow
# Test onboarding flow
```

---

## Final Verification

### Run Complete Test Suite

```bash
# Analyze
flutter analyze
# Should show 0 issues

# Get dependencies
flutter pub get

# Run tests
flutter test

# Build APK
flutter build apk --analyze-size

# Check for unused imports
dart fix --dry-run
```

### Verify All Features

- [ ] App starts correctly
- [ ] Login flow works
- [ ] Onboarding Step 1 displays correctly
- [ ] Phone display shows verified badge
- [ ] Language selector works
- [ ] Referral code input works
- [ ] Step 3 shows PAN fields
- [ ] Step 4 shows confirm account field
- [ ] Step 5 shows price and max jobs fields
- [ ] Image upload validates size
- [ ] Limited dashboard displays correctly
- [ ] Full onboarding flow completes
- [ ] No broken imports
- [ ] No dead code

---

## Rollback Plan

If anything breaks:

```bash
# Restore from git
git checkout -- .

# Or restore specific files
git checkout -- lib/core/models/technician.dart
git checkout -- lib/screens/onboarding_steps/
```

---

## Success Criteria

✅ All consolidations complete  
✅ `flutter analyze` returns 0 issues  
✅ All tests pass  
✅ Bundle size reduced  
✅ Full onboarding flow works  
✅ No broken imports  
✅ No dead code  

---

**Estimated Total Time:** 2-3 hours  
**Recommended:** Execute one phase per session  
**Commit:** After each successful phase
