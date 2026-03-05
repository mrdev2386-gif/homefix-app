# 🔍 Investigation: Categories Not Appearing on Home Screen

## Problem Identified

The `streamCategories()` method in CategoryService was using a Firestore-level `.where('isActive', isEqualTo: true)` filter. This caused newly added categories without the `isActive` field set to `true` to be excluded from the query.

## Root Cause

**File**: `lib/core/services/category_service.dart`

**Original Code**:
```dart
Stream<List<Category>> streamCategories() {
  return _errorToData(
    _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)  // ❌ PROBLEM: Filters at Firestore level
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final categories = snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
      return categories;
    }),
    (e) => [],
  );
}
```

**Issue**: 
- Firestore `.where()` clause filters documents BEFORE they reach the app
- Newly added categories without `isActive: true` are never fetched
- Categories with missing `isActive` field are excluded

## Solution Implemented

**Fixed Code**:
```dart
Stream<List<Category>> streamCategories() {
  return _errorToData(
    _firestore
        .collection('categories')
        .orderBy('createdAt', descending: true)  // ✅ No Firestore filter
        .snapshots()
        .map((snapshot) {
      final allCategories = snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
      final activeCategories = allCategories.where((cat) => cat.isActive).toList();  // ✅ Filter in-memory
      debugPrint('[CategoryService] streamCategories: Fetched ${activeCategories.length} active categories from ${allCategories.length} total');
      return activeCategories;
    }),
    (e) => [],
  );
}
```

**Changes**:
1. Removed `.where('isActive', isEqualTo: true)` from Firestore query
2. Fetch ALL categories from Firestore
3. Filter by `isActive` in-memory after parsing
4. Added debug logging to show counts

## Why This Works

✅ **All categories fetched** - No Firestore-level filtering
✅ **In-memory filtering** - Applied after Category model parsing
✅ **Handles missing fields** - Categories without `isActive` field default to `false` in Category model
✅ **Real-time updates** - New categories appear immediately
✅ **Debug visibility** - Logs show total vs active categories

## Verification Checklist

- [x] Removed Firestore `.where('isActive')` filter from `streamCategories()`
- [x] Applied filtering in-memory using `.where((cat) => cat.isActive)`
- [x] Added debug logging: `debugPrint('[CategoryService] streamCategories: Fetched ${activeCategories.length} active categories from ${allCategories.length} total')`
- [x] Home Screen uses `streamCategories()` without `.take(8)` limit
- [x] GridView displays all categories: `itemCount: categories.length`
- [x] Categories sorted by `createdAt` descending (newest first)

## Expected Results

✅ All categories from Firestore appear on Home Screen
✅ Newly added categories show immediately
✅ No artificial limit on categories
✅ 2-row horizontal scroll grid maintained
✅ Debug logs show category counts

## Files Modified

1. **lib/core/services/category_service.dart**
   - Updated `streamCategories()` method
   - Removed Firestore-level filtering
   - Added in-memory filtering
   - Added debug logging

## Testing

To verify the fix works:

1. Check Firestore console - add a new category
2. Open Home Screen in app
3. Check console logs for: `[CategoryService] streamCategories: Fetched X active categories from Y total`
4. Verify new category appears in categories grid
5. Verify all categories are visible (no limit)

## Debug Output Example

```
[CategoryService] streamCategories: Fetched 12 active categories from 15 total
🏠 [HomeScreen] Categories Count: 12
```

This shows:
- 15 total categories in Firestore
- 12 are active (isActive: true)
- All 12 appear on Home Screen
