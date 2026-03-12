# Deep Research: HomeFix Backend Cloud Functions

## 📋 Research Summary

**Date:** 2024
**Target File:** `backend/functions/src/index.ts`
**Objective:** Implement missing booking lifecycle Cloud Functions

---

## 🔍 Key Findings

### 1. **Current Backend Architecture**

**File Structure:**
```
backend/
├── functions/
│   ├── src/
│   │   ├── admin/
│   │   │   └── service_moderation.ts (TypeScript)
│   │   ├── customRequests.js (JavaScript)
│   │   ├── submitReview.js (JavaScript)
│   │   └── index.ts (TypeScript - Main entry point)
│   ├── tsconfig.json
│   └── verifyTechnicianBankAccount.ts
├── package.json
└── DEPLOY_FUNCTIONS.md
```

**Technology Stack:**
- Firebase Functions v4.5.0
- Firebase Admin SDK v11.11.0
- TypeScript (tsconfig targets ES2017)
- Node.js 18
- Razorpay SDK v2.9.2

---

### 2. **Existing Function Patterns**

#### Pattern 1: TypeScript Callable Functions (service_moderation.ts)

```typescript
export const approveService = functions.https.onCall(
  async (data: ServiceModerationData, context) => {
    verifyAdminRole(context);
    
    const { serviceId } = data;
    
    if (!serviceId) {
      throw new functions.https.HttpsError('invalid-argument', 'Service ID is required');
    }

    try {
      await db.runTransaction(async (transaction) => {
        const serviceRef = db.collection('technician_services').doc(serviceId);
        const serviceDoc = await transaction.get(serviceRef);
        
        if (!serviceDoc.exists) {
          throw new functions.https.HttpsError('not-found', 'Service not found');
        }

        transaction.update(serviceRef, {
          status: 'active',
          approvedAt: admin.firestore.FieldValue.serverTimestamp(),
          approvedBy: context.auth!.uid,
        });
      });

      await createAuditLog(context.auth!.uid, 'approve_service', serviceId);
      
      return { success: true, message: 'Service approved successfully' };
    } catch (error) {
      console.error('Error approving service:', error);
      throw new functions.https.HttpsError('internal', 'Failed to approve service');
    }
  }
);
```

**Key Characteristics:**
- ✅ Uses `functions.https.onCall()` for callable functions
- ✅ Verifies admin role with `verifyAdminRole(context)`
- ✅ Uses Firestore transactions for atomicity
- ✅ Creates audit logs
- ✅ Proper error handling with HttpsError
- ✅ TypeScript with strict typing

#### Pattern 2: JavaScript Callable Functions (customRequests.js)

```javascript
exports.createCustomRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { title, description, category, ... } = data;

  if (!title?.trim() || !description?.trim() || ...) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  try {
    const requestRef = db.collection('custom_requests').doc();
    
    await requestRef.set({
      type: 'custom_request',
      customerId: userId,
      title: title.trim(),
      ...
      status: 'pending_admin_review',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, requestId: requestRef.id };
  } catch (error) {
    console.error('Error creating custom request:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create request');
  }
});
```

**Key Characteristics:**
- ✅ Uses `functions.https.onCall()` for callable functions
- ✅ Manual authentication check
- ✅ Input validation
- ✅ Proper error handling
- ✅ FCM notifications for users

#### Pattern 3: Wallet Functions (index.ts)

```typescript
export const requestWithdrawal = functions.https.onCall(
  {
    cors: true,
    enforceAppCheck: true,
  },
  async (data: WithdrawalData, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    // Verify ownership
    if (context.auth.uid !== technicianId) {
      throw new functions.https.HttpsError('permission-denied', 'Unauthorized access');
    }

    // Validate input
    if (amount < CONFIG.MIN_WITHDRAWAL_AMOUNT) {
      throw new functions.https.HttpsError('invalid-argument', `Minimum withdrawal amount is ₹${CONFIG.MIN_WITHDRAWAL_AMOUNT}`);
    }

    // Business logic
    try {
      // ... implementation
      return { success: true, payoutId, message: '...' };
    } catch (error: any) {
      console.error('Error:', error);
      throw new functions.https.HttpsError('internal', 'Failed to ...');
    }
  }
);
```

**Key Characteristics:**
- ✅ Uses options object with `cors: true` and `enforceAppCheck: true`
- ✅ Comprehensive validation
- ✅ Firestore transactions for atomicity
- ✅ Audit logging
- ✅ Error handling with specific error codes

---

### 3. **Admin Role Verification Pattern**

**From service_moderation.ts:**

```typescript
function verifyAdminRole(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  if (!context.auth.token?.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
}
```

**Status:** ✅ Reusable pattern - can be imported and used

---

### 4. **Audit Logging Pattern**

**From service_moderation.ts:**

```typescript
async function createAuditLog(
  adminId: string,
  action: string,
  serviceId: string
): Promise<void> {
  await db.collection('admin_audit_logs').add({
    adminId,
    action,
    serviceId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}
```

**Status:** ✅ Reusable pattern - can be adapted for bookings

---

### 5. **Notification Pattern**

