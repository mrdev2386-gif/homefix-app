# Admin Panel Quick Reference - Reviews, Disputes & Risk

## 🎯 Quick Actions

### Reviews Module (`/reviews`)
```
HIDE REVIEW      → Sets isHidden = true
UNHIDE REVIEW    → Sets isHidden = false
FLAG REVIEW      → Sets isFlagged = true
UNFLAG REVIEW    → Sets isFlagged = false
```

### Disputes Module (`/disputes`)
```
INVESTIGATE      → status = 'investigating'
RESOLVE          → status = 'resolved' + resolvedAt
REJECT           → status = 'rejected' + rejectedAt
REFUND           → status = 'resolved' + credits wallet + creates transaction
```

### Risk Module (`/risk`)
```
BLOCK USER       → Updates user status to 'suspended'
RESET SCORE      → Sets riskScore = 0 + logs reason
```

---

## 🔐 Cloud Functions

| Function | Purpose | Parameters |
|----------|---------|------------|
| `admin_manageReview` | Review moderation | `{ reviewId, action, reason? }` |
| `admin_manageDispute` | Dispute resolution | `{ disputeId, action, notes?, amount? }` |
| `admin_manageRiskProfile` | Risk management | `{ entityId, action, reason?, newStatus? }` |

---

## 📊 Firestore Collections

### reviews
```typescript
{
  rating: number (1-5)
  isHidden: boolean
  isFlagged: boolean
  customerName: string
  technicianName: string
  reviewText: string
}
```

### disputes
```typescript
{
  status: 'open' | 'investigating' | 'resolved' | 'rejected'
  amountInvolved: number
  issueType: string
  description: string
  adminNotes: string
}
```

### riskSignals
```typescript
{
  riskScore: number (0-100)
  status: 'open' | 'reviewed' | 'cleared'
  userType: 'customer' | 'technician'
  triggerReason: string
}
```

---

## 🎨 Status Badges

### Reviews
- **Visible** - Green (isHidden = false)
- **Hidden** - Red (isHidden = true)
- **Flagged** - Amber (isFlagged = true)
- **Critical** - Rose (rating ≤ 2)

### Disputes
- **Open** - Blue
- **Investigating** - Amber
- **Resolved** - Green
- **Rejected** - Red

### Risk
- **Critical** - Rose (score ≥ 70)
- **High** - Amber (score 40-69)
- **Medium** - Indigo (score 20-39)
- **Low** - Slate (score < 20)

---

## 🔍 Filters

### Reviews
- Status: All, Visible, Hidden, Flagged
- Rating: 1★, 2★, 3★, 4★, 5★
- Search: Customer, Technician, Text

### Disputes
- Tabs: All, Open, Investigating, Resolved, Rejected
- Search: ID, Customer, Technician, Description

### Risk
- Status: All, Open, Reviewed, Cleared
- Score: All, Critical, High, Medium, Low
- Search: User ID, Trigger Reason

---

## 💰 Refund Process

When issuing refund:
1. Admin clicks "Refund" button
2. Enters amount and notes
3. Confirms action
4. **Backend automatically:**
   - Updates dispute status to 'resolved'
   - Credits customer wallet
   - Creates wallet transaction
   - Logs admin action

**Verify:**
```javascript
// Check wallet balance
customers/{customerId}.walletBalance

// Check transaction
customers/{customerId}/wallet_transactions/{txnId}
{
  type: 'credit',
  amount: <refund-amount>,
  reason: 'Dispute refund: <dispute-id>',
  disputeId: <dispute-id>
}
```

---

## 📝 Activity Logging

Every action creates log in `activity_logs`:
```typescript
{
  actorType: 'admin'
  actorUid: <admin-uid>
  action: 'review_hide' | 'dispute_resolve' | 'risk_reset'
  entityId: <entity-id>
  metadata: { reason?, amount?, newStatus? }
  createdAt: Timestamp
}
```

---

## ⚡ Keyboard Shortcuts

- `Ctrl/Cmd + K` - Focus search
- `Esc` - Close modal
- `Enter` - Confirm action (in modal)

---

## 🚨 Important Notes

### Security
- ✅ All writes via Cloud Functions
- ✅ Admin verification on every call
- ✅ No direct Firestore writes from frontend
- ✅ Activity logging for audit trail

### Performance
- Pagination: 20 items per page
- Search debounce: 300ms
- Indexed queries for speed

### Data Integrity
- No hard deletes (soft delete only)
- Timestamps on all actions
- Immutable transaction records

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied | Verify admin document exists |
| Function not found | Deploy Cloud Functions |
| Index required | Deploy Firestore indexes |
| Refund not working | Check customer wallet field exists |
| Slow loading | Check Firestore indexes built |

---

## 📞 Support Commands

```bash
# View function logs
firebase functions:log

# Check specific function
firebase functions:log --only admin_manageReview

# Deploy functions
firebase deploy --only functions

# Deploy indexes
firebase deploy --only firestore:indexes
```

---

## ✅ Pre-Flight Checklist

Before using admin panel:
- [ ] Admin document exists in Firestore
- [ ] Cloud Functions deployed
- [ ] Firestore indexes created
- [ ] Security rules updated
- [ ] Test data seeded (optional)

---

## 🎯 Common Workflows

### Moderate Negative Review
1. Go to Reviews → Filter by 1-2 stars
2. Read review text
3. If abusive → Flag
4. If inappropriate → Hide
5. Check activity log

### Resolve Customer Dispute
1. Go to Disputes → Open tab
2. Click dispute to view details
3. Mark as "Investigating"
4. Review evidence
5. If valid → Issue Refund
6. If invalid → Reject with notes

### Handle High-Risk User
1. Go to Risk → Filter by Critical
2. Review risk signals
3. Check user history
4. If malicious → Block User
5. If false positive → Reset Score

---

**Last Updated:** 2024
**Version:** 1.0.0
**Status:** Production Ready ✅
