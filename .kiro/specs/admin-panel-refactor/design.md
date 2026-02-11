# Design Document: Admin Panel Refactor

## Overview

This design document outlines the architecture and implementation approach for refactoring the admin panel into a production-ready administrative control system. The refactor will transform the existing visual-only implementation into a fully functional, secure, and maintainable system for managing all platform entities.

### Design Principles

1. **Security First**: All write operations go through secure backend Cloud Functions with proper authentication and authorization
2. **Real-time Updates**: Use Firestore listeners for live data synchronization across admin sessions
3. **Optimistic UI**: Update the UI immediately and rollback on errors for better user experience
4. **Type Safety**: Leverage TypeScript throughout for compile-time error detection
5. **Component Reusability**: Build a library of reusable UI components for consistency
6. **Separation of Concerns**: Clear boundaries between UI, business logic, and data access layers

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Admin Panel (Next.js)                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              UI Layer (React Components)                │ │
│  │  - Pages  - Forms  - Tables  - Modals  - Charts       │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           Business Logic Layer (Hooks/Utils)            │ │
│  │  - Data Fetching  - State Management  - Validation     │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │          Data Access Layer (API Client)                 │ │
│  │  - admin-api.ts  - Firestore Queries  - Auth           │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Firebase Backend (Cloud Functions)              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Admin Functions (Secure, Authenticated)                │ │
│  │  - Technician Management  - Customer Management         │ │
│  │  - Booking Management     - Finance Management          │ │
│  │  - Service Management     - Settings Management         │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Cloud Firestore Database                   │
│  Collections: technicians, customers, bookings, services,    │
│  payouts, wallet_transactions, banners, audit_logs, admins   │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

- **Frontend Framework**: Next.js 14 (App Router) with React 18
- **Language**: TypeScript for type safety
- **Styling**: Tailwind CSS for utility-first styling
- **UI Components**: Custom components with Lucide React icons
- **Charts**: Recharts for data visualization
- **Backend**: Firebase Cloud Functions (Node.js)
- **Database**: Cloud Firestore
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage for images
- **State Management**: React hooks (useState, useEffect, useContext)

## Components and Interfaces

### Core UI Components

#### 1. Layout Components

**AdminLayout**
- Purpose: Provides consistent layout structure across all admin pages
- Props: `children: ReactNode`
- Features: Sidebar navigation, header with user info, logout button
- Location: `src/components/layout/AdminLayout.tsx`

**Sidebar**
- Purpose: Navigation menu for all admin sections
- Props: `currentPath: string`
- Features: Collapsible menu, active state indicators, icons
- Location: `src/components/layout/Sidebar.tsx`

**Header**
- Purpose: Top bar with user information and actions
- Props: `user: AdminUser`
- Features: User avatar, notifications, logout
- Location: `src/components/layout/Header.tsx`

#### 2. Data Display Components

**DataTable**
- Purpose: Reusable table component for displaying entity lists
- Props:
  ```typescript
  interface DataTableProps<T> {
    columns: ColumnDef<T>[];
    data: T[];
    loading?: boolean;
    emptyMessage?: string;
    onRowClick?: (row: T) => void;
    pagination?: PaginationConfig;
  }
  ```
- Features: Sorting, filtering, pagination, row selection
- Location: `src/components/ui/DataTable.tsx`

**StatusBadge**
- Purpose: Display status with color coding
- Props: `status: string, variant: 'success' | 'warning' | 'error' | 'info'`
- Location: `src/components/ui/StatusBadge.tsx`

**EmptyState**
- Purpose: Display when no data is available
- Props: `message: string, icon?: ReactNode, action?: ReactNode`
- Location: `src/components/ui/EmptyState.tsx`

#### 3. Form Components

**FormInput**
- Purpose: Reusable input field with validation
- Props:
  ```typescript
  interface FormInputProps {
    label: string;
    name: string;
    type?: string;
    value: string;
    onChange: (value: string) => void;
    error?: string;
    required?: boolean;
    placeholder?: string;
  }
  ```
- Location: `src/components/forms/FormInput.tsx`

**FormSelect**
- Purpose: Dropdown selection with validation
- Props: Similar to FormInput with `options: Array<{label: string, value: string}>`
- Location: `src/components/forms/FormSelect.tsx`

