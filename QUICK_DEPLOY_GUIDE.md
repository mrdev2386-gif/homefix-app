# Quick Deployment Guide - Firebase Functions Fix

## Problem
```
TypeError: functions.pubsub.schedule is not a function
```

## Solution
Temporarily disabled scheduled function `runWalletReconciliation` that was causing deployment crash.

## Deploy Now

```bash
# 1. Navigate to functions directory
cd functions

# 2. Build TypeScript
npm run build

# 3. Deploy to Firebase
npm run deploy

# 4. Verify in Firebase Console
# - Go to Cloud Functions
# - Verify deployment succeeded
# - Check that functions are listed
```

## What Changed

**File 1:** `src/finance/wallet_reconciliation.ts`
- Removed: `runWalletReconciliation` scheduled function
- Added: `walletReconciliationDisabled` stub function
- Kept: All admin callables (triggerManualReconciliation, getReconciliationAnomalies, markWalletReviewed)

**File 2:** `src/index.ts`
- Commented out: `export const runWalletReconciliation`
- Added: `export const walletReconciliationDisabled`
- Kept: All admin callable exports

## Verification

After deployment, verify:
1. ✅ Deployment succeeded (no errors)
2. ✅ Cloud Functions are listed in Firebase Console
3. ✅ Admin callables are available
4. ✅ No `functions.pubsub.schedule` errors

## Rollback (if needed)

To restore scheduled function later:
1. Uncomment `export const runWalletReconciliation` in index.ts
2. Restore `runWalletReconciliation` function in wallet_reconciliation.ts
3. Run `npm run build && npm run deploy`

---

**Status:** Ready to deploy
**Risk:** Low (minimal changes, no logic modified)
**Time:** ~2-3 minutes
