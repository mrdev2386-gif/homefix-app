# Implementation Plan: Admin Panel Refactor

## Overview

This implementation plan breaks down the admin panel refactor into discrete, manageable tasks. Each task builds on previous work to create a production-ready administrative control system. The implementation follows a phased approach: foundation components first, then core entity management, followed by financial/content management, settings, and finally testing and deployment.

## Tasks

- [ ] 1. Set up project foundation and shared infrastructure
  - Create TypeScript interfaces for all data models (Technician, Customer, Booking, Service, Payout, Banner, AuditLog)
  - Set up custom hooks directory structure
  - Configure testing framework (Jest + React Testing Library + fast-check)
  - Set up error logging utility functions
  - _Requirements: 8.1, 8.3, 11.1_

- [ ] 2. Implement core authentication and authorization
  - [ ] 2.1 Create useAdminAuth hook for authentication state management
    - Implement Firebase Auth integration
    - Add admin role verification from custom claims
    - Handle session expiration and redirect to login
    - _Requirements: 8.2, 8.5, 8.6_
  
  - [ ]* 2.2 Write property test for authentication authorization
    - **Property 3: Authentication Authorization**
    - **Validates: Requirements 8.2, 8.5**
  
  - [ ] 2.3 Create authentication middleware for protected routes
    - Verify admin authentication before rendering pages
    - Redirect unauthorized users to login
    - _Requirements: 8.5_

- [ ] 3. Build reusable UI component library
  - [ ] 3.1 Create layout components (AdminLayout, Sidebar, Header)
    - Implement consistent layout structure with navigation
    - Add user info display and logout functionality
    - Make sidebar collapsible with active state indicators
    - _Requirements: 9.1, 9.9_
  
  - [ ] 3.2 Create DataTable component with sorting and pagination
    - Implement generic table with column definitions
    - Add loading states and empty state display
    - Include pagination controls
    - _Requirements: 9.2, 9.10_
  
  - [ ] 3.3 Create form components (FormInput, FormSelect, ImageUpload)
    - Implement input fields with validation error display
    - Add image upload with preview and format validation
    - _Requirements: 9.7, 6.7_
  
  - [ ]* 3.4 Write property test for file upload validation
    - **Property 4: File Upload Validation**
    - **Validates: Requirements 6.7**
  
  - [ ] 3.4 Create modal components (ConfirmDialog, DetailModal, FormModal)
    - Implement confirmation dialog for destructive actions
    - Add detail view modal with close functionality
    - Create form modal for create/edit operations
    - _Requirements: 9.6_
  
  - [ ] 3.5 Create StatusBadge and EmptyState components
    - Implement color-coded status badges
    - Add empty state with icon and message
    - _Requirements: 9.4_

- [ ] 4. Implement custom hooks for data management
  - [ ] 4.1 Create useFirestoreQuery hook for real-time data
    - Implement Firestore listener setup and cleanup
    - Add loading and error states
    - Handle query constraints (where, orderBy, limit)
    - _Requirements: 10.1, 10.2, 10.4_
  
  - [ ] 4.2 Create useOptimisticUpdate hook
    - Implement optimistic UI update pattern
    - Add rollback on error functionality
    - _Requirements: 10.3, 10.5_
  
  - [ ]* 4.3 Write property test for optimistic update rollback
    - **Property 7: Optimistic Update Rollback**
    - **Validates: Requirements 10.5**
  
  - [ ] 4.4 Create usePagination hook
    - Implement pagination state management
    - Add page navigation functions
    - _Requirements: 12.1_

- [ ] 5. Checkpoint - Ensure foundation is solid
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement Technician Management page
  - [ ] 6.1 Create TechnicianTable component with filters and search
    - Display technicians with status indicators
    - Add status filter dropdown
    - Implement search by name/phone with debouncing
    - _Requirements: 1.1, 1.2, 1.3_
  
  - [ ]* 6.2 Write property test for technician filtering
    - **Property 1: Data Filtering Consistency (Technicians)**
    - **Validates: Requirements 1.2**
  
  - [ ]* 6.3 Write property test for technician search
    - **Property 2: Search Result Relevance (Technicians)**
    - **Validates: Requirements 1.3**
  
  - [ ] 6.4 Create TechnicianDetailModal component
    - Display complete technician profile
    - Show booking history and wallet balance
    - Add edit profile functionality
    - _Requirements: 1.10_
  
  - [ ] 6.5 Implement technician approval workflow
    - Create ApprovalDialog with approve/reject options
    - Call admin_approveTechnicianApplication Cloud Function
    - Show success/error feedback
    - _Requirements: 1.4, 1.5_
  
  - [ ] 6.6 Implement technician suspension and reactivation
    - Add suspend action with reason input
    - Add reactivate action
    - Call admin_manageUser Cloud Function
    - _Requirements: 1.6, 1.7_
  
  - [ ] 6.7 Implement availability toggle
    - Add toggle switch in table
    - Call admin_toggleTechAvailability Cloud Function
    - Use optimistic update pattern
    - _Requirements: 1.8_
  
  - [ ]* 6.8 Write unit tests for technician management
    - Test table rendering with various data states
    - Test approval/rejection dialogs
    - Test error handling for API failures
    - _Requirements: 1.1, 1.4, 1.5, 1.6, 1.7, 1.8_

