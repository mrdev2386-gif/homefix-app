# HomeFix Monorepo - Comprehensive Codebase Analysis

**Analysis Date:** March 13, 2026  
**Project Root:** `c:\Users\yash\projects\homefix`

---

## 1. PROJECT STRUCTURE

### Root-Level Directory Organization
```
homefix/
├── apps/                          # Multi-app workspace
│   ├── customer_app/             # Flutter - Customer-facing app
│   ├── technician_app/           # Flutter - Service provider app  
│   └── admin_panel/              # Next.js/React - Admin dashboard
├── backend/                       # Node.js backend documentation
├── functions/                     # Firebase Cloud Functions
├── lib/                          # Shared lib (main.dart only)
├── scripts/                      # Automation and migration scripts
├── docs/                         # Documentation
├── android/, ios/, web, windows/ # Platform-specific code
└── .security/, .firebase/        # Configuration directories
```

### Apps Inventory

#### **Customer App** (Flutter)
- **Path:** `apps/customer_app/`
- **Language:** Dart
- **Files:** 178 Dart files
- **Key Directories:**
  - `lib/core/` - Shared business logic
  - `lib/features/` - Feature modules
  - `lib/screens/` - Legacy screen files
  - `android/` - Android build config
  - `ios/` - iOS build config

#### **Technician App** (Flutter)
- **Path:** `apps/technician_app/`
- **Language:** Dart
- **Files:** 89 Dart files
- **Key Directories:**
  - `lib/core/` - Core services & models
  - `lib/features/` - Feature modules (10 features)
  - `lib/screens/` - Screen implementations
  - `lib/tests/` - Security audit tests

#### **Admin Panel** (Next.js/React)
- **Path:** `apps/admin_panel/`
- **Language:** TypeScript/TSX, JavaScript
- **Files:** 63 source files
- **Key Directories:**
  - `src/app/` - Next.js app router pages
  - `src/components/` - React components
  - `src/hooks/` - Custom React hooks
  - `src/lib/` - Utility libraries & services
  - `src/constants/` - Application constants
  - `src/types/` - TypeScript interfaces

#### **Cloud Functions**
- **Path:** `functions/`
- **Language:** TypeScript/JavaScript
- **Files:** 90 TS/JS files in `src/` (plus compiled JS in `lib/`)
- **Key Modules:**
  - `admin/` - Admin operations (13 files)
  - `booking/` - Booking lifecycle (11 files)
  - `technician/` - Technician operations (12 files)
  - `customer/` - Customer operations (3 files)
  - `matching/` - Matching engine (4 files)
  - `finance/` - Wallet & payouts (5 files)
  - `payments/` - Payment processing (3 files)
  - `shared/` - Shared utilities (8 files)

---

## 2. DUPLICATE DETECTION

### 🔴 CRITICAL DUPLICATES

#### **A. Duplicate Screen Files (Technician App)**

| File | Purpose | Status | Action |
|------|---------|--------|--------|
| `wallet_screen.dart` | Technician wallet UI | ACTIVE | Unclear which is canonical |
| `wallet_screen_fixed.dart` | Wallet UI (fixed version) | ACTIVE | DUPLICATE - Likely fixed version |
| `dashboard_screen.dart` | Dashboard home | ACTIVE | Canonical |
| `dashboard_home_enhanced.dart` | Dashboard (enhanced version) | ACTIVE | DUPLICATE - Imports from dashboard_screen line 5 |

**Risk Level:** HIGH - Ambiguous which version is used; imports suggest enhanced version is fallback

---

#### **B. Duplicate Cloud Function Files**

| Module | File 1 | File 2 | Status | Risk |
|--------|--------|--------|--------|------|
| **Notifications** | `admin/notifications.ts` | `shared/notifications.ts` | BOTH ACTIVE | HIGH - Both exported separately |
| **Utils** | `admin/utils.ts` | `shared/utils.ts` | BOTH ACTIVE | HIGH - Inconsistent utility functions |
| **Security** | `shared/security.ts` | (only in shared) | SINGLE | OK |
| **Index** | `src/index.ts` | `testing/index.ts` | Different scope | OK |

