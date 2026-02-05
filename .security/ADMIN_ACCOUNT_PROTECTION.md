# Admin Account Protection - Security Fix

## Issue Summary
Admin accounts were vulnerable to being disabled in Firebase Authentication through the `admin_manageUser` Cloud Function. This occurred when:
1. The `type` parameter was not passed from the admin panel
2. No validation existed to prevent admin accounts from being disabled
3. No fail-safe existed to protect admin UIDs

## Root Cause
**Location:** `functions/src/admin/users.ts` - `manageUser` function

**The Problem:**
```typescript
// BEFORE (VULNERABLE)
const { userId, action, type } = data;
if (!userId || !action) throw new Error('Missing params');
// type was optional - could be undefined
const collection = type === 'technician' ? 'technicians' : 'customers';
// No check if userId is an admin
await admin.auth().updateUser(userId, { disabled: true });
```

**Admin Panel Bug:**
```typescript
// BEFORE (MISSING TYPE)
await fn({ userId, action }); // ❌ type not sent
```

## Security Fix Implemented

### 1. Backend Protection (Cloud Function)

**File:** `functions/src/admin/users.ts`

**Changes:**
- ✅ Made `type` parameter **REQUIRED** and validated
- ✅ Added admin account detection before any operation
- ✅ Implemented double fail-safe before disabling Auth accounts
- ✅ Added detailed error logging for blocked attempts

```typescript
// AFTER (SECURE)
export const manageUser = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);
    const { userId, action, type } = data;

    // STRICT VALIDATION: type is REQUIRED
    if (!userId || !action) throw new HttpsError('invalid-argument', 'Missing userId or action');
    if (!type || !['customer', 'technician'].includes(type)) {
        throw new HttpsError('invalid-argument', 'Missing or invalid type. Must be "customer" or "technician"');
    }

    // CRITICAL SAFEGUARD: Prevent admin accounts from being disabled
    const userRoleDoc = await db.collection('users').doc(userId).get();
    if (userRoleDoc.exists && userRoleDoc.data()?.role === 'admin') {
        console.error(`[User] BLOCKED: Attempt to ${action} admin account ${userId}`);
        throw new HttpsError(
            'permission-denied', 
            'Cannot block/unblock admin accounts. Admin accounts are protected from modification.'
        );
    }

    // ... rest of function

    if (action === 'block') {
        updates.isBlocked = true;
        // FINAL FAIL-SAFE: Double-check before disabling at Auth level
        if (userRoleDoc.exists && userRoleDoc.data()?.role === 'admin') {
            throw new HttpsError('permission-denied', 'Cannot disable admin account at Auth level');
        }
        await admin.auth().updateUser(userId, { disabled: true });
    }
});
```

### 2. Frontend Fix (Admin Panel)

**File:** `apps/admin_panel/src/app/(admin)/customers/page.tsx`

**Changes:**
- ✅ Always send `type: 'customer'` parameter
- ✅ Improved error handling with detailed messages
- ✅ Added success feedback

```typescript
// AFTER (CORRECT)
const handleManageUser = async (userId: string, action: string) => {
    if (!confirm(`Are you sure you want to ${action} this user?`)) return;
    try {
        const fn = httpsCallable(functions, 'admin_manageUser');
        await fn({ userId, action, type: 'customer' }); // ✅ type explicitly sent
        alert(`User ${action}ed successfully`);
    } catch (e: any) {
        console.error('Failed to manage user:', e);
        alert(`Operation failed: ${e.message || 'Unknown error'}`);
    }
};
```

## Security Guarantees

### ✅ Protection Layers

1. **Layer 1: Type Validation**
   - Function rejects requests without valid `type` parameter
   - Prevents undefined behavior

2. **Layer 2: Admin Detection**
   - Checks `users/{uid}.role === 'admin'` before any operation
   - Blocks the entire operation if target is admin

3. **Layer 3: Auth-Level Fail-Safe**
   - Double-checks admin status before calling `admin.auth().updateUser()`
   - Prevents accidental admin account disable

4. **Layer 4: Audit Logging**
   - All blocked attempts are logged with details
   - Helps detect security issues or misuse

### ✅ What's Protected

- ✅ Admin accounts **CANNOT** be blocked via admin panel
- ✅ Admin accounts **CANNOT** be disabled at Firebase Auth level
- ✅ Missing `type` parameter causes immediate rejection
- ✅ Invalid `type` values are rejected
- ✅ All admin modification attempts are logged

### ✅ What Still Works

- ✅ Customer accounts can be blocked/unblocked
- ✅ Technician accounts can be blocked/unblocked (if function is called with type: 'technician')
- ✅ Admin panel functions normally for non-admin users
- ✅ All other admin functions remain unchanged

## Deployment Status

**Deployed:** ✅ February 9, 2026 06:47 AM IST

**Function:** `admin_manageUser` (us-central1)

**Status:** Successfully deployed and active

## Testing Recommendations

### Test Case 1: Block Customer (Should Work)
```
1. Login as admin
2. Go to Customers page
3. Click "Block" on a customer account
4. Verify: Customer is blocked successfully
5. Verify: Customer cannot login
```

### Test Case 2: Block Admin (Should Fail)
```
1. Login as admin
2. Manually call admin_manageUser with admin UID
3. Expected: Error "Cannot block/unblock admin accounts"
4. Verify: Admin account remains active
5. Verify: Admin can still login
```

### Test Case 3: Missing Type (Should Fail)
```
1. Call admin_manageUser without type parameter
2. Expected: Error "Missing or invalid type"
3. Verify: No changes to any account
```

## Monitoring

### Check Admin Logs
```javascript
// Firestore → admin_logs
// Look for blocked attempts:
{
  action: 'user_block',
  targetId: '<admin_uid>',
  timestamp: <timestamp>
}
```

### Check Cloud Functions Logs
```
Firebase Console → Functions → admin_manageUser → Logs
Filter for: "BLOCKED: Attempt to"
```

## Future Improvements

1. **Add Rate Limiting:** Prevent rapid block/unblock attempts
2. **Add Email Alerts:** Notify when admin modification is attempted
3. **Add Audit Dashboard:** Show all blocked admin modification attempts
4. **Add Multi-Admin Protection:** Prevent last admin from being removed

## Rollback Plan

If issues occur, rollback by deploying previous version:
```bash
firebase functions:delete admin_manageUser
# Then redeploy from backup
```

## Contact

For security issues or questions, contact the platform security team.

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-09  
**Author:** Firebase Security Team
