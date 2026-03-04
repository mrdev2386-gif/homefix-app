# Phase 2 Quick Reference - Backend Security Hardening

## What Changed?

### Frontend (Flutter)
| Component | Before | After |
|-----------|--------|-------|
| Document Creation | Client-side `_initializeMinimalTechnicianDocument()` | Auth trigger (backend) |
| KYC Evaluation | Client-side logic in provider | Cloud Function `evaluateTechnicianKyc()` |
| AuthGate | Direct field read | Waits for document + proper routing |
| Submit Flow | Submit data only | Submit + evaluate KYC + refresh |

### Backend (Cloud Functions)
| Function | Type | Purpose |
|----------|------|---------|
| `onUserCreated` | Auth Trigger | Auto-create minimal technician doc |
| `evaluateTechnicianKyc` | Callable | Evaluate KYC, set `isKycComplete` |
| `checkKycStatus` | Callable | Read KYC status (read-only) |

### Firestore Rules
| Collection | Blocked Fields | Reason |
|-----------|----------------|--------|
| technicians | isKycComplete, role, createdAt, walletBalance + 14 more | Backend-only, admin-only, or immutable |

---

## Key Flow Changes

### Signup Flow
```
User signs up → Firebase Auth → Auth trigger creates doc → AuthGate waits → Routes to onboarding
```

### Onboarding Flow
```
Fill data → Submit → evaluateTechnicianKyc() → isKycComplete set by backend → AuthGate sees updated status → Routes to review/dashboard
```

### AuthGate Logic
```
1. Wait for technician document (retry max 10x with 500ms delay)
2. If no doc: show onboarding
3. If onboarding not done: show onboarding
4. If not KYC complete: show onboarding
5. If not approved: show review
6. If approved: show dashboard
```

---

## Files Changed

### New Files
- `functions/src/technician/auth.ts` - Auth trigger
- `functions/src/technician/kyc.ts` - KYC functions

### Modified Files
- `functions/src/index.ts` - Imports and exports
- `firestore_hardened_final.rules` - Security rules
- `lib/core/providers/technician_provider.dart` - Removed creation, added KYC methods
- `lib/main.dart` - AuthGate document wait logic

---

## Blocked Fields (18 Total)

**KYC & Approval:**
- isKycComplete, onboardingCompleted, isApproved, adminApproved

**Security & System:**
- role, createdAt, updatedAt, status

**Financial:**
- walletBalance, totalEarnings, pendingEarnings

**Metrics:**
- rating, avgRating, totalRatings, jobsDone, jobsCompleted

**Audit:**
- _kycChecklist, _kycEvaluatedAt

---

## New Cloud Function Methods

### Provider Methods

```dart
Future<Map<String, dynamic>?> evaluateTechnicianKyc()
// Returns: { success: bool, isKycComplete: bool, checklist: {...} }
// Used after onboarding submit

Future<bool?> checkKycStatus()
// Returns: isKycComplete boolean
// Used by AuthGate for routing
```

---

## Tested Scenarios

✅ New user signup → document created by trigger
✅ AuthGate waits for document (no infinite loading)
✅ Onboarding submit → KYC evaluation → status updated
✅ Client cannot write to blocked fields
✅ Client cannot manipulate KYC status
✅ Error handling (network failures, timeouts)
✅ Idempotency (creating document twice is safe)

---

## Deployment Commands

```bash
# Deploy Cloud Functions
firebase deploy --only functions

# Deploy Firestore Rules
firebase deploy --only firestore:rules

# View logs
firebase functions:log
```

---

## Rollback Plan

If issue found:
1. Revert individual Cloud Functions (client still works gracefully)
2. Revert Firestore rules to previous version
3. Revert Flutter app to previous version

No data loss - all changes are additive/behavioral.

---

## Monitoring

### Look for in Cloud Function logs:
- `technician_auto_created_on_auth` - Auth trigger firing
- `KYC evaluation completed` - Successful evaluations
- Errors in evaluating KYC

### Firestore collection:
- `audit_logs` - Track all backend actions

### Client logs:
- `[FUNCTIONS]` - Cloud Function calls
- `[FIRESTORE]` - Document operations
- `[AUTH]` - AuthGate routing decisions

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Infinite loading on login | AuthGate waits max 5 sec, then shows onboarding |
| Can't write to field | Check if in blocked list (18 fields can't write) |
| KYC not evaluating | Check if all 10 fields complete in Firestore |
| Document never created | Verify Auth trigger deployed, check Cloud Function logs |

---

## Security Wins

✅ **Auth Trigger:** Client zero control over document creation
✅ **KYC Evaluation:** Server authoritative, cannot be bypassed
✅ **Firestore Rules:** Database-level enforcement, cannot be hacked around
✅ **AuthGate:** No null states, no infinite waits
✅ **Audit Trail:** Every KYC evaluation logged with checklist

---

## One-Minute Summary

**What:** Moved document creation and KYC evaluation from client to backend

**Why:** Prevents manipulation of critical fields like isKycComplete, role, financial data

**How:** 
- Auth trigger auto-creates document
- Cloud Functions evaluate KYC
- Firestore rules block dangerous writes

**Result:** System is secure, predictable, production-safe. AuthGate handles async flows gracefully.

---

*Quick Reference for Phase 2*
*Keep this handy during testing and deployment*
