# Firestore Audit - Quick Reference & File Paths

## Collections Inventory (50+ Collections)

### EXPECTED & VERIFIED ✅
| Collection | Type | Primary Use | Recommendation |
|-----------|------|-------------|-----------------|
| bookings | Core | Booking lifecycle | ✅ KEEP - Well structured |
| technician_services | Core | Service listings | ✅ KEEP - Correct location |
| reviews | Core | Customer reviews | ✅ KEEP - Active |
| notifications | Core | Push notifications | ✅ KEEP - Standard structure |
| customers | Core | Customer profiles | ✅ KEEP - Primary user store |
| technicians | Core | Technician profiles | ✅ KEEP - Standard structure |

### CRITICAL ARCHITECTURAL FLAWS 🔴
| Collection | Issue | Severity | Fix Timeline |
|-----------|-------|----------|--------------|
| wallets / technician_wallets | Duplication across 3 locations | CRITICAL | 2 weeks |
| technician_wallets | Unbounded reconciliation queries | CRITICAL | 1 week |
| notifications | N+1 query pattern | CRITICAL | 1 week |
| reviews | Rating race condition | CRITICAL | 2 weeks |
| payment_logs | No date filtering | MEDIUM | 3 days |

### DEPRECATED & LEGACY 🔴
| Collection | Status | Migration | Archive |
|-----------|--------|-----------|---------|
| technician_categories | Deprecated | → categories | Backup then delete |
| technician_subcategories | Deprecated | → services | Backup then delete |
| users | Partial (uses customers) | Migrate to customers | Review usage |
| subServices | Legacy | → services structure | Check for orphaned docs |
| cleaning_essentials | Marketing only | Archived | Keep for history |

### UTILITY/SYSTEM ✅
| Collection | Purpose | Active | Notes |
|-----------|---------|--------|-------|
| rate_limits | Rate limiting | ✅ | Essential |
| risk_profiles | Fraud detection | ✅ | Active |
| activity_logs | Audit trail | ✅ | Growing |
| admin_logs | Admin actions | ✅ | Backup |
| booking_idempotency | Dedup prevention | ✅ | Critical |
| device_change_requests | Security | ✅ | Active |

---

## Critical Code Locations

### CRITICAL ISSUES - MUST FIX

