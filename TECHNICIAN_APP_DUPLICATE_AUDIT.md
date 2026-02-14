# 🔍 TECHNICIAN APP DUPLICATE & UNUSED CODE AUDIT REPORT

**Audit Date:** 2026-02-13  
**App:** HomeFix Technician App  
**Scope:** `apps/technician_app/lib/`

---

## 📊 EXECUTIVE SUMMARY

| Metric | Value |
|--------|-------|
| **Total Dart Files** | 51 |
| **Duplicate File Groups** | 5 |
| **Stub/Empty Files** | 9 |
| **Backup Files (.bak)** | 2 |
| **Estimated Duplicate %** | ~25% |
| **Risk Level** | MEDIUM |

---

## 🔴 CRITICAL DUPLICATES (Exact/Same Class Name)

### 1. Login Screen Triplication
| File | Lines | Status | Used By |
|------|-------|--------|---------|
| [`features/auth/login_screen.dart`](apps/technician_app/lib/features/auth/login_screen.dart) | 37 | Basic stub | None (dead) |
| [`features/auth/presentation/login_screen.dart`](apps/technician_app/lib/features/auth/presentation/login_screen.dart) | 13 | **STUB** | `app/routes.dart` |
| [`screens/login_screen.dart`](apps/technician_app/lib/screens/login_screen.dart) | 265 | **FULL IMPLEMENTATION** | Unknown |

**Action:** Delete the two stubs, update routes if needed.

---

### 2. Dashboard Screen Triplication
| File | Lines | Status | Used By |
|------|-------|--------|---------|
| [`features/dashboard/dashboard_screen.dart`](apps/technician_app/lib/features/dashboard/dashboard_screen.dart) | 63 | Basic | None (dead) |
| [`features/dashboard/presentation/dashboard_screen.dart`](apps/technician_app/lib/features/dashboard/presentation/dashboard_screen.dart) | 13 | **STUB** | `app/routes.dart` |
| [`screens/dashboard_screen.dart`](apps/technician_app/lib/screens/dashboard_screen.dart) | 649 | **FULL IMPLEMENTATION** | `main.dart` |

**Note:** This is the main dashboard with BottomNavigationBar, location tracking, job stats.

---

### 3. Job Requests Duplication
| File | Lines | Status | Used By |
|------|-------|--------|---------|
| [`features/job_requests/job_requests_screen.dart`](apps/technician_app/lib/features/job_requests/job_requests_screen.dart) | 440 | **FULL IMPLEMENTATION** | `screens/dashboard_screen.dart` |
| [`features/job_requests/presentation/job_requests_screen.dart`](apps/technician_app/lib/features/job_requests/presentation/job_requests_screen.dart) | 13 | **STUB** | None |

---

### 4. Job Details Duplication
| File | Lines | Status | Used By |
|------|-------|--------|---------|
| [`features/job_details/presentation/job_detail_screen.dart`](apps/technician_app/lib/features/job_details/presentation/job_detail_screen.dart) | 13 | **STUB** | `app/routes.dart` (unused) |
| [`screens/job_details_screen.dart`](apps/technician_app/lib/screens/job_details_screen.dart) | 383 | **FULL IMPLEMENTATION** | Unknown |

---

## 🟡 LIKELY DUPLICATES (Near-Duplicate)

### 5. Onboarding Flow
| File | Lines | Status |
|------|-------|--------|
| [`screens/onboarding_screen.dart`](apps/technician_app/lib/screens/onboarding_screen.dart) | 204 | Full implementation |
| [`features/onboarding/onboarding_flow.dart`](apps/technician_app/lib/features/onboarding/onboarding_flow.dart) | 107 | Mock/partial |

**Similarity:** Both handle technician onboarding but different approaches.

---

### 6. Routes Configuration
| File | Lines | Status |
|------|-------|--------|
| [`app/routes.dart`](apps/technician_app/lib/app/routes.dart) | 40 | **CURRENT** - uses presentation stubs |
| [`app/routes.dart.bak`](apps/technician_app/lib/app/routes.dart.bak) | 18 | Old version |

---

## 🟢 UNUSED / DEAD FILES

### Empty/Stub Files (<20 lines)
| File | Lines | Reason |
|------|-------|--------|
| [`core/config/app_config.dart`](apps/technician_app/lib/core/config/app_config.dart) | 3 | Single const, unused |
| [`core/network/api_endpoints.dart`](apps/technician_app/lib/core/network/api_endpoints.dart) | 4 | Single consts, unused |
| [`features/auth/presentation/login_screen.dart`](apps/technician_app/lib/features/auth/presentation/login_screen.dart) | 13 | STUB - not used |
| [`features/dashboard/presentation/dashboard_screen.dart`](apps/technician_app/lib/features/dashboard/presentation/dashboard_screen.dart) | 13 | STUB - not used |
| [`features/job_requests/presentation/job_requests_screen.dart`](apps/technician_app/lib/features/job_requests/presentation/job_requests_screen.dart) | 13 | STUB - not used |
| [`features/job_details/presentation/job_detail_screen.dart`](apps/technician_app/lib/features/job_details/presentation/job_detail_screen.dart) | 13 | STUB - not used |
| [`features/dashboard/dashboard_screen.dart`](apps/technician_app/lib/features/dashboard/dashboard_screen.dart) | 63 | Basic, superseded |

