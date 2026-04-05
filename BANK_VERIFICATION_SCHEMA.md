# Technician Schema - Bank Verification Fields

## New Fields Added for Production-Safe Bank Verification

### Security & Rate Limiting Fields

```typescript
{
  // Existing bank fields
  bankAccountNumber: string;
  bankIfsc: string;
  bankHolderName: string;
  bankVerified: boolean;
  bankVerificationStatus: 'pending' | 'verifying' | 'verified' | 'failed';
  bankVerificationMessage: string;
  bankSubmittedAt: Timestamp;
  bankVerifiedAt: Timestamp;
  
  // Razorpay integration
  razorpayContactId: string;
  fundAccountId: string;
  razorpayFundAccountId: string;
  
  // NEW: Race condition protection
  verificationLock: boolean;  // Prevents concurrent verification attempts
  
  // NEW: Rate limiting
  verificationAttempts: number;  // Counter for attempts within window
  lastVerificationAttemptAt: Timestamp;  // Last attempt timestamp
}
```

## Firestore Collections

### 1. `verificationRequests/{idempotencyKey}`
**Purpose:** Idempotency tracking to prevent duplicate verifications

```typescript
{
  technicianId: string;
  success: boolean;
  status: 'verified' | 'failed';
  message: string;
  fundAccountId?: string;
  error?: string;
  createdAt: Timestamp;
  expiresAt: Timestamp;  // 24 hours for success, 1 hour for failures
}
```

### 2. `payment_logs/{logId}`
**Purpose:** Audit trail for all bank verification attempts

```typescript
{
  technicianId: string;
  action: 'bank_verification_attempt' | 'bank_verification_success' | 'bank_verification_failed' | 'bank_verification_error' | 'bank_verification_cleanup';
  status: 'started' | 'verified' | 'failed';
  accountNumber: string;  // Masked: ****1234
  ifsc: string;
  previousStatus?: string;
  idempotencyKey: string;
  attemptNumber?: number;
  reason?: string;
  error?: string;
  fundAccountId?: string;
  createdAt: Timestamp;
}
```

## Migration Script

Run this to add new fields to existing technician documents:

```javascript
// scripts/add_bank_verification_fields.js
const admin = require('firebase-admin');
admin.initializeApp();

async function addBankVerificationFields() {
  const technicians = await admin.firestore()
    .collection('technicians')
    .get();

  const batch = admin.firestore().batch();
  let count = 0;

  technicians.docs.forEach(doc => {
    const data = doc.data();
    
    // Only update if fields don't exist
    if (data.verificationLock === undefined) {
      batch.update(doc.ref, {
        verificationLock: false,
        verificationAttempts: 0,
        lastVerificationAttemptAt: null
      });
      count++;
    }
  });

  if (count > 0) {
    await batch.commit();
    console.log(`Updated ${count} technician documents`);
  } else {
    console.log('All documents already have the new fields');
  }
}

addBankVerificationFields().catch(console.error);
```

## Firestore Rules Update

Add these rules to `firestore.rules`:

```javascript
match /verificationRequests/{requestId} {
  // Only Cloud Functions can write
  allow read: if false;
  allow write: if false;
}

match /technicians/{technicianId} {
  // Technicians cannot modify verification lock or attempts
  allow update: if request.auth.uid == technicianId 
    && !request.resource.data.diff(resource.data).affectedKeys().hasAny([
      'verificationLock',
      'verificationAttempts',
      'lastVerificationAttemptAt',
      'bankVerified',
      'bankVerificationStatus',
      'fundAccountId',
      'razorpayContactId'
    ]);
}
```

## Status Flow

```
Initial State:
  bankVerificationStatus: null or 'pending'
  verificationLock: false

User Submits:
  bankVerificationStatus: 'verifying'
  verificationLock: true  🔒

Success:
  bankVerificationStatus: 'verified'
  bankVerified: true
  verificationLock: false  🔓

Failure:
  bankVerificationStatus: 'failed'
  bankVerified: false
  verificationLock: false  🔓

Timeout (Auto-cleanup):
  bankVerificationStatus: 'failed'
  bankVerificationMessage: 'Verification timeout. Please retry.'
  verificationLock: false  🔓
```

## Rate Limiting Logic

```
MAX_ATTEMPTS = 5
ATTEMPT_WINDOW = 1 hour

If (attempts >= 5 within 1 hour):
  Reject with "Too many attempts"

If (window expired):
  Reset counter to 0
```

## Idempotency Logic

```
idempotencyKey = SHA256(technicianId + accountNumber)

If (idempotencyKey exists in verificationRequests):
  Return cached result

Else:
  Process verification
  Store result in verificationRequests
```
