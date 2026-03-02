# ⚡ Quick Fix Reference Card

## 🔥 IMMEDIATE ACTIONS (Do These First)

### 1. Get App Check Debug Token (2 minutes)

```powershell
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter run
```

**Look for this in console:**
```
TOKEN_EXTRACTOR: 🔥 APP_CHECK_DEBUG_TOKEN: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

**Copy the token** → Go to Firebase Console → App Check → Apps → Add debug token → Paste → Save

**Restart app completely** (not hot reload)

---

### 2. Create FAQ Index (1 minute)

**Option A:** Click the index error link in console

**Option B:** Firebase Console → Firestore → Indexes → Create:
- Collection: `faqs`
- Fields: `category` (Ascending), `order` (Ascending)
- Click Create

Wait for status: **Enabled**

---

### 3. Approve Your Technician (1 minute)

Firebase Console → Firestore → `technicians/{your-uid}` → Edit:

```
isApproved: true
adminApproved: true
isKycComplete: true
status: "approved"
```

Click **Update**

---

## 🧪 QUICK TESTS

### Test 1: Profile Update
1. Open app → Profile
2. Change name
3. Save
4. **Expected:** `[TECH WRITE] SUCCESS via CF`

### Test 2: Service Creation
1. Open app → Services
2. Add new service
3. Fill all fields
4. Save
5. **Expected:** `[SERVICE CREATE] SUCCESS`

---

## 🚨 Quick Troubleshooting

| Error | Quick Fix |
|-------|-----------|
| App Check 403 | Register debug token in Firebase Console |
| Index not found | Create FAQ index (see above) |
| Not approved | Set isApproved=true in Firestore |
| Function not found | `firebase deploy --only functions:saveTechnicianStepData` |
| Profile not saving | Check Cloud Function logs in Firebase Console |

---

## ✅ Success Indicators

You're good when you see:

```
✅ [APP_CHECK] ✅ Activated (Mode: Debug)
✅ [TECH WRITE] SUCCESS via CF
✅ [SERVICE CREATE] SUCCESS
✅ [CATEGORY] SUCCESS: Fetched categories: X
```

---

## 📋 Complete Checklist

- [ ] App Check debug token registered
- [ ] FAQ index created and enabled
- [ ] Technician approved in Firestore
- [ ] Cloud Function deployed
- [ ] Profile update works
- [ ] Service creation works

**All checked? You're done! 🎉**

---

## 📖 Full Guide

For detailed instructions, see: **APP_CHECK_FIRESTORE_FIX.md**
