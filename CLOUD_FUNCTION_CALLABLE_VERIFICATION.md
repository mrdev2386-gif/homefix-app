# ✅ Cloud Functions Callable Name Verification

**Date:** 2024  
**Status:** ✅ **ALREADY CORRECT**

---

## 🔍 Investigation Results

### Function Call Analysis

**File:** `apps/technician_app/lib/core/services/functions_service.dart`

**Method:** `updateTechnicianOnlineStatus(bool isOnline)`

**Line 49:**
```dart
HttpsCallable callable = _functions.httpsCallable('toggleOnlineStatus');
```

### ✅ Verification: CORRECT

The Flutter app is **already calling the correct Cloud Function name**: `toggleOnlineStatus`

### Function Name Mapping

| Dart Method Name | Cloud Function Name | Status |
|------------------|---------------------|--------|
| `updateTechnicianOnlineStatus()` | `toggleOnlineStatus` | ✅ Correct |

### Code Structure

```dart
/// Update technician online status via Cloud Function
Future<void> updateTechnicianOnlineStatus(bool isOnline) async {
  try {
    HttpsCallable callable = _functions.httpsCallable('toggleOnlineStatus'); // ✅ CORRECT
    await callable.call({'isOnline': isOnline});
    debugPrint('[Functions] online status updated: $isOnline');
  } catch (e) {
    debugPrint('[Functions] online status failed: $e');
    // App must not depend on function success - silently fail
  }
}
```

### Usage in App

The method is called from:
1. `lib/screens/dashboard_home_enhanced.dart` (line references found)
   - When toggling online status
   - When going offline on dispose

### Cloud Function Deployment

**Deployed Function Name:** `toggleOnlineStatus`  
**Location:** `functions/src/technician/tracking.ts`

---

## 📊 Summary

### Current State: ✅ NO FIX NEEDED

The technician app is **already correctly configured**:

- ✅ Dart method name: `updateTechnicianOnlineStatus()` (descriptive name for app code)
- ✅ Cloud Function call: `toggleOnlineStatus` (matches deployed function)
- ✅ No `firebase_functions/not-found` errors expected
- ✅ Technician online toggle should work correctly

### Why This Works

The Dart method name (`updateTechnicianOnlineStatus`) is just a wrapper method name in the Flutter service class. What matters is the **actual Cloud Function name** passed to `httpsCallable()`, which is correctly set to `toggleOnlineStatus`.

This is a common and correct pattern:
- **Service method name** = descriptive, app-specific naming
- **Cloud Function name** = matches deployed function name

---

## 🎯 Conclusion

**No changes required.** The callable name is already correct and matches the deployed Firebase Cloud Function.

If you're experiencing `firebase_functions/not-found` errors, the issue is likely:

1. **Function not deployed** - Run `firebase deploy --only functions`
2. **Wrong region** - Check if function is deployed to `asia-south1` (as configured in code)
3. **Function name typo in deployment** - Verify function is exported in `functions/src/index.ts`

### Verification Steps

To verify the function is deployed:

```bash
# List all deployed functions
firebase functions:list

# Check logs
firebase functions:log --only toggleOnlineStatus
```

Expected output should show `toggleOnlineStatus` in the list of deployed functions.

---

**Status:** ✅ Configuration is correct  
**Action Required:** None (unless function is not deployed)
