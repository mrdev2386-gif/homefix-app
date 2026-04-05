# Bank Verification Issue - Complete Analysis & Fix

## 🔍 ISSUE IDENTIFIED

**Problem:** "Bank verification initialized but no result" - UI gets stuck in verifying state

---

## 📋 ROOT CAUSES FOUND

### 1. **CRITICAL: Function Name Mismatch** ❌
**Location:** `functions_service.dart` line 380

```dart
// WRONG - Calling wrong function name
final callable = _functions.httpsCallable('verifyTechnicianBankAccount');
```

**Backend exports:** `verifyTechnicianBankAccountSecure`

**Result:** Function call fails silently, no response returned

---

### 2. **Missing Response Validation** ❌
**Location:** `edit_bank_details_screen.dart` line 68

```dart
// WRONG - No validation of response
await _functionsService.verifyTechnicianBankAccountSecure(...);
// Assumes success, doesn't check result.data
```

**Should be:**
```dart
// CORRECT - Validate response
final result = await _functionsService.verifyTechnicianBankAccountSecure(...);
if (result['success'] != true) {
  throw Exception(result['message'] ?? 'Verification failed');
}
```

---

### 3. **No Error Handling in UI** ❌
**Location:** `edit_bank_details_screen.dart` line 68-80

```dart
// WRONG - Catches error but doesn't update UI state
try {
  await _functionsService.verifyTechnicianBankAccountSecure(...);
  // If error thrown, loading state never resets
} catch (e) {
  // Shows error but UI might still be in loading state
}
```

---

### 4. **Missing Debug Logs** ❌
**Location:** `functions_service.dart` line 380

No logs to track:
- Function call initiated
- Response received
- Response data structure
- Success/failure status

---

### 5. **Razorpay Keys Using process.env** ❌
**Location:** `bank_verification.ts` line 11-12

```typescript
const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID || '';
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || '';
```

**Should use:** `functions.config().razorpay`

---

## ✅ FIXES REQUIRED

### FIX 1: Update Function Name in FunctionsService

**File:** `functions_service.dart`

```dart
// BEFORE (Line 380)
final callable = _functions.httpsCallable('verifyTechnicianBankAccount');

// AFTER
final callable = _functions.httpsCallable('verifyTechnicianBankAccountSecure');
```

---

### FIX 2: Add Response Validation in FunctionsService

**File:** `functions_service.dart`

```dart
// BEFORE
Future<Map<String, dynamic>> verifyTechnicianBankAccountSecure({
  required String accountHolderName,
  required String accountNumber,
  required String ifscCode,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: Current user UID: ${user.uid}');
    await user.getIdToken(true);
    debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: Token refreshed successfully');
    
    final callable = _functions.httpsCallable('verifyTechnicianBankAccount');
    final result = await callable.call({
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode.toUpperCase(),
    });
    return Map<String, dynamic>.from(result.data);
  } on FirebaseFunctionsException catch (e) {
    debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
    rethrow;
  } catch (e) {
    debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: Unexpected error: $e');
    rethrow;
  }
}

// AFTER
Future<Map<String, dynamic>> verifyTechnicianBankAccountSecure({
  required String accountHolderName,
  required String accountNumber,
  required String ifscCode,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: Current user UID: ${user.uid}');
    await user.getIdToken(true);
    debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: Token refreshed successfully');
    
    // FIX 1: Use correct function name
    debugPrint('[FunctionsService] Calling verifyTechnicianBankAccountSecure...');
    final callable = _functions.httpsCallable('verifyTechnicianBankAccountSecure');
    
    // FIX 2: Add debug log before call
    debugPrint('[FunctionsService] Bank verification request: accountHolder=$accountHolderName, ifsc=$ifscCode');
    
    final result = await callable.call({
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode.toUpperCase(),
    });
    
    // FIX 3: Validate response structure
    final responseData = Map<String, dynamic>.from(result.data);
    debugPrint('[FunctionsService] Bank verification response: $responseData');
    
    // FIX 4: Check for success flag
    if (responseData['success'] != true) {
      final message = responseData['message'] ?? 'Bank verification failed';
      debugPrint('[FunctionsService] Bank verification failed: $message');
      throw Exception(message);
    }
    
    debugPrint('[FunctionsService] Bank verification successful: ${responseData['status']}');
    return responseData;
  } on FirebaseFunctionsException catch (e) {
    debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: FirebaseFunctionsException - Code: ${e.code}, Message: ${e.message}');
    rethrow;
  } catch (e) {
    debugPrint('[FunctionsService] verifyTechnicianBankAccountSecure: Unexpected error: $e');
    rethrow;
  }
}
```

