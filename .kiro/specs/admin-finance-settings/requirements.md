# Requirements Document

## Introduction

The HomeFix Admin Panel Finance & Settings Module provides administrators with secure financial management capabilities and system configuration controls. This module enables admins to manage booking payouts to technicians, approve wallet withdrawal requests, monitor system activities through audit logs, and configure platform-wide settings. All financial operations follow a Firebase-first secure architecture where monetary transactions are processed exclusively through callable Cloud Functions, preventing direct database manipulation and ensuring proper audit trails.

## Glossary

- **Admin_Panel**: The web-based administrative interface for HomeFix platform management
- **Booking_Payout**: A payment record representing earnings owed to a technician for a completed booking
- **Wallet_Withdrawal**: A request from a technician to withdraw funds from their wallet balance
- **Audit_Log**: An immutable record of administrative actions performed in the system
- **Cloud_Function**: A Firebase callable function that executes server-side business logic with security validation
- **Payout_Status**: The current state of a payout (pending, processing, completed, failed)
- **Withdrawal_Status**: The current state of a withdrawal request (pending, approved, rejected, completed)
- **Platform_Commission**: The percentage fee charged by HomeFix on each booking transaction
- **System_Tests_Module**: The legacy testing module to be removed from the admin panel
- **App_Settings**: Platform-wide configuration parameters stored in Firestore
- **Maintenance_Mode**: A system state that prevents customer-facing operations while allowing admin access

## Requirements

### Requirement 1: Remove System Tests Module

**User Story:** As a platform administrator, I want the System Tests module removed from the admin panel, so that the interface only contains production-ready features.

#### Acceptance Criteria

1. THE Admin_Panel SHALL remove all System Tests sidebar navigation entries
2. THE Admin_Panel SHALL remove all System Tests route definitions
3. THE Admin_Panel SHALL remove all System Tests page components
4. THE Admin_Panel SHALL remove all System Tests related component files
5. WHEN the Admin_Panel loads, THE Admin_Panel SHALL NOT display any System Tests navigation or routes

### Requirement 2: Display Booking Payouts List

**User Story:** As a platform administrator, I want to view a list of all booking payouts, so that I can monitor technician earnings and payment status.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display a paginated list of booking payouts ordered by creation date descending
2. FOR EACH booking payout, THE Admin_Panel SHALL display booking ID, technician name, booking amount, platform commission, technician earning, payout status, and creation date
3. THE Admin_Panel SHALL provide filter controls for payout status (pending, processing, completed, failed)
4. THE Admin_Panel SHALL provide a search capability by technician name or booking ID
5. WHEN no payouts exist, THE Admin_Panel SHALL display an empty state message
6. WHILE loading payout data, THE Admin_Panel SHALL display a loading indicator
7. IF payout data loading fails, THEN THE Admin_Panel SHALL display an error message with retry option

### Requirement 3: Display Booking Payout Details

**User Story:** As a platform administrator, I want to view detailed information about a specific booking payout, so that I can verify payment accuracy and status.

#### Acceptance Criteria

1. WHEN an administrator selects a booking payout, THE Admin_Panel SHALL display complete payout details including booking ID, technician ID, technician name, service ID, booking amount, platform commission percentage, technician earning, payout status, payout method, creation timestamp, and paid timestamp
2. THE Admin_Panel SHALL display the payout status with appropriate visual indicators (color coding)
3. WHERE the payout status is completed, THE Admin_Panel SHALL display the paid timestamp
4. THE Admin_Panel SHALL provide a navigation option to return to the payouts list

### Requirement 4: Process Booking Payout

**User Story:** As a platform administrator, I want to mark booking payouts as paid through a secure process, so that technician payments are properly recorded and audited.

#### Acceptance Criteria

1. WHERE a booking payout has status pending, THE Admin_Panel SHALL display a "Mark as Paid" action button
2. WHEN an administrator clicks "Mark as Paid", THE Admin_Panel SHALL invoke the processBookingPayout Cloud_Function with payout ID and admin credentials
3. THE Admin_Panel SHALL NOT perform direct Firestore writes to update payout status
4. WHEN the Cloud_Function succeeds, THE Admin_Panel SHALL display a success message and refresh the payout details
5. IF the Cloud_Function fails, THEN THE Admin_Panel SHALL display the error message returned by the function
6. WHILE the Cloud_Function executes, THE Admin_Panel SHALL disable the action button and display a processing indicator

