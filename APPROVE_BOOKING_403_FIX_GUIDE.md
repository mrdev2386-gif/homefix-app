# 403 Forbidden Error Fix - Implementation Guide

## Quick Summary

**Problem**: Clicking "Approve Booking" returns `403 Forbidden`

**Cause**: Admin user lacks `admin: true` custom claim in Firebase Auth token

**Solution**: Set admin custom claim using provided script, then refresh token

**Time to Fix**: ~5 minutes

---

## Prerequisites

### Required
- [ ] Node.js installed (v14+)
- [ ] Firebase CLI installed
- [ ] Access to Firebase Console
- [ ] Admin email address

### Optional
- [ ] Firebase service account key (will download if needed)

---

## Step-by-Step Fix

### STEP 1: Download Firebase Service Account Key

**Location**: Firebase Console → Project Settings → Service Accounts

**Instructions**:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project: **homefix-aa42d**
3. Click ⚙️ (Settings) → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Save file as `scripts/serviceAccountKey.json`

**File Structure**:
```
homefix/
├── scripts/
│   ├── setAdminRole.js
│   └── serviceAccountKey.json  ← Place here
└── ...
```

### STEP 2: Install Dependencies

**Command**:
```bash
cd c:\Users\yash\projects\homefix
npm install firebase-admin
```

**Expected Output**:
```
added X packages
```

### STEP 3: Run Admin Role Setup Script

**Command**:
```bash
node scripts/setAdminRole.js admin@homefix.com
```

**Replace** `admin@homefix.com` with actual admin email

**Expected Output**:
```
============================================================
🔐 HomeFix Admin Role Setup
============================================================

✅ Firebase Admin SDK initialized
📧 Looking up user: admin@homefix.com
✅ Found user: <uid>
   Email: admin@homefix.com
   Display Name: Admin User

🔧 Setting admin custom claim...
✅ Admin claim set successfully

============================================================
✅ ADMIN ROLE SETUP COMPLETE
============================================================

📋 User Details:
   Email: admin@homefix.com
   UID: <uid>
   Custom Claim: admin = true

📝 Next Steps:
   1. Log out from admin panel
   2. Close the browser completely
   3. Clear browser cache (optional but recommended)
   4. Log back in with the admin email
   5. Token will refresh with admin claim
   6. Try approving a booking

🔍 To Verify Admin Claim:
   1. Open admin panel
   2. Open browser DevTools (F12)
   3. Go to Console tab
   4. Run this command:
      firebase.auth().currentUser.getIdTokenResult().then(r => console.log(r.claims))
   5. Should show: { admin: true, ... }

❓ Troubleshooting:
   • If still getting 403: Log out and back in again
   • If token doesn't show admin claim: Clear browser cache
   • If user not found: Check email spelling in Firebase Console

============================================================
```

### STEP 4: Log Out from Admin Panel

**Instructions**:
1. Open admin panel: `http://localhost:3000`
2. Click profile icon (top right)
3. Click **Sign Out**
4. Confirm logout

### STEP 5: Close Browser Completely

**Why**: Clears all cached tokens and cookies

**Instructions**:
1. Close all browser windows
2. Wait 5 seconds
3. Reopen browser

### STEP 6: Log Back In

**Instructions**:
1. Go to `http://localhost:3000`
2. Log in with admin email
3. Wait for page to load

**What Happens**:
- AuthProvider forces token refresh
- New token includes `admin: true` claim
- Admin panel loads successfully

### STEP 7: Verify Admin Claim

**Instructions**:
1. Open browser DevTools (F12)
2. Go to **Console** tab
3. Paste this command:
   ```javascript
   firebase.auth().currentUser.getIdTokenResult().then(r => console.log(r.claims))
   ```
4. Press Enter

**Expected Output**:
```javascript
{
  admin: true,
  iss: "https://securetoken.google.com/homefix-aa42d",
  aud: "homefix-aa42d",
  auth_time: 1234567890,
  user_id: "<uid>",
  sub: "<uid>",
  iat: 1234567890,
  exp: 1234571490,
  email: "admin@homefix.com",
  email_verified: false,
  firebase: { ... }
}
```

✅ **If you see `admin: true`, the fix is working!**

### STEP 8: Test Approve Booking

**Instructions**:
1. Navigate to **Bookings**
2. Click on a booking with status **PENDING_ADMIN_APPROVAL**
3. Click **Approve** button
4. Confirm in dialog

**Expected Result**:
- ✅ No 403 error
- ✅ Button shows loading state
- ✅ Booking status changes to **ADMIN_APPROVED**
- ✅ Timeline updates
- ✅ Success message appears

---

## Troubleshooting

### Issue 1: Script Says "User Not Found"

**Cause**: Email doesn't match Firebase user

**Solution**:
1. Go to Firebase Console → Authentication
2. Find the admin user
3. Copy exact email (case-sensitive)
4. Run script again with correct email

**Example**:
```bash
# Wrong
node scripts/setAdminRole.js Admin@homefix.com

# Correct
node scripts/setAdminRole.js admin@homefix.com
```

### Issue 2: Still Getting 403 After Setup

**Cause**: Token not refreshed

