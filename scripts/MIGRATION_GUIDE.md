# HOMEFIX CATEGORY SYSTEM MIGRATION GUIDE

## 🎯 OBJECTIVE
Migrate from legacy `technician_categories` + `technician_subcategories` to unified `categories` + `services` system.

---

## ⚠️ PRE-MIGRATION CHECKLIST

- [ ] Firebase Admin SDK configured
- [ ] `serviceAccountKey.json` placed in project root
- [ ] Node.js installed (v16+)
- [ ] Backup of entire Firestore database taken
- [ ] All team members notified
- [ ] Maintenance window scheduled (optional)

---

## 📦 SETUP

### 1. Install Dependencies
```powershell
cd C:\Users\yash\projects\homefix\scripts
npm init -y
npm install firebase-admin
```

### 2. Place Service Account Key
Download from Firebase Console → Project Settings → Service Accounts
Place at: `C:\Users\yash\projects\homefix\serviceAccountKey.json`

---

## 🚀 EXECUTION STEPS

### PHASE 1️⃣: DRY RUN (Read-Only Verification)

**Check current data counts:**
```powershell
# Open Firebase Console
# Navigate to Firestore Database
# Count documents in:
#   - technician_categories (should be 40+)
#   - technician_subcategories (should be 200+)
#   - categories (check if exists)
#   - services (check current count)
```

---

### PHASE 2️⃣: RUN MIGRATION

```powershell
cd C:\Users\yash\projects\homefix\scripts
node migrate_category_system.js
```

**Expected Output:**
```
🚀 HOMEFIX CATEGORY SYSTEM MIGRATION
=====================================

📦 PHASE 1A: Backing up existing categories collection...
✅ Backed up X documents to _archived_old_categories

📦 PHASE 1B: Migrating technician_categories → categories...
✅ Migrated 40+ categories

📦 PHASE 2: Migrating technician_subcategories → services...
✅ Migrated 200+ services

🔍 PHASE 3: Verifying migration...
📊 Categories count: 40+
📊 Services count: 200+
✅ No orphan services found

✅ MIGRATION COMPLETE
```

---

### PHASE 3️⃣: VERIFICATION

#### A. Firebase Console Check
1. Open Firestore Database
2. Verify `categories` collection has 40+ documents
3. Verify `services` collection has 200+ documents
4. Spot-check 5 random services have valid `categoryId`

#### B. App Testing

**Customer App:**
```powershell
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter run
```
- [ ] Browse services
- [ ] Select category
- [ ] View services under category

**Technician App:**
```powershell
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter run
```
- [ ] Go to Add Service screen
- [ ] Select category dropdown (should load from `categories`)
- [ ] Select service dropdown (should load from `services`)
- [ ] Submit service (should save to `technician_services`)

#### C. Cloud Functions Test
- [ ] Create new booking
- [ ] Matching function runs successfully
- [ ] Service validation passes

---

### PHASE 4️⃣: ROLLBACK (If Needed)

**Only if migration fails:**
```powershell
cd C:\Users\yash\projects\homefix\scripts
node rollback_migration.js
```

This restores `categories` from `_archived_old_categories` backup.

---

### PHASE 5️⃣: MONITOR (7 Days)

**Daily Checks:**
- [ ] Customer app service browsing works
- [ ] Technician app add service works
- [ ] Booking creation works
- [ ] Matching function works
- [ ] No errors in Cloud Functions logs

**Firebase Console Monitoring:**
- Check `categories` collection usage
- Check `services` collection usage
- Verify `technician_categories` NOT being accessed
- Verify `technician_subcategories` NOT being accessed

---

### PHASE 6️⃣: ARCHIVE LEGACY (After 7 Days Stable)

```powershell
cd C:\Users\yash\projects\homefix\scripts
node archive_legacy_collections.js
```

**This will:**
- Move `technician_categories` → `_archived_technician_categories`
- Move `technician_subcategories` → `_archived_technician_subcategories`
- Delete original collections

---

### PHASE 7️⃣: PERMANENT DELETION (After 30 Days)

**Manual deletion in Firebase Console:**
1. Navigate to Firestore Database
2. Delete `_archived_technician_categories` collection
3. Delete `_archived_technician_subcategories` collection
4. Delete `_archived_old_categories` collection (if exists)

---

## 🔧 TROUBLESHOOTING

### Error: "Service account key not found"
**Solution:** Place `serviceAccountKey.json` in project root

### Error: "Permission denied"
**Solution:** Ensure service account has Firestore Admin role

### Error: "Orphan services found"
**Solution:** Check categoryId values, may need manual fix

### Migration completed but app not loading data
**Solution:** 
1. Check app is fetching from `collection('categories')` not `collection('technician_categories')`
2. Verify Firestore indexes are deployed
3. Clear app cache and restart

---

## 📊 EXPECTED RESULTS

| Metric | Before | After |
|--------|--------|-------|
| `categories` count | 0 or few | 40+ |
| `services` count | varies | 200+ |
| `technician_categories` | 40+ | 40+ (unchanged) |
| `technician_subcategories` | 200+ | 200+ (unchanged) |

**After 7 days:**
| Collection | Status |
|------------|--------|
| `categories` | ✅ ACTIVE |
| `services` | ✅ ACTIVE |
| `technician_categories` | 🗄️ ARCHIVED |
| `technician_subcategories` | 🗄️ ARCHIVED |

---

## 📞 SUPPORT

**Issues?** Contact: 9508322397

**Logs Location:**
- Cloud Functions: Firebase Console → Functions → Logs
- App Logs: Android Studio Logcat

---

## ✅ POST-MIGRATION CHECKLIST

- [ ] Migration script executed successfully
- [ ] Categories count ≥ 40
- [ ] Services count ≥ 200
- [ ] No orphan services
- [ ] Customer app tested
- [ ] Technician app tested
- [ ] Booking flow tested
- [ ] 7-day monitoring period completed
- [ ] Legacy collections archived
- [ ] 30-day grace period completed
- [ ] Permanent deletion completed

---

**Migration Date:** _____________
**Executed By:** _____________
**Status:** _____________
