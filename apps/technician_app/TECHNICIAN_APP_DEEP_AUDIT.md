# HomeFix Technician App — Deep Codebase Audit

Generated: 2026-04-06

---

## 1. PROJECT STRUCTURE (REAL, FROM CODE)

```
lib/
├── main.dart                          (745 lines — BLOATED)
├── firebase_options.dart
├── core/
│   ├── app_theme.dart
│   ├── constants/india_locations.dart
│   ├── firebase/
│   │   ├── firebase_functions.dart         (correct — single instance)
│   │   ├── firebase_functions_instance.dart (DEAD — never imported)
│   │   └── firebase_init.dart
│   ├── models/
│   │   ├── booking.dart, bank_account.dart, wallet.dart, etc.
│   │   ├── coupon.dart         (LIKELY UNUSED)
│   │   ├── customer.dart       (LIKELY UNUSED — not needed in technician app)
│   │   ├── earning.dart        (LIKELY UNUSED)
│   │   └── payment_method.dart (LIKELY UNUSED)
│   ├── providers/
│   │   └── technician_provider.dart  (766 lines — GOD CLASS)
│   ├── services/
│   │   ├── booking_service.dart
│   │   ├── functions_service.dart    (525 lines)
│   │   ├── image_compression_service.dart  (DUPLICATE of ImageSizeGuard)
│   │   ├── notifications_service.dart
│   │   ├── onboarding_service.dart
│   │   ├── push_notification_service.dart  (DUPLICATE FCM + FIREBASE VIOLATION)
│   │   ├── technician_service.dart
│   │   └── wallet_service.dart
│   ├── utils/
│   │   ├── image_size_guard.dart
│   │   ├── image_upload_service.dart  (WRONG LAYER — service in utils/)
│   │   ├── image_utils.dart           (TINY — likely dead)
│   │   └── ...
│   └── widgets/
│       ├── technician_status_guard.dart  (DUPLICATE approval routing)
│       └── ...
├── features/
│   ├── availability/presentation/    (EMPTY SHELL)
│   ├── custom_requests_screen.dart   (ORPHAN — outside feature folder)
│   ├── job_requests/
│   │   ├── job_requests_screen.dart       (DUPLICATE job screen)
│   │   └── technician_job_screen.dart     (DUPLICATE + FIREBASE VIOLATION)
│   ├── notifications/presentation/   (EMPTY SHELL)
│   ├── onboarding/                   (EMPTY SHELL)
│   ├── profile/presentation/
│   │   ├── profile_screen.dart            (PASSTHROUGH — 16 lines, zero value)
│   │   └── technician_profile_screen.dart (127KB — MASSIVELY BLOATED)
│   ├── services/presentation/        (EMPTY SHELL)
│   └── technician/
│       ├── screens/profile_under_review_screen.dart (DUPLICATE approval screen)
│       └── services/add_service_screen.dart          (57KB — BLOATED)
└── screens/                          (LEGACY LAYER — conflicts with features/)
    ├── application_status_screen.dart     (DUPLICATE approval screen)
    ├── dashboard_home_enhanced.dart       (49KB — BLOATED)
    ├── waiting_for_approval_screen.dart   (DUPLICATE approval screen)
    ├── wallet_screen.dart                 (79KB — LARGEST FILE)
    └── onboarding_steps/
        ├── firestore_payload_example.js   (JS FILE IN lib/ — cleanup artifact)
        ├── step4_bank_details.dart        (DEAD — one of two step4s)
        └── step4_work_portfolio.dart      (ONE OF TWO step4s)
```

---

## 2. ISSUES FOUND — CATEGORY-WISE

### CATEGORY 1 — DUPLICATE CODE

**Issue 1.1 — Duplicate Job Screens**
- `features/job_requests/job_requests_screen.dart` — calls `technicianAcceptBooking` / `technicianRejectBooking` via BookingService
- `features/job_requests/technician_job_screen.dart` — calls `technicianRespondToJob` directly (different function name, possibly nonexistent)
- Both show same ASSIGNED bookings.
- FIX: Delete `technician_job_screen.dart`.

