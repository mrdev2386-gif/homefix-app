# PRE-MIGRATION GLOBAL REFERENCE SAFETY CHECK
## HOMEFIX CATEGORY SYSTEM MIGRATION

**Date:** 2024
**Scope:** Entire HomeFix Project (Frontend + Backend + Rules)
**Search Terms:** `technician_categories`, `technician_subcategories`, `service_categories`, `subServices`, `cleaning_essentials`

---

## 🔍 STEP 1: GLOBAL SEARCH RESULTS

### 1️⃣ `technician_categories` REFERENCES

#### **Backend (Cloud Functions)**

| File | Line | Context | Operation | Status |
|------|------|---------|-----------|--------|
| `admin/dynamic_content.ts` | 134, 223, 381, 409, 421, 430, 439 | Admin CRUD operations | READ/WRITE | ⚠️ ADMIN ONLY |
| `admin/system_initialization.ts` | 15, 90, 93, 94 | System initialization seed data | READ/WRITE | ⚠️ ADMIN ONLY |
| `technician/onboarding.ts` | 359 | Category validation during onboarding | READ | ⚠️ PRODUCTION |

**Total References:** 13 occurrences across 3 files

#### **Frontend (Customer App)**

| File | Line | Context | Operation | Status |
|------|------|---------|-----------|--------|
| `lib/core/services/firestore_service.dart` | 548, 581 | Stream/fetch technician categories | READ | ⚠️ PRODUCTION |

**Total References:** 2 occurrences in 1 file

#### **Frontend (Technician App)**

**Total References:** 0 occurrences ✅

---

### 2️⃣ `technician_subcategories` REFERENCES

#### **Backend (Cloud Functions)**

| File | Line | Context | Operation | Status |
|------|------|---------|-----------|--------|
| `admin/dynamic_content.ts` | 224, 392, 456, 468, 477, 486 | Admin CRUD operations | READ/WRITE | ⚠️ ADMIN ONLY |
| `admin/system_initialization.ts` | 106 | System initialization seed data | WRITE | ⚠️ ADMIN ONLY |

**Total References:** 7 occurrences across 2 files

#### **Frontend (Customer App)**

| File | Line | Context | Operation | Status |
|------|------|---------|-----------|--------|
| `lib/core/services/firestore_service.dart` | 562, 593 | Stream/fetch technician subcategories | READ | ⚠️ PRODUCTION |

**Total References:** 2 occurrences in 1 file

#### **Frontend (Technician App)**

| File | Line | Context | Operation | Status |
|------|------|---------|-----------|--------|
| `lib/core/services/category_data_service.dart` | 151, 156, 159 | Fetch subcategories (with debug comments) | READ | ⚠️ PRODUCTION |

**Total References:** 3 occurrences in 1 file

---

### 3️⃣ `service_categories` REFERENCES

**Total References:** 0 occurrences ✅ (Collection does not exist in code)

---

### 4️⃣ `subServices` REFERENCES

#### **Backend (Cloud Functions)**

**CRITICAL FINDING:** `subServices` is a DIFFERENT system (nested subcollection under services)

| File | Context | Status |
|------|---------|--------|
| `admin/catalog_audit.ts` | Audit tool for service structure | 🟡 ADMIN TOOL |
| `admin/dynamic_content.ts` | CRUD for subServices subcollection | 🟡 ADMIN ONLY |
| `admin/services.ts` | Service management with subServices | 🟡 ADMIN ONLY |
| `matching/engine.ts` | Matching logic uses subServiceId | 🔴 PRODUCTION CRITICAL |
| `matching/matchTechniciansV2.ts` | Matching with subServices array | 🔴 PRODUCTION CRITICAL |
| `matching/technician_matching.ts` | Strict subService validation | 🔴 PRODUCTION CRITICAL |
| `scripts/initialize-services.js` | Service initialization script | 🟡 SETUP SCRIPT |

**Total References:** 100+ occurrences across 7+ files

**⚠️ WARNING:** `subServices` is NOT the same as `technician_subcategories`
- `subServices` = Nested subcollection under `categories/{id}/services/{id}/subServices`
- `technician_subcategories` = Root-level collection (LEGACY)

---

### 5️⃣ `cleaning_essentials` REFERENCES

#### **Backend (Cloud Functions)**

| File | Line | Context | Operation | Status |
|------|------|---------|-----------|--------|
| `admin/dynamic_content.ts` | 65, 77, 86, 96, 219, 295 | Admin CRUD operations | READ/WRITE | ⚠️ ADMIN ONLY |
| `admin/system_initialization.ts` | 53, 120, 123, 124 | System initialization seed data | READ/WRITE | ⚠️ ADMIN ONLY |

**Total References:** 10 occurrences across 2 files

#### **Frontend (Customer App)**

| File | Context | Status |
|------|---------|--------|
| `lib/core/services/firestore_service.dart` | Stream cleaning essentials for dashboard | 🟡 MARKETING ONLY |

**Total References:** 1 method in 1 file

---

## 🎯 STEP 2: USAGE CLASSIFICATION

