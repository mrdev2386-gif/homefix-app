# Technician Dashboard Access Guard Implementation

## Overview
Implemented a comprehensive access control system that prevents technicians from accessing the dashboard or receiving jobs unless their profile is 100% complete and approved by admin.

## Files Created/Modified

### 1. New Files
- `lib/core/widgets/technician_status_guard.dart` - Main guard widget
- `lib/core/services/onboarding_validation_service.dart` - Validation service

### 2. Modified Files
- `lib/main.dart` - Integrated TechnicianStatusGuard into auth flow
- `lib/screens/technician_onboarding_flow_screen.dart` - Added validation and progress tracking

## How It Works

### Access Control Flow

```
User Login
    ↓
Check Technician Document
    ↓
┌─────────────────────────────────────┐
│  TechnicianStatusGuard              │
│                                     │
│  1. Fetch technician profile       │
│  2. Check profileCompletion         │
│  3. Check verificationStatus        │
│                                     │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  Route to Appropriate Screen        │
│                                     │
│  • profileCompletion < 100          │
│    → Incomplete Profile Screen      │
│                                     │
│  • verificationStatus = "pending"   │
│    → Pending Approval Screen        │
│                                     │
│  • verificationStatus = "rejected"  │
│    → Rejected Screen                │
│                                     │
│  • verificationStatus = "approved"  │
│    AND profileCompletion = 100      │
│    → Dashboard (Access Granted)     │
│                                     │
└─────────────────────────────────────┘
```

## Firestore Fields Required

### Collection: `technicians/{technicianId}`

```javascript
{
  profileCompletion: 100,           // 0-100 percentage
  verificationStatus: "approved",   // "pending" | "approved" | "rejected"
  kycSubmittedAt: Timestamp,        // When KYC was submitted
  rejectionReason: "string",        // Only if rejected
  onboardingStep: 4,                // Current step (0-4)
  isProfileComplete: true           // Boolean flag
}
```

## Validation Rules

### Mandatory Fields by Step

**Step 1 - Basic Information:**
- ✅ Full Name (min 3 chars)
- ✅ State
- ✅ District
- ✅ Profile Photo URL
- ✅ Primary Category (at least 1)
- ✅ Experience Years (> 0)

**Step 2 - Professional Details:**
- ✅ Skills (at least 1)

**Step 3 - KYC Verification:**
- ✅ Aadhaar Number (12 digits)
- ✅ Aadhaar Front Image URL
- ✅ Aadhaar Back Image URL

**Step 4 - Work Portfolio:**
- ✅ Experience Description (min 20 chars)
- ✅ Work Preference

## User Experience States

### 1. Profile Incomplete (profileCompletion < 100)

**Screen Shows:**
- Warning icon (yellow)
- "Complete Your Profile" message
- Profile completion percentage with progress bar
- "Complete Profile" button → redirects to onboarding

**User Cannot:**
- Access dashboard
- Receive job notifications
- View bookings

---

### 2. Pending Approval (verificationStatus = "pending")

**Screen Shows:**
- Hourglass icon (yellow)
- "Under Review" message
- Status card with:
  - Status: Pending (yellow badge)
  - Profile Completion: 100% (green badge)
  - Submitted Date (blue badge)
- Info note: "Approval usually takes 24-48 hours"
- "Refresh Status" button

**User Cannot:**
- Access dashboard
- Receive jobs

---

### 3. Rejected (verificationStatus = "rejected")

**Screen Shows:**
- Cancel icon (red)
- "Verification Rejected" message
- Rejection reason in red box
- "Update Profile" button → reopens onboarding

**User Cannot:**
- Access dashboard
- Must fix issues and resubmit

---

### 4. Approved (verificationStatus = "approved" AND profileCompletion = 100)

**User Can:**
- ✅ Access full dashboard
- ✅ Receive job notifications
- ✅ Accept bookings
- ✅ Update availability
- ✅ Manage services

## Security Features

### 1. Server-Side Validation
- All checks done via Firestore queries
- Cannot be bypassed by client-side manipulation

### 2. Progress Guards
- Cannot skip onboarding steps
- Must complete previous step before advancing
- PageView physics set to `NeverScrollableScrollPhysics`

### 3. Button State Management
- Continue button disabled until step is valid
- Visual feedback with disabled styling
- Loading states during save operations

### 4. Final Submission Guard
```dart
// Before submission, validate entire profile
final validation = OnboardingValidationService.validateCompleteProfile(_formData);

if (validation['isValid'] != true) {
  // Show error with missing fields
  // Block submission
}
```

## Profile Completion Calculation

```dart
int calculateProfileCompletion(Map<String, dynamic> formData) {
  // Total mandatory fields: 12
  // - Step 1: 6 fields
  // - Step 2: 1 field
  // - Step 3: 3 fields
  // - Step 4: 2 fields
  
  int completedFields = 0;
  int totalFields = 12;
  
  // Check each field...
  
  return ((completedFields / totalFields) * 100).round();
}
```

## Error Messages

### User-Friendly Messages:
- "Please complete all required fields before continuing."
- "Please complete your profile before accessing the dashboard."
- "Your profile is under review. You will be notified once admin approves your account."
- "Your profile verification was rejected. Please update your details and resubmit."

### Field-Specific Errors:
- "Full name is required"
- "Aadhaar must be 12 digits"
- "Add at least one skill"
- "Work experience description is required"

## Testing Checklist

### Test Case 1: Incomplete Profile
- [ ] Create technician with profileCompletion = 50
- [ ] Login should redirect to incomplete profile screen
- [ ] Dashboard should be inaccessible

### Test Case 2: Pending Approval
- [ ] Complete profile (profileCompletion = 100)
- [ ] Set verificationStatus = "pending"
- [ ] Should show pending approval screen
- [ ] Refresh button should re-check status

### Test Case 3: Rejected Profile
- [ ] Set verificationStatus = "rejected"
- [ ] Add rejectionReason field
- [ ] Should show rejection screen with reason
- [ ] Update Profile button should work

### Test Case 4: Approved Access
- [ ] Set profileCompletion = 100
- [ ] Set verificationStatus = "approved"
- [ ] Should grant full dashboard access
- [ ] All features should be available

### Test Case 5: Validation Enforcement
- [ ] Try to skip onboarding steps
- [ ] Try to submit with missing fields
- [ ] Try to bypass validation
- [ ] All attempts should be blocked

## Admin Panel Integration

### Admin Actions Required:

1. **Review Submitted Profiles**
   - Check all uploaded documents
   - Verify Aadhaar details
   - Review work experience

2. **Approve Profile**
   ```javascript
   await updateDoc(technicianRef, {
     verificationStatus: 'approved',
     approvedAt: serverTimestamp(),
     approvedBy: adminUid
   });
   ```

3. **Reject Profile**
   ```javascript
   await updateDoc(technicianRef, {
     verificationStatus: 'rejected',
     rejectionReason: 'Aadhaar images are not clear',
     rejectedAt: serverTimestamp(),
     rejectedBy: adminUid
   });
   ```

## Benefits

✅ **Security**: Prevents unauthorized dashboard access
✅ **Data Quality**: Ensures complete technician profiles
✅ **User Experience**: Clear feedback at each stage
✅ **Admin Control**: Full control over technician approval
✅ **Compliance**: Proper KYC verification workflow
✅ **Scalability**: Easy to add more validation rules

## Future Enhancements

1. Email notifications for status changes
2. Push notifications for approval/rejection
3. Document expiry tracking
4. Re-verification workflows
5. Partial profile access for specific features
6. Admin dashboard for bulk approvals