- [ ] 7. Implement Customer Management page
  - [ ] 7.1 Create CustomerTable component with filters and search
    - Display customers with pagination
    - Add status filter (active/blocked)
    - Implement search by name/phone/email with debouncing
    - _Requirements: 2.1, 2.2, 2.3_
  
  - [ ]* 7.2 Write property test for customer filtering
    - **Property 1: Data Filtering Consistency (Customers)**
    - **Validates: Requirements 2.3**
  
  - [ ]* 7.3 Write property test for customer search
    - **Property 2: Search Result Relevance (Customers)**
    - **Validates: Requirements 2.2**
  
  - [ ] 7.4 Create CustomerDetailModal component
    - Display complete customer profile
    - Show booking history
    - Add edit profile functionality
    - _Requirements: 2.4, 2.8_
  
  - [ ] 7.5 Implement customer block/unblock functionality
    - Add block action with reason input
    - Add unblock action
    - Call admin_blockUser Cloud Function
    - _Requirements: 2.6, 2.7_
  
  - [ ]* 7.6 Write unit tests for customer management
    - Test table rendering and pagination
    - Test block/unblock dialogs
    - Test error handling
    - _Requirements: 2.1, 2.6, 2.7_

- [ ] 8. Implement Booking Management page
  - [ ] 8.1 Create BookingTable component with comprehensive filters
    - Display bookings with pagination
    - Add status filter dropdown
    - Add date range filter
    - Implement search by customer name/booking ID
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [ ]* 8.2 Write property test for booking filtering
    - **Property 1: Data Filtering Consistency (Bookings)**
    - **Validates: Requirements 4.2, 4.3**
  
  - [ ]* 8.3 Write property test for booking search
    - **Property 2: Search Result Relevance (Bookings)**
    - **Validates: Requirements 4.4**
  
  - [ ] 8.4 Create BookingDetailModal component
    - Display complete booking information
    - Show customer, technician, service details
    - Display status history timeline
    - _Requirements: 4.5, 4.10_
  
  - [ ] 8.5 Implement technician assignment functionality
    - Create AssignTechnicianDialog with technician selection
    - Call backend Cloud Function for assignment
    - Handle reassignment logic
    - _Requirements: 4.6, 4.7_
  
  - [ ] 8.6 Implement booking status update
    - Add status update dropdown
    - Validate status transitions
    - Call backend Cloud Function
    - _Requirements: 4.8_
  
  - [ ] 8.7 Implement booking cancellation
    - Create CancelDialog with reason input
    - Call backend Cloud Function
    - Show refund status if applicable
    - _Requirements: 4.9_
  
  - [ ]* 8.8 Write unit tests for booking management
    - Test table rendering with filters
    - Test assignment and cancellation dialogs
    - Test status update validation
    - _Requirements: 4.1, 4.6, 4.8, 4.9_