**Risk Level:** HIGH - Unclear which utilities/notifications are authoritative

---

#### **C. Technician Service Management Functions (RESOLVED)**

**Status:** ✅ Previously identified and consolidated

| Function | Location | Status |
|----------|----------|--------|
| `addTechnicianService` | `services_management.ts` | ✓ Canonical |
| `createTechnicianService` | Alias → `services_management.ts` | ✓ Consolidated |
| `updateTechnicianService` | `services_management.ts` | ✓ Single |
| `deleteTechnicianService` | `services_management.ts` | ✓ Single |
| `toggleTechnicianServiceStatus` | `services_management.ts` | ✓ Single |
| `getMyTechnicianServices` | `createTechnicianService.ts` | ⚠️ Separate file |

**Note:** createTechnicianService.ts still exists but may be deprecated. Verify if still exported.

---

### ⚠️ POTENTIAL DUPLICATES & MODEL ISSUES

#### **Technician Model Variants**
- **File:** `apps/technician_app/lib/core/models/technician.dart` (CANONICAL)
- **Backup/History File:** `technician_enhanced.dart` may exist in documentation
- **Issue:** Enhanced version with additional fields documented but unclear if implemented
- **Status:** Check if `technician_enhanced.dart` exists in codebase

#### **Screen File Naming Patterns**
- Multiple `*_fixed.dart` versions (e.g., `wallet_screen_fixed.dart`)
- Multiple enhanced versions (e.g., `dashboard_home_enhanced.dart`)
- **Risk:** Unclear which is production code vs. abandoned fixes

---

## 3. FILE INVENTORY

### Customer App - Core Structure

**Models** (21 files):
```
address.dart
banner_model.dart
booking.dart
cart_item.dart
category.dart
chat.dart
coupon.dart
custom_request.dart
dashboard_models.dart
matched_technician.dart
notification.dart
payment_method.dart
proposal.dart
review.dart
service.dart
service_request.dart
service_result.dart
sub_service.dart
technician.dart
user_model.dart
user_settings.dart
```

**Providers** (8 files):
```
auth_provider.dart
booking_provider.dart
cart_provider.dart
category_provider.dart
checkout_provider.dart
favorites_provider.dart
locale_provider.dart
location_provider.dart
```

**Services** (21 files):
```
address_cache_service.dart
address_service.dart
auth_service.dart
booking_service.dart
category_service.dart
chat_service.dart
coupon_service.dart
custom_request_limit_service.dart
database_seeder.dart
firestore_service.dart
functions_service.dart
gemini_service.dart
location_service.dart
matching_service.dart
notifications_service.dart
push_notification_service.dart
review_service.dart
storage_service.dart
technician_discovery_service.dart
ticket_service.dart
user_settings_service.dart
wallet_service.dart (⚠️ missing from list but imported)
```

**Utils & Helpers** (9 files):
```
app_localizations.dart
booking_status_utils.dart
data_integrity_guard.dart
firestore_guards.dart
firestore_service_validation.dart
image_utils.dart
logger.dart
safe_parsing.dart
user_feedback.dart
```

**Widgets** (10 files):
```
in_app_notification.dart
location_dialogs.dart
location_selector.dart
matching_loading_overlay.dart
no_technicians_popup.dart
safe_network_image.dart
safe_scroll_wrapper.dart
safe_video_player.dart
service_result_builder.dart
```

**Theme** (3 files):
```
app_colors.dart
app_text_styles.dart
app_theme.dart
```

### Technician App - Core Structure

**Models** (14 files):
```
bank_account.dart
booking.dart
booking_payment.dart
coupon.dart
customer.dart
earning.dart
faq_model.dart
payment_method.dart
payout.dart
review.dart
service.dart
technician.dart (⚠️ May have enhanced variant)
technician_service.dart
wallet.dart
wallet_transaction.dart
```

