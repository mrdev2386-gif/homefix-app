# 🚨 CRITICAL FIXES - Action Checklist

## Priority 1: IMMEDIATE (Fix Today)

### ✅ Task 1: Remove Duplicate Function Implementations

**File:** `src/index.ts`

**Action:**
```typescript
// DELETE THESE LINES (around line 180-185):
// export const createTechnicianService = technicianServices.createTechnicianService;
// export const updateTechnicianService = technicianServices.updateTechnicianService;
// export const deleteTechnicianService = technicianServices.deleteTechnicianService;
// export const getMyTechnicianServices = technicianServices.getMyTechnicianServices;

// RENAME THESE (around line 190-195):
export const createTechnicianService = techServicesManagement.addTechnicianService;
export const updateTechnicianService = techServicesManagement.updateTechnicianService;
export const deleteTechnicianService = techServicesManagement.deleteTechnicianService;
export const toggleTechnicianServiceStatus = techServicesManagement.toggleTechnicianServiceStatus;
export const getMyTechnicianServices = technicianServices.getMyTechnicianServices; // Keep this one

// DELETE IMPORT:
// import * as technicianServices from './technician/createTechnicianService';
```

**Verification:**
```bash
# Search for duplicate exports
findstr /n "createTechnicianService\|updateTechnicianService\|deleteTechnicianService" src\index.ts

# Should only show ONE export for each function
```

---

### ✅ Task 2: Fix Admin Initialization

**File:** `src/index.ts`

**Action:**
```typescript
// REPLACE LINES 1-5:
// OLD:
// import { initializeApp } from 'firebase-admin/app';
// import { getFirestore } from 'firebase-admin/firestore';
// initializeApp();

// NEW:
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}
console.log("BOOT OK - Functions loading...");

// MOVE THIS LINE UP (currently at line 9):
// import * as admin from 'firebase-admin';
```

**Verification:**
```bash
# Deploy and check logs
firebase deploy --only functions
firebase functions:log --limit 10

# Should see "BOOT OK - Functions loading..." once
```

---

### ✅ Task 3: Fix Race Condition in Wallet Credit

**File:** `src/payments/razorpayWebhookV2.ts`

**Action:**
```typescript
// FIND: async function processTechnicianWalletCredit (around line 450)

// REPLACE:
await db.runTransaction(async (transaction) => {
  const orderRef = db.collection("razorpayOrders").doc(orderId);
  const orderDoc = await transaction.get(orderRef);
  
  // OLD:
  // if (orderDoc.exists && orderDoc.data()?.status === "paid") {
  //   console.log(`${LOG_PREFIX} duplicate_ignored - Order already paid in transaction: ${orderId}`);
  //   return;  // ⚠️ UNSAFE - transaction still commits
  // }
  
  // NEW:
  if (orderDoc.exists && orderDoc.data()?.status === "paid") {
    console.log(`${LOG_PREFIX} duplicate_ignored - Order already paid: ${orderId}`);
    throw new Error("IDEMPOTENCY_CHECK_FAILED"); // ✅ Abort transaction
  }
  
  // ✅ FIRST ACTION: Mark order as paid BEFORE wallet credit
  if (orderDoc.exists) {
    transaction.update(orderRef, {
      status: "paid",
      paymentId,
      paidAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
  
  // Then proceed with wallet credit...
  const walletRef = db.collection("technician_wallets").doc(technicianId);
  const walletDoc = await transaction.get(walletRef);
  
  // ... rest of the function
});
```

**Verification:**
```bash
# Test with duplicate webhook calls
# Monitor logs for "IDEMPOTENCY_CHECK_FAILED"
firebase functions:log --only razorpayWebhookV2
```

---

## Priority 2: HIGH (Fix This Week)

### ✅ Task 4: Add Missing Null Checks

**File:** `src/payments/razorpayWebhookV2.ts`

**Action:**
```typescript
// FIND: async function processBookingPayment (around line 350)

// REPLACE:
const bookingRef = db.collection("bookings").doc(orderData.bookingId);
const bookingDoc = await bookingRef.get();

if (!bookingDoc.exists) {
  console.warn(`${LOG_PREFIX} booking_not_found - Booking: ${orderData.bookingId}`);
  return;
}

// OLD:
// const booking = bookingDoc.data()!;

// NEW:
const bookingData = bookingDoc.data();
if (!bookingData) {
  console.error(`${LOG_PREFIX} booking_data_missing - Booking ${bookingDoc.id} has no data`);
  return;
}
const booking = bookingData;

// Continue with rest of function...
```

---

### ✅ Task 5: Consolidate Profile Completion Logic

**Create New File:** `src/shared/technician_utils.ts`

```typescript
/**
 * Shared utilities for technician profile management
 */

export const TOTAL_ONBOARDING_STEPS = 4;

export interface TechnicianData {
  stepsCompleted?: {
    basic?: boolean;
    professional?: boolean;
    kyc?: boolean;
    portfolio?: boolean;
  };
  profileApproved?: boolean;
  profileRejected?: boolean;
}

export function calculateProfileCompletion(technician: TechnicianData): number {
  const stepsCompleted = technician.stepsCompleted || {};
  const completedSteps = Object.values(stepsCompleted).filter(Boolean).length;
  return Math.round((completedSteps / TOTAL_ONBOARDING_STEPS) * 100);
}

export function validateProfileForServiceManagement(
  technician: TechnicianData
): { valid: boolean; error?: string } {
  const profileCompletion = calculateProfileCompletion(technician);
  
  if (profileCompletion < 100) {
    return {
      valid: false,
      error: "Please complete your profile to 100% before managing services."
    };
  }
  
  if (!technician.profileApproved) {
    if (technician.profileRejected) {
      return {
        valid: false,
        error: "Your profile was rejected. Please update your information and resubmit."
      };
    }
    return {
      valid: false,
      error: "Your profile is under admin review. You can manage services after approval."
    };
  }
  
  return { valid: true };
}
```