### Requirement 5: Display Wallet Withdrawals List

**User Story:** As a platform administrator, I want to view all wallet withdrawal requests, so that I can process technician payout requests.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display a paginated list of wallet withdrawals ordered by request date descending
2. FOR EACH withdrawal, THE Admin_Panel SHALL display technician name, withdrawal amount, bank account details, IFSC code, status, and request timestamp
3. THE Admin_Panel SHALL provide filter controls for withdrawal status (pending, approved, rejected, completed)
4. THE Admin_Panel SHALL provide a search capability by technician name
5. WHEN no withdrawals exist, THE Admin_Panel SHALL display an empty state message
6. WHILE loading withdrawal data, THE Admin_Panel SHALL display a loading indicator
7. IF withdrawal data loading fails, THEN THE Admin_Panel SHALL display an error message with retry option

### Requirement 6: Approve Wallet Withdrawal

**User Story:** As a platform administrator, I want to approve wallet withdrawal requests through a secure process, so that technician funds are released with proper authorization.

#### Acceptance Criteria

1. WHERE a wallet withdrawal has status pending, THE Admin_Panel SHALL display "Approve" and "Reject" action buttons
2. WHEN an administrator clicks "Approve", THE Admin_Panel SHALL prompt for optional admin notes
3. WHEN approval is confirmed, THE Admin_Panel SHALL invoke the approveWalletWithdrawal Cloud_Function with withdrawal ID, admin credentials, and admin notes
4. THE Admin_Panel SHALL NOT perform direct Firestore writes to update withdrawal status
5. WHEN the Cloud_Function succeeds, THE Admin_Panel SHALL display a success message and refresh the withdrawal details
6. IF the Cloud_Function fails, THEN THE Admin_Panel SHALL display the error message returned by the function
7. WHILE the Cloud_Function executes, THE Admin_Panel SHALL disable action buttons and display a processing indicator

### Requirement 7: Reject Wallet Withdrawal

**User Story:** As a platform administrator, I want to reject wallet withdrawal requests with a reason, so that technicians understand why their request was denied.

#### Acceptance Criteria

1. WHERE a wallet withdrawal has status pending, THE Admin_Panel SHALL display a "Reject" action button
2. WHEN an administrator clicks "Reject", THE Admin_Panel SHALL prompt for required rejection reason
3. WHEN rejection is confirmed with a reason, THE Admin_Panel SHALL invoke the rejectWalletWithdrawal Cloud_Function with withdrawal ID, admin credentials, and rejection reason
4. THE Admin_Panel SHALL NOT allow rejection without a reason
5. WHEN the Cloud_Function succeeds, THE Admin_Panel SHALL display a success message and refresh the withdrawal details
6. IF the Cloud_Function fails, THEN THE Admin_Panel SHALL display the error message returned by the function

### Requirement 8: Display Audit Logs

**User Story:** As a platform administrator, I want to view audit logs of all administrative actions, so that I can monitor system activity and ensure accountability.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display a paginated list of audit logs ordered by creation date descending
2. FOR EACH audit log, THE Admin_Panel SHALL display admin name, action type, entity type, entity ID, timestamp, and IP address
3. THE Admin_Panel SHALL provide filter controls for action type (payout_processed, withdrawal_approved, withdrawal_rejected, settings_updated)
4. THE Admin_Panel SHALL provide filter controls for entity type (booking_payout, wallet_withdrawal, app_settings)
5. THE Admin_Panel SHALL provide a date range filter for log entries
6. WHEN an administrator selects an audit log, THE Admin_Panel SHALL display complete metadata in a readable format
7. THE Admin_Panel SHALL NOT provide any edit or delete capabilities for audit logs
8. WHEN no logs match the filters, THE Admin_Panel SHALL display an empty state message

### Requirement 9: Display Platform Settings

**User Story:** As a platform administrator, I want to view current platform settings, so that I can understand the system configuration.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display current platform commission percentage
2. THE Admin_Panel SHALL display support phone number
3. THE Admin_Panel SHALL display support email address
4. THE Admin_Panel SHALL display maintenance mode status (enabled/disabled)
5. THE Admin_Panel SHALL display minimum withdrawal amount
6. THE Admin_Panel SHALL display last updated timestamp
7. WHILE loading settings data, THE Admin_Panel SHALL display a loading indicator
8. IF settings data loading fails, THEN THE Admin_Panel SHALL display an error message with retry option

