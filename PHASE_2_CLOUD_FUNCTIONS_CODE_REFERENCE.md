# Phase 2 - Cloud Functions Code Reference

This document provides the exact code structure and important sections of the new/modified Cloud Functions.

---

## 1. Auth Trigger: `functions/src/technician/auth.ts`

**Purpose:** Automatically create minimal technician document when Firebase Auth user is created

**Key Sections:**

### Imports
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
```

### Function Definition
```typescript
export const createTechnicianOnAuthCreate = functions.auth
  .user()
  .onCreate(async (user: admin.auth.UserRecord) => {
    // Triggered when Firebase Auth user created
  });
```

### Idempotency Check
```typescript
const uid = user.uid;
const db = admin.firestore();

// Check if document already exists (idempotent)
const existingDoc = await db.collection('technicians').doc(uid).get();
if (existingDoc.exists) {
  console.log(`[Auth Trigger] Technician doc already exists for ${uid}`);
  return; // Skip if already created
}
```

### Minimal Document Structure
```typescript
const minimalTechnicianDoc = {
  uid: uid,
  phone: user.phoneNumber || '',
  email: user.email || '',
  name: user.displayName || 'Technician',
  
  // Onboarding flags
  onboardingCompleted: false,
  onboardingStep: 'phone',
  
  // KYC flags
  isKycComplete: false,
  
  // Profile flags
  isApproved: false,
  adminApproved: false,
  
  // System fields
  role: 'technician',
  status: 'active',
  isOnline: false,
  isVerified: false,
  
  // Timestamps (server-generated)
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
};
```

### Document Creation
```typescript
await db.collection('technicians').doc(uid).set(minimalTechnicianDoc, {
  merge: true, // Merge with existing doc if any (extra safety)
});
```

### Audit Logging
```typescript
await db.collection('audit_logs').add({
  action: 'technician_auto_created_on_auth',
  uid: uid,
  email: user.email,
  phone: user.phoneNumber,
  timestamp: admin.firestore.FieldValue.serverTimestamp(),
  source: 'auth_trigger',
});
```

### Error Handling
```typescript
try {
  // ... creation logic ...
} catch (error) {
  console.error(`[Auth Trigger] Error creating technician: ${error}`);
  // Non-fatal - don't throw, auth is more important than doc creation
  // Client will handle missing doc gracefully
}
```

---

## 2. KYC Functions: `functions/src/technician/kyc.ts`

### Imports
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v1/https';
import { Timestamp } from 'firebase-admin/firestore';
```

### Interface Definition
```typescript
interface KycChecklist {
  fullName: boolean;
  phone: boolean;
  city: boolean;
  experience: boolean;
  profilePhoto: boolean;
  aadhaarNumber: boolean;
  aadhaarFrontUrl: boolean;
  aadhaarBackUrl: boolean;
  services: boolean;
  bankDetails: boolean;
}

interface KycEvaluationResult {
  success: boolean;
  isKycComplete: boolean;
  checklist: KycChecklist;
  evaluatedAt?: Timestamp;
}
```

### Function 2A: `evaluateTechnicianKyc`

**Purpose:** Evaluate KYC completion based on 10 required fields, update isKycComplete

