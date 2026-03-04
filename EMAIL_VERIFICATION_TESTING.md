# Email Verification System - Testing Guide

## 🧪 Complete Testing Checklist

### Test 1: Basic Email Verification Flow
**Objective:** Verify automatic email verification detection works

**Steps:**
1. Open technician app
2. Navigate to Profile → Edit Personal Details
3. Change email to a new valid email address
4. Tap "Verify Email" button
5. Check your email inbox
6. Click verification link in email
7. Return to app (keep it open)

**Expected Results:**
- ✅ "Verify Email" button appears when email changes
- ✅ Orange badge shows: "Verification email sent. Checking automatically..."
- ✅ Within 5-10 seconds after clicking link, green badge appears: "✓ Email Verified"
- ✅ "Verify Email" button disappears
- ✅ Success snackbar shows briefly
- ✅ "Save Changes" button becomes enabled

**Pass Criteria:** All expected results occur without manual "Check Status" button press

---

### Test 2: Timer Memory Leak Prevention
**Objective:** Ensure timer is properly cancelled

**Steps:**
1. Change email and tap "Verify Email"
2. Wait for orange badge to appear
3. Press back button to exit screen
4. Wait 30 seconds
5. Check app memory usage (should not increase)
6. Re-enter Edit Personal Details screen

**Expected Results:**
- ✅ No crashes
- ✅ No memory leaks
- ✅ App remains responsive
- ✅ Previous verification state is remembered

**Pass Criteria:** No memory issues, clean disposal

---

### Test 3: Multiple Timer Protection
**Objective:** Prevent multiple timers from running simultaneously

**Steps:**
1. Change email
2. Tap "Verify Email" button
3. Immediately tap "Verify Email" button again (5 times rapidly)
4. Observe console logs

**Expected Results:**
- ✅ Only one timer is created
- ✅ No duplicate verification checks
- ✅ No crashes or errors
- ✅ UI remains stable

**Pass Criteria:** Guard clause prevents multiple timers

---

### Test 4: Re-authentication Flow
**Objective:** Test phone OTP re-authentication when session is old

**Steps:**
1. Sign in to technician app
2. Wait 30+ minutes (or force requires-recent-login)
3. Navigate to Edit Personal Details
4. Change email
5. Tap "Verify Email"
6. OTP bottom sheet should appear
7. Enter OTP from SMS
8. Tap "Verify OTP"

**Expected Results:**
- ✅ OTP bottom sheet appears automatically
- ✅ OTP sent to registered phone number
- ✅ After OTP verification, verification email is sent
- ✅ Auto-check timer starts
- ✅ Process continues normally

**Pass Criteria:** Re-authentication works seamlessly

---

### Test 5: Email Sync to Firestore
**Objective:** Ensure email is saved to Firestore

**Steps:**
1. Change email and verify it
2. Tap "Save Changes"
3. Open Firebase Console
4. Navigate to Firestore → technicians/{uid}
5. Check email field

**Expected Results:**
- ✅ Email field exists in Firestore document
- ✅ Email matches the verified email
- ✅ Other fields (name, city, etc.) also updated

**Pass Criteria:** Email correctly stored in Firestore

---

### Test 6: Auto-Sync from FirebaseAuth
**Objective:** Test email auto-sync when Firestore email is empty

**Steps:**
1. In Firebase Console, delete email field from technicians/{uid}
2. Restart app
3. Navigate to Edit Personal Details
4. Check email field

**Expected Results:**
- ✅ Email field is populated from FirebaseAuth.user.email
- ✅ No errors or crashes
- ✅ Email is editable

**Pass Criteria:** Email auto-syncs from FirebaseAuth

---

### Test 7: Error Handling - Invalid OTP
**Objective:** Test error handling for invalid OTP

**Steps:**
1. Trigger re-authentication flow
2. Enter wrong OTP (e.g., "000000")
3. Tap "Verify OTP"

**Expected Results:**
- ✅ Error snackbar shows: "Invalid OTP. Please try again."
- ✅ Bottom sheet remains open
- ✅ User can retry with correct OTP

**Pass Criteria:** Proper error message displayed

---

### Test 8: Error Handling - Network Error
**Objective:** Test error handling for network issues

**Steps:**
1. Turn off WiFi and mobile data
2. Change email
3. Tap "Verify Email"

**Expected Results:**
- ✅ Error snackbar shows: "Network error. Please check your connection."
- ✅ No crashes
- ✅ User can retry after reconnecting

**Pass Criteria:** Network errors handled gracefully

---

### Test 9: Error Handling - Too Many Requests
**Objective:** Test rate limiting error handling

**Steps:**
1. Rapidly tap "Verify Email" multiple times
2. Trigger Firebase rate limiting

**Expected Results:**
- ✅ Error snackbar shows: "Too many attempts. Please try again later."
- ✅ Button becomes disabled temporarily
- ✅ No crashes

**Pass Criteria:** Rate limiting handled properly

---

### Test 10: UI State Transitions
**Objective:** Verify all UI states display correctly

**Test Cases:**

**Case A: Email Not Changed**
```
Expected UI:
- Email field shows current email
- No verification UI visible
- Save button enabled
```

**Case B: Email Changed (Not Verified)**
```
Expected UI:
- Email field shows new email with ⚠ icon
- "Verify Email" button visible
- Orange badge: "Verification email sent. Checking automatically..."
- Save button disabled
```

**Case C: Email Verified**
```
Expected UI:
- Email field shows new email with ✓ icon
- "Verify Email" button hidden
- Green badge: "✓ Email Verified"
- Save button enabled
```

**Pass Criteria:** All UI states render correctly

---

### Test 11: Screen Navigation During Verification
**Objective:** Test timer behavior during navigation

