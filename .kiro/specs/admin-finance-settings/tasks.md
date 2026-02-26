# Implementation Plan: Admin Finance & Settings Module

## Overview

This implementation plan breaks down the Admin Finance & Settings Module into discrete coding tasks. The module provides secure financial management capabilities including booking payouts, wallet withdrawals, audit logs, and platform settings. All financial write operations are processed through Firebase Cloud Functions to ensure security and proper audit trails.

## Tasks

- [x] 1. Remove System Tests Module
  - Remove all System Tests navigation entries from sidebar component
  - Delete System Tests route definitions and page components
  - Remove all System Tests related files
  - Verify no broken navigation links remain
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. Set up data models and TypeScript interfaces
  - Create TypeScript interfaces for BookingPayout, WalletWithdrawal, AuditLog, and AppSettings
  - Define status type unions and enums
  - Create Cloud Function request/response interfaces
  - Set up Firebase service initialization utilities
  - _Requirements: 2.2, 3.1, 5.2, 8.2, 9.1-9.6_

- [x] 3. Implement shared UI components
  - [x] 3.1 Create StatusBadge component with color coding for all status types
    - Support pending, processing, completed, failed, approved, rejected statuses
    - Implement size variants (sm, md, lg)
    - _Requirements: 2.2, 3.2, 5.2_
  
  - [x] 3.2 Create FilterBar component with search and filter controls
    - Implement search input with debouncing
    - Add filter dropdown controls
    - _Requirements: 2.3, 2.4, 5.3, 5.4, 8.3, 8.4, 8.5_
  
  - [x] 3.3 Create ConfirmDialog component for user confirmations
    - Support optional input fields with validation
    - Implement character count for minimum length requirements
    - Add loading states during async operations
    - _Requirements: 6.2, 7.2, 7.3, 7.4_
  
  - [x] 3.4 Create ErrorState and EmptyState components
    - Display error messages with retry buttons
    - Show contextual empty state messages with icons
    - _Requirements: 2.5, 5.5, 8.8, 13.1, 13.2, 13.3, 13.4, 14.1, 14.2, 14.3, 14.4_
  
  - [x] 3.5 Create LoadingState component with skeleton loaders
    - Implement shimmer animation effect
    - Match layout of actual content
    - _Requirements: 2.6, 5.6, 9.7, 12.1_

- [ ]* 3.6 Write unit tests for shared components
    - Test StatusBadge color mapping and rendering
    - Test FilterBar search and filter interactions
    - Test ConfirmDialog validation and submission
    - Test ErrorState and EmptyState rendering
    - _Requirements: 2.2, 2.3, 2.4, 3.2, 5.2, 5.3, 5.4_

- [x] 4. Implement Booking Payouts List Page
  - [x] 4.1 Create useBookingPayouts custom hook with Firestore real-time listeners
    - Implement query with orderBy createdAt descending
    - Add status filtering capability
    - Add search by technician name and booking ID
    - Implement pagination (20 items per page)
    - Handle loading and error states
    - Clean up listeners on unmount
    - _Requirements: 2.1, 2.3, 2.4, 18.1, 19.1, 19.5_
  
  - [x] 4.2 Create BookingPayoutsPage component
    - Display paginated list with all required fields (booking ID, technician name, amount, commission, earning, status, date)
    - Integrate FilterBar for status filtering and search
    - Add pagination controls with page numbers
    - Implement click navigation to details page
    - Show loading, error, and empty states
    - _Requirements: 2.1, 2.2, 2.5, 2.6, 2.7, 18.1, 18.4, 18.5, 18.6_
  
  - [ ]* 4.3 Write property test for list ordering consistency
    - **Property 1: List Ordering Consistency**
    - **Validates: Requirements 2.1**
  
  - [ ]* 4.4 Write property test for complete information display
    - **Property 2: Complete Information Display**
    - **Validates: Requirements 2.2**
  
  - [ ]* 4.5 Write property test for search filtering correctness
    - **Property 3: Search Filtering Correctness**
    - **Validates: Requirements 2.4**
  
  - [ ]* 4.6 Write unit tests for BookingPayoutsPage
    - Test rendering with mock data
    - Test filter and search interactions
    - Test pagination controls
    - Test navigation to details page
    - Test error and empty states
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

