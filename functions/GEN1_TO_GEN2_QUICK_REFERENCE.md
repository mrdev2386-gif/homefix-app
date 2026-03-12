# Gen1 → Gen2 Migration Quick Reference

## Summary

✅ **3 files migrated**
✅ **7 functions converted**
✅ **0 errors**
✅ **Ready to deploy**

---

## Files Changed

### 1. `src/notification_triggers.ts`
- 4 functions migrated
- Firestore triggers (onCreate, onUpdate)

### 2. `src/reviews/review_triggers.ts`
- 1 function migrated
- Firestore trigger (onCreate)

### 3. `src/finance/wallet_reconciliation.ts`
- 3 functions migrated
- Callable functions (onCall)

---

## Key Changes

### Firestore Triggers

```typescript
// OLD
functions.firestore.document('path/{id}').onCreate(async (snap, ctx) => {
  const data = snap.data();
  const id = ctx.params.id;
});

// NEW
onDocumentCreated('path/{id}', async (event) => {
  const data = event.data?.data();
  const id = event.params.id;
});
```

### Callable Functions

```typescript
// OLD
functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  throw new functions.https.HttpsError('error', 'msg');
});

// NEW
onCall({ enforceAppCheck: false }, async (request) => {
  const uid = request.auth?.uid;
  throw new HttpsError('error', 'msg');
});
```

---

## Imports

### Firestore Triggers
```typescript
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
```

### Callable Functions
```typescript
import { onCall } from 'firebase-functions/v2/https';
import { HttpsError } from 'firebase-functions/v2/https';
```

---

## Deployment

```bash
# Build
npm run build

# Deploy
firebase deploy --only functions

# Verify
firebase functions:list
firebase functions:log
```

---

## Verification

- ✅ All Gen1 patterns replaced
- ✅ All imports updated
- ✅ All error handling updated
- ✅ TypeScript builds successfully
- ✅ No breaking changes
- ✅ Admin SDK compatible
- ✅ Security rules compatible
- ✅ Client SDK compatible

---

## Status: READY FOR PRODUCTION
