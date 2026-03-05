# ⚡ APP CHECK DISABLED - QUICK REFERENCE

**Status:** ⚠️ DEVELOPMENT MODE  
**Deploy:** Run `disable_app_check.bat`

---

## 🎯 WHAT CHANGED

**App Check enforcement:** `true` → `false`

**26 functions** now callable without App Check tokens

---

## 🚀 DEPLOY NOW

```bash
# Quick deploy
disable_app_check.bat

# OR manually
cd C:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions
```

---

## ✅ WHAT THIS FIXES

- ✅ No more "App attestation failed (403)"
- ✅ No more "unauthenticated" errors
- ✅ State/district selection works
- ✅ Profile updates save correctly
- ✅ All functions callable in debug mode

---

## 🔐 SECURITY

**Still Secure:**
- ✅ Firebase Auth required
- ✅ User owns data check
- ✅ Rate limiting active

**Temporarily Disabled:**
- ⚠️ App Check token validation
- ⚠️ Device attestation

---

## 🧪 TEST

1. Open customer app
2. Edit Profile → Select State → Select District
3. Save
4. ✅ Should work without errors

---

## ⚠️ BEFORE PRODUCTION

**MUST re-enable App Check:**

1. Change all functions: `{ enforceAppCheck: true }`
2. Register production apps in Firebase Console
3. Enable Play Integrity (Android) / App Attest (iOS)
4. Redeploy functions
5. Enable enforcement in Firebase Console

---

## 📞 SUPPORT

**Phone:** 9508322397  
**Firebase Console:** https://console.firebase.google.com/project/homefix-aa42d

---

**⚠️ REMINDER: This is TEMPORARY for development only!**