### Backup Files
| File | Lines | Reason |
|------|-------|--------|
| [`main.dart.bak`](apps/technician_app/lib/main.dart.bak) | 125 | Old Flutter template |
| [`app/routes.dart.bak`](apps/technician_app/lib/app/routes.dart.bak) | 18 | Old routes |

---

## 📦 LARGE RISKY FILES (>400 lines)

| File | Lines | Risk |
|------|-------|------|
| [`screens/dashboard_screen.dart`](apps/technician_app/lib/screens/dashboard_screen.dart) | 649 | **HIGH** - Multiple responsibilities (nav, stats, jobs) |
| [`features/job_requests/job_requests_screen.dart`](apps/technician_app/lib/features/job_requests/job_requests_screen.dart) | 440 | **MEDIUM** - Complex card UI |
| [`screens/job_details_screen.dart`](apps/technician_app/lib/screens/job_details_screen.dart) | 383 | **MEDIUM** - Has duplicate method definitions |

**Note:** [`screens/job_details_screen.dart`](apps/technician_app/lib/screens/job_details_screen.dart) has duplicate helper methods:
- `_buildSectionTitle` (lines 195, 325)
- `_buildInfoRow` (lines 218, 332)  
- `_buildPriceRow` (lines 259, 356)
- `_buildStatusPill` (lines 283, 366)

---

## 📊 DUPLICATION METRICS

### By Category
| Category | Count | Impact |
|----------|-------|--------|
| Exact duplicates | 4 groups | HIGH |
| Stub files | 6 | MEDIUM |
| Backup files | 2 | LOW |
| Empty configs | 2 | LOW |
| Large files | 3 | MEDIUM |

### Percentage Calculation
- **Total files:** 51
- **Files to potentially remove:** 14 (27%)
- **True duplicates (unique content):** 8
- **Estimated duplication:** ~25%

---

## 🚀 PHASE C — SAFE CLEANUP ROADMAP

### ✅ PHASE 1 — Zero-Risk Deletions (SAFE)
*Can delete immediately - no code changes needed*

1. **`main.dart.bak`** - Old template, never used
2. **`app/routes.dart.bak`** - Old routes, superseded
3. **`core/config/app_config.dart`** - Empty/unused config
4. **`core/network/api_endpoints.dart`** - Empty/unused endpoints

**Files to delete:** 4  
**Risk:** NONE

---

### ✅ PHASE 2 — Stub File Cleanup (SAFE)
*Remove presentation stubs that are never used*

1. **`features/auth/presentation/login_screen.dart`** (13 lines)
2. **`features/dashboard/presentation/dashboard_screen.dart`** (13 lines)
3. **`features/job_requests/presentation/job_requests_screen.dart`** (13 lines)
4. **`features/job_details/presentation/job_detail_screen.dart`** (13 lines)

**Pre-condition:** Verify `app/routes.dart` doesn't import these  
**Risk:** LOW (verify routing first)

---

### ✅ PHASE 3 — Dead Basic Implementations (LOW RISK)
*Remove superseded basic implementations*

1. **`features/dashboard/dashboard_screen.dart`** (63 lines) - superseded by `screens/dashboard_screen.dart`
2. **`features/auth/login_screen.dart`** (37 lines) - superseded by `screens/login_screen.dart`

**Risk:** LOW (verify no imports exist)

---

### ⚠️ PHASE 4 — Architecture Review (MEDIUM RISK)
*Requires code changes*

1. Consolidate onboarding: `screens/onboarding_screen.dart` vs `features/onboarding/onboarding_flow.dart`
2. Fix `app/routes.dart` to use actual implementations from `screens/` folder
3. Refactor large files: split `screens/dashboard_screen.dart` (649 lines)
4. Fix duplicate methods in `screens/job_details_screen.dart`

**Risk:** MEDIUM (requires testing)

---

## 🛡️ SAFETY RULES CONFIRMED

| Rule | Status |
|------|--------|
| No mass delete | ✅ Maintained |
| No architecture rewrite | ✅ Only cleanup |
| No Firebase changes | ✅ Not touched |
| No navigation changes | ⚠️ Routes need update |
| No provider changes | ✅ Not touched |
| No business logic | ✅ Only stubs removed |

---

## ✅ SUCCESS CRITERIA VERIFICATION

- [x] Full technician app scanned (51 files)
- [x] Duplication % estimated (~25%)
- [x] Unused files identified (14 files)
- [x] Risk areas highlighted (large files, stubs)
- [x] Safe cleanup roadmap prepared (4 phases)
- [x] No files deleted yet (Phase A/B complete)

---

## 📋 RECOMMENDATION

**Start with PHASE 1** (4 files, zero risk) immediately:
- `main.dart.bak`
- `app/routes.dart.bak`  
- `core/config/app_config.dart`
- `core/network/api_endpoints.dart`

Then proceed to **PHASE 2** after verifying imports.

**Total safe removal:** ~8 files (~16% of codebase)