**Steps:**
1. Change email and tap "Verify Email"
2. Navigate away from screen (don't verify email yet)
3. Navigate back to Edit Personal Details
4. Verify email in inbox
5. Observe if verification is detected

**Expected Results:**
- ✅ Timer is cancelled when leaving screen
- ✅ New timer starts when returning to screen
- ✅ Verification is detected on return
- ✅ No crashes or memory issues

**Pass Criteria:** Timer lifecycle managed correctly

---

### Test 12: Rapid Email Changes
**Objective:** Test behavior when user changes email multiple times

**Steps:**
1. Change email to email1@test.com
2. Tap "Verify Email"
3. Immediately change email to email2@test.com
4. Tap "Verify Email" again
5. Verify email2@test.com

**Expected Results:**
- ✅ Previous timer is cancelled
- ✅ New timer starts for email2
- ✅ Only email2 verification is tracked
- ✅ No conflicts or errors

**Pass Criteria:** Handles rapid changes gracefully

---

### Test 13: App Backgrounding
**Objective:** Test timer behavior when app goes to background

**Steps:**
1. Change email and tap "Verify Email"
2. Press home button (app goes to background)
3. Verify email in inbox
4. Return to app after 30 seconds

**Expected Results:**
- ✅ Timer continues running in background
- ✅ Verification is detected when app returns to foreground
- ✅ UI updates correctly
- ✅ No crashes

**Pass Criteria:** Background behavior is correct

---

### Test 14: Email Validation
**Objective:** Test email format validation

**Test Cases:**
- Invalid: "notanemail"
- Invalid: "test@"
- Invalid: "@example.com"
- Valid: "test@example.com"
- Valid: "user.name+tag@example.co.uk"

**Expected Results:**
- ✅ Invalid emails show validation error
- ✅ Valid emails pass validation
- ✅ "Verify Email" button only enabled for valid emails

**Pass Criteria:** Email validation works correctly

---

### Test 15: Save Without Verification
**Objective:** Ensure user cannot save unverified email

**Steps:**
1. Change email
2. Tap "Verify Email"
3. Do NOT verify email
4. Tap "Save Changes"

**Expected Results:**
- ✅ Error snackbar shows: "⚠ Please verify your email before saving profile"
- ✅ Profile is not saved
- ✅ User remains on screen

**Pass Criteria:** Unverified email cannot be saved

---

## 🎯 Automated Test Script (Optional)

```dart
// Integration test for email verification
testWidgets('Email verification flow works end-to-end', (tester) async {
  // 1. Navigate to edit screen
  await tester.pumpWidget(MyApp());
  await tester.tap(find.text('Edit Personal Details'));
  await tester.pumpAndSettle();

  // 2. Change email
  await tester.enterText(find.byType(TextField).at(2), 'newemail@test.com');
  await tester.pumpAndSettle();

  // 3. Verify button appears
  expect(find.text('Verify Email'), findsOneWidget);

  // 4. Tap verify button
  await tester.tap(find.text('Verify Email'));
  await tester.pumpAndSettle();

  // 5. Check orange badge appears
  expect(find.text('Verification email sent. Checking automatically...'), findsOneWidget);

  // 6. Simulate email verification (mock)
  // ... mock Firebase user.emailVerified = true

  // 7. Wait for auto-check (5 seconds)
  await tester.pump(Duration(seconds: 6));

  // 8. Check green badge appears
  expect(find.text('✓ Email Verified'), findsOneWidget);

  // 9. Verify button should be hidden
  expect(find.text('Verify Email'), findsNothing);

  // 10. Save button should be enabled
  expect(find.text('Save Changes'), findsOneWidget);
});
```

---

## 📊 Test Results Template

| Test # | Test Name                          | Status | Notes |
|--------|------------------------------------|--------|-------|
| 1      | Basic Email Verification Flow      | ⬜     |       |
| 2      | Timer Memory Leak Prevention       | ⬜     |       |
| 3      | Multiple Timer Protection          | ⬜     |       |
| 4      | Re-authentication Flow             | ⬜     |       |
| 5      | Email Sync to Firestore            | ⬜     |       |
| 6      | Auto-Sync from FirebaseAuth        | ⬜     |       |
| 7      | Error Handling - Invalid OTP       | ⬜     |       |
| 8      | Error Handling - Network Error     | ⬜     |       |
| 9      | Error Handling - Too Many Requests | ⬜     |       |
| 10     | UI State Transitions               | ⬜     |       |
| 11     | Screen Navigation During Verify    | ⬜     |       |
| 12     | Rapid Email Changes                | ⬜     |       |
| 13     | App Backgrounding                  | ⬜     |       |
| 14     | Email Validation                   | ⬜     |       |
| 15     | Save Without Verification          | ⬜     |       |

**Legend:**
- ⬜ Not Tested
- ✅ Passed
- ❌ Failed
- ⚠️ Partial Pass

---

## 🐛 Known Issues to Watch For

1. **Firebase Rate Limiting**: If testing too rapidly, Firebase may rate limit verification emails
2. **Email Delivery Delay**: Some email providers may delay delivery by 1-2 minutes
3. **Background Timer**: On iOS, background timers may be throttled after 30 seconds
4. **Network Flakiness**: Ensure stable internet connection during testing

---

## ✅ Final Acceptance Criteria

All tests must pass with these conditions:

- ✅ No manual "Check Status" button press required
- ✅ Email verification detected within 10 seconds of clicking link
- ✅ No memory leaks or crashes
- ✅ All error cases handled gracefully
- ✅ UI states are clear and intuitive
- ✅ Email always syncs to Firestore
- ✅ Re-authentication works seamlessly
- ✅ Timer lifecycle is properly managed

---

**Testing Status:** Ready for QA
**Last Updated:** 2026
**Tested By:** _____________
**Date:** _____________