**Issue 1.2 — Four Approval/Status Screens**
- `screens/application_status_screen.dart`
- `screens/waiting_for_approval_screen.dart`
- `core/widgets/technician_status_guard.dart` (inline pending/rejected UI)
- `features/technician/screens/profile_under_review_screen.dart`
- FIX: Keep only `technician_status_guard.dart`. Delete the other three.

**Issue 1.3 — Duplicate FCM Token Management**
- `push_notification_service.dart`: **direct Firestore writes** to `technicians/{uid}/fcmTokens` (VIOLATION)
- `notifications_service.dart`: calls Cloud Function `saveFcmToken` (CORRECT)
- Both initialized in `main.dart`. Double auth listeners. Double writes.
- FIX: Delete `push_notification_service.dart` entirely.

**Issue 1.4 — Duplicate Image Compression**
- `core/services/image_compression_service.dart`
- `core/utils/image_size_guard.dart` (`ImageSizeGuard.validateAndCompress`)
- FIX: Delete `image_compression_service.dart`. Use `ImageSizeGuard` everywhere.

**Issue 1.5 — Three Refresh Methods in TechnicianProvider**
- `refreshTechnicianData()` — via TechnicianService (cache)
- `refreshTechnician()` — direct Firestore server fetch, misses updating `_isApproved`
- `fetchFreshTechnicianData()` — server fetch, returns object but doesn't update provider state
- FIX: Consolidate into one `refreshFromServer()` that updates ALL fields.

**Issue 1.6 — Online Status via Two Different Cloud Function Names**
- `TechnicianProvider.updateOnlineStatus()` → `updateTechnicianStatus`
- `FunctionsService.updateTechnicianOnlineStatus()` → `toggleOnlineStatus`
- FIX: Pick one, wire consistently from provider → service.

---

### CATEGORY 2 — DUPLICATE FILES

**Issue 2.1 — Two Firebase Functions Singleton Classes**
- `core/firebase/firebase_functions.dart` → `FirebaseFunctionsService` (used everywhere)
- `core/firebase/firebase_functions_instance.dart` → `FirebaseFunctionsInstance` (never imported)
- FIX: Delete `firebase_functions_instance.dart`.

**Issue 2.2 — Two Step 4 Files**
- `step4_bank_details.dart` — original (bank details moved out of onboarding)
- `step4_work_portfolio.dart` — current
- FIX: Check `technician_onboarding_flow_screen.dart` imports → delete unused step4.

**Issue 2.3 — `profile_screen.dart` is Pure Passthrough (16 lines)**
- `class ProfileScreen { build() => const TechnicianProfileScreen(); }`
- FIX: Delete. Import `TechnicianProfileScreen` directly in `DashboardScreen`.

**Issue 2.4 — Bank Account Screens in Two Locations**
- `screens/add_bank_account_screen.dart` (legacy)
- `features/profile/presentation/edit_bank_details_screen.dart` (feature)
- FIX: Audit which is navigated to → delete the other.

---

### CATEGORY 3 — FIREBASE VIOLATIONS (CRITICAL)

**Violation 3.1 — Direct Firestore Client Writes**

| File | Line | Write |
|---|---|---|
| `core/providers/technician_provider.dart` | 108–115 | `technicians/{uid}.update({'email': ...})` |
| `core/providers/technician_provider.dart` | 711–724 | `technicians/{uid}.update({'profileApprovalRequested': true, ...})` |
| `core/services/push_notification_service.dart` | 191–211 | `technicians/{uid}/fcmTokens.set(...)` + `technicians/{uid}.update({fcmToken: ...})` |

FIX:
- Email: Call a `syncTechnicianEmail` Cloud Function instead.
- `profileApprovalRequested`: Call a `requestAdminVerification` Cloud Function.
- FCM token: Already correctly handled in `notifications_service.dart` via `saveFcmToken` CF.

**Violation 3.2 — Deprecated Firebase Auth Method**
- File: `core/services/functions_service.dart` line 406
- `await user.updateEmail(newEmail)` — DEPRECATED in `firebase_auth ^5.0.0`
- FIX: Replace with `user.verifyBeforeUpdateEmail(newEmail)`.

**Violation 3.3 — `technician_job_screen.dart` Raw Firestore Stream**
- Line 47–52: `FirebaseFirestore.instance.collection('bookings').where(...).snapshots()`
- Bypasses `BookingService` entirely. No error handling layer.
- FIX: Delete this file (duplicate anyway).