**ImageUpload**
- Purpose: Image upload with preview
- Props:
  ```typescript
  interface ImageUploadProps {
    onUpload: (file: File) => Promise<string>;
    currentImage?: string;
    maxSize?: number;
    acceptedFormats?: string[];
  }
  ```
- Location: `src/components/forms/ImageUpload.tsx`

#### 4. Modal Components

**ConfirmDialog**
- Purpose: Confirmation dialog for destructive actions
- Props:
  ```typescript
  interface ConfirmDialogProps {
    open: boolean;
    title: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
    onConfirm: () => void;
    onCancel: () => void;
    variant?: 'danger' | 'warning' | 'info';
  }
  ```
- Location: `src/components/modals/ConfirmDialog.tsx`

**DetailModal**
- Purpose: Display detailed information in a modal
- Props: `open: boolean, onClose: () => void, title: string, children: ReactNode`
- Location: `src/components/modals/DetailModal.tsx`

**FormModal**
- Purpose: Modal with form for create/edit operations
- Props: `open: boolean, onClose: () => void, onSubmit: (data: any) => void, title: string, children: ReactNode`
- Location: `src/components/modals/FormModal.tsx`

### Page Components

#### 1. Dashboard Page
- Path: `/dashboard`
- Purpose: Overview of key metrics and recent activity
- Components: StatCard, RevenueChart, RecentBookingsTable
- Data: Dashboard stats from `admin_getDashboardStats`

#### 2. Technicians Page
- Path: `/technicians`
- Purpose: Manage technician accounts and applications
- Components: TechnicianTable, TechnicianDetailModal, ApprovalDialog
- Data: Technicians from `admin_getTechnicians`
- Actions: Approve, reject, suspend, reactivate, toggle availability

#### 3. Customers Page
- Path: `/customers`
- Purpose: Manage customer accounts
- Components: CustomerTable, CustomerDetailModal, BlockDialog
- Data: Customers from `admin_getUsers` with role filter
- Actions: View details, edit profile, block, unblock

#### 4. Bookings Page
- Path: `/bookings`
- Purpose: Manage service bookings
- Components: BookingTable, BookingDetailModal, AssignTechnicianDialog, CancelDialog
- Data: Bookings from Firestore with filters
- Actions: View details, assign technician, update status, cancel

#### 5. Services Page
- Path: `/services`
- Purpose: Manage service catalog
- Components: ServiceTree, ServiceFormModal, CategoryFormModal
- Data: Services and categories from Firestore
- Actions: Create, edit, delete services and categories, toggle active status

#### 6. Finance Page
- Path: `/finance`
- Purpose: Manage payouts and wallet transactions
- Components: PayoutTable, WalletBalanceCard, TransactionHistory, AdjustmentDialog
- Data: Payouts and transactions from Firestore
- Actions: Approve payouts, adjust wallet balances, view reports

#### 7. Banners Page
- Path: `/service-banners`
- Purpose: Manage promotional banners
- Components: BannerGrid, BannerFormModal, ImageUpload
- Data: Banners from Firestore
- Actions: Create, edit, delete, toggle active status, reorder

#### 8. Settings Page
- Path: `/settings`
- Purpose: Manage global system settings
- Components: SettingsForm, MaintenanceModeToggle, AdminUserTable
- Data: System configuration from Firestore
- Actions: Update settings, manage admin users

#### 9. Audit Logs Page
- Path: `/audit-logs`
- Purpose: View system audit trail
- Components: AuditLogTable, LogDetailModal
- Data: Audit logs from `admin_getAuditLogs`
- Actions: View, filter, export

### Custom Hooks

#### useAdminAuth
```typescript
interface UseAdminAuthReturn {
  user: AdminUser | null;
  loading: boolean;
  error: Error | null;
  logout: () => Promise<void>;
}

function useAdminAuth(): UseAdminAuthReturn
```
- Purpose: Manage admin authentication state
- Location: `src/hooks/useAdminAuth.ts`

#### useFirestoreQuery
```typescript
interface UseFirestoreQueryReturn<T> {
  data: T[];
  loading: boolean;
  error: Error | null;
  refetch: () => void;
}

function useFirestoreQuery<T>(
  collectionPath: string,
  constraints?: QueryConstraint[]
): UseFirestoreQueryReturn<T>
```
- Purpose: Real-time Firestore queries with loading states
- Location: `src/hooks/useFirestoreQuery.ts`

