# Implementation Plan: Admin Panel Google Login

## Overview

This implementation plan breaks down the Google Sign-In feature into discrete, incremental coding tasks. Each task builds on previous work, with testing integrated throughout to catch errors early. The plan follows a bottom-up approach: utilities first, then components, then integration.

## Tasks

- [x] 1. Create authentication utility functions
  - Create `apps/admin_panel/src/lib/auth.ts` with reusable auth functions
  - Implement `signInWithGoogle()` using Firebase `signInWithPopup` and `GoogleAuthProvider`
  - Implement `verifyAdminClaim(user)` to check admin custom claim
  - Implement `signOutUser()` to handle sign-out and state cleanup
  - Implement `getAdminToken(user)` to force token refresh and retrieve claims
  - Export all functions for use in components
  - _Requirements: 1.1, 1.2, 2.1, 2.2, 6.1_

- [ ]* 1.1 Write property test for admin claim verification
  - **Property 1: Admin Claim Authorization**
  - **Validates: Requirements 2.2, 2.3, 2.4, 2.5**
  - Test that users with admin=true get access, admin=false get denied
  - Use fast-check to generate random user objects with varying admin claims
  - Configure for minimum 100 iterations

- [ ]* 1.2 Write unit tests for auth utility functions
  - Test `signInWithGoogle()` calls Firebase with correct provider
  - Test `verifyAdminClaim()` returns true/false based on claim
  - Test `signOutUser()` calls Firebase signOut
  - Test error handling for network failures and popup blocked scenarios
  - _Requirements: 1.4, 5.1, 5.4_

- [x] 2. Update AuthProvider component with Google auth support
  - Open `apps/admin_panel/src/components/AuthProvider.tsx`
  - Add `signOut` function to AuthContext interface and implementation
  - Enhance admin claim verification to handle token refresh failures
  - Improve error handling in `onAuthStateChanged` callback
  - Ensure unauthorized users (admin !== true) are signed out immediately
  - Export `signOut` from context for use in components
  - _Requirements: 2.3, 2.4, 2.5, 4.3, 6.3_

- [ ]* 2.1 Write property test for unauthenticated redirect
  - **Property 2: Unauthenticated User Redirect**
  - **Validates: Requirements 4.4, 6.5**
  - Test that any protected route redirects when user is not authenticated
  - Use fast-check to generate random protected route paths
  - Configure for minimum 100 iterations

- [ ]* 2.2 Write property test for sign-out state cleanup
  - **Property 4: Sign-Out State Cleanup**
  - **Validates: Requirements 6.3**
  - Test that any auth state is cleared after sign-out
  - Use fast-check to generate random auth states
  - Verify user, isAdmin, and loading are all reset
  - Configure for minimum 100 iterations

- [x] 3. Modernize login page UI and add Google sign-in
  - Open `apps/admin_panel/src/app/login/page.tsx`
  - Remove the "Tailwind Active" test div completely
  - Import `signInWithGoogle` and `verifyAdminClaim` from auth utilities
  - Add `handleGoogleSignIn` function that calls `signInWithGoogle()`
  - After successful Google sign-in, verify admin claim using `verifyAdminClaim()`
  - If admin claim is false, sign out user and show "Access Denied" error
  - If admin claim is true, navigate to `/dashboard`
  - Add Google sign-in button using existing Button component with outline variant
  - Add "OR" divider between Google button and email/password form
  - Ensure error state is cleared when user starts new sign-in attempt
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.3, 2.4, 3.2, 3.4, 5.3, 5.5_

- [ ]* 3.1 Write property test for error state clearing
  - **Property 3: Error State Clearing**
  - **Validates: Requirements 5.5**
  - Test that any error message is cleared when new sign-in starts
  - Use fast-check to generate random error messages
  - Configure for minimum 100 iterations

- [ ]* 3.2 Write property test for authentication error handling
  - **Property 5: Authentication Error Handling**
  - **Validates: Requirements 1.4, 5.1, 5.2, 5.4**
  - Test that all Firebase error codes produce appropriate messages
  - Use fast-check to generate different error codes
  - Verify user cancellation produces no error message
  - Configure for minimum 100 iterations

- [ ]* 3.3 Write unit tests for login page
  - Test Google sign-in button is rendered
  - Test "Tailwind Active" text is not present
  - Test both Google and email/password options are displayed
  - Test error messages display correctly for different scenarios
  - Test navigation to dashboard on successful admin login
  - Test sign-out and error display for non-admin users
  - _Requirements: 1.1, 3.2, 3.4, 5.3_

- [x] 4. Add centralized error handling
  - Create error handler function in `apps/admin_panel/src/lib/auth.ts`
  - Implement `handleAuthError(error: FirebaseError): string` function
  - Map Firebase error codes to user-friendly messages
  - Handle popup-blocked, network-failed, too-many-requests, user-cancelled
  - Return empty string for user cancellation (silent failure)
  - Export function for use in login page
  - Update login page to use centralized error handler
  - _Requirements: 1.4, 5.1, 5.2, 5.4_

- [ ]* 4.1 Write unit tests for error handler
  - Test each Firebase error code maps to correct message
  - Test user cancellation returns empty string
  - Test unknown errors return generic message
  - _Requirements: 1.4, 5.1, 5.2, 5.4_

- [x] 5. Install and configure property-based testing library
  - Install `fast-check` and `@fast-check/jest` as dev dependencies
  - Configure Jest to work with fast-check
  - Create test setup file if needed
  - Verify property tests can run with `npm test`
  - _Requirements: Testing Strategy_

- [x] 6. Checkpoint - Ensure all tests pass
  - Run all unit tests and verify they pass
  - Run all property tests and verify they pass
  - Manually test Google sign-in flow in browser
  - Verify admin users can access dashboard
  - Verify non-admin users see access denied
  - Verify "Tailwind Active" text is removed
  - Ask the user if questions arise

- [ ] 7. Final integration and polish
  - Test complete authentication flow end-to-end
  - Verify error messages are clear and helpful
  - Test responsive design on mobile, tablet, desktop
  - Verify sign-out functionality works correctly
  - Test page refresh maintains auth state for admin users
  - Ensure no hardcoded values in configuration
  - _Requirements: 3.3, 4.5, 6.2, 7.1_

- [ ]* 7.1 Write integration tests
  - Test complete Google sign-in to dashboard flow
  - Test admin claim verification with mocked Firebase
  - Test sign-out and redirect flow
  - Test error recovery scenarios
  - _Requirements: All requirements_

- [ ] 8. Final checkpoint - Production readiness
  - Run full test suite and verify all tests pass
  - Manually test all user flows (admin login, non-admin denial, sign-out)
  - Verify no console errors or warnings
  - Verify Firebase configuration is correct
  - Ensure all "Tailwind Active" test text is removed
  - Ask the user if questions arise

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties with 100+ iterations
- Unit tests validate specific examples and edge cases
- Checkpoints ensure incremental validation and user feedback
- All code uses TypeScript for type safety
- Firebase configuration is reused from existing setup (no new projects needed)