- [x] 5. Implement Booking Payout Details Page and Processing
  - [x] 5.1 Create processBookingPayout Cloud Function
    - Verify admin authentication and claims
    - Validate payout exists and status is pending
    - Update payout status to completed with transaction
    - Create audit log entry atomically
    - Return success/error response
    - _Requirements: 4.2, 4.3, 15.1, 15.4, 15.8, 16.1, 16.5, 16.6_
  
  - [x] 5.2 Create useProcessPayout custom hook
    - Invoke processBookingPayout Cloud Function with auth token
    - Handle loading, success, and error states
    - Return processing status and error messages
    - _Requirements: 4.2, 4.4, 4.5, 4.6, 15.8_
  
  - [x] 5.3 Create BookingPayoutDetailsPage component
    - Display all payout details (booking ID, technician info, amounts, status, timestamps)
    - Show "Mark as Paid" button conditionally for pending status
    - Implement real-time updates via Firestore listener
    - Display paid timestamp only for completed status
    - Add back navigation to list
    - Show loading and error states
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 19.1, 19.5, 25_
  
  - [ ]* 5.4 Write property test for conditional action button visibility
    - **Property 4: Conditional Action Button Visibility**
    - **Validates: Requirements 4.1**
  
  - [ ]* 5.5 Write property test for Cloud Function invocation parameters
    - **Property 5: Cloud Function Invocation with Correct Parameters**
    - **Validates: Requirements 4.2, 15.8**
  
  - [ ]* 5.6 Write property test for success response handling
    - **Property 6: Success Response Handling**
    - **Validates: Requirements 4.4**
  
  - [ ]* 5.7 Write property test for error response display
    - **Property 7: Error Response Display**
    - **Validates: Requirements 4.5**
  
  - [ ]* 5.8 Write property test for UI disabled state during operations
    - **Property 8: UI Disabled State During Operations**
    - **Validates: Requirements 4.6, 12.2, 12.3**
  
  - [ ]* 5.9 Write unit tests for payout details and processing
    - Test details page rendering with mock data
    - Test "Mark as Paid" button click and confirmation
    - Test Cloud Function success and error scenarios
    - Test loading states during processing
    - Test conditional timestamp display
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.4, 4.5, 4.6_

- [x] 6. Checkpoint - Ensure booking payouts module is working
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Implement Wallet Withdrawals List Page
  - [x] 7.1 Create useWalletWithdrawals custom hook with Firestore real-time listeners
    - Implement query with orderBy requestedAt descending
    - Add status filtering capability
    - Add search by technician name
    - Implement pagination (20 items per page)
    - Handle loading and error states
    - Clean up listeners on unmount
    - _Requirements: 5.1, 5.3, 5.4, 18.2, 19.2, 19.5_
  
  - [x] 7.2 Create WalletWithdrawalsPage component
    - Display paginated list with all required fields (technician name, amount, bank details, IFSC, status, timestamp)
    - Integrate FilterBar for status filtering and search
    - Add pagination controls
    - Implement click navigation to details page
    - Show loading, error, and empty states
    - _Requirements: 5.1, 5.2, 5.5, 5.6, 5.7, 18.2, 18.4, 18.5, 18.6_
  
  - [ ]* 7.3 Write property test for withdrawal list ordering
    - **Property 1: List Ordering Consistency**
    - **Validates: Requirements 5.1**
  
  - [ ]* 7.4 Write property test for withdrawal information display
    - **Property 2: Complete Information Display**
    - **Validates: Requirements 5.2**
  
  - [ ]* 7.5 Write unit tests for WalletWithdrawalsPage
    - Test rendering with mock data
    - Test filter and search interactions
    - Test pagination controls
    - Test navigation to details page
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

