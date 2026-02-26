# 🏗️ Architecture Diagram - Reviews, Disputes & Risk Modules

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     HOMEFIX ADMIN PANEL                         │
│                    (Next.js + TypeScript)                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   FIREBASE CLOUD FUNCTIONS                      │
│                     (Admin Verification)                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │ admin_manage     │  │ admin_manage     │  │ admin_manage │ │
│  │ Review           │  │ Dispute          │  │ RiskProfile  │ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Firestore SDK
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FIRESTORE DATABASE                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ reviews  │  │ disputes │  │ risk     │  │ activity     │  │
│  │          │  │          │  │ Signals  │  │ _logs        │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ customers/{id}/wallet_transactions (refund records)     │ │
│  └──────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow - Reviews Module

```
┌──────────────┐
│ Admin Panel  │
│ /reviews     │
└──────┬───────┘
       │
       │ 1. Load Reviews
       │ getDocs(query(reviews, orderBy, limit))
       ▼
┌──────────────┐
│  Firestore   │
│  reviews     │
└──────┬───────┘
       │
       │ 2. Display with filters
       ▼
┌──────────────┐
│ Admin clicks │
│ "Hide"       │
└──────┬───────┘
       │
       │ 3. Call Cloud Function
       │ admin_manageReview({ reviewId, action: 'hide' })
       ▼
┌──────────────────────┐
│ Cloud Function       │
│ - Verify admin       │
│ - Update review      │
│ - Log activity       │
└──────┬───────────────┘
       │
       │ 4. Update Firestore
       ▼
┌──────────────────────┐
│ reviews/{id}         │
│ isHidden: true       │
│ updatedAt: now()     │
└──────────────────────┘
       │
       │ 5. Create log
       ▼
┌──────────────────────┐
│ activity_logs/{id}   │
│ action: review_hide  │
│ actorUid: admin_uid  │
└──────────────────────┘
```

---

## Data Flow - Disputes Module (Refund)

```
┌──────────────┐
│ Admin Panel  │
│ /disputes    │
└──────┬───────┘
       │
       │ 1. Load Disputes
       │ getDocs(query(disputes, where, orderBy))
       ▼
┌──────────────┐
│  Firestore   │
│  disputes    │
└──────┬───────┘
       │
       │ 2. Admin clicks "Refund"
       │ Enters amount & notes
       ▼
┌──────────────┐
│ Confirmation │
│ Modal        │
└──────┬───────┘
       │
       │ 3. Call Cloud Function
       │ admin_manageDispute({ disputeId, action: 'refund', amount, notes })
       ▼
┌──────────────────────────────────┐
│ Cloud Function                   │
│ - Verify admin                   │
│ - Start Firestore transaction    │
│ - Update dispute status          │
│ - Credit customer wallet         │
│ - Create wallet transaction      │
│ - Log activity                   │
│ - Commit transaction             │
└──────┬───────────────────────────┘
       │
       │ 4. Atomic Updates
       ▼
┌─────────────────────────────────────────────────────────┐
│ TRANSACTION (All or Nothing)                            │
├─────────────────────────────────────────────────────────┤
│ disputes/{id}                                           │
│   status: 'resolved'                                    │
│   refundAmount: 500                                     │
│   refundProcessedAt: now()                              │
│                                                         │
│ customers/{customerId}                                  │
│   walletBalance: oldBalance + 500                       │
│                                                         │
│ customers/{customerId}/wallet_transactions/{txnId}      │
│   type: 'credit'                                        │
│   amount: 500                                           │
│   reason: 'Dispute refund: {disputeId}'                 │
│   disputeId: {disputeId}                                │
│   createdAt: now()                                      │
│                                                         │
│ activity_logs/{logId}                                   │
│   action: 'dispute_refund'                              │
│   actorUid: admin_uid                                   │
│   metadata: { amount: 500, notes: '...' }               │
└─────────────────────────────────────────────────────────┘
```

---

## Data Flow - Risk Module