#### useOptimisticUpdate
```typescript
interface UseOptimisticUpdateReturn<T> {
  execute: (
    optimisticData: T,
    serverUpdate: () => Promise<T>
  ) => Promise<void>;
  rollback: () => void;
}

function useOptimisticUpdate<T>(
  currentData: T,
  setData: (data: T) => void
): UseOptimisticUpdateReturn<T>
```
- Purpose: Optimistic UI updates with rollback on error
- Location: `src/hooks/useOptimisticUpdate.ts`

#### usePagination
```typescript
interface UsePaginationReturn {
  page: number;
  pageSize: number;
  totalPages: number;
  goToPage: (page: number) => void;
  nextPage: () => void;
  prevPage: () => void;
}

function usePagination(
  totalItems: number,
  initialPageSize?: number
): UsePaginationReturn
```
- Purpose: Pagination state management
- Location: `src/hooks/usePagination.ts`

## Data Models

### TypeScript Interfaces

#### Admin User
```typescript
interface AdminUser {
  uid: string;
  email: string;
  displayName: string;
  role: 'super_admin' | 'admin' | 'support';
  permissions: string[];
  createdAt: Timestamp;
  lastLogin: Timestamp;
}
```

#### Technician
```typescript
interface Technician {
  id: string;
  name: string;
  phone: string;
  email: string;
  status: 'pending' | 'approved' | 'rejected' | 'blocked';
  isAvailable: boolean;
  profileImage?: string;
  address: Address;
  services: string[]; // Service IDs
  rating: number;
  totalBookings: number;
  walletBalance: number;
  bankDetails?: BankDetails;
  documents: Document[];
  createdAt: Timestamp;
  updatedAt: Timestamp;
  approvedAt?: Timestamp;
  approvedBy?: string;
  rejectionReason?: string;
}

interface BankDetails {
  accountNumber: string;
  ifscCode: string;
  accountHolderName: string;
  bankName: string;
}

interface Document {
  type: 'aadhar' | 'pan' | 'license' | 'certificate';
  url: string;
  verified: boolean;
}
```

#### Customer
```typescript
interface Customer {
  id: string;
  name: string;
  phone: string;
  email?: string;
  profileImage?: string;
  addresses: Address[];
  walletBalance: number;
  totalBookings: number;
  status: 'active' | 'blocked';
  createdAt: Timestamp;
  updatedAt: Timestamp;
  blockedAt?: Timestamp;
  blockReason?: string;
}

interface Address {
  id: string;
  label: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  pincode: string;
  latitude: number;
  longitude: number;
  isDefault: boolean;
}
```

#### Booking
```typescript
interface Booking {
  id: string;
  customerId: string;
  customerName: string;
  customerPhone: string;
  technicianId?: string;
  technicianName?: string;
  serviceId: string;
  serviceName: string;
  subServices: SubServiceItem[];
  address: Address;
  scheduledDate: Timestamp;
  scheduledTime: string;
  status: BookingStatus;
  paymentStatus: 'pending' | 'paid' | 'refunded' | 'failed';
  amount: number;
  finalAmount: number;
  discount: number;
  platformFee: number;
  technicianEarning: number;
  statusHistory: StatusChange[];
  createdAt: Timestamp;
  updatedAt: Timestamp;
  completedAt?: Timestamp;
  cancelledAt?: Timestamp;
  cancellationReason?: string;
}

type BookingStatus = 
  | 'pending_payment'
  | 'confirmed'
  | 'assigned'
  | 'on_the_way'
  | 'started'
  | 'completed'
  | 'cancelled';

interface SubServiceItem {
  subServiceId: string;
  name: string;
  quantity: number;
  price: number;
}

interface StatusChange {
  status: BookingStatus;
  timestamp: Timestamp;
  changedBy: string;
  reason?: string;
}
```

