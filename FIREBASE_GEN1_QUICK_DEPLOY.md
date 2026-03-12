# Firebase Functions Gen1 Scheduler - Quick Deploy Guide

## Problem
```
TypeError: functions.pubsub.schedule is not a function
```

## Solution Applied

### File 1: `functions/src/finance/wallet_reconciliation.ts`
✅ Uses correct Gen1 syntax:
```typescript
import * as functions from 'firebase-functions';

export const runWalletReconciliation = functions
    .pubsub
    .schedule('0 3 * * *')
    .timeZone('UTC')
    .onRun(async (context) => {
        // reconciliation logic unchanged
    });
```

### File 2: `functions/src/index.ts`
✅ Properly exports all functions:
```typescript
export const runWalletReconciliation = walletReconciliation.runWalletReconciliation;
export const triggerManualReconciliation = walletReconciliation.triggerManualReconciliation;
export const getReconciliationAnomalies = walletReconciliation.getReconciliationAnomalies;
export const markWalletReviewed = walletReconciliation.markWalletReviewed;
```

## Deploy Steps

```bash
# 1. Navigate to functions directory
cd functions

# 2. Build TypeScript
npm run build

# 3. Deploy to Firebase
npm run deploy

# 4. Verify in Firebase Console
# - Go to Cloud Functions
# - Look for "runWalletReconciliation" (should show as Pub/Sub trigger)
# - Verify schedule: "0 3 * * *" (daily at 3 AM UTC)
```

## Verification

After deployment, verify in Firebase Console:
1. Cloud Functions → runWalletReconciliation
2. Trigger type should be: **Cloud Pub/Sub**
3. Topic should be: **firebase-schedule-runWalletReconciliation**
4. Schedule should be: **0 3 * * *** (daily at 3 AM UTC)

## Key Points

✅ **Gen1 Syntax Used:** `functions.pubsub.schedule()`
✅ **No v2 Imports:** No `firebase-functions/v2/scheduler`
✅ **Business Logic:** Unchanged - reconciliation logic preserved
✅ **Firestore:** No collections modified
✅ **Security:** Admin callables require authentication

## Troubleshooting

If error persists after deployment:

1. **Clear build cache:**
   ```bash
   rm -rf functions/lib
   npm run build
   ```

2. **Verify package.json:**
   - Should have: `"firebase-functions": "^7.1.1"`
   - Should NOT have: `"firebase-functions/v2"`

3. **Check imports in wallet_reconciliation.ts:**
   - Should have: `import * as functions from 'firebase-functions';`
   - Should NOT have: `import { onSchedule } from 'firebase-functions/v2/scheduler';`

4. **Verify exports in index.ts:**
   - All four functions should be exported
   - No commented-out exports for wallet reconciliation

---

**Status:** Ready to Deploy
**Estimated Deploy Time:** 2-3 minutes
**Zero Downtime:** Yes