**Violation 3.4 — Dead Null Check**
- File: `functions_service.dart` line 408
- `if (user != null && !user.emailVerified)` — `user` was already null-checked two lines up
- FIX: Simplify the condition.

---

### CATEGORY 4 — MULTIPLE LOGIC IMPLEMENTATIONS

**Issue 4.1 — Routing Logic in 3 Places**
- `AuthGate` uses `tech.getProfileCompletion()` (dynamic model method)
- `TechnicianStatusGuard` uses `_technicianData!['profileCompletion']` (raw Firestore int, may be stale)
- These can disagree about routing for the same user.
- FIX: `AuthGate` is sole routing authority. `TechnicianStatusGuard` consumes `TechnicianProvider`.

**Issue 4.2 — Booking Field Name and Status String Inconsistency**
- `getPendingBookings()`: field `technicianId`, status `['ASSIGNED', 'approved_by_admin']`
- `getActiveBookings()`: field `technicianId`, status `['ASSIGNED', 'assigned', 'accepted', ...]`
- `getAvailableBookings()`: field `assignedTechnicianId`, status `['pending', 'confirmed']`
- Mixed case `'ASSIGNED'` vs `'assigned'` — Firestore is case-sensitive.
- FIX: Create `BookingStatus` constants. Normalize field names to match backend.

**Issue 4.3 — Three AuthStateChanges Listeners**
- `TechnicianProvider` constructor
- `NotificationsService._setupTokenHandlers()`
- `PushNotificationService._setupAuthStateListener()`
- Triple FCM token writes on every login.
- FIX: Single auth listener in `TechnicianProvider`. Others react via provider.

---

### CATEGORY 5 — ARCHITECTURE ISSUES

**Issue 5.1 — `main.dart` is 745 Lines (God File)**
- Contains app init, error widgets, auth gate logic, loading UIs, App Check UI.
- FIX: Extract to `app.dart`, `auth_gate.dart`, `core/widgets/loading_screen.dart`, `core/widgets/error_boundary.dart`.

**Issue 5.2 — Dual Screen Layer (`screens/` AND `features/`)**
- All large screens still in legacy `lib/screens/`. `lib/features/` is mostly empty shells.
- FIX: Migrate `lib/screens/` content into `lib/features/` subdirectories over phases.

**Issue 5.3 — `TechnicianProvider` is a God Class (766 lines)**
- Handles auth, FCM, onboarding, KYC, image upload, skills, sign out, admin review request.
- FIX: Split into `AuthProvider`, `OnboardingProvider`, `ProfileProvider`.

**Issue 5.4 — Four Empty Feature Shells**
- `features/availability/presentation/`, `features/notifications/presentation/`, `features/onboarding/`, `features/services/presentation/`
- FIX: Populate (migrate screens) or delete.

**Issue 5.5 — `image_upload_service.dart` in `core/utils/`**
- A service making network/storage calls does not belong in `utils/`.
- FIX: Move to `core/services/media_service.dart`.

---

### CATEGORY 6 — STATE MANAGEMENT ISSUES

**Issue 6.1 — NotificationsService Singleton + ChangeNotifierProvider Anti-pattern**
- Eagerly init in `main()` outside widget tree, then registered as `ChangeNotifierProvider`.
- Dispose lifecycle broken. Init errors can't surface to UI.
- FIX: Don't eagerly init. Use `FutureProvider` or lazy initialization.

**Issue 6.2 — `TechnicianStatusGuard` Duplicates Provider's Firestore Query**
- Makes own `get()` call — extra Firestore read. Provider stream already has this data.
- FIX: Consume `context.watch<TechnicianProvider>()` instead.

**Issue 6.3 — `JobRequestsScreen` Instantiates Service Directly**
- `final BookingService _bookingService = BookingService();` — not in provider tree.
- FIX: Provide via `Provider<BookingService>`.

---

### CATEGORY 7 — UNUSED / DEAD CODE