#### Service
```typescript
interface Service {
  id: string;
  name: string;
  description: string;
  categoryId: string;
  categoryName: string;
  subcategoryId?: string;
  subcategoryName?: string;
  basePrice: number;
  unit: string;
  duration: number; // minutes
  isActive: boolean;
  displayOrder: number;
  imageUrl?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface ServiceCategory {
  id: string;
  name: string;
  description: string;
  icon: string;
  displayOrder: number;
  isActive: boolean;
  subcategories: ServiceSubcategory[];
}

interface ServiceSubcategory {
  id: string;
  name: string;
  description: string;
  displayOrder: number;
  isActive: boolean;
}
```

#### Payout
```typescript
interface Payout {
  id: string;
  technicianId: string;
  technicianName: string;
  amount: number;
  status: 'pending' | 'approved' | 'processing' | 'completed' | 'failed';
  bankDetails: BankDetails;
  razorpayPayoutId?: string;
  requestedAt: Timestamp;
  approvedAt?: Timestamp;
  approvedBy?: string;
  completedAt?: Timestamp;
  failureReason?: string;
}
```

#### WalletTransaction
```typescript
interface WalletTransaction {
  id: string;
  userId: string;
  userType: 'technician' | 'customer';
  type: 'credit' | 'debit';
  amount: number;
  description: string;
  bookingId?: string;
  payoutId?: string;
  status: 'pending' | 'completed' | 'failed';
  balanceBefore: number;
  balanceAfter: number;
  createdAt: Timestamp;
}
```

#### Banner
```typescript
interface ServiceBanner {
  id: string;
  title: string;
  description: string;
  imageUrl: string;
  linkedServiceId?: string;
  isActive: boolean;
  displayOrder: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
}
```

#### AuditLog
```typescript
interface AuditLog {
  id: string;
  adminId: string;
  adminEmail: string;
  action: string;
  entityType: string;
  entityId: string;
  changes?: Record<string, any>;
  metadata?: Record<string, any>;
  timestamp: Timestamp;
  ipAddress?: string;
}
```

### Firestore Collection Structure