```
┌──────────────┐
│ Admin Panel  │
│ /risk        │
└──────┬───────┘
       │
       │ 1. Load Risk Signals
       │ getDocs(query(riskSignals, orderBy, limit))
       ▼
┌──────────────┐
│  Firestore   │
│ riskSignals  │
└──────┬───────┘
       │
       │ 2. Display with score colors
       │ Critical (≥70): Red
       │ High (40-69): Amber
       │ Medium (20-39): Indigo
       │ Low (<20): Slate
       ▼
┌──────────────┐
│ Admin clicks │
│ "Reset Score"│
└──────┬───────┘
       │
       │ 3. Prompt for reason
       │ Enter reason text
       ▼
┌──────────────┐
│ Confirmation │
└──────┬───────┘
       │
       │ 4. Call Cloud Function
       │ admin_manageRiskProfile({ entityId, action: 'reset', reason })
       ▼
┌──────────────────────┐
│ Cloud Function       │
│ - Verify admin       │
│ - Reset risk score   │
│ - Update status      │
│ - Store reason       │
│ - Log activity       │
└──────┬───────────────┘
       │
       │ 5. Update Firestore
       ▼
┌──────────────────────────────┐
│ riskSignals/{entityId}       │
│   riskScore: 0               │
│   status: 'normal'           │
│   lastEvaluatedAt: now()     │
│   metadata:                  │
│     lastResetBy: admin_uid   │
│     reason: 'Manual review'  │
└──────────────────────────────┘
       │
       │ 6. Create log
       ▼
┌──────────────────────┐
│ activity_logs/{id}   │
│ action: risk_reset   │
│ actorUid: admin_uid  │
│ metadata: { reason } │
└──────────────────────┘
```

---

## Security Layer

```
┌─────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 1: Firebase Authentication                      │
│  ├─ User must be logged in                             │
│  └─ context.auth.uid verified                          │
│                                                         │
│  Layer 2: Admin Verification                           │
│  ├─ Check admins/{uid} document exists                 │
│  └─ Throw permission-denied if not admin               │
│                                                         │
│  Layer 3: Firestore Rules                              │
│  ├─ Read: Only if isAdmin()                            │
│  └─ Write: false (Cloud Functions only)                │
│                                                         │
│  Layer 4: Activity Logging                             │
│  ├─ Every action logged                                │
│  ├─ Includes actor, action, entity, metadata           │
│  └─ Immutable audit trail                              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  ADMIN PANEL PAGES                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  /reviews                                               │
│  ├─ useState: reviews, loading, filters                │
│  ├─ useEffect: fetchReviews()                          │
│  ├─ Filters: Rating, Status                            │
│  ├─ Search: Debounced (300ms)                          │
│  ├─ Pagination: Load More                              │
│  └─ Actions: Hide, Flag, View Details                  │
│                                                         │
│  /disputes                                              │
│  ├─ useState: disputes, loading, statusTab             │
│  ├─ useEffect: fetchDisputes()                         │
│  ├─ Tabs: Open, Investigating, Resolved, Rejected      │
│  ├─ Search: Real-time filter                           │
│  ├─ Pagination: Load More                              │
│  ├─ Actions: Investigate, Resolve, Reject, Refund      │
│  └─ Modal: Action confirmation with inputs             │
│                                                         │
│  /risk                                                  │
│  ├─ useState: signals, loading, filters                │
│  ├─ useEffect: fetchSignals()                          │
│  ├─ Filters: Status, Score Level                       │
│  ├─ Search: User ID, Trigger Reason                    │
│  ├─ Pagination: Load More                              │
│  ├─ Color Coding: Risk score visualization             │
│  └─ Actions: Block User, Reset Score                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Firestore Collections Schema

```
┌─────────────────────────────────────────────────────────┐
│                  FIRESTORE STRUCTURE                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  reviews/                                               │
│  └─ {reviewId}                                          │
│     ├─ bookingId: string                               │
│     ├─ customerId: string                              │
│     ├─ customerName: string                            │
│     ├─ technicianId: string                            │
│     ├─ technicianName: string                          │
│     ├─ rating: number (1-5)                            │
│     ├─ reviewText: string                              │
│     ├─ isHidden: boolean                               │
│     ├─ isFlagged: boolean                              │
│     ├─ createdAt: Timestamp                            │
│     └─ updatedAt: Timestamp                            │
│                                                         │
│  disputes/                                              │
│  └─ {disputeId}                                         │
│     ├─ bookingId: string                               │
│     ├─ customerId: string                              │
│     ├─ customerName: string                            │
│     ├─ technicianId: string                            │
│     ├─ technicianName: string                          │
│     ├─ issueType: string                               │
│     ├─ description: string                             │
│     ├─ amountInvolved: number                          │
│     ├─ status: enum                                    │
│     ├─ adminNotes: string                              │
│     ├─ createdAt: Timestamp                            │
│     ├─ updatedAt: Timestamp                            │
│     ├─ resolvedAt?: Timestamp                          │
│     ├─ refundAmount?: number                           │
│     └─ refundProcessedAt?: Timestamp                   │
│                                                         │
│  riskSignals/                                           │
│  └─ {signalId}                                          │
│     ├─ userId: string                                  │
│     ├─ userType: enum                                  │
│     ├─ riskType: string                                │
│     ├─ riskScore: number (0-100)                       │
│     ├─ triggerReason: string                           │
│     ├─ status: enum                                    │
│     ├─ createdAt: Timestamp                            │
│     ├─ reviewedAt?: Timestamp                          │
│     ├─ adminNotes?: string                             │
│     └─ metadata?: object                               │
│                                                         │
│  activity_logs/                                         │
│  └─ {logId}                                             │
│     ├─ actorType: 'admin'                              │
│     ├─ actorUid: string                                │
│     ├─ action: string                                  │
│     ├─ entityId: string                                │
│     ├─ metadata: object                                │
│     └─ createdAt: Timestamp                            │
│                                                         │
│  customers/                                             │
│  └─ {customerId}                                        │
│     ├─ walletBalance: number                           │
│     └─ wallet_transactions/                            │
│        └─ {txnId}                                       │
│           ├─ type: 'credit'                            │
│           ├─ amount: number                            │
│           ├─ reason: string                            │
│           ├─ disputeId: string                         │
│           └─ createdAt: Timestamp                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Deployment Pipeline