#### 1. Unbounded Wallet Reconciliation (MOST EXPENSIVE)
**File:** [functions/src/technician/booking_actions_hardened.ts](functions/src/technician/booking_actions_hardened.ts#L313-L323)
**Lines:** 313-323  
**Function:** Wallet reconciliation logic  
**Issue:** `db.collection('technician_wallets').get()` without pagination  
**Cost:** ~$0.60 per execution  
**Fix Time:** 2 hours  

```
CURRENT: for (const wallet of ALL_WALLETS) { ...read transactions... }
SHOULD BE: batch(100 wallets at a time)
```

#### 2. Wallet Balance Duplication (FINANCIAL RISK)
**Files:**
- [apps/customer_app/lib/core/services/wallet_service.dart](apps/customer_app/lib/core/services/wallet_service.dart)
- [apps/customer_app/lib/core/services/firestore_service.dart](apps/customer_app/lib/core/services/firestore_service.dart#L283)
- [functions/src/finance/wallet_logic.ts](functions/src/finance/wallet_logic.ts)

**Locations:**
- `customers/{id}.walletBalance` (array field)
- `wallets/{id}.balance` (legacy collection)
- `technician_wallets/{id}.balance` (separate collection)

**Problem:** 3 sources of truth for same data  
**Fix:** Single atomic writes via transaction  

#### 3. N+1 Notification Query (SCALE ISSUE)
**File:** [functions/src/shared/notification_helper.ts](functions/src/shared/notification_helper.ts#L187-188)  
**Lines:** 187-188  
**Pattern:** For each notification, load FCM tokens (N+1)  
**Cost:** $3 per 10,000 notifications  
**Fix Time:** 3 hours  

#### 4. Rating Update Race Condition
**File:** [functions/src/reviews/review_triggers.ts](functions/src/reviews/review_triggers.ts#L37-68)  
**Lines:** 37-68  
**Issue:** Multiple simultaneous review triggers cause rating miscalculation  
**Fix:** Use Firestore transaction  

#### 5. Missing Date Filtering on Time-Series Queries
**Files:**
- [functions/src/payments/razorpay.ts](functions/src/payments/razorpay.ts#L471)
- [functions/src/technician/booking_actions_hardened.ts](functions/src/technician/booking_actions_hardened.ts#L565)

**Issues:** Scans entire collections without time range  
**Fix:** Add `createdAt >= thirtyDaysAgo` filters  

---

## Query Pattern Reference

### ✅ EFFICIENT Patterns (Use These)
```typescript
// Pattern 1: User's bookings with pagination
db.collection('bookings')
  .where('customerId', '==', userId)
  .orderBy('createdAt', 'desc')
  .limit(20)
  .startAfter(lastDoc)  // Cursor pagination

// Pattern 2: Services by category
db.collection('technician_services')
  .where('categoryId', '==', categoryId)
  .where('isActive', '==', true)
  .orderBy('createdAt', 'desc')
  .limit(20)

// Pattern 3: Technician's services
db.collection('technician_services')
  .where('technicianId', '==', techId)
  .snapshots()
```

### ❌ INEFFICIENT Patterns (Avoid These)
```typescript
// ❌ UNBOUNDED - Loads everything
db.collection('technician_wallets').get()

// ❌ N+1 - Load each notification's tokens separately
for (const notif of notifications) {
  await loadTokens(notif.userId);  // N queries!
}

// ❌ NO TIME FILTER - Scans entire collection
db.collection('payment_logs')
  .where('razorpayOrderId', '==', id)
  .get()

// ❌ RACE CONDITION - No transaction
const reviews = await db.collection('reviews').get();
const avg = calcAverage(reviews);
await db.collection('technicians').update({ ratingAvg: avg });
```

---

## Missing Firestore Indexes

### REQUIRED INDEXES (Create in Firebase Console)

```
Collection: bookings
- Composite: (customerId, createdAt DESC)
- Composite: (technicianId, status, createdAt DESC)
- Composite: (status, createdAt DESC)
- Composite: (paymentStatus, createdAt DESC)

Collection: payment_logs
- Composite: (customerId, createdAt DESC)
- Composite: (status, createdAt DESC)

Collection: technician_services
- Composite: (technicianId, rating DESC)
- Composite: (categoryId, rating DESC)

Collection: notifications
- Composite: (userId, isRead, createdAt DESC)
```

---

## Data Consistency Checks

### Run This Query to Find Issues

```javascript
// Check wallet balance consistency
const users = await db.collection('customers').get();
for (const doc of users.docs) {
  const customersBalance = doc.data().walletBalance;
  const walletsDoc = await db.collection('wallets').doc(doc.id).get();
  const walletsBalance = walletsDoc.data()?.balance;
  
  if (customersBalance !== walletsBalance) {
    console.error(`MISMATCH: ${doc.id}`, {
      customers: customersBalance,
      wallets: walletsBalance
    });
  }
}
```

---

## Functions Summary

### By Collection (Write Access)

```
bookings     ← 20+ functions
technicians  ← 25+ functions  
customers    ← 20+ functions
notifications ← 10+ functions
reviews      ← 8 functions
payment_*    ← 15+ functions
```

### By Type (High Priority)

**Booking Lifecycle Functions** (7)
- [functions/src/technician/booking_actions_hardened.ts](functions/src/technician/booking_actions_hardened.ts) - Line 1-600
- All booking status transitions
- Payment verification

**Payment Functions** (8)
- [functions/src/payments/razorpay.ts](functions/src/payments/razorpay.ts)
- [functions/src/payments/razorpayWebhookV2.ts](functions/src/payments/razorpayWebhookV2.ts)
- Webhooks + order creation

**Technician Onboarding** (12)
- [functions/src/technician/onboarding.ts](functions/src/technician/onboarding.ts)
- [functions/src/technician/application.ts](functions/src/technician/application.ts)
- All 6 steps

**Service Management** (8)
- [functions/src/technician/services_management.ts](functions/src/technician/services_management.ts)
- [functions/src/admin/services.ts](functions/src/admin/services.ts)
- Add/update/moderate services

---

## Client App Collection Usage

### Customer App [apps/customer_app/lib/]
**Collections Read:**
- bookings → [booking_service.dart](apps/customer_app/lib/core/services/booking_service.dart#L93)
- categories → [category_service.dart](apps/customer_app/lib/core/services/category_service.dart#L108)
- technician_services → [category_service.dart](apps/customer_app/lib/core/services/category_service.dart#L161)
- reviews → [review_service.dart](apps/customer_app/lib/core/services/review_service.dart#L11)
- customers/{id}/addresses → [firestore_service.dart](apps/customer_app/lib/core/services/firestore_service.dart#L131)
- notifications → [notifications_service.dart](apps/customer_app/lib/core/services/notifications_service.dart#L271)

**Collections Written To (VIA CLOUD FUNCTIONS ONLY):**
- ❌ NO DIRECT WRITES - All via Cloud Functions

### Technician App [apps/technician_app/lib/]
**Collections Read:**
- technicians → [technician_profile_screen.dart](apps/technician_app/lib/features/profile/presentation/profile_screen.dart)
- bookings → [technician_job_screen.dart](apps/technician_app/lib/features/job_requests/technician_job_screen.dart)
- technician_services → [services_screen.dart](apps/technician_app/lib/features/technician/services/services_screen.dart)
- categories → [add_service_screen.dart](apps/technician_app/lib/features/technician/services/add_service_screen.dart)

### Admin Panel [apps/admin_panel/src/]
**Collections Read/Written:**
- technician_services → [admin/services/page.tsx](apps/admin_panel/src/app/%28admin%29/services/page.tsx#L106)
  - Query: `WHERE status == 'pending_review'` ← PAGINATED ✓
- bookings → Admin dashboard
- All user management collections

---

## Schema Documentation

### customers Document
```json
{
  "uid": "auth_id",
  "email": "user@example.com",
  "phone": "9876543210",
  "displayName": "John Doe",
  "photoUrl": "https://...",
  "primaryAddress": {
    "id": "addr_1",
    "coordinates": {"latitude": 12.9, "longitude": 77.5},
    "address": "123 Main St",
    "city": "Bangalore",
    "state": "Karnataka"
  },
  "walletBalance": 500,           // ⚠️ DUPLICATION
  "totalSpent": 5000,
  "totalBookings": 12,
  "preferredLanguage": "en",
  "blockedTechnicians": [],
  "isVerified": true,
  "isBlocked": false,
  "createdAt": "2026-01-15T10:30:00Z",
  "updatedAt": "2026-03-13T15:45:00Z"
}
```

### bookings Document
```json
{
  "id": "booking_abc123",
  "customerId": "cust_123",
  "technicianId": "tech_456",
  "serviceId": "svc_789",
  "status": "technician_accepted",
  "scheduledAt": "2026-03-15T14:00:00Z",
  "startedAt": null,
  "completedAt": null,
  "customerAddress": {...},
  "price": 500,
  "paymentStatus": "completed",
  "paymentId": "pay_123",
  "razorpayOrderId": "order_456",
  "createdAt": "2026-03-13T10:00:00Z",
  "updatedAt": "2026-03-13T15:30:00Z"
}
```

### technician_services Document
```json
{
  "id": "svc_abc123",
  "technicianId": "tech_456",
  "categoryId": "cat_789",
  "name": "Plumbing repair",
  "description": "Full plumbing services",
  "basePrice": 500,
  "estimatedDuration": 120,
  "images": ["https://..."],
  "isActive": true,
  "visibility": "public",
  "rating": 4.5,              // ⚠️ DUPLICATION RISK
  "totalRatings": 24,
  "completedBookings": 25,
  "status": "approved",
  "createdAt": "2026-02-01T10:00:00Z",
  "updatedAt": "2026-03-13T15:00:00Z"
}
```

---

## Deployment Verification Checklist

- [ ] wallet reconciliation paginated (Issue #1)
- [ ] wallet balance single source of truth (Issue #2)
- [ ] notification query batch fetches tokens (Issue #3)
- [ ] rating updates use transaction (Issue #5)
- [ ] date filters added to time-series queries (Issue #6)
- [ ] all 8 missing indexes created
- [ ] test data cleanup implemented (Issue #11)
- [ ] address collection references consolidated (Issue #10)
- [ ] Razorpay response truncation implemented (Issue #8)
- [ ] admin pagination tested end-to-end

---

## Contact & References

**Audit Completed:** March 13, 2026  
**Total Issues:** 13 critical/medium  
**Estimated Fix Effort:** 40-60 hours  
**Estimated Monthly Savings:** $500+  
**Document:** [FIRESTORE_ARCHITECTURE_AUDIT_COMPLETE.md](FIRESTORE_ARCHITECTURE_AUDIT_COMPLETE.md)