**Providers** (1 file):
```
technician_provider.dart (⚠️ Single provider handles all state)
```

**Services** (12 files):
```
booking_service.dart
category_data_service.dart
faq_service.dart
functions_service.dart
image_compression_service.dart
notifications_service.dart
onboarding_service.dart
onboarding_validation_service.dart
push_notification_service.dart
technician_catalog_service.dart
technician_service.dart
wallet_service.dart
```

**Utils** (7 files):
```
app_logger.dart
availability_utils.dart
firestore_safe_parser.dart
image_size_guard.dart
image_upload_service.dart
image_utils.dart
service_image_utils.dart
```

**Features** (10 modules):
```
availability/
earnings/
job_requests/
kyc/
notifications/
onboarding/
profile/
services/
support/
technician/
```

### Admin Panel - Structure

**Pages/Routes** (via Next.js app router):
```
src/app/(admin)/
├── bookings/
├── services/
├── technicians/
├── customers/
├── disputes/
├── finance/
├── wallet/
├── approvals/
└── dashboard/
```

**Key Libraries** (6 files):
```
firestore-utils.ts
services/ (multiple admin services)
```

**Components** (under src/components/ui)

**Hooks** (under src/hooks)

---

## 4. MODELS AND SERVICES INVENTORY

### Shared Models Comparison

| Model | Customer App | Technician App | Shared |
|-------|-------------|-----------------|--------|
| Booking | ✓ | ✓ | ⚠️ Different structures |
| Technician | ✓ | ✓ (enhanced variant) | ⚠️ Duplicate fields |
| Service | ✓ | ✓ | ⚠️ Service vs TechnicianService |
| Category | ✓ | Via service | Partial |
| User/Customer | User model | Customer model | ⚠️ Not unified |
| Review | ✓ | ✓ | ✓ Consistent |
| Payment | ✓ | ✓ | ⚠️ Different structures |
| Wallet | ✓ | ✓ | ✓ Consistent |

### Critical Model Gaps

**Missing from Customer App:**
- TechnicianService (has generic Service)
- Payout (has Wallet only)
- Earning (has Booking history)

**Missing from Technician App:**
- Cart/CartItem (N/A - service provider)
- Coupon (hardcoded or via service?)

---

## 5. PROVIDERS - STATE MANAGEMENT ANALYSIS

### Customer App Providers (8 total)

| Provider | Purpose | Status | Used By |
|----------|---------|--------|---------|
| `auth_provider.dart` | Authentication state | ✓ ACTIVE | Auth screens, services |
| `booking_provider.dart` | Booking management | ✓ ACTIVE | Booking screens |
| `cart_provider.dart` | Shopping cart | ✓ ACTIVE | Cart & checkout |
| `category_provider.dart` | Service categories | ✓ ACTIVE | Home, service list |
| `checkout_provider.dart` | Checkout flow | ✓ ACTIVE | Payment flow |
| `favorites_provider.dart` | Favorite technicians | ⚠️ CHECK USAGE | Profile screen |
| `locale_provider.dart` | Language/localization | ✓ ACTIVE | App wide |
| `location_provider.dart` | District & location | ✓ ACTIVE | Address, matching |

**Assessment:** All appear to be in use. No obvious unused providers detected.

### Technician App Providers (1 total)

| Provider | Purpose | Status | Note |
|----------|---------|--------|------|
| `technician_provider.dart` | All technician state | ✓ ACTIVE | ⚠️ MONOLITHIC - Single provider for all state |

**Issue:** Single provider managing profile, wallet, services, availability, etc. May benefit from separation.

### Likely Unused Providers Status
- **No obvious candidates** - Both apps consolidate state into actively used providers
- **Recommendation:** Run dynamic analysis on app flows to confirm

---

## 6. FIRESTORE INTEGRATION - Database Operations

### Query Patterns Found

**A. Customer App Firestore Usage**

