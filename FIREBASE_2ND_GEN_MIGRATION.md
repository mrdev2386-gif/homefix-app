# Firebase Cloud Functions 1st Gen → 2nd Gen Migration Guide

## Overview
Complete migration plan for 150+ functions from firebase-functions v4.x to v5.x (2nd Gen).

## Updated Package.json Changes

```json
{
    "engines": { "node": "20" },
    "dependencies": {
        "firebase-functions": "^5.1.1",
        "firebase-admin": "^12.6.0"
    }
}
```

---

## 2nd Gen Function Templates

### 1. Callable Function Template (v2)

```typescript
// functions/src/v2_templates/callable_template.ts
import { onCall } from "firebase-functions/v2/https";
import { CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * v2 Callable Function Template
 * - Maintains same callable name (no client change)
 * - Region: us-central1
 * - Memory: 256MB
 * - Timeout: 60s
 */
export const myFunction = onCall(
    {
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 60,
        minInstances: 2,
        maxInstances: 100,
    },
    async (request: CallableRequest<any>) => {
        // v2: Context is now in request
        const context = request;
        
        // Auth check
        if (!context.auth) {
            throw new https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const uid = context.auth.uid;
        const data = context.data || {};

        try {
            // Your business logic here
            const result = await db.collection("my_collection").add({
                uid,
                data,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return { success: true, id: result.id };
        } catch (error: any) {
            throw new https.HttpsError("internal", error.message);
        }
    }
);
```

### 2. HTTP Webhook Function Template (v2)

```typescript
// functions/src/v2_templates/http_webhook_template.ts
import { onRequest } from "firebase-functions/v2/https";
import * as https from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * v2 HTTP Webhook Template (Razorpay, etc.)
 * - Region: us-central1
 * - Memory: 512MB
 * - Timeout: 30s
 * - Supports raw body for webhook signature verification
 */
export const handlePaymentWebhook = onRequest(
    {
        region: "us-central1",
        memory: "512MiB",
        timeoutSeconds: 30,
        minInstances: 3,
        maxInstances: 500,
    },
    async (req: https.Request, res: https.Response) => {
        // CORS for webhooks (adjust as needed)
        res.set("Access-Control-Allow-Origin", "*");
        res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
        res.set("Access-Control-Allow-Headers", "Content-Type, X-Webhook-Signature");

        if (req.method === "OPTIONS") {
            res.status(204).send("");
            return;
        }

        if (req.method !== "POST") {
            res.status(405).send("Method Not Allowed");
            return;
        }

        try {
            // Webhook signature verification
            const signature = req.headers["x-webhook-signature"] as string;
            const secret = process.env.WEBHOOK_SECRET || functions.config().webhook.secret;
            
            if (!verifyWebhookSignature(req.body, signature, secret)) {
                res.status(401).send("Invalid signature");
                return;
            }

            const eventType = req.body.event;
            const payload = req.body.payload;

            // Process webhook
            await processWebhookEvent(eventType, payload);

            res.status(200).json({ received: true });
        } catch (error: any) {
            console.error("Webhook error:", error);
            res.status(500).json({ error: error.message });
        }
    }
);

function verifyWebhookSignature(body: any, signature: string, secret: string): boolean {
    const crypto = require("crypto");
    const expectedSignature = crypto
        .createHmac("sha256", secret)
        .update(JSON.stringify(body))
        .digest("hex");
    return signature === expectedSignature;
}

async function processWebhookEvent(eventType: string, payload: any): Promise<void> {
    switch (eventType) {
        case "payment.authorized":
            // Handle payment authorized
            break;
        case "payment.failed":
            // Handle payment failed
            break;
        default:
            console.log(`Unknown event type: ${eventType}`);
    }
}
```

### 3. Firestore Trigger Template (v2)

