# Implementation Plan

## Overview

This task list implements the architectural refactoring to eliminate clean architecture violations in the HomeFix customer app. The implementation follows a 5-phase approach: extend services, refactor booking creation, refactor user profile access, refactor technician queries, and code cleanup.

---

## Phase 0: Exploration and Preservation Tests

- [x] 1. Audit architectural violations (Bug Condition exploration)
  - **Property 1: Bug Condition** - Direct Firestore Access and Function Call Violations
  - **CRITICAL**: This audit MUST document violations in unfixed code - findings confirm the bug exists
  - **DO NOT attempt to fix violations during this audit**
  - **NOTE**: This audit establishes the baseline for validation after implementation
  - **GOAL**: Surface all instances of architectural violations across the codebase
  - **Audit Approach**: Use static analysis to find all violations systematically
  - Search for `FirebaseFirestore.instance` in `apps/customer_app/lib/features/**/*.dart` and `apps/customer_app/lib/core/widgets/**/*.dart`
  - Search for `FunctionsHelper.getCallable` in UI components (not in service layer)
  - Run `dart analyze` to find unused imports, variables, and functions
  - Document all violations with file paths and line numbers
  - Verify violations match the Bug Condition specification from design (isBugCondition pseudocode)
  - Run audit on UNFIXED code
  - **EXPECTED OUTCOME**: Audit FINDS violations (this is correct - it proves the architectural debt exists)
  - Document findings: expected violations in urgent_booking_screen.dart:44, customer_booking_screen.dart:512, etc.
  - Mark task complete when audit is complete and violations are documented
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10, 1.11_

- [ ] 2. Test functional behavior preservation (BEFORE implementing fix)
  - **Property 2: Preservation** - Functional Behavior Baseline
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for all user interactions
  - Test booking creation through customer_booking_screen - observe validation, error messages, success flow
  - Test booking creation through urgent_booking_screen - observe validation, error messages, success flow
  - Test user profile loading in urgent_booking_screen - observe data structure and error handling
  - Test technician queries in urgent_booking_screen - observe filtering and real-time updates
  - Test category display, custom requests, and banners - observe data fetching patterns
  - Document observed behavior patterns from Preservation Requirements in design
  - Measure baseline performance (load times, query times) for comparison after refactoring
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS and document baseline behavior (this confirms what must be preserved)
  - Mark task complete when baseline behavior is documented and tests pass on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11, 3.12_

---

## Phase 1: Extend FirestoreService with Missing Methods