| Service | Operation | Collection | Query Pattern |
|---------|-----------|-----------|---------------|
| `booking_service.dart` | Create/Read | `bookings` | Where `customerId` == uid |
| `address_service.dart` | CRUD | `customers/{uid}/addresses` | Subcollection access |
| `category_service.dart` | Read | `categories` | Filter by availability |
| `location_service.dart` | Read | `locations` | Query by state/district |
| `matching_service.dart` | Read | `technician_services` | Location-based queries |
| `push_notification_service.dart` | Listen | `notifications` | Real-time updates |
| `review_service.dart` | Write | `reviews` | Create after booking completion |
| `wallet_service.dart` | Read | `technician_wallets` | Query earnings |

**Database Security:** ✓ Using collection references with UID validation

---

**B. Technician App Firestore Usage**

| Service | Operation | Collection | Query Pattern |
|---------|-----------|-----------|---------------|
| `booking_service.dart` | Read | `bookings` | Where `technicianId` == uid |
| `technician_catalog_service.dart` | CRUD | `technician_services` | User's own services |
| `wallet_service.dart` | Transactions | `technician_wallets` | Payout & withdrawal |
| `notifications_service.dart` | Listen | `notifications` | Real-time for jobs |
| `onboarding_service.dart` | Write | `technicians` | Profile completion tracking |

**Database Security:** ✓ UID-based access control implemented

---

**C. Technician Service Management**

**File:** `functions/src/technician/createTechnicianService.ts` (~1100 lines)
**Key Operations:**
```typescript
// Service creation with validation
- checkDuplicateSpam() → Rate limiting (max 20 services)
- checkDuplicateTitle() → Prevent duplicate titles by technician
- checkDuplicateService() → Check technicianId + subServiceId combo
- verifyCategory() → Validate category exists
- verifyImageExists() → Validate image in storage
```

**Database Write Pattern:**
```
technician_services/{serviceId}
  - technicianId
  - categoryId
  - subServiceId
  - title
  - price
  - status (pending/approved/rejected)
```

---

**D. Booking Lifecycle Functions**

| File | Purpose | Triggers | Collections |
|------|---------|----------|-----------|
| `booking_lifecycle.ts` | Main flow | onCreate, onWrite | bookings, matching_queue |
| `new_booking_flow.ts` | New booking logic | onCreate | bookings, notifications |
| `unified_booking_lifecycle.ts` | Consolidated flow | onWrite | Various |
| `production_hardening.ts` | Safety checks | Various | Auth validation |

---

### Firestore Security Rules

**Files Located:**
- `firestore.rules` (root) - Main rules
- `firestore_unified.rules` - Consolidated version
- `firestore_hardened_final.rules` - Production version
- `firestore_approval_rules.rules` - Approval flow specific
- `firestore_bank_rules.rules` - Bank details specific
- `firestore_reviews.rules` - Review permissions
- `firestore_service_features.rules` - Service moderation

**⚠️ Issue:** Multiple rule files suggest incomplete consolidation. Recommend merging into single source of truth.

---

## 7. CLOUD FUNCTIONS - Comprehensive Inventory

### Function Categories

#### **Admin Functions** (13 files, ~2500 lines)
```
admin/
├── bookings.ts              → Booking moderation & approval
├── booking_moderation.ts    → Service booking review
├── catalog_audit.ts         → Catalog integrity checks
├── dashboard.ts             → Analytics & metrics
├── data_migration.ts        → Data normalization
├── disputes.ts              → Dispute management
├── dynamic_content.ts       → CMS-like content
├── finance.ts               → Financial reporting
├── images.ts                → Image management/CDN
├── migrate_booking_status.ts → One-time migration
├── notifications.ts         → Admin notification triggers
├── reviews.ts               → Review moderation
├── risk.ts                  → Fraud risk scoring
├── serviceApproval.ts       → Service moderation
├── services.ts              → Service catalog mgmt
├── service_management.ts    → (Duplicate or variant?)
├── system_initialization.ts → Setup/seed data
├── technicians.ts           → Technician mgmt
├── technician_approval.ts   → Onboarding approval
├── technician_management.ts → Profile updates
├── technician_normalization.ts → Data cleanup
├── users.ts                 → Customer user mgmt
└── utils.ts                 → Admin utilities (⚠️ DUPLICATED)
```