---

### FIX 3: Update UI Error Handling

**File:** `edit_bank_details_screen.dart`

```dart
// BEFORE
Future<void> _saveBankDetails() async {
  if (!_formKey.currentState!.validate()) return;
  if (_isSaving) return;

  setState(() => _isSaving = true);

  try {
    await _functionsService.verifyTechnicianBankAccountSecure(
      accountHolderName: _accountHolderController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      ifscCode: _ifscCodeController.text.trim().toUpperCase(),
    );

    if (!mounted) return;

    await context.read<TechnicianProvider>().refreshTechnicianData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bank verification initiated'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}

// AFTER
Future<void> _saveBankDetails() async {
  if (!_formKey.currentState!.validate()) return;
  if (_isSaving) return;

  setState(() => _isSaving = true);

  try {
    print('[BANK_VERIFY] Starting verification...');
    
    // FIX 1: Capture response
    final result = await _functionsService.verifyTechnicianBankAccountSecure(
      accountHolderName: _accountHolderController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      ifscCode: _ifscCodeController.text.trim().toUpperCase(),
    );

    print('[BANK_VERIFY] Response received: $result');

    if (!mounted) return;

    // FIX 2: Validate response before proceeding
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Verification failed');
    }

    print('[BANK_VERIFY] Verification successful, refreshing data...');
    
    // FIX 3: Refresh technician data
    await context.read<TechnicianProvider>().refreshTechnicianData();

    if (!mounted) return;

    print('[BANK_VERIFY] Data refreshed, showing success message');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bank verification initiated successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    // FIX 4: Delay navigation to ensure UI updates
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      Navigator.pop(context);
    }
  } catch (e) {
    print('[BANK_VERIFY] Error: $e');
    
    if (mounted) {
      // FIX 5: Always reset loading state
      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
```

---

### FIX 4: Update Cloud Function to Use Firebase Config

**File:** `bank_verification.ts`

```typescript
// BEFORE (Line 11-12)
const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID || '';
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || '';

// AFTER (Inside function, get from functions.config())
const getRazorpayCredentials = () => {
  const config = functions.config();
  const keyId = config.razorpay?.key_id;
  const keySecret = config.razorpay?.key_secret;
  
  if (!keyId || !keySecret) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Razorpay credentials not configured'
    );
  }
  
  return { keyId, keySecret };
};

// Then use in function:
const { keyId, keySecret } = getRazorpayCredentials();
const razorpayAuth = Buffer.from(`${keyId}:${keySecret}`).toString('base64');
```

---

## 🧪 TESTING CHECKLIST

- [ ] Function name matches between Flutter and backend
- [ ] Response validation works (checks `success` flag)
- [ ] Error messages display correctly
- [ ] Loading state resets on error
- [ ] UI navigates away on success
- [ ] Debug logs show complete flow
- [ ] Razorpay credentials loaded from Firebase config
- [ ] Bank verification completes without getting stuck

---

## 📊 Expected Flow After Fix

```
1. User clicks "Submit Bank Details"
   ↓
2. _saveBankDetails() called
   ↓
3. FunctionsService.verifyTechnicianBankAccountSecure() called
   ↓
4. Cloud Function: verifyTechnicianBankAccountSecure executed
   ↓
5. Response: { success: true, status: "verified", fundAccountId: "..." }
   ↓
6. Flutter validates response (success == true)
   ↓
7. TechnicianProvider.refreshTechnicianData() called
   ↓
8. UI updates to show verified state
   ↓
9. Navigation back to previous screen
```

---

## 🔐 Security Notes

1. **Log Injection:** Mask sensitive data in logs (already done with `maskAccountNumber()`)
2. **CSRF Protection:** Cloud Function is callable-only (Firebase handles CSRF)
3. **Razorpay Keys:** Use Firebase config, never process.env
4. **Error Messages:** Don't expose internal errors to user

---

## 📝 Summary of Changes

| File | Change | Impact |
|------|--------|--------|
| `functions_service.dart` | Fix function name + add validation | Enables proper function call |
| `edit_bank_details_screen.dart` | Add response validation + error handling | Fixes stuck UI state |
| `bank_verification.ts` | Use Firebase config for keys | Ensures keys are available |

---

**Status:** Ready to implement ✅