### Requirement 10: Update Platform Settings

**User Story:** As a platform administrator, I want to update platform settings through a secure process, so that configuration changes are properly validated and audited.

#### Acceptance Criteria

1. THE Admin_Panel SHALL provide an edit mode for platform settings with input validation
2. THE Admin_Panel SHALL validate that platform commission percentage is between 0 and 100
3. THE Admin_Panel SHALL validate that support phone number matches a valid phone format
4. THE Admin_Panel SHALL validate that support email matches a valid email format
5. THE Admin_Panel SHALL validate that minimum withdrawal amount is a positive number
6. WHEN an administrator saves settings changes, THE Admin_Panel SHALL invoke the updateAppSettings Cloud_Function with new settings and admin credentials
7. THE Admin_Panel SHALL NOT perform direct Firestore writes to update settings
8. WHEN the Cloud_Function succeeds, THE Admin_Panel SHALL display a success message and refresh the settings display
9. IF the Cloud_Function fails, THEN THE Admin_Panel SHALL display the error message and retain the edit mode with user input
10. WHILE the Cloud_Function executes, THE Admin_Panel SHALL disable the save button and display a processing indicator

### Requirement 11: Responsive Admin UI

**User Story:** As a platform administrator, I want the admin panel to work well on different screen sizes, so that I can manage the platform from various devices.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display a responsive layout that adapts to screen widths from 320px to 2560px
2. WHEN viewed on mobile devices (width less than 768px), THE Admin_Panel SHALL display a collapsible sidebar navigation
3. WHEN viewed on tablet and desktop devices (width 768px or greater), THE Admin_Panel SHALL display a persistent sidebar navigation
4. THE Admin_Panel SHALL display data tables with horizontal scrolling on small screens
5. THE Admin_Panel SHALL stack form fields vertically on mobile devices

### Requirement 12: Loading States

**User Story:** As a platform administrator, I want to see clear loading indicators during data operations, so that I know the system is processing my requests.

#### Acceptance Criteria

1. WHILE fetching data from Firestore, THE Admin_Panel SHALL display skeleton loaders or spinner indicators
2. WHILE executing Cloud_Functions, THE Admin_Panel SHALL display inline loading indicators on action buttons
3. THE Admin_Panel SHALL disable interactive elements during loading operations to prevent duplicate submissions
4. WHEN a loading operation exceeds 10 seconds, THE Admin_Panel SHALL display a timeout warning with retry option

### Requirement 13: Error Handling

**User Story:** As a platform administrator, I want to see clear error messages when operations fail, so that I can understand and resolve issues.

#### Acceptance Criteria

1. WHEN a Firestore query fails, THE Admin_Panel SHALL display an error message with the failure reason
2. WHEN a Cloud_Function returns an error, THE Admin_Panel SHALL display the error message from the function response
3. WHEN a network error occurs, THE Admin_Panel SHALL display a network connectivity error message
4. FOR ALL error states, THE Admin_Panel SHALL provide a retry action button
5. THE Admin_Panel SHALL log error details to the browser console for debugging purposes

### Requirement 14: Empty States

**User Story:** As a platform administrator, I want to see helpful messages when no data is available, so that I understand the current system state.

#### Acceptance Criteria

1. WHEN no booking payouts exist, THE Admin_Panel SHALL display "No payouts found" with an informative icon
2. WHEN no wallet withdrawals exist, THE Admin_Panel SHALL display "No withdrawal requests found" with an informative icon
3. WHEN no audit logs match the current filters, THE Admin_Panel SHALL display "No logs found for the selected filters" with filter reset option
4. WHEN search results are empty, THE Admin_Panel SHALL display "No results match your search" with search clear option

### Requirement 15: Security Architecture

**User Story:** As a platform administrator, I want all financial operations to be processed securely through Cloud Functions, so that the system prevents unauthorized database manipulation.

#### Acceptance Criteria

