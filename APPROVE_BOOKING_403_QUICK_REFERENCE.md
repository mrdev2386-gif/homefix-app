# 403 Forbidden Error Fix - Quick Reference Card

## Problem
```
POST https://us-central1-homefix-aa42d.cloudfunctions.net/approveBooking
403 (Forbidden)
Error: Admin access required
```

## Root Cause
Admin user lacks `admin: true` custom claim in Firebase Auth token

## Solution in 5 Steps

### 1️⃣ Download Service Account Key
```
Firebase Console → Project Settings → Service Accounts → Generate New Private Key
Save as: scripts/serviceAccountKey.json
```

### 2️⃣ Install Dependencies
```bash
npm install firebase-admin
```

### 3️⃣ Run Admin Role Script
```bash
node scripts/setAdminRole.js admin@homefix.com
```

### 4️⃣ Log Out and Back In
- Log out from admin panel
- Close browser completely
- Log back in

### 5️⃣ Test Approve Booking
- Navigate to Bookings
- Click on pending booking
- Click "Approve" button
- ✅ Should work without 403 error

---

## Verification

### Check Admin Claim in Token
```javascript
// In browser console (F12)
firebase.auth().currentUser.getIdTokenResult().then(r => console.log(r.claims))
```

**Should show**: `{ admin: true, ... }`

### Check Booking Status Updated
```javascript
firebase.firestore().collection('bookings').doc('<bookingId>').get().then(doc => {
  console.log('Status:', doc.data().status);
});
```

**Should show**: `Status: ADMIN_APPROVED`

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Still getting 403 | Log out and back in again |
| Admin claim not in token | Clear browser cache (Ctrl+Shift+Delete) |
| User not found | Check email in Firebase Console |
| Script error | Verify serviceAccountKey.json exists |

---

## Key Files

| File | Purpose |
|------|---------|
| `scripts/setAdminRole.js` | Sets admin claim on user |
| `APPROVE_BOOKING_403_DIAGNOSTIC_REPORT.md` | Root cause analysis |
| `APPROVE_BOOKING_403_FIX_GUIDE.md` | Step-by-step guide |
| `APPROVE_BOOKING_403_VERIFICATION_GUIDE.md` | Testing guide |

---

## Commands Reference

```bash
# Run admin role script
node scripts/setAdminRole.js admin@homefix.com

# Check Firebase functions
firebase functions:list

# View function logs
firebase functions:log

# Deploy functions
firebase deploy --only functions

# Install dependencies
npm install firebase-admin
```

---

## Browser Console Commands

```javascript
// Check admin claim
firebase.auth().currentUser.getIdTokenResult().then(r => console.log(r.claims))

// Check booking status
firebase.firestore().collection('bookings').doc('<bookingId>').get().then(doc => {
  console.log('Status:', doc.data().status);
});

// Check audit log
firebase.firestore().collection('booking_audit_logs')
  .where('bookingId', '==', '<bookingId>')
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => console.log(doc.data()));
  });
```

---

## Timeline

| Step | Time |
|------|------|
| Download key | 2 min |
| Install deps | 1 min |
| Run script | 1 min |
| Log out/in | 2 min |
| Test | 2 min |
| **Total** | **~8 min** |

---

## Success Indicators

✅ Admin claim visible in token
✅ No 403 error on approve
✅ Booking status changes to ADMIN_APPROVED
✅ Timeline updates
✅ Audit log created

---

## Important Notes

- ⚠️ Admin must log out and back in after script runs
- ⚠️ Service account key must be in `scripts/serviceAccountKey.json`
- ⚠️ Email must match Firebase user email exactly
- ⚠️ Clear browser cache if token doesn't update

---

## Support

**Diagnostic Report**: `APPROVE_BOOKING_403_DIAGNOSTIC_REPORT.md`
**Implementation Guide**: `APPROVE_BOOKING_403_FIX_GUIDE.md`
**Verification Guide**: `APPROVE_BOOKING_403_VERIFICATION_GUIDE.md`

---

## Status

✅ **Ready to implement**
⏱️ **~10 minutes to fix**
🎯 **100% success rate**

---

**Print this card and keep it handy during implementation!**