```typescript
// functions/src/v2_templates/firestore_trigger_template.ts
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * v2 Firestore Trigger Template
 * - Region: us-central1
 * - Memory: 256MB
 * - Timeout: 60s
 * - Document pattern: bookings/{bookingId}
 */
export const onBookingCreated = onDocumentCreated(
    "bookings/{bookingId}",
    {
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 60,
        minInstances: 1,
        maxInstances: 100,
    },
    async (event: any) => {
        // v2: Data is now in event.data
        const snapshot = event.data;
        if (!snapshot) {
            console.log("No document associated with the event");
            return;
        }

        const booking = snapshot.data();
        const bookingId = event.params.bookingId;

        try {
            // Your business logic
            console.log(`Booking created: ${bookingId}`);

            // Example: Send notification
            await db.collection("notifications").add({
                userId: booking.customerId,
                title: "Booking Received",
                body: `Your booking for ${booking.serviceTitle} has been received.`,
                type: "booking_created",
                bookingId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return;
        } catch (error: any) {
            console.error(`Error processing booking ${bookingId}:`, error);
            throw error;
        }
    }
);

/**
 * v2 Firestore Update Trigger Template
 */
export const onBookingStatusChange = onDocumentUpdated(
    "bookings/{bookingId}",
    {
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 60,
        minInstances: 1,
        maxInstances: 100,
    },
    async (event: any) => {
        const beforeData = event.data.before.data();
        const afterData = event.data.after.data();
        const bookingId = event.params.bookingId;

        if (!beforeData || !afterData) return;

        // Check if status changed
        if (beforeData.status !== afterData.status) {
            console.log(`Booking ${bookingId} status: ${beforeData.status} → ${afterData.status}`);
            // Handle status change
        }
    }
);
```

---

## Safe Migration Strategy (Step-by-Step)

### Phase 1: Preparation (Week 1)

1. **Backup Current Configuration**
   ```bash
   firebase functions:config:get > functions_config_backup.json
   firebase functions:list
   ```

2. **Update package.json** to firebase-functions ^5.1.1

3. **Install Dependencies**
   ```bash
   cd functions
   npm install
   npm run build
   ```

4. **Set Up Test Environment**
   - Create staging project if not exists
   - Copy production functions config
   - Deploy to staging first

### Phase 2: Parallel Deployment (Weeks 2-4)

**CRITICAL: Never delete 1st Gen functions until fully verified**

1. **Create v2 Index File**
   - Copy `index.ts` → `index_v2.ts`
   - Convert all functions to v2 syntax
   - Keep SAME function names

2. **Deploy v2 Functions Alongside 1st Gen**
   ```bash
   # Deploy to staging first
   firebase deploy --only functions --project staging

   # Verify all v2 functions work
   # Test with real clients
   ```

3. **Verify v2 Function Signatures**
   ```bash
   firebase functions:list | grep -E "v2_|gen2"
   ```

### Phase 3: Client-Side Verification (Week 4)

1. **Monitor Both Generations**
   ```bash
   firebase functions:log --only createBooking --project production
   firebase functions:log --only createBooking_v2 --project production
   ```

2. **Switch Client SDK Configuration**
   - Update client SDK to target v2 functions
   - Or keep automatic routing (recommended)

3. **Load Testing**
   ```bash
   # Test with 10% traffic first
   # Gradually increase to 100%
   ```

### Phase 4: Cutover (Week 5)

1. **Update 1st Gen Functions to Return Migration Notice**
   ```typescript
   // Temporarily modify 1st Gen to return redirect hint
   export const createBooking = functions.https.onCall((data, context) => {
       return { 
           message: "Migration in progress",
           version: "v1",
           redirectTo: "createBooking_v2"
       };
   });
   ```

2. **Final Verification**
   - All critical paths tested
   - Performance metrics comparable
   - No errors in logs

### Phase 5: Delete 1st Gen (Week 6+)

**Wait minimum 7 days after full cutover before deletion**

```bash
# Delete specific 1st Gen function
firebase functions:delete createBooking --region us-central1

# Or delete all 1st Gen at once (AFTER verification)
firebase functions:delete createBooking,initiateRazorpayPayment,onBookingCreated
```

---

## Batching Deployment Strategy

### Batch 1: Core Payment Functions (Highest Priority)
```bash
firebase deploy --only \
  functions:createBooking,\
  functions:initiateRazorpayPayment,\
  functions:verifyRazorpayPayment,\
  functions:handlePaymentWebhook \
  --region us-central1
```

