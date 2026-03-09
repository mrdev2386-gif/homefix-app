# ⚡ SERVICE MODERATION - QUICK REFERENCE

## 🎯 CORRECT WORKFLOW

```
Technician Creates Service
         ↓
status: 'pending'
isActive: false
         ↓
Admin Panel Shows Service
         ↓
Admin Approves
         ↓
status: 'approved'
isActive: true
         ↓
Customer App Shows Service
```

---

## 🔧 QUICK DEPLOY

```powershell
# 1. Deploy Functions
cd C:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions

# 2. Run Migration
cd C:\Users\yash\projects\homefix\scripts
node normalize_service_status.js

# 3. Verify
node verify_service_moderation.js

# 4. Update Apps
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter build apk --release

cd C:\Users\yash\projects\homefix\apps\admin_panel
npm run build
firebase deploy --only hosting
```

---

## 📋 QUICK TEST

### Test Service Creation
1. Technician creates service
2. Check Firestore: `status: 'pending'`, `isActive: false`
3. Verify NOT in customer app
4. Verify IS in admin panel

### Test Admin Approval
1. Admin approves service
2. Check Firestore: `status: 'approved'`, `isActive: true`
3. Verify IS in customer app

---

## 🔍 QUICK VERIFY

```javascript
// Check in Firestore Console
// Collection: technician_services

// Pending Service (CORRECT):
{
  status: 'pending',
  isActive: false,
  isDeleted: false
}

// Approved Service (CORRECT):
{
  status: 'approved',
  isActive: true,
  isDeleted: false
}
```

---

## 🚨 QUICK TROUBLESHOOT

### Issue: Services not showing in admin panel
**Fix**: Check query uses `where('status', '==', 'pending')`

### Issue: Services showing in customer app before approval
**Fix**: Check query uses `where('status', '==', 'approved')` AND `where('isActive', '==', true)`

### Issue: Approved services not showing in customer app
**Fix**: Verify admin approval sets `isActive: true`

---

## 📁 KEY FILES

1. **Service Creation**: `functions/src/technician/services_management.ts` (Line 199)
2. **Admin Approval**: `functions/src/admin/service_management.ts` (Line 74)
3. **Customer Query**: `apps/customer_app/lib/features/services/presentation/category_technicians_screen.dart` (Line 46)
4. **Admin Query**: `apps/admin_panel/src/app/(admin)/service-approvals/page.tsx` (Line 56)

---

## ✅ SUCCESS CHECKLIST

- [ ] Functions deployed
- [ ] Migration run
- [ ] Verification passed
- [ ] New services have `status: 'pending'`
- [ ] Admin panel shows pending services
- [ ] Customer app shows only approved services
- [ ] All tests pass

---

**Status**: ✅ READY TO DEPLOY
