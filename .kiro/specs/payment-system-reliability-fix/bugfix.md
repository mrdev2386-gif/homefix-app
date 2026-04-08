# Bugfix Requirements Document

## Introduction

During the final payment system audit and real-world testing validation, critical code consistency issues were discovered in the HomeFix customer app that violate clean architecture principles and create maintenance risks. While the backend payment system achieved an A- rating (92/100) and is production-ready, the frontend codebase contains architectural violations that must be fixed before launch.

These issues do not represent functional bugs but rather architectural debt that:
- Violates the established clean architecture pattern (UI → Provider → Service → Data)
- Creates multiple sources of truth for critical operations
- Introduces code bloat that slows compilation and increases bundle size
- Makes the codebase harder to test, debug, and maintain

The system currently works correctly, but these violations create technical debt that will compound over time and increase the risk of future bugs.

## Bug Analysis

### Current Behavior (Defect)

#### 1. Clean Architecture Violations

1.1 WHEN UI components need to read user profiles THEN the system directly accesses FirebaseFirestore.instance bypassing UserService (urgent_booking_screen.dart:44, dashboard_app_bar.dart:153)

1.2 WHEN UI components need to fetch technicians THEN the system directly queries Firestore collections bypassing TechnicianService (urgent_booking_screen.dart:120, service_details_screen.dart:140)

1.3 WHEN UI components need to display categories THEN the system directly streams from Firestore bypassing CategoryService (category_chip_bar.dart:38)

1.4 WHEN UI components need to access services THEN the system directly reads Firestore documents bypassing FirestoreService (service_details_screen.dart:68, category_technicians_screen.dart:20)

1.5 WHEN UI components need to display custom requests THEN the system directly streams from custom_requests collection bypassing service layer (custom_request_status_widget.dart:15)

1.6 WHEN UI components need to show banners THEN the system directly queries banners collection bypassing service layer (banner_slider.dart:29)

#### 2. Duplicate Business Logic

1.7 WHEN creating a booking from customer_booking_screen THEN the system directly calls FunctionsHelper.getCallable('createBookingRequest') bypassing BookingService (customer_booking_screen.dart:512)

1.8 WHEN creating an urgent booking THEN the system directly calls FunctionsHelper.getCallable('createBookingRequest') bypassing BookingService (urgent_booking_screen.dart:351)

#### 3. Code Bloat

1.9 WHEN the codebase is compiled THEN the system includes 47 unused imports increasing compilation time and bundle size

1.10 WHEN the codebase is analyzed THEN the system contains 15 unused variables creating confusion and maintenance overhead

1.11 WHEN the codebase is reviewed THEN the system contains 5 unused functions that serve no purpose and add complexity

### Expected Behavior (Correct)

#### 1. Clean Architecture Compliance

2.1 WHEN UI components need to read user profiles THEN the system SHALL use UserService.instance.getUserProfile() maintaining clean architecture separation

2.2 WHEN UI components need to fetch technicians THEN the system SHALL use TechnicianService or FirestoreService methods maintaining service layer abstraction

2.3 WHEN UI components need to display categories THEN the system SHALL use CategoryService.instance methods maintaining single source of truth

2.4 WHEN UI components need to access services THEN the system SHALL use FirestoreService.instance methods maintaining proper layer separation

2.5 WHEN UI components need to display custom requests THEN the system SHALL use a dedicated CustomRequestService maintaining clean architecture

2.6 WHEN UI components need to show banners THEN the system SHALL use a dedicated BannerService or FirestoreService maintaining service layer pattern

#### 2. Single Source of Truth

2.7 WHEN creating a booking from any screen THEN the system SHALL use BookingProvider.createBookingRequest() or BookingService.createBookingRequest() maintaining single booking creation path

2.8 WHEN creating an urgent booking THEN the system SHALL use the same BookingProvider.createBookingRequest() method ensuring consistent behavior and validation

#### 3. Clean Codebase

2.9 WHEN the codebase is compiled THEN the system SHALL contain zero unused imports ensuring fast compilation and minimal bundle size

2.10 WHEN the codebase is analyzed THEN the system SHALL contain zero unused variables ensuring code clarity and maintainability

2.11 WHEN the codebase is reviewed THEN the system SHALL contain zero unused functions ensuring every line of code serves a purpose

### Unchanged Behavior (Regression Prevention)

#### 1. Functional Preservation

3.1 WHEN users create bookings through any flow THEN the system SHALL CONTINUE TO create bookings successfully with identical validation and error handling

3.2 WHEN users view their booking history THEN the system SHALL CONTINUE TO display all bookings with correct status and details

3.3 WHEN users browse services and technicians THEN the system SHALL CONTINUE TO show accurate, real-time data from Firestore

3.4 WHEN users interact with categories and filters THEN the system SHALL CONTINUE TO provide the same filtering and navigation experience

3.5 WHEN users view custom requests THEN the system SHALL CONTINUE TO display request status and details correctly

3.6 WHEN users see promotional banners THEN the system SHALL CONTINUE TO display banners with correct images and links

#### 2. Performance Preservation

3.7 WHEN the app loads data from Firestore THEN the system SHALL CONTINUE TO use the same caching and streaming strategies ensuring no performance degradation

3.8 WHEN users navigate between screens THEN the system SHALL CONTINUE TO provide the same responsive experience with no additional latency

#### 3. Error Handling Preservation

3.9 WHEN network errors occur during data fetching THEN the system SHALL CONTINUE TO handle errors gracefully with appropriate user feedback

3.10 WHEN Firestore operations fail THEN the system SHALL CONTINUE TO provide the same error messages and recovery options

#### 4. State Management Preservation

3.11 WHEN data updates in Firestore THEN the system SHALL CONTINUE TO reflect changes in real-time through existing stream subscriptions

3.12 WHEN users perform actions that modify data THEN the system SHALL CONTINUE TO update UI state correctly through existing provider patterns