```
┌─────────────┐
│ Developer   │
│ Workstation │
└──────┬──────┘
       │
       │ 1. Code Changes
       ▼
┌─────────────┐
│ Git Commit  │
└──────┬──────┘
       │
       │ 2. Build Functions
       │ npm run build
       ▼
┌─────────────────┐
│ TypeScript      │
│ Compilation     │
└──────┬──────────┘
       │
       │ 3. Deploy Functions
       │ firebase deploy --only functions
       ▼
┌─────────────────┐
│ Firebase        │
│ Cloud Functions │
└──────┬──────────┘
       │
       │ 4. Deploy Indexes
       │ firebase deploy --only firestore:indexes
       ▼
┌─────────────────┐
│ Firestore       │
│ Indexes         │
└──────┬──────────┘
       │
       │ 5. Build Admin Panel
       │ npm run build
       ▼
┌─────────────────┐
│ Next.js Build   │
│ Static Export   │
└──────┬──────────┘
       │
       │ 6. Deploy Hosting
       │ firebase deploy --only hosting
       ▼
┌─────────────────┐
│ Firebase        │
│ Hosting         │
└──────┬──────────┘
       │
       │ 7. Live!
       ▼
┌─────────────────┐
│ Production      │
│ Admin Panel     │
└─────────────────┘
```

---

## Error Handling Flow

```
┌──────────────┐
│ User Action  │
└──────┬───────┘
       │
       │ Try
       ▼
┌──────────────────┐
│ Cloud Function   │
│ Call             │
└──────┬───────────┘
       │
       ├─ Success ──────────┐
       │                    ▼
       │              ┌──────────────┐
       │              │ Update UI    │
       │              │ Show Success │
       │              └──────────────┘
       │
       └─ Error ────────────┐
                            ▼
                      ┌──────────────┐
                      │ Catch Block  │
                      └──────┬───────┘
                             │
                             ▼
                      ┌──────────────┐
                      │ Show Alert   │
                      │ with Message │
                      └──────┬───────┘
                             │
                             ▼
                      ┌──────────────┐
                      │ Log to       │
                      │ Console      │
                      └──────────────┘
```

---

**Architecture Version:** 1.0.0
**Last Updated:** 2024
**Status:** Production Ready ✅
