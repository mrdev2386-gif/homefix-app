# 🔍 TECHNICIAN KYC PIPELINE - COMPLETE AUDIT & FIX

## 🚨 EXECUTIVE SUMMARY

**Status**: ⚠️ **CRITICAL ISSUES FOUND**

The technician KYC verification pipeline has **MULTIPLE BREAKING POINTS** that prevent proper admin approval flow:

1. ❌ **Admin Panel queries WRONG fields** (looking for old field names)
2. ❌ **Approval function uses WRONG field names** (doesn't set required flags)
3. ❌ **Field name mismatch** between Cloud Function and Admin Panel
4. ⚠️ **Missing documents in admin detail view**
5. ⚠️ **Technician app may not detect approval properly**

---

## 📊 END-TO-END FLOW ANALYSIS

### ✅ STEP 1: Technician Submits KYC (WORKING)

**File**: `functions/src/technician/onboarding.ts` → `submitTechnicianKyc`

```typescript
await db.collection('technicians').doc(uid).set({
    isKycComplete: true,           // ✅ CORRECT
    onboardingCompleted: true,     // ✅ CORRECT
    onboardingStep: 'submitted',   // ✅ CORRECT
    status: 'pending',             // ✅ CORRECT
    kycStatus: 'pending',          // ✅ CORRECT
    submittedAt: FieldValue.serverTimestamp()
}, { merge: true });
```

**Result**: ✅ Technician document correctly marked as pending KYC

---

### ❌ STEP 2: Admin Panel Query (BROKEN)

**File**: `apps/admin_panel/src/app/(admin)/technicians/page.tsx`

**Current Query** (via `admin_getTechnicians`):
```typescript
// functions/src/admin/technicians.ts
let query: admin.firestore.Query = db.collection('technicians');

if (status) {
    query = query.where('status', '==', status);  // ✅ This works
}
```

**Problem**: Admin panel filters by `status: 'pending'` which SHOULD work, but:

1. No explicit filter for `isKycComplete: true` to show only submitted KYC
2. Query returns ALL pending technicians (even those who haven't submitted)

**FIX NEEDED**: Add KYC completion filter

---

### ❌ STEP 3: Admin Approval Function (CRITICALLY BROKEN)

**File**: `functions/src/admin/technicians.ts` → `approveTechnician`

**Current Code**:
```typescript
await techRef.update({
    status: approve ? 'approved' : 'suspended',  // ✅ Sets status
    isVerified: approve,                         // ❌ WRONG FIELD!
    rejectionReason: !approve ? reason : FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp()
});
```

**CRITICAL BUGS**:
1. ❌ Sets `isVerified` instead of `isApproved` (technician app checks `isApproved`)
2. ❌ Does NOT set `adminApproved: true` (required by technician app)
3. ❌ Does NOT set `kycStatus: 'approved'` (inconsistent state)
4. ❌ Does NOT set `isActive: true` (technician can't go online)

**Technician App Expects** (from `technician_provider.dart`):
```dart
_isApproved = tech.isApproved;           // ❌ NOT SET BY ADMIN
_isAdminApproved = tech.adminApproved;   // ❌ NOT SET BY ADMIN
```

**Result**: 🔥 **TECHNICIAN NEVER GETS ACTIVATED**

---

### ❌ STEP 4: Admin Detail View (BROKEN)

**File**: `apps/admin_panel/src/app/(admin)/technicians/[id]/page.tsx`

**Current Code**:
```typescript
// Fetch application documents if available
const appDoc = await db.collection('technician_applications').doc(techId).get();
const documents = appDoc.exists ? appDoc.data()?.documents : null;
```

**CRITICAL BUG**: 
- Looks for `technician_applications` collection
- But KYC documents are stored in `technicians` collection with fields:
  - `aadhaarFrontUrl`
  - `aadhaarBackUrl`
  - `profilePhotoUrl`

**Result**: ❌ **ADMIN CANNOT SEE KYC DOCUMENTS**

---

### ⚠️ STEP 5: Technician App Detection (PARTIAL)

**File**: `apps/technician_app/lib/core/providers/technician_provider.dart`

**Current Code**:
```dart
_isApproved = tech.isApproved;
_isAdminApproved = tech.adminApproved;
```

**Status**: ✅ Code is correct, BUT admin function doesn't set these fields!

---

## 🔧 COMPLETE FIX IMPLEMENTATION

### FIX 1: Admin Approval Function (CRITICAL)

**File**: `functions/src/admin/technicians.ts`

**Replace** the `approveTechnician` function:

```typescript
export const approveTechnician = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { techId, approve, reason } = data;

        if (!techId) throw new functions.https.HttpsError('invalid-argument', 'Missing techId');

        const techRef = db.collection('technicians').doc(techId);
        const techDoc = await techRef.get();
        if (!techDoc.exists) throw new functions.https.HttpsError('not-found', 'Technician not found');

        console.log('[ADMIN APPROVAL] Processing approval for:', techId, 'approve:', approve);

        if (approve) {
            // APPROVE: Set ALL required fields for technician activation
            await techRef.update({
                // Primary approval flags
                isApproved: true,              // ✅ Required by technician app
                adminApproved: true,           // ✅ Required by technician app
                isVerified: true,              // ✅ Legacy compatibility
                
                // Status fields
                status: 'approved',            // ✅ Main status
                kycStatus: 'approved',         // ✅ KYC-specific status
                
                // Activation
                isActive: true,                // ✅ Allow going online
                
                // Metadata
                approvedAt: admin.firestore.FieldValue.serverTimestamp(),
                approvedBy: context.auth!.uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                
                // Clear rejection fields
                rejectionReason: admin.firestore.FieldValue.delete()
            });

            console.log('[ADMIN APPROVAL] ✅ Technician approved and activated:', techId);
        } else {
            // REJECT/SUSPEND: Clear approval flags
            await techRef.update({
                status: 'suspended',
                isApproved: false,
                adminApproved: false,
                isVerified: false,
                isActive: false,
                isOnline: false,               // Force offline
                kycStatus: 'rejected',
                rejectionReason: reason || 'Not specified',
                rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
                rejectedBy: context.auth!.uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            console.log('[ADMIN APPROVAL] ❌ Technician suspended:', techId);
        }

        await logAdminAction(context.auth!.uid, approve ? 'tech_approve' : 'tech_suspend', techId, { reason });
        return { success: true };
    } catch (error: any) {
        console.error('[Technician] Error in approveTechnician:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to update technician status');
    }
});
```

---

### FIX 2: Admin Panel - Show KYC Documents

**File**: `functions/src/admin/technicians.ts` → `getTechnicianById`

**Replace** the documents fetching section:

```typescript
export const getTechnicianById = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { techId } = data;
        if (!techId) throw new functions.https.HttpsError('invalid-argument', 'Missing techId');

        const techDoc = await db.collection('technicians').doc(techId).get();
        if (!techDoc.exists) throw new functions.https.HttpsError('not-found', 'Technician not found');

        const techData = techDoc.data()!;

        // Fetch wallet & earnings
        const walletDoc = await db.collection('wallets').doc(techId).get();
        const wallet = walletDoc.exists ? walletDoc.data() : { balance: 0, pendingBalance: 0 };

        // Fetch job history (last 5)
        const jobsSnap = await db.collection('bookings')
            .where('assignedTechnicianId', '==', techId)
            .orderBy('createdAt', 'desc')
            .limit(5)
            .get();
        const jobHistory = jobsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        // ✅ FIX: Extract KYC documents from technician document itself
        const documents: Record<string, string> = {};
        if (techData.aadhaarFrontUrl) {
            documents['Aadhaar Front'] = techData.aadhaarFrontUrl;
        }
        if (techData.aadhaarBackUrl) {
            documents['Aadhaar Back'] = techData.aadhaarBackUrl;
        }
        if (techData.profilePhotoUrl) {
            documents['Profile Photo'] = techData.profilePhotoUrl;
        }

        // Fetch ratings & reviews (last 5)
        const reviewsSnap = await db.collection('reviews')
            .where('technicianId', '==', techId)
            .orderBy('createdAt', 'desc')
            .limit(5)
            .get();
        const reviews = reviewsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        console.log('[ADMIN PIPELINE] Loaded technician details with', Object.keys(documents).length, 'documents');

        return {
            ...techData,
            wallet,
            jobHistory,
            documents,  // ✅ Now contains actual KYC documents
            reviews
        };
    } catch (error: any) {
        console.error('[Admin Techs] Error in getTechnicianById:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to fetch technician details');
    }
});
```

---

### FIX 3: Admin Panel - Filter Pending KYC

**File**: `functions/src/admin/technicians.ts` → `getTechnicians`

**Add** KYC filter option:

```typescript
export const getTechnicians = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);
        const { limit = 10, offset = 0, status, search, city, kycPending } = data;

        let query: admin.firestore.Query = db.collection('technicians');

        // ✅ NEW: Filter for pending KYC submissions
        if (kycPending === true) {
            query = query
                .where('isKycComplete', '==', true)
                .where('kycStatus', '==', 'pending');
        } else if (status) {
            query = query.where('status', '==', status);
        }

        if (city) {
            query = query.where('city', '==', city);
        }

        const snapshot = await query.orderBy('createdAt', 'desc').get();
        let techs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        if (search) {
            const lowerSearch = search.toLowerCase();
            techs = techs.filter((t: any) =>
                t.name?.toLowerCase().includes(lowerSearch) ||
                t.fullName?.toLowerCase().includes(lowerSearch) ||
                t.email?.toLowerCase().includes(lowerSearch) ||
                t.phone?.includes(search) ||
                t.id.includes(search)
            );
        }

        const total = techs.length;
        const paginatedTechs = techs.slice(offset, offset + limit);

        console.log('[ADMIN PIPELINE] Loaded', paginatedTechs.length, 'technicians (total:', total, ')');

        return {
            techs: paginatedTechs,
            total,
            limit,
            offset
        };
    } catch (error: any) {
        console.error('[Admin Techs] Error in getTechnicians:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', error.message || 'Failed to fetch technicians');
    }
});
```

---

### FIX 4: Admin Panel UI - Add Pending KYC Tab

**File**: `apps/admin_panel/src/app/(admin)/technicians/page.tsx`

**Add** a filter button for pending KYC:

```typescript
// Add state
const [showPendingKyc, setShowPendingKyc] = useState(false);

// Update fetchTechs
const fetchTechs = useCallback(async () => {
    setLoading(true);
    try {
        const data = await adminApi.getTechnicians({
            limit,
            offset: (page - 1) * limit,
            search: searchTerm,
            status: statusFilter || undefined,
            city: cityFilter || undefined,
            kycPending: showPendingKyc || undefined  // ✅ NEW
        });
        setTechs(data.techs);
        setTotal(data.total);
    } catch (e) {
        console.error('Failed to fetch technicians:', e);
    } finally {
        setLoading(false);
    }
}, [page, limit, searchTerm, statusFilter, cityFilter, showPendingKyc]);

// Add button in UI (before status filter)
<Button
    variant={showPendingKyc ? "default" : "outline"}
    size="sm"
    onClick={() => setShowPendingKyc(!showPendingKyc)}
    className="h-12 rounded-xl font-black uppercase tracking-widest text-[10px]"
>
    {showPendingKyc ? '✅ Showing Pending KYC' : '📋 Show Pending KYC'}
</Button>
```

---

### FIX 5: Add Debug Logging

**File**: `apps/technician_app/lib/core/providers/technician_provider.dart`

**Add** approval detection logging:

```dart
void _listenToTechnicianData(String uid) {
    // ... existing code ...
    
    _techSubscription = _techService.getTechnicianStream(uid).listen((tech) {
        // ... existing code ...
        
        if (tech != null) {
            // ✅ ADD: Debug log for approval detection
            debugPrint('[ADMIN PIPELINE] Approval detected: ${tech.isApproved}');
            debugPrint('[ADMIN PIPELINE] Admin approved: ${tech.adminApproved}');
            debugPrint('[ADMIN PIPELINE] Status: ${tech.status}');
            debugPrint('[ADMIN PIPELINE] KYC Status: ${tech.kycStatus}');
            
            // ... rest of existing code ...
        }
    });
}
```

---

## 🧪 TESTING CHECKLIST

### Test 1: KYC Submission
- [ ] Technician completes all onboarding steps
- [ ] Clicks "Submit for Review"
- [ ] Check Firestore: `isKycComplete: true`, `kycStatus: 'pending'`
- [ ] Check logs: `[KYC SUBMIT] Successfully marked KYC complete`

### Test 2: Admin Panel Visibility
- [ ] Admin logs into panel
- [ ] Clicks "Show Pending KYC" button
- [ ] Technician appears in list
- [ ] Click technician name to view details
- [ ] Verify KYC documents are visible (Aadhaar front/back, photo)

### Test 3: Admin Approval
- [ ] Admin clicks "Activate Asset" button
- [ ] Check Firestore after approval:
  ```
  isApproved: true
  adminApproved: true
  status: 'approved'
  kycStatus: 'approved'
  isActive: true
  approvedAt: <timestamp>
  ```
- [ ] Check Cloud Function logs: `[ADMIN APPROVAL] ✅ Technician approved`

### Test 4: Technician App Detection
- [ ] Technician app should automatically detect approval
- [ ] Check logs: `[ADMIN PIPELINE] Approval detected: true`
- [ ] Pending review screen should disappear
- [ ] Dashboard should unlock
- [ ] Technician can toggle online/offline

### Test 5: End-to-End Flow
- [ ] Complete flow from submission to activation takes < 2 minutes
- [ ] No manual refresh required
- [ ] Real-time updates work correctly

---

## 🚀 DEPLOYMENT STEPS

### Step 1: Deploy Cloud Functions
```bash
cd c:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions:admin_approveTechnician,functions:admin_getTechnicians,functions:admin_getTechnicianById
```

### Step 2: Verify Deployment
```bash
firebase functions:log --only admin_approveTechnician
```

### Step 3: Test with Real Data
1. Use existing pending technician OR
2. Create new test technician account
3. Complete KYC submission
4. Approve via admin panel
5. Verify activation in technician app

---

## 📊 FIELD MAPPING REFERENCE

### Technician Document Fields (Firestore)

| Field | Type | Set By | Purpose |
|-------|------|--------|---------|
| `isKycComplete` | boolean | Cloud Function (submit) | KYC submitted |
| `kycStatus` | string | Cloud Function | 'pending' → 'approved' |
| `status` | string | Cloud Function | 'pending' → 'approved' |
| `isApproved` | boolean | Admin Function | ✅ REQUIRED for app |
| `adminApproved` | boolean | Admin Function | ✅ REQUIRED for app |
| `isActive` | boolean | Admin Function | Can go online |
| `isVerified` | boolean | Admin Function | Legacy field |
| `aadhaarFrontUrl` | string | Technician (upload) | KYC document |
| `aadhaarBackUrl` | string | Technician (upload) | KYC document |
| `profilePhotoUrl` | string | Technician (upload) | KYC document |

---

## ⚠️ CRITICAL NOTES

1. **DO NOT** use `technician_applications` collection - it's legacy
2. **ALWAYS** set both `isApproved` AND `adminApproved` on approval
3. **ALWAYS** set `isActive: true` when approving
4. **ALWAYS** check logs after deployment
5. **TEST** with real device, not just emulator

---

## 🎯 SUCCESS METRICS

After fixes are deployed:

✅ Admin can see pending KYC submissions
✅ Admin can view all KYC documents
✅ Admin approval activates technician immediately
✅ Technician app detects approval without refresh
✅ Technician can go online after approval
✅ No manual intervention required

---

## 📞 SUPPORT

If issues persist after applying fixes:
1. Check Cloud Function logs: `firebase functions:log`
2. Check Firestore document structure
3. Verify admin has proper permissions
4. Test with fresh technician account

**Contact**: 9508322397
