# Quick Reference: Duplicate Functions Action Plan

## 🔴 CRITICAL - Fix Immediately

### 1. Technician Services (HIGH DUPLICATION)
**Problem:** Two complete implementations of service management functions

| Function | File 1 | File 2 | Action |
|----------|--------|--------|--------|
| `addTechnicianService` | services_management.ts:98 | createTechnicianService.ts:538 | **CONSOLIDATE** |
| `updateTechnicianService` | services_management.ts:260 | createTechnicianService.ts:750 | **CONSOLIDATE** |
| `deleteTechnicianService` | services_management.ts:411 | createTechnicianService.ts:910 | **CONSOLIDATE** |
| `toggleTechnicianServiceStatus` | services_management.ts:362 | createTechnicianService.ts:1037 | **CONSOLIDATE** |
| `getMyTechnicianServices` | - | createTechnicianService.ts:993 | **MOVE** |

**Steps:**
1. [ ] Compare implementations side-by-side (createTechnicianService.ts is likely more complete)
2. [ ] Copy superior version to services_management.ts
3. [ ] Delete createTechnicianService.ts OR repurpose it
4. [ ] Update index.ts imports
5. [ ] Test all service CRUD operations
6. [ ] Verify no logic specific to deleted version was lost

**Timeline:** Critical - can cause unexpected behavior if wrong version is called

---

### 2. Booking Status Updates (HARDENED VERSION SHADOWED)
**Problem:** Hardened version with wallet transaction safety is not being used

**Files:**
- Canonical: `booking/new_booking_flow.ts:840` → `updateBookingStatusGeneric`
- Hardened: `technician/booking_actions_hardened.ts:156` → `updateBookingStatusNew` (UNUSED)
- Export: `index.ts:117-118` → Both aliased to flow version

**Steps:**
1. [ ] Compare implementations - check if hardened has different wallet logic
2. [ ] If hardened version has FIX needed: migrate fixes to flow version
3. [ ] If duplicate: keep flow version, remove hardened version
4. [ ] Simplify index exports to single canonical function
5. [ ] Test booking status changes with wallet transactions

**Red Flag:** Comment mentions "FIX 2: ATOMIC WALLET TRANSACTION" - verify if this is critical

**Timeline:** Critical - could be losing transaction safety

---

### 3. Remove Deprecated Razorpay Webhook (V1)
**Problem:** Old webhook still exists and marked @deprecated, but never removed

**Files:**
- Old (Deprecated): `payments/razorpay.ts:388` → `razorpayWebhook` (marked @deprecated)
- New (Active): `payments/razorpayWebhookV2.ts:37` → `razorpayWebhookV2`
- Status: Only V2 is exported in index.ts (line 566)

**Steps:**
1. [ ] Verify Razorpay dashboard webhook URL points to razorpayWebhookV2
2. [ ] Check logs - is razorpayWebhook getting any calls?
3. [ ] Remove `razorpayWebhook` function from razorpay.ts (lines 388-640)
4. [ ] Verify `createPaymentOrder` and `createRazorpayOrder` stay (not webhook)
5. [ ] Test payment flow end-to-end
6. [ ] Deploy with caution - this is payment-critical path

**Timeline:** Critical - reduce webhook complexity, ensure single source of truth

---

## 🟡 MEDIUM - Address Soon

### 4. Deprecate Matching V1
**Problem:** Old matching algorithm exists alongside V2

**Files:**
- V1 (Old): `matching/technician_matching.ts:93` → `matchTechnicians` (KEEP BUT DEPRECATE)
- V2 (New): `matching/matchTechniciansV2.ts:123` → `matchTechniciansV2` (ACTIVE)
- Used in: `index.ts:107-108`

**Steps:**
1. [ ] Add `@deprecated` JSDoc to matchTechnicians function
2. [ ] Add deprecation warning message when called
3. [ ] Log warning: "Use matchTechniciansV2 instead"
4. [ ] Update documentation to recommend V2
5. [ ] Monitor logs for V1 usage
6. [ ] Remove V1 in next major version (set timeline)

**Timeline:** Medium - architectural cleanliness, not urgent

---

### 5. Booking Creation Deduplication
**Problem:** Three "createBooking" functions with different names/purposes

**Files:**
- Main flow: `booking/new_booking_flow.ts:119` → `createBookingRequest` (includes idempotency)
- Explicit idempotency: `booking/production_hardening.ts:207` → `createBookingIdempotent` (separate layer)
- Template: `v2_templates/callable_template.ts:41` → `createBooking` (example only)

**Assessment:** NOT pure duplicates - each has purpose, but explicit idempotency may be redundant

**Steps:**
1. [ ] Verify `createBookingRequest` has sufficient idempotency handling
2. [ ] Check if `createBookingIdempotent` adds value beyond main flow
3. [ ] If redundant: remove and update docs
4. [ ] If needed: merge logic into main flow
5. [ ] Keep template as educational material
6. [ ] Document which should be used for new code

**Timeline:** Medium - code organization

---

## 🟢 LOW - Monitor & Plan