### `technician_categories`

| Reference | Classification | Critical? |
|-----------|----------------|-----------|
| `admin/dynamic_content.ts` | ADMIN ONLY | ❌ No |
| `admin/system_initialization.ts` | ADMIN ONLY | ❌ No |
| `technician/onboarding.ts:359` | **PRODUCTION CRITICAL** | ✅ **YES** |
| `customer_app/firestore_service.dart` | **PRODUCTION CRITICAL** | ✅ **YES** |

**VERDICT:** 🔴 **BLOCKED** - 2 production-critical references found

---

### `technician_subcategories`

| Reference | Classification | Critical? |
|-----------|----------------|-----------|
| `admin/dynamic_content.ts` | ADMIN ONLY | ❌ No |
| `admin/system_initialization.ts` | ADMIN ONLY | ❌ No |
| `customer_app/firestore_service.dart` | **PRODUCTION CRITICAL** | ✅ **YES** |
| `technician_app/category_data_service.dart` | **PRODUCTION CRITICAL** | ✅ **YES** |

**VERDICT:** 🔴 **BLOCKED** - 2 production-critical references found

---

### `cleaning_essentials`

| Reference | Classification | Critical? |
|-----------|----------------|-----------|
| `admin/dynamic_content.ts` | ADMIN ONLY | ❌ No |
| `admin/system_initialization.ts` | ADMIN ONLY | ❌ No |
| `customer_app/firestore_service.dart` | MARKETING ONLY | ❌ No |

**VERDICT:** 🟢 **SAFE TO MIGRATE** - No critical dependencies

---

### `subServices`

**VERDICT:** 🟢 **NOT AFFECTED** - Different system, not part of this migration

---

## 🚨 STEP 3: PRODUCTION CRITICAL FINDINGS

### ❌ BLOCKER #1: Customer App Uses `technician_categories`

**File:** `apps/customer_app/lib/core/services/firestore_service.dart`

**Lines 548-558:**
```dart
Stream<List<TechnicianCategory>> streamTechnicianCategories() {
  return _db.collection('technician_categories')  // ← BLOCKER
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final categories = snapshot.docs
          .map((doc) => TechnicianCategory.fromFirestore(doc))
          .toList();
        categories.sort((a, b) => a.order.compareTo(b.order));
        return categories;
      });
}
```

**Lines 581-590:**
```dart
Future<List<TechnicianCategory>> getTechnicianCategories() async {
  final snapshot = await _db.collection('technician_categories')  // ← BLOCKER
      .where('isActive', isEqualTo: true)
      .get();
  
  final categories = snapshot.docs
    .map((doc) => TechnicianCategory.fromFirestore(doc))
    .toList();
  categories.sort((a, b) => a.order.compareTo(b.order));
  return categories;
}
```

**Impact:** Customer app will break if `technician_categories` is deleted

---

### ❌ BLOCKER #2: Customer App Uses `technician_subcategories`

**File:** `apps/customer_app/lib/core/services/firestore_service.dart`

**Lines 562-576:**
```dart
Stream<List<TechnicianSubcategory>> streamTechnicianSubcategories({String? categoryId}) {
  Query query = _db.collection('technician_subcategories')  // ← BLOCKER
      .where('isActive', isEqualTo: true);
  
  if (categoryId != null) {
    query = query.where('categoryId', isEqualTo: categoryId);
  }

  return query.snapshots()
      .map((snapshot) {
        final subcategories = snapshot.docs
          .map((doc) => TechnicianSubcategory.fromFirestore(doc))
          .toList();
        subcategories.sort((a, b) => a.order.compareTo(b.order));
        return subcategories;
      });
}
```

**Lines 593-602:**
```dart
Future<List<TechnicianSubcategory>> getTechnicianSubcategories() async {
  final snapshot = await _db.collection('technician_subcategories')  // ← BLOCKER
      .where('isActive', isEqualTo: true)
      .get();
  
  final subcategories = snapshot.docs
    .map((doc) => TechnicianSubcategory.fromFirestore(doc))
    .toList();
  subcategories.sort((a, b) => a.order.compareTo(b.order));
  return subcategories;
}
```

**Impact:** Customer app will break if `technician_subcategories` is deleted

---

### ❌ BLOCKER #3: Technician App Uses `technician_subcategories`

**File:** `apps/technician_app/lib/core/services/category_data_service.dart`

**Lines 151-175:**
```dart
/// STRICT: Only collection "technician_subcategories", orderBy "order", filter categoryId
Future<List<SubCategoryData>> getSubCategories({String? categoryId, bool forceRefresh = false}) async {
  if (forceRefresh) clearCache();

  try {
    debugPrint('[SUBCATEGORY] Fetching from "technician_subcategories" for category: $categoryId');
    
    Query query = _firestore
        .collection('technician_subcategories')  // ← BLOCKER
        .where('isActive', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    QuerySnapshot snapshot = await query.orderBy('order').get();

    debugPrint('[SUBCATEGORY] SUCCESS: docs=${snapshot.docs.length}');
    
    final subCategories = snapshot.docs
        .map((doc) => SubCategoryData.fromFirestore(doc))
        .toList();
        
    return subCategories;
  } catch (e) {
    debugPrint('[SUBCATEGORY] CRITICAL ERROR fetching subcategories: $e');
    rethrow;
  }
}
```