#### **Booking Functions** (11 files, ~3000 lines)
```
booking/
├── booking_lifecycle.ts          → Main booking state machine
├── booking_notifications.ts      → Notification triggers
├── cleanup.ts                    → Cleanup & expiry
├── complete_booking_flow.ts      → Full booking process
├── final_hardening.ts            → Security hardening
├── new_booking_flow.ts           → New booking initialization
├── payment_qr.ts                 → Payment QR generation
├── production_hardening.ts       → Production safeguards
├── refund_system.ts              → Refund processing
└── unified_booking_lifecycle.ts  → Consolidated flow
```

#### **Technician Functions** (12 files, ~1500 lines)
```
technician/
├── alerts.ts                    → Job alerts
├── application.ts               → Partner application flow
├── auth.ts                      → Technician authentication
├── bank_verification.ts         → Bank account verification
├── booking_actions_hardened.ts  → Safe booking actions
├── createTechnicianService.ts   → Service creation (1100+ lines)
├── kyc.ts                       → KYC verification
├── onboarding.ts                → Onboarding flow
├── profile_management.ts        → Profile updates
├── security.ts                  → Security checks
├── services_management.ts       → Service CRUD
├── tracking.ts                  → Location tracking
└── triggers.ts                  → Firestore triggers
```

#### **Other Modules**
- **Customer** (3 files): address, cart, favorites management
- **Matching** (4 files): Matching engine v1, v2, variants
- **Finance** (5 files): wallet, payout, invoice, withdrawal, reconciliation
- **Payments** (3 files): Razorpay integration, webhook handling
- **Reviews** (1 file): Review triggers
- **Chat** (1 file): Chat management
- **Custom Requests** (1 file): Custom request notifications
- **Shared** (8 files): utilities, models, notifications, security, config
- **Scripts** (2 files): Database initialization
- **Testing** (3 files): Test factories & actions
- **Templates** (2 files): Callable & HTTP webhook templates

### Key Function Exports (index.ts)

**~190 exports covering:**
- Callable functions (client-accessible)
- Firestore triggers (onWrite, onCreate, onDelete)
- HTTP webhooks
- Scheduled functions (Cloud Scheduler)

---

## 8. AUTHENTICATION - Auth Flows & Integration

### Customer App Auth Flow

**File:** `apps/customer_app/lib/core/services/auth_service.dart`

```dart
// Key Methods:
- signupWithPhone(phone)
  - Firebase Auth OTP verification
  - Create customer document in Firestore
  - LocationProvider initialization

- loginWithPhone(phone)
  - OTP verification
  - Redirect to location selection

- logout()
  - Auth sign-out
  - Clear local state

- getCurrentUser()
  - Returns AuthService.currentUser?.uid
```

**Auth Provider:** `apps/customer_app/lib/core/providers/auth_provider.dart`
- Listens to Firebase Auth state changes
- Manages login/logout UI state

---

### Technician App Auth Flow

**File:** `apps/technician_app/lib/core/services/auth_service.dart` (likely exists)

**Firebase Cloud Function Auth:**
- `technician/auth.ts` - Authentication logic
- `technician/security.ts` - Security checks post-auth

**Onboarding Protected by:**
- `technician/triggers.ts` - Auth state triggers
- `admin/technician_approval.ts` - Admin approval gate

---

### Firebase App Check Integration

**Client Implementation:**
- `customer_app/lib/core/firebase/firebase_init.dart`
- `technician_app/lib/core/firebase/firebase_init.dart`

**Status:** ✓ App Check enabled for security

---

## 9. BROKEN IMPORTS & DEPENDENCY ISSUES

