# BANK VERIFICATION SYSTEM - FLOW DIAGRAM

## 🔄 COMPLETE VERIFICATION FLOW

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TECHNICIAN SUBMITS BANK DETAILS                  │
│                                                                     │
│  Input: accountHolderName, accountNumber, ifscCode                 │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 1: AUTHENTICATION CHECK                     │
│                                                                     │
│  ✓ User authenticated?                                              │
│  ✓ Valid technician profile?                                        │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 2: INPUT VALIDATION                         │
│                                                                     │
│  ✓ All fields present?                                              │
│  ✓ IFSC format valid? (4 letters + 0 + 6 alphanumeric)             │
│  ✓ Account number valid? (6-18 digits)                             │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│              STEP 3: IDEMPOTENCY CHECK (FIX #1)                     │
│                                                                     │
│  idempotencyKey = SHA256(userId + accountNumber)                    │
│                                                                     │
│  IF exists in verificationRequests:                                 │
│    ✓ Return cached result                                           │
│    ✓ Skip verification                                              │
│  ELSE:                                                              │
│    → Continue to next step                                          │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│            STEP 4: RACE CONDITION CHECK (FIX #2)                    │
│                                                                     │
│  IF verificationLock == true:                                       │
│    ✗ Reject: "Verification already in progress"                     │
│  ELSE:                                                              │
│    → Continue to next step                                          │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│              STEP 5: RATE LIMITING CHECK (FIX #3)                   │
│                                                                     │
│  IF attempts >= 5 within 1 hour:                                    │
│    ✗ Reject: "Too many attempts. Try after 1 hour."                │
│  ELSE IF window expired:                                            │
│    → Reset counter to 0                                             │
│  → Continue to next step                                            │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│         STEP 6: DUPLICATE FUND ACCOUNT CHECK (FIX #4)               │
│                                                                     │
│  IF bankVerified == true AND fundAccountId exists:                  │
│    ✓ Return: "Already verified"                                     │
│    ✓ Skip verification                                              │
│  ELSE:                                                              │
│    → Continue to next step                                          │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│           STEP 7: SET STATUS & LOCK (FIX #5 + #6)                   │
│                                                                     │
│  UPDATE technicians/{uid}:                                          │
│    bankVerificationStatus = "verifying"                             │
│    verificationLock = true 🔒                                       │
│    verificationAttempts += 1                                        │
│    lastVerificationAttemptAt = now                                  │
│                                                                     │
│  LOG payment_logs:                                                  │
│    action = "bank_verification_attempt"                             │
│    accountNumber = "****1234" (masked)                              │
│    idempotencyKey = hash                                            │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│         STEP 8: RAZORPAY CONTACT (FIX #7 - REUSE)                   │
│                                                                     │
│  IF razorpayContactId exists:                                       │
│    ✓ Reuse existing contact                                         │
│  ELSE:                                                              │
│    → Create new Razorpay contact                                    │
│    → Store razorpayContactId                                        │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│      STEP 9: RAZORPAY FUND ACCOUNT (FIX #8 - OVERWRITE)            │
│                                                                     │
│  → Create fund account via Razorpay API                             │
│  → Razorpay validates bank details automatically                    │
│  → Get fundAccountId and active status                              │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
    ┌───────────────────────────┐   ┌───────────────────────────┐
    │   FUND ACCOUNT ACTIVE     │   │  FUND ACCOUNT INACTIVE    │
    │   (Verification Success)  │   │  (Verification Failed)    │
    └───────────────────────────┘   └───────────────────────────┘
                    │                           │
                    ▼                           ▼
    ┌───────────────────────────┐   ┌───────────────────────────┐
    │  STEP 10: UPDATE SUCCESS  │   │  STEP 11: UPDATE FAILURE  │
    │  (FIX #9)                 │   │  (FIX #11)                │
    │                           │   │                           │
    │  UPDATE technicians:      │   │  UPDATE technicians:      │
    │    bankVerified = true    │   │    bankVerified = false   │
    │    status = "verified"    │   │    status = "failed"      │
    │    fundAccountId = id     │   │    message = error        │
    │    verificationLock=false │   │    verificationLock=false │
    │                           │   │                           │
    │  STORE idempotency:       │   │  STORE idempotency:       │
    │    success = true         │   │    success = false        │
    │    expiresAt = +24h       │   │    expiresAt = +1h        │
    │                           │   │                           │
    │  LOG success              │   │  LOG failure              │
    └───────────────────────────┘   └───────────────────────────┘
                    │                           │
                    └─────────────┬─────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │   RETURN RESULT TO APP  │
                    └─────────────────────────┘
```

---

## ⚠️ ERROR HANDLING FLOW

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ANY ERROR OCCURS                                 │
│                                                                     │
│  Network error, Razorpay API error, Firestore error, etc.          │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│              STEP 12: SAFE ERROR HANDLING (FIX #10)                 │
│                                                                     │
│  UPDATE technicians/{uid}:                                          │
│    bankVerificationStatus = "failed"                                │
│    bankVerificationMessage = error message                          │
│    verificationLock = false 🔓 (ALWAYS RELEASE)                     │
│                                                                     │
│  STORE idempotency:                                                 │
│    success = false                                                  │
│    error = error message                                            │
│    expiresAt = +1h                                                  │
│                                                                     │
│  LOG error with masked account number                               │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │   THROW ERROR TO APP    │
                    │   (User can retry)      │
                    └─────────────────────────┘
```

---

## 🧹 AUTO-CLEANUP FLOW (FIX #7)

```
┌─────────────────────────────────────────────────────────────────────┐
│          SCHEDULED FUNCTION: Every 10 minutes                       │
│          cleanupStuckBankVerifications()                            │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  QUERY technicians:                                                 │
│    WHERE bankVerificationStatus == "verifying"                      │
│    WHERE updatedAt < (now - 2 minutes)                              │
│    LIMIT 100                                                        │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
        ┌───────────────────┐       ┌───────────────────┐
        │  FOUND STUCK      │       │  NO STUCK         │
        │  VERIFICATIONS    │       │  VERIFICATIONS    │
        └───────────────────┘       └───────────────────┘
                    │                           │
                    ▼                           ▼
        ┌───────────────────┐       ┌───────────────────┐
        │  FOR EACH:        │       │  EXIT             │
        │                   │       └───────────────────┘
        │  UPDATE:          │
        │    status="failed"│
        │    message=       │
        │    "timeout"      │
        │    lock=false 🔓  │
        │                   │
        │  LOG cleanup      │
        └───────────────────┘
                    │
                    ▼
        ┌───────────────────┐
        │  COMMIT BATCH     │
        └───────────────────┘
```

---

## 🗑️ IDEMPOTENCY CLEANUP FLOW

```
┌─────────────────────────────────────────────────────────────────────┐
│          SCHEDULED FUNCTION: Daily at 2 AM                          │
│          cleanupOldIdempotencyRecords()                             │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  QUERY verificationRequests:                                        │
│    WHERE expiresAt < now                                            │
│    LIMIT 500                                                        │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
        ┌───────────────────┐       ┌───────────────────┐
        │  FOUND EXPIRED    │       │  NO EXPIRED       │
        │  RECORDS          │       │  RECORDS          │
        └───────────────────┘       └───────────────────┘
                    │                           │
                    ▼                           ▼
        ┌───────────────────┐       ┌───────────────────┐
        │  DELETE ALL       │       │  EXIT             │
        │  EXPIRED RECORDS  │       └───────────────────┘
        └───────────────────┘
                    │
                    ▼
        ┌───────────────────┐
        │  COMMIT BATCH     │
        └───────────────────┘
```

---

## 🔄 RETRY FLOW (AFTER FAILURE)

```
┌─────────────────────────────────────────────────────────────────────┐
│              USER SEES "VERIFICATION FAILED"                        │
│              Taps "Resubmit Bank Details"                           │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  IF status == "failed":                                             │
│    ✓ Allow resubmission                                             │
│    ✓ Generate NEW idempotency key (if account number changed)      │
│    ✓ Create NEW fund account (overwrites old fundAccountId)        │
│    ✓ Reuse existing razorpayContactId                               │
│                                                                     │
│  IF status == "verified":                                           │
│    ✗ Block resubmission                                             │
│    ✓ Show "Already verified" message                                │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📊 DATA FLOW

```
┌──────────────────┐
│  Technician App  │
└────────┬─────────┘
         │
         │ Submit bank details
         ▼
┌──────────────────────────────────────────────────────────────┐
│  Cloud Function: verifyTechnicianBankAccountSecure           │
│                                                              │
│  1. Validate input                                           │
│  2. Check idempotency (verificationRequests)                 │
│  3. Check lock (technicians.verificationLock)                │
│  4. Check rate limit (technicians.verificationAttempts)      │
│  5. Check duplicate (technicians.bankVerified)               │
│  6. Set lock & status                                        │
│  7. Call Razorpay API                                        │
│  8. Update Firestore                                         │
│  9. Store idempotency result                                 │
│  10. Release lock                                            │
└──────────────────────────────────────────────────────────────┘
         │
         │ Write to Firestore
         ▼
┌──────────────────────────────────────────────────────────────┐
│  Firestore Collections                                       │
│                                                              │
│  • technicians/{uid}                                         │
│    - bankVerificationStatus                                  │
│    - verificationLock                                        │
│    - verificationAttempts                                    │
│    - fundAccountId                                           │
│    - razorpayContactId                                       │
│                                                              │
│  • verificationRequests/{idempotencyKey}                     │
│    - success, status, message                                │
│    - expiresAt                                               │
│                                                              │
│  • payment_logs/{logId}                                      │
│    - action, status, accountNumber (masked)                  │
│    - idempotencyKey, attemptNumber                           │
└──────────────────────────────────────────────────────────────┘
         │
         │ Real-time updates
         ▼
┌──────────────────┐
│  Technician App  │
│  (Shows status)  │
└──────────────────┘
```

---

## 🎯 KEY DECISION POINTS

### Decision 1: Idempotency Check
```
IF idempotencyKey exists:
  → Return cached result (no API call)
ELSE:
  → Continue verification
```

### Decision 2: Lock Check
```
IF verificationLock == true:
  → Reject (race condition)
ELSE:
  → Set lock and continue
```

### Decision 3: Rate Limit Check
```
IF attempts >= 5 within 1 hour:
  → Reject (rate limit)
ELSE:
  → Increment counter and continue
```

### Decision 4: Duplicate Check
```
IF bankVerified == true AND fundAccountId exists:
  → Return success (no API call)
ELSE:
  → Continue verification
```

### Decision 5: Contact Reuse
```
IF razorpayContactId exists:
  → Reuse existing contact
ELSE:
  → Create new contact
```

### Decision 6: Fund Account Result
```
IF fundAccount.active == true:
  → Set status = "verified"
ELSE:
  → Set status = "failed"
```

---

**Legend:**
- ✓ = Success path
- ✗ = Rejection path
- 🔒 = Lock acquired
- 🔓 = Lock released
- → = Flow continues