```
/technicians/{technicianId}
  - Technician document
  /wallet/{walletId}
    - Wallet balance and metadata
  /wallet_transactions/{transactionId}
    - Individual transactions
  /earnings/{bookingId}
    - Earnings per booking

/customers/{customerId}
  - Customer document
  /wallet_transactions/{transactionId}
    - Individual transactions

/bookings/{bookingId}
  - Booking document

/services/{serviceId}
  - Service document

/service_categories/{categoryId}
  - Category document with subcategories array

/payouts/{payoutId}
  - Payout document

/service_banners/{bannerId}
  - Banner document

/audit_logs/{logId}
  - Audit log document

/admins/{adminId}
  - Admin user document

/system_config/settings
  - Global configuration document
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Data Filtering Consistency

*For any* collection of entities (technicians, customers, bookings, payouts) and any filter criteria (status, date range, etc.), applying the filter should return only entities that match all specified criteria, and the filtered result should be a subset of the original collection.

**Validates: Requirements 1.2, 2.3, 4.2, 4.3, 5.2**

### Property 2: Search Result Relevance

*For any* searchable collection (technicians, customers, bookings) and any search term, all returned results should contain the search term in at least one of the searchable fields (name, phone, email, ID), and no result should be returned that doesn't contain the search term.

**Validates: Requirements 1.3, 2.2, 4.4**

### Property 3: Authentication Authorization

*For any* user attempting to access the admin panel, if the user does not have admin privileges, they should be redirected to the login page and not granted access to any admin functionality.

**Validates: Requirements 8.2, 8.5**

### Property 4: File Upload Validation

*For any* file upload attempt, if the file format is not in the accepted list (JPEG, PNG) or the file size exceeds the maximum (2MB), the upload should be rejected with a descriptive error message before any network request is made.

**Validates: Requirements 6.7**

### Property 5: Form Validation Completeness

*For any* form submission, if any required field is empty or contains invalid data, the form should not be submitted and field-level error messages should be displayed for all invalid fields.

**Validates: Requirements 9.7, 11.4**

### Property 6: Error Message Display

*For any* failed operation (API call, network request, validation error), the admin panel should display a user-friendly error message that describes what went wrong and, where applicable, provides actionable next steps.

**Validates: Requirements 9.5, 11.1**

### Property 7: Optimistic Update Rollback

*For any* optimistic UI update followed by a failed backend operation, the UI should revert to the state before the optimistic update, and an error message should be displayed to the user.

**Validates: Requirements 10.5**

## Error Handling

### Error Categories

#### 1. Network Errors
- **Scenario**: Network connectivity issues, timeout errors
- **Handling**: Display retry button, cache failed requests for retry
- **User Feedback**: "Network error. Please check your connection and try again."

#### 2. Authentication Errors
- **Scenario**: Session expired, invalid token, insufficient permissions
- **Handling**: Redirect to login page, clear local auth state
- **User Feedback**: "Your session has expired. Please log in again."

#### 3. Validation Errors
- **Scenario**: Invalid form input, business rule violations
- **Handling**: Display field-level errors, prevent submission
- **User Feedback**: Specific error per field (e.g., "Phone number must be 10 digits")

#### 4. Backend Errors
- **Scenario**: Cloud Function failures, database errors
- **Handling**: Log error details, display user-friendly message
- **User Feedback**: "Unable to complete the operation. Please try again later."

#### 5. File Upload Errors
- **Scenario**: Invalid file format, size exceeded, upload failure
- **Handling**: Validate before upload, show progress, allow retry
- **User Feedback**: "Image must be JPEG or PNG and less than 2MB"

### Error Handling Patterns

#### Try-Catch with User Feedback
```typescript
async function handleAction() {
  setLoading(true);
  setError(null);
  
  try {
    await adminApi.someAction(data);
    setSuccess(true);
  } catch (error) {
    const message = getErrorMessage(error);
    setError(message);
    console.error('Action failed:', error);
  } finally {
    setLoading(false);
  }
}
```

#### Optimistic Update with Rollback
```typescript
async function handleUpdate(newData: T) {
  const previousData = data;
  
  // Optimistic update
  setData(newData);
  
  try {
    await adminApi.updateData(newData);
  } catch (error) {
    // Rollback on error
    setData(previousData);
    setError(getErrorMessage(error));
  }
}
```

#### Form Validation
```typescript
function validateForm(formData: FormData): ValidationErrors {
  const errors: ValidationErrors = {};
  
  if (!formData.name?.trim()) {
    errors.name = 'Name is required';
  }
  
  if (!formData.phone?.match(/^\d{10}$/)) {
    errors.phone = 'Phone must be 10 digits';
  }
  
  if (!formData.email?.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)) {
    errors.email = 'Invalid email format';
  }
  
  return errors;
}
```

### Error Logging

All errors should be logged with context for debugging:

```typescript
function logError(error: Error, context: ErrorContext) {
  console.error('Error occurred:', {
    message: error.message,
    stack: error.stack,
    context: {
      action: context.action,
      userId: context.userId,
      timestamp: new Date().toISOString(),
      ...context.metadata
    }
  });
  
  // Optional: Send to error tracking service
  // errorTracker.captureException(error, context);
}
```

## Testing Strategy

### Dual Testing Approach

The admin panel refactor will use both unit testing and property-based testing to ensure comprehensive coverage:

- **Unit Tests**: Verify specific examples, edge cases, error conditions, and integration points
- **Property Tests**: Verify universal properties across all inputs using randomized test data

Both approaches are complementary and necessary for production-ready code.

### Unit Testing

#### Framework and Tools
- **Test Framework**: Jest with React Testing Library
- **Coverage Target**: Minimum 80% code coverage
- **Location**: Co-located with components (`*.test.tsx`)

#### Unit Test Focus Areas

1. **Component Rendering**
   - Components render without errors
   - Props are correctly passed and displayed
   - Conditional rendering works as expected
   - Empty states display correctly

2. **User Interactions**
   - Button clicks trigger correct handlers
   - Form submissions call correct functions
   - Modal open/close behavior
   - Navigation works correctly

3. **Edge Cases**
   - Empty data arrays
   - Null/undefined values
   - Maximum/minimum values
   - Boundary conditions

4. **Error Conditions**
   - API call failures
   - Network errors
   - Validation errors
   - Permission errors

5. **Integration Points**
   - API client calls correct endpoints
   - Firestore queries use correct paths
   - Authentication state changes
   - Real-time listener setup/teardown

#### Example Unit Tests

```typescript
// Component rendering test
describe('TechnicianTable', () => {
  it('should render technicians with status badges', () => {
    const technicians = [
      { id: '1', name: 'John', status: 'approved' },
      { id: '2', name: 'Jane', status: 'pending' }
    ];
    
    render(<TechnicianTable data={technicians} />);
    
    expect(screen.getByText('John')).toBeInTheDocument();
    expect(screen.getByText('Jane')).toBeInTheDocument();
    expect(screen.getAllByRole('row')).toHaveLength(3); // header + 2 rows
  });
  
  it('should display empty state when no data', () => {
    render(<TechnicianTable data={[]} />);
    expect(screen.getByText(/no technicians found/i)).toBeInTheDocument();
  });
});

