# ⚡ FIREBASE FIXES - QUICK REFERENCE

**Status:** ✅ FIXED  
**Deploy:** Run `deploy_fixes.bat`

---

## 🎯 WHAT WAS FIXED

### 1. Firestore Rules ✅
**Added:** `settings` subcollection access
```javascript
match /settings/{docId} {
  allow read, write: if isOwner(customerId);
}
```

### 2. updateUserProfile Function ✅
**Added Fields:**
- `state` + `stateNormalized`
- `displayName`
- `defaultAddress`
- `latitude`
- `longitude`

### 3. Security ✅
- ✅ Owner-only access maintained
- ✅ No global writes allowed
- ✅ App Check enforced
- ✅ Rate limiting active

---

## 🚀 DEPLOY NOW

```bash
# Run deployment script
deploy_fixes.bat

# OR manually:
firebase deploy --only firestore:rules
cd functions && npm run build
firebase deploy --only functions:updateUserProfile
```

---

## 🧪 TEST

1. Open customer app
2. Go to Profile → Edit Location
3. Select State → Select District → Save
4. ✅ Should save without errors
5. ✅ Data should persist

---

## 🐛 IF ERRORS PERSIST

### PERMISSION_DENIED
- Deploy rules: `firebase deploy --only firestore:rules`
- Check Firebase Console → Firestore → Rules

### unauthenticated
- Verify user logged in
- Register debug token in Firebase Console
- Check App Check initialization

### App Check 403
- Register debug token: Firebase Console → App Check → Apps
- Copy token from app logs
- Paste in "Manage debug tokens"

---

## 📞 SUPPORT

**Phone:** 9508322397  
**Firebase Console:** https://console.firebase.google.com/project/homefix-aa42d

---

## ✅ CHECKLIST

- [ ] Deploy Firestore rules
- [ ] Deploy Cloud Function
- [ ] Register debug tokens
- [ ] Test state selection
- [ ] Test district selection
- [ ] Verify data persists
- [ ] Check no errors in logs

---

**Last Updated:** 2026-01-XX  
**Status:** ✅ READY