**Impact:** Technician app will break if `technician_subcategories` is deleted

---

### ❌ BLOCKER #4: Backend Onboarding Uses `technician_categories`

**File:** `functions/src/technician/onboarding.ts`

**Line 359:**
```typescript
const categoryDoc = await db.collection('technician_categories').doc(categoryId).get();
```

**Context:** Validates category during technician onboarding

**Impact:** Technician onboarding will fail if `technician_categories` is deleted

---

## ✅ STEP 4: BOOKING & MATCHING FLOW VERIFICATION

### Booking Creation Flow

**File:** `functions/src/booking/new_booking_flow.ts`

**Lines 145-157:**
```typescript
// Fallback to global services (if applicable)
const globalServiceDoc = await db.collection('categories').doc(categoryId)
    .collection('services').doc(serviceId).get();

if (!globalServiceDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Service not found');
}
```

✅ **VERIFIED:** Uses `collection('categories')` - NOT `technician_categories`

---

### Matching Engine Flow

**File:** `functions/src/matching/matchTechniciansV2.ts`

**Lines 258-285:**
```typescript
// Query eligible technicians
let query: admin.firestore.Query = db.collection("technicians")
  .where("isApproved", "==", true)
  .where("isOnline", "==", true);

if (subServiceId) {
  query = query.where("subServices", "array-contains", subServiceId);
} else {
  query = query.where("services", "array-contains", serviceId);
}
```

✅ **VERIFIED:** Uses `collection('technicians')` with `services` array field
✅ **VERIFIED:** Does NOT use `technician_categories` or `technician_subcategories`

---

## 🔐 STEP 5: FIRESTORE RULES VERIFICATION

**File:** `apps/technician_app/firestore.rules`

**Search Results:** No references to `technician_categories` or `technician_subcategories` ✅

**Conclusion:** Security rules do NOT depend on legacy collections

---

## 📊 STEP 6: FINAL RESULT

### 🔴 **BLOCKED - MIGRATION CANNOT PROCEED**

**Reason:** 4 production-critical references found that will break the application

---

## 🛠️ FILES REQUIRING FIXES BEFORE MIGRATION

### 1. Customer App - `firestore_service.dart`

**Required Changes:**
- Replace `collection('technician_categories')` → `collection('categories')`
- Replace `collection('technician_subcategories')` → `collection('services')`
- Update query logic to filter by `categoryId`

**Lines to Fix:** 548, 562, 581, 593

---

### 2. Technician App - `category_data_service.dart`

**Required Changes:**
- Replace `collection('technician_subcategories')` → `collection('services')`
- Update query to filter by `categoryId`

**Lines to Fix:** 159

---

### 3. Backend - `onboarding.ts`

**Required Changes:**
- Replace `collection('technician_categories')` → `collection('categories')`

**Lines to Fix:** 359

---

### 4. Backend - `dynamic_content.ts` (Admin Panel)

**Required Changes:**
- Replace all `technician_categories` → `categories`
- Replace all `technician_subcategories` → `services`
- Update CRUD operations

**Lines to Fix:** 134, 223, 224, 381, 392, 409, 421, 430, 439, 456, 468, 477, 486

---

### 5. Backend - `system_initialization.ts` (Admin Panel)

**Required Changes:**
- Update seed data to use `categories` and `services`

**Lines to Fix:** 15, 90, 93, 94, 106

---

## 📋 MIGRATION CHECKLIST

### Phase 1: Code Updates (REQUIRED BEFORE MIGRATION)
- [ ] Fix Customer App `firestore_service.dart`
- [ ] Fix Technician App `category_data_service.dart`
- [ ] Fix Backend `onboarding.ts`
- [ ] Fix Backend `dynamic_content.ts`
- [ ] Fix Backend `system_initialization.ts`
- [ ] Deploy all code changes
- [ ] Test all affected features

### Phase 2: Data Migration (AFTER CODE FIXES)
- [ ] Run migration script
- [ ] Verify data integrity
- [ ] Test all apps end-to-end

### Phase 3: Cleanup (AFTER 7 DAYS STABLE)
- [ ] Archive legacy collections
- [ ] Monitor for 30 days
- [ ] Permanent deletion

---

## 🎯 RECOMMENDATION

**DO NOT RUN MIGRATION SCRIPT YET**

**Next Steps:**
1. Fix all 5 files listed above
2. Deploy code changes to production
3. Test thoroughly
4. THEN run migration script
5. Monitor for issues

**Estimated Time:**
- Code fixes: 2-3 hours
- Testing: 1-2 hours
- Deployment: 30 minutes
- Migration: 10 minutes
- Total: 4-6 hours

---

**Report Generated:** 2024
**Status:** ⚠️ MIGRATION BLOCKED - CODE FIXES REQUIRED FIRST