**From customRequests.js:**

```javascript
// Send FCM notification
const techDoc = await db.collection('technicians').doc(technicianId).get();
const fcmToken = techDoc.data()?.fcmToken;

if (fcmToken) {
  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: 'New Custom Service Request',
      body: 'You have been assigned a new custom service request',
    },
    data: { requestId, type: 'custom_request' },
  });
}
```

**Status:** ✅ Reusable pattern - can be adapted for booking notifications

---

### 6. **Booking Status Naming Convention**

**Current Usage in Admin Panel:**
- `PENDING_ADMIN_APPROVAL` - Awaiting admin review
- `ADMIN_APPROVED` - Admin approved, awaiting technician
- `TECHNICIAN_ACCEPTED` - Technician accepted
- `IN_PROGRESS` - Service started
- `COMPLETED` - Service completed
- `REJECTED` - Admin rejected

**Status:** ✅ Consistent with admin panel expectations

---

### 7. **Firestore Transaction Pattern**

**From index.ts (wallet functions):**

```typescript
await db.runTransaction(async (transaction) => {
  const walletDoc = await transaction.get(walletRef);
  const currentBalance = walletDoc.data()?.availableBalance || 0;

  if (currentBalance < amount) {
    throw new Error('Insufficient balance');
  }

  transaction.update(walletRef, {
    availableBalance: currentBalance - amount,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});
```

**Status:** ✅ Atomic operations for data consistency

---

### 8. **Error Handling Pattern**

**Standard HttpsError codes used:**
- `unauthenticated` - User not authenticated
- `permission-denied` - User lacks permissions
- `invalid-argument` - Invalid input data
- `not-found` - Resource not found
- `failed-precondition` - Precondition failed
- `already-exists` - Resource already exists
- `internal` - Internal server error
- `resource-exhausted` - Rate limit exceeded

**Status:** ✅ Consistent error handling

---

## 🎯 Missing Booking Lifecycle Functions

### Required Functions:

1. **approveBooking** - Admin approves booking
2. **rejectBooking** - Admin rejects booking
3. **markBookingActive** - Mark service as started
4. **completeBooking** - Mark service as completed
5. **updateBookingPayment** - Update payment status

### Current Status:

- ❌ `approveBooking` - NOT IMPLEMENTED
- ❌ `rejectBooking` - NOT IMPLEMENTED
- ❌ `markBookingActive` - NOT IMPLEMENTED
- ❌ `completeBooking` - NOT IMPLEMENTED
- ❌ `updateBookingPayment` - NOT IMPLEMENTED

---

## 📊 Implementation Plan

### Step 1: Create Booking Status Constants

```typescript
const BOOKING_STATUS = {
  PENDING_ADMIN_APPROVAL: 'PENDING_ADMIN_APPROVAL',
  ADMIN_APPROVED: 'ADMIN_APPROVED',
  TECHNICIAN_ACCEPTED: 'TECHNICIAN_ACCEPTED',
  IN_PROGRESS: 'IN_PROGRESS',
  COMPLETED: 'COMPLETED',
  REJECTED: 'REJECTED',
} as const;
```

### Step 2: Create Helper Functions

- `verifyAdminRole()` - Already exists in service_moderation.ts
- `createBookingAuditLog()` - New function for booking audits
- `sendBookingNotification()` - New function for FCM notifications
- `getBookingData()` - Fetch booking with validation

### Step 3: Implement Booking Functions

Each function will:
1. Verify admin authentication
2. Validate input parameters
3. Fetch and validate booking document
4. Update booking status with transaction
5. Send notifications if applicable
6. Create audit log
7. Return success response

### Step 4: Integration Points

- Admin panel calls these functions via `adminBookingService.ts`
- Functions update Firestore `bookings/{bookingId}`
- Notifications sent to technicians and customers
- Audit logs created for compliance

---

## 🔐 Security Considerations

### Authentication:
- ✅ All functions require admin role
- ✅ Verified via `context.auth.token?.admin`

### Authorization:
- ✅ Only admins can approve/reject bookings
- ✅ Only system can mark active/completed

### Data Validation:
- ✅ Booking ID must exist
- ✅ Booking status must be valid
- ✅ Status transitions must be valid

### Audit Trail:
- ✅ All admin actions logged
- ✅ Timestamp and admin ID recorded
- ✅ Action type recorded

---

## 📝 Deployment Instructions

### Prerequisites:
```bash
cd backend
npm install
```

### Deploy Functions:
```bash
firebase deploy --only functions
```

### View Logs:
```bash
firebase functions:log
```

### Test Functions:
```bash
firebase emulators:start --only functions
```

---

## ✅ Conclusion

**Current State:** 🟡 PARTIALLY IMPLEMENTED
- ✅ Admin panel UI ready
- ✅ Service layer ready
- ✅ Backend patterns established
- ❌ Booking lifecycle functions missing

**Next Steps:**
1. Implement 5 missing booking functions
2. Follow existing TypeScript patterns
3. Use admin role verification
4. Add FCM notifications
5. Create audit logs
6. Deploy and test

---

**Research Completed:** ✅
**Ready for Implementation:** ✅
