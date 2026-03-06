# Technician Matching Update - State + District Requirement

## Overview
Updated technician matching to require BOTH state AND district to be the same as customer location for more precise location-based matching.

## Changes Made

### 1. Customer App - Urgent Booking Query
**File:** `apps/customer_app/lib/features/urgent/urgent_booking_screen.dart`

**Changes:**
- Added `_userState` variable to store customer's state
- Updated `_loadUserData()` to fetch both state and district from customer profile
- Updated technician query to filter by both state and district:
  ```dart
  .where('state', isEqualTo: _userState)
  .where('district', isEqualTo: _userDistrict)
  ```
- Updated error messages to show both state and district

### 2. Customer App - FirestoreService (Already Complete)
**File:** `apps/customer_app/lib/core/services/firestore_service.dart`

**Status:** ✅ Already saves both state and district in `savePrimaryAddressToProfile()` method

### 3. Technician App - Onboarding Service
**File:** `apps/technician_app/lib/core/services/onboarding_service.dart`

**Changes:**
- Updated `saveBasicDetails()` method to accept `state` parameter
- Cloud Function call now includes both state and district

### 4. Technician App - Basic Identity Step
**File:** `apps/technician_app/lib/screens/onboarding_steps/step1_basic_identity.dart`

**Changes:**
- Replaced single "City" text field with `LocationSelector` widget
- Added state and district variables
- Updated form data handling to save both state and district

### 5. Technician App - Onboarding Flow
**File:** `apps/technician_app/lib/screens/technician_onboarding_flow_screen.dart`

**Changes:**
- Added state to form data initialization
- Updated step 0 data to include both state and district

### 6. Technician App - Model Update
**File:** `apps/technician_app/lib/core/models/technician.dart`

**Changes:**
- Added `state` field to Technician model
- Updated constructor, fromFirestore, toMap, and copyWith methods

## Testing Scenarios

### Expected Behavior:
1. **Customer state = jharkhand, district = deoghar**
   - **Technician A:** state = jharkhand, district = deoghar → ✅ SHOULD APPEAR
   - **Technician B:** state = bihar, district = deoghar → ❌ SHOULD NOT APPEAR  
   - **Technician C:** state = jharkhand, district = dumka → ❌ SHOULD NOT APPEAR

### Test Steps:
1. Run `flutter clean && flutter pub get && flutter run`
2. Complete customer profile with state and district
3. Test urgent booking to verify only matching technicians appear
4. Complete technician onboarding with state and district selection

## Benefits
- ✅ Eliminates cross-state district conflicts
- ✅ More precise location-based matching
- ✅ Consistent state + district requirement across both apps
- ✅ Reliable technician filtering

## Notes
- Customer app already had proper state + district saving
- Technician app needed updates to collect and store state information
- Both apps now consistently require state + district for matching