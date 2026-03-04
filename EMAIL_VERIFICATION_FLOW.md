# Email Verification System - Visual Flow

## 🔄 Complete Verification Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    USER CHANGES EMAIL                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              User taps "Verify Email" button                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    ┌───────────────┐
                    │ Recent Login? │
                    └───────────────┘
                     ↙            ↘
                  YES              NO
                   ↓                ↓
    ┌──────────────────────┐   ┌──────────────────────┐
    │ Send Verification    │   │ Trigger Phone OTP    │
    │ Email Directly       │   │ Re-authentication    │
    └──────────────────────┘   └──────────────────────┘
                   ↓                ↓
                   │         ┌──────────────────┐
                   │         │ User Enters OTP  │
                   │         └──────────────────┘
                   │                ↓
                   │         ┌──────────────────┐
                   │         │ Re-auth Success  │
                   │         └──────────────────┘
                   │                ↓
                   └────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│           Verification Email Sent Successfully               │
│                                                              │
│   UI Shows: "Verification email sent. Checking              │
│              automatically..."                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              START AUTO-CHECK TIMER (5 sec)                  │
│                                                              │
│   Guard: if (_autoCheckTimer != null && isActive) return;   │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    ┌───────────────┐
                    │  Every 5 sec  │
                    └───────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              BACKGROUND VERIFICATION CHECK                   │
│                                                              │
│   1. await user.reload()                                    │
│   2. Check user.emailVerified                               │
│   3. Update UI state                                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    ┌───────────────┐
                    │  Verified?    │
                    └───────────────┘
                     ↙            ↘
                  YES              NO
                   ↓                ↓
    ┌──────────────────────┐   ┌──────────────────────┐
    │ STOP TIMER           │   │ Continue Checking    │
    │ Show Success Badge   │   │ (loop back)          │
    │ "✓ Email Verified"   │   └──────────────────────┘
    └──────────────────────┘              ↓
                   ↓                      ↑
                   │                      │
                   │         ┌────────────┘
                   │         │
                   ↓         │
    ┌──────────────────────┐│
    │ Hide Verify Button   ││
    │ Enable Save Button   ││
    └──────────────────────┘│
                   ↓         │
    ┌──────────────────────┐│
    │ User Saves Profile   ││
    └──────────────────────┘│
                   ↓         │
    ┌──────────────────────┐│
    │ Email Synced to      ││
    │ Firestore            ││
    │ technicians/{uid}    ││
    └──────────────────────┘│
                            │
                            │
                    Max 2 minutes
                    or until verified
```

---

## 🎨 UI State Transitions

### State 1: Email Not Changed
```
┌────────────────────────────────────────┐
│  Email: user@example.com               │
│  [No verification UI shown]            │
└────────────────────────────────────────┘
```

### State 2: Email Changed (Not Verified)
```
┌────────────────────────────────────────┐
│  Email: newemail@example.com  ⚠        │
│                                        │
│  [Verify Email]                        │
│                                        │
│  ⏱ Verification email sent.            │
│     Checking automatically...          │
└────────────────────────────────────────┘
```

### State 3: Email Verified
```
┌────────────────────────────────────────┐
│  Email: newemail@example.com  ✓        │
│                                        │
│  ✓ Email Verified                      │
│                                        │
│  [Save Changes]  ← Now enabled         │
└────────────────────────────────────────┘
```

---

## 🛡️ Memory Safety

### Timer Lifecycle
```
CREATE TIMER
    ↓
┌─────────────────────────────────────┐
│  _autoCheckTimer = Timer.periodic   │
└─────────────────────────────────────┘
    ↓
RUNNING
    ↓
┌─────────────────────────────────────┐
│  Checks every 5 seconds             │
└─────────────────────────────────────┘
    ↓
STOP CONDITIONS (any of):
    ↓
┌─────────────────────────────────────┐
│  1. Email verified                  │
│  2. Screen disposed                 │
│  3. Widget unmounted                │
└─────────────────────────────────────┘
    ↓
CLEANUP
    ↓
┌─────────────────────────────────────┐
│  _autoCheckTimer?.cancel()          │
│  _autoCheckTimer = null             │
└─────────────────────────────────────┘
```

---

## 🔐 Security Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT (Flutter App)                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    Verify Email
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  FIREBASE AUTH                               │
│                                                              │
│  • Sends verification email                                 │
│  • Updates user.emailVerified flag                          │
│  • Requires re-auth if session old                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    User Clicks Link
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  EMAIL VERIFIED                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    Auto-detected by app
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  SAVE PROFILE                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              CLOUD FUNCTION (Secure)                         │
│                                                              │
│  updateTechnicianPersonalDetails({                          │
│    fullName, email, city, experience, gender, bio           │
│  })                                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  FIRESTORE                                   │
│                                                              │
│  technicians/{uid} {                                        │
│    name: "...",                                             │
│    email: "newemail@example.com",  ← SYNCED                 │
│    district: "...",                                         │
│    experienceYears: 5,                                      │
│    gender: "...",                                           │
│    bio: "..."                                               │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Error Handling Matrix

| Error Code                  | User Message                              | Action                    |
|-----------------------------|-------------------------------------------|---------------------------|
| `invalid-verification-code` | Invalid OTP. Please try again.           | Allow retry               |
| `too-many-requests`         | Too many attempts. Try again later.      | Block temporarily         |
| `network-request-failed`    | Network error. Check your connection.    | Allow retry               |
| `session-expired`           | Session expired. Request new OTP.        | Restart flow              |
| `requires-recent-login`     | Please re-authenticate to continue.      | Trigger phone OTP         |
| Other                       | An error occurred. Please try again.     | Generic fallback          |

---

## ⚡ Performance Optimizations

1. **Silent Checks**: Background checks don't show loading indicators
2. **Smart Timer**: Stops immediately when verified (no wasted cycles)
3. **Guard Clause**: Prevents multiple timers from running
4. **Mounted Check**: Prevents setState on disposed widgets
5. **Efficient Reload**: Only reloads user when checking, not continuously

---

## 🎯 Key Improvements Summary

| Before                          | After                                    |
|---------------------------------|------------------------------------------|
| Manual "Check Status" button    | Automatic detection every 5 seconds      |
| No user reload                  | Always reloads before checking           |
| Potential memory leaks          | Timer properly cancelled                 |
| Multiple timers possible        | Guard prevents multiple timers           |
| Poor UI feedback                | Clean verified badge                     |
| Email might not sync            | Auto-syncs from FirebaseAuth             |
| Generic error messages          | Specific, actionable error messages      |

---

**Status:** ✅ PRODUCTION READY
**Last Updated:** 2026