1. THE Admin_Panel SHALL invoke Cloud_Functions for all payout status changes
2. THE Admin_Panel SHALL invoke Cloud_Functions for all withdrawal approvals and rejections
3. THE Admin_Panel SHALL invoke Cloud_Functions for all settings updates
4. THE Admin_Panel SHALL NOT include any direct Firestore write operations for bookingPayouts collection
5. THE Admin_Panel SHALL NOT include any direct Firestore write operations for walletWithdrawals collection
6. THE Admin_Panel SHALL NOT include any direct Firestore write operations for appSettings collection
7. THE Admin_Panel SHALL only perform read operations directly against Firestore for display purposes
8. THE Admin_Panel SHALL pass admin authentication tokens to all Cloud_Function invocations

### Requirement 16: Audit Trail Creation

**User Story:** As a platform administrator, I want all administrative actions to be automatically logged, so that there is a complete audit trail for compliance and security.

#### Acceptance Criteria

1. WHEN a booking payout is processed, THE Cloud_Function SHALL create an audit log entry with action type "payout_processed"
2. WHEN a wallet withdrawal is approved, THE Cloud_Function SHALL create an audit log entry with action type "withdrawal_approved"
3. WHEN a wallet withdrawal is rejected, THE Cloud_Function SHALL create an audit log entry with action type "withdrawal_rejected"
4. WHEN platform settings are updated, THE Cloud_Function SHALL create an audit log entry with action type "settings_updated"
5. FOR EACH audit log entry, THE Cloud_Function SHALL record admin ID, admin name, action type, entity type, entity ID, metadata, IP address, and timestamp
6. THE Cloud_Function SHALL create audit logs atomically with the primary operation to ensure consistency

### Requirement 17: Navigation Structure

**User Story:** As a platform administrator, I want clear navigation to all finance and settings features, so that I can efficiently access the tools I need.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display a "Finance" section in the sidebar navigation
2. THE Finance section SHALL contain navigation links for "Booking Payouts" and "Wallet Withdrawals"
3. THE Admin_Panel SHALL display a "System" section in the sidebar navigation
4. THE System section SHALL contain navigation links for "Audit Logs" and "Settings"
5. WHEN an administrator navigates to a module, THE Admin_Panel SHALL highlight the active navigation item
6. THE Admin_Panel SHALL NOT display the System Tests module in any navigation section

### Requirement 18: Data Pagination

**User Story:** As a platform administrator, I want large data sets to be paginated, so that the interface remains performant and usable.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display booking payouts in pages of 20 items
2. THE Admin_Panel SHALL display wallet withdrawals in pages of 20 items
3. THE Admin_Panel SHALL display audit logs in pages of 50 items
4. THE Admin_Panel SHALL provide pagination controls (previous, next, page numbers)
5. THE Admin_Panel SHALL display the current page number and total page count
6. WHEN an administrator changes pages, THE Admin_Panel SHALL scroll to the top of the content area

### Requirement 19: Real-time Data Updates

**User Story:** As a platform administrator, I want to see updated data when changes occur, so that I'm always viewing current information.

#### Acceptance Criteria

1. WHEN viewing the booking payouts list, THE Admin_Panel SHALL use Firestore real-time listeners to receive updates
2. WHEN viewing the wallet withdrawals list, THE Admin_Panel SHALL use Firestore real-time listeners to receive updates
3. WHEN viewing audit logs, THE Admin_Panel SHALL use Firestore real-time listeners to receive new entries
4. WHEN viewing settings, THE Admin_Panel SHALL use Firestore real-time listeners to receive updates
5. WHEN an administrator navigates away from a module, THE Admin_Panel SHALL unsubscribe from Firestore listeners to prevent memory leaks

### Requirement 20: Input Validation

**User Story:** As a platform administrator, I want form inputs to be validated before submission, so that I receive immediate feedback on invalid data.

#### Acceptance Criteria

1. WHEN editing platform commission percentage, THE Admin_Panel SHALL validate the value is between 0 and 100
2. WHEN editing support phone number, THE Admin_Panel SHALL validate the format matches a valid phone pattern
3. WHEN editing support email, THE Admin_Panel SHALL validate the format matches a valid email pattern
4. WHEN editing minimum withdrawal amount, THE Admin_Panel SHALL validate the value is a positive number greater than zero
5. THE Admin_Panel SHALL display inline validation error messages below invalid fields
6. THE Admin_Panel SHALL disable the save button until all validation errors are resolved
7. WHEN entering rejection reasons for withdrawals, THE Admin_Panel SHALL validate the reason is not empty and contains at least 10 characters