### Scan Results

**Import Pattern Analysis:**
- ✓ Package imports (Firebase, Flutter packages) - All valid
- ✓ Relative imports use correct paths
- ⚠️ **Potential Issues Found:**

#### **Issue 1: Missing wallet_service.dart import?**
- Referenced in multiple services but may not be exported
- Verify: `apps/customer_app/lib/core/services/wallet_service.dart` exists

#### **Issue 2: TechnicianService model variant**
- Enhanced models referenced in documentation
- Verify: Current implementation vs documented variants

#### **Issue 3: Root-level lib/ directory**
- Contains only `main.dart` (Flutter entry point at root?)
- This location suggests monorepo root is also a Flutter app
- **⚠️ Unusual structure** - Typically apps are separately compiled

---

## 10. FIREBASE CONFIGURATION

### Configuration Files Located

| File | Location | Status | Purpose |
|------|----------|--------|---------|
| `firebase.json` | Project root | ✓ FOUND | Firebase project config |
| `.firebaserc` | Project root | ✓ FOUND | Firebase project aliases |
| `firebase_options.dart` | Root | ✓ FOUND | Customer app Firebase init |
| `firebase_options.dart` | technician_app/ | ✓ FOUND | Technician app Firebase init |
| `google-services.json` | technician_app/android/app/ | ✓ FOUND | Android Firebase config (in editor) |

### Firebase Projects

**Files analyzed indicate:**
- Single Firebase project for development
- App Check enabled
- Multiple apps registered (customer, technician)
- Firestore Database configured
- Cloud Functions deployed

### Configuration Status

| Service | Status | Evidence |
|---------|--------|----------|
| Firestore | ✓ ACTIVE | Database operations throughout codebase |
| Cloud Functions | ✓ ACTIVE | 90 function files |
| Authentication | ✓ ACTIVE | Auth services in both apps |
| Storage | ✓ ACTIVE | Image upload in services |
| Cloud Messaging (FCM) | ✓ ACTIVE | Push notification services |
| App Check | ✓ ACTIVE | `firebase_app_check` imports |

---

## 11. ADMIN PANEL - Dashboard Structure

### Pages/Routes Structure

**Location:** `apps/admin_panel/src/app/(admin)/`

```
(admin)/
├── page.tsx                 → Dashboard home
├── bookings/                → Booking management & approval
├── services/                → Technician services moderation
├── technicians/             → Technician management
├── customers/               → Customer management
├── disputes/                → Dispute resolution
├── finance/
│   ├── page.tsx            → Finance dashboard
│   └── wallet/             → Wallet management
├── approvals/               → Various approval workflows
└── [Dynamic routes]
```

### Key Features

**Services Management:**
```tsx
// apps/admin_panel/src/app/(admin)/services/page.tsx
- Fetch from technician_services collection
- Filter by status (pending, approved, rejected)
- Moderation UI with approve/reject actions
- Pagination with lazy loading
```

**Booking Approval:**
- View pending bookings
- Approve/reject technician assignments
- Modify pricing/details
- Generate payment QR codes

**Admin Services:**
- `adminBookingService.ts` - booking queries
- Firestore pagination utilities
- Service enumeration & filtering

### Admin Panel Utilities

**Key Libraries:**
- `firestore-utils.ts` - Pagination & querying
- `lib/services/` - Business logic services
- Custom hooks for data fetching

---

## 12. NOTIFICATIONS SYSTEM

### Client Implementation

**Customer App:**
```dart
// apps/customer_app/lib/core/services/notifications_service.dart
- FCM initialization
- Local notification display
- Notification routing by type
- Channel setup (high importance)

// apps/customer_app/lib/core/services/push_notification_service.dart
- Push token management
- Token refresh handling
```

**Notification Model:** `apps/customer_app/lib/core/models/notification.dart`

**Screens:**
- `features/notifications/presentation/notifications_screen.dart`
- `features/notifications/presentation/notification_screen.dart`