```typescript
export const evaluateTechnicianKyc = functions.https.onCall<
  {},
  KycEvaluationResult
>(async (data: {}, context: functions.https.CallableContext) => {
  // Authentication check
  if (!context.auth) {
    throw new HttpsError(
      'unauthenticated',
      'User must be authenticated to evaluate KYC'
    );
  }

  const uid = context.auth.uid;
  const db = admin.firestore();

  // Fetch technician document
  const techDoc = await db.collection('technicians').doc(uid).get();
  const techData = techDoc.data();

  if (!techData) {
    throw new HttpsError('not-found', 'Technician document not found');
  }

  // Build KYC checklist
  const kycChecklist: KycChecklist = {
    fullName: !!techData.fullName && techData.fullName.trim().length >= 3,
    phone: !!techData.phone && techData.phone.length >= 10,
    city: !!techData.city && techData.city.trim().length > 0,
    experience: typeof techData.experienceYears === 'number' && techData.experienceYears >= 0,
    profilePhoto: !!techData.profilePhotoUrl,
    aadhaarNumber: !!techData.aadhaarNumber && techData.aadhaarNumber.length === 12,
    aadhaarFrontUrl: !!techData.aadhaarFrontUrl,
    aadhaarBackUrl: !!techData.aadhaarBackUrl,
    services: Array.isArray(techData.services) && techData.services.length > 0,
    bankDetails: !!techData.bankDetails && typeof techData.bankDetails === 'object',
  };

  // Determine if complete (all checks must pass)
  const isKycComplete = Object.values(kycChecklist).every(val => val === true);

  // Update technician document with KYC status
  // Only this Cloud Function can set isKycComplete (blocked in Firestore rules)
  await db.collection('technicians').doc(uid).update({
    isKycComplete: isKycComplete,
    _kycChecklist: kycChecklist,
    _kycEvaluatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Audit log
  await db.collection('audit_logs').add({
    action: 'kyc_evaluated',
    uid: uid,
    isKycComplete: isKycComplete,
    checklist: kycChecklist,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    isKycComplete: isKycComplete,
    checklist: kycChecklist,
    evaluatedAt: admin.firestore.Timestamp.now(),
  };
});
```

### Token Validation Helper
```typescript
// Optional: Validate token freshness
const tenMinutesAgo = Math.floor(Date.now() / 1000) - 600;
if (context.auth.token.iat < tenMinutesAgo) {
  throw new HttpsError('unauthenticated', 'Token too old - please refresh and retry');
}
```

### Function 2B: `checkKycStatus`

**Purpose:** Read-only check of current KYC status without re-evaluation

```typescript
export const checkKycStatus = functions.https.onCall<
  {},
  { isKycComplete: boolean; evaluatedAt?: Timestamp }
>(async (data: {}, context: functions.https.CallableContext) => {
  // Authentication check
  if (!context.auth) {
    throw new HttpsError(
      'unauthenticated',
      'User must be authenticated to check KYC status'
    );
  }

  const uid = context.auth.uid;
  const db = admin.firestore();

  // Fetch technician document
  const techDoc = await db.collection('technicians').doc(uid).get();
  const techData = techDoc.data();

  if (!techData) {
    throw new HttpsError('not-found', 'Technician document not found');
  }

  return {
    isKycComplete: techData.isKycComplete || false,
    evaluatedAt: techData._kycEvaluatedAt || null,
  };
});
```

### Error Handling Pattern
```typescript
try {
  // ... function logic ...
} on FirebaseError catch (error) {
  throw new HttpsError(
    'internal',
    `Firebase error: ${error.message}`
  );
} on Exception catch (error) {
  throw new HttpsError(
    'unknown',
    `Unexpected error: ${error.toString()}`
  );
}
```

---

## 3. Integration: `functions/src/index.ts`

### Required Imports
```typescript
// At top of file, around line 40-45
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as techAuth from './technician/auth';
import * as techKyc from './technician/kyc';
import * as express from 'express';
```

### Export Auth Trigger
```typescript
// Around line 605-612
export const onUserCreated = techAuth.createTechnicianOnAuthCreate;
```

### Export KYC Functions
```typescript
// Around line 625-640
export const evaluateTechnicianKyc = techKyc.evaluateTechnicianKyc;
export const checkKycStatus = techKyc.checkKycStatus;
```

---

## 4. Firestore Rules: `firestore_hardened_final.rules`

### Technician Collection Rules