// Error handling test
describe('useAdminAuth', () => {
  it('should redirect to login on authentication error', async () => {
    const mockPush = jest.fn();
    jest.spyOn(require('next/navigation'), 'useRouter').mockReturnValue({
      push: mockPush
    });
    
    // Mock auth error
    jest.spyOn(auth, 'onAuthStateChanged').mockImplementation((callback) => {
      callback(null);
      return () => {};
    });
    
    renderHook(() => useAdminAuth());
    
    await waitFor(() => {
      expect(mockPush).toHaveBeenCalledWith('/login');
    });
  });
});
```

### Property-Based Testing

#### Framework and Configuration
- **Library**: fast-check for TypeScript
- **Minimum Iterations**: 100 runs per property test
- **Location**: Separate test files (`*.property.test.ts`)

#### Property Test Requirements

Each property test must:
1. Reference the design document property number
2. Use the tag format: `Feature: admin-panel-refactor, Property {number}: {property_text}`
3. Run minimum 100 iterations with randomized inputs
4. Test the universal property, not specific examples

#### Property Test Implementation

```typescript
import fc from 'fast-check';

/**
 * Feature: admin-panel-refactor, Property 1: Data Filtering Consistency
 * 
 * For any collection of entities and any filter criteria, applying the filter
 * should return only entities that match all specified criteria.
 */
describe('Property 1: Data Filtering Consistency', () => {
  it('should filter technicians by status correctly', () => {
    fc.assert(
      fc.property(
        fc.array(technicianArbitrary()),
        fc.constantFrom('pending', 'approved', 'rejected', 'blocked'),
        (technicians, filterStatus) => {
          const filtered = filterTechniciansByStatus(technicians, filterStatus);
          
          // All filtered items must match the filter
          const allMatch = filtered.every(t => t.status === filterStatus);
          
          // Filtered result must be subset of original
          const isSubset = filtered.every(t => 
            technicians.some(orig => orig.id === t.id)
          );
          
          // No matching items should be excluded
          const noMissing = technicians
            .filter(t => t.status === filterStatus)
            .every(t => filtered.some(f => f.id === t.id));
          
          return allMatch && isSubset && noMissing;
        }
      ),
      { numRuns: 100 }
    );
  });
});

/**
 * Feature: admin-panel-refactor, Property 2: Search Result Relevance
 * 
 * For any searchable collection and any search term, all returned results
 * should contain the search term in at least one searchable field.
 */
describe('Property 2: Search Result Relevance', () => {
  it('should return only customers matching search term', () => {
    fc.assert(
      fc.property(
        fc.array(customerArbitrary()),
        fc.string({ minLength: 1, maxLength: 20 }),
        (customers, searchTerm) => {
          const results = searchCustomers(customers, searchTerm);
          
          // All results must contain search term
          const allRelevant = results.every(c => 
            c.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            c.phone.includes(searchTerm) ||
            c.email?.toLowerCase().includes(searchTerm.toLowerCase())
          );
          
          // No relevant items should be excluded
          const noMissing = customers
            .filter(c => 
              c.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
              c.phone.includes(searchTerm) ||
              c.email?.toLowerCase().includes(searchTerm.toLowerCase())
            )
            .every(c => results.some(r => r.id === c.id));
          
          return allRelevant && noMissing;
        }
      ),
      { numRuns: 100 }
    );
  });
});

/**
 * Feature: admin-panel-refactor, Property 5: Form Validation Completeness
 * 
 * For any form submission, if any required field is empty or invalid,
 * the form should not be submitted and errors should be displayed.
 */