| Item | Reason |
|---|---|
| `core/firebase/firebase_functions_instance.dart` | Never imported |
| `core/models/coupon.dart` | No reference found |
| `core/models/customer.dart` | Technician app needs no customer model |
| `core/models/earning.dart` | Superseded by wallet_transaction.dart |
| `core/models/payment_method.dart` | No reference found |
| `features/job_requests/technician_job_screen.dart` | Not in any route |
| `screens/application_status_screen.dart` | Redundant with status guard |
| `screens/waiting_for_approval_screen.dart` | Redundant with status guard |
| `features/technician/screens/profile_under_review_screen.dart` | Redundant |
| `core/services/image_compression_service.dart` | Duplicates ImageSizeGuard |
| `core/utils/image_utils.dart` | 816 bytes, likely absorbed |
| `screens/onboarding_steps/firestore_payload_example.js` | Debug artifact |
| `BookingService.getAvailableBookings()` | Legacy auto-assign flow |
| `BookingService.claimBooking()` | Legacy function |
| `TechnicianProvider.onboard()` | Thin wrapper, likely unused |

---

### CATEGORY 8 — DEPENDENCY ISSUES

| Package | Status | Action |
|---|---|---|
| `dio: ^5.3.0` | Not used | Remove |
| `google_sign_in: ^6.2.1` | Not used (phone auth app) | Remove |
| `rxdart: ^0.28.0` | 1 use only | Replace with standard Dart, remove |
| `image: ^4.1.0` | Audit needed | Verify actual usage |
| `firebase_performance: ^0.10.0` | Minimal usage | Keep, but audit traces |

---

### CATEGORY 9 — MISSING IMPLEMENTATIONS

| Feature | Status |
|---|---|
| Notifications Screen | Empty feature shell — no UI screen |
| Availability Scheduling | Empty feature shell |
| QR Payment full flow | Partial in wallet_screen.dart |
| Navigation to Reviews screen | May not be wired up |

---

### CATEGORY 10 — PERFORMANCE ISSUES

| File | Problem |
|---|---|
| `wallet_screen.dart` (79KB) | Split into 4 focused screens |
| `technician_profile_screen.dart` (127KB) | Split into section widgets |
| `dashboard_home_enhanced.dart` (49KB) | Extract cards/sections |
| `add_service_screen.dart` (57KB) | Split form sections |
| `main.dart` (745 lines) | Extract auth gate + widgets |
| `print()` in production code | `booking_service.dart`, `technician_job_screen.dart`, `functions_service.dart` |
| Triple authStateChanges listeners | Extra reads on every login |
| `TechnicianStatusGuard` extra Firestore read | Use provider stream instead |

Debug print locations:
- `booking_service.dart` lines 118, 141, 171, 190: `print("CALLING FUNCTION: ...")`
- `technician_job_screen.dart` lines 30, 55–59: debug dumps
- `functions_service.dart` lines 321–323: `print('[AUTH DEBUG] ...')`
- `technician_provider.dart` line 245: `print('[Provider] ...')`

---

## 3. CLEAN ARCHITECTURE SUGGESTION

```
lib/
├── main.dart               (< 60 lines — only Firebase init + runApp)
├── app.dart                (MaterialApp + routing)
├── auth_gate.dart          (routing logic only)
├── firebase_options.dart
│
├── core/
│   ├── theme/app_theme.dart
│   ├── constants/india_locations.dart
│   ├── firebase/
│   │   ├── firebase_init.dart
│   │   └── firebase_functions.dart
│   ├── models/             (only models confirmed in use)
│   ├── providers/
│   │   ├── technician_provider.dart      (thin)
│   │   └── notifications_provider.dart
│   ├── services/
│   │   ├── booking_service.dart
│   │   ├── functions_service.dart
│   │   ├── media_service.dart            (merged compress + upload)
│   │   ├── notifications_service.dart    (FCM + notifications)
│   │   ├── onboarding_service.dart
│   │   ├── technician_service.dart
│   │   └── wallet_service.dart
│   ├── utils/
│   │   ├── app_logger.dart
│   │   ├── availability_utils.dart
│   │   ├── firestore_safe_parser.dart
│   │   └── transaction_display_helper.dart
│   └── widgets/
│       ├── error_boundary.dart
│       ├── loading_screen.dart
│       ├── safe_network_image.dart
│       └── searchable_dropdown.dart
│
└── features/
    ├── auth/screens/           (login, otp, app_onboarding)
    ├── onboarding/
    │   ├── screens/flow + steps/
    │   └── widgets/technician_status_guard.dart
    ├── dashboard/screens/      (dashboard_screen + home)
    ├── jobs/screens/           (job_requests, job_details)
    ├── services/screens/       (services_screen, add_service)
    ├── profile/screens/        (profile, edit_personal, edit_bank, reviews)
    ├── wallet/screens/         (overview, withdrawal, history, qr)
    ├── earnings/screens/
    ├── notifications/screens/  (TO BE IMPLEMENTED)
    ├── availability/screens/   (TO BE IMPLEMENTED)
    ├── kyc/screens/
    └── support/screens/
```