- [-] 3. Extend FirestoreService with missing data access methods

  - [x] 3.1 Add getUserProfile method to FirestoreService
    - File: `apps/customer_app/lib/core/services/firestore_service.dart`
    - Add method: `Future<Map<String, dynamic>?> getUserProfile(String userId)`
    - Implementation: Wrap `_db.collection('customers').doc(userId).get()` pattern from urgent_booking_screen.dart:44
    - Return `doc.data()` or null if document doesn't exist
    - Add error handling for Firestore exceptions
    - _Bug_Condition: Replaces direct FirebaseFirestore.instance access in UI components_
    - _Expected_Behavior: All user profile access flows through FirestoreService_
    - _Preservation: Returns identical data structure as direct Firestore query_
    - _Requirements: 1.1, 2.1, 3.1, 3.2_

  - [x] 3.2 Add streamOnlineTechnicians method to FirestoreService
    - File: `apps/customer_app/lib/core/services/firestore_service.dart`
    - Add method: `Stream<List<Map<String, dynamic>>> streamOnlineTechnicians({required String state, required String district})`
    - Implementation: Wrap technician query pattern from urgent_booking_screen.dart:120
    - Query: `_db.collection('technicians').where('isOnline', isEqualTo: true).where('state', isEqualTo: state).where('district', isEqualTo: district)`
    - Map snapshots to list of maps with 'id' field included
    - Add error handling for stream errors
    - _Bug_Condition: Replaces direct Firestore queries for technicians in UI_
    - _Expected_Behavior: All technician queries flow through FirestoreService_
    - _Preservation: Returns identical data and updates in real-time_
    - _Requirements: 1.2, 2.2, 3.3, 3.7, 3.11_

  - [x] 3.3 Verify streamCustomRequests method exists
    - File: `apps/customer_app/lib/core/services/firestore_service.dart`
    - Check if `streamCustomRequests` method already exists
    - If not, add method: `Stream<List<Map<String, dynamic>>> streamCustomRequests(String userId)`
    - Implementation: Wrap custom_requests query pattern
    - _Bug_Condition: Replaces direct Firestore access for custom requests_
    - _Expected_Behavior: Custom requests accessed through FirestoreService_
    - _Preservation: Returns identical data structure_
    - _Requirements: 1.5, 2.5, 3.5_

  - [x] 3.4 Verify streamBanners method exists
    - File: `apps/customer_app/lib/core/services/firestore_service.dart`
    - Check if `streamBanners` method already exists
    - If not, add method: `Stream<List<Map<String, dynamic>>> streamBanners()`
    - Implementation: Wrap banners collection query pattern
    - _Bug_Condition: Replaces direct Firestore access for banners_
    - _Expected_Behavior: Banners accessed through FirestoreService_
    - _Preservation: Returns identical banner data_
    - _Requirements: 1.6, 2.6, 3.6_

  - [ ] 3.5 Write unit tests for new FirestoreService methods
    - File: `apps/customer_app/test/core/services/firestore_service_test.dart`
    - Test getUserProfile with valid userId, invalid userId, and missing document
    - Test streamOnlineTechnicians with various state/district combinations
    - Test error handling for all new methods
    - Mock Firestore using fake_cloud_firestore or mockito
    - _Requirements: 2.1, 2.2, 2.5, 2.6_

---

## Phase 2: Refactor Booking Creation to Use BookingProvider

- [ ] 4. Refactor booking creation to use BookingProvider

  - [x] 4.1 Update BookingProvider to support urgent bookings
    - File: `apps/customer_app/lib/core/providers/booking_provider.dart`
    - Add optional `isUrgent` parameter to `createBookingRequest` method
    - Ensure method passes `isUrgent` flag to backend function
    - Maintain identical validation logic
    - Maintain identical error handling
    - _Bug_Condition: Centralizes booking creation logic in one place_
    - _Expected_Behavior: All booking creation flows through BookingProvider_
    - _Preservation: Booking validation and error handling remain unchanged_
    - _Requirements: 1.7, 1.8, 2.7, 2.8, 3.1, 3.9_

  - [x] 4.2 Refactor customer_booking_screen to use BookingProvider
    - File: `apps/customer_app/lib/features/booking/presentation/customer_booking_screen.dart`
    - Function: `_createBooking` (around line 512)
    - Replace `FunctionsHelper.getCallable('createBookingRequest')` with `Provider.of<BookingProvider>(context, listen: false).createBookingRequest()`
    - Extract service details into proper parameters for BookingProvider
    - Maintain identical error handling and user feedback
    - Remove direct FunctionsHelper import if no longer needed
    - _Bug_Condition: Removes direct Cloud Function call from UI_
    - _Expected_Behavior: Booking creation uses service layer_
    - _Preservation: User experience and validation remain identical_
    - _Requirements: 1.7, 2.7, 3.1, 3.9_

  - [x] 4.3 Refactor urgent_booking_screen to use BookingProvider
    - File: `apps/customer_app/lib/features/urgent/urgent_booking_screen.dart`
    - Function: `_createUrgentBooking` (around line 351)
    - Replace `FunctionsHelper.getCallable('createBookingRequest')` with `Provider.of<BookingProvider>(context, listen: false).createBookingRequest(isUrgent: true)`
    - Extract service details into proper parameters
    - Maintain identical error handling and user feedback
    - Remove direct FunctionsHelper import if no longer needed
    - _Bug_Condition: Removes direct Cloud Function call from UI_
    - _Expected_Behavior: Urgent booking creation uses service layer_
    - _Preservation: User experience and validation remain identical_
    - _Requirements: 1.8, 2.8, 3.1, 3.9_

  - [ ] 4.4 Write integration tests for booking creation flows
    - File: `apps/customer_app/test/integration/booking_creation_test.dart`
    - Test booking creation through customer_booking_screen
    - Test urgent booking creation through urgent_booking_screen
    - Verify identical validation and error handling
    - Mock BookingProvider and verify correct parameters passed
    - _Requirements: 2.7, 2.8, 3.1_