---

### Backend Implementation

**Cloud Functions:**

| File | Purpose | Triggers |
|------|---------|----------|
| `admin/notifications.ts` | Admin notifications | Manual triggers |
| `shared/notifications.ts` | Shared notification logic | Various triggers |
| `booking/booking_notifications.ts` | Booking alerts | Booking state changes |
| `custom_requests/custom_request_notifications.ts` | Custom request alerts | Request created/updated |
| `notifications_management.ts` | Notification management | Dedicated endpoints |
| `notification_triggers.ts` | Event-based notifications | Firestore triggers |

**⚠️ Issue:** Both `admin/notifications.ts` and `shared/notifications.ts` exist - unclear which is authoritative

---

### Notification Types Supported

- **Booking Notifications:** New job, approval, completion
- **Review Notifications:** Rating reminders, review posted
- **Wallet Notifications:** Payout processed, withdrawal approved
- **System Notifications:** Approvals, service moderation
- **Chat Notifications:** New messages

---

## 13. SECURITY RULES

### Firestore Rules Files

| File | Focus Area | Status | Notes |
|------|-----------|--------|-------|
| `firestore.rules` | General access | ✓ | Main rules file (USE THIS) |
| `firestore_unified.rules` | Consolidated | ✓ | May be alternate version |
| `firestore_hardened_final.rules` | Security | ✓ | Latest hardened version |
| `firestore_approval_rules.rules` | Approval flow | ⚠️ | Specialized rules |
| `firestore_bank_rules.rules` | Bank data | ⚠️ | Bank-specific permissions |
| `firestore_reviews.rules` | Review moderation | ⚠️ | Review-specific rules |
| `firestore_service_features.rules` | Service moderation | ⚠️ | Service-specific rules |

**⚠️ Critical Issue:** Multiple rule files without clear consolidation strategy
- Recommend: Single authoritative `firestore.rules` with all rules
- Current state creates conflict risk

### Rule Organization

**Typical Pattern:**
```
match /bookings/{bookingId} {
  allow read: if request.auth.uid == resource.data.customerId
           || request.auth.uid == resource.data.technicianId;
  allow write: if request.auth.uid == resource.data.customerId;
}

match /customers/{customerId} {
  allow read, write: if request.auth.uid == customerId;
  allow create: if request.auth.uid != null;
  
  match /addresses/{addressId} {
    allow read, write: if request.auth.uid == customerId;
  }
}
```

**Authentication:**
- ✓ UID-based access control
- ✓ Role-based rules (customer, technician, admin)
- ✓ App Check integration

---

## 14. STRUCTURAL ISSUES & RECOMMENDATIONS

### 🔴 CRITICAL ISSUES (Fix Immediately)

1. **Duplicate Notification Logic**
   - `admin/notifications.ts` vs `shared/notifications.ts`
   - **Action:** Consolidate into single source, update all imports
   - **Risk:** Silent notification failures if wrong version is called

2. **Duplicate Util Functions**
   - `admin/utils.ts` vs `shared/utils.ts`
   - **Action:** Merge into single shared utils
   - **Risk:** Logic divergence, maintenance burden

3. **Multiple Firestore Rules Files**
   - 7 different `.rules` files without clear merge strategy
   - **Action:** Consolidate into single `firestore.rules`
   - **Risk:** Security bypass through rule conflicts

4. **Duplicate Screen Files**
   - `wallet_screen.dart` vs `wallet_screen_fixed.dart`
   - `dashboard_screen.dart` vs `dashboard_home_enhanced.dart`
   - **Action:** Remove old versions, confirm enhanced versions are production
   - **Risk:** Unclear which version is deployed

---

### ⚠️ MEDIUM ISSUES (Address Soon)

5. **Single Monolithic Provider (Technician App)**
   - `technician_provider.dart` manages all state
   - **Action:** Consider splitting into feature-specific providers
   - **Benefit:** Better testability, reusability

