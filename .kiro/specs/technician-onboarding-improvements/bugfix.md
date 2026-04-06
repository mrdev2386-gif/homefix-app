# Bugfix Requirements Document

## Introduction

This document addresses four identified issues in the technician onboarding system discovered during a comprehensive production audit. While the system is production-ready, these fixes will improve data quality, prevent race conditions, reduce confusion, and ensure consistency. The issues range from medium priority (validation enforcement and profile locking) to low priority (legacy function deprecation and format standardization).

The fixes target both frontend (Flutter) and backend (Cloud Functions) components to ensure systematic validation and proper state management throughout the onboarding lifecycle.

## Bug Analysis

### Current Behavior (Defect)

#### Issue 1: Step 4 Validation Not Enforced

1.1 WHEN a technician completes Step 4 (Work Portfolio) with empty or minimal data THEN the system allows progression to submission without validation errors

1.2 WHEN a technician submits their onboarding without completing Step 4 fields (experienceDescription, workPreference) THEN the system accepts the submission and marks it as complete

#### Issue 2: Profile Lock Missing After Submission

1.3 WHEN a technician submits their KYC for admin review THEN the system does not prevent further edits to the profile

1.4 WHEN a technician edits their profile while an admin is reviewing or approving it THEN the system allows the changes, potentially causing the admin to approve stale data

1.5 WHEN an admin approves a technician profile THEN the system does not lock the profile, allowing post-approval edits that may invalidate the approval

#### Issue 3: Legacy KYC Function Causes Confusion

1.6 WHEN developers or admins need to approve a technician THEN the system provides two functions (`approveKYC()` and `approveTechnician()`) without clear guidance on which to use

1.7 WHEN the `approveKYC()` function is called THEN the system executes approval logic that may differ from `approveTechnician()`, causing inconsistent approval states

#### Issue 4: Aadhaar Masking Format Inconsistency

1.8 WHEN Aadhaar numbers are masked in the frontend THEN the system may use different formats (e.g., `XXXX-XXXX-1234` vs `XXXXXXXX1234`)

1.9 WHEN Aadhaar numbers are masked in the backend THEN the system may produce a different format than the frontend, causing display inconsistencies

1.10 WHEN masked Aadhaar is displayed to users or admins THEN the system shows inconsistent formatting across different screens and contexts

### Expected Behavior (Correct)

#### Issue 1: Step 4 Validation Enforcement

2.1 WHEN a technician attempts to complete Step 4 (Work Portfolio) with empty experienceDescription THEN the system SHALL display a validation error "Experience description is required"

2.2 WHEN a technician enters an experienceDescription shorter than 20 characters THEN the system SHALL display a validation error "Description must be at least 20 characters"

2.3 WHEN a technician attempts to complete Step 4 without selecting a workPreference THEN the system SHALL display a validation error "Work type preference is required"

2.4 WHEN a technician attempts to submit onboarding without completing Step 4 validation THEN the system SHALL prevent submission and highlight missing Step 4 fields

#### Issue 2: Profile Lock Implementation

2.5 WHEN a technician submits their KYC for admin review THEN the system SHALL set `isLocked=true` in the technician document

2.6 WHEN a technician with `isLocked=true` attempts to edit their profile THEN the system SHALL prevent the edit and display "Profile is locked. Contact support to make changes."

2.7 WHEN an admin approves or rejects a technician THEN the system SHALL maintain `isLocked=true` to prevent post-decision edits

2.8 WHEN a technician needs to update their locked profile THEN the system SHALL require admin intervention to unlock (future enhancement scope)

#### Issue 3: Legacy Function Deprecation

2.9 WHEN the `approveKYC()` function is called THEN the system SHALL log a deprecation warning and redirect the call to `approveTechnician()`

2.10 WHEN developers review the codebase THEN the system SHALL clearly indicate that `approveKYC()` is deprecated with comments and documentation

2.11 WHEN the `approveKYC()` function redirects to `approveTechnician()` THEN the system SHALL pass the correct parameters and maintain identical behavior

#### Issue 4: Aadhaar Masking Standardization

2.12 WHEN Aadhaar numbers are masked in the backend THEN the system SHALL use the format `XXXX-XXXX-{last4digits}` consistently

2.13 WHEN Aadhaar numbers are masked in the frontend THEN the system SHALL use the format `XXXX-XXXX-{last4digits}` consistently

2.14 WHEN an Aadhaar number has invalid length (not 12 digits) THEN the system SHALL return the fallback mask `XXXX-XXXX-XXXX`

2.15 WHEN masked Aadhaar is displayed across different screens THEN the system SHALL show consistent formatting using the standardized masking function

### Unchanged Behavior (Regression Prevention)

#### Onboarding Flow Preservation

3.1 WHEN a technician completes Steps 1, 2, and 3 with valid data THEN the system SHALL CONTINUE TO save progress and allow navigation between steps

3.2 WHEN a technician uploads Aadhaar documents and profile photos THEN the system SHALL CONTINUE TO encrypt Aadhaar numbers and store document URLs securely

3.3 WHEN a technician resumes onboarding after closing the app THEN the system SHALL CONTINUE TO load the last completed step and saved data

#### Admin Approval Workflow Preservation

3.4 WHEN an admin approves a technician using `approveTechnician()` THEN the system SHALL CONTINUE TO set `isApproved=true`, `adminApproved=true`, `status='approved'`, `isActive=true`

3.5 WHEN an admin rejects a technician using `suspendTechnician()` THEN the system SHALL CONTINUE TO set `status='suspended'`, `isApproved=false`, `isActive=false`

3.6 WHEN an approved technician toggles their online status THEN the system SHALL CONTINUE TO allow the toggle and update `isOnline` field

#### Security Controls Preservation

3.7 WHEN a client attempts to directly set `isApproved`, `adminApproved`, or `role` fields THEN the system SHALL CONTINUE TO reject the request via server-side validation

3.8 WHEN Aadhaar numbers are stored in Firestore THEN the system SHALL CONTINUE TO encrypt them using the `encrypt()` function

3.9 WHEN admin-only functions are called without admin authentication THEN the system SHALL CONTINUE TO reject the request with authentication error

#### Data Consistency Preservation

3.10 WHEN a technician's profile is updated via Cloud Functions THEN the system SHALL CONTINUE TO use atomic Firestore updates

3.11 WHEN multiple status fields (`status`, `kycStatus`, `isApproved`, `isActive`) are updated THEN the system SHALL CONTINUE TO maintain their distinct purposes and relationships

3.12 WHEN a technician submits KYC THEN the system SHALL CONTINUE TO set `isKycComplete=true`, `onboardingStep='submitted'`, `status='pending'`