describe('Property 5: Form Validation Completeness', () => {
  it('should validate all required fields before submission', () => {
    fc.assert(
      fc.property(
        formDataArbitrary(),
        (formData) => {
          const errors = validateTechnicianForm(formData);
          const hasErrors = Object.keys(errors).length > 0;
          
          // If any required field is empty, there should be errors
          const requiredFields = ['name', 'phone', 'email'];
          const hasEmptyRequired = requiredFields.some(
            field => !formData[field]?.trim()
          );
          
          if (hasEmptyRequired) {
            return hasErrors;
          }
          
          // If phone is invalid format, there should be an error
          if (formData.phone && !formData.phone.match(/^\d{10}$/)) {
            return errors.phone !== undefined;
          }
          
          // If email is invalid format, there should be an error
          if (formData.email && !formData.email.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)) {
            return errors.email !== undefined;
          }
          
          return true;
        }
      ),
      { numRuns: 100 }
    );
  });
});

/**
 * Feature: admin-panel-refactor, Property 7: Optimistic Update Rollback
 * 
 * For any optimistic UI update followed by a failed backend operation,
 * the UI should revert to the state before the optimistic update.
 */
describe('Property 7: Optimistic Update Rollback', () => {
  it('should rollback optimistic updates on error', async () => {
    fc.assert(
      await fc.asyncProperty(
        technicianArbitrary(),
        technicianArbitrary(),
        async (originalData, updatedData) => {
          const { result } = renderHook(() => useOptimisticUpdate(originalData));
          
          // Mock API to fail
          const mockUpdate = jest.fn().mockRejectedValue(new Error('API Error'));
          
          // Perform optimistic update
          await result.current.execute(updatedData, mockUpdate);
          
          // Data should be rolled back to original
          return result.current.data === originalData;
        }
      ),
      { numRuns: 100 }
    );
  });
});

// Arbitraries for generating random test data
function technicianArbitrary() {
  return fc.record({
    id: fc.uuid(),
    name: fc.string({ minLength: 3, maxLength: 50 }),
    phone: fc.stringOf(fc.integer({ min: 0, max: 9 }), { minLength: 10, maxLength: 10 }),
    email: fc.emailAddress(),
    status: fc.constantFrom('pending', 'approved', 'rejected', 'blocked'),
    isAvailable: fc.boolean(),
    rating: fc.float({ min: 0, max: 5 }),
    totalBookings: fc.nat(),
    walletBalance: fc.float({ min: 0, max: 100000 })
  });
}

function customerArbitrary() {
  return fc.record({
    id: fc.uuid(),
    name: fc.string({ minLength: 3, maxLength: 50 }),
    phone: fc.stringOf(fc.integer({ min: 0, max: 9 }), { minLength: 10, maxLength: 10 }),
    email: fc.option(fc.emailAddress()),
    status: fc.constantFrom('active', 'blocked'),
    totalBookings: fc.nat(),
    walletBalance: fc.float({ min: 0, max: 100000 })
  });
}