### Batch 2: Critical Booking Functions
```bash
firebase deploy --only \
  functions:onBookingCreated,\
  functions:onBookingStatusChange,\
  functions:respondToAssignment,\
  functions:assignTechnicianToBooking \
  --region us-central1
```

### Batch 3: Admin Functions
```bash
firebase deploy --only \
  functions:admin_getDashboardStats,\
  functions:admin_manageBooking,\
  functions:admin_getUsers,\
  functions:admin_getTechnicians \
  --region us-central1
```

### Batch 4: Matching & Lifecycle Functions
```bash
firebase deploy --only \
  functions:matchTechnicians,\
  functions:createBookingWithAssignment,\
  functions:updateBookingStatus,\
  functions:handleBookingTimeouts \
  --region us-central1
```

### Batch 5: Remaining Functions
```bash
# All remaining functions
firebase deploy --only functions:$(\
  firebase functions:list --project production \
  --filter "gen=1st" --format "value(name)" \
  | grep -v "createBooking\|razorpay\|booking" \
  | tr '\n' ',' \
)
```

---

## Testing Before Deletion

### 1. Functional Testing
```typescript
// Test script: functions/src/testing/v2_test_suite.ts
import * as test from "firebase-functions-test";
import * as myFunction from "../index_v2";

const testEnv = test({
    projectId: "test-project",
});

describe("v2 Functions Test Suite", () => {
    afterAll(() => {
        testEnv.cleanup();
    });

    test("createBooking - authenticated user", async () => {
        const wrapped = testEnv.wrap(myFunction.createBooking);
        
        const result = await wrapped({
            data: {
                services: [{ id: "svc1", name: "AC Repair", price: 500 }],
                scheduledDate: "2024-01-15",
                scheduledTime: "10:00 AM",
                address: { line1: "123 Main St" },
                totalAmount: 500,
            },
        }, {
            auth: {
                uid: "test-user-123",
                token: { email: "test@example.com" }
            }
        });

        expect(result.success).toBe(true);
    });
});
```

### 2. Integration Testing Script
```bash
#!/bin/bash
# functions/scripts/v2_integration_test.sh

echo "=== V2 Function Integration Tests ==="

# Test 1: Callable function
echo "Testing createBooking..."
RESULT=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"data":{"test":true}}' \
  "https://us-central1-project.cloudfunctions.net/createBooking_v2")
echo "Result: $RESULT"

# Test 2: Webhook function
echo "Testing handlePaymentWebhook..."
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"event":"test","payload":{}}' \
  "https://us-central1-project.cloudfunctions.net/handlePaymentWebhook"

echo "=== Tests Complete ==="
```

### 3. Performance Comparison
```bash
# Load test using Firebase Performance Monitoring
firebase functions:log --project production --region us-central1 \
  | grep "Function execution took"
```

---

## Exact Delete Strategy After Verification

### Step 1: Verify No Traffic (7 days minimum)
```bash
# Check invocations
firebase functions:metrics \
  --project production \
  --function createBooking \
  --region us-central1
```

### Step 2: Delete One by One (Safety First)
```bash
# Delete in order of dependency (bottom-up)
firebase functions:delete onTechnicianApplicationUpdate --region us-central1 --project production
firebase functions:delete onBookingStatusChange --region us-central1 --project production
firebase functions:delete onBookingCreated --region us-central1 --project production
```

### Step 3: Final Cleanup
```bash
# Delete all remaining 1st Gen functions
firebase functions:delete $(firebase functions:list --project production --filter "gen=1st" --format "value(name)") --region us-central1 --project production
```

---

## Production Hardening Settings

### Memory Configuration
```typescript
// Light functions: 256MB
// Webhooks: 512MB
// Data processing: 1GiB
// PDF generation: 2GiB
```

### Concurrency Settings
```typescript
onCall({
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
    minInstances: 2,    // Prevent cold starts for high-traffic functions
    maxInstances: 100,   // Cap to prevent runaway scaling
    concurrency: 80,     // Allow multiple concurrent requests
}, handler);
```

