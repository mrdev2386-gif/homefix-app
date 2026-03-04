# Razorpay Bank Verification - Complete Implementation Guide

## ✅ IMPLEMENTATION OVERVIEW

### System Architecture
```
Profile Screen (Bank Details Form)
  ↓
Cloud Function: verifyTechnicianBankAccount
  ↓
Razorpay Penny Drop API (₹1 verification)
  ↓
Firestore Update (bankStatus: approved/rejected/verifying)
  ↓
TechnicianProvider (realtime listener)
  ↓
Wallet Screen (auto-updates UI)
```

---

## 📁 FILES CREATED

### 1. Backend - Cloud Function ✅
**File**: `backend/functions/verifyTechnicianBankAccount.ts`

**Features**:
- Validates bank details (IFSC format, account number)
- Calls Razorpay Penny Drop API
- Updates Firestore with verification status
- Handles webhook for async updates
- Secure (uses Razorpay secret keys)

**Deploy**:
```bash
cd backend/functions
npm install axios
firebase deploy --only functions:verifyTechnicianBankAccount,functions:razorpayWebhook
```

**Environment Setup**:
```bash
firebase functions:config:set razorpay.key_id="YOUR_RAZORPAY_KEY_ID"
firebase functions:config:set razorpay.key_secret="YOUR_RAZORPAY_KEY_SECRET"
```

---

### 2. Firestore Security Rules ✅
**File**: `firestore_bank_rules.rules`

**Key Rules**:
- Technicians can read their own document
- Technicians CANNOT update: `bankStatus`, `bankVerifiedAt`, `bankVerificationMessage`
- Only Cloud Functions can update verification fields
- Wallet transactions are read-only

**Deploy**:
```bash
firebase deploy --only firestore:rules
```

---

### 3. Flutter - FunctionsService ✅
**File**: `FUNCTIONS_SERVICE_BANK_VERIFY.dart`

**Add to**: `lib/core/services/functions_service.dart`

**Method**: `verifyBankAccount()`
- Calls Cloud Function
- Includes timeout (45 seconds)
- Logs with AppLogger
- Returns verification result

---

### 4. Flutter - Simplified Wallet UI ✅
**File**: `WALLET_SIMPLIFIED_BANK_SECTION.dart`

**Replace**: `_buildBankAccountsSection()` in `wallet_screen.dart`

**Features**:
- NO direct bank account adding
- Shows "Add Bank Account" button → navigates to Profile
- Displays 3 states:
  - **No Bank**: Redirect to profile
  - **Verifying**: Shows progress indicator
  - **Rejected**: Shows error with "Update" button
  - **Approved**: Shows masked account details

---

### 5. Flutter - Updated Withdraw Button ✅
**File**: `WALLET_WITHDRAW_BUTTON_UPDATED.dart`

**Replace**: `_buildActionButtonsRow()` in `wallet_screen.dart`

**Logic**:
- Enabled ONLY when `bankStatus == 'approved'`
- Shows warning messages:
  - "Add bank account to withdraw"
  - "Bank verification in progress"
  - "Bank verification failed"
  - "Insufficient balance"

---

## 🔐 BANK STATUS FLOW

### Status Values
```dart
null / 'not_submitted' → No bank details
'verifying'            → Penny drop in progress
'approved'             → Verified successfully
'rejected'             → Verification failed
```

### Status Transitions
```
User submits bank details
  ↓
bankStatus = 'verifying'
  ↓
Razorpay API call
  ↓
SUCCESS → bankStatus = 'approved'
FAILED  → bankStatus = 'rejected'
```

---

## 🎨 UI STATES

### 1. No Bank Account
```
┌─────────────────────────────────────┐
│         [🏦]                        │
│                                     │
│   No bank account linked            │
│                                     │
│   Add your bank details from        │
│   Profile to enable withdrawals     │
│                                     │
│   [+ Add Bank Account]              │
│   (navigates to Profile)            │
└─────────────────────────────────────┘
```

### 2. Verifying
```
┌─────────────────────────────────────┐
│ Bank Account        [Verifying...]  │
├─────────────────────────────────────┤
│ [⏳] Verifying bank account...      │
│      This usually takes a few       │
│      seconds                        │
└─────────────────────────────────────┘

Withdraw Button: DISABLED
Message: "Bank verification in progress"
```

### 3. Rejected
```
┌─────────────────────────────────────┐
│ Bank Account              [Failed]  │
├─────────────────────────────────────┤
│ [❌] Bank verification failed       │
│                                     │
│ Please check your bank details      │
│ and try again                       │
│                                     │
│ [Update Bank Details]               │
│ (navigates to Profile)              │
└─────────────────────────────────────┘

Withdraw Button: DISABLED
Message: "Bank verification failed"
```

### 4. Approved
```
┌─────────────────────────────────────┐
│ Bank Account           [Verified]   │
├─────────────────────────────────────┤
│ [🏦] HDFC Bank                      │
│      John Doe                       │
│ ─────────────────────────────────── │
│ Account Number    XXXX5678          │
│ IFSC Code        HDFC0001234        │
└─────────────────────────────────────┘

Withdraw Button: ENABLED
```

---

## 🔧 PROFILE SCREEN INTEGRATION

### Bank Details Form
**Location**: Profile → Bank & Payout section

**Fields**:
- Account Holder Name
- Bank Name
- Account Number
- IFSC Code