- [ ] 8. Implement Wallet Withdrawal Details Page and Actions
  - [ ] 8.1 Create approveWalletWithdrawal Cloud Function
    - Verify admin authentication and claims
    - Validate withdrawal exists and status is pending
    - Update withdrawal status to approved with transaction
    - Store optional admin notes
    - Create audit log entry atomically
    - Return success/error response
    - _Requirements: 6.3, 6.4, 15.2, 15.5, 15.8, 16.2, 16.5, 16.6_
  
  - [ ] 8.2 Create rejectWalletWithdrawal Cloud Function
    - Verify admin authentication and claims
    - Validate withdrawal exists and status is pending
    - Validate rejection reason is at least 10 characters
    - Update withdrawal status to rejected with transaction
    - Store rejection reason
    - Create audit log entry atomically
    - Return success/error response
    - _Requirements: 7.3, 7.4, 15.2, 15.5, 15.8, 16.3, 16.5, 16.6_
  
  - [ ] 8.3 Create useApproveWithdrawal and useRejectWithdrawal custom hooks
    - Invoke respective Cloud Functions with auth token
    - Handle loading, success, and error states
    - Return processing status and error messages
    - _Requirements: 6.3, 6.5, 6.6, 7.3, 7.5, 7.6, 15.8_
  
  - [ ] 8.4 Create WalletWithdrawalDetailsPage component
    - Display all withdrawal details (technician info, amount, bank details, IFSC, status)
    - Show "Approve" and "Reject" buttons conditionally for pending status
    - Implement approval dialog with optional admin notes input
    - Implement rejection dialog with required reason input (min 10 chars)
    - Add real-time updates via Firestore listener
    - Add back navigation to list
    - Show loading and error states
    - _Requirements: 6.1, 6.2, 7.1, 7.2, 7.4, 19.2, 19.5_
  
  - [ ]* 8.5 Write property test for rejection reason validation
    - **Property 14: Rejection Reason Validation**
    - **Validates: Requirements 7.4, 20.7**
  
  - [ ]* 8.6 Write property test for withdrawal action button visibility
    - **Property 4: Conditional Action Button Visibility**
    - **Validates: Requirements 6.1, 7.1**
  
  - [ ]* 8.7 Write unit tests for withdrawal details and actions
    - Test details page rendering with mock data
    - Test approve button with notes dialog
    - Test reject button with reason validation
    - Test Cloud Function success and error scenarios
    - Test loading states during processing
    - _Requirements: 6.1, 6.2, 6.3, 6.5, 6.6, 7.1, 7.2, 7.3, 7.5, 7.6_

- [ ] 9. Checkpoint - Ensure wallet withdrawals module is working
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Implement Audit Logs Page
  - [ ] 10.1 Create useAuditLogs custom hook with Firestore real-time listeners
    - Implement query with orderBy createdAt descending
    - Add action type filtering (payout_processed, withdrawal_approved, withdrawal_rejected, settings_updated)
    - Add entity type filtering (booking_payout, wallet_withdrawal, app_settings)
    - Add date range filtering
    - Implement pagination (50 items per page)
    - Handle loading and error states
    - Clean up listeners on unmount
    - _Requirements: 8.1, 8.3, 8.4, 8.5, 18.3, 19.3, 19.5_
  
  - [ ] 10.2 Create AuditLogsPage component
    - Display paginated list with all required fields (admin name, action type, entity type, entity ID, timestamp, IP)
    - Implement multi-dimensional FilterBar (action type, entity type, date range)
    - Add expandable metadata view for each log entry
    - Ensure read-only display (no edit/delete buttons)
    - Add pagination controls
    - Show loading, error, and empty states with filter reset option
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 18.3, 18.4, 18.5, 18.6_
  
  - [ ]* 10.3 Write property test for audit log ordering
    - **Property 1: List Ordering Consistency**
    - **Validates: Requirements 8.1**
  
  - [ ]* 10.4 Write property test for audit log information display
    - **Property 2: Complete Information Display**
    - **Validates: Requirements 8.2**
  
  - [ ]* 10.5 Write unit tests for AuditLogsPage
    - Test rendering with mock data
    - Test multi-dimensional filtering
    - Test date range filtering
    - Test expandable metadata view
    - Test read-only enforcement (no edit/delete buttons)
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8_