```plaintext
match /technicians/{technicianId} {
  // Helper function to check ownership
  function isOwner(uid) {
    return request.auth.uid == uid;
  }

  // CREATE: Only Auth trigger creates (disabled for client)
  allow create: if false;

  // READ: Owner can read their own doc
  allow read: if isOwner(technicianId);

  // UPDATE: Owner can update, but cannot modify sensitive fields
  allow update: if isOwner(technicianId) && (
    !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny([
        // KYC and Approval fields (backend-only)
        'isKycComplete',
        'onboardingCompleted',
        'isApproved',
        'adminApproved',
        
        // System fields (immutable)
        'role',
        'createdAt',
        'updatedAt',
        'status',
        
        // Financial fields (backend-only)
        'walletBalance',
        'totalEarnings',
        'pendingEarnings',
        
        // Metrics (backend-calculated)
        'rating',
        'avgRating',
        'totalRatings',
        'jobsDone',
        'jobsCompleted',
        
        // Audit fields (backend-only)
        '_kycChecklist',
        '_kycEvaluatedAt'
      ])
  );

  // DELETE: Nobody can delete
  allow delete: if false;

  // Subcollections are inherited by parent rules
}
```

---

## Testing the Cloud Functions Locally

### 1. Start Emulator
```bash
firebase emulators:start
```

### 2. Test with cURL

**Create Auth User:**
```bash
curl -X POST http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "returnSecureToken": true
  }'
```

**Call evaluateTechnicianKyc:**
```bash
curl -X POST http://localhost:5001/project-id/us-central1/evaluateTechnicianKyc \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ID_TOKEN>" \
  -d '{}'
```

### 3. Test in Firebase Console
1. Go to Cloud Functions tab
2. Click "Testing" in function details
3. Provide test input
4. Run function

---

## Deployment Verification

### 1. Verify Functions Deployed
```bash
firebase functions:list
```

Expected output:
```
✔  onUserCreated (Auth Trigger) - us-central1
✔  evaluateTechnicianKyc (HTTPS Callable) - us-central1
✔  checkKycStatus (HTTPS Callable) - us-central1
```

### 2. Check Function Code
```bash
firebase functions:describe onUserCreated
firebase functions:describe evaluateTechnicianKyc
firebase functions:describe checkKycStatus
```

### 3. View Recent Logs
```bash
firebase functions:log --tail

# Filter by function
firebase functions:log --limit=50 -- --level=info
```

---

## Performance Considerations

### Auth Trigger
- **Latency:** <1 second (runs after Auth user created)
- **Cost:** ~10ms per call (minimal)
- **Idempotency:** Checked with doc.exists() before writing
- **Timeout:** Default 60 seconds (plenty for this task)

### evaluateTechnicianKyc
- **Latency:** 500-2000ms (Firestore read + write + audit log)
- **Cost:** 3 Firestore operations (read tech doc, update tech doc, write audit log)
- **Timeout:** 30 seconds (set in Flutter provider)
- **Optimization:** No loops, direct field checks

### checkKycStatus
- **Latency:** 200-500ms (Firestore read only)
- **Cost:** 1 Firestore read operation
- **Timeout:** 10 seconds (set in Flutter provider)
- **Optimization:** Read-only, no writes

---

## Security Checklist

✅ Auth trigger doesn't throw errors (auth flow not blocked)
✅ Both callable functions check authentication
✅ Firestore rules block client writes to sensitive fields
✅ No direct user input in Cloud Functions (safe from injection)
✅ Proper error handling with meaningful error codes
✅ Audit logging for all KYC evaluations
✅ Idempotency checks where needed
✅ No sensitive data in error messages

---

## Rollback Procedure

### If Auth Trigger Issues
```bash
# Deploy previous version
firebase deploy --only functions:onUserCreated@previously-working-hash
```

### If KYC Function Issues
```bash
# Remove the functions (client will handle gracefully)
firebase deploy --only functions --remove functions:evaluateTechnicianKyc,functions:checkKycStatus
```

### If Firestore Rules Issues
```bash
# Restore previous rules
firebase deploy --only firestore:rules --config=<backup-rules-file>
```

---

## Monitoring Checklist

- [ ] Cloud Functions dashboard shows < 5% error rate
- [ ] Auth trigger firing for all new signups (check audit_logs)
- [ ] KYC evaluations completing in < 2 seconds
- [ ] No timeout errors in client app
- [ ] Firestore rules working (try to write to blocked field)
- [ ] Database storage within budget
- [ ] No cost spikes in Cloud Functions

---

*Code Reference for Phase 2*
*Use this for detailed implementation understanding*
