# ⚡ ADMIN PANEL NOT SHOWING SERVICES - QUICK FIX

## 🎯 QUICK DIAGNOSIS

### Step 1: Run Diagnostic (30 seconds)
```powershell
cd C:\Users\yash\projects\homefix\scripts
node diagnose_admin_panel_fetch.js
```

### Step 2: Check Output

#### Output A: "No pending services"
**Cause**: All services approved or no services exist  
**Fix**: Create test service from technician app

#### Output B: "X services missing status field"
**Cause**: Old services without status field  
**Fix**: Run migration
```powershell
node normalize_service_status.js
```

#### Output C: "Index error"
**Cause**: Firestore index missing  
**Fix**: Deploy indexes
```powershell
cd C:\Users\yash\projects\homefix
firebase deploy --only firestore:indexes
```

#### Output D: "X pending services found"
**Cause**: Admin panel config issue  
**Fix**: Check browser console for errors

---

## 🔍 BROWSER CONSOLE CHECK

1. Open admin panel
2. Press F12 (Developer Tools)
3. Go to Console tab
4. Look for `[ADMIN PANEL]` logs

### Expected Logs:
```
[ADMIN PANEL] Setting up service approvals listener...
[ADMIN PANEL] Snapshot received
[ADMIN PANEL] Total documents: 2
[ADMIN PANEL] Doc 1: abc123 {...}
```

### If No Logs:
- Check Firebase config in `apps/admin_panel/src/lib/firebase.ts`
- Verify project ID matches production

### If Error Logs:
- Check error message
- Verify Firestore rules allow admin read

---

## ✅ QUICK FIXES

### Fix 1: Missing Status Field
```powershell
cd C:\Users\yash\projects\homefix\scripts
node normalize_service_status.js
```

### Fix 2: Create Test Service
1. Open technician app
2. Create new service
3. Check admin panel

### Fix 3: Deploy Indexes
```powershell
firebase deploy --only firestore:indexes
```

### Fix 4: Rebuild Admin Panel
```powershell
cd C:\Users\yash\projects\homefix\apps\admin_panel
npm run build
firebase deploy --only hosting
```

---

## 📊 VERIFICATION

Admin panel working when:
- ✅ Browser console shows `[ADMIN PANEL]` logs
- ✅ Console shows documents being fetched
- ✅ Pending services appear in table
- ✅ Can approve/reject services

---

**Status**: ✅ DEBUG TOOLS READY