- [ ] 11. Implement Settings Page
  - [ ] 11.1 Create updateAppSettings Cloud Function
    - Verify admin authentication and claims
    - Validate commission percentage (0-100)
    - Validate email format
    - Validate phone number format
    - Validate minimum withdrawal amount (positive number)
    - Update settings document with transaction
    - Create audit log entry atomically
    - Return success/error response
    - _Requirements: 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 15.3, 15.6, 15.8, 16.4, 16.5, 16.6_
  
  - [ ] 11.2 Create useAppSettings custom hook with Firestore real-time listener
    - Subscribe to appSettings/config document
    - Handle loading and error states
    - Clean up listener on unmount
    - _Requirements: 9.1-9.7, 19.4, 19.5_
  
  - [ ] 11.3 Create useSettingsForm custom hook
    - Manage form state (values, errors, touched)
    - Implement inline validation for all fields
    - Validate commission percentage (0-100)
    - Validate email format
    - Validate phone number format
    - Validate minimum withdrawal amount (positive)
    - Return form state and handlers
    - _Requirements: 10.2, 10.3, 10.4, 10.5, 20.1, 20.2, 20.3, 20.4, 20.5, 20.6_
  
  - [ ] 11.4 Create useUpdateSettings custom hook
    - Invoke updateAppSettings Cloud Function with auth token
    - Handle loading, success, and error states
    - Preserve form state on error
    - _Requirements: 10.6, 10.8, 10.9, 10.10, 15.8_
  
  - [ ] 11.5 Create SettingsPage component
    - Display current settings (commission, phone, email, maintenance mode, min withdrawal, last updated)
    - Implement edit mode with form inputs
    - Show inline validation errors below fields
    - Disable save button when validation errors exist
    - Display loading indicator during save
    - Show success message on successful update
    - Show error message and retain edit mode on failure
    - Add real-time settings updates
    - _Requirements: 9.1-9.8, 10.1, 10.8, 10.9, 10.10, 19.4, 20.5, 20.6_
  
  - [ ]* 11.6 Write property test for commission percentage validation
    - **Property 10: Commission Percentage Validation**
    - **Validates: Requirements 10.2, 20.1**
  
  - [ ]* 11.7 Write property test for phone number validation
    - **Property 11: Phone Number Format Validation**
    - **Validates: Requirements 10.3, 20.2**
  
  - [ ]* 11.8 Write property test for email validation
    - **Property 12: Email Format Validation**
    - **Validates: Requirements 10.4, 20.3**
  
  - [ ]* 11.9 Write property test for positive number validation
    - **Property 13: Positive Number Validation**
    - **Validates: Requirements 10.5, 20.4**
  
  - [ ]* 11.10 Write property test for save button disabled state
    - **Property 23: Save Button Disabled on Validation Errors**
    - **Validates: Requirements 20.6**
  
  - [ ]* 11.11 Write unit tests for SettingsPage
    - Test settings display with mock data
    - Test edit mode activation
    - Test inline validation for all fields
    - Test save button disabled state with errors
    - Test successful save flow
    - Test error handling and form state preservation
    - _Requirements: 9.1-9.8, 10.1, 10.2, 10.3, 10.4, 10.5, 10.8, 10.9, 10.10_

- [ ] 12. Checkpoint - Ensure audit logs and settings modules are working
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Update navigation structure
  - [ ] 13.1 Update Sidebar component with new navigation structure
    - Add "Finance" section with "Booking Payouts" and "Wallet Withdrawals" links
    - Add "System" section with "Audit Logs" and "Settings" links
    - Remove any remaining System Tests navigation entries
    - Implement active navigation highlighting
    - _Requirements: 1.1, 17.1, 17.2, 17.3, 17.4, 17.5, 17.6_
  
  - [ ]* 13.2 Write property test for active navigation highlighting
    - **Property 17: Active Navigation Highlighting**
    - **Validates: Requirements 17.5**
  
  - [ ]* 13.3 Write unit tests for navigation structure
    - Test Finance section links render correctly
    - Test System section links render correctly
    - Test System Tests links are not present
    - Test active navigation highlighting
    - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5, 17.6_

