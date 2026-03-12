# Firebase Functions Gen1 to Gen2 Migration Guide

## Overview
This document outlines the complete migration from Firebase Functions Gen1 to Gen2 to support CPU configuration and resolve the deployment error: "Cannot set CPU on functions because they are GCF gen 1".

## Key Changes Required

### 1. Package.json Update
```json
"firebase-functions": "^5.1.0"  // Updated from ^3.24.1
```

### 2. Import Changes

#### OLD (Gen1):
```typescript
import * as functions from 'firebase-functions';

// Usage:
functions.https.onCall(...)
functions.firestore.document(...).onCreate(...)
functions.auth.user().onCreate(...)
functions.pubsub.schedule(...).onRun(...)
```

#### NEW (Gen2):
```typescript
import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onAuthUserCreate } from 'firebase-functions/v2/identity';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';

// Usage:
onCall(...)
onDocumentCreated(...)
onAuthUserCreate(...)
onSchedule(...)
onMessagePublished(...)
```

### 3. Function Definition Changes

#### Callable Functions (HTTPS)

**OLD (Gen1):**
```typescript
export const myFunction = functions.https.onCall(async (data, context) => {
    // logic
});
```

**NEW (Gen2):**
```typescript
export const myFunction = onCall(
    {
        region: 'asia-south1',
        memory: '512MiB',
        cpu: 1,
        timeoutSeconds: 60,
        concurrency: 100,
    },
    async (request) => {
        const data = request.data;
        const context = request.auth;
        // logic
    }
);
```

#### Firestore Triggers

**OLD (Gen1):**
```typescript
export const myTrigger = functions.firestore
    .document('collection/{docId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        // logic
    });
```

**NEW (Gen2):**
```typescript
export const myTrigger = onDocumentCreated(
    {
        document: 'collection/{docId}',
        region: 'asia-south1',
        memory: '512MiB',
    },
    async (event) => {
        const data = event.data?.data();
        const params = event.params;
        // logic
    }
);
```

#### Auth Triggers

**OLD (Gen1):**
```typescript
export const myAuthTrigger = functions.auth.user().onCreate(async (user) => {
    // logic
});
```

**NEW (Gen2):**
```typescript
export const myAuthTrigger = onAuthUserCreate(
    {
        region: 'asia-south1',
        memory: '256MiB',
    },
    async (user) => {
        // logic
    }
);
```

#### Scheduled Functions

**OLD (Gen1):**
```typescript
export const mySchedule = functions.pubsub.schedule('every 24 hours')
    .timeZone('Asia/Kolkata')
    .onRun(async (context) => {
        // logic
    });
```

**NEW (Gen2):**
```typescript
export const mySchedule = onSchedule(
    {
        schedule: 'every 24 hours',
        timeZone: 'Asia/Kolkata',
        region: 'asia-south1',
        memory: '512MiB',
    },
    async (context) => {
        // logic
    }
);
```

### 4. Error Handling Changes

**OLD (Gen1):**
```typescript
throw new functions.https.HttpsError('unauthenticated', 'Not authenticated');
```

**NEW (Gen2):**
```typescript
import { HttpsError } from 'firebase-functions/v2/https';
throw new HttpsError('unauthenticated', 'Not authenticated');
```

### 5. Parameter Access Changes

**OLD (Gen1) - Callable:**
```typescript
export const func = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    const input = data.someField;
});
```

**NEW (Gen2) - Callable:**
```typescript
export const func = onCall(async (request) => {
    const uid = request.auth?.uid;
    const input = request.data.someField;
});
```

**OLD (Gen1) - Firestore:**
```typescript
export const trigger = functions.firestore.document('path/{id}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const id = context.params.id;
    });
```

**NEW (Gen2) - Firestore:**
```typescript
export const trigger = onDocumentCreated('path/{id}', async (event) => {
    const data = event.data?.data();
    const id = event.params.id;
});
```

## Files Requiring Migration

### Critical Files (Callable Functions):
1. `src/index.ts` - Main exports
2. `src/booking/booking_lifecycle.ts` - Booking operations
3. `src/admin/booking_moderation.ts` - Admin functions
4. `src/finance/technician_withdrawal.ts` - Withdrawal functions
5. `src/finance/wallet_reconciliation.ts` - Wallet functions
6. `src/custom_request.ts` - Custom requests
7. `src/admin/notifications.ts` - Admin notifications
8. `src/technician/auth.ts` - Auth triggers
9. `src/notification_triggers.ts` - Notification triggers
10. `src/reviews/review_triggers.ts` - Review triggers
11. `src/booking/booking_notifications.ts` - Booking notifications
12. `src/custom_requests/custom_request_notifications.ts` - Custom request notifications

### Additional Files (Module Exports):
- All files in `src/admin/` directory
- All files in `src/booking/` directory
- All files in `src/finance/` directory
- All files in `src/technician/` directory
- All files in `src/customer/` directory
- All files in `src/payments/` directory
- All files in `src/matching/` directory
- All files in `src/chat/` directory
- All files in `src/partner/` directory
- All files in `src/custom_requests/` directory

## CPU Configuration Options

Once migrated to Gen2, you can set CPU configuration:

```typescript
export const heavyComputation = onCall(
    {
        region: 'asia-south1',
        memory: '1GiB',
        cpu: 2,  // 1 or 2 CPUs
        timeoutSeconds: 540,  // Up to 9 minutes
        concurrency: 100,
    },
    async (request) => {
        // Heavy computation logic
    }
);
```

### Memory Options:
- 128MiB, 256MiB, 512MiB, 1GiB, 2GiB, 4GiB, 8GiB, 16GiB

### CPU Options:
- 1 (default)
- 2 (requires memory >= 1GiB)

### Timeout Options:
- 1-540 seconds (up to 9 minutes)

## Migration Checklist

- [ ] Update package.json to firebase-functions@^5.1.0
- [ ] Update all imports in index.ts
- [ ] Migrate all callable functions (onCall)
- [ ] Migrate all Firestore triggers (onDocumentCreated, onDocumentUpdated)
- [ ] Migrate all auth triggers (onAuthUserCreate)
- [ ] Migrate all scheduled functions (onSchedule)
- [ ] Update all error handling (HttpsError)
- [ ] Update all parameter access patterns
- [ ] Run TypeScript compilation check
- [ ] Test with Firebase emulator
- [ ] Deploy to Firebase

## Testing

### Local Testing:
```bash
npm run build
npm run serve
```

### Deployment:
```bash
firebase deploy --only functions
```

## Rollback Plan

If issues occur:
1. Revert package.json to firebase-functions@^3.24.1
2. Revert all function definitions to Gen1 syntax
3. Run `npm install`
4. Redeploy

## References

- [Firebase Functions Gen2 Documentation](https://firebase.google.com/docs/functions/gen2)
- [Migration Guide](https://firebase.google.com/docs/functions/migrate-gen2)
- [CPU Configuration](https://firebase.google.com/docs/functions/manage-functions#set_memory_and_cpu_allocation)
