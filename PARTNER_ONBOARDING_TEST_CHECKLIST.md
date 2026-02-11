# Partner Onboarding - Testing Checklist

## 🎯 CRITICAL TEST: Step 3 Button Fix

### Test Scenario
**Objective**: Verify the Continue button works on Step 3 (Track Record)

**Steps**:
1. ✅ Open Partner Onboarding screen
2. ✅ Fill Step 1 (Name: "John Doe", Phone: "9876543210", Email: "john@example.com")
3. ✅ Tap Continue → Should navigate to Step 2
4. ✅ Select at least 1 category (e.g., "Plumbing")
5. ✅ Tap Continue → Should navigate to Step 3
6. ✅ Enter "5" in Years of Experience field
7. ✅ Leave Description field empty (it's optional)
8. ✅ **Tap Continue button**
9. ✅ **EXPECTED**: Smooth animation to Step 4
10. ✅ **RESULT**: _______________

**Status**: [ ] PASS [ ] FAIL

---

## 📋 COMPLETE FLOW TEST

### Step 1: Personal Information
- [ ] Screen loads without errors
- [ ] Title shows "Personal Information"
- [ ] Subtitle shows "Let's start with your basic details"
- [ ] Progress shows "Step 1 of 8" and "12% Complete"
- [ ] Three input fields visible (Name, Phone, Email)
- [ ] Each field has icon on left
- [ ] Placeholder text visible
- [ ] Try Continue without filling → Red Snackbar appears
- [ ] Fill all fields correctly
- [ ] Tap Continue → Smooth animation to Step 2

**Status**: [ ] PASS [ ] FAIL

### Step 2: Service Expertise
- [ ] Screen loads without errors
- [ ] Title shows "Service Expertise"
- [ ] Subtitle shows "Select the services you can provide"
- [ ] Progress shows "Step 2 of 8" and "25% Complete"
- [ ] Category chips visible
- [ ] Tap chip → Chip highlights (blue background)
- [ ] Selected count updates
- [ ] Try Continue without selection → Red Snackbar appears
- [ ] Select at least 1 category
- [ ] Tap Continue → Smooth animation to Step 3

**Status**: [ ] PASS [ ] FAIL

### Step 3: Track Record ⭐ CRITICAL
- [ ] Screen loads without errors
- [ ] Title shows "Track Record"
- [ ] Subtitle shows "Tell us about your professional experience"
- [ ] Progress shows "Step 3 of 8" and "37% Complete"
- [ ] Two input fields visible (Years, Description)
- [ ] Years field has work icon
- [ ] Description field is multi-line
- [ ] Try Continue without years → Red Snackbar: "Please enter valid years of experience (must be greater than 0)"
- [ ] Enter "0" → Same error
- [ ] Enter "-1" → Same error
- [ ] Enter "abc" → Same error
- [ ] Enter "5" → No error
- [ ] Leave Description empty → No error (optional)
- [ ] **Tap Continue → Smooth animation to Step 4** ✅
- [ ] **Button works perfectly**

**Status**: [ ] PASS [ ] FAIL

### Step 4: Profile Photo
- [ ] Screen loads without errors
- [ ] Title shows "Profile Photo"
- [ ] Subtitle shows "Upload a clear photo of yourself"
- [ ] Progress shows "Step 4 of 8" and "50% Complete"
- [ ] Upload area visible (200x200)
- [ ] Shows camera icon and "Tap to upload"
- [ ] Try Continue without photo → Red Snackbar appears
- [ ] Tap upload area → Image picker opens
- [ ] Select image → Image preview shows
- [ ] Green Snackbar: "Image uploaded successfully"
- [ ] Tap Continue → Smooth animation to Step 5

**Status**: [ ] PASS [ ] FAIL

### Step 5: ID Verification
- [ ] Screen loads without errors
- [ ] Title shows "ID Verification"
- [ ] Subtitle shows "Upload a government-issued ID..."
- [ ] Progress shows "Step 5 of 8" and "62% Complete"
- [ ] Upload area visible (full width, 200px height)
- [ ] Shows upload icon and "Tap to upload ID"
- [ ] Try Continue without ID → Red Snackbar appears
- [ ] Tap upload area → Image picker opens
- [ ] Select image → Image preview shows
- [ ] Green Snackbar: "Image uploaded successfully"
- [ ] Tap Continue → Smooth animation to Step 6

**Status**: [ ] PASS [ ] FAIL

### Step 6: Service Address
- [ ] Screen loads without errors
- [ ] Title shows "Service Address"
- [ ] Subtitle shows "Where will you provide services?"
- [ ] Progress shows "Step 6 of 8" and "75% Complete"
- [ ] Address field visible (multi-line)
- [ ] Has location icon
- [ ] Try Continue with short address → Red Snackbar: "Please enter a complete address (minimum 10 characters)"
- [ ] Enter complete address (10+ chars)
- [ ] Tap Continue → Smooth animation to Step 7

**Status**: [ ] PASS [ ] FAIL

### Step 7: Bank Details
- [ ] Screen loads without errors
- [ ] Title shows "Bank Details"
- [ ] Subtitle shows "For receiving payments"
- [ ] Progress shows "Step 7 of 8" and "87% Complete"
- [ ] Three input fields visible (Holder Name, Account, IFSC)
- [ ] Each field has appropriate icon
- [ ] Try Continue without filling → Red Snackbar appears
- [ ] Enter short account number → Error
- [ ] Enter wrong IFSC length → Error
- [ ] Fill all correctly (Account: 10+ digits, IFSC: 11 chars)
- [ ] Tap Continue → Smooth animation to Step 8

**Status**: [ ] PASS [ ] FAIL

### Step 8: Terms & Conditions
- [ ] Screen loads without errors
- [ ] Title shows "Terms & Conditions"
- [ ] Subtitle shows "Please review and accept"
- [ ] Progress shows "Step 8 of 8" and "100% Complete"
- [ ] Agreement card visible with terms
- [ ] Checkbox visible (unchecked)
- [ ] Try Submit without checkbox → Red Snackbar: "Please agree to the terms and conditions"
- [ ] Tap checkbox → Checkbox fills with checkmark
- [ ] Button text changes to "Submit Application"
- [ ] Tap Submit → Loading spinner appears
- [ ] Success dialog appears
- [ ] Dialog shows checkmark icon, title, message
- [ ] Tap "Back to Profile" → Returns to profile

**Status**: [ ] PASS [ ] FAIL

---

## 🔄 BACK NAVIGATION TEST

### Test Scenario
**Objective**: Verify back navigation works safely

**Steps**:
1. [ ] Navigate to Step 3
2. [ ] Fill Years of Experience: "5"
3. [ ] Tap back button (AppBar)
4. [ ] Should return to Step 2
5. [ ] Data should be preserved (categories still selected)
6. [ ] Tap Continue → Returns to Step 3
7. [ ] Years field should still show "5"
8. [ ] No crashes
9. [ ] Smooth animations

**Status**: [ ] PASS [ ] FAIL

---

## ⚠️ ERROR HANDLING TEST

### Validation Errors
- [ ] Each step shows appropriate error message
- [ ] Error appears in red Snackbar
- [ ] Error message is clear and actionable
- [ ] Error disappears after 3 seconds
- [ ] Can dismiss error by tapping
- [ ] After fixing error, can proceed

### Network Errors
- [ ] Turn off internet
- [ ] Try to submit application
- [ ] Should show error message
- [ ] Should not crash
- [ ] Turn on internet
- [ ] Retry → Should work

### Image Upload Errors
- [ ] Cancel image picker → No error shown
- [ ] Select invalid file → Error shown
- [ ] Select valid image → Success message

**Status**: [ ] PASS [ ] FAIL

---

## 🎨 UI/UX TEST

### Visual Design
- [ ] Clean white background (#FAFAFA)
- [ ] White cards with soft shadows
- [ ] Rounded corners (16-20px)
- [ ] Consistent padding (24px)
- [ ] Bold titles (28px, weight 900)
- [ ] Grey subtitles (15px)
- [ ] Primary color accents (blue)

### Animations
- [ ] Smooth fade-in on step load
- [ ] Smooth slide transition
- [ ] Progress bar animates
- [ ] Button shows loading spinner
- [ ] No janky animations
- [ ] 400ms duration feels right

### Typography
- [ ] Google Fonts Outfit used
- [ ] Text is readable
- [ ] Proper hierarchy
- [ ] Consistent sizing

### Spacing
- [ ] Consistent padding
- [ ] Proper field spacing (20px)
- [ ] Bottom bar doesn't overlap content
- [ ] Scrollable on small screens

**Status**: [ ] PASS [ ] FAIL

---

## 📱 DEVICE COMPATIBILITY TEST

### Screen Sizes
- [ ] Small phone (< 5.5") - Content scrollable
- [ ] Medium phone (5.5" - 6.5") - Looks good
- [ ] Large phone (> 6.5") - Looks good
- [ ] Tablet - Looks good

### Keyboard Behavior
- [ ] Keyboard appears when tapping input
- [ ] Bottom bar stays above keyboard
- [ ] Can scroll to see all fields
- [ ] Keyboard doesn't hide button
- [ ] Keyboard dismisses on Continue

**Status**: [ ] PASS [ ] FAIL

---

## 🔒 SAFETY TEST

### Memory Leaks
- [ ] Navigate through all steps
- [ ] Go back to Step 1
- [ ] Navigate forward again
- [ ] No memory warnings
- [ ] No performance degradation

### Crash Prevention
- [ ] Rapid tapping Continue → No crash
- [ ] Rapid back/forward → No crash
- [ ] Rotate device → No crash
- [ ] Background/foreground → No crash
- [ ] Low memory → Handles gracefully

**Status**: [ ] PASS [ ] FAIL

---

## ✅ FINAL VERIFICATION

### Critical Requirements
- [x] Step 3 button works ⭐
- [ ] All 8 steps functional
- [ ] Modern UI design
- [ ] Smooth animations
- [ ] Clear validation
- [ ] Error handling
- [ ] Back navigation safe
- [ ] Image upload works
- [ ] Form submission works
- [ ] Success dialog appears

### Production Readiness
- [ ] No compilation errors
- [ ] No runtime errors
- [ ] No crashes
- [ ] No memory leaks
- [ ] User-friendly
- [ ] Professional look
- [ ] Fast performance

---

## 📊 TEST RESULTS

### Summary
- Total Tests: _____ / _____
- Passed: _____
- Failed: _____
- Critical Issues: _____

### Critical Test Result
**Step 3 Button**: [ ] WORKING [ ] NOT WORKING

### Overall Status
[ ] READY FOR PRODUCTION
[ ] NEEDS FIXES

---

## 🎉 SIGN-OFF

**Tested By**: _______________
**Date**: _______________
**Device**: _______________
**OS Version**: _______________

**Notes**:
_______________________________________
_______________________________________
_______________________________________

**Approved for Production**: [ ] YES [ ] NO

---

## 📞 ISSUE REPORTING

If any test fails:
1. Note the exact step where it failed
2. Describe what happened vs. what was expected
3. Include device and OS information
4. Take screenshots if possible
5. Check console for error messages

**The most critical test is Step 3 button - this MUST work!** ⭐