- [ ] 14. Implement responsive design and additional features
  - [ ] 14.1 Add responsive layout support
    - Implement collapsible sidebar for mobile (< 768px)
    - Implement persistent sidebar for tablet/desktop (>= 768px)
    - Add horizontal scrolling for tables on small screens
    - Stack form fields vertically on mobile
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_
  
  - [ ] 14.2 Implement pagination scroll behavior
    - Scroll to top of content area on page change
    - Use smooth scrolling animation
    - _Requirements: 18.6_
  
  - [ ] 14.3 Add timeout warnings for long operations
    - Display timeout warning after 10 seconds
    - Provide retry option
    - _Requirements: 12.4_
  
  - [ ] 14.4 Implement comprehensive error logging
    - Log all errors to browser console with context
    - Include component name, operation, timestamp, and user ID
    - _Requirements: 13.5_
  
  - [ ]* 14.5 Write property test for timeout warning display
    - **Property 19: Timeout Warning Display**
    - **Validates: Requirements 12.4**
  
  - [ ]* 14.6 Write property test for error retry availability
    - **Property 20: Error Retry Availability**
    - **Validates: Requirements 13.1, 13.2, 13.3, 13.4**
  
  - [ ]* 14.7 Write property test for console error logging
    - **Property 21: Console Error Logging**
    - **Validates: Requirements 13.5**
  
  - [ ]* 14.8 Write property test for page change scroll behavior
    - **Property 18: Page Change Scroll Behavior**
    - **Validates: Requirements 18.6**
  
  - [ ]* 14.9 Write unit tests for responsive and additional features
    - Test responsive layout breakpoints
    - Test pagination scroll behavior
    - Test timeout warning display
    - Test error logging functionality
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 12.4, 13.5, 18.6_

- [ ] 15. Implement pagination property tests
  - [ ]* 15.1 Write property test for pagination item count
    - **Property 9: Pagination Item Count**
    - **Validates: Requirements 18.1, 18.2, 18.3**
  
  - [ ]* 15.2 Write property test for real-time data updates
    - **Property 15: Real-Time Data Updates**
    - **Validates: Requirements 19.1, 19.2, 19.3, 19.4**
  
  - [ ]* 15.3 Write property test for listener cleanup
    - **Property 16: Listener Cleanup on Unmount**
    - **Validates: Requirements 19.5**
  
  - [ ]* 15.4 Write property test for authentication token inclusion
    - **Property 24: Authentication Token Inclusion**
    - **Validates: Requirements 15.8**
  
  - [ ]* 15.5 Write property test for conditional timestamp display
    - **Property 25: Conditional Timestamp Display**
    - **Validates: Requirements 3.3**

- [ ] 16. Set up Firestore security rules and indexes
  - [ ] 16.1 Update Firestore security rules
    - Add rules for bookingPayouts collection (read for admins, no direct writes)
    - Add rules for walletWithdrawals collection (read for admins, no direct writes)
    - Add rules for auditLogs collection (read for admins, no direct writes)
    - Add rules for appSettings document (read for admins, no direct writes)
    - Deploy security rules to Firebase
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7_
  
  - [ ] 16.2 Create Firestore indexes
    - Create index for bookingPayouts: status (asc) + createdAt (desc)
    - Create index for bookingPayouts: technicianId (asc) + createdAt (desc)
    - Create index for walletWithdrawals: status (asc) + requestedAt (desc)
    - Create index for walletWithdrawals: technicianId (asc) + requestedAt (desc)
    - Create index for auditLogs: actionType (asc) + createdAt (desc)
    - Create index for auditLogs: entityType (asc) + createdAt (desc)
    - Create index for auditLogs: adminId (asc) + createdAt (desc)
    - Deploy indexes to Firebase
    - _Requirements: 2.1, 2.3, 5.1, 5.3, 8.1, 8.3, 8.4_

- [ ] 17. Deploy Cloud Functions
  - Deploy processBookingPayout function to Firebase
  - Deploy approveWalletWithdrawal function to Firebase
  - Deploy rejectWalletWithdrawal function to Firebase
  - Deploy updateAppSettings function to Firebase
  - Verify all functions are callable and have correct permissions
  - _Requirements: 4.2, 6.3, 7.3, 10.6, 15.1, 15.2, 15.3_

- [ ] 18. Final checkpoint and integration testing
  - Ensure all unit tests pass
  - Ensure all property-based tests pass
  - Test complete user flows (process payout, approve withdrawal, reject withdrawal, update settings)
  - Verify real-time updates work across all modules
  - Test error handling and retry functionality
  - Verify responsive design on multiple screen sizes
  - Test navigation and active state highlighting
  - Ensure all audit logs are created correctly
  - Ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties across all inputs
- Unit tests validate specific examples, edge cases, and integration points
- All financial write operations must go through Cloud Functions (never direct Firestore writes)
- Real-time listeners must be cleaned up on component unmount to prevent memory leaks
- All Cloud Function invocations must include admin authentication tokens