**Solution**:
1. Log out from admin panel
2. Close browser completely
3. Clear browser cache:
   - Chrome: Ctrl+Shift+Delete
   - Firefox: Ctrl+Shift+Delete
   - Safari: Cmd+Shift+Delete
4. Log back in
5. Try again

### Issue 3: Admin Claim Not Showing in Token

**Cause**: Token refresh didn't happen

**Solution**:
1. Open DevTools (F12)
2. Go to Application → Cookies
3. Delete all cookies for localhost
4. Refresh page
5. Log in again
6. Check token again

### Issue 4: Service Account Key Not Found

**Cause**: File not in correct location

**Solution**:
1. Download key from Firebase Console
2. Place in: `scripts/serviceAccountKey.json`
3. Verify file exists:
   ```bash
   dir scripts\serviceAccountKey.json
   ```
4. Run script again

### Issue 5: Permission Denied Error

**Cause**: Service account key doesn't have permissions

**Solution**:
1. Go to Firebase Console → Project Settings
2. Download a NEW service account key
3. Replace `scripts/serviceAccountKey.json`
4. Run script again

---

## Verification Checklist

### Before Fix
- [ ] Getting 403 error when clicking Approve
- [ ] Admin panel loads (user is authenticated)
- [ ] AuthProvider shows "Non-admin user attempted access" in console

### After Fix
- [ ] Script runs successfully
- [ ] Admin claim set on user
- [ ] Token refresh happens on login
- [ ] Admin claim visible in browser console
- [ ] No 403 error when approving booking
- [ ] Booking status updates to ADMIN_APPROVED
- [ ] Timeline updates correctly

---

## How It Works

### Before Fix
```
1. Admin logs in
2. AuthProvider checks for admin claim
3. Claim is missing
4. AuthProvider redirects to login (or allows access if not enforced)
5. Admin clicks Approve
6. Cloud Function checks for admin claim
7. Claim is missing
8. Cloud Function throws 403 Forbidden
```

### After Fix
```
1. Admin logs in
2. AuthProvider checks for admin claim
3. Claim is present (set by script)
4. AuthProvider allows access
5. Admin clicks Approve
6. Cloud Function checks for admin claim
7. Claim is present
8. Cloud Function approves booking
9. Booking status updates to ADMIN_APPROVED
```

---

## Security Notes

### ✅ This is Secure
- Admin claim set server-side only (via Admin SDK)
- Cannot be modified by client
- Verified by Cloud Function on every call
- Included in ID token (cryptographically signed)
- Requires Firebase authentication

### ✅ Best Practices
- Admin role verified on every function call
- Token refresh on login
- Non-admin users cannot access admin functions
- Audit logging for all actions

---

## Additional Admin Users

### To Add More Admins

**Command**:
```bash
node scripts/setAdminRole.js another-admin@homefix.com
```

**Repeat for each admin user**

### To Remove Admin Role

**Use Firebase Console**:
1. Go to Firebase Console → Authentication
2. Find user
3. Click on user
4. Scroll to "Custom Claims"
5. Edit and remove `admin: true`
6. Save

---

## Deployment Notes

### Cloud Functions
- ✅ Already deployed and working
- ✅ Already checking for admin claim
- ✅ No changes needed

### Admin Panel
- ✅ Already checking for admin claim
- ✅ Already forcing token refresh
- ✅ No changes needed

### Only Change Needed
- ✅ Set admin custom claim on user account (done by script)

---

## Next Steps

### Immediate
1. ✅ Run setAdminRole.js script
2. ✅ Log out and back in
3. ✅ Test approve booking

### Short-term
1. Document admin setup process
2. Add admin user setup to onboarding
3. Create admin user management guide

### Long-term
1. Implement admin user management UI
2. Add role-based access control (RBAC)
3. Add audit logging dashboard

---

## Support

### If You Get Stuck

1. **Check the diagnostic report**: `APPROVE_BOOKING_403_DIAGNOSTIC_REPORT.md`
2. **Review this guide**: `APPROVE_BOOKING_403_FIX_GUIDE.md`
3. **Check browser console**: F12 → Console tab
4. **Check Firebase logs**: `firebase functions:log`

### Common Commands

```bash
# Check if script exists
dir scripts\setAdminRole.js

# Check if service account key exists
dir scripts\serviceAccountKey.json

# Run script
node scripts\setAdminRole.js admin@homefix.com

# Check Firebase functions
firebase functions:list

# View function logs
firebase functions:log

# Deploy functions
firebase deploy --only functions
```

---

## Summary

| Step | Action | Time |
|------|--------|------|
| 1 | Download service account key | 2 min |
| 2 | Install dependencies | 1 min |
| 3 | Run admin role script | 1 min |
| 4 | Log out from admin panel | 1 min |
| 5 | Close browser | 1 min |
| 6 | Log back in | 1 min |
| 7 | Verify admin claim | 1 min |
| 8 | Test approve booking | 1 min |
| **Total** | | **~10 min** |

---

## Conclusion

The 403 Forbidden error is fixed by setting the admin custom claim on the Firebase user account. This is a one-time setup that takes about 10 minutes. After that, the admin can approve bookings without any issues.

**Status**: ✅ Ready to implement
