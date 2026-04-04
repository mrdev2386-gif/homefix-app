# 🧪 AUTHWRAPPER FIX - TESTING CHECKLIST

## 📋 PRE-TEST SETUP

- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Ensure device/emulator is connected
- [ ] Check Firebase project is configured
- [ ] Verify `google-services.json` is in place

---

## ✅ TEST CASE 1: NEW USER SIGNUP (Google)

### Steps:
1. [ ] Open app
2. [ ] Verify LoginScreen appears
3. [ ] Tap "Continue with Google"
4. [ ] Complete Google sign-in
5. [ ] Verify OnboardingScreen appears
6. [ ] Enter name (minimum 3 characters)
7. [ ] Tap "Next"
8. [ ] Select state and district
9. [ ] Tap "Finish Onboarding"
10. [ ] Verify MainWrapperScreen appears

### Expected Result:
✅ User completes onboarding and sees home screen

---

## ✅ TEST CASE 2: NEW USER SIGNUP (Phone)

### Steps:
1. [ ] Open app
2. [ ] Verify LoginScreen appears
3. [ ] Enter 10-digit phone number
4. [ ] Tap "Continue"
5. [ ] Enter OTP code
6. [ ] Tap "Verify & Continue"
7. [ ] Verify OnboardingScreen appears
8. [ ] Complete onboarding (name + location)
9. [ ] Verify MainWrapperScreen appears

### Expected Result:
✅ User completes onboarding and sees home screen

---

## ✅ TEST CASE 3: RETURNING USER (Complete Profile)

### Steps:
1. [ ] Close app completely
2. [ ] Reopen app
3. [ ] Observe loading indicator briefly
4. [ ] Verify MainWrapperScreen appears directly

### Expected Result:
✅ No onboarding screen, direct to home
✅ No repeated onboarding

---

## ✅ TEST CASE 4: INCOMPLETE PROFILE

### Steps:
1. [ ] Manually delete `district` field from Firestore
2. [ ] Close and reopen app
3. [ ] Verify OnboardingScreen appears
4. [ ] Complete onboarding
5. [ ] Verify MainWrapperScreen appears

### Expected Result:
✅ User is prompted to complete profile

---

## ✅ TEST CASE 5: LOGOUT AND RE-LOGIN

### Steps:
1. [ ] Navigate to Profile
2. [ ] Tap Logout
3. [ ] Verify LoginScreen appears
4. [ ] Login again (Google or Phone)
5. [ ] Verify MainWrapperScreen appears (no onboarding)

### Expected Result:
✅ Profile already complete, skip onboarding

---

## ✅ TEST CASE 6: NO INTERNET CONNECTION

### Steps:
1. [ ] Disable internet/WiFi
2. [ ] Open app
3. [ ] Observe behavior
4. [ ] Enable internet
5. [ ] Verify app recovers

### Expected Result:
✅ App shows loading or error gracefully
✅ Recovers when connection restored

---

## ✅ TEST CASE 7: ROUTE NAVIGATION

### Steps:
1. [ ] From MainWrapperScreen, navigate to Profile
2. [ ] Navigate to Saved Addresses
3. [ ] Navigate back
4. [ ] Navigate to Custom Request
5. [ ] Navigate back

### Expected Result:
✅ All routes work without errors
✅ No "route not found" errors

---

## 🐛 DEBUGGING CHECKLIST

If issues occur, check:

### Console Logs:
- [ ] Check for Firebase initialization messages
- [ ] Check for auth state change logs
- [ ] Check for Firestore query logs
- [ ] Check for route errors

### Firestore Data:
```
customers/{uid}
  ├─ profileCompleted: true
  ├─ isOnboarded: true
  └─ district: "Some District"
```

### Common Issues:

| Issue | Solution |
|-------|----------|
| Onboarding repeats | Check Firestore fields above |
| Route error | Verify routes in main.dart |
| Stuck on loading | Check Firebase connection |
| Login fails | Check google-services.json |
| White screen | Check console for errors |

---

## 📊 PERFORMANCE CHECKS

- [ ] App starts in < 3 seconds
- [ ] Auth check completes in < 2 seconds
- [ ] Profile fetch completes in < 1 second
- [ ] No memory leaks (check DevTools)
- [ ] No unnecessary rebuilds

---

## ✅ FINAL VERIFICATION

- [ ] All test cases pass
- [ ] No console errors
- [ ] Smooth navigation
- [ ] No UI flickers
- [ ] Proper loading states
- [ ] Correct routing logic

---

## 📝 TEST RESULTS

**Date**: _______________
**Tester**: _______________
**Device**: _______________
**OS Version**: _______________

### Results:
- [ ] All tests passed
- [ ] Some tests failed (list below)
- [ ] Needs further investigation

### Notes:
```
_______________________________________
_______________________________________
_______________________________________
```

---

## 🎉 SUCCESS CRITERIA

✅ New users complete onboarding once
✅ Returning users skip onboarding
✅ No route errors
✅ No repeated onboarding
✅ Smooth user experience
✅ Fast app startup

---

**Status**: Ready for testing
**Priority**: High
**Estimated Time**: 15-20 minutes
