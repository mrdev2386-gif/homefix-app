# 🚀 SERVICE MODERATION FIX - DEPLOYMENT CHECKLIST

## ✅ PRE-DEPLOYMENT VERIFICATION

### 1. Verify Code Changes
- [x] `functions/src/technician/services_management.ts` - Service creation sets `status: 'pending'` and `isActive: false`
- [x] `functions/src/admin/service_management.ts` - Admin approval sets `isActive: true`
- [x] `apps/customer_app/lib/features/services/presentation/category_technicians_screen.dart` - Queries only approved services
- [x] `apps/admin_panel/src/app/(admin)/service-approvals/page.tsx` - Queries pending services and sets isActive on approval

### 2. Run Verification Script
```powershell
cd C:\Users\yash\projects\homefix\scripts
node verify_service_moderation.js
```

**Expected Output**: Should show current state of services and any issues

---

## 🔧 DEPLOYMENT STEPS

### STEP 1: Deploy Cloud Functions (CRITICAL)

```powershell
cd C:\Users\yash\projects\homefix\functions

# Build TypeScript
npm run build

# Deploy service management functions
firebase deploy --only functions:addTechnicianService,functions:updateTechnicianService,functions:admin_approveService,functions:admin_rejectService,functions:admin_disableService

# Verify deployment
firebase functions:log --only addTechnicianService --limit 5
```

**Verification**:
- [ ] Functions deployed successfully
- [ ] No errors in deployment logs
- [ ] Functions are callable

---

### STEP 2: Run Data Migration (CRITICAL)

```powershell
cd C:\Users\yash\projects\homefix\scripts

# Run migration to fix existing services
node normalize_service_status.js
```

**Expected Output**:
```
📊 Found X services to check
⚠️  Service XXX: Missing status → Setting to 'pending'
✅ Committed batch of X updates
📊 MIGRATION SUMMARY
Total services checked: X
Services updated: X
Services already correct: X
✅ Migration completed successfully!
```

**Verification**:
- [ ] Migration completed without errors
- [ ] All services now have `status` field
- [ ] All services now have `isActive` field
- [ ] Pending services have `isActive: false`
- [ ] Approved services have `isActive: true`

---

### STEP 3: Verify Migration Success

```powershell
cd C:\Users\yash\projects\homefix\scripts

# Run verification script
node verify_service_moderation.js
```

**Expected Output**:
```
✅ VERIFICATION PASSED - All services are correctly configured!
✅ Service moderation workflow is correctly configured!
```

**Verification**:
- [ ] No missing status fields
- [ ] No missing isActive fields
- [ ] No pending services with isActive=true
- [ ] No approved services with isActive=false

---

### STEP 4: Update Customer App

```powershell
cd C:\Users\yash\projects\homefix\apps\customer_app

# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Or build for specific platform
flutter build ios --release  # For iOS
```

**Verification**:
- [ ] App builds successfully
- [ ] No compilation errors
- [ ] Service query updated to check `status == 'approved'`

---

### STEP 5: Update Admin Panel

