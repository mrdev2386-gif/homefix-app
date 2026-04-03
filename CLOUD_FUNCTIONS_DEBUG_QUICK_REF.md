# Cloud Functions Debugging - Quick Reference

## 🔴 CRITICAL ISSUES FIXED

### 1. Type Validation Missing
**Before**: `if (!price)` → Could accept string "0"
**After**: `if (typeof price !== 'number' || price <= 0)` → Strict type checking

### 2. Firestore Write Failure
**Before**: `.update()` on non-existent customer document → CRASH
**After**: Wrapped in try-catch with fallback

### 3. Missing Error Context
**Before**: `console.error('Failed:', error)` → Generic message
**After**: Full error object with message, code, stack, uid, requestData

### 4. No Request Logging
**Before**: No visibility into what client sent
**After**: Every request logged with full data

---

## 📋 Files Modified

```
✅ functions/src/customer/cart_management.ts
   - addToCartCallable (Line 8)
   - updateCartQuantityCallable (Line 120)
   - removeFromCartCallable (Line 180)
   - clearCartCallable (Line 220)

✅ functions/src/customer/favorites_management.ts
   - toggleFavoriteCallable (Line 8)
```

---

## 🧪 Testing After Deployment

### Test 1: Valid Request
```bash
# Should see in logs:
# [addToCartCallable] REQUEST RECEIVED
# [addToCartCallable] SUCCESS
```

### Test 2: Invalid Price (String)
```bash
# Should see in logs:
# [addToCartCallable] VALIDATION FAILED: price invalid { price: '500', type: 'string' }
```

### Test 3: Missing serviceId
```bash
# Should see in logs:
# [addToCartCallable] VALIDATION FAILED: serviceId missing or invalid
```

---

## 🔍 How to Read Logs

### Firebase Console
1. Go to Firebase Console → Functions
2. Click on function name
3. Click "Logs" tab
4. Filter by function name: `addToCartCallable` or `toggleFavoriteCallable`
5. Look for `[functionName]` prefix in logs

### Command Line
```bash
firebase functions:log --region asia-south1
```

---

## 🚀 Deployment

```bash
cd c:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions
```

---

## ✅ Validation Checklist

- [x] All inputs have type checking
- [x] All errors logged with full context
- [x] All operations logged
- [x] Firestore failures handled gracefully
- [x] Non-critical failures don't crash function
- [x] Request data logged for debugging
- [x] Success responses logged
- [x] Error responses include error message

---

## 📊 Logging Levels

| Level | Example | When |
|-------|---------|------|
| INFO | `[addToCartCallable] REQUEST RECEIVED` | Function called |
| INFO | `[addToCartCallable] Authenticated UID: user123` | Auth verified |
| INFO | `[addToCartCallable] Generated itemId: svc1` | Processing |
| WARN | `[addToCartCallable] Failed to update customer lastCartUpdate` | Non-critical failure |
| ERROR | `[addToCartCallable] VALIDATION FAILED: price invalid` | Validation error |
| ERROR | `[addToCartCallable] INTERNAL ERROR: ...` | Unexpected error |

---

## 🎯 Common Issues & Solutions

| Issue | Log Message | Solution |
|-------|-------------|----------|
| Wrong price type | `VALIDATION FAILED: price invalid { price: '500', type: 'string' }` | Send number, not string |
| Missing serviceId | `VALIDATION FAILED: serviceId missing or invalid` | Include serviceId in request |
| Firestore write fails | `INTERNAL ERROR: ... code: 'permission-denied'` | Check Firestore security rules |
| Customer doc missing | `Failed to update customer lastCartUpdate` | Create customer document first |

---

**Status**: ✅ READY FOR DEPLOYMENT
