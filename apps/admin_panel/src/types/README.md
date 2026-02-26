# Finance Module Type Definitions

This directory contains TypeScript type definitions for the Admin Finance & Settings Module.

## Files

### `finance.ts`
Complete type definitions for the finance and settings module including:

- **Status Type Unions**: PayoutStatus, WithdrawalStatus, AuditActionType, AuditEntityType
- **Firestore Collection Interfaces**: BookingPayout, WalletWithdrawal, AuditLog, AppSettings
- **Cloud Function Interfaces**: Request/response types for all Cloud Functions
- **Filter Interfaces**: PayoutFilters, WithdrawalFilters, AuditLogFilters
- **UI Component Props**: StatusBadgeProps, ConfirmDialogProps, ErrorStateProps, EmptyStateProps
- **Form State Interfaces**: SettingsFormValues, FormErrors, FormTouched

## Usage

Import types from the central index:

```typescript
import type {
  BookingPayout,
  WalletWithdrawal,
  PayoutStatus,
  ProcessBookingPayoutRequest
} from '@/types';
```

Or import directly from the finance module:

```typescript
import type { BookingPayout } from '@/types/finance';
```

## Data Models

### BookingPayout
Represents a payment owed to a technician for a completed booking.

**Collection**: `bookingPayouts`

**Key Fields**:
- `bookingId`: Reference to the booking
- `technicianId`: Reference to the technician
- `technicianEarning`: Amount to be paid to technician
- `status`: Current payout status (pending, processing, completed, failed)
- `paidAt`: Timestamp when marked as paid (optional)

### WalletWithdrawal
Represents a technician's request to withdraw funds from their wallet.

**Collection**: `walletWithdrawals`

**Key Fields**:
- `technicianId`: Reference to the technician
- `amount`: Withdrawal amount requested
- `bankAccountNumber`: Technician's bank account
- `status`: Current withdrawal status (pending, approved, rejected, completed)
- `rejectionReason`: Reason for rejection (if rejected)

### AuditLog
Immutable record of all administrative actions.

**Collection**: `auditLogs`

**Key Fields**:
- `adminId`: Admin who performed the action
- `actionType`: Type of action performed
- `entityType`: Type of entity affected
- `entityId`: ID of the affected entity
- `metadata`: Additional action-specific data

### AppSettings
Platform-wide configuration settings.

**Document Path**: `appSettings/config`

**Key Fields**:
- `platformCommissionPercentage`: Commission rate (0-100)
- `supportPhoneNumber`: Support contact number
- `supportEmail`: Support contact email
- `maintenanceMode`: Whether platform is in maintenance mode
- `minWithdrawalAmount`: Minimum amount for withdrawals

## Cloud Functions

All financial write operations are processed through Cloud Functions:

1. **processBookingPayout**: Mark a payout as paid
2. **approveWalletWithdrawal**: Approve a withdrawal request
3. **rejectWalletWithdrawal**: Reject a withdrawal request with reason
4. **updateAppSettings**: Update platform settings

Each function has corresponding Request and Response interfaces defined in `finance.ts`.

## Security

- All write operations go through Cloud Functions (no direct Firestore writes)
- Admin authentication tokens are passed with every function call
- Firestore security rules enforce read-only access from the client
- Audit logs are created automatically for all administrative actions