---

## Phase 3: Refactor User Profile Access to Use FirestoreService

- [ ] 5. Refactor user profile access to use FirestoreService

  - [x] 5.1 Refactor urgent_booking_screen user profile loading
    - File: `apps/customer_app/lib/features/urgent/urgent_booking_screen.dart`
    - Function: `_loadUserData` (around line 44)
    - Replace `FirebaseFirestore.instance.collection('customers').doc(user.uid).get()` with `FirestoreService().getUserProfile(user.uid)`
    - Maintain identical error handling
    - Keep same state management logic (setState calls)
    - Remove direct cloud_firestore import if no longer needed
    - _Bug_Condition: Removes direct Firestore access from UI_
    - _Expected_Behavior: User profile access flows through FirestoreService_
    - _Preservation: User data structure and error handling remain identical_
    - _Requirements: 1.1, 2.1, 3.2, 3.9_

  - [x] 5.2 Refactor customer_booking_screen user address fetching
    - File: `apps/customer_app/lib/features/booking/presentation/customer_booking_screen.dart`
    - Function: `_createBooking` (user address query)
    - Replace direct Firestore query with `FirestoreService().getUserProfile(user.uid)`
    - Extract address from result
    - Maintain identical error handling
    - _Bug_Condition: Removes direct Firestore access from UI_
    - _Expected_Behavior: User address access flows through FirestoreService_
    - _Preservation: Address data structure remains identical_
    - _Requirements: 1.1, 2.1, 3.2_

  - [ ] 5.3 Search for other user profile access patterns
    - Search codebase for `FirebaseFirestore.instance.collection('customers')` in UI components
    - Refactor any additional instances to use FirestoreService.getUserProfile
    - Document all changes
    - _Requirements: 1.1, 2.1_

---

## Phase 4: Refactor Technician Queries to Use FirestoreService

- [ ] 6. Refactor technician queries to use FirestoreService

  - [x] 6.1 Refactor urgent_booking_screen technician list
    - File: `apps/customer_app/lib/features/urgent/urgent_booking_screen.dart`
    - Function: `_buildTechnicianList` (around line 120)
    - Replace `FirebaseFirestore.instance.collection('technicians')` stream with `FirestoreService().streamOnlineTechnicians(state: _userState, district: _userDistrict)`
    - Maintain identical StreamBuilder logic
    - Keep same error handling and loading states
    - Remove direct cloud_firestore import if no longer needed
    - _Bug_Condition: Removes direct Firestore stream from UI_
    - _Expected_Behavior: Technician queries flow through FirestoreService_
    - _Preservation: Technician data and real-time updates remain identical_
    - _Requirements: 1.2, 2.2, 3.3, 3.7, 3.11_

  - [ ] 6.2 Search for other technician query patterns
    - Search codebase for `FirebaseFirestore.instance.collection('technicians')` in UI components
    - Refactor any additional instances to use FirestoreService methods
    - Document all changes
    - _Requirements: 1.2, 2.2_

---

## Phase 5: Code Cleanup (Remove Unused Imports, Variables, Functions)