- [ ] 9. Checkpoint - Ensure core entity management is complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Implement Service Catalog Management page
  - [ ] 10.1 Create ServiceTree component for hierarchical display
    - Display services organized by category and subcategory
    - Add expand/collapse functionality
    - Show active/inactive status
    - _Requirements: 3.1_
  
  - [ ] 10.2 Create ServiceFormModal for CRUD operations
    - Add form for creating/editing services
    - Include fields: name, description, price, category, subcategory
    - Validate required fields
    - Call admin_manageService Cloud Function
    - _Requirements: 3.2, 3.3, 3.4_
  
  - [ ]* 10.3 Write property test for form validation
    - **Property 5: Form Validation Completeness (Service Form)**
    - **Validates: Requirements 9.7**
  
  - [ ] 10.4 Create CategoryFormModal for category management
    - Add form for creating categories and subcategories
    - Call admin_manageService Cloud Function
    - _Requirements: 3.7, 3.8_
  
  - [ ] 10.5 Implement service active/inactive toggle
    - Add toggle switch in service tree
    - Call backend Cloud Function
    - Use optimistic update
    - _Requirements: 3.5_
  
  - [ ] 10.6 Implement service reordering
    - Add drag-and-drop or up/down buttons
    - Call backend Cloud Function to update display order
    - _Requirements: 3.6_
  
  - [ ]* 10.7 Write unit tests for service management
    - Test service tree rendering
    - Test CRUD operations
    - Test validation errors
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 11. Implement Finance and Payout Management page
  - [ ] 11.1 Create PayoutTable component with filters
    - Display payout requests with status indicators
    - Add status filter (pending, approved, completed, failed)
    - Show technician name, amount, request date
    - _Requirements: 5.1, 5.2_
  
  - [ ]* 11.2 Write property test for payout filtering
    - **Property 1: Data Filtering Consistency (Payouts)**
    - **Validates: Requirements 5.2**
  
  - [ ] 11.3 Create WalletBalanceCard component
    - Display technician wallet balance
    - Show transaction history
    - Add manual adjustment button
    - _Requirements: 5.3_
  
  - [ ] 11.4 Implement payout approval
    - Create approval dialog with confirmation
    - Call backend Cloud Function to initiate payout
    - Show processing status
    - Handle failure cases with error display
    - _Requirements: 5.4, 5.8_
  
  - [ ] 11.5 Implement wallet balance adjustment
    - Create AdjustmentDialog with amount and reason
    - Validate adjustment amount
    - Call backend Cloud Function
    - _Requirements: 5.6_
  
  - [ ] 11.6 Create financial reports view
    - Display revenue, commission, payout summaries
    - Add date range filter
    - Show charts for trends
    - _Requirements: 5.7_
  
  - [ ]* 11.7 Write unit tests for finance management
    - Test payout table and filters
    - Test approval workflow
    - Test wallet adjustment
    - _Requirements: 5.1, 5.4, 5.6_

- [ ] 12. Implement Banner Management page
  - [ ] 12.1 Create BannerGrid component
    - Display banners in grid layout with preview images
    - Show active/inactive status
    - Add reorder functionality
    - _Requirements: 6.1_
  
  - [ ] 12.2 Create BannerFormModal with image upload
    - Add form fields: title, description, linked service
    - Integrate ImageUpload component
    - Validate image format (JPEG, PNG) and size (max 2MB)
    - Upload to Firebase Storage
    - Call admin_manageServiceBanners Cloud Function
    - _Requirements: 6.2, 6.3, 6.7_
  
  - [ ] 12.3 Implement banner delete functionality
    - Create delete confirmation dialog
    - Delete image from Firebase Storage
    - Call backend Cloud Function
    - _Requirements: 6.4_
  
  - [ ] 12.4 Implement banner active/inactive toggle
    - Add toggle switch in banner grid
    - Call backend Cloud Function
    - _Requirements: 6.5_
  
  - [ ] 12.5 Implement banner reordering
    - Add drag-and-drop or up/down buttons
    - Call backend Cloud Function to update display order
    - _Requirements: 6.6_
  
  - [ ]* 12.6 Write unit tests for banner management
    - Test banner grid rendering
    - Test image upload validation
    - Test CRUD operations
    - _Requirements: 6.1, 6.2, 6.7_

- [ ] 13. Checkpoint - Ensure financial and content management is complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 14. Implement Settings Management page
  - [ ] 14.1 Create SettingsForm component
    - Display all configurable system parameters
    - Add maintenance mode toggle
    - Add service availability hours configuration
    - Call backend Cloud Function to save settings
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.7_
  
  - [ ] 14.2 Create AdminUserTable component
    - Display admin users with roles and permissions
    - Add create new admin button
    - Add edit permissions functionality
    - _Requirements: 7.5, 7.6_
  
  - [ ] 14.3 Implement admin user creation
    - Create form modal for new admin user
    - Validate email and role
    - Call backend Cloud Function
    - _Requirements: 7.5_
  
  - [ ] 14.4 Implement admin permission updates
    - Create permission editor dialog
    - Call backend Cloud Function
    - _Requirements: 7.6_
  
  - [ ]* 14.5 Write unit tests for settings management
    - Test settings form rendering
    - Test maintenance mode toggle
    - Test admin user management
    - _Requirements: 7.1, 7.2, 7.5, 7.6_

- [ ] 15. Implement Audit Logs page
  - [ ] 15.1 Create AuditLogTable component
    - Display audit logs with pagination
    - Show timestamp, admin user, action, entity
    - Add filters: date range, admin user, action type
    - Call admin_getAuditLogs Cloud Function
    - _Requirements: 8.4_
  
  - [ ] 15.2 Create LogDetailModal component
    - Display detailed log information
    - Show before/after changes if available
    - Display metadata
    - _Requirements: 8.4_
  
  - [ ]* 15.3 Write unit tests for audit logs
    - Test table rendering with filters
    - Test detail modal
    - _Requirements: 8.4_

