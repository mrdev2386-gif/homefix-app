# Duplicate & Versioned Functions Audit
**Analysis Date:** March 11, 2026  
**Scope:** functions/src directory

---

## Executive Summary

Found **7 major duplicate/versioned function sets** with **11+ duplicate implementations** across the codebase. Most are evolving versions with the newer version typically marked as V2 or with different names (New, Idempotent, etc.).

---

## 1. Technician Matching Functions

### Duplicate Set: `matchTechnicians` variants

| Version | File | Status | Notes |
|---------|------|--------|-------|
| `matchTechnicians` | [functions/src/matching/technician_matching.ts](functions/src/matching/technician_matching.ts#L93) | **OLD** | Original matching algorithm |
| `matchTechniciansV2` | [functions/src/matching/matchTechniciansV2.ts](functions/src/matching/matchTechniciansV2.ts#L123) | **ACTIVE** | New improved matching algorithm |
| Context: Also imported and used in `/matching/matching_v2.ts` | - | - | - |

**Status:** Both exported from index.ts. V2 should be the primary function.
**Files to clean:**
- Legacy import in [index.ts line 107](functions/src/index.ts#L107) for `matchTechnicians` should be deprecated
- Consider removing `technician_matching.ts` if V2 covers all cases

---

## 2. Razorpay Payment Webhooks

### Duplicate Set: `razorpayWebhook` variants

| Version | File | Status | Notes |
|---------|------|--------|-------|
| `razorpayWebhook` | [functions/src/payments/razorpay.ts](functions/src/payments/razorpay.ts#L388) | **DEPRECATED** | Old webhook handler, marked @deprecated in code |
| `razorpayWebhookV2` | [functions/src/payments/razorpayWebhookV2.ts](functions/src/payments/razorpayWebhookV2.ts#L37) | **ACTIVE** | New webhook with wallet auto-creation and better error handling |

**Status:** Code comments indicate V1 is deprecated. V2 should be used for all new payments.
**Active Usage:** Only `razorpayWebhookV2` is exported in [index.ts line 566](functions/src/index.ts#L566)
**Cleanup Needed:**
- Remove or deprecate `razorpayWebhook` in [razorpay.ts lines 388-640](functions/src/payments/razorpay.ts#L388-L640)
- Related: `handlePaymentCapturedV2` function in `razorpayWebhookV2.ts`

---

## 3. Booking Creation Functions

### Duplicate Set: Multiple `createBooking` variants

| Version | File | Status | Purpose |
|---------|------|--------|---------|
| `createBookingRequest` | [functions/src/booking/new_booking_flow.ts](functions/src/booking/new_booking_flow.ts#L119) | **ACTIVE** | Main booking creation flow (NEW payment system) |
| `createBookingIdempotent` | [functions/src/booking/production_hardening.ts](functions/src/booking/production_hardening.ts#L207) | **ACTIVE** | Idempotent variant with duplicate prevention |
| `createBooking` (template) | [functions/src/v2_templates/callable_template.ts](functions/src/v2_templates/callable_template.ts#L41) | **TEMPLATE** | Example/template only, not actual implementation |

**Status:** Multiple active implementations for different purposes
- `createBookingRequest` → main flow, added to cart
- `createBookingIdempotent` → safety mechanism for production
- Template in v2_templates is example code only

**Analysis:**
- These are evolved versions addressing different concerns (flow vs. idempotency)
- No direct duplication; each serves a purpose
- Consider merging idempotent logic into `createBookingRequest` as an option

---

## 4. Booking Status Update Functions

### Duplicate Set: `updateBookingStatus` variants

| Version | File | Status | Notes |
|---------|------|--------|-------|
| `updateBookingStatusGeneric` | [functions/src/booking/new_booking_flow.ts](functions/src/booking/new_booking_flow.ts#L840) | **ACTIVE** | Generic status update handler |
| `updateBookingStatusNew` (alias) | [functions/src/technician/booking_actions_hardened.ts](functions/src/technician/booking_actions_hardened.ts#L156) | **DUPLICATE** | Same as above, separate implementation |
| **Export aliases in index.ts** [lines 117-118](functions/src/index.ts#L117-L118) | - | - | Both point to `updateBookingStatusGeneric` |

**Status:** 
- `updateBookingStatusGeneric` in `new_booking_flow.ts` is canonical
- `updateBookingStatusNew` in `booking_actions_hardened.ts` is DUPLICATE implementation
- Index exports both as aliases to same underlying function (confusing)

**Critical Issues:**
- Two separate implementations of the same functionality
- One in `new_booking_flow.ts`, one in `booking_actions_hardened.ts`
- Index aliases both to `updateBookingStatusGeneric` from flow, ignoring the hardened version
- **Risk:** If hardened version is different, it's being shadowed

**Cleanup Action:**
- Verify if `booking_actions_hardened.ts` version is different/improved
- If yes, consolidate both versions
- If no, remove the hardened duplicate and keep the flow version
- Simplify the index exports to single canonical function

---

## 5. Technician Services Management (MAJOR DUPLICATION)

### Duplicate Set: Service management functions in TWO files

| Function | File 1 | File 2 | Status |
|----------|--------|--------|--------|
| `addTechnicianService` | [services_management.ts](functions/src/technician/services_management.ts#L98) | [createTechnicianService.ts](functions/src/technician/createTechnicianService.ts#L538) | Both ACTIVE |
| `updateTechnicianService` | [services_management.ts](functions/src/technician/services_management.ts#L260) | [createTechnicianService.ts](functions/src/technician/createTechnicianService.ts#L750) | Both ACTIVE |
| `deleteTechnicianService` | [services_management.ts](functions/src/technician/services_management.ts#L411) | [createTechnicianService.ts](functions/src/technician/createTechnicianService.ts#L910) | Both ACTIVE |
| `toggleTechnicianServiceStatus` | [services_management.ts](functions/src/technician/services_management.ts#L362) | [createTechnicianService.ts](functions/src/technician/createTechnicianService.ts#L1037) | Both ACTIVE |
| `getMyTechnicianServices` | - | [createTechnicianService.ts](functions/src/technician/createTechnicianService.ts#L993) | ACTIVE |

**Export Routing:**
- Index.ts imports from TWO sources:
  - [Line 41](functions/src/index.ts#L41): `import * as techServicesManagement from './technician/services_management'`
  - [Line 41](functions/src/index.ts#L41): `import * as technicianServices from './technician/createTechnicianService'`
- [Export lines 188-193](functions/src/index.ts#L188-L193): Uses `techServicesManagement` for first 4 functions, `technicianServices` for getMyTechnicianServices

**Critical Issue:**
- **DUPLICATE IMPLEMENTATIONS** of same functions in two separate files
- Both files export the same function names
- Index selectively picks from each file, masking the duplication
- **HIGH DUPLICATION RISK** - which version is actually being used?

**Cleanup Action (URGENT):**
1. Compare implementations in both files for differences
2. Consolidate into single file (recommend `services_management.ts`)
3. Delete `createTechnicianService.ts` or repurpose it
4. Update index.ts imports
5. Verify no logic specific to either implementation is lost

---

## 6. Wallet & Payment Processing Functions

### Duplicate Set: Wallet credit/processing variants

| Function | File | Variant | Status |
|----------|------|---------|--------|
| `processTechnicianEarning` | [functions/src/finance/wallet_logic.ts](functions/src/finance/wallet_logic.ts#L59) | Original | **ACTIVE** |
| `creditTechnicianWalletV2` | [functions/src/payments/razorpayWebhookV2.ts](functions/src/payments/razorpayWebhookV2.ts#L579) | V2 variant | **ACTIVE** |
| `updateWalletBalance` | [functions/src/finance/wallet_logic.ts](functions/src/finance/wallet_logic.ts#L13) | Generic helper | **ACTIVE** |
| `processWalletTransaction` (callable) | [functions/src/finance/wallet_logic.ts](functions/src/finance/wallet_logic.ts#L106) | Admin callable | **ACTIVE** |

**Status:** 
- Multiple active implementations for wallet operations
- `processTechnicianEarning` is used in [payment_qr.ts line 115](functions/src/booking/payment_qr.ts#L115) and [new_booking_flow.ts line 783](functions/src/booking/new_booking_flow.ts#L783)
- `creditTechnicianWalletV2` is internal to webhook handler only
- Different functions handle different flows (earnings vs. manual credits)

**Analysis:**
- These are EVOLVED versions, not pure duplicates
- Each has specific purpose and context
- V2 version is webhook-specific, original is general-purpose
- Could benefit from consolidation but not critical duplicates

---

## 7. Razorpay Payment Order Functions

### Duplicate Set: Payment order creation variants

| Function | File | Alias In | Status |
|----------|------|----------|--------|
| `createPaymentOrder` | [functions/src/payments/razorpay.ts](functions/src/payments/razorpay.ts#L220) | - | **ACTIVE** |
| `initiateRazorpayPayment` | [index.ts](functions/src/index.ts#L243) | → `createPaymentOrder` | **ALIAS** |
| `createRazorpayOrder` | [index.ts](functions/src/index.ts#L568) | → `createPaymentOrder` | **ALIAS** |

**Status:** 
- Single implementation with two export aliases
- Confusing naming (what's the difference between `createPaymentOrder`, `createRazorpayOrder`, `initiateRazorpayPayment`?)
- Template also has `initiateRazorpayPayment` [v2_templates/callable_template.ts](functions/src/v2_templates/callable_template.ts#L108)

**Cleanup Action:**
- Choose canonical name and stick with it
- Remove confusing aliases
- Update clients to use single endpoint

---

## Summary Statistics

| Category | Count | Critical |
|----------|-------|----------|
| Total duplicate sets | 7 | - |
| Active implementations | 11+ | - |
| Deprecated/marked old | 2 | ✓ |
| True duplicates (same logic, different files) | 4 | ✓ |
| Evolved versions (V1 → V2) | 1 | ✓ |
| Aliases/naming confusion | 2 | ✓ |
| **Recommend immediate action** | **4 sets** | ✓ |

---

## Recommendations by Priority

### 🔴 CRITICAL (Fix Immediately)

1. **Technician Services Duplication** (#5)
   - Two complete implementations of same functions
   - Consolidate into single source of truth
   - High risk of inconsistency

2. **Booking Status Updates** (#4)
   - Verify if hardened version is different
   - Consolidate if same logic
   - Index misleadingly exports both

3. **Remove razorpayWebhook** (#2)
   - Already marked @deprecated
   - Only V2 is exported; remove V1 completely
   - Reduces webhook complexity

### 🟡 MEDIUM (Address Soon)

4. **Matching Functions** (#1)
   - V2 is active, V1 should be deprecated
   - Add clear deprecation warning to V1
   - Document migration path

5. **Booking Creation** (#3)
   - Three variants with different purposes
   - Consider merging idempotent logic into main flow
   - Document which to use for new code

### 🟢 LOW (Monitor/Refactor)

6. **Wallet/Payment Processing** (#6)
   - Multiple active functions with clear purposes
   - Document usage for each variant
   - Consider consolidating helpers

7. **Razorpay Order Aliases** (#7)
   - Standardize naming conventions
   - Remove confusing aliases
   - Document canonical endpoint name

---

## Files Affected (Summary)

**Most problematic:**
- `functions/src/technician/createTechnicianService.ts` - DUPLICATE OF services_management.ts
- `functions/src/technician/services_management.ts` - Same functions as above
- `functions/src/booking/booking_actions_hardened.ts` - Duplicate updateBookingStatus
- `functions/src/payments/razorpay.ts` - Deprecated webhook still present

**Files with good V2 versions:**
- `functions/src/matching/matchTechniciansV2.ts` ✓
- `functions/src/payments/razorpayWebhookV2.ts` ✓
- `functions/src/booking/new_booking_flow.ts` ✓

---

## Next Steps

1. Generate comparison reports for duplicate files
2. Verify which implementation is actually being called in production
3. Create migration plan for consolidation
4. Update documentation with canonical function names
5. Add deprecation warnings to old versions
6. Schedule cleanup after verifying no breakage