**Update Files:**
```typescript
// IN src/technician/services_management.ts:
import { validateProfileForServiceManagement } from '../shared/technician_utils';

// REPLACE validation logic:
const validation = validateProfileForServiceManagement(techData);
if (!validation.valid) {
  throw new https.HttpsError("failed-precondition", validation.error!);
}

// IN src/technician/createTechnicianService.ts:
// Same replacement
```

---

## Priority 3: MEDIUM (Fix This Month)

### ✅ Task 6: Add Input Sanitization

**Create New File:** `src/shared/sanitization.ts`

```typescript
/**
 * Input sanitization utilities
 */

export function sanitizeText(input: string): string {
  // Remove HTML tags and trim
  return input
    .trim()
    .replace(/<[^>]*>/g, '')
    .replace(/[<>]/g, '');
}

export function sanitizeHTML(input: string): string {
  // More aggressive HTML removal
  return input
    .trim()
    .replace(/<script[^>]*>.*?<\/script>/gi, '')
    .replace(/<[^>]*>/g, '')
    .replace(/javascript:/gi, '')
    .replace(/on\w+\s*=/gi, '');
}

export function sanitizeUrl(url: string): string {
  // Ensure URL is safe
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    throw new Error('Invalid URL protocol');
  }
  
  // Block javascript: and data: URLs
  if (url.toLowerCase().includes('javascript:') || url.toLowerCase().includes('data:')) {
    throw new Error('Unsafe URL detected');
  }
  
  return url.trim();
}
```

**Update Functions:**
```typescript
// IN src/technician/services_management.ts:
import { sanitizeText, sanitizeHTML } from '../shared/sanitization';

// REPLACE:
if (updates.name !== undefined) {
  updateData.name = sanitizeText(updates.name);
}

if (updates.description !== undefined) {
  updateData.description = sanitizeHTML(updates.description);
}
```

---

### ✅ Task 7: Improve Image URL Validation

**File:** `src/technician/createTechnicianService.ts`

**Action:**
```typescript
// FIND: function validateImageUrl (around line 350)

// REPLACE:
function validateImageUrl(url: string): { valid: boolean; error?: string } {
  try {
    const parsedUrl = new URL(url);
    
    // Only allow Firebase Storage
    const ALLOWED_DOMAINS = [
      'firebasestorage.googleapis.com',
      'storage.googleapis.com'
    ];
    
    if (!ALLOWED_DOMAINS.includes(parsedUrl.hostname)) {
      return { 
        valid: false, 
        error: 'Image must be hosted on Firebase Storage' 
      };
    }
    
    // Check file extension
    const validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    const pathname = parsedUrl.pathname.toLowerCase();
    const hasValidExtension = validExtensions.some(ext => pathname.includes(ext));
    
    if (!hasValidExtension) {
      return { 
        valid: false, 
        error: 'Invalid image format. Use JPG, PNG, or WebP' 
      };
    }
    
    return { valid: true };
  } catch (error) {
    return { valid: false, error: 'Invalid URL format' };
  }
}
```

---

## Deployment Checklist

### Before Deployment
- [ ] All critical fixes applied
- [ ] Code reviewed by team
- [ ] TypeScript build successful (`npm run build`)
- [ ] No console errors in build output
- [ ] Environment variables verified

### Deployment Steps
```bash
# 1. Build
cd C:\Users\yash\projects\homefix\functions
npm run build

# 2. Deploy to staging first
firebase use staging
firebase deploy --only functions

# 3. Test critical flows
# - Create technician service
# - Process payment
# - Update booking status

# 4. Monitor logs for 30 minutes
firebase functions:log --limit 100

# 5. If stable, deploy to production
firebase use production
firebase deploy --only functions
```

### After Deployment
- [ ] Monitor error rates in Cloud Functions dashboard
- [ ] Check payment processing logs
- [ ] Verify no duplicate function calls
- [ ] Test booking creation and updates
- [ ] Monitor wallet transactions

---

## Verification Commands

```bash
# Check for duplicate exports
findstr /n "export const.*Technician.*Service" src\index.ts

# Check admin initialization
findstr /n "initializeApp\|admin.apps" src\index.ts

# Check for unsafe patterns
findstr /n "\.data()!" src\payments\*.ts
findstr /n "return;" src\payments\razorpayWebhookV2.ts

# Build and check for errors
npm run build 2>&1 | findstr /i "error"
```

---

## Rollback Plan

If issues occur after deployment:

```bash
# Quick rollback
firebase deploy --only functions --force

# Or revert specific function
firebase deploy --only functions:createTechnicianService --force

# Check logs
firebase functions:log --only createTechnicianService --limit 50
```

---

**Created:** 2025-01-XX  
**Priority:** CRITICAL  
**Estimated Time:** 4-8 hours for all critical fixes