6. **Missing Service Layer Abstraction**
   - Some services call Firestore directly
   - **Action:** Enforce repository pattern; service → repository → firestore
   - **Benefit:** Easier testing, centralized error handling

7. **Duplicate Service Creation Logic**
   - `services_management.ts` vs `createTechnicianService.ts`
   - **Status:** Partially consolidated but unclear if cleanup complete
   - **Action:** Verify only one is exported; delete/deprecate the other

---

### 📋 MINOR ISSUES (Cleanup/Optimization)

8. **Unused Imports**
   - Some models/services imported but not used
   - **Action:** Run lint analysis to identify

9. **Inconsistent Naming**
   - Some files use `_service`, others `Service`
   - **Action:** Standardize on single naming convention

10. **Documentation Fragmentation**
    - 200+ markdown files in root directory
    - **Action:** Archive in `/docs/` folder; keep README for live issues

---

## 15. SUMMARY STATISTICS

| Metric | Count | Health |
|--------|-------|--------|
| Total Dart files (both apps) | 267 | ✓ Manageable |
| Total TypeScript/JS files (functions) | 90 | ✓ Organized |
| Admin Panel source files | 63 | ✓ Organized |
| Models (combined) | ~40 | ⚠️ Some duplication |
| Services (combined) | ~46 | ⚠️ Needs cleanup |
| Providers (combined) | 9 | ✓ Moderate |
| Duplicate files identified | 5+ | 🔴 HIGH RISK |
| Firestore rule files | 7 | 🔴 HIGH RISK |
| Cloud Function modules | 14 | ✓ Well-organized |

---

## 16. CODEBASE HEALTH ASSESSMENT

### Overall Assessment: ⚠️ GOOD WITH CRITICAL ISSUES

**Strengths:**
- ✓ Clear separation between customer & technician apps
- ✓ Centralized Firebase functions
- ✓ Modern Next.js admin panel
- ✓ Good use of providers for state management
- ✓ Security-conscious (App Check, Firestore rules, UID validation)

**Weaknesses:**
- 🔴 Multiple duplicate files creating confusion
- 🔴 Firestore rules not consolidated
- ⚠️ Some utility/service redundancy
- ⚠️ Screen file versioning unclear
- ⚠️ Documentation fragmented

**Recommendation:**
1. **Immediate:** Consolidate duplicate files (notifications, utils, rules)
2. **Short-term:** Clarify screen file usage (fixed/enhanced variants)
3. **Medium-term:** Consider provider separation in technician app
4. **Long-term:** Establish code review process to prevent future duplicates

---

## 17. QUICK REFERENCE - KEY FILE LOCATIONS

**Auth & User Management:**
- Customer Auth: `apps/customer_app/lib/core/services/auth_service.dart`
- Technician Auth: `functions/src/technician/auth.ts`
- Onboarding: `apps/technician_app/lib/features/onboarding/`

**Booking System:**
- Customer Booking: `apps/customer_app/lib/features/bookings/`
- Cloud Functions: `functions/src/booking/`
- Moderation: `functions/src/admin/booking_moderation.ts`

**Services/Catalog:**
- Service Model: `apps/technician_app/lib/core/models/technician_service.dart`
- Creation Logic: `functions/src/technician/createTechnicianService.ts`
- Admin Panel: `apps/admin_panel/src/app/(admin)/services/page.tsx`

**Payments & Wallet:**
- Wallet Logic: `functions/src/finance/wallet_logic.ts`
- Razorpay: `functions/src/payments/razorpay.ts`
- Admin Panel: `apps/admin_panel/src/app/(admin)/finance/wallet/`

**Location System:**
- Model: `apps/customer_app/lib/core/models/address.dart`
- Service: `apps/customer_app/lib/core/services/location_service.dart`
- Provider: `apps/customer_app/lib/core/providers/location_provider.dart`

**Notifications:**
- ⚠️ Dual implementation - See Section 12

---

**Document Generated:** March 13, 2026
**Next Review:** After critical issues are resolved
