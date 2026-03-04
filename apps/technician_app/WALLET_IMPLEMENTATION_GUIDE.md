# 🔧 TECHNICIAN WALLET SYSTEM - IMPLEMENTATION GUIDE

## QUICK SUMMARY

**What's Wrong:**
1. WalletScreen has duplicate "Add Bank" section
2. Bank account fetching is correct but UI needs cleanup
3. Firestore rules missing for bank accounts collection
4. Button labels don't reflect all bank statuses

**What to Fix:**
1. Remove `_buildBankAccountsSection()` from WalletScreen
2. Enhance button label logic to show all states
3. Add Firestore rules for bank accounts
4. Verify navigation to Profile Screen works

**Time Required:** 30 minutes  
**Risk Level:** LOW (no breaking changes)

---

## STEP-BY-STEP FIXES

### FIX #1: Remove Duplicate Bank Section from WalletScreen

**File:** `apps/technician_app/lib/screens/wallet_screen.dart`

**Action 1: Remove method**
```dart
// DELETE THIS ENTIRE METHOD (lines ~500-650):
Widget _buildBankAccountsSection() {
  return StreamBuilder<List<TechnicianBankAccount>>(
    // ... entire method
  );
}
```

**Action 2: Remove from UI**
```dart
// In _buildContent() method, REMOVE these lines:
// Step 5: QR Code Card
_buildQRCard(),
const SizedBox(height: 20),
// Bank Accounts Section          <-- DELETE THIS LINE
_buildBankAccountsSection(),       <-- DELETE THIS LINE
const SizedBox(height: 20),        <-- DELETE THIS LINE
// Transaction History
_buildTransactionHistory(transactions),
```

**After Fix:**
```dart
// Step 5: QR Code Card
_buildQRCard(),
const SizedBox(height: 20),
// Transaction History
_buildTransactionHistory(transactions),
```

---

### FIX #2: Enhance Button Label Logic

**File:** `apps/technician_app/lib/screens/wallet_screen.dart`

**Add this method to `_WalletScreenState` class:**

```dart
/// Get appropriate button label based on bank account status
String _getBankButtonLabel(List<TechnicianBankAccount> accounts) {
  if (accounts.isEmpty) {
    return 'Add Bank';
  }
  
  final account = accounts.first;
  
  switch (account.status) {
    case BankAccountStatus.pending:
      return 'Verification in Progress';
    case BankAccountStatus.rejected:
      return 'Update Bank Details';
    case BankAccountStatus.verified:
      return 'Manage Bank';
    case BankAccountStatus.dormant:
      return 'Reactivate Bank';
  }
}
```

**Update button in `_buildActionButtonsRow()`:**

```dart
// REPLACE THIS:
label: hasBankAccount ? 'Manage Bank' : 'Add Bank',

// WITH THIS:
label: _getBankButtonLabel(bankAccounts),
```

---

### FIX #3: Add Firestore Security Rules

**File:** `firestore.rules`

**Add this rule block after existing rules:**

```javascript
// ============================================
// TECHNICIAN BANK ACCOUNTS
// ============================================
match /technician_bank_accounts/{accountId} {
  // Technician can read their own bank accounts
  allow read: if isAuthenticated() && 
               request.auth.uid == resource.data.technicianId;
  
  // Only Cloud Functions can write (no client writes)
  allow write: if false;
}
```

**Deploy:**
```bash
cd C:\Users\yash\projects\homefix
firebase deploy --only firestore:rules
```

---

### FIX #4: Verify Navigation Method

**File:** `apps/technician_app/lib/screens/wallet_screen.dart`

**Verify this method exists and is correct:**

```dart
/// Navigate to Profile Screen → Bank & Payout Section
void _navigateToBankManagement() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const TechnicianProfileScreen(),
    ),
  ).then((_) {
    // Refresh after returning from profile
    context.read<TechnicianProvider>().refreshTechnicianData();
  });
}
```

**Status:** ✅ Already implemented correctly

---

## VERIFICATION CHECKLIST