```powershell
cd C:\Users\yash\projects\homefix\apps\admin_panel

# Install dependencies (if needed)
npm install

# Build production
npm run build

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

**Verification**:
- [ ] Admin panel builds successfully
- [ ] Deployment successful
- [ ] Admin panel accessible at production URL

---

## 🧪 POST-DEPLOYMENT TESTING

### Test 1: Service Creation Flow
1. [ ] Login as technician (approved profile)
2. [ ] Create a new service
3. [ ] Verify in Firestore:
   - `status: 'pending'`
   - `isActive: false`
   - `isDeleted: false`
4. [ ] Verify service NOT visible in customer app
5. [ ] Verify service IS visible in admin panel (pending list)

### Test 2: Admin Approval Flow
1. [ ] Login to admin panel
2. [ ] Navigate to Service Approvals
3. [ ] Verify pending service appears in list
4. [ ] Click "Approve" on the service
5. [ ] Verify in Firestore:
   - `status: 'approved'`
   - `isActive: true`
   - `approvedAt: <timestamp>`
   - `approvedBy: <admin_id>`
6. [ ] Verify service IS visible in customer app
7. [ ] Verify service removed from pending list in admin panel

### Test 3: Admin Rejection Flow
1. [ ] Create another test service as technician
2. [ ] Login to admin panel
3. [ ] Click "Reject" on the service
4. [ ] Verify in Firestore:
   - `status: 'rejected'`
   - `isActive: false`
   - `rejectedAt: <timestamp>`
   - `rejectionReason: <reason>`
5. [ ] Verify service NOT visible in customer app
6. [ ] Verify service removed from pending list

### Test 4: Customer App Query
1. [ ] Open customer app
2. [ ] Navigate to services listing
3. [ ] Verify ONLY approved services are shown
4. [ ] Verify pending services are NOT shown
5. [ ] Verify rejected services are NOT shown
6. [ ] Verify deleted services are NOT shown

### Test 5: Security Validation
1. [ ] Try to update service status directly from technician app (should fail)
2. [ ] Try to set `isActive: true` from technician app (should fail)
3. [ ] Verify Firestore rules prevent status manipulation
4. [ ] Verify only admins can approve/reject services

---

## 📊 MONITORING

### Metrics to Watch (First 24 Hours)

1. **Cloud Functions**
   - Monitor `addTechnicianService` execution count
   - Monitor `admin_approveService` execution count
   - Check for any function errors

2. **Firestore**
   - Monitor read/write operations
   - Check for any security rule violations
   - Verify no unauthorized status changes

3. **Customer App**
   - Monitor service listing queries
   - Check for any query errors
   - Verify correct services are displayed

4. **Admin Panel**
   - Monitor pending services count
   - Check approval/rejection success rate
   - Verify no UI errors

---

## 🚨 ROLLBACK PLAN

If critical issues occur:

### Rollback Cloud Functions
```powershell
# List recent deployments
firebase functions:log

# Rollback to previous version (if needed)
# Note: Firebase doesn't support automatic rollback
# You'll need to redeploy previous code
```

### Rollback Data Migration
```powershell
# If migration caused issues, manually revert in Firestore Console
# Or restore from Firestore backup
gcloud firestore import gs://homefix-backups/daily/YYYY-MM-DD
```

---

## ✅ SUCCESS CRITERIA

Deployment is successful when:

1. ✅ All Cloud Functions deployed without errors
2. ✅ Data migration completed successfully
3. ✅ Verification script passes all checks
4. ✅ New services created with `status: 'pending'` and `isActive: false`
5. ✅ Admin panel shows pending services
6. ✅ Admin approval sets `status: 'approved'` and `isActive: true`
7. ✅ Customer app shows only approved services
8. ✅ No security rule violations
9. ✅ No function execution errors
10. ✅ All post-deployment tests pass

---

## 📞 SUPPORT CONTACTS

**Critical Issues**: 9508322397  
**DevOps Team**: [Contact Info]  
**Firebase Support**: Enterprise Support Plan

---

## 📝 DEPLOYMENT LOG

| Date | Time | Action | Status | Notes |
|------|------|--------|--------|-------|
| YYYY-MM-DD | HH:MM | Cloud Functions Deployed | ⏳ Pending | |
| YYYY-MM-DD | HH:MM | Data Migration Run | ⏳ Pending | |
| YYYY-MM-DD | HH:MM | Verification Passed | ⏳ Pending | |
| YYYY-MM-DD | HH:MM | Customer App Updated | ⏳ Pending | |
| YYYY-MM-DD | HH:MM | Admin Panel Updated | ⏳ Pending | |
| YYYY-MM-DD | HH:MM | Testing Completed | ⏳ Pending | |

---

**Deployment Prepared By**: Amazon Q Developer  
**Date**: 2026-01-XX  
**Status**: ✅ READY FOR DEPLOYMENT