**Submit Flow**:
```dart
// In profile screen
Future<void> _submitBankDetails() async {
  setState(() => _isVerifying = true);
  
  try {
    final result = await _functionsService.verifyBankAccount(
      accountHolderName: _nameController.text.trim(),
      accountNumber: _accountController.text.trim(),
      ifscCode: _ifscController.text.trim().toUpperCase(),
      bankName: _bankController.text.trim(),
    );
    
    if (result['status'] == 'approved') {
      _showSuccessDialog('Bank account verified successfully!');
    } else if (result['status'] == 'verifying') {
      _showInfoDialog('Bank verification in progress. This may take a few moments.');
    } else {
      _showErrorDialog(result['message'] ?? 'Verification failed');
    }
  } catch (e) {
    _showErrorDialog('Failed to verify bank account: $e');
  } finally {
    setState(() => _isVerifying = false);
  }
}
```

---

## 📊 FIRESTORE STRUCTURE

### technicians/{uid}
```json
{
  "bankName": "HDFC Bank",
  "accountNumber": "12345678",
  "ifscCode": "HDFC0001234",
  "accountHolderName": "John Doe",
  "bankStatus": "approved",
  "bankVerifiedAt": Timestamp,
  "bankVerificationMessage": "Bank account verified successfully",
  "bankSubmittedAt": Timestamp,
  "razorpayFundAccountId": "fa_xxxxx",
  "updatedAt": Timestamp
}
```

---

## 🧪 TESTING CHECKLIST

### Backend Testing
- [ ] Deploy Cloud Function successfully
- [ ] Set Razorpay credentials in Firebase config
- [ ] Test with valid bank details
- [ ] Test with invalid IFSC code
- [ ] Test with invalid account number
- [ ] Verify Firestore updates correctly
- [ ] Test webhook handler

### Frontend Testing
- [ ] Wallet shows "Add Bank Account" when no bank
- [ ] Button navigates to Profile screen
- [ ] Submit bank details from Profile
- [ ] Wallet shows "Verifying..." status
- [ ] Wallet updates to "Verified" after approval
- [ ] Wallet shows "Failed" on rejection
- [ ] Withdraw button disabled during verification
- [ ] Withdraw button enabled after approval
- [ ] Account number masked correctly (XXXX1234)

### Security Testing
- [ ] Client cannot update bankStatus directly
- [ ] Client cannot update bankVerifiedAt
- [ ] Only Cloud Functions can update verification fields
- [ ] Account numbers not logged in full

---

## 🚀 DEPLOYMENT STEPS

### 1. Backend Setup
```bash
# Install dependencies
cd backend/functions
npm install axios

# Set Razorpay credentials
firebase functions:config:set razorpay.key_id="rzp_test_xxxxx"
firebase functions:config:set razorpay.key_secret="xxxxx"

# Deploy functions
firebase deploy --only functions:verifyTechnicianBankAccount,functions:razorpayWebhook
```

### 2. Firestore Rules
```bash
# Update firestore.rules with bank verification rules
firebase deploy --only firestore:rules
```

### 3. Flutter App
```bash
# Add method to functions_service.dart
# Update wallet_screen.dart
# Update profile screen with bank form
# Test locally
flutter run
```

### 4. Razorpay Setup
- Enable Fund Account Validation API in Razorpay Dashboard
- Configure webhook URL: `https://YOUR_PROJECT.cloudfunctions.net/razorpayWebhook`
- Test with Razorpay test mode first

---

## 📝 IMPLEMENTATION CHECKLIST

### Backend ✅
- [x] Cloud Function created
- [x] Razorpay integration code
- [x] Webhook handler
- [x] Error handling
- [x] Firestore security rules

### Frontend ✅
- [x] FunctionsService method
- [x] Simplified wallet UI
- [x] Updated withdraw button
- [x] Navigation to profile
- [x] Status-based UI rendering
- [x] AppLogger integration

### Pending ⏳
- [ ] Add verifyBankAccount() to functions_service.dart
- [ ] Replace _buildBankAccountsSection() in wallet_screen.dart
- [ ] Replace _buildActionButtonsRow() in wallet_screen.dart
- [ ] Create bank details form in profile screen
- [ ] Deploy Cloud Functions
- [ ] Deploy Firestore rules
- [ ] Configure Razorpay credentials
- [ ] Test end-to-end flow

---

## 🎯 KEY BENEFITS

1. **Automated Verification**: No manual approval needed
2. **Instant Feedback**: Users know immediately if bank is valid
3. **Secure**: All verification happens server-side
4. **Simplified UX**: Single source of truth (Profile screen)
5. **Realtime Updates**: Wallet UI updates automatically
6. **Audit Trail**: All verification attempts logged
7. **Razorpay Integration**: Industry-standard penny drop

---

## 📞 SUPPORT

### Razorpay Documentation
- Fund Account Validation: https://razorpay.com/docs/api/fund-accounts/validations/
- Webhooks: https://razorpay.com/docs/webhooks/

### Troubleshooting
- **Verification timeout**: Increase Cloud Function timeout to 60s
- **Invalid IFSC**: Validate format: `^[A-Z]{4}0[A-Z0-9]{6}$`
- **Webhook not working**: Check Razorpay dashboard webhook logs
- **Status not updating**: Check TechnicianProvider change detection

---

**Implementation Date**: 2026-01-XX
**Status**: CODE COMPLETE ✅ | DEPLOYMENT PENDING ⏳
**Estimated Deployment Time**: 30-45 minutes
**Risk**: LOW (well-tested pattern)
**Breaking Changes**: NONE (additive only)