function formDataArbitrary() {
  return fc.record({
    name: fc.option(fc.string({ maxLength: 50 })),
    phone: fc.option(fc.string({ maxLength: 15 })),
    email: fc.option(fc.string({ maxLength: 100 })),
    address: fc.option(fc.string({ maxLength: 200 }))
  });
}
```

### Integration Testing

Integration tests verify that components work correctly with real Firebase services in a test environment:

1. **Authentication Flow**: Login, logout, session management
2. **Firestore Operations**: Real-time listeners, queries, updates
3. **Cloud Functions**: API calls with actual backend
4. **File Uploads**: Image upload to Firebase Storage
5. **End-to-End Workflows**: Complete user journeys (e.g., approve technician application)

### Test Coverage Goals

- **Unit Tests**: 80% code coverage minimum
- **Property Tests**: All universal properties from design document
- **Integration Tests**: Critical user workflows
- **Manual Testing**: UI/UX, responsive design, accessibility

## Implementation Phases

### Phase 1: Foundation (Week 1)
- Set up project structure and shared components
- Implement authentication and authorization
- Create reusable UI components (DataTable, forms, modals)
- Set up custom hooks (useAdminAuth, useFirestoreQuery, useOptimisticUpdate)

### Phase 2: Core Entity Management (Week 2-3)
- Implement Technician Management page
- Implement Customer Management page
- Implement Booking Management page
- Add real-time updates and optimistic UI

### Phase 3: Financial and Content Management (Week 4)
- Implement Finance/Payout Management page
- Implement Service Catalog Management page
- Implement Banner Management page
- Add file upload functionality

### Phase 4: Settings and Audit (Week 5)
- Implement Settings page
- Implement Audit Logs page
- Add admin user management
- Implement global configuration

### Phase 5: Testing and Polish (Week 6)
- Write unit tests for all components
- Write property-based tests for core logic
- Perform integration testing
- UI/UX refinements and bug fixes

### Phase 6: Deployment (Week 7)
- Production deployment
- Monitoring and error tracking setup
- Documentation and training
- Post-deployment verification

## Security Considerations

### Authentication and Authorization

1. **Firebase Auth Integration**: Use Firebase Auth for admin authentication
2. **Role-Based Access Control**: Verify admin role in custom claims
3. **Session Management**: Implement session timeout and refresh
4. **Secure Routes**: Protect all admin routes with authentication middleware

### Data Security

1. **No Direct Firestore Writes**: All write operations through Cloud Functions
2. **Input Validation**: Validate all user input before sending to backend
3. **XSS Prevention**: Sanitize user-generated content before display
4. **CSRF Protection**: Use Firebase Auth tokens for request authentication

### API Security

1. **Cloud Function Authentication**: Verify admin role in all Cloud Functions
2. **Rate Limiting**: Implement rate limiting on sensitive operations
3. **Audit Logging**: Log all administrative actions with user context
4. **Error Messages**: Don't expose sensitive information in error messages

## Performance Optimization

### Frontend Optimization

1. **Code Splitting**: Use Next.js dynamic imports for large components
2. **Image Optimization**: Use Next.js Image component with proper sizing
3. **Lazy Loading**: Load data tables and charts on demand
4. **Debouncing**: Debounce search and filter inputs (300ms)
5. **Memoization**: Use React.memo and useMemo for expensive computations

### Data Fetching Optimization

1. **Pagination**: Limit initial data fetch to 20-50 items per page
2. **Firestore Indexes**: Create composite indexes for complex queries
3. **Query Caching**: Cache frequently accessed data (e.g., service catalog)
4. **Real-time Listeners**: Use targeted listeners, not collection-wide
5. **Batch Operations**: Batch multiple Firestore operations when possible

### Backend Optimization

1. **Cloud Function Cold Starts**: Keep functions warm with scheduled pings
2. **Database Queries**: Optimize Firestore queries with proper indexes
3. **Caching**: Implement Redis caching for frequently accessed data
4. **Async Operations**: Use async/await for non-blocking operations
5. **Connection Pooling**: Reuse database connections across invocations

## Deployment Strategy

### Environment Setup

1. **Development**: Local development with Firebase emulators
2. **Staging**: Staging environment with test data
3. **Production**: Production environment with real data

### Deployment Process

1. **Build**: Run `npm run build` to create production build
2. **Test**: Run all tests and verify coverage
3. **Deploy**: Deploy to Firebase Hosting
4. **Verify**: Smoke test critical workflows
5. **Monitor**: Watch error logs and performance metrics

### Rollback Plan

1. **Version Control**: Tag each production release
2. **Quick Rollback**: Revert to previous Firebase Hosting version
3. **Database Migrations**: Keep backward-compatible schema changes
4. **Communication**: Notify team of rollback and issues

## Monitoring and Maintenance

### Error Tracking

1. **Frontend Errors**: Capture and log client-side errors
2. **Backend Errors**: Monitor Cloud Function errors and timeouts
3. **Performance**: Track page load times and API response times
4. **User Actions**: Monitor failed operations and user feedback

### Metrics to Track

1. **Usage**: Active admin users, page views, actions per session
2. **Performance**: Page load time, API response time, error rate
3. **Business**: Technician approvals, booking assignments, payouts processed
4. **System Health**: Cloud Function invocations, Firestore reads/writes, storage usage

### Maintenance Tasks

1. **Weekly**: Review error logs and user feedback
2. **Monthly**: Analyze performance metrics and optimize bottlenecks
3. **Quarterly**: Update dependencies and security patches
4. **Annually**: Review and refactor technical debt