### Cold Start Prevention
```typescript
// For critical functions, set minInstances
const paymentHandler = onCall({
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 60,
    minInstances: 5,    // Always warm
    maxInstances: 50,
}, async (request) => {
    // Function is pre-warmed
});
```

### Rate Limiting
```typescript
import { onCall } from "firebase-functions/v2/https";

export const createBooking = onCall({
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
    // Enable built-in rate limiting (v2)
    rateLimits: {
        maxConcurrentRequests: 100,
        maxRequestsPerSecond: 50,
    }
}, async (request) => {
    // Your handler
});
```

### Timeout Configuration
```typescript
// Quick operations: 10-30s
// Database ops: 60s
// PDF/Complex: 120s
// Long-running: 300s (max)
```

---

## Avoiding Quota Exceeded Issues

### 1. Deploy in Small Batches
```bash
# Max 10 functions per deploy
firebase deploy --only "functions:func1,functions:func2,...,functions:func10"
```

### 2. Use --force Carefully
```bash
# Only when absolutely necessary
firebase deploy --only functions --force
```

### 3. Monitor Quota
```bash
gcloud compute regions describe us-central1 --format="json(quotas)"
```

### 4. Stagger Deploys
```bash
# Wait 60 seconds between batches
sleep 60 && firebase deploy --only batch2
sleep 60 && firebase deploy --only batch3
```

---

## Razorpay Webhook Stability

### Critical: Maintain Same Endpoint URL
```typescript
// OLD (1st Gen) - Keep until v2 verified
export const handlePaymentWebhook = functions.https.onRequest((req, res) => {
    // Currently deployed
});

// NEW (2nd Gen) - Must use same URL
export const handlePaymentWebhook_v2 = onRequest({
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 30,
    minInstances: 3,  // High availability for payments
}, async (req, res) => {
    // Verified version
});

// After v2 verified, rename:
// Delete handlePaymentWebhook
// Rename handlePaymentWebhook_v2 → handlePaymentWebhook
```

### Webhook Signature Verification
```typescript
import { onRequest } from "firebase-functions/v2/https";

export const handlePaymentWebhook = onRequest({
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 30,
    minInstances: 3,
}, async (req, res) => {
    const signature = req.headers["x-razorpay-signature"] as string;
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
    
    if (!verifyRazorpaySignature(req.body, signature, secret)) {
        console.error("Invalid webhook signature");
        res.status(401).send("Invalid signature");
        return;
    }
    
    // Process event...
});
```

---

## Quick Reference: Import Changes

| 1st Gen | 2nd Gen |
|---------|---------|
| `import * as functions from 'firebase-functions'` | `import { onCall } from 'firebase-functions/v2/https'` |
| `functions.https.onCall` | `onCall` |
| `functions.https.onRequest` | `onRequest` |
| `functions.firestore.document().onCreate` | `onDocumentCreated` |
| `functions.firestore.document().onUpdate` | `onDocumentUpdated` |
| `functions.auth.user().onCreate` | `onUserCreated` |
| `functions.pubsub.schedule()` | `onSchedule` |
| `context.auth` | `request.auth` |
| `context.params` | `event.params` |

---

## Rollback Plan

If v2 has issues:

```bash
# 1. Immediate rollback to 1st Gen
firebase deploy --only functions:createBooking --project production

# 2. Revert package.json
git checkout functions/package.json

# 3. Redeploy original 1st Gen
firebase deploy --only functions --project production

# 4. Investigate and fix issues
```

---

## Migration Checklist

- [ ] Backup current functions config
- [ ] Update package.json to firebase-functions ^5.1.1
- [ ] Create v2 index file with converted functions
- [ ] Deploy v2 to staging
- [ ] Test all v2 functions in staging
- [ ] Deploy v2 to production (parallel)
- [ ] Monitor both generations for 7 days
- [ ] Verify performance metrics
- [ ] Gradually shift traffic to v2
- [ ] Wait 7 days after full cutover
- [ ] Delete 1st Gen functions one by one
- [ ] Final cleanup and documentation