### Before Deployment
- [ ] Removed `_buildBankAccountsSection()` method
- [ ] Removed bank section from `_buildContent()`
- [ ] Added `_getBankButtonLabel()` method
- [ ] Updated button label to use new method
- [ ] Verified `_navigateToBankManagement()` exists
- [ ] Added Firestore rules for bank accounts
- [ ] Compiled without errors

### After Deployment
- [ ] Deployed Firestore rules successfully
- [ ] Opened Wallet Screen - no bank section visible
- [ ] Tapped "Add Bank" - navigated to Profile Screen
- [ ] Checked bank account status - button label correct
- [ ] Tested with pending bank - "Verification in Progress" shown
- [ ] Tested with verified bank - "Manage Bank" shown
- [ ] Tested withdraw with unverified bank - disabled
- [ ] Tested withdraw with verified bank - enabled

---

## TESTING SCENARIOS

### Scenario 1: No Bank Account
```
1. Open Wallet Screen
2. Verify: "Add Bank" button visible
3. Tap button
4. Verify: Navigates to Profile Screen
5. Verify: Bank & Payout section visible
```

### Scenario 2: Bank Pending Verification
```
1. Create bank account (status: pending)
2. Open Wallet Screen
3. Verify: Button shows "Verification in Progress"
4. Verify: Withdraw button is DISABLED
5. Verify: No bank section in wallet
```

### Scenario 3: Bank Verified
```
1. Bank account verified (status: verified)
2. Open Wallet Screen
3. Verify: Button shows "Manage Bank"
4. Verify: Withdraw button is ENABLED
5. Tap Withdraw → Should work
```

### Scenario 4: Bank Rejected
```
1. Bank account rejected (status: rejected)
2. Open Wallet Screen
3. Verify: Button shows "Update Bank Details"
4. Verify: Withdraw button is DISABLED
5. Tap button → Navigate to Profile to update
```

---

## SECURITY VERIFICATION

### Test 1: Client Cannot Write Bank Accounts
```javascript
// Try this in browser console (should fail):
db.collection('technician_bank_accounts').add({
  technicianId: 'user123',
  bankName: 'Test Bank',
  accountNumber: '1234567890',
  ifscCode: 'TEST0001234',
  accountHolderName: 'Test User',
  status: 'verified'
});

// Expected: Permission denied error
```

### Test 2: Technician Can Read Own Accounts
```javascript
// This should work:
db.collection('technician_bank_accounts')
  .where('technicianId', '==', currentUser.uid)
  .get();

// Expected: Returns user's bank accounts
```

### Test 3: Technician Cannot Read Others' Accounts
```javascript
// This should fail:
db.collection('technician_bank_accounts')
  .where('technicianId', '==', 'otherUserId')
  .get();

// Expected: Permission denied error
```

---

## ROLLBACK PLAN

If issues occur:

### Rollback Step 1: Revert WalletScreen
```bash
git checkout apps/technician_app/lib/screens/wallet_screen.dart
```

### Rollback Step 2: Revert Firestore Rules
```bash
git checkout firestore.rules
firebase deploy --only firestore:rules
```

---

## MONITORING

### After Deployment, Monitor:

1. **Cloud Functions Logs**
   - Check `verifyTechnicianBankAccount` for errors
   - Check `razorpayBankWebhook` for webhook failures

2. **Firestore**
   - Monitor `technician_bank_accounts` collection
   - Check for permission denied errors in logs

3. **App Logs**
   - Check for navigation errors
   - Check for bank fetch errors

---

## SUMMARY OF CHANGES

| File | Change | Lines | Impact |
|------|--------|-------|--------|
| wallet_screen.dart | Remove section | -150 | UI Cleanup |
| wallet_screen.dart | Add method | +15 | Enhanced Labels |
| wallet_screen.dart | Update button | 1 | Better UX |
| firestore.rules | Add rules | +10 | Security |

**Total Changes:** 4 files, ~176 lines modified/added

---

## FINAL CHECKLIST

- [ ] All code changes implemented
- [ ] No compilation errors
- [ ] Firestore rules deployed
- [ ] All tests passing
- [ ] Security verified
- [ ] Ready for production

