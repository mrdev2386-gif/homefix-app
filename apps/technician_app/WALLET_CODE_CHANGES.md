# 🔧 EXACT CODE CHANGES - COPY & PASTE READY

## FILE 1: wallet_screen.dart

### CHANGE 1: Add New Method (Add to _WalletScreenState class)

**Location:** After `_navigateToBankManagement()` method

**Add this code:**
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

---

### CHANGE 2: Update Button Label in _buildActionButtonsRow()

**Location:** Line ~280 in `_buildActionButtonsRow()` method

**BEFORE:**
```dart
Expanded(
  child: _ModernActionButton(
    icon: Icons.add_circle_outline_rounded,
    label: hasBankAccount ? 'Manage Bank' : 'Add Bank',
    onTap: () => _navigateToBankManagement(),
    gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  ),
),
```

**AFTER:**
```dart
Expanded(
  child: _ModernActionButton(
    icon: Icons.add_circle_outline_rounded,
    label: _getBankButtonLabel(bankAccounts),
    onTap: () => _navigateToBankManagement(),
    gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  ),
),
```

---

### CHANGE 3: Remove Bank Section from UI

**Location:** In `_buildContent()` method, around line ~120

**BEFORE:**
```dart
const SizedBox(height: 12),
// Step 5: QR Code Card
_buildQRCard(),
const SizedBox(height: 20),
// Bank Accounts Section
_buildBankAccountsSection(),
const SizedBox(height: 20),
// Transaction History
_buildTransactionHistory(transactions),
const SizedBox(height: 32),
```

**AFTER:**
```dart
const SizedBox(height: 12),
// Step 5: QR Code Card
_buildQRCard(),
const SizedBox(height: 20),
// Transaction History
_buildTransactionHistory(transactions),
const SizedBox(height: 32),
```

---

### CHANGE 4: Delete Entire Method

**Location:** Find and DELETE the entire `_buildBankAccountsSection()` method

**This method spans ~150 lines and starts with:**
```dart
/// Bank accounts section - Modern Premium Design
Widget _buildBankAccountsSection() {
  return StreamBuilder<List<TechnicianBankAccount>>(
    // ... entire method
  );
}
```

**Action:** Delete the entire method (search for "_buildBankAccountsSection" and delete)

---

### CHANGE 5: Delete Unused Method (Optional)

**Location:** Find and DELETE the `_showAddBankDialog()` method if it exists

**This method looks like:**
```dart
void _showAddBankDialog() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddBankAccountScreen()),
  ).then((_) => context.read<TechnicianProvider>().refreshTechnicianData());
}
```

**Action:** Delete this method (it's no longer used)

---

## FILE 2: firestore.rules

### CHANGE 1: Add Bank Accounts Collection Rules

**Location:** At the end of the file, before the closing brace

**Add this code:**
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

**Full context (where to add):**
```javascript
// ... existing rules ...

// ============================================
// TECHNICIAN BANK ACCOUNTS
// ============================================
match /technician_bank_accounts/{accountId} {
  allow read: if isAuthenticated() && 
               request.auth.uid == resource.data.technicianId;
  allow write: if false;
}

} // End of database rules
```

---

## VERIFICATION COMMANDS

### Verify wallet_screen.dart compiles:
```bash
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter analyze lib/screens/wallet_screen.dart
```

### Verify firestore.rules syntax:
```bash
cd C:\Users\yash\projects\homefix
firebase rules:test firestore.rules
```

### Deploy firestore.rules:
```bash
cd C:\Users\yash\projects\homefix
firebase deploy --only firestore:rules
```

---

## TESTING CODE

### Test 1: Verify Button Labels
```dart
// Add to test file
void testBankButtonLabels() {
  final state = _WalletScreenState();
  
  // Test 1: No bank
  expect(state._getBankButtonLabel([]), 'Add Bank');
  
  // Test 2: Pending
  final pendingBank = TechnicianBankAccount(
    id: '1',
    technicianId: 'user1',
    bankName: 'Test Bank',
    accountNumber: '1234567890',
    ifscCode: 'TEST0001234',
    accountHolderName: 'Test User',
    status: BankAccountStatus.pending,
    createdAt: DateTime.now(),
  );
  expect(state._getBankButtonLabel([pendingBank]), 'Verification in Progress');
  
  // Test 3: Verified
  final verifiedBank = pendingBank.copyWith(status: BankAccountStatus.verified);
  expect(state._getBankButtonLabel([verifiedBank]), 'Manage Bank');
  
  // Test 4: Rejected
  final rejectedBank = pendingBank.copyWith(status: BankAccountStatus.rejected);
  expect(state._getBankButtonLabel([rejectedBank]), 'Update Bank Details');
}
```

---

## SUMMARY OF CHANGES

| File | Change | Type | Lines |
|------|--------|------|-------|
| wallet_screen.dart | Add method | Addition | +15 |
| wallet_screen.dart | Update button | Modification | 1 |
| wallet_screen.dart | Remove section call | Deletion | -3 |
| wallet_screen.dart | Delete method | Deletion | -150 |
| wallet_screen.dart | Delete method | Deletion | -10 |
| firestore.rules | Add rules | Addition | +10 |

**Total:** 6 changes, ~-147 net lines

---

## CHECKLIST

### Before Making Changes
- [ ] Backup current files
- [ ] Create new branch: `git checkout -b fix/wallet-system`
- [ ] Read this document completely

### Making Changes
- [ ] Add `_getBankButtonLabel()` method
- [ ] Update button label in `_buildActionButtonsRow()`
- [ ] Remove bank section call from `_buildContent()`
- [ ] Delete `_buildBankAccountsSection()` method
- [ ] Delete `_showAddBankDialog()` method (if exists)
- [ ] Add Firestore rules for bank accounts

### After Making Changes
- [ ] Compile: `flutter analyze`
- [ ] No errors shown
- [ ] Deploy rules: `firebase deploy --only firestore:rules`
- [ ] Test locally
- [ ] Commit: `git commit -m "fix: wallet system cleanup and security"`
- [ ] Push: `git push origin fix/wallet-system`

---

## ROLLBACK COMMANDS

If you need to undo changes:

```bash
# Undo wallet_screen.dart changes
git checkout apps/technician_app/lib/screens/wallet_screen.dart

# Undo firestore.rules changes
git checkout firestore.rules

# Redeploy old rules
firebase deploy --only firestore:rules
```

---

## QUICK REFERENCE

### What Gets Removed
- ❌ `_buildBankAccountsSection()` method
- ❌ Bank section from wallet UI
- ❌ `_showAddBankDialog()` method

### What Gets Added
- ✅ `_getBankButtonLabel()` method
- ✅ Enhanced button label logic
- ✅ Firestore security rules

### What Stays the Same
- ✅ Bank fetching logic
- ✅ Withdraw guard logic
- ✅ Navigation to Profile
- ✅ All other wallet features

---

**Ready to implement? Follow the changes above in order!**