---

## 4. SAFE REFACTOR PLAN

### Phase 1 — Zero-Risk Cleanups
1. Delete `core/firebase/firebase_functions_instance.dart`
2. Delete 4 empty feature shells
3. Delete `onboarding_steps/firestore_payload_example.js`
4. Remove `dio`, `google_sign_in` from pubspec.yaml → `flutter pub get`
5. Fix duplicate cloud_functions import in `onboarding_service.dart` (lines 3+5)
6. Replace all `print()` with `debugPrint()` or `AppLogger`
7. Fix deprecated `user.updateEmail()` → `user.verifyBeforeUpdateEmail()`
8. Remove dead null check in `functions_service.dart` line 408

### Phase 2 — Duplicate File Elimination
9. Delete `technician_job_screen.dart` (not reachable from any route)
10. Delete unused `step4_bank_details.dart` (verify which step4 is in flow)
11. Delete `profile_screen.dart` → update dashboard_screen.dart import
12. Audit and delete unused bank account screen
13. Delete `push_notification_service.dart` + remove init from `main.dart`
14. Delete `application_status_screen.dart`, `waiting_for_approval_screen.dart`, `profile_under_review_screen.dart`
15. Delete unused models: coupon, customer, earning, payment_method
16. Delete `image_compression_service.dart`

### Phase 3 — Firebase Violation Fixes (MUST DO)
17. Replace direct `technicians/{uid}.update({'email': ...})` with Cloud Function call
18. Replace `_requestAdminVerification()` direct write with Cloud Function callable
19. Verify `saveFcmToken` CF exists on backend

### Phase 4 — State Management Cleanup
20. Consolidate 3 refresh methods → single `refreshFromServer()`
21. Fix `refreshTechnician()` to update `_isApproved`, `_profileApprovalRequested`, `_profileRejected`
22. Fix `TechnicianStatusGuard` to consume `TechnicianProvider` instead of direct Firestore
23. Fix `NotificationsService` singleton + `ChangeNotifierProvider` anti-pattern

### Phase 5 — Logic Unification
24. Create `BookingStatus` constant class
25. Fix mixed-case status strings in all queries
26. Align `technicianId` vs `assignedTechnicianId` (check backend first!)
27. Consolidate online status to single Cloud Function via FunctionsService
28. Replace rxdart `.onErrorReturn([])` → standard `.handleError()` → remove dep

### Phase 6 — File Splitting and Architecture
29. Split `wallet_screen.dart` (79KB) → 4 screens
30. Split `dashboard_home_enhanced.dart` (49KB) → widgets
31. Split `technician_profile_screen.dart` (127KB) → sections
32. Split `add_service_screen.dart` (57KB)
33. Extract `main.dart` → `app.dart` + `auth_gate.dart`
34. Move `image_upload_service.dart` → `core/services/media_service.dart`
35. Migrate `lib/screens/` → `lib/features/`
36. Implement `notifications_screen.dart`
37. Implement `availability_screen.dart`

---

## 5. AUDIT SCORECARD

| Category | Issues | Severity |
|---|---|---|
| Duplicate Code | 6 | CRITICAL |
| Duplicate Files | 5 | CRITICAL |
| Firebase Violations | 4 | CRITICAL |
| Multiple Logic Implementations | 3 | HIGH |
| Architecture Issues | 5 | HIGH |
| Missing Features | 4 | HIGH |
| State Management | 3 | MEDIUM |
| Dead/Unused Code | 15+ | MEDIUM |
| Dependencies | 5 | MEDIUM |
| Performance | 8 | MEDIUM |

**Overall App Health: 4/10 — Functional but not production-scalable.**