### 6. Razorpay Naming Cleanup
**Problem:** Confusing multiple names for payment order creation

**Files:**
- Function 1: `payments/razorpay.ts:115` → `createRazorpayOrder`
- Function 2: `payments/razorpay.ts:220` → `createPaymentOrder`
- Export 1: `index.ts:243` → `initiateRazorpayPayment` (alias to createPaymentOrder)
- Export 2: `index.ts:568` → `createRazorpayOrder` (re-export)

**Steps:**
1. [ ] Decide canonical name: `createPaymentOrder`, `createRazorpayOrder`, or new name?
2. [ ] Consolidate into single function with clear name
3. [ ] Remove confusing aliases
4. [ ] Update all call sites
5. [ ] Document: "Use X to create payment orders"

**Timeline:** Low - polish, schedule for next refactor

---

### 7. Wallet Functions (Evolved Versions)
**Problem:** Multiple wallet processing functions with different purposes

**Files:**
- Low-level: `finance/wallet_logic.ts:13` → `updateWalletBalance` (atomic operation)
- Business rule: `finance/wallet_logic.ts:59` → `processTechnicianEarning` (with commission)
- Webhook variant: `payments/razorpayWebhookV2.ts:579` → `creditTechnicianWalletV2`
- Admin interface: `finance/wallet_logic.ts:106` → `processWalletTransaction` (callable)

**Assessment:** NOT duplicates - clear separation of concerns

**Verdict:** ✓ NO ACTION NEEDED - Leave as is, but document each purpose

---

## Reference: What's Active vs Deprecated

| Component | Old Version | New Version | Status | Export | Action |
|-----------|------------|------------|--------|---------|--------|
| Webhook | razorpayWebhook | razorpayWebhookV2 | V2 only exported | ✓ razorpayWebhookV2 | REMOVE V1 |
| Matching | matchTechnicians | matchTechniciansV2 | Both exported | ✓✓ both | Deprecate V1 |
| Status Update | (flow version) | (hardened) | Both exported | Both | Consolidate, keep best |
| Services | services_management | createTechnicianService | Both exported | ✓ from mgmt | Consolidate |
| Booking Create | createBookingRequest | N/A | Single + idempotent layer | ✓ request | Optional cleanup |

---

## File Delete Checklist

Files safe to delete/consolidate:
- [ ] `technician/createTechnicianService.ts` (after merging to services_management.ts)
- [ ] `payments/razorpay.ts` → Remove just `razorpayWebhook` function (keep order functions)

Files to deprecate (but keep):
- [ ] `matching/technician_matching.ts` (keep but mark @deprecated)

Files to review/possibly consolidate:
- [ ] `technician/booking_actions_hardened.ts` (if hardened updates aren't needed)
- [ ] `booking/production_hardening.ts` (check if explicit idempotency needed)

---

## Testing Checklist After Cleanup

### Critical Flows to Test:
- [ ] **Services:** Add/update/delete technician service → No breakage
- [ ] **Booking:** Create booking → Status updates → Payment → Completion
- [ ] **Wallet:** Technician earnings credited correctly → Commission calculated
- [ ] **Webhooks:** Razorpay payment confirmation → Wallet updated
- [ ] **Matching:** New booking → Technician matched correctly
- [ ] **Idempotency:** Duplicate requests return existing booking, not new one

### Regression Testing:
- [ ] Technician app services management
- [ ] Customer booking creation flow  
- [ ] Admin booking approval workflow
- [ ] Payment processing and webhooks
- [ ] Technician wallet balance updates
- [ ] Notification triggers on status changes

---

## Estimated Effort

| Task | Effort | Risk | Timeline |
|------|--------|------|----------|
| Consolidate services | 4 hours | High | This sprint |
| Consolidate booking status | 3 hours | High | This sprint |
| Remove webhook V1 | 2 hours | Medium | This sprint |
| Deprecate matching V1 | 1 hour | Low | Next sprint |
| Booking create cleanup | 2 hours | Medium | Next sprint |
| Razorpay naming | 2 hours | Low | Next quarter |
| **Total** | **14 hours** | - | **2 sprints** |

---

## Related Documentation

See also:
- [DUPLICATE_FUNCTIONS_AUDIT.md](DUPLICATE_FUNCTIONS_AUDIT.md) - Full audit details
- [DUPLICATE_FUNCTIONS_DETAILED_ANALYSIS.md](DUPLICATE_FUNCTIONS_DETAILED_ANALYSIS.md) - Technical comparison
- Various `.md` files in repo documenting specific features

---

## Questions to Answer During Cleanup

1. **Services:** Which createTechnicianService.ts has the "correct" implementation?
2. **Booking Status:** Does booking_actions_hardened.ts version have wallet safety that's missing from flow version?
3. **Webhooks:** Could both V1 and V2 be running if Razorpay URL not updated?
4. **Matching:** What's the actual improvement in V2 algorithm?
5. **Idempotency:** Is explicit createBookingIdempotent layer needed beyond what createBookingRequest already does?

