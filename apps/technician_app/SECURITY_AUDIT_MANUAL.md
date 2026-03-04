# 🔒 PRODUCTION SECURITY AUDIT - MANUAL VERIFICATION

## AUTOMATED AUDIT TOOL

Run: `BankModuleAuditScreen` in technician_app

Location: `lib/tests/bank_module_security_audit.dart`

---

## STEP 1: FIRESTORE RULES ENFORCEMENT

### Test: Direct Client Read
```dart
final doc = await FirebaseFirestore.instance
    .collection('technicians')
    .doc(uid)
    .get();
    
final accountNumber = doc.data()?['accountNumber'];
```

### Expected Result:
- ✅ PASS: accountNumber is null OR masked (****1234)
- ❌ FAIL: accountNumber contains full raw number

### Verification Command:
```bash
# In Firebase Console > Firestore
# Navigate to technicians/{uid}
# Check accountNumber field
```

---

## STEP 2: FUNCTION MASKING

### Test: Call updateTechnicianBankDetails
```dart
final result = await functions.httpsCallable('updateTechnicianBankDetails').call({
  'accountHolderName': 'Test',
  'bankName': 'Test Bank',
  'accountNumber': '1234567890123',
  'ifscCode': 'SBIN0001234',
});

print(result.data);
```

### Expected Response:
```json
{
  "success": true,
  "message": "Bank details submitted for verification",
  "bankStatus": "pending",
  "maskedAccountNumber": "****0123"
}
```

### Verification:
- ✅ PASS: Contains `maskedAccountNumber`
- ✅ PASS: Does NOT contain `accountNumber`
- ❌ FAIL: Contains raw `accountNumber`

---

## STEP 3: APPROVED LOCK

### Test: Attempt Update on Approved Status

1. Set bankStatus to approved:
```bash
# Firebase Console > Firestore
technicians/{uid}
  bankStatus: "approved"
```

2. Attempt update:
```dart
await functions.httpsCallable('updateTechnicianBankDetails').call({
  'accountHolderName': 'Hacker',
  'bankName': 'Evil Bank',
  'accountNumber': '9999999999999',
  'ifscCode': 'HACK0001234',
});
```

### Expected Result:
- ✅ PASS: Throws `FirebaseFunctionsException`
- ✅ PASS: Error code: `failed-precondition`
- ✅ PASS: Message: "Cannot modify approved bank details"
- ✅ PASS: Firestore document unchanged

### Verification:
```bash
# Check Firestore after error
# accountHolderName should NOT be "Hacker"
```

---

## STEP 4: REGION CONSISTENCY

### Test: Check Functions Instance
```dart
final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
print(functions.toString());
```

### Expected:
- ✅ PASS: Contains "us-central1"
- ❌ FAIL: Contains "us-central" or default region

### Verification:
```bash
# Check functions_service.dart
grep -n "instanceFor" lib/core/services/functions_service.dart
```

---

## STEP 5: SCHEMA PURITY

### Test: Check for Nested Object
```dart
final doc = await FirebaseFirestore.instance
    .collection('technicians')
    .doc(uid)
    .get();
    
final data = doc.data();
print('Has bankDetails: ${data?.containsKey('bankDetails')}');
print('Has accountHolderName: ${data?.containsKey('accountHolderName')}');
```

### Expected:
- ✅ PASS: `bankDetails` does NOT exist
- ✅ PASS: `accountHolderName` exists at root level
- ❌ FAIL: Both `bankDetails` and root-level fields exist

### Verification:
```bash
# Firebase Console > Firestore
# Check technicians/{uid} structure
# Should see:
#   accountHolderName (root)
#   bankName (root)
#   accountNumber (root)
#   ifscCode (root)
#   bankStatus (root)
# Should NOT see:
#   bankDetails { ... }
```

---

## STEP 6: UI STATE VERIFICATION

### Manual UI Test

#### State 1: not_submitted
1. Set `bankStatus: "not_submitted"` in Firestore
2. Open Bank Details screen
3. **Expected:**
   - ✅ Editable form visible
   - ✅ All fields can be typed into
   - ✅ Submit button enabled

#### State 2: pending
1. Set `bankStatus: "pending"` in Firestore
2. Open Bank Details screen
3. **Expected:**
   - ✅ Read-only view
   - ✅ "Verification Pending" message
   - ✅ Account number masked (****1234)
   - ✅ No edit button

#### State 3: approved
1. Set `bankStatus: "approved"` in Firestore
2. Open Bank Details screen
3. **Expected:**
   - ✅ Locked view with verified badge
   - ✅ "Bank Details Verified" message
   - ✅ Account number masked
   - ✅ No edit button
   - ✅ Cannot navigate to edit form

#### State 4: rejected
1. Set `bankStatus: "rejected"` in Firestore
2. Set `bankRejectionReason: "Invalid IFSC"` in Firestore
3. Open Bank Details screen
4. **Expected:**
   - ✅ Editable form visible
   - ✅ Red rejection banner
   - ✅ Rejection reason displayed
   - ✅ Can resubmit

---

## FINAL VERIFICATION CHECKLIST

### Security
- [ ] Raw account number NOT readable from Firestore
- [ ] Cloud Function returns masked data only
- [ ] Approved status cannot be edited
- [ ] All writes go through Cloud Functions
- [ ] Firestore rules block direct writes

### Architecture
- [ ] Single data structure (root-level only)
- [ ] No nested bankDetails object
- [ ] Region consistency (us-central1)
- [ ] No duplicate implementations

### UI/UX
- [ ] UI refreshes immediately after submission
- [ ] No hot reload needed
- [ ] All 4 states render correctly
- [ ] Masking works in all views

---

## PASS/FAIL CRITERIA

### PASS Requirements:
- All 6 steps return ✅ PASS
- No ❌ FAIL in any step
- Manual UI verification complete

### FAIL Conditions:
- Any step returns ❌ FAIL
- Raw account number exposed
- Approved status can be edited
- Schema has nested objects
- Wrong region used

---

## DEPLOYMENT VERIFICATION

After deploying to production:

1. Run automated audit tool
2. Verify all steps pass
3. Test all 4 UI states manually
4. Monitor Cloud Function logs
5. Check Firestore security rules active

---

## TROUBLESHOOTING

### Issue: Step 1 FAIL (Raw account readable)
**Fix:** Deploy Firestore rules, ensure no direct client writes

### Issue: Step 2 FAIL (No masking)
**Fix:** Redeploy Cloud Function with masking logic

### Issue: Step 3 FAIL (Approved editable)
**Fix:** Redeploy Cloud Function with approved check

### Issue: Step 4 FAIL (Wrong region)
**Fix:** Update functions_service.dart to use us-central1

### Issue: Step 5 FAIL (Nested object)
**Fix:** Migrate data, remove legacy fallback from model

---

## SIGN-OFF

**Auditor:** _________________
**Date:** _________________
**Status:** PASS / FAIL
**Notes:** _________________