- [ ] 16. Implement Dashboard page
  - [ ] 16.1 Create StatCard components for key metrics
    - Display total revenue, bookings today, active bookings
    - Show pending KYC, online technicians, total customers
    - Call admin_getDashboardStats Cloud Function
    - _Requirements: Requirements not explicitly listed, but implied_
  
  - [ ] 16.2 Create RevenueChart component
    - Display revenue and bookings over time
    - Use Recharts library
    - Add date range selector
    - _Requirements: Requirements not explicitly listed, but implied_
  
  - [ ] 16.3 Create RecentBookingsTable component
    - Display recent bookings with status
    - Add click to view details
    - _Requirements: Requirements not explicitly listed, but implied_
  
  - [ ]* 16.4 Write unit tests for dashboard
    - Test stat cards rendering
    - Test chart rendering
    - Test recent bookings table
    - _Requirements: Requirements not explicitly listed, but implied_

- [ ] 17. Implement comprehensive error handling
  - [ ] 17.1 Create error handling utilities
    - Implement getErrorMessage function for user-friendly messages
    - Add error logging with context
    - Create error boundary component
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_
  
  - [ ]* 17.2 Write property test for error message display
    - **Property 6: Error Message Display**
    - **Validates: Requirements 9.5, 11.1**
  
  - [ ] 17.3 Add error handling to all API calls
    - Wrap all adminApi calls in try-catch
    - Display user-friendly error messages
    - Add retry functionality for network errors
    - _Requirements: 11.1, 11.2_
  
  - [ ] 17.4 Add form validation error display
    - Show field-level validation errors
    - Prevent submission with invalid data
    - _Requirements: 11.4_
  
  - [ ]* 17.5 Write unit tests for error handling
    - Test error message display
    - Test retry functionality
    - Test validation error display
    - _Requirements: 11.1, 11.2, 11.4_

- [ ] 18. Implement performance optimizations
  - [ ] 18.1 Add debouncing to search inputs
    - Implement 300ms debounce on all search fields
    - _Requirements: 12.2_
  
  - [ ] 18.2 Optimize image loading
    - Use Next.js Image component
    - Add lazy loading for images
    - _Requirements: 12.4_
  
  - [ ] 18.3 Implement query result caching
    - Cache service catalog data
    - Cache frequently accessed configuration
    - _Requirements: 12.5_
  
  - [ ]* 18.4 Write unit tests for performance features
    - Test debouncing behavior
    - Test caching logic
    - _Requirements: 12.2, 12.5_

- [ ] 19. Checkpoint - Ensure all features are implemented
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 20. Write comprehensive test suite
  - [ ]* 20.1 Complete all property-based tests
    - Ensure all 7 properties have test implementations
    - Run with minimum 100 iterations each
    - Verify all tests pass
    - _Requirements: All testable requirements_
  
  - [ ]* 20.2 Complete all unit tests
    - Achieve minimum 80% code coverage
    - Test all components, hooks, and utilities
    - Test error conditions and edge cases
    - _Requirements: All requirements_
  
  - [ ]* 20.3 Perform integration testing
    - Test authentication flow end-to-end
    - Test complete workflows (approve technician, assign booking, approve payout)
    - Test real-time updates with multiple sessions
    - _Requirements: 8.2, 10.1, 10.4_

- [ ] 21. UI/UX polish and refinement
  - [ ] 21.1 Ensure consistent styling across all pages
    - Verify button styles, colors, spacing
    - Check typography consistency
    - Ensure proper alignment in tables and forms
    - _Requirements: 9.1, 9.2, 9.9_
  
  - [ ] 21.2 Add loading states to all async operations
    - Show spinners during API calls
    - Disable buttons during processing
    - _Requirements: 9.3_
  
  - [ ] 21.3 Verify responsive design on tablet
    - Test all pages on tablet viewport
    - Adjust layout as needed
    - _Requirements: 9.8_
  
  - [ ] 21.4 Add confirmation dialogs to all destructive actions
    - Verify delete, block, cancel actions have confirmations
    - _Requirements: 9.6_

- [ ] 22. Documentation and deployment preparation
  - [ ] 22.1 Write deployment documentation
    - Document environment setup
    - Document deployment process
    - Document rollback procedure
    - _Requirements: Deployment strategy from design_
  
  - [ ] 22.2 Set up error tracking and monitoring
    - Configure error logging service
    - Set up performance monitoring
    - Create monitoring dashboard
    - _Requirements: Monitoring from design_
  
  - [ ] 22.3 Create admin user guide
    - Document all features and workflows
    - Add screenshots and examples
    - Include troubleshooting section
    - _Requirements: All requirements_

- [ ] 23. Final checkpoint and deployment
  - Ensure all tests pass, ask the user if questions arise.
  - Verify all features are working correctly
  - Perform final code review
  - Deploy to production

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation and allow for user feedback
- Property tests validate universal correctness properties with randomized inputs
- Unit tests validate specific examples, edge cases, and integration points
- The implementation follows a phased approach to minimize risk and enable early feedback