- [-] 7. Remove unused code and imports

  - [x] 7.1 Remove unused cloud_firestore imports
    - Run `dart analyze` to find unused imports
    - Remove `import 'package:cloud_firestore/cloud_firestore.dart'` from UI files after refactoring
    - Expected: 47 instances based on bug description
    - Verify app still compiles after removal
    - _Bug_Condition: Removes code bloat from unused imports_
    - _Expected_Behavior: Codebase contains zero unused imports_
    - _Preservation: No functional changes_
    - _Requirements: 1.9, 2.9_

  - [x] 7.2 Remove unused FunctionsHelper imports
    - Search for `import 'package:customer_app/core/helpers/functions_helper.dart'` in files that no longer use it
    - Remove imports from customer_booking_screen and urgent_booking_screen if no longer needed
    - Verify app still compiles
    - _Requirements: 1.9, 2.9_

  - [ ] 7.3 Remove unused variables
    - Run `dart analyze` to find unused variables
    - Remove variables that are no longer referenced
    - Expected: 15 instances based on bug description
    - Verify app still compiles and tests pass
    - _Bug_Condition: Removes code bloat from unused variables_
    - _Expected_Behavior: Codebase contains zero unused variables_
    - _Preservation: No functional changes_
    - _Requirements: 1.10, 2.10_

  - [ ] 7.4 Remove unused functions
    - Run `dart analyze` to find unused functions
    - Remove functions that are no longer called
    - Expected: 5 instances based on bug description
    - Verify app still compiles and tests pass
    - _Bug_Condition: Removes code bloat from unused functions_
    - _Expected_Behavior: Codebase contains zero unused functions_
    - _Preservation: No functional changes_
    - _Requirements: 1.11, 2.11_

  - [ ] 7.5 Run final code analysis
    - Run `dart analyze` on entire customer_app
    - Verify zero unused imports, variables, and functions
    - Verify zero linting errors
    - Document final analysis results
    - _Requirements: 2.9, 2.10, 2.11_

---

## Phase 6: Validation and Testing

- [ ] 8. Validate bug condition fix and preservation

  - [ ] 8.1 Verify architectural violations are eliminated
    - **Property 1: Expected Behavior** - Service Layer Enforcement
    - **IMPORTANT**: Re-run the SAME audit from task 1 - do NOT create a new audit
    - The audit from task 1 identifies architectural violations
    - When this audit passes (finds zero violations), it confirms the expected behavior is satisfied
    - Search for `FirebaseFirestore.instance` in UI components
    - Search for `FunctionsHelper.getCallable` in UI components (not in service layer)
    - Run `dart analyze` to verify zero unused imports, variables, functions
    - **EXPECTED OUTCOME**: Audit PASSES with zero violations (confirms bug is fixed)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 2.11_

  - [ ] 8.2 Verify functional behavior preservation
    - **Property 2: Preservation** - Functional Behavior Unchanged
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation tests from task 2 on FIXED code
    - Test booking creation through customer_booking_screen - verify identical behavior
    - Test booking creation through urgent_booking_screen - verify identical behavior
    - Test user profile loading - verify identical data structure
    - Test technician queries - verify identical filtering and real-time updates
    - Test category display, custom requests, banners - verify identical behavior
    - Compare performance metrics with baseline from task 2 (< 50ms difference acceptable)
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all functionality works identically to baseline
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11, 3.12_

  - [ ] 8.3 Run full integration test suite
    - Run all existing integration tests for customer_app
    - Verify all tests pass
    - Document any test failures and investigate root cause
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [ ] 8.4 Perform manual smoke testing
    - Test complete booking flow from service selection to payment
    - Test urgent booking flow
    - Test user profile viewing and editing
    - Test technician browsing and filtering
    - Test category navigation
    - Test custom request creation and viewing
    - Test banner display and interaction
    - Verify no visual regressions or UI glitches
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.8_

---

## Phase 7: Checkpoint

- [ ] 9. Final checkpoint - Ensure all tests pass and code quality is maintained
  - Verify all unit tests pass
  - Verify all integration tests pass
  - Verify all preservation tests pass
  - Verify `dart analyze` reports zero issues
  - Verify app builds successfully for Android and iOS
  - Verify no performance degradation (compare with baseline from task 2)
  - Document final status and any remaining concerns
  - Ask user if questions arise or if ready to deploy
  - _Requirements: All requirements 1.1-3.12_

